import XCTest

final class WhatIfUITests: MoneyTrackerUITestCase {
    private var originalAppearance: XCUIDevice.Appearance = .light

    override func setUpWithError() throws {
        continueAfterFailure = false
        originalAppearance = XCUIDevice.shared.appearance
    }

    override func tearDownWithError() throws {
        XCUIDevice.shared.appearance = originalAppearance
        app = nil
    }

    @MainActor
    private func attach(_ name: String) {
        Thread.sleep(forTimeInterval: 0.4)
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    @MainActor
    private func launch(args: [String]) {
        app = XCUIApplication()
        app.launchArguments = ["--uitesting"] + args
        app.launch()
    }

    @MainActor
    private func dismissKeyboard() {
        let kbDone = app.buttons["whatIf.keyboardDone"]
        if kbDone.waitForExistence(timeout: 1.5), kbDone.isHittable {
            kbDone.tap()
        } else if app.keyboards.count > 0 {
            app.swipeDown()
        }
    }

    @MainActor
    func testWhatIfFlowLightDarkAndHiddenBalances() throws {
        XCUIDevice.shared.appearance = .light
        launch(args: ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT"])

        let calc = app.buttons["home.whatIfButton"]
        let eye = app.buttons["Oscura importi"]
        let gear = app.buttons["Impostazioni"]
        XCTAssertTrue(calc.waitForExistence(timeout: 5))
        XCTAssertTrue(eye.waitForExistence(timeout: 5))
        XCTAssertTrue(gear.waitForExistence(timeout: 5))
        XCTAssertLessThan(calc.frame.minX, eye.frame.minX)
        XCTAssertLessThan(eye.frame.minX, gear.frame.minX)
        attach("home-header-it-light")

        calc.tap()
        XCTAssertTrue(app.buttons["whatIf.done"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["whatIf.accountMenu"].waitForExistence(timeout: 5))
        let todayBefore = app.staticTexts["whatIf.result.today.now"].label

        app.buttons["whatIf.addHypothesis"].tap()
        let amount0 = app.textFields["whatIf.row.0.amount"]
        XCTAssertTrue(amount0.waitForExistence(timeout: 3))
        amount0.tap()
        amount0.typeText("150")
        let name0 = app.textFields["whatIf.row.0.name"]
        name0.tap()
        name0.typeText("cena")

        let delta = app.staticTexts["whatIf.result.delta"]
        XCTAssertTrue(delta.label.contains("150"))

        let toggle0 = app.switches["whatIf.row.0.toggle"]
        toggle0.tap()
        XCTAssertTrue(delta.label.contains("0"))

        app.buttons["whatIf.row.0.sign"].tap()
        toggle0.tap()
        XCTAssertTrue(delta.label.contains("+"))

        // Add second hypothesis and capture light screenshot with 2 items (-150 cena, +350 lavoretto)
        app.buttons["whatIf.row.0.sign"].tap() // back to minus on row 0
        dismissKeyboard()
        let addBtn = app.buttons["whatIf.addHypothesis"]
        XCTAssertTrue(addBtn.waitForExistence(timeout: 3))
        addBtn.tap()
        let sign1 = app.buttons["whatIf.row.1.sign"]
        XCTAssertTrue(sign1.waitForExistence(timeout: 3))
        sign1.tap() // plus on row 1
        let amount1 = app.textFields["whatIf.row.1.amount"]
        XCTAssertTrue(amount1.waitForExistence(timeout: 3))
        amount1.tap()
        amount1.typeText("350")
        let name1 = app.textFields["whatIf.row.1.name"]
        name1.tap()
        name1.typeText("lavoretto")
        dismissKeyboard()
        attach("whatif-it-light")

        // Close and reopen: hypotheses must be cleared and baseline unchanged
        app.buttons["whatIf.done"].tap()
        XCTAssertTrue(calc.waitForExistence(timeout: 5))
        calc.tap()
        XCTAssertTrue(app.buttons["whatIf.done"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.textFields["whatIf.row.0.amount"].exists)
        XCTAssertEqual(app.staticTexts["whatIf.result.today.now"].label, todayBefore)

        // Hidden balance launch
        app.terminate()
        launch(args: ["-hideBalance", "YES", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"])
        XCTAssertTrue(app.buttons["home.whatIfButton"].waitForExistence(timeout: 5))
        app.buttons["home.whatIfButton"].tap()
        XCTAssertTrue(app.buttons["whatIf.done"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.staticTexts["whatIf.result.today.now"].label.contains("••••"))
        XCTAssertTrue(app.staticTexts["whatIf.result.end.with"].label.contains("••••"))
        app.buttons["whatIf.addHypothesis"].tap()
        let hiddenAmt = app.textFields["whatIf.row.0.amount"]
        hiddenAmt.tap()
        hiddenAmt.typeText("150")
        dismissKeyboard()
        XCTAssertTrue(app.staticTexts["whatIf.result.delta"].label.contains("150"))
        attach("whatif-oscurati")
    }

    @MainActor
    func testWhatIfDarkScreenshot() throws {
        launch(args: ["-AppleLanguages", "(it)", "-AppleLocale", "it_IT"])
        XCTAssertTrue(app.buttons["home.whatIfButton"].waitForExistence(timeout: 5))
        app.buttons["home.whatIfButton"].tap()
        XCTAssertTrue(app.buttons["whatIf.done"].waitForExistence(timeout: 5))
        app.buttons["whatIf.addHypothesis"].tap()
        app.textFields["whatIf.row.0.amount"].tap()
        app.textFields["whatIf.row.0.amount"].typeText("150")
        app.textFields["whatIf.row.0.name"].tap()
        app.textFields["whatIf.row.0.name"].typeText("cena")
        dismissKeyboard()
        app.buttons["whatIf.addHypothesis"].tap()
        XCTAssertTrue(app.buttons["whatIf.row.1.sign"].waitForExistence(timeout: 3))
        app.buttons["whatIf.row.1.sign"].tap()
        app.textFields["whatIf.row.1.amount"].tap()
        app.textFields["whatIf.row.1.amount"].typeText("350")
        app.textFields["whatIf.row.1.name"].tap()
        app.textFields["whatIf.row.1.name"].typeText("lavoretto")
        dismissKeyboard()
        attach("whatif-it-dark")
    }

    @MainActor
    func testGermanAccessibilityXLHeaderAndSheet() throws {
        XCUIDevice.shared.appearance = .light
        launch(args: [
            "-AppleLanguages", "(de)",
            "-AppleLocale", "de_DE",
            "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryAccessibilityXL",
        ])

        let calc = app.buttons["home.whatIfButton"]
        let eye = app.buttons["Beträge ausblenden"]
        let gear = app.buttons["Einstellungen"]
        XCTAssertTrue(calc.waitForExistence(timeout: 5))
        XCTAssertTrue(eye.waitForExistence(timeout: 5))
        XCTAssertTrue(gear.waitForExistence(timeout: 5))
        XCTAssertGreaterThanOrEqual(calc.frame.width, 44)
        XCTAssertGreaterThanOrEqual(eye.frame.width, 44)
        XCTAssertGreaterThanOrEqual(gear.frame.width, 44)
        XCTAssertLessThan(calc.frame.maxX, eye.frame.minX + 0.5)
        XCTAssertLessThan(eye.frame.maxX, gear.frame.minX + 0.5)
        attach("home-header-de-axxl")

        calc.tap()
        XCTAssertTrue(app.buttons["whatIf.done"].waitForExistence(timeout: 5))
        app.buttons["whatIf.addHypothesis"].tap()
        let amt0 = app.textFields["whatIf.row.0.amount"]
        XCTAssertTrue(amt0.waitForExistence(timeout: 3))
        amt0.tap()
        amt0.typeText("150")
        let name0 = app.textFields["whatIf.row.0.name"]
        name0.tap()
        name0.typeText("Abendessen")
        dismissKeyboard()

        app.buttons["whatIf.addHypothesis"].tap()
        let amt1 = app.textFields["whatIf.row.1.amount"]
        XCTAssertTrue(amt1.waitForExistence(timeout: 3))
        amt1.tap()
        amt1.typeText("abc")
        dismissKeyboard()
        attach("whatif-de-axxl")
    }
}
