# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 02:03** · ramo `redesign-sentiero`
- **Task:** `S-73a`, `S-73b`, `S-73c`, `S-73d`, `S-73e` → segnati `[~]` in `.cantiere/PIANO.md` (un commit per task: `1afbe71`, `64005ac`, `1806a3d`, `90e76a3`, più il commit `S-73e`)

## Fatto
- **S-73a (`1afbe71`, iOS):** aggiunto `MoneyTracker/Views/MonthlyPlannedBalance.swift` (`expected(for:day:calendar:)`, `expectedByAccountID(for:day:calendar:)`) allineato a `DashboardView.countsInProjection`; `AccountsView.swift` calcola i valori attesi una volta nel `body` e aggiorna `projectionDay` su `scenePhase` active / `.NSCalendarDayChanged` / `significantTimeChangeNotification` mantenendo intatti «A conti fatti», «→» e tutta la grafica; `DashboardView.swift` (`whatIfBaselines` conti esclusi) usa `MonthlyPlannedBalance.expected`. `Domain/` e `AccountBalanceCache` non toccati. Nuovi test in `MoneyTrackerTests/MonthlyPlannedBalanceTests.swift`.
- **S-73b (`64005ac`, Android):** estratto `HomeProjection.countsInMonth(t, month, zone)` e aggiunto `Balance.expectedInMonth` / `Balance.totalExpectedInMonth` (lasciando intatti `Balance.current`/`future`); `AccountsScreen.kt`, `WhatIfScenario.kt` (conti esclusi) e `BucktrailApp.kt` usano `today` e `zone` con la regola della Home. Nuovi test JVM in `app/src/test/java/com/bucktrail/android/domain/AccountsExpectedMonthTest.kt`.
- **S-73c (`1806a3d`, iOS):** in `AddTransactionView.swift` aggiunti `isFutureDate` e `defaultDone`, `DatePicker` con `Binding` imposta `isDone = !isFutureDate` per i non fissi (solo su modifica utente, non su `load()`), «Già effettuato» visibile anche per i non fissi con data futura; `TransactionsView.swift` abilita lo swipe `Pianificato`/`Conferma` anche per movimenti fatti con data futura; `DashboardView.countsInProjection` esteso a tutti i singoli pianificati (`!isDone && !isTransfer && templateId.isEmpty && recurringFrequency.isEmpty`). Aggiunto UI test `MoneyTrackerUITests/FutureTransactionPlannedUITests.swift`.
  - **Nota su `ProjectionMonthTests.swift`:** con l'estensione di S-73c (opzione B di Matteo), i due vecchi assert S-41 in `everythingElseAlwaysCounts()` per `Stipendio` (entrata singola pianificata a dicembre) e `Cena` (spesa non fissa pianificata a dicembre) erano incompatibili con la nuova regola: sono stati spostati nel nuovo `@Test` `singlePlannedCountsOnlyInItsMonth()` dove verificano il comportamento corretto S-73c, più il test `futureDateAutoPlannedRule()`.
- **S-73d (`90e76a3`, Android):** esteso `HomeProjection.countsInMonth` a tutti i singoli pianificati; aggiornato `SwipeRules.canToggleDone` (con parametro opzionale `isFutureDate: Boolean = false`) e `TransactionRow.kt` per consentire lo swipe anche sui movimenti fatti con data futura; in `AddTransactionForm.kt` mostrato `Già effettuato` anche quando `date > today`. Nuovi test JVM in `FuturePlannedRulesTest.kt`.
- **S-73e (iOS + Android):** risolto in `AddTransactionView.swift` sostituendo `.onChange(of: isFixed)` con il `Binding` sul `Toggle` così `load()` non resetta `isDone` aprendo una fissa già effettuata; aggiunto `testEditingDoneFixedExpenseKeepsItDone()` in `FutureTransactionPlannedUITests.swift`; verificato `AddTransactionForm.kt` su Android (inizializza `done = existing?.isDone ?: true` e lo modifica solo al tocco).

## Verifiche eseguite
- **iOS unit test (`xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO -only-testing:MoneyTrackerTests test`):**
  - `MoneyTrackerTests`: **255/255** test Swift Testing passati in 55 suite (`TEST SUCCEEDED`), 1 XCTest (`TwoDeviceLiveSyncTests/testLiveSync`) skipped perché richiede lo script a due dispositivi. (In una corsa precedente con Runner appesantito si era verificato un crash intermittente su `SyncLostTransactionTests.initialE2ELoginDownloadsThenSchedulesUploadForDirtyTransaction`; al rilancio pulito tutto `MoneyTrackerTests` è passato 255/255.)
- **iOS UI test (`FutureTransactionPlannedUITests`):**
  - `testFutureNonFixedExpenseBehaviorAndYesterdayDone`: **1/1** passato (`TEST SUCCEEDED`).
  - `testEditingDoneFixedExpenseKeepsItDone`: **1/1** passato (`TEST SUCCEEDED`).
- **Screenshot Conti in demo (`.cantiere/tmp/s73/`):**
  - `prima-light.png`, `dopo-light.png`, `dopo-dark.png` generati e controllati visivamente (layout, «A conti fatti» e «→» invariati nella struttura, chiari e leggibili).
- **Android (`ANDROID_HOME=~/Library/Android/sdk 03_CODICE/bucktrail-android/gradlew -p 03_CODICE/bucktrail-android assembleDebug lintDebug testDebugUnitTest --rerun`):**
  - `assembleDebug` verde, `lintDebug` verde, `testDebugUnitTest`: **366/366** passati su 63 file XML (`failures=0`, `errors=0`, `skipped=0`).

## Aperto / note per il collaudo
- `MoneyTracker.xcscheme` era già modificato in locale prima del turno: lasciato fuori da tutti i commit come richiesto.
- Collaudo indipendente su `S-73a..S-73e` (+ `S-70k`). Restano in carico a Matteo la prova reale su telefono `S-70d` e l'eventuale verifica visiva di Conti.
