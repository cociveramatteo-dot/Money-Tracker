# Report notturno MoneyTracker — 14/07/2026

**Esito: ✅ TEST OK** (superati al tentativo 2 di 5)

## Dettaglio tentativi

- `xcodebuild_20260714_041248_attempt1.log`: ❌ fallito
  <details><summary>Estratto errori</summary>

  ```
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testAddEditDeleteAccount] : Failed to synthesize event: Neither element nor any descendant has keyboard focus. Event dispatch snapshot: TextField, {{41.0, 352.0}, {341.0, 67.0}}, identifier: 'tf_accountBalance', placeholderValue: '0', value: 0
  <unknown>:0: error: -[MoneyTrackerUITests.AccountFlowUITests testCancelAddAccountDiscardsInput] : Failed to tap "Conti" Button: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testAddEditDeleteCategory] : Failed to synthesize event: Timed out while synthesizing event.
  <unknown>:0: error: -[MoneyTrackerUITests.CategoryFlowUITests testDefaultCategoryCannotBeEdited] : Failed to get matching snapshots: Timed out while evaluating UI query.
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testAddMultipleTransactionsThenDeleteAll] : Failed to tap "fabButton" Button: Timed out while synthesizing event.
  /Users/matteo/Desktop/MoneyTracker/MoneyTrackerUITests/NavigationStressUITests.swift:25: error: -[MoneyTrackerUITests.NavigationStressUITests testOpenAndCancelAddSheetsRepeatedly] : XCTAssertTrue failed - Voce menu fabMenu_addTransaction non trovata
  <unknown>:0: error: -[MoneyTrackerUITests.NavigationStressUITests testSearchTransactionsTypeAndClearRepeatedly] : Failed to get matching snapshots: Timed out while evaluating UI query.
  <unknown>:0: error: -[MoneyTrackerUITests.TransactionFlowUITests testAddEditDeleteTransaction] : Failed to synthesize event: Timed out while synthesizing event.
  ```
  </details>
- `xcodebuild_20260714_041248_attempt2.log`: ✅ superato

## Modifiche automatiche

Nessuna modifica al codice è stata necessaria.
