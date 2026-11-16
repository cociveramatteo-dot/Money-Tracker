import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Demo showcase", .serialized)
@MainActor
struct DemoDataSeederTests {
    @Test("Reset replaces series and copies; showcase covers history, plans and overrides")
    func showcaseAndReset() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = container.mainContext
        // Do not leave the app's global version marker changed by an in-memory test.
        let saved = UserDefaults.standard.object(forKey: "demoSeedVersion")
        defer {
            if let saved { UserDefaults.standard.set(saved, forKey: "demoSeedVersion") }
            else { UserDefaults.standard.removeObject(forKey: "demoSeedVersion") }
        }
        DemoDataSeeder.forceReset(context: context)
        let oldRules = try context.fetch(FetchDescriptor<RecurringRule>()).map(\.id)
        let oldCount = try context.fetchCount(FetchDescriptor<Transaction>())
        DemoDataSeeder.forceReset(context: context)
        let rules = try context.fetch(FetchDescriptor<RecurringRule>())
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        #expect(rules.count == 9)
        #expect(rules.allSatisfy { !oldRules.contains($0.id) })
        #expect(transactions.count == oldCount)
        #expect(Set(transactions.map(\.id)).count == transactions.count)
        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 4)
        #expect(try context.fetchCount(FetchDescriptor<Goal>()) == 4)
        #expect(try RecurringMaterializer().materializeDue(context: context) == 0)
        #expect(rules.contains { $0.type == TransactionType.entrata.rawValue })
        let overridden = try #require(rules.first { !RecurrenceExceptionCodec.decode($0.exceptionsJSON).isEmpty })
        let exception = try #require(RecurrenceExceptionCodec.decode(overridden.exceptionsJSON).first)
        let copyID = RecurrenceCalculator.occurrenceID(ruleId: overridden.id, key: exception.key)
        #expect(transactions.first { $0.id == copyID }?.amount == Decimal(string: "112.40"))
        #expect(transactions.contains { !$0.templateId.isEmpty && $0.isDone && Calendar.current.isDateInToday($0.date) })
        #expect(transactions.contains { !$0.isDone && $0.date > Date() })
        let oldest = try #require(transactions.map(\.date).min())
        #expect(Calendar.current.dateComponents([.month], from: oldest, to: Date()).month! >= 6)
        let transferGroups = Dictionary(grouping: transactions.filter(\.isTransfer), by: \.transferGroupId)
        #expect(transferGroups.count == 8)
        #expect(transferGroups.values.allSatisfy { $0.count == 2 && $0.reduce(Decimal.zero) { $0 + $1.signedAmount } == 0 })
        let used = Set(transactions.map(\.category))
        #expect(Set(Category.defaults.map(\.name)).subtracting(["Rettifica saldo"]).isSubset(of: used))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = .current
        let budgets = try context.fetch(FetchDescriptor<Budget>()).filter {
            $0.month == calendar.component(.month, from: Date()) && $0.year == calendar.component(.year, from: Date())
        }
        let currentPlans = transactions.filter {
            !$0.isDone && calendar.isDate($0.date, equalTo: Date(), toGranularity: .month)
        }
        #expect(currentPlans.reduce(Decimal.zero) { $0 + $1.signedAmount } != 0)
        let ratios = budgets.map { budget in
            transactions.filter { $0.category == budget.category && $0.isDone && !$0.isTransfer &&
                calendar.isDate($0.date, equalTo: Date(), toGranularity: .month) }
                .reduce(Decimal.zero) { $0 + $1.amount } / budget.monthlyLimit
        }
        #expect(ratios.contains { $0 < Decimal(string: "0.8")! })
        #expect(ratios.contains { $0 >= Decimal(string: "0.8")! && $0 < 1 })
        #expect(ratios.contains { $0 >= 1 })
    }
}
