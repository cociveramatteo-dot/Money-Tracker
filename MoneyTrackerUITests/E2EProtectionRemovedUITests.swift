import XCTest

/// Captures the «Protezione avanzata disattivata» sheet (`protectionRemoved`)
/// in light and dark mode, plus the sign-out confirmation.
@MainActor
final class E2EProtectionRemovedUITests: XCTestCase {
    private let app = XCUIApplication()
    private var originalAppearance: XCUIDevice.Appearance = .light

    override func setUp() async throws {
        await MainActor.run {
            continueAfterFailure = false
            originalAppearance = XCUIDevice.shared.appearance
        }
    }

    override func tearDown() async throws {
        await MainActor.run {
            app.terminate()
            XCUIDevice.shared.appearance = originalAppearance
        }
    }

    func testProtectionRemovedSheetInLightAndDark() {
        for (appearance, suffix) in [(XCUIDevice.Appearance.light, "light"), (.dark, "dark")] {
            XCUIDevice.shared.appearance = appearance
            app.terminate()
            app.launchArguments = [
                "-E2EEnabled", "YES", "-E2EUITestHarness", "YES", "-E2EFixture", "removed",
                "-AppleLanguages", "(it)",
                "-UIPreferredContentSizeCategoryName", "UICTContentSizeCategoryL"
            ]
            app.launch()

            XCTAssertTrue(app.staticTexts["e2e_protection_removed"].waitForExistence(timeout: 20))
            let continueButton = app.buttons["e2e_continue_unprotected"]
            let signOut = app.buttons["e2e_sign_out"]
            XCTAssertTrue(continueButton.waitForExistence(timeout: 5))
            XCTAssertTrue(signOut.exists)
            capture("protezione-rimossa-\(suffix)")

            // The settings page behind the sheet shows the same actions: tap the visible one.
            let visible = app.buttons.matching(identifier: "e2e_sign_out").allElementsBoundByIndex
                .first { $0.isHittable }
            XCTAssertNotNil(visible)
            visible?.tap()
            // iOS 26 shows the confirmation as a popover with no cancel button.
            let dialog = app.sheets["Esci dall'account?"]
            XCTAssertTrue(dialog.waitForExistence(timeout: 5))
            XCTAssertTrue(dialog.buttons["Esci"].exists)
            sleep(1) // let the popover finish its appearance animation
            capture("protezione-rimossa-esci-\(suffix)")
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.85)).tap()
            XCTAssertTrue(dialog.waitForNonExistence(timeout: 5))
            XCTAssertTrue(signOut.waitForExistence(timeout: 5))
        }
    }

    private func capture(_ name: String) {
        let shot = XCTAttachment(screenshot: app.screenshot())
        shot.name = name
        shot.lifetime = .keepAlways
        add(shot)
    }
}
