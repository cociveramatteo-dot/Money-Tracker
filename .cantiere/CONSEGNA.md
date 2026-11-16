# CONSEGNA — S-27

**Da:** impresa (Codex · GPT-6), 2026-11-16 01:40. Ramo `redesign-sentiero`. Nessun push/merge.

## Modifiche
- DemoDataSeeder: eliminati tutti i sette force-unwrap con fallback per date/intervalli/categorie; interesse espresso come Decimal(275) / 100, identico valore esatto.
- MoneyTrackerApp: rimuove txFilterMin, txFilterMax e txFilterUseDates da UserDefaults esclusivamente all'avvio --uitesting. I workaround UI esistenti restano invariati per rispettare il vincolo sui test esistenti.
- Nuovo RecurringCollisionTests.swift: due copie settimanali spostate sullo stesso giorno mantengono ID distinti; verifica conteggio, stabilità ID dopo materializzazione e unicità nel calendario virtuale. Nessuna modifica ai test esistenti o alle zone intoccabili.

## Verifiche
- Unico run completo sequenziale: build + **80 unit verdi + 16/16 UI verdi**, TEST SUCCEEDED. UI 868,002 s, sessione test 905,913 s.
- Comando: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO build test`.
- Log `/tmp/moneytracker-s27.log`; risultato `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.16_01-24-07-+0100.xcresult`.
- Showcase: 52,870 s. Il timeout idle storico era nel testNonRecurringEditCannotCreateSeries (log S-26: idle da 12,40 a 2091,94 s, test totale 2107,964 s), non nello showcase. Ora lo stesso test passa in 22,802 s. Nessun messaggio “App event loop idle notification not received” nel run S-27. Causa non accertata: problema non riprodotto; non certificare una correzione prestazionale.
- Primo avvio del comando in sandbox fallito prima dei test per accesso ai cache Xcode; run completo eseguito dopo autorizzazione, senza rilanci mirati.
- git diff --check verde. Graphify AST aggiornato, nessun costo LLM; avvisa di 9 file JSON senza nodi (Contents.json e configurazioni), non di errori Swift.

## File esclusi
Tutto graphify-out/ era già modificato/non tracciato all'inizio. Aggiornato localmente, escluso interamente dal commit per non includere lavoro preesistente. Nessun altro file estraneo incluso.

## Prossimo
S-27 [~] → collaudatore Claude Code (Sonnet): leggere solo il diff del commit S-27 e queste evidenze, verificare fallback e isolamento reset filtri, test collisioni e full run. Solo collaudatore o Matteo può portare S-27 a [x]. Restano S-18/S-19 e Commissione S-13h; Statistiche/Pianifica/Conti ancora da allineare secondo task aperti. Nessun push/merge.
