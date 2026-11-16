import XCTest

final class SentieroAccountsUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws { continueAfterFailure = false }
    @MainActor private func launch(language: String, size: String) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(\(language))", "-AppleLocale", language,
                               "-UIPreferredContentSizeCategoryName", size]
        app.launch()
        goToTab("Conti")
        XCTAssertTrue(app.staticTexts["accounts_total"].waitForExistence(timeout: 5))
    }
    @MainActor private func capture(language: String, size: String) {
        launch(language: language, size: size)
        save("S8-\(language)-\(size)-top")
        app.swipeUp()
        save("S8-\(language)-\(size)-bottom")
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

    /// Only the deterministic demo store is mutated; normal launch resets it.
    @MainActor func testAccountMenus() {
        launch(language: "it", size: "UICTContentSizeCategoryXL")
        let account = app.staticTexts["Conto Corrente"]
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        let total = app.staticTexts["accounts_total"]
        let initial = total.label
        account.press(forDuration: 1)
        XCTAssertTrue(app.buttons["account_edit"].waitForExistence(timeout: 3))
        XCTAssertTrue(app.buttons["account_archive"].exists)
        app.buttons["account_exclude"].tap()
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initial), object: total)], timeout: 5) == .completed)
        save("S8-excluded-XL")
        account.press(forDuration: 1)
        XCTAssertEqual(app.buttons["account_exclude"].label, "Includi nel totale")
        app.buttons["account_exclude"].tap()
        account.press(forDuration: 1)
        app.buttons["account_archive"].tap()
        let archived = app.buttons["accounts_archived"]
        for _ in 0..<4 {
            if archived.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(archived.waitForExistence(timeout: 5))
        save("S8-archived-collapsed-XL")
        archived.tap()
        app.swipeUp()
        XCTAssertTrue(account.waitForExistence(timeout: 5))
        save("S8-archived-expanded-XL")
        account.press(forDuration: 1)
        XCTAssertTrue(app.buttons["account_restore"].waitForExistence(timeout: 3))
        app.buttons["account_restore"].tap()
        for _ in 0..<4 {
            if total.isHittable { break }
            app.swipeDown()
        }
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label == %@", initial), object: total)], timeout: 5) == .completed)
        app.terminate()
    }
    @MainActor func testThresholdPresentation() {
        launch(language: "it", size: "UICTContentSizeCategoryXL")
        app.staticTexts["Conto Corrente"].tap()
        XCTAssertTrue(app.textFields["tf_accountName"].waitForExistence(timeout: 5))
        let threshold = app.textFields.element(boundBy: 2)
        for _ in 0..<4 {
            if threshold.isHittable { break }
            app.swipeUp()
        }
        threshold.tap()
        threshold.typeText("9999999")
        let save = app.buttons["btn_saveAccount"]
        for _ in 0..<4 {
            if save.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        save.tap()
        let warning = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Sotto la soglia di")).firstMatch
        XCTAssertTrue(warning.waitForExistence(timeout: 5))
        self.save("S8-threshold-XL")
        app.terminate()
    }

    @MainActor func testHiddenBalances() {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-hideBalance", "YES", "-AppleLanguages", "(it)",
                               "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryXL"]
        app.launch()
        goToTab("Conti")
        let total = app.staticTexts["accounts_total"]
        XCTAssertTrue(total.waitForExistence(timeout: 5))
        XCTAssertEqual(total.label, "Saldo nascosto")
        save("S8-hidden-XL")
        app.terminate()
    }

}
