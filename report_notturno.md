# Report notturno MoneyTracker — 18/07/2026

**Esito: ❌ TEST FALLITI** dopo 5 tentativi di correzione automatica.

Serve un intervento manuale: controlla il log completo in `/Users/matteo/Desktop/NightTestApp/logs/nightly_20260718_041124.log` e i risultati in `/Users/matteo/Desktop/NightTestApp/logs`.

## Dettaglio tentativi

- `xcodebuild_20260718_041124_attempt1.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  ```
  </details>
- `xcodebuild_20260718_041124_attempt2.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testCancelAddAccountDiscardsInput] : Failed to tap "tf_accountName" TextField: No matches found for Descendants matching type TextField from input {(
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testAddMultipleTransactionsThenDeleteAll] : Failed to tap "btn_saveTransaction" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260718_041124_attempt3.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testCancelAddAccountDiscardsInput] : Failed to get matching snapshots: Timed out while evaluating UI query.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testOpenAndCancelAddSheetsRepeatedly] : Failed to tap "Conti" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260718_041124_attempt4.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testAddEditDeleteAccount] : Failed to get launch progress for <XCUIApplicationImpl: 0x104fe6740 com.matteo.moneytracker.MoneyTracker at /Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-hkukkzcryepwfrgtssroybzyqqat/Build/Products/Debug-iphonesimulator/MoneyTracker.app>: Timed out while requesting launch progress.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testOpenAndCancelAddSheetsRepeatedly] : Failed to tap "fabMenu_addTransaction" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260718_041124_attempt5.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testAddEditDeleteAccount] : Failed to tap "tf_accountName" TextField: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to get matching snapshots: Timed out while evaluating UI query.
  ```
  </details>

## Modifiche automatiche

Nessuna modifica al codice è stata necessaria.
