# Diagnosi · movimenti scollegati dal conto (account vero) · architetto 2026-11-27

Lavoro solo in lettura. I dati personali restano in Drive (`prima.json`, `dopo.json`): qui ci sono solo conteggi.

## Fatti misurati sulle due esportazioni
- 6 conti con gli **stessi id** in prima e dopo, nomi unici.
- 113 movimenti persi (BuddyBank 56, Portafoglio 39, TradeRepubblic 12, PayPal 6), più 13 già senza conto in prima (creati 2–9/09).
- **Confine netto sulla data di creazione (`createdAt`)**: tutti i movimenti creati entro il **2026-10-29 01:03 UTC** hanno perso il conto, tranne 2 (16/10).
  Tutti quelli creati dal **2026-10-29 08:30 UTC** in poi sono rimasti collegati. Nessuna eccezione dopo il confine.

## Causa
**Il danno è quasi certamente sul server da fine ottobre. Il rientro di ieri l'ha solo reso visibile.**

1. **Il rientro scarica tutto dal server.** Il cambio utente svuota il locale, iOS `SyncService.swift:597-600` (in chiaro) e
   `SyncService+E2E.swift:60-81` (percorso con la Protezione avanzata accesa nella build). Poi fa un pull completo
   (`:606-611` e `initialE2ESync` `:477-492` → `download`). Dopo il rientro, quindi, il telefono contiene esattamente quello che c'è sul server.
2. **Il pull crea i movimenti nuovi col conto preso dal server** (`SyncService.swift:999`, `sb.accountId.flatMap { accountMap[$0] }`).
   I 6 conti arrivano tutti (stessi id): se il server avesse avuto `account_id`, i movimenti sarebbero stati ricollegati. Quindi
   **sul server quei 113 hanno `account_id` null**. In alternativa puntano a un conto inesistente: la query qui sotto lo distingue.
3. **Perché il telefono di prima mostrava i saldi giusti:** sui movimenti già presenti il pull non sovrascrive mai il conto locale con null
   (`SyncService.swift:983`, `if let accId = sb.accountId`). Android fa lo stesso (`SyncMerge.kt:81`). Il collegamento locale ha nascosto il guasto per un mese.
4. **Perché restano solo quelli vecchi:** il push dei movimenti è **incrementale**. Carica solo gli id "sporchi" (`SyncService.swift:820-828`,
   `fullUpsert: table != .transactions`; era incrementale già dal 07/2026, vedi `08dedf8`). Dopo l'azzeramento, solo i movimenti creati
   o modificati in seguito sono stati ricaricati con il conto giusto. Gli altri sono rimasti null.
5. **L'"eco" che può aver causato l'azzeramento:** ogni salvataggio del contesto principale, **compreso quello del pull**, segna come
   sporchi i movimenti inseriti o aggiornati (`MoneyTrackerApp.swift:313-324` → `recordChanges` `SyncService.swift:521-538`). Dopo
   1,5 s li ricarica sul server con il valore locale. Se un dispositivo appena entrato ha tutti i movimenti senza conto, li rimanda
   **tutti** a null. Questo è coerente con il confine netto: il 29/10, tra le 02:03 e le 09:30 ora italiana, un'installazione o un rientro con il codice di allora ha scritto null
   su tutto lo storico. Dal codice di oggi non si ricostruisce il primo anello. Altra ipotesi: FK `on delete set null` più un conto
   cancellato e ricaricato. La query 2 lo verifica.
- **Non c'entrano** la paginazione (209 righe, `fetchIds` paginato), l'archivio volatile, la base a tre vie (riguarda solo le cancellazioni)
  né la Protezione avanzata dell'account di prova (RLS: un altro `user_id` non tocca le righe di Matteo).
- La build di ieri sera era al massimo `175ccb0` (20:50). Nessun fix S-51 era dentro, ma nessuno l'avrebbe evitato.

## Copertura S-51
**Non coperta.** S-51/S-51d/e/g trattano archivio volatile, cancellazioni e conti cancellati altrove. Restano tre punti scoperti:
il pull inserisce senza conto in silenzio, il null remoto non viene mai segnalato né corretto, i movimenti scaricati vengono rimandati
sul server ("eco"). Correzione proposta (S-52b, iOS + Android):
1. **Niente eco:** i salvataggi fatti dal `download` non devono finire in `dirtyTransactionIds`. Solo le modifiche dell'utente o degli Intent
   restano sporche. Va fatto con un segnale di "applicazione remota" attivo durante il salvataggio del pull, verificato da un test.
2. **Auto-riparazione:** nel pull, se il remoto ha `account_id` null o sconosciuto, il locale ha un conto e la riga non è sporca, si tiene
   il locale, la si segna sporca (così il push corregge il server) e si scrive un avviso nel log. Prima va verificato che l'interfaccia non
   permetta di togliere il conto a un movimento: se lo permette, serve una regola diversa.
3. Se all'inserimento `sb.accountId` non c'è in `accountMap`, scrivere un avviso nel log (oggi diventa null in silenzio).

