import XCTest

// MARK: - Base class

/// Classe base per tutti gli XCUITest di MoneyTracker.
/// Lancia l'app con "--uitesting": bypassa login/Face ID e forza la modalità
/// demo (dati deterministici, nessuna chiamata di rete) — vedi
/// MoneyTrackerApp.isUITesting.
class MoneyTrackerUITestCase: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    // MARK: - Navigation helpers

    /// Naviga a una tab tramite l'etichetta visibile ("Home", "Movimenti", "Statistiche",
    /// "Pianifica", "Conti") — la tab bar flottante espone `tab_<nome minuscolo>`.
    func goToTab(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let tab = app.buttons["tab_\(label.lowercased())"]
        XCTAssertTrue(tab.waitForExistence(timeout: 5), "Tab \(label) non trovata", file: file, line: line)
        tab.tap()
    }

    /// Apre il FAB e, se presente un menu (tab Home/Movimenti), seleziona la voce richiesta.
    func tapFAB(menuItem: String? = nil, file: StaticString = #filePath, line: UInt = #line) {
        let fab = app.buttons["fabButton"]
        XCTAssertTrue(fab.waitForExistence(timeout: 5), "FAB non trovato", file: file, line: line)
        fab.tap()
        if let menuItem {
            let item = app.buttons[menuItem]
            XCTAssertTrue(item.waitForExistence(timeout: 3), "Voce menu \(menuItem) non trovata", file: file, line: line)
            item.tap()
        }
    }

    /// Seleziona una sezione o filtro della tab Movimenti (Tutti/Fisse/Ricorrenti/Trasf./Uscite/Entrate).
    /// Va chiamata dopo `goToTab("Movimenti")` — con la pagina unica (S-12) seleziona il chip
    /// inline per Tutti/Fisse/Trasf./Uscite/Entrate, oppure apre la pagina a sé per Ricorrenti.
    func openTransactionsSection(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let block = app.buttons["txFilterBlock_\(label)"]
        let chips = app.scrollViews["tx_typeChips"]
        XCTAssertTrue(chips.waitForExistence(timeout: 5), file: file, line: line)
        chips.swipeRight()
        for _ in 0..<5 {
            if block.exists && chips.frame.contains(block.frame) { break }
            chips.swipeLeft()
        }
        XCTAssertTrue(block.waitForExistence(timeout: 5), "Blocco \(label) non trovato", file: file, line: line)
        block.tap()
    }

    /// The Tutti chip does not reset persisted amount/date filters.
    /// Creation tests must start with those filters explicitly cleared through the UI.
    func clearTransactionFilters(file: StaticString = #filePath, line: UInt = #line) {
        let clear = app.buttons["Rimuovi filtri"]
        if clear.exists { clear.tap() }
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: clear)], timeout: 5) == .completed,
            "Filtri avanzati ancora attivi", file: file, line: line)
    }

    /// MovementRow combines name and metadata into one accessible label.
    /// Match the full name boundary, rather than requiring an isolated Text leaf.
    func transactionRow(named name: String) -> XCUIElement {
        app.staticTexts.matching(NSPredicate(format: "label == %@ OR label BEGINSWITH %@", name, name + ",")).firstMatch
    }

    /// Wait for the sheet and actual field focus before dispatching keyboard events.
    func enterTransactionField(_ identifier: String, text: String, file: StaticString = #filePath, line: UInt = #line) {
        let field = app.textFields[identifier]
        XCTAssertTrue(field.waitForExistence(timeout: 5), file: file, line: line)
        let focused = NSPredicate(format: "hasKeyboardFocus == true")
        for _ in 0..<2 {
            field.tap()
            if XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: focused, object: field)], timeout: 2) == .completed { break }
        }
        XCTAssertTrue(focused.evaluate(with: field), "Campo senza focus: \(identifier)", file: file, line: line)
        field.typeText(text)
    }

    /// Bring the button above the keyboard explicitly; XCUITest's implicit scroll
    /// can compute a hit point while the SwiftUI scroll view is still moving.
    func saveTransactionForm(file: StaticString = #filePath, line: UInt = #line) {
        let save = app.buttons["btn_saveTransaction"]
        for _ in 0..<4 {
            if save.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(save.isHittable, "Salva non raggiungibile", file: file, line: line)
        save.tap()
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: app.buttons["btn_cancelAddTransaction"])], timeout: 5) == .completed,
            "Il form non si è chiuso dopo Salva", file: file, line: line)
    }

    /// Swipe-to-delete robusto su una riga movimento (cercata per nome): subito
    /// dopo l'insert, la riga può impiegare più di un istante a installare i
    /// gesture recognizer della cella List — un primo swipe tentato in quella
    /// finestra non rivela nulla. Ririsolve l'elemento (per tipo, Button o
    /// StaticText a seconda di quanto ha stabilizzato l'accessibilità) e
    /// ritenta lo swipe finché il bottone elimina non appare, invece di
    /// affidarsi a una singola pausa fissa (durata del settling non
    /// deterministica, osservata flaky sia a 0.4s sia a 1.0s).
    func swipeToDeleteTransaction(named name: String, file: StaticString = #filePath, line: UInt = #line) {
        let deleteButton = app.buttons["btn_deleteTransaction"]
        // Scope alla sola gerarchia StaticText: .descendants(matching: .any) forza
        // una scansione dell'intero albero di accessibilità (ogni elemento di ogni
        // tipo, comprese le ~75 righe demo) a ogni retry di waitForExistence — con
        // la lista movimenti popolata questo ha fatto durare un singolo swipe fino
        // a 17 minuti invece di pochi secondi (vedi log notte 11/07). La riga
        // combinata (.accessibilityElement(children: .combine) in Theme.swift)
        // risolve comunque come StaticText, quindi restringere il tipo è sicuro.
        let target = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        for _ in 0..<6 {
            XCTAssertTrue(target.waitForExistence(timeout: 5), "Riga \(name) non trovata", file: file, line: line)
            target.swipeLeft()
            if deleteButton.waitForExistence(timeout: 1.5) { break }
        }
        XCTAssertTrue(deleteButton.exists, "Bottone elimina non apparso dopo lo swipe", file: file, line: line)
        deleteButton.tap()
    }

    /// Ritorna alla schermata precedente tramite il back button standard della nav bar.
    func navigateBack() {
        let backButton = app.navigationBars.buttons.element(boundBy: 0)
        if backButton.waitForExistence(timeout: 3) {
            backButton.tap()
        }
    }

    /// Nome univoco per una entità di test, per evitare collisioni tra run.
    func uniqueName(_ prefix: String) -> String {
        "\(prefix)_\(Int(Date().timeIntervalSince1970 * 1000) % 1_000_000)"
    }
}
