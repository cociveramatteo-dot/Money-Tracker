# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-27 23:54** · ramo `redesign-sentiero`
- **Esito:** **S-72b, S-72a, S-72d, S-72c, S-72e → [~]** in `.cantiere/PIANO.md`.

## Cosa è stato fatto (S-72)
- **S-72b (`b5407e1`)**: occorrenze programmate rese righe normali (`MovementListLayout.swift` / `MovementListLayout.kt`), gruppo «In arrivo · pianificati» in cima solo nei mesi futuri (`selectedMonth > startOfCurrentMonth`), rimossi badge/righe `VirtualOccurrenceRow` e chiave `"Virtuale · esclusa dai totali"` in 7 lingue, allineato filtro virtuali su iOS e Android (inclusa correzione `occ.type` e `KeywordCategoryClassifier.fold`).
- **S-72a (`5c86c5a`)**: sostituito `NextMonthSummary` con `MovementTotalsBlock` / `MovementSectionTotals` (iOS + Android) in fondo a ogni sezione (`Tutti`, `Fisse`, `Uscite`, `Entrate`, `Trasf.`, `Ricorrenti`), calcolati sulle righe mostrate (reali deduplicati per `transferGroupId` + virtuali); layout in colonna ai formati accessibilità AX; aggiunte 3 chiavi (`Trasferito`, `Uscite programmate`, `Entrate programmate`) in 7 lingue; eliminati i test superati `NextMonthSummaryTests.swift` e `NextMonthSummaryTest.kt` per D4.
- **S-72d (`477e089`)**: soglia alzata a `>= 3` movimenti in `>= 3` mesi distinti in `RecurringSeriesDetector.swift` e `RecurringSeriesDetector.kt`, esclusi trasferimenti e `"Rettifica saldo"`; creata pagina `HabitsView.swift` (iOS) e `HabitsPage` (Android) raggiungibile da `btn_openHabits` in Statistiche; aggiunte 3 chiavi (`Abitudini`, `Nessuna abitudine`, `abitudini_vuoto`) in 7 lingue + test (`RecurringSeriesDetectorTests`, `RecurringSeriesDetectorTest`, `HabitsUITests`).
- **S-72c (`d57ed2a`)**: «Ricorrenti» spostata come chip e sezione inline di `Movimenti` (D1 = `a`: sia spese fisse sia movimenti periodici; D2/D3: nessuna ricerca separata e tap che apre l'editor serie con tag `editRecurrence_<nome>`); rimossi `ProgrammedRuleCard`, `subListContent`, `RecurringPage` e 7 chiavi non più usate; aggiunta chiave `"Nessuna serie programmata in questo mese."` in 7 lingue; adattata la sola navigazione nei 3 UI test D4 (`DemoShowcaseUITests`, `RecurrenceAppearanceUITests`, `RecurrenceCancelAndHomeUITests`).
- **S-72e (`9343afd`, `d7ccbbf`)**: rimossi «rispetto al mese scorso», «Media mensile — ultimi 12 mesi» (incluso footer «Uscite medie» in `Andamento`) e «Anno vs anno» da `StatisticsView.swift` e `StatisticsScreen.kt`, mantenendo `prevMonthSpent` per il PDF; rimosse le 6 chiavi non più usate in 7 lingue. In `d7ccbbf`, rifiniti in AX-XL i titoli `Movimenti`/`Statistiche` su una riga (`.lineLimit(1).minimumScaleFactor(0.65)`) e il badge verde filtro (`Capsule()` con `dynamicTypeSize(...xxxLarge)` e `fixedSize()`) dopo verifica visiva del taglio su `de-axxl-mov-badge.png`.

## Verifiche eseguite
- **iOS (`MoneyTrackerTests`)**: rieseguito l'intero target dopo l'ultimo commit (`d7ccbbf`) — `xcodebuild -project MoneyTracker.xcodeproj -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' test -only-testing:MoneyTrackerTests`: **242 test in 53 suite verdi** (`** TEST SUCCEEDED **`).
- **iOS UI test (sui commit precedenti S-72d/S-72c)**: `HabitsUITests` (1/1 verde), `DemoShowcaseUITests` + `RecurrenceAppearanceUITests` + `RecurrenceCancelAndHomeUITests` (8/8 verdi).
- **Android**: `ANDROID_HOME=/Users/matteo/Library/Android/sdk 03_CODICE/bucktrail-android/gradlew -p 03_CODICE/bucktrail-android assembleDebug testDebugUnitTest` → **`BUILD SUCCESSFUL`** (più `lintDebug` verde su ciascun commit S-72b..S-72e).
- **Screenshot in `.cantiere/tmp/s72/`**: **46 PNG** (`it-light-*`, `it-dark-*`, `de-axxl-*`: Movimenti corrente e futuro in Tutti/Fisse/Ricorrenti top+bottom, badge filtro `de-axxl-mov-badge.png`, Statistiche top+bottom, Abitudini); rivisti `it-light`, `it-dark` e `de-axxl` (incluso secondo giro su badge e testate dopo `d7ccbbf`).

## Non provato / Aperto
- **Collaudo indipendente S-72 (b, a, d, c, e)** su diff, screenshot e UI.
- **Note preesistenti invariate**:
  - `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` era già modificato in working tree ed è stato lasciato fuori da tutti i commit.
  - `03_CODICE/bucktrail-android/scripts/ios-strings-to-android.py` ha fallito con `nome extra duplicato: periodo` (le stringhe Android e `strings-map.json` sono state aggiornate e verificate direttamente con Gradle).
  - La generazione PDF in Statistiche mantiene `prevMonthSpent`, ma non è stata esportata una nuova anteprima PDF su simulatore in questo turno.
- **Prossimo turno richiesto da Matteo**: `S-70j` (nuovo turno separato dopo chiusura S-72).
