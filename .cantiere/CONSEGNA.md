# CONSEGNA — S-28

**Da:** impresa (Codex · GPT-6), 2026-11-16 09:57. Ramo `redesign-sentiero`. Nessun push/merge.

## Modifica
FloatingTabBar.swift: celle flessibili con minWidth 0 per distribuire equamente lo spazio; margine orizzontale di 4 pt sulle etichette; fino a due righe centrate per i nomi lunghi. La prima prova con una sola riga separava correttamente l'italiano ma abbreviava Bewegungen in tedesco XL: rilevato negli screenshot e corretto prima della verifica finale.
ContentView letto ma invariato. Stessi font/token, cinque destinazioni, indici di selezione, identificatori, azioni e altezza minima; nessuna modifica alle zone intoccabili o ai test esistenti.
Nuovo TabBarAppearanceUITests.swift: verifica cinque tab selezionabili e hittable, touch target >=44×44, screenshot italiano L, italiano XL e tedesco XL.

## Verifiche finali
- Build + **80 unit e 3 UI verdi**, TEST SUCCEEDED. Test UI 89,869 s. Log `/tmp/moneytracker-s28.log`.
- Risultato `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.16_09-54-05-+0100.xcresult`.
- Tre immagini finali ispezionate in `/tmp/moneytracker-s28-final-images/` (manifest e `tab-bars.png` con ritagli affiancati): italiano L e XL separati e senza troncamenti; tedesco XL mostra il nome completo su due righe, senza ellissi. Verificato su iPhone 18 Pro / iOS 27.2; non certificati tutti i dispositivi o tutte le dimensioni accessibilità.
- Primo run (80+3 verdi) aveva mostrato troncamento tedesco, quindi sostituito dal run finale sul codice corretto. Le immagini in `/tmp/moneytracker-s28-images/` sono intermedie e non vanno usate per collaudo finale.
- Comando finale: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/TabBarAppearanceUITests build test`.
- Avvio sandbox fermato sui cache Xcode, rieseguito autorizzato. Esportazione xcresult autorizzata perché aggiorna database esterno al cantiere.
- git diff --check verde; graphify AST aggiornato senza LLM. Screenshot e xcresult fuori da git.

## File esclusi
Tutto graphify-out/ già modificato/non tracciato all'inizio, aggiornato localmente e lasciato fuori dal commit. Nessun altro lavoro estraneo incluso.

## Prossimo
Collaudo indipendente S-28 → collaudatore Claude Code (Sonnet): leggere solo il diff del commit S-28 e queste evidenze, confrontare tre screenshot finali, verificare separazione etichette, nomi completi, target touch e selezione invariata. Solo collaudatore o Matteo porta S-28 a [x]. Poi rivalutazione sei giudici Commissione S-13h; approvazione traduzioni Matteo ancora pendente. Nessun push/merge. Commissione non eseguita in questo turno.
