import XCTest

/// S-73i: aprendo dalla card «Da confermare» un movimento pianificato di un mese passato,
/// il form mantiene l'interruttore «Già effettuato» visibile anche per i non fissi
/// (wasPlannedOnOpen == true) e non lo fa sparire quando l'utente lo attiva.
final class OverduePlannedFormUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(it)", "-AppleLocale", "it"]
        app.launch()
    }

    @MainActor
    private func pickPreviousMonthDay(_ day: Int = 15) {
        let picker = app.datePickers["picker_date"]
        for _ in 0..<4 {
            if picker.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(picker.waitForExistence(timeout: 5))
        picker.tap()

        let prevCandidates = [
            "DatePicker.PreviousMonth",
            "Mostra il mese precedente", "Mese precedente", "Precedente", "Indietro", "Previous Month",
        ]
        let prevBtn = app.buttons.matching(
            NSPredicate(format: "identifier IN %@ OR label IN %@", prevCandidates, prevCandidates)
        ).firstMatch
        XCTAssertTrue(prevBtn.waitForExistence(timeout: 3))
        prevBtn.tap()

        let cal = Calendar(identifier: .gregorian)
        let prevMonth = cal.date(byAdding: .month, value: -1, to: Date())!
        var comps = cal.dateComponents([.year, .month], from: prevMonth)
        comps.day = day
        let targetDate = cal.date(from: comps)!

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "it_IT")
        fmt.setLocalizedDateFormatFromTemplate("dMMMM")
        let dayMonthLabel = fmt.string(from: targetDate)

        let dayBtn = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label CONTAINS[c] %@", "\(day)", dayMonthLabel)
        ).firstMatch
        XCTAssertTrue(dayBtn.waitForExistence(timeout: 5))
        dayBtn.tap()

        let dismissRegion = app.otherElements["PopoverDismissRegion"]
        if dismissRegion.exists {
            dismissRegion.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        } else if dayBtn.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15)).tap()
        }
    }

    @MainActor
    func testOverdueEditKeepsDoneToggleVisibleWhenPlannedOnOpenAndToggled() throws {
        let actualText = app.staticTexts["home_actualBalance"]
        XCTAssertTrue(actualText.waitForExistence(timeout: 5))
        let initialActual = actualText.label

        let overdueName = uniqueName("PianifPassatoS73i")
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "25")
        enterTransactionField("tf_name", text: overdueName)

        let fixedSwitch = app.switches["toggle_isFixed"]
        for _ in 0..<4 {
            if fixedSwitch.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(fixedSwitch.waitForExistence(timeout: 5))
        if (fixedSwitch.value as? String) != "1" { fixedSwitch.tap() }

        let doneSwitch = app.switches["toggle_isDone"]
        XCTAssertTrue(doneSwitch.waitForExistence(timeout: 5))
        if (doneSwitch.value as? String) == "1" { doneSwitch.tap() }

        pickPreviousMonthDay(15)
        saveTransactionForm()

        // Apri il movimento dalla card «Da confermare» in Home
        let confirmHome = app.buttons["btn_confirmOverdue_\(overdueName)"]
        for _ in 0..<4 {
            if confirmHome.exists && confirmHome.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(confirmHome.waitForExistence(timeout: 5))

        let overdueRowText = transactionRow(named: overdueName)
        XCTAssertTrue(overdueRowText.waitForExistence(timeout: 5))
        overdueRowText.tap()

        // Al caricamento isDone resta false e l'interruttore è visibile
        let editFixed = app.switches["toggle_isFixed"]
        for _ in 0..<4 {
            if editFixed.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(editFixed.waitForExistence(timeout: 5))
        let editDone = app.switches["toggle_isDone"]
        XCTAssertTrue(editDone.waitForExistence(timeout: 5))
        XCTAssertEqual(editDone.value as? String, "0")

        // Togliendo Spesa fissa (ora non fisso + data passata), grazie a wasPlannedOnOpen
        // l'interruttore Già effettuato deve restare visibile e, toccandolo, restare visibile.
        editFixed.tap()
        XCTAssertTrue(editDone.waitForExistence(timeout: 3), "Già effettuato deve restare visibile anche per non fisso se era pianificato all'apertura")
        if (editDone.value as? String) != "1" { editDone.tap() }
        XCTAssertTrue(editDone.exists, "L'interruttore non deve sparire al tocco")
        XCTAssertEqual(editDone.value as? String, "1")
        saveTransactionForm()

        XCTAssertFalse(app.buttons["btn_confirmOverdue_\(overdueName)"].exists)
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialActual), object: actualText)], timeout: 5) == .completed)
    }
}