**Test (S-52c)** con `InMemoryRemote` su iOS e `03_CODICE/bucktrail-android/scripts/fake-supabase.py` per Android e la prova a due dispositivi.
Server con conto A, T1 (`account_id` null) e T2 (A). Il dispositivo D1 ha T1→A e T2→A, base registrata, niente sporchi.
- (a) D2 entra da zero, fa pull e poi push: il server **non riceve upsert** di T1/T2 (oggi li riceve: è la riproduzione dell'eco).
- (b) D1 fa pull: il server ha T1.account_id = A.
- (c) Poi D2 fa pull: T1 è collegato ad A e il saldo di A comprende T1.

## Verifica server (Matteo, SQL Editor di Supabase, sola lettura)
Sostituire `LA-TUA-EMAIL` con l'email dell'account vero.
```sql
-- 1) stato dei movimenti
with u as (select id from auth.users where email = 'LA-TUA-EMAIL')
select
  (select count(*) from mt_transactions t join u on t.user_id = u.id)                          as movimenti,
  (select count(*) from mt_transactions t join u on t.user_id = u.id where t.account_id is null) as senza_conto,
  (select count(*) from mt_transactions t join u on t.user_id = u.id
     where t.account_id is not null
       and not exists (select 1 from mt_accounts a where a.id = t.account_id))                   as conto_inesistente,
  (select count(*) from mt_accounts a join u on a.user_id = u.id)                                as conti,
  (select count(*) from mt_vault v join u on v.user_id = u.id)                                   as righe_cifrate,
  (select state from mt_e2e e join u on e.user_id = u.id)                                        as protezione,
  (select min(created_at)::text || ' → ' || max(created_at)::text
     from mt_transactions t join u on t.user_id = u.id where t.account_id is null)               as periodo_senza_conto;
-- 2) definizione della chiave esterna
select conname, pg_get_constraintdef(oid) from pg_constraint
where conrelid = 'public.mt_transactions'::regclass and contype = 'f';
```
**Risultato atteso** se la diagnosi è giusta: movimenti 209, senza_conto **126** (113 + 13 storici), conto_inesistente 0, conti 6,
righe_cifrate 0, protezione vuota, periodo 2026-09-02 → 2026-10-29. Se invece senza_conto = 13, il server è sano: **fermarsi** e
richiamare l'architetto. Se righe_cifrate > 0 o protezione non è vuota, i movimenti stanno cifrati nel vault (`account_id` dentro il payload,
`progetto-e2e-sync.md` §2) e l'UPDATE SQL non serve: fermarsi.

## Riparazione (S-52a, dopo l'esito della query)
1. **Script Python locale** (non nel repository: in `~/` o nella cartella temporanea). Prende in input i percorsi di `prima.json` e `dopo.json`. Costruisce la mappa
   movimento → id del conto: `accountName` di prima → `id` del conto con quel nome in prima, solo per i 113 che in dopo sono null.
   Controlla che gli id dei conti siano uguali in dopo. Scrive `riparazione.sql` **in Drive**, mai nel repository.
2. **SQL generato**, un'unica transazione:
   `begin;` · tabella temporanea `fix(tx_id uuid primary key, account_id uuid not null)` con i 113 valori ·
   blocco `do $$` che ricava `u` da `auth.users` via email e controlla tre cose, altrimenti `raise exception`, quindi niente commit:
   (i) 113 righe in `mt_transactions` con `id in fix`, `user_id = u` e `account_id is null`;
   (ii) tutti i 113 `account_id` esistono in `mt_accounts` con `user_id = u`;
   (iii) dopo `update … set account_id = f.account_id from fix f where t.id = f.tx_id and t.user_id = u and t.account_id is null`
   il numero di righe toccate è esattamente 113 ·
   `select` di controllo (senza_conto atteso 13) · `commit;`. Rieseguirlo non fa danni: dopo il primo giro tocca 0 righe e quindi si ferma al controllo (i).
3. **Ripartenza dei telefoni**, in quest'ordine:
   (a) **prima** dell'UPDATE, su ogni telefono collegato all'account vero: tirare giù per aggiornare una volta, così eventuali modifiche in coda partono subito. Poi non toccarli.
   (b) eseguire `riparazione.sql`.
   (c) su ogni telefono: tirare giù per aggiornare. Il pull ricollega i movimenti (`SyncService.swift:983`, Android `SyncMerge.kt:81`) e l'eco rimanda il conto giusto.
   (d) rilanciare la query 1: senza_conto deve essere 13. Se è risalito, rieseguire `riparazione.sql` e ripetere (c).
   Logout e login non servono e sono sconsigliati.
- Alternativa dall'app: ricollegare a mano i 113 movimenti dalla modifica del movimento. Funziona, perché ogni modifica è sporca e va sul server, ma è lunga e facile da sbagliare. Solo come ripiego.

## Divieti (fino a riparazione verificata)
- Non uscire dall'account e non reinstallare l'app su nessun telefono. Non entrare con l'account vero su dispositivi nuovi.
- Non accendere né spegnere la Protezione avanzata sull'account vero: copierebbe nel vault i null.
- Non modificare i movimenti vecchi (settembre-ottobre) e non ricollegarne qualcuno a mano "per prova": poi la verifica dei conteggi non torna.
- Non cancellare né spostare `prima.json`: è l'unica copia giusta dei collegamenti. Farne una copia in Drive.
- Movimenti nuovi: si possono aggiungere, nascono già col conto.
