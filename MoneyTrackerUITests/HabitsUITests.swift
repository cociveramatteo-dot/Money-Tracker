import XCTest

final class HabitsUITests: MoneyTrackerUITestCase {
    @MainActor
    func testOpenHabitsFromStatistics() {
        goToTab("Statistiche")
        let button = app.buttons["btn_openHabits"]
        for _ in 0..<4 where !button.isHittable { app.swipeUp() }
        XCTAssertTrue(button.waitForExistence(timeout: 5))
        button.tap()
        XCTAssertTrue(app.navigationBars["Abitudini"].waitForExistence(timeout: 5))
    }
}
