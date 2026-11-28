import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
@Suite("Overdue planned movements (S-73f)")
struct OverduePlannedMovementsTests {
    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, month: Int, year: Int = 2026) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test("Segnala solo pianificati non trasferimenti di mesi passati")
    func detectsOnlyPastMonthUnconfirmedNonTransfers() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext

        let nov28 = date(28, month: 11)
        let pastPlanned = Transaction(name: "Bolletta ottobre", amount: 80, type: .uscita, date: date(20, month: 10), isDone: false, isFixed: false)
        let pastFixedPlanned = Transaction(name: "Assicurazione ott", amount: 120, type: .uscita, date: date(15, month: 10), isDone: false, isFixed: true)
        let pastDone = Transaction(name: "Pagata ott", amount: 40, type: .uscita, date: date(12, month: 10), isDone: true, isFixed: true)
        let pastTransfer = Transaction(name: "Giro ott", amount: 50, type: .uscita, date: date(10, month: 10), isDone: false, isTransfer: true)
        let thisMonthPlanned = Transaction(name: "Cena nov", amount: 30, type: .uscita, date: date(29, month: 11), isDone: false, isFixed: false)
        let thisMonthPastDayPlanned = Transaction(name: "Spesa 10 nov", amount: 25, type: .uscita, date: date(10, month: 11), isDone: false, isFixed: false)
        let nextMonthPlanned = Transaction(name: "Fissa dic", amount: 200, type: .uscita, date: date(12, month: 12), isDone: false, isFixed: true)

        for t in [pastPlanned, pastFixedPlanned, pastDone, pastTransfer, thisMonthPlanned, thisMonthPastDayPlanned, nextMonthPlanned] {
            ctx.insert(t)
        }
        try ctx.save()

        let overdue = OverduePlannedMovements.list(
            from: [pastPlanned, pastFixedPlanned, pastDone, pastTransfer, thisMonthPlanned, thisMonthPastDayPlanned, nextMonthPlanned],
            relativeTo: nov28,
            calendar: calendar
        )
        #expect(Set(overdue.map(\.name)) == ["Bolletta ottobre", "Assicurazione ott"])

        // Confermare uno dei due lo toglie subito dall'elenco "da confermare"
        pastPlanned.isDone = true
        let remaining = OverduePlannedMovements.list(
            from: [pastPlanned, pastFixedPlanned],
            relativeTo: nov28,
            calendar: calendar
        )
        #expect(remaining.map(\.name) == ["Assicurazione ott"])
    }

    @Test("Esclude i movimenti dei conti archiviati e risolve l'icona di categoria")
    func excludesArchivedAccountsAndResolvesCategoryIcon() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext

        let active = Account(name: "Conto", type: .conto, initialBalance: 500)
        let archived = Account(name: "Vecchio", type: .conto, initialBalance: 100)
        archived.isArchived = true
        ctx.insert(active)
        ctx.insert(archived)

        let nov28 = date(28, month: 11)
        let onActive = Transaction(name: "Hotel Roma 2 notti", amount: 195, type: .uscita, category: "Viaggi", categoryIcon: "circle.dotted", date: date(15, month: 10), isDone: false, account: active)
        let onArchived = Transaction(name: "Vecchia bolletta", amount: 60, type: .uscita, category: "Casa", categoryIcon: "house.fill", date: date(12, month: 10), isDone: false, account: archived)
        let noAccount = Transaction(name: "Senza conto", amount: 25, type: .uscita, category: "", categoryIcon: "", date: date(10, month: 10), isDone: false, account: nil)

        ctx.insert(onActive)
        ctx.insert(onArchived)
        ctx.insert(noAccount)
        try ctx.save()

        let overdue = OverduePlannedMovements.list(from: [onActive, onArchived, noAccount], relativeTo: nov28, calendar: calendar)
        #expect(Set(overdue.map { $0.name }) == ["Hotel Roma 2 notti", "Senza conto"])

        // Con categoria nota ma categoryIcon di default "circle.dotted" -> usa icona della categoria ("airplane")
        #expect(OverduePlannedMovements.resolvedCategorySymbol(for: onActive) == "airplane")
        // Solo se manca la categoria usa il cerchio tratteggiato generico
        #expect(OverduePlannedMovements.resolvedCategorySymbol(for: noAccount) == "circle.dotted")
    }
}
