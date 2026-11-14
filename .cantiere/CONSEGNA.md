# CONSEGNA — collaudo S-13f

**Da:** collaudatore (Claude Code · Sonnet) · 2026-11-14 10:40 · commit esaminato: cff65f7
**Esito:** parte Swift **ok**, nessun difetto bloccante. S-13f resta [~].

## Verificato (leggendo il diff e il log dei test)
- DTO `SBRecurringRule`: 16 colonne = tabella SQL di S-13e; CodingKeys snake_case; `amount` Decimal; `exceptions` testuale; frequency (mensile/settimanale/annuale) coerente col CHECK SQL e col calcolatore.
- NULL: encode esplicito di account_id, end_date, materialized_through (coperto da test).
- Push: upsert completo + `deleteOrphans` con filtro `user_id`; fetch locale throwing (un errore non diventa «insieme vuoto»). Come per i budget.
- Pull: merge inserisce/aggiorna/cancella; watermark = max(locale, remoto), 9 combinazioni testate.
- Logout: `clearLocalData` cancella le regole (test).
- Log `/tmp/moneytracker-s13f-recheck.log`: 64 test, TEST SUCCEEDED. `git status` pulito (solo backup graphify non tracciato). Nessuna vista/modello/test preesistente toccato.

## Solo test locali, NON provato
- Nessuna chiamata al Supabase reale: né push/pull veri, né isolamento RLS tra due utenti, né due dispositivi. I test sono in memoria.
- Oggi non c'è UI per creare/vedere regole (S-13g): la prova reale con l'app non è eseguibile prima.

## Aperto
- **S-16:** il confronto fallito era l'importo a 19 cifre (non exceptions); ipotesi SwiftData/Decimal non verificata; impatto pratico basso. Serve un test diagnostico (vedi PIANO).
- **S-17 (nuovo):** il pull di `syncOnLogin` (stesso utente) può cancellare regole locali mai spedite. Decisione di Matteo/Codex.
- S-13g UI/alert/avvii materializer/sette lingue.

## Prossimo
Codex: S-13g (dopo S-12 su TransactionsView) e, se Matteo accetta, S-17. La prova reale si fa dopo S-13g: due dispositivi (o simulatore + iPhone) con lo stesso account, creare una regola su A, controllare su B dopo il pull; poi secondo account per l'isolamento.
