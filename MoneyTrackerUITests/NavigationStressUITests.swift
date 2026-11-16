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
        XCTAssertTrue(app.buttons["tab_home"].exists)
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
        clearTransactionFilters()
        let baseName = uniqueName("Stress")
        var names: [String] = []

        for i in 0..<5 {
            let name = "\(baseName)_\(i)"
            names.append(name)
            tapFAB(menuItem: "fabMenu_addTransaction")
            enterTransactionField("tf_amount", text: "\(10 + i)")
            enterTransactionField("tf_name", text: name)
            saveTransactionForm()
            XCTAssertTrue(transactionRow(named: name).waitForExistence(timeout: 5), "Transazione \(name) non creata")
        }

        // Elimina dalla più recente (in cima alla lista) alla più vecchia: così ogni
        // riga da eliminare è sempre la prima del gruppo appena creato, senza bisogno
        // di scroll — le righe fuori schermo non esistono nella gerarchia di
        // accessibilità di una List lazy finché non vengono scrollate in vista.
        for name in names.reversed() {
            let row = transactionRow(named: name)
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            swipeToDeleteTransaction(named: name)
            XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
                predicate: NSPredicate(format: "exists == false"), object: transactionRow(named: name))], timeout: 5) == .completed)
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
        XCTAssertTrue(app.buttons["tab_home"].exists)

        goToTab("Statistiche")
        XCTAssertTrue(app.buttons["tab_statistiche"].exists)

        XCTAssertEqual(app.state, .runningForeground)
    }
}
