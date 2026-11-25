import XCTest

final class E2ESettingsOffUITests: MoneyTrackerUITestCase {
    @MainActor func testSecuritySettingsStayUnchangedWithFeatureOff() {
        let settings = app.buttons["Impostazioni"]
        XCTAssertTrue(settings.waitForExistence(timeout: 8))
        settings.tap()

        let history = app.buttons["Cronologia modifiche"]
        let scroll = app.scrollViews.firstMatch
        for _ in 0..<5 where !history.isHittable { scroll.swipeUp() }
        XCTAssertTrue(history.isHittable)
        XCTAssertTrue(app.staticTexts["Blocco con Face ID"].exists)
        XCTAssertFalse(app.buttons["e2e_settings"].exists)

        let screenshot = XCTAttachment(screenshot: app.screenshot())
        screenshot.name = "sicurezza-interruttore-spento"
        screenshot.lifetime = .keepAlways
        add(screenshot)
    }
}

@MainActor
final class E2EUITests: XCTestCase {
    private let app = XCUIApplication()
    private var originalAppearance: XCUIDevice.Appearance = .light
    private let phrase = "correct horse battery staple"
    private var configuration: String {
        ProcessInfo.processInfo.environment["E2E_SCREENSHOTS"] ?? "it-light"
    }
    private var language: String { String(configuration.prefix(2)) }
    private var cancelLabel: String {
        switch language {
        case "en": "Cancel"
        case "de": "Abbrechen"
        default: "Annulla"
        }
    }
    private var visualSweep: Bool { ProcessInfo.processInfo.environment["E2E_SCREENSHOTS"] != nil }

    override func setUp() async throws {
        await MainActor.run {
            continueAfterFailure = false
            originalAppearance = XCUIDevice.shared.appearance
            XCUIDevice.shared.appearance = configuration.contains("-dark") ? .dark : .light
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            app.terminate()
            XCUIDevice.shared.appearance = originalAppearance
        }
    }

    func testActivationValidationAndDisableConfirmation() throws {
        launch()
        let activation = app.buttons["e2e_activate"]
        XCTAssertTrue(activation.waitForExistence(timeout: 15))
        if language == "de" {
            XCTAssertEqual(activation.label, "Erweiterten Schutz aktivieren")
        }
        screenshot("01-spenta")
        tap(activation)

        let first = app.secureTextFields["e2e_phrase"]
        let second = app.secureTextFields["e2e_repeat"]
        let next = app.buttons["e2e_continue"]
        screenshot("02-frase", when: first)
        tap(next)
        let validation = app.staticTexts["e2e_phrase_error"]
        XCTAssertTrue(validation.exists)
        if language == "it" { XCTAssertEqual(validation.label, "La frase deve avere almeno 10 caratteri.") }
        screenshot("02-frase-corta")

        type(phrase, in: first)
        type("different phrase", in: second)
        tap(next)
        XCTAssertTrue(validation.exists)
        if language == "it" { XCTAssertEqual(validation.label, "Le due frasi non coincidono.") }
        type(phrase, in: second, replacing: "different phrase")
        tap(next)
        try acknowledgeKey(capture: "03-recupero")
        if visualSweep { screenshot("04-cifratura", when: app.staticTexts["e2e_progress"]) }

        let active = app.staticTexts["e2e_active"]
        XCTAssertTrue(active.waitForExistence(timeout: 15))
        screenshot("04-completata")
        tap(app.buttons["e2e_close"])
        XCTAssertTrue(active.waitForExistence(timeout: 5))
        screenshot("05-attiva")

        tap(app.buttons["e2e_disable"])
        let confirmation = app.alerts.firstMatch
        XCTAssertTrue(confirmation.waitForExistence(timeout: 5))
        screenshot("05-disattiva-conferma")
        tap(confirmation.buttons.matching(NSPredicate(format: "label != %@", cancelLabel)).firstMatch)
        if visualSweep { screenshot("05-disattiva-in-corso", when: app.staticTexts["e2e_progress"]) }
        XCTAssertTrue(activation.waitForExistence(timeout: 15))
    }

    func testUnlockRejectsWrongPhraseAndPromptsOnce() {
        launch(.locked)
        let field = app.secureTextFields["e2e_unlock_secret"]
        screenshot("06-sblocco", when: field)
        type("incorrect phrase", in: field)
        tap(app.buttons["e2e_unlock"])
        let error = app.staticTexts["e2e_unlock_error"]
        XCTAssertTrue(error.waitForExistence(timeout: 12))
        if language == "it" { XCTAssertEqual(error.label, "Frase o chiave non corretta.") }
        screenshot("06-frase-errata")
        tap(app.buttons["e2e_unlock_method"])
        screenshot("06-sblocco-con-chiave", when: app.secureTextFields["e2e_repeat"])
        tap(app.buttons["e2e_restart"])
        XCTAssertTrue(app.alerts.firstMatch.waitForExistence(timeout: 5))
        screenshot("07-ricomincia")
        tap(app.alerts.firstMatch.buttons[cancelLabel])

        tap(app.buttons["e2e_close"])
        XCTAssertFalse(field.exists)
        tap(app.buttons["e2e_unlock_open"])
        type(phrase, in: field)
        tap(app.buttons["e2e_unlock"])
        XCTAssertTrue(app.staticTexts["e2e_active"].waitForExistence(timeout: 15))
    }

