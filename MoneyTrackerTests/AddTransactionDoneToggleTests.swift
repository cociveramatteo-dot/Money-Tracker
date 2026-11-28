import Testing
import Foundation
@testable import MoneyTracker

@MainActor
@Suite("S-73i · Visibilità interruttore Già effettuato")
struct AddTransactionDoneToggleTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, month: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    @Test("Movimento non fisso pianificato di un mese passato mostra Già effettuato se era pianificato all'apertura")
    func overdueNonFixedPlannedShowsDoneToggle() {
        let today = date(28, month: 11)
        let pastDate = date(15, month: 10)

        // Nuovo movimento non fisso del passato (wasPlannedOnOpen == false): nascosto
        #expect(!AddTransactionView.shouldShowDoneToggle(
            isFixed: false,
            date: pastDate,
            wasPlannedOnOpen: false,
            relativeTo: today,
            calendar: calendar
        ))

        // Movimento non fisso scaduto aperto da "Da confermare" (isDone == false -> wasPlannedOnOpen == true): visibile
        #expect(AddTransactionView.shouldShowDoneToggle(
            isFixed: false,
            date: pastDate,
            wasPlannedOnOpen: true,
            relativeTo: today,
            calendar: calendar
        ))
    }

    @Test("Movimento di oggi o passato già effettuato (isDone == true) non mostra l'interruttore se non fisso")
    func donePastNonFixedDoesNotShowToggle() {
        let today = date(28, month: 11)
        let pastDate = date(15, month: 10)

        #expect(!AddTransactionView.shouldShowDoneToggle(
            isFixed: false,
            date: today,
            wasPlannedOnOpen: false,
            relativeTo: today,
            calendar: calendar
        ))
        #expect(!AddTransactionView.shouldShowDoneToggle(
            isFixed: false,
            date: pastDate,
            wasPlannedOnOpen: false,
            relativeTo: today,
            calendar: calendar
        ))
    }

    @Test("Voce fissa o data futura mostrano sempre l'interruttore anche se wasPlannedOnOpen è falso")
    func fixedOrFutureAlwaysShowToggle() {
        let today = date(28, month: 11)
        let pastDate = date(15, month: 10)
        let futureDate = date(10, month: 12)

        #expect(AddTransactionView.shouldShowDoneToggle(
            isFixed: true,
            date: pastDate,
            wasPlannedOnOpen: false,
            relativeTo: today,
            calendar: calendar
        ))
        #expect(AddTransactionView.shouldShowDoneToggle(
            isFixed: false,
            date: futureDate,
            wasPlannedOnOpen: false,
            relativeTo: today,
            calendar: calendar
        ))
    }
}
