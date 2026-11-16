import XCTest

final class TabBarAppearanceUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func verify(language: String, size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        let identifiers = ["tab_home", "tab_movimenti", "tab_statistiche", "tab_pianifica", "tab_conti"]
        for identifier in identifiers {
            let button = app.buttons[identifier]
            XCTAssertTrue(button.waitForExistence(timeout: 5))
            XCTAssertTrue(button.isHittable)
            XCTAssertGreaterThanOrEqual(button.frame.width, 44)
            XCTAssertGreaterThanOrEqual(button.frame.height, 44)
            button.tap()
            XCTAssertTrue(button.isSelected)
        }
        app.buttons["tab_movimenti"].tap()
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = "S28-\(language)-\(size)"
        attachment.lifetime = .keepAlways
        add(attachment)
        app.terminate()
    }

    @MainActor func testItalianXL() { verify(language: "it", size: "UICTContentSizeCategoryXL") }
    @MainActor func testGermanXL() { verify(language: "de", size: "UICTContentSizeCategoryXL") }
    @MainActor func testItalianDefault() { verify(language: "it", size: "UICTContentSizeCategoryL") }
}
