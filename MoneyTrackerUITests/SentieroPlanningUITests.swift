import XCTest

final class SentieroPlanningUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func capture(language: String, size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        goToTab("Pianifica")
        XCTAssertTrue(app.buttons["planning_budget"].waitForExistence(timeout: 5))
        save("S7-\(language)-\(size)-budget")
        app.swipeUp()
        save("S7-\(language)-\(size)-budget-bottom")
        for _ in 0..<4 {
            if app.buttons["planning_goals"].isHittable { break }
            app.swipeDown()
        }
        app.buttons["planning_goals"].tap()
        let label = language == "de" ? "Fortschritt hinzufügen" : "Aggiungi progresso"
        let add = app.buttons.matching(NSPredicate(format: "label == %@", label)).firstMatch
        XCTAssertTrue(add.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(add.frame.width, 44)
        XCTAssertGreaterThanOrEqual(add.frame.height, 44)
        save("S7-\(language)-\(size)-goals")
        add.tap()
        XCTAssertTrue(app.textFields["tf_goalName"].waitForExistence(timeout: 5))
        app.buttons["btn_cancelAddGoal"].tap()
        app.swipeUp()
        save("S7-\(language)-\(size)-goals-bottom")
        app.terminate()
    }
    @MainActor private func save(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name; attachment.lifetime = .keepAlways; add(attachment)
    }
    @MainActor func testItalian() { capture(language: "it", size: "UICTContentSizeCategoryL") }
    @MainActor func testXL() { capture(language: "it", size: "UICTContentSizeCategoryXL") }
    @MainActor func testGerman() { capture(language: "de", size: "UICTContentSizeCategoryL") }
    @MainActor func testDark() { capture(language: "it", size: "UICTContentSizeCategoryL") }
}
