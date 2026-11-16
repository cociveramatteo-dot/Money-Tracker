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
        let bill = app.buttons["editRecurrence_Bolletta Enel"]
        for _ in 0..<6 {
            if bill.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(bill.isHittable)
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
