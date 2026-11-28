import Testing
import Foundation
import SwiftData
@testable import MoneyTracker

/// S-73j: prove di invalidazione delle cache in cui il valore atteso cambia davvero.
@MainActor
@Suite("Invalidazione cache previsioni e Da confermare")
struct CacheInvalidationTests {

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

    @Test("Dopo la conferma di un movimento la previsione e l'elenco Da confermare cambiano valore")
    func confirmationChangesCachedValues() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let account = Account(name: "Conto", type: .conto, initialBalance: 1000)
        context.insert(account)

        let nov28 = date(28, month: 11)
        // Pianificato di novembre: pesa sulla previsione del 28/11.
        let novPlanned = Transaction(name: "Spesa nov", amount: 120, type: .uscita, date: nov28, isDone: false, account: account)
        // Pianificato di dicembre: NON pesa sulla previsione del 28/11 finché non è confermato.
        let decPlanned = Transaction(name: "Tassa dic", amount: 300, type: .uscita, date: date(10, month: 12), isDone: false, account: account)
        context.insert(novPlanned)
        context.insert(decPlanned)
        #expect(context.safeSave())

        let cache = MonthlyPlannedBalance.Cache()
        let before = cache.expectedByAccountID(for: [account], day: nov28, calendar: calendar)
        #expect(before[account.persistentModelID] == 880)

        // Confermato: entra nel saldo attuale, quindi la previsione scende di 300.
        decPlanned.isDone = true
        #expect(context.safeSave())
        let after = cache.expectedByAccountID(for: [account], day: nov28, calendar: calendar)
        #expect(after[account.persistentModelID] == 580)
        #expect(after != before)

        // ListCache: due scaduti, se ne conferma uno e l'elenco passa da 2 a 1.
        let hotel = Transaction(name: "Hotel", amount: 90, type: .uscita, category: "Viaggi", date: date(15, month: 10), isDone: false, account: account)
        let dinner = Transaction(name: "Cena", amount: 40, type: .uscita, category: "Ristoranti", date: date(20, month: 10), isDone: false, account: account)
        context.insert(hotel)
        context.insert(dinner)
        #expect(context.safeSave())

        let listCache = OverduePlannedMovements.ListCache()
        let overdueBefore = listCache.list(from: [hotel, dinner], relativeTo: nov28, calendar: calendar)
        #expect(Set(overdueBefore.map(\.id)) == [hotel.id, dinner.id])

        hotel.isDone = true
        #expect(context.safeSave())
        let overdueAfter = listCache.list(from: [hotel, dinner], relativeTo: nov28, calendar: calendar)
        #expect(overdueAfter.map(\.id) == [dinner.id])
    }

    @Test("FilteredCache aggiorna l'elenco al cambio di categoria e di importo minimo/massimo con la stessa cache")
    func filteredCacheFollowsCategoryAndAmountFilters() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let account = Account(name: "Principale", type: .conto, initialBalance: 500)
        context.insert(account)

        let nov28 = date(28, month: 11)
        let hotel = Transaction(name: "Hotel", amount: 90, type: .uscita, category: "Viaggi", date: date(15, month: 10), isDone: false, account: account)
        let dinner = Transaction(name: "Cena", amount: 40, type: .uscita, category: "Ristoranti", date: date(20, month: 10), isDone: false, account: account)
        context.insert(hotel)
        context.insert(dinner)
        #expect(context.safeSave())

        let cache = OverduePlannedMovements.FilteredCache()
        func ids(category: String = "", min: String = "", max: String = "") -> Set<UUID> {
            Set(cache.list(
                from: [hotel, dinner], relativeTo: nov28, selectedMonth: nov28, searchQuery: "", useCustomDates: false,
                filter: .tutti, selectedCategory: category, minAmountText: min, maxAmountText: max,
                rules: [], calendar: calendar
            ).map(\.id))
        }

        #expect(ids() == [hotel.id, dinner.id])
        #expect(ids(category: "Viaggi") == [hotel.id])
        #expect(ids(category: "Ristoranti") == [dinner.id])
        #expect(ids(category: "Viaggi", min: "50") == [hotel.id])
        #expect(ids(category: "Viaggi", min: "100").isEmpty)
        #expect(ids(min: "50") == [hotel.id])
        #expect(ids(max: "50") == [dinner.id])
        #expect(ids(min: "30", max: "100") == [hotel.id, dinner.id])
        #expect(ids() == [hotel.id, dinner.id])
    }
}
