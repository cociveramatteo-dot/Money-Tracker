# CONSEGNA — collaudo SQL S-13f (563980d)

**Da:** collaudatore (Claude Code · Sonnet) · 2026-11-14 10:30

**Esito: OK** (solo lettura statica; SQL non eseguito, Sync non toccato).
- Colonne: 16 su 16 coerenti con `RecurringRule.swift` e piano-s13 (id, user_id, name, type, category, category_icon, notes, amount, is_fixed, account_id, frequency, start_date, end_date, exceptions, materialized_through, created_at). Nullable corretti: account_id, end_date, materialized_through.
- Decimal: `amount numeric` senza scala, nessun arrotondamento imposto; compatibile con DTO `Decimal` come `SBTransaction`.
- Permessi: REVOKE ALL a PUBLIC/anon/authenticated, GRANT CRUD solo ad authenticated; RLS attiva.
- Quattro policy proprietario `(SELECT auth.uid()) = user_id`; UPDATE con USING + WITH CHECK. Frequency con CHECK sulle 3 voci. FK user_id → auth.users ON DELETE CASCADE. Transazione con BEGIN/COMMIT, fallisce se la tabella esiste.
- Nota: nessun CHECK end_date >= start_date, voluto (serie vuota ammessa).
**Non verificato:** esecuzione reale e isolamento tra due utenti (dopo il Sync).

## Prossimo: Matteo, S-13e
📍 supabase.com/dashboard → progetto MoneyTracker → SQL Editor → New query
▶️ Incolla il blocco SQL di `.cantiere/PER-MATTEO.md` (sezione S-13e) e premi Run una volta sola
↩️ Riporta «S-13e fatto: rls_attiva = true, numero_policy = 4» oppure l'errore completo. Se la tabella esiste già, non cancellarla: riporta l'errore.
Poi: Codex implementa il Sync di S-13f (DTO, push, pull con max watermark, clearLocalData). Non provare il Sync in app prima della conferma S-13e. Restano obblighi S-13g (alert errori, 7 lingue).

## Aggiornamento 2026-11-14 10:27
S-13e [x]: Matteo ha eseguito l'SQL, esito rls_attiva = true, numero_policy = 4. Via libera a Codex per il Sync di S-13f; isolamento tra due utenti da provare dopo.
