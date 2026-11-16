import Testing
import Foundation
@testable import MoneyTracker

@Suite("Balance trail")
struct BalanceTrailTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }
    private func date(_ day: Int, month: Int = 11) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    private func entry(_ day: Int, _ amount: Decimal, done: Bool, month: Int = 11) -> BalanceTrail.Entry {
        .init(date: date(day, month: month), signedAmount: amount, isDone: done)
    }

    @Test("Ultimo punto reale = saldo attuale; senza pianificati niente proiezione")
    func noPlanned() {
        let t = BalanceTrail.make(
            currentBalance: 100,
            entries: [entry(2, -20, done: true), entry(10, 50, done: true)],
            now: date(13), calendar: calendar)
        #expect(t.today == 13)
        #expect(t.daysInMonth == 30)
        #expect(t.actual.count == 13)
        #expect(t.actual.last == .init(day: 13, balance: 100))
        // prima del 10: 100 − 50 = 50; prima del 2: 50 + 20 = 70
        #expect(t.actual.first(where: { $0.day == 9 })?.balance == 50)
        #expect(t.actual.first?.balance == 70)
        #expect(t.projected.isEmpty)
        #expect(t.plannedMarks.isEmpty)
        #expect(!t.hasPlanned)
        #expect(t.expectedBalance == 100)
    }

    @Test("Ultimo punto proiettato = saldo atteso (attuale + pianificati)")
    func projectionMatchesExpected() {
        let t = BalanceTrail.make(
            currentBalance: 1000,
            entries: [entry(5, -100, done: true),
                      entry(20, -300, done: false), entry(25, 50, done: false)],
            now: date(13), calendar: calendar)
        #expect(t.hasPlanned)
        #expect(t.plannedCount == 2)
        #expect(t.plannedDelta == -250)
        #expect(t.expectedBalance == 750)
        #expect(t.projected.first == .init(day: 13, balance: 1000))
        #expect(t.projected.last == .init(day: 30, balance: 750))
        #expect(t.plannedMarks == [.init(day: 20, balance: 700), .init(day: 25, balance: 750)])
    }

    @Test("Pianificati scaduti e oltre fine mese restano nel saldo atteso")
    func anchoredPlanned() {
        let t = BalanceTrail.make(
            currentBalance: 500,
            entries: [entry(3, -40, done: false),            // scaduto → oggi
                      entry(2, -60, done: false, month: 12)], // mese dopo → ultimo giorno
            now: date(13), calendar: calendar)
        #expect(t.expectedBalance == 400)
        #expect(t.projected.last?.balance == 400)
        #expect(t.plannedMarks == [.init(day: 13, balance: 460), .init(day: 30, balance: 400)])
    }

    @Test("Fatti con data futura o precedente al mese non rompono la serie")
    func doneOutOfRange() {
        let t = BalanceTrail.make(
            currentBalance: 200,
            entries: [entry(28, -10, done: true),              // fatto con data futura → oggi
                      entry(20, 30, done: true, month: 10)],   // mese scorso → giorno 1
            now: date(13), calendar: calendar)
        #expect(t.actual.last?.balance == 200)
        #expect(t.actual.first(where: { $0.day == 12 })?.balance == 210)
        #expect(t.actual.first?.day == 1)
        #expect(t.actual.first?.balance == 210)
    }

    @Test("Nessun movimento: serie piatta; primo giorno del mese")
    func emptyAndFirstDay() {
        let t = BalanceTrail.make(currentBalance: 0, entries: [], now: date(1), calendar: calendar)
        #expect(t.actual == [.init(day: 1, balance: 0)])
        #expect(t.projected.isEmpty)
    }

    @Test("Decimal esatto, nessun arrotondamento")
    func exactDecimal() {
        let t = BalanceTrail.make(
            currentBalance: Decimal(string: "10.10")!,
            entries: [entry(20, Decimal(string: "-0.20")!, done: false)],
            now: date(13), calendar: calendar)
        #expect(t.expectedBalance == Decimal(string: "9.90")!)
    }
}
