# PER MATTEO — le cose che aspettano te

Le scrivono le IA del cantiere, sempre con istruzioni complete (AGENTS.md §6.13). Quando una è fatta, la spostano
in "Fatte" con la data. `riprendiamo` e il checkpoint te le ricordano, in ordine.

## Da fare

### S-26 — avviare il collaudo indipendente
📍 Claude Code, nuova sessione nella cartella `/Users/matteo/Desktop/APP/MoneyTracker`.
▶️ Incolla:
```text
Collauda S-26 Demo vetrina sul ramo redesign-sentiero. Leggi STATO e CONSEGNA, poi solo il diff dell'ultimo commit [impresa] demo vetrina (S-26). Verifica requisiti di PIANO, invarianti delle zone intoccabili, reset senza duplicati, vere regole/override/effettuato, sette lingue e le evidenze dei 79 unit + 4 UI finali verdi. Dieci screenshot e xcresult sono indicati in CONSEGNA; confronta col DESIGN_HANDOFF tenendo separati i task grafici già aperti. Non modificare i test esistenti per farli passare. Solo con esito positivo porta S-26 da [~] a [x] con data/esito. Chiudi secondo AGENTS.md. Nessun push o merge.
```
↩️ Riporta l'esito del collaudo oppure i problemi trovati.

### S-23 — controllo manuale editor singola occorrenza
📍 Simulator Xcode, MoneyTracker, scheda Movimenti.
▶️ (1) Crea un movimento Mensile, salvalo: accanto al titolo deve esserci una piccola icona repeat grigia. (2) Toccalo una volta: si apre l'editor normale, senza selettore ricorrenza; cambia importo e categoria, salva: cambia solo quella copia. (3) Tienilo premuto: compaiono «Ricorrenza» (con icona) ed «Elimina»; «Ricorrenza» apre l'editor della serie. (4) Apri un movimento non ricorrente: nessun selettore di ricorrenza.
↩️ Riporta «S-23 manuale OK» oppure cosa non torna.

### S-21 — controllo manuale menu dopo il collaudo
📍 Simulator Xcode, MoneyTracker, scheda Movimenti (dati demo).
▶️ Crea un movimento con ricorrenza Mensile, salva, tieni premuta la sua riga e tocca «Ricorrenza»: deve aprirsi l’editor con «Ambito». Se Simulator è bloccato, chiudilo con ⌘Q e riaprilo da Xcode → Open Developer Tool → Simulator; poi rilancia l’app con ▶︎ in Xcode.
↩️ Riporta «S-21 manuale OK» oppure cosa compare nel menu. Test automatico della stessa pressione prolungata già verde; controllo manuale non disponibile a Codex perché CUA non accede a Simulator.

### ✅ FATTA 2026-11-14 10:27 · S-13e — Creare `mt_recurring_rules` (SQL preparato in S-13f)

📍 Apri https://supabase.com/dashboard, scegli il progetto **MoneyTracker**, poi **SQL Editor → New query**.
▶️ Copia tutto il blocco SQL qui sotto e premi **Run** una sola volta. Non servono modifiche o credenziali nel testo.
↩️ Riporta «S-13e fatto: rls_attiva = true, numero_policy = 4», oppure copia l'errore completo. Se la tabella esiste già, fermati e riporta l'errore: non cancellarla. Se la query fallisce e resta una transazione aperta, esegui `ROLLBACK;` prima di altre query.

```sql
-- S-13e: eseguire una sola volta nel progetto Supabase di MoneyTracker.
-- Se la tabella esiste già, CREATE TABLE fallisce senza modificarla.
-- Non convertire lo storico e non modificare mt_transactions.
BEGIN;

CREATE TABLE public.mt_recurring_rules (
    id uuid PRIMARY KEY,
    user_id uuid NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name text NOT NULL,
    type text NOT NULL,
    category text NOT NULL,
    category_icon text NOT NULL,
    notes text NOT NULL DEFAULT '',
    amount numeric NOT NULL,
    is_fixed boolean NOT NULL DEFAULT false,
    account_id uuid,
    frequency text NOT NULL CHECK (frequency IN ('mensile', 'settimanale', 'annuale')),
    start_date timestamptz NOT NULL,
    end_date timestamptz,
    exceptions text NOT NULL DEFAULT '{}',
    materialized_through timestamptz,
    created_at timestamptz NOT NULL DEFAULT now()
);

-- account_id resta un UUID opzionale, senza relazione/FK, come nel modello.
-- Nessun vincolo end_date >= start_date: l'editor può chiudere una serie vuota.
-- numeric senza precisione/scala evita arrotondamenti imposti dal database.
CREATE INDEX mt_recurring_rules_user_id_idx
    ON public.mt_recurring_rules (user_id);

ALTER TABLE public.mt_recurring_rules ENABLE ROW LEVEL SECURITY;
REVOKE ALL ON TABLE public.mt_recurring_rules FROM PUBLIC, anon, authenticated;
GRANT SELECT, INSERT, UPDATE, DELETE ON TABLE public.mt_recurring_rules TO authenticated;

CREATE POLICY mt_recurring_rules_select ON public.mt_recurring_rules
    FOR SELECT TO authenticated
    USING ((SELECT auth.uid()) = user_id);
CREATE POLICY mt_recurring_rules_insert ON public.mt_recurring_rules
    FOR INSERT TO authenticated
    WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY mt_recurring_rules_update ON public.mt_recurring_rules
    FOR UPDATE TO authenticated
    USING ((SELECT auth.uid()) = user_id)
    WITH CHECK ((SELECT auth.uid()) = user_id);
CREATE POLICY mt_recurring_rules_delete ON public.mt_recurring_rules
    FOR DELETE TO authenticated
    USING ((SELECT auth.uid()) = user_id);

COMMIT;

-- Risultato atteso: rls_attiva = true, numero_policy = 4.
SELECT c.relrowsecurity AS rls_attiva,
       (SELECT count(*) FROM pg_policies
        WHERE schemaname = 'public' AND tablename = 'mt_recurring_rules') AS numero_policy
FROM pg_class c
JOIN pg_namespace n ON n.oid = c.relnamespace
WHERE n.nspname = 'public' AND c.relname = 'mt_recurring_rules';
```