    func testShowsTransitionAndAllowsChangingPhrase() {
        launch(.transition)
        screenshot("06-altro-dispositivo", when: app.secureTextFields["e2e_unlock_secret"])
        app.terminate()
        launch(.locked)
        let field = app.secureTextFields["e2e_unlock_secret"]
        type(phrase, in: field)
        tap(app.buttons["e2e_unlock"])
        XCTAssertTrue(app.staticTexts["e2e_active"].waitForExistence(timeout: 15))
        let change = app.buttons["e2e_change_phrase"]
        tap(change)
        let first = app.secureTextFields["e2e_phrase"]
        screenshot("08-cambia-frase", when: first)
        type("changed security phrase", in: first)
        type("changed security phrase", in: app.secureTextFields["e2e_repeat"])
        tap(app.buttons["e2e_continue"])
        screenshot("08-frase-aggiornata", when: app.staticTexts["e2e_phrase_updated"])
    }

    func testActivationRetriesAfterNetworkLoss() throws {
        launch(.offline)
        try beginActivation()
        let error = app.staticTexts["e2e_migration_error"]
        XCTAssertTrue(error.waitForExistence(timeout: 15))
        if language == "it" { XCTAssertEqual(error.label, "Serve una connessione a Internet.") }
        screenshot("04-senza-rete")
        tap(app.buttons["e2e_retry"])
        XCTAssertTrue(app.staticTexts["e2e_active"].waitForExistence(timeout: 15))
    }

    func testInterruptedActivationCanBeCancelled() throws {
        launch(.interrupted)
        try beginActivation()
        screenshot("04-errore", when: app.staticTexts["e2e_migration_error"])
        tap(app.buttons["e2e_cancel"])
        XCTAssertTrue(app.buttons["e2e_activate"].waitForExistence(timeout: 15))
    }

    func testNewKeyCannotCompleteAnEarlierActivation() throws {
        launch(.priorAttempt)
        try beginActivation()
        XCTAssertTrue(app.staticTexts["e2e_migration_error"].waitForExistence(timeout: 15))
        XCTAssertFalse(app.staticTexts["e2e_active"].exists)
        XCTAssertTrue(app.buttons["e2e_cancel"].exists)
    }

    private enum Fixture: String {
        case off, locked, transition, offline, interrupted, priorAttempt
    }

    private func launch(_ fixture: Fixture = .off) {
        app.launchArguments = [
            "-E2EEnabled", "YES", "-E2EUITestHarness", "YES", "-E2EFixture", fixture.rawValue,
            "-AppleLanguages", "(\(language))",
            "-UIPreferredContentSizeCategoryName",
            configuration.hasSuffix("-xl") ? "UICTContentSizeCategoryXL" : "UICTContentSizeCategoryL"
        ]
        if visualSweep, fixture == .off { app.launchArguments += ["-E2ECaptureProgress", "YES"] }
        app.launch()
    }

    private func beginActivation() throws {
        tap(app.buttons["e2e_activate"])
        type(phrase, in: app.secureTextFields["e2e_phrase"])
        type(phrase, in: app.secureTextFields["e2e_repeat"])
        tap(app.buttons["e2e_continue"])
        try acknowledgeKey()
    }

    private func acknowledgeKey(capture: String? = nil) throws {
        let key = app.staticTexts["e2e_recovery_key"]
        XCTAssertTrue(key.waitForExistence(timeout: 5))
        let groups = key.label.split { $0 == "-" || $0.isWhitespace }
        XCTAssertEqual(groups.count, 8)
        XCTAssertTrue(groups.allSatisfy { $0.count == 4 })
        let last = try XCTUnwrap(groups.last)
        let saved = app.buttons["e2e_key_saved"]
        XCTAssertFalse(saved.isEnabled)
        if let capture { screenshot(capture) }
        let confirmation = app.textFields["e2e_key_confirmation"]
        type(last.lowercased(), in: confirmation)
        XCTAssertTrue(saved.isEnabled)
        tap(saved)
    }

    private func type(_ value: String, in field: XCUIElement, replacing old: String = "") {
        tap(field)
        if !old.isEmpty { field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: old.count)) }
        field.typeText(value + "\n")
    }

    private func tap(_ element: XCUIElement, file: StaticString = #filePath, line: UInt = #line) {
        XCTAssertTrue(element.waitForExistence(timeout: 10), file: file, line: line)
        for _ in 0..<5 {
            if element.isHittable { break }
            app.scrollViews.firstMatch.swipeUp()
        }
        XCTAssertTrue(element.isHittable, file: file, line: line)
        element.tap()
    }

    private func screenshot(_ name: String, when element: XCUIElement? = nil) {
        if let element { XCTAssertTrue(element.waitForExistence(timeout: 12)) }
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = "e2e-\(configuration)-\(name)"
        shot.lifetime = .keepAlways
        add(shot)
    }
}
