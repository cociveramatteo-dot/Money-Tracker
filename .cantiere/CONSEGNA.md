# CONSEGNA — S-52b/c · Movimenti scollegati dal conto

## Cosa abbiamo trovato

- Un upsert dello stesso ID aggiorna il conto. Nel codice storico del 29 ottobre (commit `08dedf8`), il push faceva invece un DELETE degli orfani remoti subito dopo l'upsert dei conti, prima di sincronizzare i movimenti. Una copia locale incompleta seguita da un push con i conti di nuovo presenti può quindi produrre esattamente l'effetto osservato con `ON DELETE SET NULL`. I log dell'incidente non permettono di identificare quale dispositivo o evento iniziale abbia fatto partire quel DELETE.
- Logout e cambio utente svuotano la copia locale. Sul ramo attuale Android può fare un push prima del logout, e iOS lo fa quando ha modifiche in coda. Valgono le nuove guardie anche in questi casi. L'attivazione della Protezione avanzata rimuove le copie in chiaro solo dopo verifica del vault e comincia dalle tabelle dipendenti.
- S-51g continua a propagare la cancellazione effettiva dell'ultimo conto. Se il server ha ancora il movimento, i client lo conservano e gli applicano il conto remoto, anche quando è vuoto. Se una risposta parziale mostra movimenti ancora collegati a un conto locale assente dall'elenco remoto, il client conserva quel conto.

## Comportamento dei client

- Il push ordinario richiede una scelta esplicita per cancellare un conto. Prima sincronizza le cancellazioni dei movimenti previste dalla base. Un riferimento ancora presente blocca il DELETE del conto.
- Il pull iOS esclude il proprio salvataggio dall'osservazione dei cambiamenti e dal push automatico. Android usa la finestra silenziosa e riallinea il watcher. D2 appena entrato non rimanda né T1 né T2.
- D1 può riparare il collegamento di T1 se conserva il conto locale e quel conto esiste sul server. La scrittura condizionale tocca soltanto `account_id`. D2 lo riceve al pull successivo. Un errore temporaneo lascia il collegamento locale per riprovare al pull seguente.
- Il trigger sotto registra da quel momento le scritture esplicite del conto vuoto. I null preesistenti restano indistinguibili nel database: la riparazione richiede una copia locale collegata e un conto ancora remoto. I client sono compatibili con il vecchio schema e avviano la riparazione solo quando ricevono il nuovo marcatore. Nei dati cifrati non esiste la FK in questione.

## Verifiche

- Android: `assembleDebug lintDebug testDebugUnitTest` completato con 335 test unitari verdi, compreso il test HTTP con il server Python. Il report di `connectedDebugAndroidTest` contiene 11 passati e 6 saltati per configurazione.
- Server finto Python: 19/19. Lo scenario S-52 con due client riproduce il DELETE e la ricreazione con lo stesso ID. Verifica anche assenza di upsert di T1/T2, ricollegamento, saldo e S-51g. SQL eseguito solo su PostgreSQL locale con verifica FK, RLS e cancellazione completa dell'utente.
- iOS: build Release e build Debug completate. Il primo test a due dispositivi ha fallito le tre asserzioni di recupero prima della correzione e ha passato lo scenario dopo. Il giro unitario finale e i test UI sono stati fermati su richiesta di Matteo. Le nuove varianti iOS di S-51g e della cancellazione esplicita vanno ancora confermate con il giro finale.
- Il giro unitario finale ha riprodotto l'asserzione già incoerente con HEAD in `E2EGateTests.swift:174`: la sequenza attesa omette il `fetchIds(.accounts)` già introdotto da S-51d. Il test è rimasto invariato. I problemi di interop/golden del primo giro sono stati corretti nel codice, da riconfermare con la nuova build.
- Per ripartire in Xcode sulla macchina del cantiere, dalla root:
  ```sh
  xcodebuild -scheme MoneyTracker -configuration Debug -destination 'id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO build test
  ```
  Per una conferma rapida delle regressioni prima del giro completo, aggiungi `-only-testing:MoneyTrackerTests/SyncAccountLinkTests -only-testing:MoneyTrackerTests/SyncRemoteGoldenTests -only-testing:MoneyTrackerTests/E2ERowInteropTests`. Log di lavoro in `/tmp/moneytracker-s52-ios*.log`.
- Le modifiche preesistenti in `MoneyTracker.xcscheme` e `StatisticsView.swift` sono fuori dal commit. Grafo aggiornato localmente, fuori dal commit.

## SQL per Matteo dopo il collaudo

📍 Apri il progetto Bucktrail nel dashboard Supabase, entra in **SQL Editor → New query**. ▶️ Copia il blocco qui sotto per intero e premi **Run**. ↩️ Riporta il messaggio di esito. Il blocco interrompe la transazione se la FK di partenza differisce dalla definizione verificata. La FK differibile verifica a fine transazione che non restino movimenti orfani e consente la cancellazione completa dell'utente in un'unica transazione. [Documentazione PostgreSQL](https://www.postgresql.org/docs/18/ddl-constraints.html)

```sql
begin;

alter table public.mt_transactions
  add column account_link_cleared boolean not null default false;

-- Conserva le colonne e le altre opzioni della FK esistente.
do $$
declare
  definition text;
begin
  select pg_get_constraintdef(oid) into strict definition
  from pg_constraint
  where conrelid = 'public.mt_transactions'::regclass
    and conname = 'mt_transactions_account_id_fkey'
    and contype = 'f' and not condeferrable;

  if definition !~ 'ON DELETE SET NULL' then
    raise exception 'Definizione inattesa: %', definition;
  end if;

  alter table public.mt_transactions drop constraint mt_transactions_account_id_fkey;
  execute 'alter table public.mt_transactions add constraint mt_transactions_account_id_fkey '
    || replace(definition, 'ON DELETE SET NULL', 'ON DELETE NO ACTION')
    || ' DEFERRABLE INITIALLY DEFERRED';
end;
$$;

create function public.mt_track_account_link() returns trigger
language plpgsql set search_path = ''
as $$
begin
  new.account_link_cleared := new.account_id is null;
  return new;
end;
$$;

create trigger mt_track_account_link
before insert or update of account_id, account_link_cleared
on public.mt_transactions
for each row execute function public.mt_track_account_link();

create function public.mt_repair_transaction_accounts(links jsonb) returns void
language sql security invoker set search_path = ''
as $$
  update public.mt_transactions as t
     set account_id = a.id
    from jsonb_each_text(links) as requested(transaction_id, account_id)
    join public.mt_accounts as a
      on a.id = requested.account_id::uuid and a.user_id = auth.uid()
   where t.id = requested.transaction_id::uuid and t.user_id = auth.uid()
     and not t.account_link_cleared
     and (t.account_id is null or not exists (
       select 1 from public.mt_accounts as existing
       where existing.id = t.account_id and existing.user_id = t.user_id
     ));
$$;

revoke all on function public.mt_repair_transaction_accounts(jsonb) from public, anon;
grant execute on function public.mt_repair_transaction_accounts(jsonb) to authenticated;
notify pgrst, 'reload schema';

commit;
```

## Prossimo turno

Collaudatore indipendente su S-52b/c. Verificare dal diff e con i test per cancellazione esplicita del conto, S-51g, assenza di eco, sottostato cifrato e RPC condizionale con il server finto. Poi Matteo può applicare l'SQL dal proprio SQL Editor.
