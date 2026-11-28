import XCTest

/// S-73f/S-73g: movimento pianificato di un mese passato non confermato compare in «Da confermare»
/// su Home e Movimenti; pulsante compatto solo icona con accessibilityLabel localizzato, icona categoria,
/// riga secondaria su 1 riga con data sempre visibile; conferma rapida aggiorna il saldo attuale.
final class OverduePlannedUITests: MoneyTrackerUITestCase {
    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
    }

    private func launch(language: String = "it", locale: String = "it", size: String = "UICTContentSizeCategoryL") {
        app.launchArguments = [
            "--uitesting",
            "-AppleLanguages", "(\(language))",
            "-AppleLocale", locale,
            "-UIPreferredContentSizeCategoryName", size,
        ]
        app.launch()
    }

    @MainActor
    private func pickPreviousMonthDay(_ day: Int = 15, localeIdentifier: String = "it_IT") {
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
            "Mostra il mese precedente", "Mese precedente", "Precedente", "Indietro",
            "Vorheriger Monat", "Vorherigen Monat anzeigen",
            "Previous Month",
        ]
        let prevBtn = app.buttons.matching(
            NSPredicate(format: "identifier IN %@ OR label IN %@", prevCandidates, prevCandidates)
        ).firstMatch
        XCTAssertTrue(prevBtn.waitForExistence(timeout: 3), "Bottone mese precedente non trovato nel DatePicker")
        prevBtn.tap()

        let cal = Calendar(identifier: .gregorian)
        let prevMonth = cal.date(byAdding: .month, value: -1, to: Date())!
        var comps = cal.dateComponents([.year, .month], from: prevMonth)
        comps.day = day
        let targetDate = cal.date(from: comps)!

        let fmt = DateFormatter()
        fmt.locale = Locale(identifier: localeIdentifier)
        fmt.setLocalizedDateFormatFromTemplate("dMMMM")
        let dayMonthLabel = fmt.string(from: targetDate)

        let dayBtn = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label CONTAINS[c] %@", "\(day)", dayMonthLabel)
        ).firstMatch
        XCTAssertTrue(dayBtn.waitForExistence(timeout: 5), "Giorno \(dayMonthLabel) non trovato")
        dayBtn.tap()

        let dismissRegion = app.otherElements["PopoverDismissRegion"]
        if dismissRegion.exists {
            dismissRegion.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.08)).tap()
        } else if dayBtn.exists {
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.1, dy: 0.15)).tap()
        }
    }

    @MainActor
    private func createOverdueFixedExpense(name: String, amount: String = "45", categoryKey: String = "Viaggi", localeIdentifier: String = "it_IT") {
        tapFAB(menuItem: "fabMenu_addTransaction")
        enterTransactionField("tf_amount", text: amount)
        enterTransactionField("tf_name", text: name)

        let catBtn = app.buttons["btn_categoryPicker"]
        XCTAssertTrue(catBtn.waitForExistence(timeout: 5))
        catBtn.tap()
        let catRow = app.buttons["categoryRow_\(categoryKey)"]
        XCTAssertTrue(catRow.waitForExistence(timeout: 5), "Categoria \(categoryKey) non trovata")
        catRow.tap()

        let fixedSwitch = app.switches["toggle_isFixed"]
        for _ in 0..<4 {
            if fixedSwitch.isHittable { break }
            app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.35))
                .press(forDuration: 0.05, thenDragTo: app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.15)))
        }
        XCTAssertTrue(fixedSwitch.waitForExistence(timeout: 5))
        if (fixedSwitch.value as? String) != "1" {
            fixedSwitch.tap()
        }
        let doneSwitch = app.switches["toggle_isDone"]
        if !doneSwitch.waitForExistence(timeout: 2), (fixedSwitch.value as? String) != "1" {
            fixedSwitch.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.5)).tap()
        }
        XCTAssertTrue(doneSwitch.waitForExistence(timeout: 5), "Toggle Già effettuato non apparso dopo Spesa fissa")
        if (doneSwitch.value as? String) == "1" {
            doneSwitch.tap()
        }

        pickPreviousMonthDay(15, localeIdentifier: localeIdentifier)

        let save = app.buttons["btn_saveTransaction"]
        for _ in 0..<5 {
            if save.isHittable { break }
            app.swipeUp()
        }
        saveTransactionForm()
    }

    @MainActor
    private func saveShot(_ name: String) {
        let att = XCTAttachment(screenshot: app.screenshot())
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    @MainActor
    func testOverduePlannedWarningAndQuickConfirm() throws {
        launch(language: "it", locale: "it", size: "UICTContentSizeCategoryL")

        let actualText = app.staticTexts["home_actualBalance"]
        XCTAssertTrue(actualText.waitForExistence(timeout: 5))
        let initialActual = actualText.label

        let overdueName = "Hotel Roma 2 notti"
        createOverdueFixedExpense(name: overdueName, amount: "45", categoryKey: "Viaggi", localeIdentifier: "it_IT")

        // 1) In Home compare la sezione «Da confermare» e il saldo attuale resta invariato
        XCTAssertEqual(actualText.label, initialActual)
        let homeSection = app.otherElements["home_overdueSection"]
        for _ in 0..<4 {
            if homeSection.exists && homeSection.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(homeSection.waitForExistence(timeout: 5), "Sezione Da confermare non visibile in Home")
        let confirmHome = app.buttons["btn_confirmOverdue_\(overdueName)"]
        for _ in 0..<3 {
            if confirmHome.exists && confirmHome.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(confirmHome.waitForExistence(timeout: 5), "Pulsante Conferma non trovato in Home")
        XCTAssertEqual(confirmHome.label, "Conferma")
        XCTAssertGreaterThanOrEqual(confirmHome.frame.width, 44)
        XCTAssertGreaterThanOrEqual(confirmHome.frame.height, 44)
        app.swipeUp()
        saveShot("ios-home-overdue")

        // 2) In Movimenti compare in cima la sezione «Da confermare» con bordo ambra
        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        clearTransactionFilters()
        let confirmMov = app.buttons["btn_confirmOverdue_\(overdueName)"]
        XCTAssertTrue(confirmMov.waitForExistence(timeout: 5), "Segnalazione Da confermare non visibile in Movimenti")
        XCTAssertEqual(confirmMov.label, "Conferma")
        saveShot("ios-movimenti-overdue")

        // 3) Conferma rapida: l'avviso sparisce e il saldo attuale in Home scala
        confirmMov.tap()
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "exists == false"), object: confirmMov)], timeout: 5) == .completed,
            "L'avviso Da confermare deve sparire dopo la conferma")

        goToTab("Home")
        XCTAssertFalse(app.buttons["btn_confirmOverdue_\(overdueName)"].exists, "L'avviso in Home deve sparire dopo la conferma")
        XCTAssertTrue(XCTWaiter.wait(for: [XCTNSPredicateExpectation(
            predicate: NSPredicate(format: "label != %@", initialActual), object: actualText)], timeout: 5) == .completed,
            "Dopo la conferma il saldo attuale deve scalare")
    }

    @MainActor
    func testOverduePlannedGermanXL() throws {
        launch(language: "de", locale: "de_DE", size: "UICTContentSizeCategoryXL")

        let actualText = app.staticTexts["home_actualBalance"]
        XCTAssertTrue(actualText.waitForExistence(timeout: 5))

        let overdueName = "Hotel Roma 2 notti"
        createOverdueFixedExpense(name: overdueName, amount: "195", categoryKey: "Viaggi", localeIdentifier: "de_DE")

        let homeSection = app.otherElements["home_overdueSection"]
        for _ in 0..<4 {
            if homeSection.exists && homeSection.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(homeSection.waitForExistence(timeout: 5), "Sezione Zu bestätigen non visibile in Home")
        let confirmHome = app.buttons["btn_confirmOverdue_\(overdueName)"]
        for _ in 0..<3 {
            if confirmHome.exists && confirmHome.isHittable { break }
            app.swipeUp()
        }
        XCTAssertTrue(confirmHome.waitForExistence(timeout: 5))
        XCTAssertEqual(confirmHome.label, "Bestätigen")
        app.swipeUp()
        saveShot("ios-home-overdue-de-xl")

        goToTab("Movimenti")
        openTransactionsSection("Tutti")
        let confirmMov = app.buttons["btn_confirmOverdue_\(overdueName)"]
        XCTAssertTrue(confirmMov.waitForExistence(timeout: 5))
        XCTAssertEqual(confirmMov.label, "Bestätigen")
        saveShot("ios-movimenti-overdue-de-xl")
    }
}
