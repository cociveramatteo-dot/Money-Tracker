import XCTest

/// S-73c: data futura => movimento non fisso nasce pianificato, non scala il saldo attuale,
/// non entra nella previsione di un altro mese, e può essere confermato via swipe.
final class FutureTransactionPlannedUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "-AppleLanguages", "(it)", "-AppleLocale", "it"]
        app.launch()
    }

    @MainActor
    private func pickDate(daysFromToday offset: Int? = nil, nextMonthDay: Int? = nil) {
        let picker = app.datePickers["picker_date"]
        for _ in 0..<4 {
            if picker.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "DatePicker non trovato")
        picker.tap()

        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let targetDate: Date
        if let nextMonthDay {
            let nextMonth = cal.date(byAdding: .month, value: 1, to: now)!
            var comps = cal.dateComponents([.year, .month], from: nextMonth)
            comps.day = nextMonthDay
            targetDate = cal.date(from: comps)!
        } else {
            targetDate = cal.date(byAdding: .day, value: offset ?? 0, to: now)!
        }

        let currentMonth = cal.component(.month, from: now)
        let targetMonth = cal.component(.month, from: targetDate)
        if targetMonth != currentMonth {
            let isForward = targetDate > now
            let candidates = isForward
                ? ["DatePicker.NextMonth", "Mostra il mese successivo", "Mostra mese successivo", "Mese successivo", "Successivo", "Mese prossimo", "Avanti", "Next Month", "Forward"]
                : ["DatePicker.PreviousMonth", "Mostra il mese precedente", "Mostra mese precedente", "Mese precedente", "Precedente", "Indietro", "Previous Month", "Back"]
            let navButton = app.buttons.matching(
                NSPredicate(format: "identifier IN %@ OR label IN %@", candidates, candidates)
            ).firstMatch
            if navButton.waitForExistence(timeout: 3) {
                navButton.tap()
            } else {
                let grid = app.collectionViews.firstMatch
                if grid.waitForExistence(timeout: 2) {
                    if isForward { grid.swipeLeft() } else { grid.swipeRight() }
                }
            }
        }

        let dayNum = cal.component(.day, from: targetDate)
        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: "it_IT")
        fmt.dateFormat = "d MMMM"
        let dayMonthLabel = fmt.string(from: targetDate)

        let dayButton = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label CONTAINS[c] %@", "\(dayNum)", dayMonthLabel)
        ).firstMatch
        XCTAssertTrue(dayButton.waitForExistence(timeout: 5), "Giorno \(dayMonthLabel) non trovato nel DatePicker")
        dayButton.tap()

        // Chiude il popover calendario se resta aperto
        let dismissRegion = app.otherElements["PopoverDismissRegion"]
        if dismissRegion.exists {
            dismissRegion.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        } else if dayButton.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15)).tap()
        }
    }

    @MainActor
    private func scrollAndSave() {
        let save = app.buttons["btn_saveTransaction"]
        for _ in 0..<5 {
            if save.isHittable { break }
            app.swipeUp()
        }
        saveTransactionForm()
    }

    @MainActor
    func testFutureNonFixedExpenseBehaviorAndYesterdayDone() throws {
        let actualText = app.staticTexts["home_actualBalance"]
        XCTAssertTrue(actualText.waitForExistence(timeout: 5))
        let initialActual = actualText.label

        // 1) Spesa non fissa per domani -> nasce pianificata, saldo attuale invariato
        let tomorrowName = uniqueName("DomaniS73c")
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "10")
        enterTransactionField("tf_name", text: tomorrowName)
        pickDate(daysFromToday: 1)

        let doneSwitch = app.switches["toggle_isDone"]
        XCTAssertTrue(doneSwitch.waitForExistence(timeout: 3), "Toggle Già effettuato deve apparire per data futura")
        XCTAssertEqual(doneSwitch.value as? String, "0")
        scrollAndSave()

        XCTAssertEqual(actualText.label, initialActual, "La spesa futura non deve scalare subito il saldo attuale")

        // Verifica in Movimenti (nel mese di domani) e conferma via swipe
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        clearTransactionFilters()
        let cal = Calendar(identifier: .gregorian)
        let now = Date()
        let tomorrow = cal.date(byAdding: .day, value: 1, to: now)!
        if cal.component(.month, from: tomorrow) != cal.component(.month, from: now) {
            app.buttons["btn_monthPicker"].tap()
            app.buttons["Mese successivo"].tap()
        }
        let tomorrowRow = transactionRow(named: tomorrowName)
        XCTAssertTrue(tomorrowRow.waitForExistence(timeout: 5), "Spesa futura non trovata in Movimenti")
        XCTAssertEqual(tomorrowRow.value as? String, "Pianificato", "La spesa futura deve risultare pianificata")

        let confirmBtn = app.buttons["Conferma"]
        for _ in 0..<5 {
            tomorrowRow.swipeRight()
            if confirmBtn.waitForExistence(timeout: 1.5) { break }
        }
        XCTAssertTrue(confirmBtn.exists, "Swipe Conferma non apparso")
        confirmBtn.tap()
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "value == %@", "Fatto"), object: tomorrowRow)], timeout: 5) == .completed,
            "Dopo swipe Conferma la spesa deve diventare Fatto")

        goToTab("Home")
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialActual), object: actualText)], timeout: 5) == .completed,
            "Dopo Conferma il saldo attuale deve aggiornarsi")

        // 2) Spesa non fissa con data di ieri -> nasce fatta, scala subito il saldo attuale
        let afterConfirmActual = actualText.label
        let yesterdayName = uniqueName("IeriS73c")
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "15")
        enterTransactionField("tf_name", text: yesterdayName)
        pickDate(daysFromToday: -1)
        XCTAssertFalse(app.switches["toggle_isDone"].exists, "Per data passata non fissa Già effettuato resta nascosto")
        scrollAndSave()

        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", afterConfirmActual), object: actualText)], timeout: 5) == .completed,
            "La spesa di ieri deve scalare subito il saldo attuale")

        // 3) Spesa non fissa del mese prossimo -> non cambia il saldo atteso di questo mese
        let expectedText = app.staticTexts["home_expectedBalance"]
        XCTAssertTrue(expectedText.waitForExistence(timeout: 5))
        let expectedBeforeNextMonth = expectedText.label

        let nextMonthName = uniqueName("ProssimoMeseS73c")
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "25")
        enterTransactionField("tf_name", text: nextMonthName)
        pickDate(nextMonthDay: 15)
        scrollAndSave()

        XCTAssertEqual(expectedText.label, expectedBeforeNextMonth, "La spesa non fissa del mese prossimo non deve cambiare il saldo atteso di questo mese")
    }

    @MainActor
    func testEditingDoneFixedExpenseKeepsItDone() throws {
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        clearTransactionFilters()

        let name = uniqueName("FissaFattaS73e")
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: "33")
        enterTransactionField("tf_name", text: name)

        let fixedSwitch = app.switches["toggle_isFixed"]
        for _ in 0..<4 {
            if fixedSwitch.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(fixedSwitch.waitForExistence(timeout: 5))
        fixedSwitch.tap()

        let doneSwitch = app.switches["toggle_isDone"]
        XCTAssertTrue(doneSwitch.waitForExistence(timeout: 3))
        if (doneSwitch.value as? String) != "1" {
            doneSwitch.tap()
        }
        XCTAssertEqual(doneSwitch.value as? String, "1")
        scrollAndSave()

        let row = transactionRow(named: name)
        XCTAssertTrue(row.waitForExistence(timeout: 5), "Spesa fissa creata non trovata")
        XCTAssertEqual(row.value as? String, "Fatto")

        // Riapri in modifica e salva senza toccare nulla: deve restare "Fatto" (S-73e)
        row.tap()
        let editFixed = app.switches["toggle_isFixed"]
        XCTAssertTrue(editFixed.waitForExistence(timeout: 5))
        let editDone = app.switches["toggle_isDone"]
        XCTAssertTrue(editDone.waitForExistence(timeout: 3))
        XCTAssertEqual(editFixed.value as? String, "1")
        XCTAssertEqual(editDone.value as? String, "1", "Aprendo una fissa già effettuata il toggle deve restare acceso")
        scrollAndSave()

        let updatedRow = transactionRow(named: name)
        XCTAssertTrue(updatedRow.waitForExistence(timeout: 5))
        XCTAssertEqual(updatedRow.value as? String, "Fatto", "Dopo il salvataggio senza modifiche la fissa deve restare Fatto")
    }
}
