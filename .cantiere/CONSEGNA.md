# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 10:24** · ramo `redesign-sentiero`
- **Task:** `S-73g` (rifinitura grafica card «Da confermare», iOS + Android)

## Fatto
1. **Pulsante «Conferma» solo icona ✓** (`MoneyTracker/Views/OverduePlannedMovements.swift`, `03_CODICE/bucktrail-android/.../OverduePlannedMovements.kt`): cerchio ambra `DS.plannedSoft`/`plannedText` (`32pt`/`32dp`) con spunta `checkmark`, area di tocco `≥44pt`/`48dp`, `accessibilityLabel`/`contentDescription` localizzata «Conferma» nelle 7 lingue (chiave esistente `"Conferma"` / `R.string.conferma`).
2. **Riga secondaria su una riga con data sempre visibile** (`MovementRow.swift`, `Basics.kt`, `OverduePlannedMovements.swift/.kt`): rimosso il conto dalla riga secondaria (come Movimenti) e separato il suffisso data (`metadataTail`/`metaTail`) non troncabile, così su iOS e Android mostra `Fissa · 15 ott` / `Fixkosten · 15 Okt.` su 1 sola riga senza tagliare la data.
3. **Card identica in Home e Movimenti iOS, allineata ad Android** (`OverduePlannedMovements.swift`, `DashboardView.swift`, `TransactionsView.swift`): introdotto `OverduePlannedSection` (Home) e `OverduePlannedCardBackground` / `OverdueCardBorderShape` (Movimenti `List` con swipe intatti), entrambi con `DS.surface` e bordo ambra `DS.planned.opacity(0.35)`.
4. **Icona categoria**: `resolvedCategorySymbol` / `resolvedCategoryIcon` usa l'icona della categoria del movimento, lasciando `circle.dotted` solo se manca la categoria.
5. **Conti archiviati esclusi**: `OverduePlannedMovements.isOverdue` esclude i movimenti di conti archiviati su iOS (`!(t.account?.isArchived ?? false)`) e Android (`archivedAccountIds` da `HomeScreen.kt` e `MovementsScreen.kt`), coperti da nuovi test in `OverduePlannedMovementsTests.swift` e `OverduePlannedMovementsTest.kt`.
6. **Giapponese**: aggiornato `未確認` → `確認待ち` in `MoneyTracker/ja.lproj/Localizable.strings` e `03_CODICE/bucktrail-android/app/src/main/res/values-ja/strings.xml`.

## Verifiche eseguite dopo l'ultima modifica
- **iOS unit test:** `MoneyTrackerTests` intero target (`-only-testing:MoneyTrackerTests`) → **258/258** test in 57 suite verdi (+ 1 XCTest `TwoDeviceLiveSyncTests` skipped).
- **iOS UI test:** `OverduePlannedUITests` (`Hotel Roma 2 notti`, categoria `Viaggi`) → **2/2** verdi in light (`testOverduePlannedWarningAndQuickConfirm` it-L + `testOverduePlannedGermanXL` de-XL) e **1/1** verde in dark (`testOverduePlannedWarningAndQuickConfirm`).
- **Android:** `./gradlew assembleDebug lintDebug testDebugUnitTest` → **368/368** test unitari verdi (0 falliti, 0 skip); `OverduePlannedUiTest` → **1/1** light e **1/1** dark verdi su emulatore `Bucktrail_API_36`.
- **Screenshot** in `.cantiere/tmp/s73g/`: `ios-home-light.png`, `ios-home-dark.png`, `ios-movimenti-light.png`, `ios-movimenti-dark.png`, `ios-home-de-xl-light.png`, `ios-movimenti-de-xl-light.png`, `android-home-light.png`, `android-home-dark.png`, `android-movimenti-light.png`, `android-movimenti-dark.png`.

## Fuori dal commit
- `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` (modificato preesistente, lasciato fuori come richiesto).
- `.cantiere/tmp/s73g/` (escluso da `.gitignore`, come `.cantiere/tmp/s73f/`).

## Prossimo
- Matteo esamina gli screenshot in `.cantiere/tmp/s73g/` + collaudatore verifica il diff `S-73g` (chiudendo `[x]` sia `S-73g` che `S-73f`), poi checkpoint completo.
