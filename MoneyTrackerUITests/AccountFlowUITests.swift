import XCTest

/// Simula un utente reale che aggiunge, modifica ed elimina conti.
final class AccountFlowUITests: MoneyTrackerUITestCase {

    func testAddEditDeleteAccount() throws {
        goToTab("Conti")
        let name = uniqueName("ContoTest")

        // --- Aggiungi ---
        tapFAB()
        let nameField = app.textFields["tf_accountName"]
        // Timeout più ampio: questo è il primo sheet mai presentato nel processo
        // (questa è la prima suite eseguita), e il primo cold render può superare
        // i 5s abituali su una macchina CI sotto carico — osservato flaky solo qui,
        // mai nelle chiamate identiche successive a processo caldo.
        XCTAssertTrue(nameField.waitForExistence(timeout: 15))
        nameField.tap()
        nameField.typeText(name)

        let balanceField = app.textFields["tf_accountBalance"]
        balanceField.tap()
        balanceField.typeText("100")

        app.buttons["btn_saveAccount"].tap()

        let row = app.staticTexts[name]
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Il conto appena creato non è comparso nella lista")

        // --- Modifica ---
        row.tap()
        let editNameField = app.textFields["tf_accountName"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 5))
        let renamed = name + "_Mod"
        editNameField.tap()
        editNameField.typeText("_Mod")
        app.buttons["btn_saveAccount"].tap()

        XCTAssertTrue(app.staticTexts[renamed].waitForExistence(timeout: 5), "Il conto rinominato non è visibile")

        // --- Elimina (swipe + conferma) ---
        let updatedRow = app.staticTexts[renamed]
        updatedRow.swipeLeft()
        let deleteButton = app.buttons["btn_deleteAccount"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 5))
        deleteButton.tap()

        let confirmButton = app.buttons["btn_confirmDeleteAccount"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertFalse(app.staticTexts[renamed].waitForExistence(timeout: 3), "Il conto eliminato è ancora visibile")
    }

    func testCancelAddAccountDiscardsInput() throws {
        goToTab("Conti")
        let name = uniqueName("ContoAnnullato")

        tapFAB()
        app.textFields["tf_accountName"].tap()
        app.textFields["tf_accountName"].typeText(name)
        app.buttons["btn_cancelAddAccount"].tap()

        XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 3))
    }
}
