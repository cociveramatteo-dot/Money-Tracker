import XCTest

final class RecurrenceFlowUITests: MoneyTrackerUITestCase {
    func testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes() throws {
        for (index, scope) in ["Tutte", "Solo questa", "Questa e le successive"].enumerated() {
            goToTab("Movimenti")
            tapFAB(menuItem: "fabMenu_addTransaction")
            let name = uniqueName("DeleteFixed")
            app.textFields["tf_amount"].tap()
            app.textFields["tf_amount"].typeText("24")
            app.textFields["tf_name"].tap()
            app.textFields["tf_name"].typeText(name)
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
            app.switches["toggle_isFixed"].tap()
            // Enabling Fissa makes the transaction planned (isDone = false).
            app.buttons["picker_recurrence"].tap()
            app.buttons["Mensile"].tap()
            let save = app.buttons["btn_saveTransaction"]
            if !save.isHittable { app.swipeUp() }
            save.tap()
            let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", name)).firstMatch
            XCTAssertTrue(row.waitForExistence(timeout: 5))
            row.press(forDuration: 1.2)
            // Both menu entry points must lead to a responsive recurrence editor.
            app.buttons[index == 1 ? "Ricorrenza" : "Elimina"].tap()
            XCTAssertTrue(app.buttons["recurrence_scope"].waitForExistence(timeout: 5))
            app.buttons["recurrence_scope"].tap()
            app.buttons[scope].tap()
            for _ in 0..<5 {
                if app.buttons["Elimina"].isHittable { break }
                app.swipeUp()
            }
            app.buttons["Elimina"].tap()
            app.sheets.buttons["Elimina"].tap()
            XCTAssertTrue(app.buttons["fabButton"].waitForExistence(timeout: 5))
            XCTAssertTrue(NSPredicate(format: "exists == false").evaluate(with: row) ||
                XCTWaiter.wait(for: [XCTNSPredicateExpectation(predicate: NSPredicate(format: "exists == false"), object: row)], timeout: 5) == .completed, "Scope \(scope): selected planned copy must disappear")
            // A real tap after deletion also detects a stuck main thread / lingering sheet.
            goToTab("Home")
            goToTab("Movimenti")
        }
    }

    func testNonRecurringEditCannotCreateSeries() throws {
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        // Use a known non-recurring demo expense; creation is covered separately.
        let row = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", "Supermercato")).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.textFields["tf_name"].waitForExistence(timeout: 5))
        app.swipeUp()
        XCTAssertFalse(app.buttons["picker_recurrence"].exists)
        XCTAssertFalse(app.buttons["recurrence_scope"].exists)
        app.buttons["btn_cancelAddTransaction"].tap()
    }

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
        XCTAssertTrue(row.label.contains("Ricorrenza"))
        row.tap()
        XCTAssertTrue(app.textFields["tf_name"].waitForExistence(timeout: 5))
        XCTAssertFalse(app.buttons["picker_recurrence"].exists)
        app.buttons["btn_categoryPicker"].tap()
        app.buttons["categoryRow_Casa"].tap()
        for _ in 0..<4 {
            if app.buttons["btn_saveTransaction"].isHittable { break }
            app.swipeUp()
        }
        app.buttons["btn_saveTransaction"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["btn_categoryPicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["btn_categoryPicker"].label.contains("Casa"))
        app.buttons["btn_cancelAddTransaction"].tap()
        row.press(forDuration: 1.2)
        let recurrence = app.buttons["Ricorrenza"]
        XCTAssertTrue(recurrence.waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["Elimina"].exists)
        recurrence.tap()
        XCTAssertTrue(app.buttons["recurrence_scope"].waitForExistence(timeout: 5))
        // Category is editable with Solo questa too; its override must survive reopening.
        app.swipeUp()
        app.buttons["recurrence_category"].tap()
        let singleCategory = app.collectionViews.buttons["Salute"]
        XCTAssertTrue(singleCategory.waitForExistence(timeout: 5))
        if !singleCategory.isHittable { app.collectionViews.buttons["Altro"].swipeDown() }
        singleCategory.tap()
        app.navigationBars.buttons["Salva"].tap()
        XCTAssertTrue(row.waitForExistence(timeout: 5))
        row.tap()
        XCTAssertTrue(app.buttons["btn_categoryPicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["btn_categoryPicker"].label.contains("Salute"))
        app.buttons["btn_cancelAddTransaction"].tap()
        row.press(forDuration: 1.2)
        app.buttons["Ricorrenza"].tap()
        let scope = app.buttons["recurrence_scope"]
        XCTAssertTrue(scope.waitForExistence(timeout: 5))
        scope.tap()
        app.buttons["Tutte"].tap()
        // The normal editor now updates the entire series, including its category.
        XCTAssertTrue(app.buttons["recurrence_category"].label.contains("Casa"))
        let field = app.textFields["recurrence_name"]
        field.tap()
        field.typeText(String(repeating: XCUIKeyboardKey.delete.rawValue, count: name.count))
        field.typeText(name + "Updated")
        // Bring the category row above the keyboard before opening its menu.
        app.swipeUp()
        let categoryPicker = app.buttons["recurrence_category"]
        XCTAssertTrue(categoryPicker.isHittable)
        categoryPicker.tap()
        let categoryChoice = app.collectionViews.buttons["Salute"]
        XCTAssertTrue(categoryChoice.waitForExistence(timeout: 5))
        if !categoryChoice.isHittable {
            app.collectionViews.buttons["Altro"].swipeDown()
        }
        XCTAssertTrue(categoryChoice.isHittable, app.debugDescription)
        categoryChoice.tap()
        XCTAssertTrue(categoryPicker.label.contains("Salute"))
        app.navigationBars.buttons["Salva"].tap()
        let updatedRow = app.staticTexts.matching(NSPredicate(format: "label BEGINSWITH %@", name + "Updated")).firstMatch
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
        updatedRow.tap()
        XCTAssertTrue(app.buttons["btn_categoryPicker"].waitForExistence(timeout: 5))
        XCTAssertTrue(app.buttons["btn_categoryPicker"].label.contains("Salute"))
        app.buttons["btn_cancelAddTransaction"].tap()
        updatedRow.press(forDuration: 1.2)
        app.buttons["Ricorrenza"].tap()
        app.buttons["recurrence_scope"].tap()
        app.buttons["Tutte"].tap()
        XCTAssertTrue(app.buttons["recurrence_category"].label.contains("Salute"))
        for _ in 0..<4 {
            if app.buttons["Elimina"].exists && app.buttons["Elimina"].isHittable { break }
            app.swipeUp()
        }
        app.buttons["Elimina"].tap()
        app.sheets.buttons["Elimina"].tap()
        // Deletion preserves completed history, but the surviving copy has no active series.
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "NOT (label CONTAINS %@)", "Ricorrenza"), object: updatedRow)], timeout: 5) == .completed)
        goToTab("Home")
    }
}
