import XCTest

final class RecurrenceCancelAndHomeUITests: MoneyTrackerUITestCase {
    @MainActor
    func testCancelProgrammedSeriesDeletion() {
        goToTab("Movimenti")
        openTransactionsSection("Ricorrenti")
        enterTransactionField("tf_searchTransactions", text: "Bolletta Enel\n")
        let bill = app.buttons["editRecurrence_Bolletta Enel"].firstMatch
        XCTAssertTrue(bill.waitForExistence(timeout: 5))
        bill.tap()

        let scope = app.buttons["recurrence_scope"]
        XCTAssertTrue(scope.waitForExistence(timeout: 5))
        scope.tap()
        app.buttons["Tutte"].tap()
        let delete = app.buttons["Elimina"].firstMatch
        for _ in 0..<3 where !delete.isHittable { app.swipeUp() }
        XCTAssertTrue(delete.isHittable)
        delete.tap()
        let confirmation = app.sheets.firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        capture("series-delete-confirmation")
        let cancelConfirmation = confirmation.buttons["Annulla"]
        if cancelConfirmation.exists {
            cancelConfirmation.tap()
        } else {
            // A popover may expose only the destructive button; tap outside to cancel.
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)).tap()
        }
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: confirmation)], timeout: 5) == .completed)
        let editor = app.navigationBars["Ricorrenza"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.buttons["Annulla"].tap()
        XCTAssertTrue(bill.waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground)
        capture("series-after-cancel")
        bill.tap()
        XCTAssertTrue(scope.waitForExistence(timeout: 5))
    }

    @MainActor
    func testCancelDeletionOpenedFromOccurrenceSwipe() {
        goToTab("Movimenti")
        openTransactionsSection("Fisse")
        enterTransactionField("tf_searchTransactions", text: "Bolletta Enel\n")
        let occurrence = transactionRow(named: "Bolletta Enel")
        swipeToDeleteTransaction(named: "Bolletta Enel")
        let editor = app.navigationBars["Ricorrenza"]
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
        editor.buttons["Annulla"].tap()
        XCTAssertTrue(occurrence.waitForExistence(timeout: 5))
        XCTAssertEqual(app.state, .runningForeground)
        capture("occurrence-after-swipe-cancel")
        swipeToDeleteTransaction(named: "Bolletta Enel")
        XCTAssertTrue(editor.waitForExistence(timeout: 5))
    }

    @MainActor
    func testHomeRecentMovements() {
        goToTab("Home")
        let start = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.72))
        let end = app.coordinate(withNormalizedOffset: CGVector(dx: 0.20, dy: 0.32))
        start.press(forDuration: 0.05, thenDragTo: end)
        start.press(forDuration: 0.05, thenDragTo: end)
        XCTAssertTrue(app.buttons["Vedi tutti"].isHittable)
        capture("home-recent-movements")
    }

    @MainActor
    private func capture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
