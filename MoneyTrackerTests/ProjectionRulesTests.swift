import Testing
import Foundation
@testable import MoneyTracker

@MainActor
@Suite("ProjectionRules · helper neutro")
struct ProjectionRulesTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, month: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    @Test("Movimento singolo pianificato conta solo nel proprio mese")
    func singlePlannedCountsOnlyInItsMonth() {
        let nov28 = date(28, month: 11)
        let sameMonth = Transaction(name: "Cena", amount: 40, type: .uscita, date: date(30, month: 11), isDone: false, isFixed: false)
        let otherMonth = Transaction(name: "Regalo", amount: 90, type: .uscita, date: date(15, month: 12), isDone: false, isFixed: false)
        let pastMonth = Transaction(name: "Vecchia", amount: 50, type: .uscita, date: date(10, month: 10), isDone: false, isFixed: true)

        #expect(ProjectionRules.countsInProjection(sameMonth, projectionDay: nov28, calendar: calendar))
        #expect(!ProjectionRules.countsInProjection(otherMonth, projectionDay: nov28, calendar: calendar))
        #expect(!ProjectionRules.countsInProjection(pastMonth, projectionDay: nov28, calendar: calendar))
    }

    @Test("Fatti, trasferimenti e ricorrenze contano sempre")
    func doneTransfersAndRecurringAlwaysCount() {
        let nov28 = date(28, month: 11)
        let dec10 = date(10, month: 12)

        #expect(ProjectionRules.countsInProjection(Transaction(name: "Fatto", amount: 20, type: .uscita, date: dec10, isDone: true), projectionDay: nov28, calendar: calendar))
        #expect(ProjectionRules.countsInProjection(Transaction(name: "Giro", amount: 100, type: .uscita, date: dec10, isDone: false, isTransfer: true), projectionDay: nov28, calendar: calendar))
        #expect(ProjectionRules.countsInProjection(Transaction(name: "Abbonamento", amount: 15, type: .uscita, date: dec10, isDone: false, templateId: UUID().uuidString), projectionDay: nov28, calendar: calendar))
    }
}
