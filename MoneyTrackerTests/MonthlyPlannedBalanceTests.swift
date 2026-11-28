import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
@Suite("Monthly planned balance (S-73a)")
struct MonthlyPlannedBalanceTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, month: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        return try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
    }

    @Test("Conto 1000 con fissa singola -200 del 12/12: 1000 al 28/11, 800 dal 1/12")
    func singleFixedExpenseCountsOnlyInItsMonth() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let account = Account(name: "Conto", type: .conto, initialBalance: 1000)
        ctx.insert(account)
        let decemberFixed = Transaction(
            name: "Assicurazione",
            amount: 200,
            type: .uscita,
            date: date(12, month: 12),
            isDone: false,
            isFixed: true,
            account: account
        )
        ctx.insert(decemberFixed)
        try ctx.save()

        #expect(MonthlyPlannedBalance.expected(for: account, day: date(28, month: 11), calendar: calendar) == 1000)
        #expect(MonthlyPlannedBalance.expected(for: account, day: date(1, month: 12), calendar: calendar) == 800)
    }

    @Test("Spesa non fissa pianificata e ricorrente del mese contano; fatta non conta due volte")
    func nonFixedRecurringAndDoneMovements() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let account = Account(name: "Carta", type: .carta, initialBalance: 1000)
        ctx.insert(account)

        let nov28 = date(28, month: 11)
        let doneExpense = Transaction(
            name: "Spesa fatta",
            amount: 100,
            type: .uscita,
            date: date(10, month: 11),
            isDone: true,
            isFixed: false,
            account: account
        )
        let plannedNonFixed = Transaction(
            name: "Cena pianificata",
            amount: 50,
            type: .uscita,
            date: date(29, month: 11),
            isDone: false,
            isFixed: false,
            account: account
        )
        let plannedRecurring = Transaction(
            name: "Palestra",
            amount: 40,
            type: .uscita,
            date: date(30, month: 11),
            isDone: false,
            isFixed: true,
            recurringFrequency: "mensile",
            templateId: UUID().uuidString,
            account: account
        )
        ctx.insert(doneExpense)
        ctx.insert(plannedNonFixed)
        ctx.insert(plannedRecurring)
        try ctx.save()

        // currentBalance = 1000 - 100 = 900; planned = -50 - 40 = -90 -> expected = 810.
        #expect(account.currentBalance == 900)
        #expect(MonthlyPlannedBalance.expected(for: account, day: nov28, calendar: calendar) == 810)
    }

    @Test("Conto senza pianificati: previsione uguale al saldo attuale")
    func accountWithoutPlannedMatchesCurrentBalance() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let account = Account(name: "Risparmi", type: .risparmio, initialBalance: 2500)
        ctx.insert(account)
        let done = Transaction(
            name: "Versamento",
            amount: 200,
            type: .entrata,
            date: date(5, month: 11),
            isDone: true,
            account: account
        )
        ctx.insert(done)
        try ctx.save()

        let expected = MonthlyPlannedBalance.expected(for: account, day: date(28, month: 11), calendar: calendar)
        #expect(expected == account.currentBalance)
        #expect(expected == 2700)
    }

    @Test("Dizionario expectedByAccountID somma correttamente il totale mensile")
    func expectedDictionaryMatchesPerAccountAndExcludesOtherMonthFixed() throws {
        let container = try makeContainer()
        let ctx = container.mainContext
        let a1 = Account(name: "Conto", type: .conto, initialBalance: 1000)
        let a2 = Account(name: "Carta", type: .carta, initialBalance: 500)
        ctx.insert(a1)
        ctx.insert(a2)
        ctx.insert(Transaction(name: "Fissa dic", amount: 200, type: .uscita, date: date(12, month: 12), isDone: false, isFixed: true, account: a1))
        ctx.insert(Transaction(name: "Fissa nov", amount: 100, type: .uscita, date: date(29, month: 11), isDone: false, isFixed: true, account: a2))
        try ctx.save()

        let map = MonthlyPlannedBalance.expectedByAccountID(for: [a1, a2], day: date(28, month: 11), calendar: calendar)
        #expect(map[a1.persistentModelID] == 1000)
        #expect(map[a2.persistentModelID] == 400)
    }
}
