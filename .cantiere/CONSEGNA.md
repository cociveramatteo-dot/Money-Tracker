# CONSEGNA — correzioni S-14 e suite completa S-10 (operaio, 2026-11-16 15:40)

A) Correzioni S-14 fatte (nessun calcolo esistente toccato):
1. Percentuali >= 100: zero decimali (`SpendingComparisonCard.formatPercentage`; 1234 resta 1.234); sotto 100 formato invariato.
2. `StatisticsView`: snapshot `ComparisonInput` tolto dal body; `rebuildComparison()` chiamata in onAppear e onChange di transactions, selectedMonth, comparisonNow.
3. `MonthlySpendingComparison.categories` ordinate per variazione assoluta decrescente, a parità alfabetico (solo ordinamento).
Test nuovi (suite `MonthlyComparisonOrderingTests` in MonthlySpendingComparisonTests.swift): ordine + formato percentuale. Nessun test esistente modificato.

B) Suite completa (build + test, senza -only-testing, parallelo off):
- BUILD SUCCEEDED; unit Swift Testing: 92 test in 19 suite, tutti passati (XCTest unit: 0).
- UI: 45 test eseguiti, 3 falliti, 42 passati (~3037 s).
- Fallimenti (riportati, non aggirati):
  - NavigationStressUITests.testRapidTabSwitching — UITestSupport.swift:30 timeout "Failed to get matching snapshots" (284 s)
  - RecurrenceFlowUITests.testCreateEditAndDeleteScheduledSeries — RecurrenceFlowUITests.swift:64 "Neither element nor any descendant has keyboard focus" su tf_amount (557 s)
  - SentieroPlanningUITests.testGerman — SentieroPlanningUITests.swift:22 XCTAssertTrue failed (34 s)
- Log: /tmp/moneytracker-s10-full.log · xcresult: /tmp/mt-s10.xcresult
Sospetto: i primi due sembrano instabilità simulatore (focus tastiera/timeout), da rilanciare singolarmente; testGerman da analizzare (possibile regressione stringhe/S-14 non esclusa). Serve collaudatore/indagine.
