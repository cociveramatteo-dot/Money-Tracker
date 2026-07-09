import XCTest

/// Simula un utente che "martella" l'app passando rapidamente da una sezione
/// all'altra e aprendo/chiudendo più volte le stesse schermate — lo scopo è far
/// emergere crash intermittenti (race condition, stati inconsistenti, sheet
/// lasciati aperti) che un singolo passaggio lineare non troverebbe.
final class NavigationStressUITests: MoneyTrackerUITestCase {

    private let allTabs = ["Home", "Movimenti", "Statistiche", "Pianifica", "Conti"]

    func testRapidTabSwitching() throws {
        for _ in 0..<3 {
            for tab in allTabs {
                goToTab(tab)
            }
        }
        // L'app deve essere ancora viva e rispondere all'input.
        XCTAssertEqual(app.state, .runningForeground)
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)
    }

    func testOpenAndCancelAddSheetsRepeatedly() throws {
        goToTab("Movimenti")
        for _ in 0..<5 {
            tapFAB(menuItem: "fabMenu_addTransaction")
            XCTAssertTrue(app.buttons["btn_cancelAddTransaction"].waitForExistence(timeout: 5))
            app.buttons["btn_cancelAddTransaction"].tap()
        }

        goToTab("Conti")
        for _ in 0..<5 {
            tapFAB()
            XCTAssertTrue(app.buttons["btn_cancelAddAccount"].waitForExistence(timeout: 5))
            app.buttons["btn_cancelAddAccount"].tap()
        }

        XCTAssertEqual(app.state, .runningForeground)
    }

    func testAddMultipleTransactionsThenDeleteAll() throws {
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        let baseName = uniqueName("Stress")
        var names: [String] = []

        for i in 0..<5 {
            let name = "\(baseName)_\(i)"
            names.append(name)
            tapFAB(menuItem: "fabMenu_addTransaction")
            app.textFields["tf_amount"].tap()
            app.textFields["tf_amount"].typeText("\(10 + i)")
            app.textFields["tf_name"].tap()
            app.textFields["tf_name"].typeText(name)
            app.buttons["btn_saveTransaction"].tap()
            XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5), "Transazione \(name) non creata")
        }

        // Elimina dalla più recente (in cima alla lista) alla più vecchia: così ogni
        // riga da eliminare è sempre la prima del gruppo appena creato, senza bisogno
        // di scroll — le righe fuori schermo non esistono nella gerarchia di
        // accessibilità di una List lazy finché non vengono scrollate in vista.
        for name in names.reversed() {
            let row = app.staticTexts[name]
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            swipeToDeleteTransaction(named: name)
            XCTAssertFalse(app.staticTexts[name].waitForExistence(timeout: 3))
        }

        XCTAssertEqual(app.state, .runningForeground)
    }

    func testSearchTransactionsTypeAndClearRepeatedly() throws {
        goToTab("Movimenti")
        let searchField = app.textFields["tf_searchTransactions"]
        XCTAssertTrue(searchField.waitForExistence(timeout: 5))

        for term in ["Affitto", "Netflix", "Stipendio", ""] {
            searchField.tap()
            // Rimuove il testo precedente prima di digitare il nuovo.
            if let current = searchField.value as? String, !current.isEmpty {
                searchField.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: current.count))
            }
            if !term.isEmpty {
                searchField.typeText(term)
            }
        }

        XCTAssertEqual(app.state, .runningForeground)
    }

    func testDashboardAndStatisticsRenderWithoutCrashing() throws {
        goToTab("Home")
        XCTAssertTrue(app.tabBars.buttons["Home"].exists)

        goToTab("Statistiche")
        XCTAssertTrue(app.tabBars.buttons["Statistiche"].exists)

        XCTAssertEqual(app.state, .runningForeground)
    }
}
