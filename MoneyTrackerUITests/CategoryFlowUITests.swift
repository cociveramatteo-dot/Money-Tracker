import XCTest

/// Simula un utente reale che gestisce le categorie: crea, rinomina, elimina.
/// Le categorie si raggiungono da Aggiungi movimento → Categoria → Gestisci.
final class CategoryFlowUITests: MoneyTrackerUITestCase {

    /// Apre Aggiungi movimento → Categoria → Gestisci categorie.
    private func openCategoryManagement() {
        goToTab("Movimenti")
        tapFAB(menuItem: "fabMenu_addTransaction")
        app.buttons["btn_categoryPicker"].tap()
        let manageButton = app.buttons["btn_manageCategories"]
        XCTAssertTrue(manageButton.waitForExistence(timeout: 5))
        manageButton.tap()
    }

    /// Chiude Gestisci categorie → Categoria → Aggiungi movimento (senza salvare nulla).
    private func closeCategoryManagement() {
        // Il back button standard della nav bar mostra il titolo della schermata
        // precedente ("Categoria") — più affidabile di un indice posizionale,
        // perché la toolbar ha anche un pulsante "+" che potrebbe essere enumerato per primo.
        let backButton = app.navigationBars.buttons["Categoria"]
        XCTAssertTrue(backButton.waitForExistence(timeout: 5))
        backButton.tap() // Gestisci -> Categoria
        app.buttons["btn_closeCategoryPicker"].tap() // Categoria -> Aggiungi movimento
        app.buttons["btn_cancelAddTransaction"].tap() // chiude il foglio
    }

    func testAddEditDeleteCategory() throws {
        openCategoryManagement()
        let name = uniqueName("CategoriaTest")

        // --- Aggiungi ---
        app.buttons["btn_addCategory"].tap()
        let nameField = app.textFields["tf_categoryName"]
        XCTAssertTrue(nameField.waitForExistence(timeout: 5))
        nameField.tap()
        nameField.typeText(name)
        app.buttons["btn_saveCategory"].tap()

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5), "La categoria appena creata non è comparsa")

        // --- Modifica ---
        app.staticTexts[name].tap()
        let editNameField = app.textFields["tf_categoryName"]
        XCTAssertTrue(editNameField.waitForExistence(timeout: 5))
        let renamed = name + "Mod"
        editNameField.tap()
        editNameField.typeText("Mod")
        app.buttons["btn_saveCategory"].tap()

        XCTAssertTrue(app.staticTexts[renamed].waitForExistence(timeout: 5), "La categoria rinominata non è visibile")

        // --- Elimina (long press -> menu contestuale -> conferma) ---
        app.staticTexts[renamed].press(forDuration: 1.0)
        let deleteMenuItem = app.buttons["Elimina"]
        XCTAssertTrue(deleteMenuItem.waitForExistence(timeout: 5))
        deleteMenuItem.tap()

        let confirmButton = app.buttons["btn_confirmDeleteCategory"].firstMatch
        XCTAssertTrue(confirmButton.waitForExistence(timeout: 5))
        confirmButton.tap()

        XCTAssertFalse(app.staticTexts[renamed].waitForExistence(timeout: 3), "La categoria eliminata è ancora visibile")

        closeCategoryManagement()
    }

    func testDefaultCategoryCannotBeEdited() throws {
        openCategoryManagement()

        // "Cibo" è una categoria predefinita: il tap deve mostrare solo un avviso.
        app.staticTexts["Cibo"].tap()
        XCTAssertTrue(app.staticTexts["Categoria predefinita"].waitForExistence(timeout: 5))
        app.buttons["OK"].tap()

        closeCategoryManagement()
    }
}
