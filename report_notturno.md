# Report notturno MoneyTracker — 12/07/2026

**Esito: ❌ TEST FALLITI** dopo 5 tentativi di correzione automatica.

Serve un intervento manuale: controlla il log completo in `/Users/matteo/Desktop/NightTestApp/logs/nightly_20260712_041117.log` e i risultati in `/Users/matteo/Desktop/NightTestApp/logs`.

## Dettaglio tentativi

- `xcodebuild_20260712_041117_attempt1.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testCancelAddTransactionDiscardsInput] : Failed to get matching snapshots: Timed out while evaluating UI query.
  ```
  </details>
- `xcodebuild_20260712_041117_attempt2.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testAddMultipleTransactionsThenDeleteAll] : Failed to swipe left StaticText (First Match): Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testAddEditDeleteTransaction] : Failed to get matching snapshots: Timed out while evaluating UI query.
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testAddTransactionWithoutCategoryDefaultsToAltro] : Failed to synthesize event: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260712_041117_attempt3.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to tap "fabMenu_addTransaction" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testDefaultCategoryCannotBeEdited] : Failed to tap "Movimenti" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testAddMultipleTransactionsThenDeleteAll] : Failed to tap "tf_amount" TextField: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testOpenAndCancelAddSheetsRepeatedly] : Failed to tap "Movimenti" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260712_041117_attempt4.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testAddEditDeleteAccount] : Failed to tap "tf_accountName" TextField: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to tap "Movimenti" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testDefaultCategoryCannotBeEdited] : Failed to tap "Cibo" StaticText: Find single matching element. Multiple matching elements found for <XCUIElementQuery: 0x115648af0>.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testOpenAndCancelAddSheetsRepeatedly] : Failed to tap "fabMenu_addTransaction" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testRapidTabSwitching] : Failed to tap "Home" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260712_041117_attempt5.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  ```
  </details>

## Modifiche automatiche

Nessuna modifica al codice è stata necessaria.
