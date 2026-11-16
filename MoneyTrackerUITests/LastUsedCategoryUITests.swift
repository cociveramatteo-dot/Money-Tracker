import XCTest

final class LastUsedCategoryUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }

    @MainActor private func capture(language: String, size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        let name = uniqueName("Mc")
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "12")
        enterTransactionField("tf_name", text: name)
        app.buttons["btn_categoryPicker"].tap()
        XCTAssertTrue(app.buttons["categoryRow_Cibo"].waitForExistence(timeout: 5))
        app.buttons["categoryRow_Cibo"].tap()
        saveTransactionForm()
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_name", text: name)
        let picker = app.buttons["btn_categoryPicker"]
        let label = language == "de" ? "Zuletzt verwendet" : "Ultima usata"
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@", label), object: picker)], timeout: 5) == .completed)
        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "S30-\(name)-\(language)-\(size)"
        screenshot.lifetime = .keepAlways
        add(screenshot)
        // A manual correction becomes the next suggestion for exactly the same name.
        picker.tap()
        app.buttons["categoryRow_Svago"].tap()
        enterTransactionField("tf_amount", text: "14")
        saveTransactionForm()
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_name", text: name)
        let category = language == "de" ? "Freizeit" : "Svago"
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label CONTAINS %@ AND label CONTAINS %@", label, category),
            object: app.buttons["btn_categoryPicker"])], timeout: 5) == .completed)
        app.buttons["btn_cancelAddTransaction"].tap()
        app.terminate()
    }
    @MainActor func testLight() { capture(language: "it", size: "UICTContentSizeCategoryL") }
    @MainActor func testXL() { capture(language: "it", size: "UICTContentSizeCategoryXL") }
    @MainActor func testGerman() { capture(language: "de", size: "UICTContentSizeCategoryL") }
    // Da eseguire a parte dopo aver impostato l'aspetto scuro reale del simulatore (stessa convenzione di S-6).
    @MainActor func testDark() { capture(language: "it", size: "UICTContentSizeCategoryL") }
}
