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
