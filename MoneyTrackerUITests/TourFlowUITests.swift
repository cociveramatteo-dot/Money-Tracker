import XCTest

/// Percorre l'intero tour di onboarding (panoramica Livello 1) e cattura uno
/// screenshot ad ogni step, per verifica manuale che ogni spotlight punti
/// all'elemento corretto e che i testi siano coerenti.
///
/// Non eredita da MoneyTrackerUITestCase perché quella classe lancia con solo
/// "--uitesting" (che marca il tour come già visto). Qui serve anche
/// "--forceTour" (hook di QA in ContentView.swift) per farlo partire da capo.
final class TourFlowUITests: XCTestCase {

    var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["--uitesting", "--forceTour"]
        app.launch()
    }

    override func tearDownWithError() throws {
        app = nil
    }

    private func shot(_ name: String) {
        let attachment = XCTAttachment(screenshot: app.screenshot())
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }

    // Bottoni identificati per accessibilityIdentifier (vedi TourOverlayView.swift):
    // "tourModalCTA" per gli step modali (welcome/siri/done), "tourNext" per gli
    // step-elemento. Il testo "Avanti" da solo è ambiguo: MonthBar (chevron.right)
    // eredita da iOS lo stesso label automatico in italiano.
    private func tapModalCTA(timeout: TimeInterval = 6, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["tourModalCTA"]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "tourModalCTA non trovato", file: file, line: line)
        button.tap()
    }

    private func tapNext(timeout: TimeInterval = 6, file: StaticString = #filePath, line: UInt = #line) {
        let button = app.buttons["tourNext"]
        XCTAssertTrue(button.waitForExistence(timeout: timeout), "tourNext non trovato", file: file, line: line)
        button.tap()
    }

    func testFullTourWalkthrough() throws {
        // 1. Welcome (modale)
        XCTAssertTrue(app.staticTexts["Benvenuto in MoneyTracker"].waitForExistence(timeout: 10))
        shot("01_welcome")
        tapModalCTA()

        // 2. Home — Saldo attuale
        XCTAssertTrue(app.staticTexts["Saldo attuale"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("02_home_balance")
        tapNext()

        // 3. Home — Nascondi il saldo
        XCTAssertTrue(app.staticTexts["Nascondi il saldo"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("03_home_hide")
        tapNext()

        // 4. Home — Saldo atteso
        XCTAssertTrue(app.staticTexts["Saldo atteso"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("04_home_expected")
        tapNext()

        // 5. Home — I tuoi conti
        XCTAssertTrue(app.staticTexts["I tuoi conti"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("05_home_accounts")
        tapNext()

        // 6. Movimenti — Sezioni (cambio tab, attende transizione ~480ms)
        XCTAssertTrue(app.staticTexts["Sezioni"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.6)
        shot("06_movimenti_sections")
        tapNext()

        // 7. Movimenti — Tutti i movimenti (push automatico sezione "Tutti")
        XCTAssertTrue(app.staticTexts["Tutti i movimenti"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.6)
        shot("07_movimenti_block")
        tapNext()

        // 8. Movimenti — Cerca ovunque
        XCTAssertTrue(app.staticTexts["Cerca ovunque"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("08_movimenti_search")
        tapNext()

        // 9. Statistiche — Riepilogo del mese (cambio tab)
        XCTAssertTrue(app.staticTexts["Riepilogo del mese"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.6)
        shot("09_statistiche_summary")
        tapNext()

        // 10. Statistiche — Andamento nel tempo
        XCTAssertTrue(app.staticTexts["Andamento nel tempo"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("10_statistiche_trend")
        tapNext()

        // 11. Statistiche — Uscite per categoria
        XCTAssertTrue(app.staticTexts["Uscite per categoria"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("11_statistiche_category")
        tapNext()

        // 12. Pianifica — Budget per categoria (cambio tab, segmento 0)
        XCTAssertTrue(app.staticTexts["Budget per categoria"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.6)
        shot("12_pianifica_budget")
        tapNext()

        // 13. Pianifica — Storico budget
        XCTAssertTrue(app.staticTexts["Storico budget"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.5)
        shot("13_pianifica_history")
        tapNext()

        // 14. Pianifica — Obiettivi di risparmio (cambio segmento a Obiettivi)
        XCTAssertTrue(app.staticTexts["Obiettivi di risparmio"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.6)
        shot("14_pianifica_goals")
        tapNext()

        // 15. Conti — I tuoi conti (cambio tab; ultimo step-elemento, CTA = "Fine")
        XCTAssertTrue(app.staticTexts["I tuoi conti"].waitForExistence(timeout: 6))
        Thread.sleep(forTimeInterval: 0.6)
        shot("15_conti_list")
        tapNext()

        // 16. Siri & Shortcut (modale)
        XCTAssertTrue(app.staticTexts["Aggiungi spese senza aprire l'app"].waitForExistence(timeout: 6))
        shot("16_siri_shortcuts")
        tapModalCTA()

        // 17. Done (modale finale)
        XCTAssertTrue(app.staticTexts["Sei pronto"].waitForExistence(timeout: 6))
        shot("17_done")
        tapModalCTA()

        // 18. Tour concluso: overlay sparito, torna sulla Home utilizzabile.
        Thread.sleep(forTimeInterval: 0.5)
        XCTAssertFalse(app.staticTexts["Sei pronto"].exists)
        shot("18_after_tour")
    }
}
