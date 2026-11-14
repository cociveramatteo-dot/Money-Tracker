import XCTest

final class RecurrenceFlowUITests: MoneyTrackerUITestCase {
    func testCreateEditAndDeleteScheduledSeries() throws {
        goToTab("Movimenti")
        tapFAB(menuItem: "fabMenu_addTransaction")
        let name = uniqueName("Recurring")
        app.textFields["tf_amount"].tap()
        app.textFields["tf_amount"].typeText("24")
        app.textFields["tf_name"].tap()
        app.textFields["tf_name"].typeText(name)
        // Drag above the software keyboard so swipe typing cannot alter the name.
        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
            .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        let picker = app.buttons["picker_recurrence"]
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()
        app.buttons["Mensile"].tap()
        let save = app.buttons["btn_saveTransaction"]
        if !save.isHittable {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        save.tap()
        let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.press(forDuration: 1.2)
        let recurrence = app.buttons["Ricorrenza"]
        XCTAssertTrue(recurrence.waitForExistence(timeout: 5))
        recurrence.tap()
        XCTAssertTrue(app.buttons["recurrence_scope"].waitForExistence(timeout: 5))
        app.navigationBars.buttons["Annulla"].tap()
        openTransactionsSection("Ricorrenti")
        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5))
        app.buttons["editRecurrence_" + name].tap()
        let scope = app.buttons["recurrence_scope"]
        XCTAssertTrue(scope.waitForExistence(timeout: 5))
        scope.tap()
        app.buttons["Tutte"].tap()
        let field = app.textFields["recurrence_name"]
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: name.count))
        field.typeText(name + "Updated")
        app.navigationBars.buttons["Salva"].tap()
        XCTAssertTrue(app.staticTexts[name + "Updated"].waitForExistence(timeout: 5))
        app.buttons["editRecurrence_" + name + "Updated"].tap()
        app.buttons["recurrence_scope"].tap()
        app.buttons["Tutte"].tap()
        for _ in 0..<4 {
            if app.buttons["Elimina"].exists && app.buttons["Elimina"].isHittable { break }
            app.swipeUp()
        }
        app.buttons["Elimina"].tap()
        app.sheets.buttons["Elimina"].tap()
        XCTAssertFalse(app.staticTexts[name + "Updated"].waitForExistence(timeout: 3))
    }
}
