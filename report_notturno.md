# Report notturno MoneyTracker — 22/07/2026

**Esito: ✅ TEST OK** (superati al tentativo 2 di 5)

## Dettaglio tentativi

- `xcodebuild_20260722_040243_attempt1.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to get matching snapshots: Timed out while fetching snapshot from testmanagerd..
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testDefaultCategoryCannotBeEdited] : Failed to get matching snapshots: Timed out while fetching snapshot from testmanagerd..
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testAddMultipleTransactionsThenDeleteAll] : Failed to get list of active applications: Timed out while fetching attributes 'XC_kAXXCAttributeFocusedApplications' for AX element pid: 48251, elementOrHash.elementID: 0.1.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testOpenAndCancelAddSheetsRepeatedly] : Failed to tap "fabButton" Button: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260722_040243_attempt2.log`: ✅ superato

## Modifiche automatiche

Nessuna modifica al codice è stata necessaria.
