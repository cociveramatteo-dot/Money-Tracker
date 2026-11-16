import XCTest

/// Captures the four requested presentation variants without changing existing tests.
final class SentieroStatisticsUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func capture(language: String, size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        goToTab("Statistiche")
        XCTAssertTrue(app.buttons["statistics_pdf"].waitForExistence(timeout: 5))
        save("S6-\(language)-\(size)-top")
        app.buttons["statistics_range_12"].tap()
        XCTAssertTrue(app.buttons["statistics_range_12"].isSelected)
        save("S6-\(language)-\(size)-12M")
        app.buttons["statistics_range_6"].tap()
        app.swipeUp()
        save("S6-\(language)-\(size)-bottom")
        app.terminate()
    }
    @MainActor private func save(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
    @MainActor func testItalian() { capture(language: "it", size: "UICTContentSizeCategoryL") }
    @MainActor func testXL() { capture(language: "it", size: "UICTContentSizeCategoryXL") }
    @MainActor func testGerman() { capture(language: "de", size: "UICTContentSizeCategoryL") }
    // Run separately after setting the simulator's actual appearance to dark.
    @MainActor func testDark() { capture(language: "it", size: "UICTContentSizeCategoryL") }
}
