import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Recurring materialization", .serialized)
@MainActor
struct RecurringMaterializerTests {
    private let zone = TimeZone(identifier: "Europe/Rome")!
    private var materializer: RecurringMaterializer { RecurringMaterializer(timeZone: zone) }
    private var calendar: Calendar {
        var value = Calendar(identifier: .gregorian)
        value.timeZone = zone
        return value
    }

    private func date(_ year: Int = 2026, _ month: Int, _ day: Int = 1) -> Date {
        calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeContainer() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    private func rule(start: Date, frequency: String = "mensile", watermark: Date? = nil) -> RecurringRule {
        RecurringRule(name: "Affitto", amount: Decimal(string: "0.2")!, type: "Uscita",
                      category: "Casa", categoryIcon: "house", notes: "Nota", isFixed: true,
                      frequency: frequency, startDate: start, materializedThrough: watermark)
    }

    @Test("The whole current month is planned, including days after today; second run is a no-op")
    func currentMonthAndIdempotence() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let account = Account(name: "Conto", type: .conto, initialBalance: Decimal(100))
        context.insert(account)
        let input = rule(start: date(2026, 1, 31))
        input.accountId = account.id
        context.insert(input)
        try context.save()
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 1)) == 1)
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let copy = try #require(transactions.first)
        #expect(transactions.count == 1)
        #expect(copy.date == date(2026, 3, 31))
        #expect(!copy.isDone && copy.isFixed && !copy.isTransfer)
        #expect(copy.amount == Decimal(string: "0.2")!)
        #expect(copy.templateId == input.id.uuidString && copy.recurringFrequency == "")
        #expect(copy.id == RecurrenceCalculator.occurrenceID(ruleId: input.id, key: "2026-03-31"))
        #expect(copy.name == input.name && copy.notes == input.notes)
        #expect(copy.category == input.category && copy.categoryIcon == input.categoryIcon)
        #expect(copy.account?.id == account.id)
        #expect(input.materializedThrough == date(2026, 3))
        #expect(account.currentBalance == 100)
        #expect(account.futureBalance == Decimal(string: "99.8")!)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 31)) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 1)
        #expect(!context.hasChanges)
    }

    @Test("Deleted copies stay deleted and edited/completed copies stay untouched")
    func preservesCopies() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let input = rule(start: date(2026, 3, 1), frequency: "settimanale")
        context.insert(input)
        try materializer.materializeDue(context: context, now: date(2026, 3, 1))
        let copies = try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)]))
        #expect(copies.count == 5)
        context.delete(copies[0])
        copies[1].amount = Decimal(string: "99.01")!
        copies[1].name = "Modificata"
        copies[1].date = date(2026, 3, 10)
        copies[2].isDone = true
        copies[2].notes = "Pagata"
        try context.save()
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 31)) == 0)
        // Revisit the same months after a watermark merge/reset: deterministic ID is
        // the second protection, and must not overwrite any surviving copy.
        input.materializedThrough = date(2026, 2)
        var exceptions = RecurrenceExceptionCodec.decode(input.exceptionsJSON)
        exceptions["2026-03-01"] = RecurrenceException(skip: true)
        input.exceptionsJSON = try RecurrenceExceptionCodec.encode(exceptions)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 31)) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 4)
        #expect(copies[1].amount == Decimal(string: "99.01")! && copies[1].name == "Modificata")
        #expect(copies[1].date == date(2026, 3, 10))
        #expect(copies[2].isDone && copies[2].notes == "Pagata")
    }

    @Test("Three missed months recover in one run")
    func backfill() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let input = rule(start: date(2026, 1, 31), watermark: date(2026, 1))
        context.insert(input)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 4, 1)) == 3)
        let copies = try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)]))
        #expect(copies.map(\.date) == [date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30)])
        #expect(copies.allSatisfy { !$0.isDone })
        #expect(input.materializedThrough == date(2026, 4))
    }

    @Test("Backfill is capped at the latest 36 months, with a stable watermark")
    func capsBackfill() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let input = rule(start: date(2000, 1, 15), watermark: date(2000, 1))
        context.insert(input)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 11, 1)) == 36)
        let copies = try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)]))
        #expect(copies.first?.date == date(2023, 12, 15))
        #expect(copies.last?.date == date(2026, 11, 15))
        #expect(input.materializedThrough == date(2026, 11))
        #expect(try materializer.materializeDue(context: context, now: date(2026, 11, 2)) == 0)
    }

    @Test("A new rule never generates past months; future rules wait")
    func newRules() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let past = rule(start: date(2000, 1, 15))
        let future = rule(start: date(2026, 6, 15))
        context.insert(past)
        context.insert(future)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 1)) == 1)
        #expect(past.materializedThrough == date(2026, 3))
        #expect(future.materializedThrough == date(2026, 5))
        #expect(try materializer.materializeDue(context: context, now: date(2026, 6, 1)) == 4)
        let copies = try context.fetch(FetchDescriptor<Transaction>())
        #expect(copies.filter { $0.templateId == future.id.uuidString }.map(\.date) == [date(2026, 6, 15)])
    }

    @Test("Terminated rules and skips create nothing; weekly overrides keep exact Decimal")
    func exceptionsAndEnd() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let ended = rule(start: date(2026, 1, 15))
        ended.endDate = date(2026, 2, 15)
        context.insert(ended)
        let input = rule(start: date(2026, 3, 1), frequency: "settimanale")
        input.exceptionsJSON = try RecurrenceExceptionCodec.encode([
            "2026-03-01": RecurrenceException(skip: true),
            "2026-03-08": RecurrenceException(amount: "0.1", date: date(2026, 3, 9), name: "Altro", notes: "Eccezione")
        ])
        input.endDate = date(2026, 3, 15)
        context.insert(input)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 1)) == 2)
        let copies = try context.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)]))
        #expect(copies.map(\.date) == [date(2026, 3, 9), date(2026, 3, 15)])
        #expect(copies.first?.name == "Altro" && copies.first?.notes == "Eccezione")
        #expect(copies.reduce(Decimal.zero) { $0 + $1.amount } == Decimal(string: "0.3")!)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 4, 1)) == 0)
    }

    @Test("Independent containers produce the same occurrence IDs")
    func deterministicContainers() throws {
        let id = UUID()
        func generate() throws -> [UUID] {
            let container = try makeContainer()
            let input = rule(start: date(2026, 3, 1), frequency: "settimanale")
            input.id = id
            container.mainContext.insert(input)
            try materializer.materializeDue(context: container.mainContext, now: date(2026, 3, 1))
            return try container.mainContext.fetch(FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\.date)])).map(\.id)
        }
        let first = try generate()
        #expect(first.count == 5)
        #expect(first == (try generate()))
    }

    @Test("Materialization rejects a secondary context")
    func mainContextOnly() throws {
        let container = try makeContainer()
        let secondary = ModelContext(container)
        #expect(throws: RecurringMaterializer.MaterializationError.requiresMainContext) {
            try materializer.materializeDue(context: secondary, now: date(2026, 3))
        }
    }

    @Test("Computing twelve months of virtuals leaves counts, balances and month totals unchanged")
    func virtualInvariance() throws {
        let container = try makeContainer()
        let context = container.mainContext
        let accounts = [Account(name: "A", type: .conto, initialBalance: 100), Account(name: "B", type: .contanti, initialBalance: 10)]
        for account in accounts {
            context.insert(account)
            context.insert(Transaction(name: "Fatta", amount: Decimal(string: "0.1")!, type: .uscita, date: date(2026, 3, 1), account: account))
            context.insert(Transaction(name: "Pianificata", amount: Decimal(string: "0.2")!, type: .entrata, date: date(2026, 3, 20), isDone: false, account: account))
        }
        for frequency in ["mensile", "settimanale", "annuale"] {
            let input = rule(start: date(2026, 3, 15), frequency: frequency)
            input.accountId = accounts[0].id
            context.insert(input)
        }
        #expect(context.safeSave())
        func state() throws -> [Decimal] {
            // Invalidate explicitly: a stale balance cache must not mask a regression.
            AccountBalanceCache.shared.invalidateAll()
            let transactions = try context.fetch(FetchDescriptor<Transaction>())
            let monthRows = transactions.filter { calendar.isDate($0.date, equalTo: date(2026, 3), toGranularity: .month) }
            return [Decimal(transactions.count)] + accounts.flatMap { [$0.currentBalance, $0.futureBalance] }
                + [monthRows.filter { $0.type == "Entrata" }.reduce(.zero) { $0 + $1.amount },
                   monthRows.filter { $0.type == "Uscita" }.reduce(.zero) { $0 + $1.amount }]
        }
        let before = try state()
        let rules = try context.fetch(FetchDescriptor<RecurringRule>())
        let calculator = RecurrenceCalculator(timeZone: zone)
        var count = 0
        for rule in rules {
            let snapshot = RuleSnapshot(id: rule.id, name: rule.name, amount: rule.amount, type: rule.type,
                                        category: rule.category, categoryIcon: rule.categoryIcon, accountId: rule.accountId,
                                        frequency: rule.frequency, startDate: rule.startDate)
            count += calculator.occurrences(rule: snapshot, in: DateInterval(start: date(2026, 4), end: date(2027, 4))).count
        }
        #expect(count > 12)
        #expect(try state() == before)
        #expect(!context.hasChanges)
    }
}

