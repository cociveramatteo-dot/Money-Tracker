import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Intent category menu")
@MainActor
struct IntentCategoryMenuTests {
    private func movement(
        category: String = "Cibo",
        type: String = TransactionType.uscita.rawValue,
        createdAt: Double = 1,
        isDone: Bool = true,
        isTransfer: Bool = false,
        isRecurring: Bool = false
    ) -> IntentCategoryMenu.Movement {
        .init(
            category: category,
            type: type,
            createdAt: Date(timeIntervalSince1970: createdAt),
            isDone: isDone,
            isTransfer: isTransfer,
            isRecurring: isRecurring
        )
    }

    @Test func topDeduplicatesAndPreservesOrder() {
        let distinct = IntentCategoryMenu.top(suggested: "Cibo", lastUsed: "Svago")
        #expect(distinct.suggested == "Cibo")
        #expect(distinct.lastUsed == "Svago")

        let equal = IntentCategoryMenu.top(suggested: "Cibo", lastUsed: "Cibo")
        #expect(equal.suggested == "Cibo")
        #expect(equal.lastUsed == nil)

        let onlyLast = IntentCategoryMenu.top(suggested: nil, lastUsed: "Svago")
        #expect(onlyLast.suggested == nil)
        #expect(onlyLast.lastUsed == "Svago")

        let none = IntentCategoryMenu.top(suggested: nil, lastUsed: nil)
        #expect(none.suggested == nil)
        #expect(none.lastUsed == nil)
    }

    @Test func resolvePrefersExplicitChoiceOverSuggestion() {
        #expect(IntentCategoryMenu.resolve(chosen: "Svago", suggested: "Cibo", fallback: "Altro") == "Svago")
        #expect(IntentCategoryMenu.resolve(chosen: "  Svago  ", suggested: "Cibo", fallback: "Altro") == "Svago")
        #expect(IntentCategoryMenu.resolve(chosen: "   ", suggested: "Cibo", fallback: "Altro") == "Cibo")
        #expect(IntentCategoryMenu.resolve(chosen: nil, suggested: "Cibo", fallback: "Altro") == "Cibo")
        #expect(IntentCategoryMenu.resolve(chosen: nil, suggested: nil, fallback: "Altro") == "Altro")
        #expect(IntentCategoryMenu.resolve(chosen: "Altro", suggested: "Cibo", fallback: "Altro") == "Altro")
    }

    @Test func lastUsedUsesCreatedAtAndFiltersInvalidMovements() {
        let available: Set<String> = ["Cibo", "Svago", "Altro", "Lavoro"]
        let history = [
            movement(category: "Cibo", createdAt: 10),
            movement(category: "Svago", createdAt: 5),
            movement(category: "Lavoro", type: TransactionType.entrata.rawValue, createdAt: 20),
            movement(category: "Altro", createdAt: 30, isDone: false),
            movement(category: "Altro", createdAt: 40, isTransfer: true),
            movement(category: "Altro", createdAt: 50, isRecurring: true),
        ]
        #expect(IntentCategoryMenu.lastUsed(history: history, type: TransactionType.uscita.rawValue, available: available) == "Cibo")

        let deletedLatest = [
            movement(category: "Cibo", createdAt: 1),
            movement(category: "Eliminata", createdAt: 2),
        ]
        #expect(IntentCategoryMenu.lastUsed(history: deletedLatest, type: TransactionType.uscita.rawValue, available: available) == nil)
    }

