# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 11:19** · ramo `redesign-sentiero`
- **Task:** `S-73i` + 2 proposte della Commissione Suprema 2026-11-28 (pulizia `countsInProjection`, cache prestazioni iOS)

## Fatto
1. **`S-73i` — Interruttore «Già effettuato» per pianificati scaduti (`368d824`):**
   - **iOS** (`MoneyTracker/Views/AddTransactionView.swift`): aggiunto `@State private var wasPlannedOnOpen = false`, valorizzato in `load()` (`!t.isDone` in modifica, `false` in creazione, senza toccare `isDone`), ed estratto `shouldShowDoneToggle(isFixed:date:wasPlannedOnOpen:...)` usato al posto di `isFixed || Self.isFutureDate(date)`.
   - **Android** (`03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/ui/forms/AddTransactionForm.kt`): aggiunto `val wasPlannedOnOpen = rememberSaveable(existing?.id) { existing?.isDone == false }` e `shouldShowDoneToggle(fixed, date, today, wasPlannedOnOpen)`.
   - **Test nuovi:** `MoneyTrackerTests/AddTransactionDoneToggleTests.swift`, `MoneyTrackerUITests/OverduePlannedFormUITests.swift`, `03_CODICE/bucktrail-android/app/src/test/java/com/bucktrail/android/ui/forms/AddTransactionFormDoneToggleTest.kt`.
2. **Pulizia — Regola previsione in helper neutro (`d86d015`):**
   - Spostata la logica `countsInProjection` in `MoneyTracker/Views/ProjectionRules.swift` (`enum ProjectionRules`, fuori da `Domain/`).
   - Aggiornati i chiamanti in `MoneyTracker/Views/MonthlyPlannedBalance.swift` e `MoneyTracker/Views/DashboardView.swift` (lasciata in `DashboardView` solo una delega di una riga per non toccare il test esistente `ProjectionMonthTests.swift`).
   - Aggiunto `MoneyTrackerTests/ProjectionRulesTests.swift`.
3. **Prestazioni iOS — Memorizzazione previsioni e «Da confermare»:**
   - `MoneyTracker/Views/MonthlyPlannedBalance.swift` (`MonthlyPlannedBalance.Cache`) + `MoneyTracker/Views/AccountsView.swift`: memorizzato `expectedByID` per fingerprint su `projectionDay`, `accounts`, `currentBalance` e `transactions`.
   - `MoneyTracker/Views/OverduePlannedMovements.swift` (`ListCache` e `FilteredCache`) + `MoneyTracker/Views/DashboardView.swift` + `MoneyTracker/Views/TransactionsView.swift`: memorizzata la scansione `overduePlanned` (e i relativi filtri in Movimenti, con `projectionDay` aggiornato su `scenePhase`/mezzanotte).
   - Aggiunto `MoneyTrackerTests/ProjectionAndOverdueCacheTests.swift`.

## Verifiche eseguite dopo l'ultima modifica
- **iOS unit test:** intero target `MoneyTrackerTests` → **265/265** test in 60 suite verdi (+ 1 XCTest `TwoDeviceLiveSyncTests` skipped).
- **iOS UI test:** `FutureTransactionPlannedUITests` (**2/2**), `OverduePlannedFormUITests` (**1/1**), `OverduePlannedUITests` (**2/2**) → **5/5** verdi (`** TEST SUCCEEDED **`).
- **Android:** `./gradlew assembleDebug lintDebug testDebugUnitTest` → **370/370** test unitari in 65 suite verdi (0 falliti, 0 skip).
- **Zone intoccabili rispettate:** `Domain/`, `Models/`, `Sync/`, `Auth/`, `Intents/`, `Export/`, `Formatting/` e test esistenti non modificati.

## Fuori dal commit (lasciato intenzionalmente)
- `.cantiere/STATO.md` (checkpoint in corso, non modificato), `.cantiere/MAPPA.md`, `.cantiere/progetto-s72-movimenti-abitudini.md`, `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme`.

## Prossimo
- Ripresa del **CHECKPOINT** in corso da parte del capocantiere (Claude Code · Sonnet), con verifica Commissione Suprema / chiusura `S-73i`.
