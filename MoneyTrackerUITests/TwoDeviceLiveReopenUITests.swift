import XCTest

final class TwoDeviceLiveReopenUITests: XCTestCase {
    @MainActor
    func testReopenedAppShowsBothMovements() throws {
        let environment = ProcessInfo.processInfo.environment
        guard let run = environment["MT_LIVE_RUN"], let phase = environment["MT_LIVE_PHASE"] else {
            throw XCTSkip("Richiede lo script della prova a due dispositivi.")
        }
        continueAfterFailure = false
        let app = XCUIApplication()
        app.launchArguments = ["-E2EEnabled", "YES", "-AppleLanguages", "(it)", "-AppleLocale", "it_IT"]
        app.launch()

        let springboard = XCUIApplication(bundleIdentifier: "com.apple.springboard")
        for title in ["Consenti", "Allow"] where springboard.buttons[title].exists {
            springboard.buttons[title].tap()
            break
        }
        let movements = app.buttons["tab_movimenti"]
        XCTAssertTrue(movements.waitForExistence(timeout: 20))
        movements.tap()

        for origin in ["A", "B"] {
            let name = "S51b \(run) \(phase) \(origin)"
            let row = app.staticTexts.matching(
                NSPredicate(format: "label == %@ OR label BEGINSWITH %@", name, name + ",")
            ).firstMatch
            // SwiftData is checked separately for duplicates; accessibility can expose multiple elements per row.
            XCTAssertTrue(row.waitForExistence(timeout: 15), "Movimento \(origin) assente dopo la riapertura")
        }
    }
}
