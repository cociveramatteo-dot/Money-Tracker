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

    @Test("Già effettuata, entrata, trasferimento, serie ricorrente e spesa non fissa contano sempre")
    func everythingElseAlwaysCounts() {
        let today = date(24, month: 11)
        let future = date(10, month: 12)
        #expect(counts(Transaction(name: "Pagata", amount: 50, type: .uscita, date: future, isDone: true, isFixed: true), today: today))
        #expect(counts(Transaction(name: "Stipendio", amount: 1500, type: .entrata, date: future, isDone: false, isFixed: true), today: today))
        #expect(counts(Transaction(name: "Giro", amount: 100, type: .uscita, date: future, isDone: false, isFixed: true, isTransfer: true), today: today))
        #expect(counts(Transaction(name: "Affitto", amount: 700, type: .uscita, date: future, isDone: false, isFixed: true, templateId: UUID().uuidString), today: today))
        #expect(counts(Transaction(name: "Palestra", amount: 40, type: .uscita, date: future, isDone: false, isFixed: true, recurringFrequency: "mensile"), today: today))
        #expect(counts(Transaction(name: "Cena", amount: 60, type: .uscita, date: future, isDone: false, isFixed: false), today: today))
    }
}
