import AppIntents
import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Add movement unified intent (S-70j)")
@MainActor
struct AddMovementIntentTests {
    private func historyMovement(
        name: String,
        category: String,
        createdAt: Double = 1,
        isDone: Bool = true,
        isTransfer: Bool = false
    ) -> LastUsedCategory.Movement {
        .init(
            name: name,
            category: category,
            createdAt: Date(timeIntervalSince1970: createdAt),
            isDone: isDone,
            isTransfer: isTransfer
        )
    }

    @Test func suggestLikeAppDistinguishesHistoryFromKeyword() {
        let available: Set<String> = ["Cibo", "Svago", "Altro"]
        let history = [
            historyMovement(name: "Pizza margherita", category: "Cibo", createdAt: 10),
        ]

        let exactMatch = IntentCategoryMenu.suggestLikeApp(
            for: "pizza margherita",
            history: history,
            available: available,
            classify: { _ in "Svago" }
        )
        #expect(exactMatch == .init(category: "Cibo", source: .history))

        let keywordMatch = IntentCategoryMenu.suggestLikeApp(
            for: "pizza",
            history: history,
            available: available,
            classify: { _ in "Cibo" }
        )
        #expect(keywordMatch == .init(category: "Cibo", source: .keyword))

        let shortInput = IntentCategoryMenu.suggestLikeApp(
            for: "ab",
            history: [],
            available: available,
            classify: { _ in "Cibo" }
        )
        #expect(shortInput == nil)

        let altroClassifier = IntentCategoryMenu.suggestLikeApp(
            for: "qualcosa",
            history: [],
            available: available,
            classify: { _ in "Altro" }
        )
        #expect(altroClassifier == nil)
    }

    @Test func movementChoicesReplicateAppForHistoryKeywordAndDedup() throws {
        let itURL = try #require(Bundle.main.url(forResource: "it", withExtension: "lproj"))
        let itBundle = try #require(Bundle(url: itURL))
        let all = ["Cibo", "Svago", "Trasporti", "Altro"]

        // History match ("pizza" -> "Cibo") wins as "ultima usata" even when recent overall was "Svago".
        let historyChoices = IntentCategoryMenu.movementChoices(
            all: all,
            recentOfType: "Svago",
            nameSuggestion: .init(category: "Cibo", source: .history),
            bundle: itBundle
        )
        #expect(historyChoices.map(\.id) == ["Cibo", "Svago", "Trasporti", "Altro"])
        #expect(historyChoices[0].title == "Cibo · ultima usata")
        #expect(historyChoices[1].title == "Svago")

        // Keyword match ("Cibo") != recentOfType ("Svago") -> "Svago · ultima usata", then "Cibo · suggerita".
        let distinctChoices = IntentCategoryMenu.movementChoices(
            all: all,
            recentOfType: "Svago",
            nameSuggestion: .init(category: "Cibo", source: .keyword),
            bundle: itBundle
        )
        #expect(distinctChoices.map(\.id) == ["Svago", "Cibo", "Trasporti", "Altro"])
        #expect(distinctChoices[0].title == "Svago · ultima usata")
        #expect(distinctChoices[1].title == "Cibo · suggerita")
        #expect(distinctChoices[2].title == "Trasporti")

        // When recentOfType == keyword match -> single deduplicated row with lowercase "ultima usata".
        let equalChoices = IntentCategoryMenu.movementChoices(
            all: all,
            recentOfType: "Cibo",
            nameSuggestion: .init(category: "Cibo", source: .keyword),
            bundle: itBundle
        )
        #expect(equalChoices.map(\.id) == ["Cibo", "Svago", "Trasporti", "Altro"])
        #expect(equalChoices[0].title == "Cibo · ultima usata")
        #expect(equalChoices[1].title == "Svago")
    }

    @Test(arguments: ["it", "en", "de", "es", "fr", "ja", "zh-Hans"])
    func movementChoicesLocalizeLowercaseTagsAndIntentKeysAcrossAllLanguages(language: String) throws {
        let lprojURL = try #require(Bundle.main.url(forResource: language, withExtension: "lproj"))
        let langBundle = try #require(Bundle(url: lprojURL))

        let choices = IntentCategoryMenu.movementChoices(
            all: ["Cibo", "Trasporti", "Altro"],
            recentOfType: "Cibo",
            nameSuggestion: .init(category: "Trasporti", source: .keyword),
            bundle: langBundle
        )
        let food = IntentCategoryMenu.localizedCategoryName("Cibo", bundle: langBundle)
        let transport = IntentCategoryMenu.localizedCategoryName("Trasporti", bundle: langBundle)
        let lastTag = langBundle.localizedString(forKey: "ultima usata", value: "MISSING", table: nil)
        let sugTag = langBundle.localizedString(forKey: "suggerita", value: "MISSING", table: nil)
        #expect(lastTag != "MISSING")
        #expect(sugTag != "MISSING")
        #expect(choices[0].id == "Cibo")
        #expect(choices[0].title == "\(food) · \(lastTag)")
        #expect(choices[1].id == "Trasporti")
        #expect(choices[1].title == "\(transport) · \(sugTag)")

        let titleLoc = langBundle.localizedString(forKey: "Aggiungi movimento", value: "MISSING", table: nil)
        let catDialog = langBundle.localizedString(forKey: "In quale categoria?", value: "MISSING", table: nil)
        #expect(titleLoc != "MISSING")
        #expect(catDialog != "MISSING")
    }

