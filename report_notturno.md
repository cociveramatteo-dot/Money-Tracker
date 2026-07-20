# Report notturno MoneyTracker — 20/07/2026

**Esito: ❌ TEST FALLITI** dopo 5 tentativi di correzione automatica.

Serve un intervento manuale: controlla il log completo in `/Users/matteo/Desktop/NightTestApp/logs/nightly_20260720_040305.log` e i risultati in `/Users/matteo/Desktop/NightTestApp/logs`.

## Dettaglio tentativi

- `xcodebuild_20260720_040305_attempt1.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testAddEditDeleteAccount] : Failed to tap "btn_confirmDeleteAccount" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to get matching snapshots: Timed out while evaluating UI query.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testAddMultipleTransactionsThenDeleteAll] : Failed to swipe left StaticText (First Match): Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testRapidTabSwitching] : Failed to tap "Conti" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260720_040305_attempt2.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testAddEditDeleteAccount] : Failed to tap "Conti" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to tap "fabMenu_addTransaction" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testAddTransactionWithoutCategoryDefaultsToAltro] : Failed to tap "btn_deleteTransaction" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260720_040305_attempt3.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testAddTransactionWithoutCategoryDefaultsToAltro] : Failed to tap "fabMenu_addTransaction" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testCancelAddTransactionDiscardsInput] : Failed to tap "txFilterBlock_Tutti" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260720_040305_attempt4.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  ```
  </details>
- `xcodebuild_20260720_040305_attempt5.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testDefaultCategoryCannotBeEdited] : Failed to tap "btn_categoryPicker" Button: Timed out while synthesizing event.
  ```
  </details>

## Modifiche automatiche

Nessuna modifica al codice è stata necessaria.
