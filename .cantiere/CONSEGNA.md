# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 00:32** · ramo `redesign-sentiero`
- **Task:** `S-72f` → segnato `[~]` in `.cantiere/PIANO.md`

## Fatto
- **iOS (`MoneyTracker/Views/StatisticsView.swift`):** aggiunto `@Environment(\.dynamicTypeSize)` e l'helper `categoryRowHeader(_:monthSpent:)`. Con `dynamicTypeSize.isAccessibilitySize` (incluso AX-XL) tutte le righe categoria impilano il nome categoria a larghezza piena sopra la riga `percentuale` + `importo` (con `minimumScaleFactor(0.6)` sull'importo). Alle dimensioni normali usa `ViewThatFits(in: .horizontal)` tra la riga singola originale e lo stesso layout impilato in caso di nomi lunghi o importi grandi. Nessun calcolo o modello toccato.
- **Android (`03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/ui/screens/StatisticsScreen.kt`):** estratti `CategoryStatHeader` e `CategoryStatHeaderStacked`. Con `LocalDensity.current.fontScale >= 1.5f` oppure quando `rememberTextMeasurer()` rileva che `nome + % + importo` non entra in `constraints.maxWidth`, il nome categoria viene impilato a larghezza piena sopra la riga `%` + `FitText(importo)`. Nessun calcolo toccato.
- **Test UI (`MoneyTrackerUITests/SentieroStatisticsUITests.swift`):** aggiunto `testGermanAXXL()` (`de`, `UICTContentSizeCategoryAccessibilityXL`, 2 swipe verso il basso per mostrare fino ad `Abonnements` / `Sonstiges` / `Gewohnheiten`), lasciando invariati i test esistenti.

## Verifiche eseguite dopo l'ultima modifica
- **iOS (`xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/SentieroStatisticsUITests/testGermanAXXL -resultBundlePath /tmp/mt-s72f.xcresult test`):**
  - `MoneyTrackerTests`: **247/247** passati in 54 suite Swift Testing (1 XCTest `TwoDeviceLiveSyncTests/testLiveSync` skipped perché richiede lo script a due dispositivi).
  - `SentieroStatisticsUITests/testGermanAXXL`: **1/1** passato (`TEST SUCCEEDED`).
- **Screenshot `de-axxl` estratti e ispezionati visivamente in `.cantiere/tmp/s72f/`:**
  - `de-axxl-statistiche-top.png`: `Zuhause` intero sopra `47%  809,00 €`.
  - `de-axxl-statistiche-12m.png`: vista 12M AX-XL.
  - `de-axxl-statistiche-bottom.png`: `Geschenke`, `Bildung`, `Abonnements`, `Sonstiges` interi sopra percentuale e importo, senza spezzature a metà parola (verificati anche `Essen`, `Einkaufen`, `Transport`, `Freizeit`, `Gesundheit` nel giro precedente sullo stesso codice app).
- **Android (`03_CODICE/bucktrail-android/gradlew -p 03_CODICE/bucktrail-android ...`):**
  - `assembleDebug`: verde.
  - `testDebugUnitTest --rerun`: **361/361** passati su 61 file XML (`failures=0`, `skipped=0`).
  - `lintDebug`: verde.

## Aperto / note per il collaudo
- Nessun rendering diretto su emulatore Android eseguito in questo turno per `StatisticsScreen.kt` (verificati compilazione, `lintDebug` e 361/361 test unitari JVM).
- `MoneyTracker.xcscheme` era già modificato in locale prima del turno: lasciato fuori dal commit come richiesto.
- Resta la prova reale `S-70d` in carico a Matteo.
