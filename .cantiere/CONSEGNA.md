# CONSEGNA — S-21 fix menu

**Da:** seconda impresa (Codex · GPT-6), 2026-11-14 11:45.
- Ramo `redesign-sentiero`. RecurrenceContextMenu risolve nel body senza State/onAppear/onDisappear. Domain/ intatto.
- Cache: fuso passabile con default `.current` per test deterministico senza alterare il fuso globale. Nuovo unit test su modifica regola, intervallo, fuso e rimozione regole.
- UI esistente esteso: crea serie, pressione prolungata sul movimento, verifica Ricorrenza, apre editor, poi modifica/elimina serie.
- **Build + 69 unit + 1 UI verdi**, TEST SUCCEEDED, exit 0. Log completo conservato in `.cantiere/tmp/s21-fix-test.log` (ignorato da Git) e `/tmp/moneytracker-s21-fix-verified.log`.
- Risultati Xcode: `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Test-MoneyTracker-2026.11.14_11-42-52-+0100.xcresult`.
- Comando: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/RecurrenceFlowUITests test`.
- Primo tentativo sandbox senza accesso CoreSimulator: log `/tmp/moneytracker-s21-fix.log`; riesecuzione autorizzata fuori sandbox completata, nessun riavvio necessario.
- Verifica manuale NON eseguita: CUA restituisce Invalid app per Simulator, anche con percorso completo. Copertura della pressione prolungata verificata dal test UI; controllo manuale rimane da fare.
- Grafo aggiornato; modifiche preesistenti e nuove a `graphify-out/` lasciate fuori dal commit come richiesto.
- Prossimo: collaudatore (Claude Code · Sonnet), solo diff del commit S-21 + log; non chiudere S-21 prima del controllo manuale.
