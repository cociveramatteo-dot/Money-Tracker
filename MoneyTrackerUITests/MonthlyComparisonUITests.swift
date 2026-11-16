import XCTest

final class MonthlyComparisonUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func capture(language: String, size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        goToTab("Statistiche")
        let heading = app.staticTexts["statistics_comparison_title"]
        for _ in 0..<5 {
            if heading.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(heading.waitForExistence(timeout: 5))
        if heading.frame.minY > 180 {
            heading.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.18)))
        }
        let total = app.staticTexts["statistics_comparison_total"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertFalse(total.label.contains("[DA COMPLETARE]"))
        for index in 0..<5 {
            let attachment = XCTAttachment(screenshot: app.screenshot())
            attachment.name = "S14-\(language)-\(size)-\(index)"
            attachment.lifetime = .keepAlways; add(attachment)
            if app.staticTexts["statistics_categories_title"].isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.65))
                .press(forDuration: 0.05,
                       thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.4)),
                       withVelocity: .slow, thenHoldForDuration: 0.2)
        }
        XCTAssertTrue(app.staticTexts["statistics_categories_title"].isHittable)
        app.terminate()
    }
    @MainActor func testItalian() { capture(language: "it", size: "UICTContentSizeCategoryL") }
    @MainActor func testXL() { capture(language: "it", size: "UICTContentSizeCategoryXL") }
    @MainActor func testGerman() { capture(language: "de", size: "UICTContentSizeCategoryL") }
    @MainActor func testDark() { capture(language: "it", size: "UICTContentSizeCategoryL") }
}
