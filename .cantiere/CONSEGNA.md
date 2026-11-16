# CONSEGNA — S-28 correzione dopo collaudo

**Da:** impresa (Codex · GPT-6), 2026-11-16 10:03. Ramo `redesign-sentiero`. Nessun push/merge.

## Correzione
Unico file app modificato: `MoneyTracker/Views/Components/FloatingTabBar.swift`.
- `lineLimit(1)` e `minimumScaleFactor(0.6)`; rimosso allineamento multilinea.
- Celle uguali, padding testo 4 pt, target touch, altezza minima 66 pt, font/token, identificatori, selezione e callback invariati. Nessuna zona intoccabile o test modificato.
- La precedente valutazione visiva di c23aeb8 era errata: il nome tedesco spezzato con “n” orfana era un difetto, non un risultato accettabile. Ora è corretto.

## Verifiche
- Build + **80 unit e 3 UI verdi**, TEST SUCCEEDED. UI 119,542 s. Log `/tmp/moneytracker-s28.log` (nuovo run, sostituisce il precedente).
- Risultato `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.16_10-00-04-+0100.xcresult`.
- Tre immagini nuove ispezionate: `/tmp/moneytracker-s28-fix-images/` (manifest e `tab-bars.png`). **de XL: Bewegungen completo su una riga, senza ellissi, senza lettera isolata e separato da Startseite/Statistiken.** Italiano L e XL: nomi completi e separati. Verifica su iPhone 18 Pro / iOS 27.2; non certificati altri dispositivi o tutte le taglie accessibilità.
- Test UI esistenti TabBarAppearanceUITests: tutte le cinque tab selezionabili/hittable, target >=44×44. Nessun test cambiato per la correzione.
- Comando: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/TabBarAppearanceUITests build test`.
- `git diff --check` verde. Grafo AST aggiornato senza LLM, lasciato fuori dal commit perché già modificato/non tracciato a inizio turno. Immagini e xcresult fuori da git.

## Prossimo
Ricollaudo indipendente S-28 → collaudatore Claude Code (Sonnet): solo diff del commit di correzione e queste evidenze, usare esclusivamente i nuovi screenshot in `/tmp/moneytracker-s28-fix-images/`. Solo collaudatore o Matteo porta a [x]. Poi Commissione S-13h da rivalutare; approvazione traduzioni Matteo ancora pendente. Nessun push/merge.