    @Test func allCategoriesMatchesLegacyOrderWithoutDuplicates() {
        let custom = ["Animali", "Cibo", "Hobby"]
        let result = IntentCategoryMenu.allCategories(custom: custom)
        #expect(result == [
            "Animali", "Cibo", "Hobby",
            "Trasporti", "Svago", "Shopping", "Salute",
            "Casa", "Abbonamenti", "Lavoro", "Istruzione", "Viaggi", "Regali", "Altro",
        ])
    }

    @Test func swiftDataLoadersSuggestHistoryAndLatestExpense() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Account.self, Transaction.self, Budget.self, Goal.self, Category.self, RecurringRule.self, configurations: config)
        let ctx = container.mainContext
        ctx.insert(Category(name: "Cibo", icon: "fork.knife", isDefault: true, sortOrder: 0))
        ctx.insert(Category(name: "Svago", icon: "gamecontroller.fill", isDefault: true, sortOrder: 1))
        ctx.insert(Category(name: "Altro", icon: "tray.fill", isDefault: true, sortOrder: 2))

        let older = Transaction(name: "Caffè", amount: 2, type: .uscita, category: "Svago", date: Date(), isDone: true)
        older.createdAt = Date(timeIntervalSince1970: 10)
        let newer = Transaction(name: "Bar", amount: 5, type: .uscita, category: "Cibo", date: Date().addingTimeInterval(-86400 * 10), isDone: true)
        newer.createdAt = Date(timeIntervalSince1970: 20)
        let recurring = Transaction(name: "Affitto", amount: 700, type: .uscita, category: "Casa", date: Date(), isDone: true, recurringFrequency: "mensile", templateId: UUID().uuidString)
        recurring.createdAt = Date(timeIntervalSince1970: 30)
        ctx.insert(older)
        ctx.insert(newer)
        ctx.insert(recurring)
        try ctx.save()

        let available: Set<String> = ["Cibo", "Svago", "Altro"]
        #expect(IntentCategoryMenu.lastUsed(type: TransactionType.uscita.rawValue, context: ctx, available: available) == "Cibo")
        #expect(IntentCategoryMenu.suggested(for: "caffè", context: ctx, available: available) == "Svago")
        #expect(IntentCategoryMenu.suggested(for: "pizza", context: ctx, available: available) == "Cibo")
        #expect(IntentCategoryMenu.suggested(for: "ab", context: ctx, available: available) == nil)

        let col = IntentCategoryMenu.collection(name: "caffè", type: TransactionType.uscita.rawValue, context: ctx)
        #expect(col.sections.count == 3)
        #expect(col.sections[0].items.map(\.value) == ["Svago"])
        #expect(col.sections[1].items.map(\.value) == ["Cibo"])

        let dedupCol = IntentCategoryMenu.collection(name: "pizza", type: TransactionType.uscita.rawValue, context: ctx)
        #expect(dedupCol.sections.count == 2)
        #expect(dedupCol.sections[0].items.map(\.value) == ["Cibo"])

        let nilCol = IntentCategoryMenu.collection(name: "pizza", type: TransactionType.uscita.rawValue, context: nil)
        #expect(nilCol.sections.count == 1)
    }

    @Test func incomeLastUsedFallbackAndChoiceOverride() {
        let available: Set<String> = ["Cibo", "Lavoro", "Regali"]
        let history = [
            movement(category: "Cibo", type: TransactionType.uscita.rawValue, createdAt: 30),
            movement(category: "Regali", type: TransactionType.entrata.rawValue, createdAt: 20),
        ]
        #expect(IntentCategoryMenu.lastUsed(history: history, type: TransactionType.entrata.rawValue, available: available) == "Regali")
        #expect(IntentCategoryMenu.lastUsed(history: history, type: TransactionType.uscita.rawValue, available: available) == "Cibo")

        #expect(IntentCategoryMenu.incomeFallback(categories: ["Cibo", "Lavoro"]) == "Lavoro")
        #expect(IntentCategoryMenu.incomeFallback(categories: ["Cibo"]) == "Cibo")
        #expect(IntentCategoryMenu.incomeFallback(categories: []) == "Lavoro")

        let fallback = IntentCategoryMenu.incomeFallback(categories: ["Cibo", "Lavoro"])
        #expect(IntentCategoryMenu.resolve(chosen: nil, suggested: nil, fallback: fallback) == "Lavoro")
        #expect(IntentCategoryMenu.resolve(chosen: "  ", suggested: nil, fallback: fallback) == "Lavoro")
        #expect(IntentCategoryMenu.resolve(chosen: "Regali", suggested: "Lavoro", fallback: fallback) == "Regali")
    }

    @Test func swiftDataIncomeCollectionUsesLatestIncomeOnly() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Account.self, Transaction.self, Budget.self, Goal.self, Category.self, RecurringRule.self, configurations: config)
        let ctx = container.mainContext
        ctx.insert(Category(name: "Cibo", icon: "fork.knife", isDefault: true, sortOrder: 0))
        ctx.insert(Category(name: "Lavoro", icon: "briefcase.fill", isDefault: true, sortOrder: 1))
        ctx.insert(Category(name: "Regali", icon: "gift.fill", isDefault: true, sortOrder: 2))

        let expense = Transaction(name: "Pizza", amount: 15, type: .uscita, category: "Cibo", date: Date(), isDone: true)
        expense.createdAt = Date(timeIntervalSince1970: 50)
        let income = Transaction(name: "Compleanno", amount: 100, type: .entrata, category: "Regali", date: Date(), isDone: true)
        income.createdAt = Date(timeIntervalSince1970: 10)
        ctx.insert(expense)
        ctx.insert(income)
        try ctx.save()

        let col = IntentCategoryMenu.collection(name: "stampante", type: TransactionType.entrata.rawValue, context: ctx)
        #expect(col.sections.count == 3)
        #expect(col.sections[0].items.map(\.value) == ["Lavoro"])
        #expect(col.sections[1].items.map(\.value) == ["Regali"])

        // Without "Stipendio" in Category table, "stipendio" yields no suggestion, only lastUsed.
        let noMatchCol = IntentCategoryMenu.collection(name: "stipendio", type: TransactionType.entrata.rawValue, context: ctx)
        #expect(noMatchCol.sections.count == 2)
        #expect(noMatchCol.sections[0].items.map(\.value) == ["Regali"])
    }
}
