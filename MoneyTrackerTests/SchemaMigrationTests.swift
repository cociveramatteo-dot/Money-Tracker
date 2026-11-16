import Testing
import SwiftData
import Foundation
@testable import MoneyTracker

/// Verifica end-to-end la migrazione SchemaV1 (Double) → SchemaV2 (Decimal):
/// scrive uno store reale su disco con la forma legacy, lo riapre con
/// `MoneyTrackerMigrationPlan` e controlla che i valori Decimal risultanti
/// corrispondano esattamente ai Double originali (nessuna perdita ulteriore).
@Suite("Schema migration V1 → V2", .serialized)
@MainActor
struct SchemaMigrationTests {

    private func seedV1Store(at url: URL) throws {
        let schema = Schema(versionedSchema: SchemaV1.self)
        let config = ModelConfiguration(schema: schema, url: url)
        let container = try ModelContainer(for: schema, configurations: config)
        let context = container.mainContext

        let account = SchemaV1.Account(
            name: "Conto", type: "Conto Bancario", initialBalance: 123.45,
            colorHex: "000000", isArchived: false, isExcludedFromTotal: false
        )
        context.insert(account)

        let transaction = SchemaV1.Transaction(
            name: "Spesa", amount: 42.5, type: "Uscita", category: "Cibo", categoryIcon: "fork.knife",
            date: Date(), isDone: true, isFixed: false, isTransfer: false, transferGroupId: "",
            notes: "", recurringFrequency: "", templateId: "", account: account
        )
        context.insert(transaction)

        let budget = SchemaV1.Budget(
            category: "Cibo", categoryIcon: "fork.knife", monthlyLimit: 300.0, month: 1, year: 2026, account: nil
        )
        context.insert(budget)

        let goal = SchemaV1.Goal(
            name: "Vacanza", targetAmount: 1000.0, currentAmount: 250.75, emoji: "airplane", deadline: nil
        )
        context.insert(goal)

        try context.save()
        // `container`/`context` escono di scope alla fine di questa funzione: ARC li
        // dealloca prima che il test riapra lo stesso file con SchemaV2, evitando
        // conflitti di lock sullo stesso store.
    }

    @Test("Gli importi Double esistenti diventano Decimal equivalenti dopo la migrazione")
    func migratesDoubleToDecimal() throws {
        let url = FileManager.default.temporaryDirectory
            .appendingPathComponent("MoneyTrackerMigrationTest-\(UUID().uuidString).store")
        defer {
            try? FileManager.default.removeItem(at: url)
            try? FileManager.default.removeItem(at: url.appendingPathExtension("-wal"))
            try? FileManager.default.removeItem(at: url.appendingPathExtension("-shm"))
        }

        try seedV1Store(at: url)

        let v2Schema = Schema(versionedSchema: SchemaV2.self)
        let v2Config = ModelConfiguration(schema: v2Schema, url: url)
        let v2Container = try ModelContainer(
            for: v2Schema,
            migrationPlan: MoneyTrackerMigrationPlan.self,
            configurations: v2Config
        )
        let v2Context = v2Container.mainContext

        let accounts = try v2Context.fetch(FetchDescriptor<Account>())
        #expect(accounts.count == 1)
        #expect(accounts.first?.initialBalance == Decimal(123.45))

        let transactions = try v2Context.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.count == 1)
        #expect(transactions.first?.amount == Decimal(42.5))

        let budgets = try v2Context.fetch(FetchDescriptor<Budget>())
        #expect(budgets.count == 1)
        #expect(budgets.first?.monthlyLimit == Decimal(300.0))

        let goals = try v2Context.fetch(FetchDescriptor<Goal>())
        #expect(goals.count == 1)
        #expect(goals.first?.targetAmount == Decimal(1000.0))
        #expect(goals.first?.currentAmount == Decimal(250.75))
    }
}

