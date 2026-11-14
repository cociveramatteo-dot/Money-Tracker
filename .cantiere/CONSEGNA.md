# CONSEGNA — S-13f: sola preparazione SQL per S-13e

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 10:18 · ramo `redesign-sentiero`

Su richiesta di Matteo è stata preparata soltanto la parte SQL di S-13f. Blocco completo e istruzioni autosufficienti in `.cantiere/PER-MATTEO.md`, sezione S-13e.

SQL: nuova `public.mt_recurring_rules`, 16 colonne coerenti con RecurringRule e piano-s13.md; importo numeric senza scala imposta, exceptions text, date timestamptz, account_id opzionale senza FK; user_id riferito ad auth.users con cancellazione delle sole regole dell'utente eliminato. Indice user_id, RLS attiva, grant CRUD ad authenticated, nessun accesso anonimo, quattro policy proprietario con USING/WITH CHECK per UPDATE. Creazione in transazione; se la tabella esiste, fallisce senza sovrascriverla. Nessuna modifica o conversione dello storico.

**Verificato:** confronto statico con modello e piano tecnico; 16 colonne, quattro policy CRUD e predicati proprietario controllati con script locale; `git diff --check` pulito. Riferimento RLS: https://supabase.com/docs/guides/database/postgres/row-level-security.
**Non verificato:** esecuzione PostgreSQL/Supabase e isolamento tra due utenti; nessun database contattato. Nessuna build/test iOS necessaria: nessun codice Swift modificato.

## Prossimo
Collaudatore: verificare il solo diff documentale SQL di questo turno; poi Matteo esegue S-13e seguendo PER-MATTEO e riporta l'esito. S-13f resta [ ]: DTO/push/pull/clearLocalData, test e prova in app ancora da fare. La sola parte SQL è pronta, da collaudare.

## Obblighi conservati dalla precedente consegna
S-13d collaudato [x], 60 unit verdi da log. In S-13g collegare RecurrenceOperationStatus.errorMessage a un alert e instradare anche gli errori degli avvii del materializer. Localizzare errorDescription/testi di stato nelle 7 lingue. Note minori: termine sulla prima occorrenza può lasciare una serie vuota con fine < inizio (SQL lo consente); modifica tutte con nuova ancora azzera eccezioni e può affiancare pianificata nuova a copia già fatta. S-15 rimane aperto per i due fallimenti UI preesistenti.

**File estranei modificati:** nessuno rilevato all'inizio; nessun file applicativo modificato. Le vecchie richieste in PER-MATTEO sono state lasciate intatte perché fuori perimetro.