    @Test func movementChoicesTruncatesOnlyLongCustomNameAndPreservesRawId() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Account.self, Transaction.self, Budget.self, Goal.self, Category.self, RecurringRule.self,
            configurations: config
        )
        let ctx = container.mainContext
        let longCustom = "Spese condominiali straordinarie 2026"
        ctx.insert(Category(name: longCustom, icon: "house.fill", isDefault: false, sortOrder: 0))
        ctx.insert(Category(name: "Cibo", icon: "fork.knife", isDefault: true, sortOrder: 1))
        ctx.insert(Category(name: "Svago", icon: "gamecontroller.fill", isDefault: true, sortOrder: 2))

        // History has "Pizza" -> "Cibo", latest overall is "Cinema" -> "Svago".
        let oldPizza = Transaction(name: "Pizza", amount: 12, type: .uscita, category: "Cibo", date: Date(), isDone: true)
        oldPizza.createdAt = Date(timeIntervalSince1970: 10)
        let latestCinema = Transaction(name: "Cinema", amount: 10, type: .uscita, category: "Svago", date: Date(), isDone: true)
        latestCinema.createdAt = Date(timeIntervalSince1970: 20)
        let income = Transaction(name: "Bonus", amount: 300, type: .entrata, category: "Lavoro", date: Date(), isDone: true)
        income.createdAt = Date(timeIntervalSince1970: 30)
        ctx.insert(oldPizza)
        ctx.insert(latestCinema)
        ctx.insert(income)
        try ctx.save()

        let itURL = try #require(Bundle.main.url(forResource: "it", withExtension: "lproj"))
        let itBundle = try #require(Bundle(url: itURL))

        // "pizza" matches DB history -> "Cibo · ultima usata" in expense flow.
        let pizzaChoices = IntentCategoryMenu.movementChoices(
            name: "pizza",
            type: TransactionType.uscita.rawValue,
            context: ctx,
            bundle: itBundle
        )
        #expect(pizzaChoices.first?.id == "Cibo")
        #expect(pizzaChoices.first?.title == "Cibo · ultima usata")
        #expect(pizzaChoices.filter { $0.id == "Cibo" }.count == 1)

        // Income flow uses last income ("Lavoro") as "ultima usata" when name has no history/keyword.
        let incomeChoices = IntentCategoryMenu.movementChoices(
            name: "Premio aziendale",
            type: TransactionType.entrata.rawValue,
            context: ctx,
            bundle: itBundle
        )
        #expect(incomeChoices.first?.id == "Lavoro")
        #expect(incomeChoices.first?.title == "Lavoro · ultima usata")

        // Long custom name preserves raw ID while truncating display title with "…" only on name.
        let customTx = Transaction(name: "Caldaia condominio", amount: 250, type: .uscita, category: longCustom, date: Date(), isDone: true)
        customTx.createdAt = Date(timeIntervalSince1970: 40)
        ctx.insert(customTx)
        try ctx.save()

        let longChoices = IntentCategoryMenu.movementChoices(
            name: "caldaia condominio",
            type: TransactionType.uscita.rawValue,
            context: ctx,
            bundle: itBundle
        )
        let first = try #require(longChoices.first)
        #expect(first.id == longCustom)
        #expect(first.title.count <= IntentCategoryMenu.maxRowTitleLength)
        #expect(first.title.hasSuffix("… · ultima usata"))
        #expect(longChoices.filter { $0.id == longCustom }.count == 1)

        let entity = IntentCategoryChoice(choice: first)
        #expect(entity.id == longCustom)
        #expect(entity.displayRepresentation.subtitle == nil)
        #expect(String(localized: entity.displayRepresentation.title) == first.title)
    }

    @Test func saveMovementPersistsExpenseAndIncomeWithChosenCategoryAndAccount() throws {
        let config = ModelConfiguration(isStoredInMemoryOnly: true)
        let container = try ModelContainer(
            for: Account.self, Transaction.self, Budget.self, Goal.self, Category.self, RecurringRule.self,
            configurations: config
        )
        let ctx = container.mainContext
        let card = Account(name: "Carta", type: .carta, initialBalance: 500)
        let cash = Account(name: "Contanti", type: .contanti, initialBalance: 100)
        ctx.insert(card)
        ctx.insert(cash)
        ctx.insert(Category(name: "Cibo", icon: "fork.knife", isDefault: true, sortOrder: 0))
        ctx.insert(Category(name: "Lavoro", icon: "briefcase.fill", isDefault: true, sortOrder: 1))
        try ctx.save()

        let savedExpense = try AddMovementIntent.saveMovement(
            type: .uscita,
            amount: 14.5,
            name: "Pizza",
            accountName: nil,
            categoryName: "Cibo",
            in: ctx
        )
        #expect(savedExpense.transaction.transactionType == .uscita)
        #expect(savedExpense.transaction.category == "Cibo")
        #expect(savedExpense.transaction.categoryIcon == "fork.knife")
        #expect(savedExpense.transaction.amount == Decimal(string: "14.5"))
        #expect(savedExpense.accountName != nil)

        let savedIncome = try AddMovementIntent.saveMovement(
            type: .entrata,
            amount: 1500,
            name: "Stipendio",
            accountName: "Contanti",
            categoryName: "Lavoro",
            in: ctx
        )
        #expect(savedIncome.transaction.transactionType == .entrata)
        #expect(savedIncome.transaction.category == "Lavoro")
        #expect(savedIncome.accountName == "Contanti")
    }
}
