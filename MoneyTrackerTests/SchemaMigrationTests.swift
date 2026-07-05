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
