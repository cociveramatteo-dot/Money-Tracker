import XCTest

final class DemoShowcaseUITests: MoneyTrackerUITestCase {
    @MainActor
    private func capture(_ name: String) {
        // Allow the segment cross-fade to settle before visual comparison.
        Thread.sleep(forTimeInterval: 0.8)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    func testShowcaseScreens() throws {
        goToTab("Home")
        capture("S26-home")
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        clearTransactionFilters()
        capture("S26-movimenti")
        openTransactionsSection("Ricorrenti")
        capture("S26-ricorrenze")
        // Rules have no fixed display order. Full-screen swipes can skip the
        // bill's action between the fixed header and floating tab bar.
        enterTransactionField("tf_searchTransactions", text: "Bolletta Enel\n")
        let bill = app.buttons["editRecurrence_Bolletta Enel"].firstMatch
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "hittable == true"), object: bill)], timeout: 5) == .completed,
            "Prossima occorrenza di Bolletta Enel non raggiungibile dopo la ricerca")
        bill.tap()
        XCTAssertTrue(app.buttons["recurrence_scope"].waitForExistence(timeout: 5))
        capture("S26-override-singolo")
        app.buttons["Annulla"].tap()
        goToTab("Statistiche")
        capture("S26-statistiche")
        goToTab("Pianifica")
        capture("S26-budget")
        app.swipeUp()
        capture("S26-budget-dettaglio")
        app.swipeDown()
        app.buttons["Obiettivi"].tap()
        capture("S26-obiettivi")
        app.swipeUp()
        capture("S26-obiettivi-dettaglio")
        goToTab("Conti")
        capture("S26-conti")
    }
}