extension RecurringMaterializerTests {
    @Test("Migrating a legacy V2 disk store and running materialization never converts templates or copies")
    func migratedLegacyIsUntouched() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("LegacyMaterializer-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("legacy.store")
        let templateID = UUID()
        let copyID = UUID()
        func seedV2() throws {
            let schema = Schema(versionedSchema: SchemaV2.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let account = Account(name: "Legacy", type: .conto, initialBalance: 100)
            container.mainContext.insert(account)
            let template = Transaction(name: "Template", amount: Decimal(string: "19.99")!, type: .uscita,
                                       date: date(2025, 1, 31), recurringFrequency: "mensile", account: account)
            template.id = templateID
            let copy = Transaction(name: "Copia", amount: Decimal(string: "0.1")!, type: .uscita,
                                   date: date(2025, 2, 28), isDone: false, templateId: templateID.uuidString, account: account)
            copy.id = copyID
            container.mainContext.insert(template)
            container.mainContext.insert(copy)
            try container.mainContext.save()
        }
        try seedV2()
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, migrationPlan: MoneyTrackerMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: url))
        let context = container.mainContext
        AccountBalanceCache.shared.invalidateAll()
        let account = try #require(context.fetch(FetchDescriptor<Account>()).first)
        let before = [account.currentBalance, account.futureBalance]
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 1)) == 0)
        #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0)
        let copies = try context.fetch(FetchDescriptor<Transaction>())
        #expect(copies.count == 2)
        let template = try #require(copies.first { $0.id == templateID })
        let copy = try #require(copies.first { $0.id == copyID })
        #expect(template.recurringFrequency == "mensile" && template.templateId.isEmpty)
        #expect(template.amount == Decimal(string: "19.99")! && template.date == date(2025, 1, 31) && template.isDone)
        #expect(copy.recurringFrequency.isEmpty && copy.templateId == templateID.uuidString)
        #expect(copy.amount == Decimal(string: "0.1")! && copy.date == date(2025, 2, 28) && !copy.isDone)
        AccountBalanceCache.shared.invalidateAll()
        #expect([account.currentBalance, account.futureBalance] == before)
        #expect(!context.hasChanges)
    }

    @Test("Watermark survives reopening the disk store, even when a generated copy was deleted")
    func persistedWatermark() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("Watermark-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("rule.store")
        func seed() throws {
            let schema = Schema(versionedSchema: SchemaV3.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let context = container.mainContext
            context.insert(rule(start: date(2026, 3, 15)))
            #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 1)) == 1)
            context.delete(try #require(context.fetch(FetchDescriptor<Transaction>()).first))
            try context.save()
        }
        try seed()
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let context = container.mainContext
        #expect(try context.fetch(FetchDescriptor<RecurringRule>()).first?.materializedThrough == date(2026, 3))
        #expect(try materializer.materializeDue(context: context, now: date(2026, 3, 31)) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(try materializer.materializeDue(context: context, now: date(2026, 4, 1)) == 1)
        #expect(try context.fetch(FetchDescriptor<Transaction>()).first?.date == date(2026, 4, 15))
    }
}
