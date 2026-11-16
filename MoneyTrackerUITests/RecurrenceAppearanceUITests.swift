import XCTest

/// Visual evidence for S-18; existing functional UI tests remain unchanged.
final class RecurrenceAppearanceUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor
    private func captureAppearance(language: String, style: String, size: String = "UICTContentSizeCategoryL") {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        goToTab("Movimenti")
        openTransactionsSection("Ricorrenti")
        let next = app.buttons.matching(NSPredicate(format: "identifier BEGINSWITH %@", "editRecurrence_")).firstMatch
        XCTAssertTrue(next.waitForExistence(timeout: 5))
        saveCapture("S18-\(language)-\(style)-\(size)-series")
        next.tap()
        XCTAssertTrue(app.buttons["recurrence_scope"].waitForExistence(timeout: 5))
        app.buttons[language == "de" ? "Abbrechen" : "Annulla"].tap()
        navigateBack()
        app.buttons["btn_monthPicker"].tap()
        app.buttons[language == "de" ? "Nächster Monat" : "Mese successivo"].tap()
        saveCapture("S18-\(language)-\(style)-\(size)-virtual")
        app.terminate()
    }

    @MainActor private func saveCapture(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor func testLight() { captureAppearance(language: "it", style: "Light") }
    // Run separately after `xcrun simctl ui <device> appearance dark`; launch defaults do not override system appearance.
    @MainActor func testDark() { captureAppearance(language: "it", style: "Dark") }
    @MainActor func testExtraLarge() { captureAppearance(language: "it", style: "Light", size: "UICTContentSizeCategoryXL") }
    @MainActor func testGerman() { captureAppearance(language: "de", style: "Light") }
}
