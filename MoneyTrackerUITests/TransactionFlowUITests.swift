import XCTest

/// Simula un utente reale che aggiunge, modifica ed elimina movimenti.
final class TransactionFlowUITests: MoneyTrackerUITestCase {

    func testAddEditDeleteTransaction() throws {
        goToTab("Movimenti")
        openTransactionsSection("Tutti")

        let name = uniqueName("SpesaTest")

        // --- Aggiungi ---
        tapFAB(menuItem: "fabMenu_addTransaction")

        let amountField = app.textFields["tf_amount"]
        XCTAssertTrue(amountField.waitForExistence(timeout: 5))
        amountField.tap()
        amountField.typeText("42")

        let nameField = app.textFields["tf_name"]
        nameField.tap()
        nameField.typeText(name)

        // Scegli una categoria dal picker
        app.buttons["btn_categoryPicker"].tap()
        let categoryRow = app.buttons["categoryRow_Cibo"]
        XCTAssertTrue(categoryRow.waitForExistence(timeout: 5))
        categoryRow.tap()

        app.buttons["btn_saveTransaction"].tap()

        // La riga con il nome inserito deve comparire nella lista movimenti
        let row = app.staticTexts[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "La transazione appena creata non è comparsa nella lista")

        // --- Modifica ---
        row.tap()
        let editAmountField = app.textFields["tf_amount"]
        XCTAssertTrue(editAmountField.waitForExistence(timeout: 5))
        // Svuota il campo importo e inserisce un nuovo valore
        editAmountField.tap()
        if let value = editAmountField.value as? String {
            editAmountField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: value.count))
        }
        editAmountField.typeText("77")
        app.buttons["btn_saveTransaction"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5), "La transazione modificata non è più visibile")

        // --- Elimina (swipe + conferma) ---
        swipeToDeleteTransaction(named: name)

        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 3), "La transazione eliminata è ancora visibile")
    }

    func testAddTransactionWithoutCategoryDefaultsToAltro() throws {
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        clearTransactionFilters()
        let name = uniqueName("SenzaCategoria")

        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "15")
        enterTransactionField("tf_name", text: name)
        saveTransactionForm()

        XCTAssertTrue(transactionRow(named: name).waitForExistence(timeout: 5))
        XCTAssertTrue(transactionRow(named: name).label.contains("Altro"))

        // Pulizia: elimina la transazione appena creata
        swipeToDeleteTransaction(named: name)
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: transactionRow(named: name))], timeout: 5) == .completed)
    }

    func testCancelAddTransactionDiscardsInput() throws {
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        let name = uniqueName("Annullata")

        tapFAB(menuItem: "fabMenu_addTransaction")
        app.textFields["tf_name"].tap()
        app.textFields["tf_name"].typeText(name)
        app.buttons["btn_cancelAddTransaction"].tap()

        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 3), "L'annullamento non avrebbe dovuto salvare la transazione")
    }
}
