import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
@Suite("Account usage count (S-70h)")
struct AccountUsageCountTests {
    @Test("Conteggio leggero per conto con fetchCount e ordinamento per uso")
    func fetchAccountUsageCountsMatchesTransactionCountAndOrder() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(
            for: schema,
            configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
        )
        let ctx = container.mainContext

        let a1 = Account(name: "Conto", type: .conto, initialBalance: 100)
        let a2 = Account(name: "Carta", type: .carta, initialBalance: 200)
        let a3 = Account(name: "Archiviato", type: .contanti, initialBalance: 50)
        a3.isArchived = true
        ctx.insert(a1)
        ctx.insert(a2)
        ctx.insert(a3)

        ctx.insert(Transaction(name: "Caffè", amount: 2, type: .uscita, account: a2))
        ctx.insert(Transaction(name: "Pranzo", amount: 12, type: .uscita, account: a2))
        ctx.insert(Transaction(name: "Cena", amount: 25, type: .uscita, account: a2))
        ctx.insert(Transaction(name: "Bolletta", amount: 60, type: .uscita, account: a1))
        ctx.insert(Transaction(name: "Vecchio", amount: 10, type: .uscita, account: a3))
        ctx.insert(Transaction(name: "Senza conto", amount: 5, type: .uscita, account: nil))
        try ctx.save()

        let counts = AddTransactionView.fetchAccountUsageCounts(for: [a1, a2, a3], context: ctx)
        #expect(counts[a1.id] == 1)
        #expect(counts[a2.id] == 3)
        #expect(counts[a3.id] == nil)

        let ordered = AddTransactionView.orderByUsage([a1, a2], counts: counts)
        #expect(ordered.map { $0.id } == [a2.id, a1.id])
    }
}
