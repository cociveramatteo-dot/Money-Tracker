# CONSEGNA — S-13f Sync Swift

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 10:33
**Stato:** S-13f [~], parte Swift pronta per collaudo sul ramo `redesign-sentiero`. S-13e già [x].

## Fatto
- `SyncService.swift`: DTO interno `SBRecurringRule` completo (16 colonne, Decimal, exceptions testuale, nullable serializzati come NULL espliciti); push completo + deleteOrphans con filtro utente; fetch locale throwing prima di avviare gli upload per non scambiare un errore per insieme vuoto.
- Pull delle regole con inserimento, aggiornamento di tutti i campi e cancellazione orfani; watermark = max(locale, remoto), con tutte le combinazioni nil coperte. Helper condiviso tra pull e test; save resta quello del pull.
- Logout: clearLocalData elimina anche RecurringRule. Nessuna vista, modello, logica Domain, tabella remota o test preesistente modificato.
- Quattro nuovi test in `RecurringRuleSyncTests.swift`: DTO/CodingKeys/Decimal/eccezioni/NULL, nove combinazioni watermark, merge inserimenti/aggiornamenti/orfani/pull vuoto, logout.

## Verifica
- Build e **64 unit test verdi** (60 precedenti + 4 nuovi). Log: `/tmp/moneytracker-s13f-recheck.log`; xcresult: `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.14_10-32-48-+0100.xcresult`.
- Prima esecuzione: 63/64, confronto importo/eccezioni dopo persistenza ad alta precisione fallito. DTO con `123.4567890123456789` verde; test merge finale usa `0.2`. Diagnosi distinta **S-16**, non risolta né nascosta: isolare campo e differenza prima di attribuire causa a SwiftData. Log `/tmp/moneytracker-s13f.log`.
- `git diff --check` pulito. UI non eseguiti: nessuna vista modificata; difetti noti S-15 restano aperti.
- Grafo aggiornato AST senza LLM. Graphify segnala 9 file JSON senza nodi (tra cui configurazioni e Contents.json). Backup automatico `graphify-out/2026-11-14/` escluso dal commit; tutti i file inizialmente erano puliti.

## Non verificato / aperto
- Nessuna chiamata verso il Supabase reale: prova tra due dispositivi e isolamento fra due utenti ancora da eseguire dopo il collaudo; S-13f non è [x].
- S-16 precisione elevata da diagnosticare; S-13g UI/alert/avvii materializer e sette lingue ancora aperto. Non cambiare dati o schema per aggirare la verifica.

## Prossimo: collaudatore — Claude Code · Sonnet
Prompt: «Prendi il turno secondo AGENTS.md §4, leggi CONSEGNA.md. Collauda solo il diff dell'ultimo commit [seconda impresa] implementa Sync ricorrenze (S-13f), confrontandolo con .cantiere/piano-s13.md: DTO completo, NULL, Decimal/eccezioni, upsert/deleteOrphans filtrati per utente, pull con watermark max, cancellazione regole al logout e nuovi test. Build e 64 unit verdi nel log indicato. Non dichiarare verificata la rete: prova fra dispositivi e isolamento utenti non eseguiti. Esamina la scoperta S-16 senza modificare modelli o viste. Aggiorna piano e consegna, chiudi turno col cartellino. Dopo il collaudo organizza la prova reale necessaria per chiudere S-13f.»
