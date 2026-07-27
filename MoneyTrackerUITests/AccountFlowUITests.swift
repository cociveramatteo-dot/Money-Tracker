import XCTest

/// Simula un utente reale che aggiunge, modifica ed elimina conti.
final class AccountFlowUITests: MoneyTrackerUITestCase {

    func testAddEditDeleteAccount() throws {
        goToTab("Conti")
        let name = uniqueName("ContoTest")

        // --- Aggiungi ---
        tapFAB()
        let nameField = app.textFields["tf_accountName"]
        // Timeout portato a 10s (era 5s): nei run notturni, sotto carico di sistema,
        // la sheet di AddAccountView può impiegare più di 5s a presentarsi dopo il
        // tap sul FAB — visto nei log notturni come XCTAssertTrue failed qui pur con
        // il tap sul FAB sintetizzato correttamente e velocemente (nessun overlay o
        // stato applicativo coinvolto, solo l'animazione di presentazione in ritardo).
        XCTAssertTrue(nameField.waitForExistence(timeout: 10))
        nameField.tap()
        nameField.typeText(name)

        let balanceField = app.textFields["tf_accountBalance"]
        balanceField.tap()
        balanceField.typeText("100")

        app.buttons["btn_saveAccount"].tap()

        let row = app.staticTexts[name]
        XCTAssertTrue(row.waitForExistence(timeout: 10), "Il conto appena creato non è comparso nella lista")

        // --- Modifica ---
        row.tap()
        let editNameField = app.textFields["tf_accountName"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 10))
        let renamed = name + "_Mod"
        editNameField.tap()
        editNameField.typeText("_Mod")
        app.buttons["btn_saveAccount"].tap()

        XCTAssertTrue(app.staticTexts[renamed].waitForExistence(timeout: 10), "Il conto rinominato non è visibile")

        // --- Elimina (swipe + conferma) ---
        let updatedRow = app.staticTexts[renamed]
        updatedRow.swipeLeft()
        let deleteButton = app.buttons["btn_deleteAccount"]
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10))
        deleteButton.tap()

        let confirmButton = app.buttons["btn_confirmDeleteAccount"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 10))
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