La verifica finale controlla struttura RLS e numero di policy; l'isolamento tra utenti e il sync in app restano da collaudare dopo l'implementazione Sync di S-13f. Nessun SQL è stato eseguito dall'IA. Non provare il nuovo Sync prima che S-13e sia confermato.
Riferimento per policy e permessi: [documentazione ufficiale Supabase RLS](https://supabase.com/docs/guides/database/postgres/row-level-security).

- [ ] 2026-11-14 09:29 · Avviare collaudo S-13a/b/c. 📍 Claude Code · Sonnet nella cartella `/Users/matteo/Desktop/APP/MoneyTracker`. ▶️ Incollare:
  ```text
Entra in turno secondo AGENTS.md §4 solo se STATO è libero. Sul ramo redesign-sentiero collauda S-13a/b/c, senza iniziare S-13d: leggi CONSEGNA, schede S-13/S-15, piano-s13.md e D-008/D-009; per il codice leggi solo il diff dei commit 25b1b6e e dc58891 (git diff 0a76000..dc58891 -- MoneyTracker MoneyTrackerTests). Controlla calculator/UUIDv5/Decimal, migrazioni V1→V2→V3 senza conversioni legacy, mainContext/watermark/limite 36 mesi, idempotenza e copie fatte invariate, avvii dopo sync e spegnimento del vecchio motore. Le prove registrate sono build e 48 unit verdi; tutti i 12 UI sono stati eseguiti sullo stesso codice in due sessioni, 10 verdi e due falliti già noti S-15 (stress riga55 e senza-categoria riga68). Nuovo log dei sei UI ripresi: /tmp/moneytracker-s13c-ui-resume.log; gli altri log sono in CONSEGNA. Nessuna asserzione o vista è stata modificata per aggirare i difetti; diagnostica S-15 senza correzioni fuori perimetro. Rimangono solo cinque riferimenti al vecchio actor nei commenti di file fuori perimetro, rimandati a S-13h. Segna [x] solo se il tuo collaudo lo giustifica, altrimenti registra difetti precisi e lascia [~]. Chiudi con documenti, commit mirato e STATO libero. Dopo il collaudo, prossimo sviluppo: S-13d (editor degli ambiti) a Codex.
  ```
  ↩️ Riportare cartellino ed eventuali difetti del collaudatore; poi si assegna S-13d a Codex.
- [ ] 2026-11-13 · Segnalazione attrezzi (S-5, Codex). 📍 Nella chat «Azienda», incollare:
  ```text
  Nel cantiere MoneyTracker il controllo CUA dell'app Simulator va in timeout. xcodebuild compila (BUILD SUCCEEDED) ma il runner non avvia i test sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48: DTServiceHubClient / com.apple.instruments.deviceservice.lockdown non disponibile. Anche dopo shutdown/boot il problema persiste. Verificare il collegamento tra strumenti Codex e simulatore; non modificare codice o test per aggirare il problema.
  ```
  ↩️ Riportare al collaudatore la risposta o la conferma del ripristino. (Codex)
<!-- - [ ] AAAA-MM-GG · cosa · 📍 dove · ▶️ comando o testo esatto · ↩️ cosa riportare · (chi l'ha chiesto) -->

## Fatte

- 2026-11-14 · Collaudo S-12 completato dal collaudatore (01:30, [x]); rimossa richiesta già eseguita.

- 2026-11-14 09:29 · Ripresa Codex completata: eseguiti i sei UI rimasti, note di sospensione sostituite con esito e istruzioni di collaudo.

## S-24 — verifica del blocco sul caso reale
- [ ] 📍 Sull'iPhone o sul simulatore dove avveniva il blocco, con la versione contenente le modifiche S-24/S-25. ▶️ Aprire Movimenti, tenere premuto il movimento ricorrente che si bloccava, scegliere Elimina (oppure Ricorrenza), poi Tutte e confermare. Verificare che l'app risponda passando alla tab Home. L'eliminazione conserva le copie già effettuate.
  ↩️ Riportare questo testo compilato, senza dati personali:
```text
Dispositivo: iPhone / simulatore. Avvio: da icona / da Xcode.
Il blocco su Tutte si ripresenta: sì / no.
Copia: pianificata / già effettuata. Data iniziale serie: …
Se sì: app si chiude / resta ferma / Xcode evidenzia una riga (quale: …).
```
- Autorizzazioni Domain S-24/S-25 e test S-15 ricevute il 2026-11-15; nessuna autorizzazione ulteriore pendente. Già effettuato resta della singola copia (D-010).
