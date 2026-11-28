import Testing
import Foundation
@testable import MoneyTracker

/// S-41: la spesa fissa singola pianificata pesa sulla previsione Home solo nel mese della sua data.
@MainActor
@Suite("Previsione Home · competenza mensile")
struct ProjectionMonthTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ day: Int, month: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    private func counts(_ t: Transaction, today: Date) -> Bool {
        DashboardView.countsInProjection(t, projectionDay: today, calendar: calendar)
    }

    @Test("Spesa fissa singola di dicembre: fuori a novembre, dentro dal 1° dicembre")
    func monthPassage() {
        let tax = Transaction(name: "Tasse", amount: 900, type: .uscita, date: date(10, month: 12), isDone: false, isFixed: true)
        #expect(!counts(tax, today: date(24, month: 11)))
        #expect(!counts(tax, today: date(30, month: 11)))
        #expect(counts(tax, today: date(1, month: 12)))
        #expect(counts(tax, today: date(31, month: 12)))
    }

    @Test("Una spesa fissa singola di un mese passato non pesa sul mese corrente")
    func pastMonth() {
        let old = Transaction(name: "Tasse", amount: 900, type: .uscita, date: date(10, month: 10), isDone: false, isFixed: true)
        #expect(!counts(old, today: date(24, month: 11)))
    }

    @Test("Già effettuata, trasferimento e serie ricorrente contano sempre")
    func everythingElseAlwaysCounts() {
        let today = date(24, month: 11)
        let future = date(10, month: 12)
        #expect(counts(Transaction(name: "Pagata", amount: 50, type: .uscita, date: future, isDone: true, isFixed: true), today: today))
        #expect(counts(Transaction(name: "Giro", amount: 100, type: .uscita, date: future, isDone: false, isFixed: true, isTransfer: true), today: today))
        #expect(counts(Transaction(name: "Affitto", amount: 700, type: .uscita, date: future, isDone: false, isFixed: true, templateId: UUID().uuidString), today: today))
        #expect(counts(Transaction(name: "Palestra", amount: 40, type: .uscita, date: future, isDone: false, isFixed: true, recurringFrequency: "mensile"), today: today))
    }

    @Test("Movimento singolo pianificato (fisso o no, uscita o entrata) conta solo nel suo mese (S-73c)")
    func singlePlannedCountsOnlyInItsMonth() {
        let nov24 = date(24, month: 11)
        let dec10 = date(10, month: 12)
        let nov29 = date(29, month: 11)

        let plannedExpenseNextMonth = Transaction(name: "Cena", amount: 60, type: .uscita, date: dec10, isDone: false, isFixed: false)
        let plannedIncomeNextMonth = Transaction(name: "Stipendio", amount: 1500, type: .entrata, date: dec10, isDone: false, isFixed: true)
        let plannedExpenseThisMonth = Transaction(name: "Cena oggi", amount: 35, type: .uscita, date: nov29, isDone: false, isFixed: false)
        let plannedIncomeThisMonth = Transaction(name: "Rimborso", amount: 80, type: .entrata, date: nov29, isDone: false, isFixed: false)

        #expect(!counts(plannedExpenseNextMonth, today: nov24))
        #expect(!counts(plannedIncomeNextMonth, today: nov24))
        #expect(counts(plannedExpenseNextMonth, today: dec10))
        #expect(counts(plannedIncomeNextMonth, today: dec10))
        #expect(counts(plannedExpenseThisMonth, today: nov24))
        #expect(counts(plannedIncomeThisMonth, today: nov24))
    }

    @Test("Data futura rende pianificato in automatico solo se non fisso; passato o oggi resta fatto (S-73c)")
    func futureDateAutoPlannedRule() {
        let nov28 = date(28, month: 11)
        let nov29 = date(29, month: 11)
        let nov27 = date(27, month: 11)

        #expect(AddTransactionView.isFutureDate(nov29, relativeTo: nov28, calendar: calendar))
        #expect(!AddTransactionView.isFutureDate(nov28, relativeTo: nov28, calendar: calendar))
        #expect(!AddTransactionView.isFutureDate(nov27, relativeTo: nov28, calendar: calendar))

        #expect(!AddTransactionView.defaultDone(isFixed: false, date: nov29, relativeTo: nov28, calendar: calendar))
        #expect(AddTransactionView.defaultDone(isFixed: false, date: nov28, relativeTo: nov28, calendar: calendar))
        #expect(AddTransactionView.defaultDone(isFixed: false, date: nov27, relativeTo: nov28, calendar: calendar))
        #expect(!AddTransactionView.defaultDone(isFixed: true, date: nov27, relativeTo: nov28, calendar: calendar))
    }
}
