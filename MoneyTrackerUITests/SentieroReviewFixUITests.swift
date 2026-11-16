import XCTest

/// Evidence for the two review fixes; existing tests remain unchanged.
final class SentieroReviewFixUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func capture(size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(it)", "-AppleLocale", "it",
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        goToTab("Pianifica")
        verifyPlanning("budget")
        app.buttons["planning_goals"].tap()
        verifyPlanning("goals")
        goToTab("Conti")
        let account = app.staticTexts["Conto Corrente"]
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        account.press(forDuration: 1)
        app.buttons["account_archive"].tap()
        let archived = app.buttons["accounts_archived"]
        for _ in 0..<4 {
            if archived.isHittable { break }
            app.swipeUp()
        }
        archived.tap()
        app.swipeUp()
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        save("review-archived-\(size)")
        account.press(forDuration: 1)
        XCTAssertTrue(app.buttons["account_restore"].waitForExistence(timeout: 3))
        app.buttons["account_restore"].tap()
        XCTAssertFalse(archived.exists)
        app.terminate()
    }

    @MainActor private func verifyPlanning(_ section: String) {
        let fab = app.buttons["fabButton"]
        let collection = app.scrollViews.firstMatch
        XCTAssertTrue(collection.waitForExistence(timeout: 5))
        XCTAssertLessThanOrEqual(collection.frame.maxY, fab.frame.minY)
        save("review-\(section)-initial")
        app.swipeUp()
        save("review-\(section)-bottom")
        for _ in 0..<4 {
            if app.buttons["planning_goals"].isHittable { break }
            app.swipeDown()
        }
    }
    @MainActor private func save(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testLight() { capture(size: "UICTContentSizeCategoryL") }
    @MainActor func testXL() { capture(size: "UICTContentSizeCategoryXL") }
    // Run after setting actual simulator appearance to dark.
    @MainActor func testDark() { capture(size: "UICTContentSizeCategoryL") }
}
