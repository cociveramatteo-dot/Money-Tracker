import Testing
import Foundation
import SwiftData
@testable import MoneyTracker

@MainActor
@Suite("Cache previsioni e Da confermare")
struct ProjectionAndOverdueCacheTests {

    private var calendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(_ day: Int, month: Int) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        return try ModelContainer(for: schema, configurations: config)
    }

    @Test("MonthlyPlannedBalance.Cache restituisce valori identici e si invalida su modifiche ai movimenti o al giorno")
    func expectedBalanceCacheMatchesAndInvalidates() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let account = Account(name: "Conto", type: .conto, initialBalance: 1000)
        context.insert(account)

        let nov28 = date(28, month: 11)
        let dec10 = date(10, month: 12)
        let novPlanned = Transaction(name: "Spesa nov", amount: 120, type: .uscita, date: nov28, isDone: false, account: account)
        let decPlanned = Transaction(name: "Tassa dic", amount: 300, type: .uscita, date: dec10, isDone: false, account: account)
        context.insert(novPlanned)
        context.insert(decPlanned)
        #expect(context.safeSave())

        let cache = MonthlyPlannedBalance.Cache()
        let first = cache.expectedByAccountID(for: [account], day: nov28, calendar: calendar)
        #expect(first[account.persistentModelID] == 880)

        // Hit in cache: identico senza variazioni
        let hit = cache.expectedByAccountID(for: [account], day: nov28, calendar: calendar)
        #expect(hit == first)

        // Conferma movimento -> deve invalidare e aggiornare
        novPlanned.isDone = true
        #expect(context.safeSave())
        let afterConfirm = cache.expectedByAccountID(for: [account], day: nov28, calendar: calendar)
        #expect(afterConfirm[account.persistentModelID] == 880)

        // Cambio importo di movimento pianificato -> invalida
        decPlanned.amount = 400
        #expect(context.safeSave())
        let decView = cache.expectedByAccountID(for: [account], day: dec10, calendar: calendar)
        #expect(decView[account.persistentModelID] == 480)
    }

    @Test("OverduePlannedMovements.ListCache e FilteredCache si invalidano su conferma, archiviazione conto e filtri")
    func overdueCachesInvalidateOnMutationsAndFilters() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let account = Account(name: "Principale", type: .conto, initialBalance: 500)
        context.insert(account)

        let nov28 = date(28, month: 11)
        let oct15 = date(15, month: 10)
        let tx = Transaction(name: "Hotel", amount: 90, type: .uscita, category: "Viaggi", date: oct15, isDone: false, isFixed: false, account: account)
        context.insert(tx)
        try context.save()

        let listCache = OverduePlannedMovements.ListCache()
        #expect(listCache.list(from: [tx], relativeTo: nov28, calendar: calendar).map(\.id) == [tx.id])

        let filteredCache = OverduePlannedMovements.FilteredCache()
        let allMatched = filteredCache.list(
            from: [tx], relativeTo: nov28, selectedMonth: nov28, searchQuery: "", useCustomDates: false,
            filter: .tutti, selectedCategory: "", minAmountText: "", maxAmountText: "", rules: [], calendar: calendar
        )
        #expect(allMatched.map(\.id) == [tx.id])

        let fixedOnly = filteredCache.list(
            from: [tx], relativeTo: nov28, selectedMonth: nov28, searchQuery: "", useCustomDates: false,
            filter: .fisse, selectedCategory: "", minAmountText: "", maxAmountText: "", rules: [], calendar: calendar
        )
        #expect(fixedOnly.isEmpty)

        // Conferma movimento -> deve sparire anche dalla ListCache
        tx.isDone = true
        #expect(listCache.list(from: [tx], relativeTo: nov28, calendar: calendar).isEmpty)

        // Ripristinato ma conto archiviato -> resta escluso
        tx.isDone = false
        account.isArchived = true
        #expect(listCache.list(from: [tx], relativeTo: nov28, calendar: calendar).isEmpty)
    }
}
