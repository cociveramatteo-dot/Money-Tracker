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

    @Test func topDeduplicatesAndOrdersLastUsedFirst() {
        let distinct = IntentCategoryMenu.top(suggested: "Trasporti", lastUsed: "Cibo")
        #expect(distinct.lastUsed == "Cibo")
        #expect(distinct.suggested == "Trasporti")

        let equal = IntentCategoryMenu.top(suggested: "Cibo", lastUsed: "Cibo")
        #expect(equal.lastUsed == "Cibo")
        #expect(equal.suggested == nil)

        let onlyLast = IntentCategoryMenu.top(suggested: nil, lastUsed: "Svago")
        #expect(onlyLast.lastUsed == "Svago")
        #expect(onlyLast.suggested == nil)

        let onlySuggested = IntentCategoryMenu.top(suggested: "Trasporti", lastUsed: nil)
        #expect(onlySuggested.lastUsed == nil)
        #expect(onlySuggested.suggested == "Trasporti")

        let none = IntentCategoryMenu.top(suggested: nil, lastUsed: nil)
        #expect(none.lastUsed == nil)
        #expect(none.suggested == nil)
    }

    @Test func remainingCategoriesExcludesTopItemsWithoutChangingOrder() {
        let all = ["Animali", "Cibo", "Trasporti", "Svago", "Altro"]
        let remainingBoth = IntentCategoryMenu.remainingCategories(
            all: all,
            excluding: (lastUsed: "Cibo", suggested: "Trasporti")
        )
        #expect(remainingBoth == ["Animali", "Svago", "Altro"])

        let remainingOne = IntentCategoryMenu.remainingCategories(
            all: all,
            excluding: (lastUsed: "Cibo", suggested: nil)
        )
        #expect(remainingOne == ["Animali", "Trasporti", "Svago", "Altro"])

        let remainingNone = IntentCategoryMenu.remainingCategories(
            all: all,
            excluding: (lastUsed: nil, suggested: nil)
        )
        #expect(remainingNone == all)
    }

    @Test func formattedTitleTruncatesOnlyCategoryNameAndKeepsTagIntact() {
        #expect(
            IntentCategoryMenu.formattedTitle(categoryDisplayName: "Cibo", tag: "Ultima usata")
            == "Cibo · Ultima usata"
        )
        #expect(
            IntentCategoryMenu.formattedTitle(categoryDisplayName: "Trasporti", tag: "Suggerita")
            == "Trasporti · Suggerita"
        )
        #expect(
            IntentCategoryMenu.formattedTitle(categoryDisplayName: "100% Casa", tag: nil)
            == "100% Casa"
        )

        let longName = "Spese condominiali straordinarie 2026"
        let tag = "Ultima usata"
        let truncated = IntentCategoryMenu.formattedTitle(categoryDisplayName: longName, tag: tag)
        #expect(truncated.count <= IntentCategoryMenu.maxRowTitleLength)
        #expect(truncated.hasSuffix("… · \(tag)"))
        #expect(!truncated.contains("2026"))

        let germanTag = "Zuletzt verwendet"
        let truncatedDe = IntentCategoryMenu.formattedTitle(categoryDisplayName: longName, tag: germanTag)
        #expect(truncatedDe.count <= IntentCategoryMenu.maxRowTitleLength)
        #expect(truncatedDe.hasSuffix("… · \(germanTag)"))
    }

    @Test(arguments: ["it", "en", "de", "es", "fr", "ja", "zh-Hans"])
    func itemTitlesAreLocalizedInAllSevenLanguagesAndPreserveRawValue(language: String) throws {
        let lprojURL = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let langBundle = try #require(Bundle(url: lprojURL))

        let lastItem = IntentCategoryMenu.item(for: "Cibo", tagKey: "Ultima usata", bundle: langBundle)
        #expect(lastItem.value == "Cibo")
        #expect(lastItem.description.subtitle == nil)
        let expectedFood = IntentCategoryMenu.localizedCategoryName("Cibo", bundle: langBundle)
        let expectedLast = langBundle.localizedString(forKey: "Ultima usata", value: "Ultima usata", table: nil)
        #expect(String(localized: lastItem.description.title) == "\(expectedFood) · \(expectedLast)")

        let sugItem = IntentCategoryMenu.item(for: "Trasporti", tagKey: "Suggerita", bundle: langBundle)
        #expect(sugItem.value == "Trasporti")
        #expect(sugItem.description.subtitle == nil)
        let expectedTransport = IntentCategoryMenu.localizedCategoryName("Trasporti", bundle: langBundle)
        let expectedSug = langBundle.localizedString(forKey: "Suggerita", value: "Suggerita", table: nil)
        #expect(String(localized: sugItem.description.title) == "\(expectedTransport) · \(expectedSug)")

        let customItem = IntentCategoryMenu.item(for: "100% Casa", tagKey: "Ultima usata", bundle: langBundle)
        #expect(customItem.value == "100% Casa")
        #expect(String(localized: customItem.description.title) == "100% Casa · \(expectedLast)")
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

        let itURL = try #require(Bundle.main.url(forResource: "it", withExtension: "lproj"))
        let itBundle = try #require(Bundle(url: itURL))

        let col = IntentCategoryMenu.collection(name: "caffè", type: TransactionType.uscita.rawValue, context: ctx, bundle: itBundle)
        #expect(col.sections.count == 2)
        #expect(col.sections[0].items.map(\.value) == ["Cibo", "Svago"])
        #expect(String(localized: col.sections[0].items[0].description.title) == "Cibo · Ultima usata")
        #expect(String(localized: col.sections[0].items[1].description.title) == "Svago · Suggerita")
        #expect(col.sections[0].items.allSatisfy { $0.description.subtitle == nil })
        let bottomValues = col.sections[1].items.map(\.value)
        #expect(!bottomValues.contains("Cibo"))
        #expect(!bottomValues.contains("Svago"))
        #expect(bottomValues.contains("Altro"))

        let dedupCol = IntentCategoryMenu.collection(name: "pizza", type: TransactionType.uscita.rawValue, context: ctx, bundle: itBundle)
        #expect(dedupCol.sections.count == 2)
        #expect(dedupCol.sections[0].items.map(\.value) == ["Cibo"])
        #expect(String(localized: dedupCol.sections[0].items[0].description.title) == "Cibo · Ultima usata")
        #expect(!dedupCol.sections[1].items.map(\.value).contains("Cibo"))

        let nilCol = IntentCategoryMenu.collection(name: "pizza", type: TransactionType.uscita.rawValue, context: nil, bundle: itBundle)
        #expect(nilCol.sections.count == 1)
        #expect(nilCol.sections[0].items.map(\.value) == IntentCategoryMenu.defaultCategories)
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

        let itURL = try #require(Bundle.main.url(forResource: "it", withExtension: "lproj"))
        let itBundle = try #require(Bundle(url: itURL))

        let col = IntentCategoryMenu.collection(name: "stampante", type: TransactionType.entrata.rawValue, context: ctx, bundle: itBundle)
        #expect(col.sections.count == 2)
        #expect(col.sections[0].items.map(\.value) == ["Regali", "Lavoro"])
        #expect(String(localized: col.sections[0].items[0].description.title) == "Regali · Ultima usata")
        #expect(String(localized: col.sections[0].items[1].description.title) == "Lavoro · Suggerita")
        #expect(!col.sections[1].items.map(\.value).contains("Regali"))
        #expect(!col.sections[1].items.map(\.value).contains("Lavoro"))

        // Without "Stipendio" in Category table, "stipendio" yields no suggestion, only lastUsed.
        let noMatchCol = IntentCategoryMenu.collection(name: "stipendio", type: TransactionType.entrata.rawValue, context: ctx, bundle: itBundle)
        #expect(noMatchCol.sections.count == 2)
        #expect(noMatchCol.sections[0].items.map(\.value) == ["Regali"])
        #expect(String(localized: noMatchCol.sections[0].items[0].description.title) == "Regali · Ultima usata")
        #expect(!noMatchCol.sections[1].items.map(\.value).contains("Regali"))
    }

    @Test func swiftDataCollectionHandlesSuggestedOnlyEmptyHistoryAndLongCustomName() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(for: Account.self, Transaction.self, Budget.self, Goal.self, Category.self, RecurringRule.self, configurations: config)
        let ctx = container.mainContext
        let longCustom = "Spese condominiali straordinarie 2026"
        ctx.insert(Category(name: longCustom, icon: "house.fill", isDefault: false, sortOrder: 0))
        ctx.insert(Category(name: "Cibo", icon: "fork.knife", isDefault: true, sortOrder: 1))

        let itURL = try #require(Bundle.main.url(forResource: "it", withExtension: "lproj"))
        let itBundle = try #require(Bundle(url: itURL))

        // No history and empty name -> single section with all categories.
        let emptyCol = IntentCategoryMenu.collection(name: "", type: TransactionType.uscita.rawValue, context: ctx, bundle: itBundle)
        #expect(emptyCol.sections.count == 1)
        #expect(emptyCol.sections[0].items.first?.value == longCustom)

        // No expense history, keyword match "pizza" -> suggested only, no duplicate below.
        let suggestedOnly = IntentCategoryMenu.collection(name: "pizza", type: TransactionType.uscita.rawValue, context: ctx, bundle: itBundle)
        #expect(suggestedOnly.sections.count == 2)
        #expect(suggestedOnly.sections[0].items.map(\.value) == ["Cibo"])
        #expect(String(localized: suggestedOnly.sections[0].items[0].description.title) == "Cibo · Suggerita")
        #expect(!suggestedOnly.sections[1].items.map(\.value).contains("Cibo"))

        // Long custom category as last used: title truncates name only, stored value remains full name.
        let tx = Transaction(name: "Caldaia", amount: 250, type: .uscita, category: longCustom, date: Date(), isDone: true)
        ctx.insert(tx)
        try ctx.save()

        let longCol = IntentCategoryMenu.collection(name: "altro", type: TransactionType.uscita.rawValue, context: ctx, bundle: itBundle)
        #expect(longCol.sections.count == 2)
        #expect(longCol.sections[0].items.map(\.value) == [longCustom])
        let displayedTitle = String(localized: longCol.sections[0].items[0].description.title)
        #expect(displayedTitle.count <= IntentCategoryMenu.maxRowTitleLength)
        #expect(displayedTitle.hasSuffix("… · Ultima usata"))
        #expect(!longCol.sections[1].items.map(\.value).contains(longCustom))
    }
}
