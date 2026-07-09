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
    /// "Pianifica", "Conti") — i tab item SwiftUI non propagano accessibilityIdentifier
    /// al UITabBarButton sottostante, quindi l'unico aggancio affidabile è il testo.
    func goToTab(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let tab = app.tabBars.buttons[label]
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

    /// Apre una sezione della tab Movimenti (Tutti/Fisse/Ricorrenti/Trasf./Uscite/Entrate)
    /// dall'hub a blocchi. Va chiamata dopo `goToTab("Movimenti")` — la lista dei
    /// movimenti non è più visibile sull'hub, compare solo dentro la sezione.
    func openTransactionsSection(_ label: String, file: StaticString = #filePath, line: UInt = #line) {
        let block = app.buttons["txFilterBlock_\(label)"]
        XCTAssertTrue(block.waitForExistence(timeout: 5), "Blocco \(label) non trovato", file: file, line: line)
        block.tap()
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
        let target = app.descendants(matching: .any).matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
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