// Additive V3 coverage; existing V1 → V2 test above stays unchanged.
extension SchemaMigrationTests {
    private func seedV2Store(at url: URL) throws -> (UUID, UUID, UUID) {
        let schema = Schema(versionedSchema: SchemaV2.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
        let context = container.mainContext
        let account = Account(name: "Conto V2", type: .conto, initialBalance: Decimal(string: "1234.56")!)
        context.insert(account)
        let template = Transaction(name: "Legacy", amount: Decimal(string: "19.99")!, type: .uscita,
                                   category: "Casa", categoryIcon: "house", date: Date(timeIntervalSince1970: 1_700_000_000),
                                   isDone: true, isFixed: true, notes: "Originale", recurringFrequency: "mensile", account: account)
        context.insert(template)
        let copy = Transaction(name: "Copia", amount: Decimal(string: "0.10")!, type: .uscita,
                               category: "Casa", categoryIcon: "house", date: Date(timeIntervalSince1970: 1_702_000_000),
                               isDone: false, notes: "Pianificata", templateId: template.id.uuidString, account: account)
        context.insert(copy)
        let budget = Budget(category: "Casa", monthlyLimit: Decimal(string: "300.01")!, month: 11, year: 2026, account: account)
        context.insert(budget)
        context.insert(Goal(name: "Meta", targetAmount: Decimal(string: "1000.01")!, currentAmount: Decimal(string: "0.20")!))
        try context.save()
        return (account.id, template.id, copy.id)
    }

    @Test("V2 disk store opens as V3 without changing legacy transactions or creating rules")
    func migratesV2ToV3WithoutConvertingLegacy() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("MigrationV3-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let (accountID, templateID, copyID) = try seedV2Store(at: url)
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, migrationPlan: MoneyTrackerMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: url))
        let context = container.mainContext
        let accounts = try context.fetch(FetchDescriptor<Account>())
        #expect(accounts.count == 1)
        let account = try #require(accounts.first)
        #expect(account.id == accountID && account.name == "Conto V2")
        #expect(account.initialBalance == Decimal(string: "1234.56")!)
        #expect(account.transactions.count == 2)
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(transactions.count == 2)
        let template = try #require(transactions.first { $0.id == templateID })
        #expect(template.name == "Legacy" && template.amount == Decimal(string: "19.99")!)
        #expect(template.recurringFrequency == "mensile" && template.templateId == "")
        #expect(template.date == Date(timeIntervalSince1970: 1_700_000_000))
        #expect(template.isDone && template.isFixed && !template.isTransfer)
        #expect(template.notes == "Originale" && template.category == "Casa" && template.categoryIcon == "house")
        #expect(template.account?.id == accountID)
        let copy = try #require(transactions.first { $0.id == copyID })
        #expect(copy.name == "Copia" && copy.amount == Decimal(string: "0.10")!)
        #expect(copy.templateId == templateID.uuidString && copy.recurringFrequency == "")
        #expect(!copy.isDone && copy.notes == "Pianificata")
        #expect(copy.date == Date(timeIntervalSince1970: 1_702_000_000))
        #expect(copy.account?.id == accountID)
        let budgets = try context.fetch(FetchDescriptor<Budget>())
        #expect(budgets.count == 1 && budgets.first?.monthlyLimit == Decimal(string: "300.01")!)
        #expect(budgets.first?.account?.id == accountID)
        let goals = try context.fetch(FetchDescriptor<Goal>())
        #expect(goals.count == 1 && goals.first?.targetAmount == Decimal(string: "1000.01")!)
        #expect(goals.first?.currentAmount == Decimal(string: "0.20")!)
        #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0)
        // Materializer is S-13c; opening/migrating alone must never create occurrences.
        try context.save()
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 2)
    }

    @Test("V3 persists a new rule with exact Decimal and no account relationship")
    func persistsV3Rule() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("RuleV3-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        let id = UUID()
        let accountID = UUID()
        let start = Date(timeIntervalSince1970: 1_700_000_000)
        let exceptions = try RecurrenceExceptionCodec.encode(["2026-11-15": RecurrenceException(amount: "0.1")])
        func seed() throws {
            let schema = Schema(versionedSchema: SchemaV3.self)
            let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, url: url))
            let rule = RecurringRule(id: id, name: "Nuova", amount: Decimal(string: "0.2")!, type: "Uscita",
                                     notes: "Nota", isFixed: true, accountId: accountID, frequency: "mensile", startDate: start,
                                     endDate: start.addingTimeInterval(86400), exceptionsJSON: exceptions,
                                     materializedThrough: start, createdAt: start)
            container.mainContext.insert(rule)
            try container.mainContext.save()
        }
        try seed()
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, migrationPlan: MoneyTrackerMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: url))
        let rules = try container.mainContext.fetch(FetchDescriptor<RecurringRule>())
        #expect(rules.count == 1)
        let rule = try #require(rules.first)
        #expect(rule.id == id && rule.accountId == accountID)
        #expect(rule.amount == Decimal(string: "0.2")! && rule.name == "Nuova")
        #expect(rule.frequency == "mensile" && rule.isFixed && rule.notes == "Nota")
        #expect(rule.startDate == RecurrenceCalculator().noon(start))
        #expect(rule.endDate == RecurrenceCalculator().noon(start.addingTimeInterval(86400)))
        #expect(rule.materializedThrough == start && rule.createdAt == start)
        #expect(rule.exceptionsJSON == exceptions)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(try container.mainContext.fetchCount(FetchDescriptor<Account>()) == 0)
    }
}


extension SchemaMigrationTests {
    @Test("V1 store can migrate through V2 to the current V3 schema")
    func migratesV1ThroughV3() throws {
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent("MigrationV1V3-\(UUID())", isDirectory: true)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let url = directory.appendingPathComponent("test.store")
        try seedV1Store(at: url)
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, migrationPlan: MoneyTrackerMigrationPlan.self,
                                           configurations: ModelConfiguration(schema: schema, url: url))
        let context = container.mainContext
        #expect(try context.fetch(FetchDescriptor<Account>()).first?.initialBalance == Decimal(string: "123.45")!)
        #expect(try context.fetch(FetchDescriptor<Transaction>()).first?.amount == Decimal(string: "42.5")!)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 1)
        #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0)
        #expect(try context.fetch(FetchDescriptor<Budget>()).first?.monthlyLimit == 300)
        #expect(try context.fetch(FetchDescriptor<Goal>()).first?.currentAmount == Decimal(string: "250.75")!)
    }
}
