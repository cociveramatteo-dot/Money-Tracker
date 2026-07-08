import XCTest

/// Simula un utente reale che aggiunge, modifica ed elimina movimenti.
final class TransactionFlowUITests: MoneyTrackerUITestCase {

    func testAddEditDeleteTransaction() throws {
        goToTab("Movimenti")

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
        let updatedRow = app.staticTexts[name]
        updatedRow.swipeLeft()
        let deleteButton = app.buttons["btn_deleteTransaction"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 3), "La transazione eliminata è ancora visibile")
    }

    func testAddTransactionWithoutCategoryDefaultsToAltro() throws {
        goToTab("Movimenti")
        let name = uniqueName("SenzaCategoria")

        tapFAB(menuItem: "fabMenu_addTransaction")
        app.textFields["tf_amount"].tap()
        app.textFields["tf_amount"].typeText("15")
        app.textFields["tf_name"].tap()
        app.textFields["tf_name"].typeText(name)
        app.buttons["btn_saveTransaction"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))

        // Pulizia: elimina la transazione appena creata
        app.staticTexts[name].swipeLeft()
        app.buttons["btn_deleteTransaction"].tap()
    }

    func testCancelAddTransactionDiscardsInput() throws {
        goToTab("Movimenti")
        let name = uniqueName("Annullata")

        tapFAB(menuItem: "fabMenu_addTransaction")
        app.textFields["tf_name"].tap()
        app.textFields["tf_name"].typeText(name)
        app.buttons["btn_cancelAddTransaction"].tap()

        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 3), "L'annullamento non avrebbe dovuto salvare la transazione")
    }
}
