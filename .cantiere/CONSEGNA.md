# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 03:04** · ramo `redesign-sentiero`
- **Task:** `S-70h`, `S-73f` → entrambi segnati `[~]` in `.cantiere/PIANO.md` (un commit per task: `3014da4` per `S-70h`, commit `S-73f` in questo turno)

## Fatto

- **S-70h (`3014da4`, iOS + Android):**
  - Segnaposto importo in «E se…?»: cambiato `"0,00"` → `"0"` su iOS (`MoneyTracker/Views/WhatIf/WhatIfView.swift`) e Android (`WhatIfSheet.kt`) in linea con gli altri form importo dell'app.
  - Conteggio leggero conti in apertura modulo movimento (`MoneyTracker/Views/AddTransactionView.swift`): aggiunto `fetchAccountUsageCounts(for:context:)` con `FetchDescriptor<Transaction>` filtrato per `accountID` + `context.fetchCount(descriptor)` per i conti non archiviati invece del fetch dell'intera tabella `Transaction`; aggiunto test unitario `MoneyTrackerTests/AccountUsageCountTests.swift`.
- **S-73f (iOS + Android, opzione B):**
  - Calcoli invariati: i movimenti pianificati di mesi passati non confermati restano fuori da Home e Conti.
  - Segnalazione «Da confermare» riusando componenti e token ambrati Sentiero (`DS.plannedText`, `DS.plannedSoft`, `DS.planned` / `c.plannedText`, `c.plannedSoft`, `c.planned`, icone `clock` / `checkmark.circle.fill`) in **Home** (sopra «Ultimi movimenti») e in **Movimenti** (in cima al mese corrente, coerente coi filtri attivi), con conferma rapida a un tocco (`btn_confirmOverdue_<nome>`) e swipe «Conferma» / «Elimina».
  - Nuovi file UI: `MoneyTracker/Views/OverduePlannedMovements.swift`, `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/ui/OverduePlannedMovements.kt`; aggiornati `DashboardView.swift`, `TransactionsView.swift`, `HomeScreen.kt`, `MovementsScreen.kt`, `BucktrailApp.kt`.
  - Traduzioni in tutte e 7 le lingue (`it`, `en`, `de`, `es`, `fr`, `ja`, `zh-Hans`) su `Localizable.strings` e `strings.xml`.
  - Test nuovi: iOS unit `MoneyTrackerTests/OverduePlannedMovementsTests.swift`, iOS UI `MoneyTrackerUITests/OverduePlannedUITests.swift` (pianificato mese scorso → compare «Da confermare» → conferma rapida → sparisce e saldo attuale scala), Android JVM `OverduePlannedMovementsTest.kt`, Android Compose UI `OverduePlannedUiTest.kt`.

## Verifiche eseguite dopo l'ultima modifica

- **iOS (`MoneyTrackerTests`, senza `-only-testing` su singole suite):** `257/257` test Swift Testing passati su 57 suite (`** TEST SUCCEEDED **`, 1 XCTest `TwoDeviceLiveSyncTests` skipped).
- **iOS (`MoneyTrackerUITests/OverduePlannedUITests`):** passato `1/1` in light mode e `1/1` in dark mode (`iPhone 18 Pro`).
- **Android (`./gradlew assembleDebug lintDebug testDebugUnitTest --rerun`):** `BUILD SUCCESSFUL` (`assembleDebug` verde, `lintDebug` verde, `367/367` test unitari passati su 64 file XML con `failures=0`, `errors=0`, `skipped=0`).
- **Android (`OverduePlannedUiTest` su emulatore `Bucktrail_API_36`):** passato `1/1` in light e `1/1` in dark.
- **Screenshot light/dark (`S-73f`, per approvazione grafica di Matteo):**
  - `.cantiere/tmp/s73f/ios-home-light.png`
  - `.cantiere/tmp/s73f/ios-home-dark.png`
  - `.cantiere/tmp/s73f/ios-movimenti-light.png`
  - `.cantiere/tmp/s73f/ios-movimenti-dark.png`
  - `.cantiere/tmp/s73f/android-home-light.png`
  - `.cantiere/tmp/s73f/android-home-dark.png`
  - `.cantiere/tmp/s73f/android-movimenti-light.png`
  - `.cantiere/tmp/s73f/android-movimenti-dark.png`

## Aperto / note per il collaudo

- `MoneyTracker.xcscheme` era già modificato in locale prima del turno: lasciato fuori da tutti i commit.
- Su `android-home-light.png` lo scroll iniziale si è fermato sull'intestazione «To confirm 1» (la card completa light è comunque visibile in `android-movimenti-light.png`, e su Home in `android-home-dark.png`).
- Serve collaudo indipendente su `S-70h` e `S-73f` più approvazione grafica degli screenshot `.cantiere/tmp/s73f/` da parte di Matteo.
