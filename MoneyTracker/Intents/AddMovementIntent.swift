import AppIntents
import Foundation
import SwiftData

// MARK: - Unified Movement Type (S-70j)

enum MovementKind: String, AppEnum, CaseIterable, Sendable {
    case uscita
    case entrata

    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Tipo")
    static let caseDisplayRepresentations: [MovementKind: DisplayRepresentation] = [
        .uscita: DisplayRepresentation(title: "Uscita"),
        .entrata: DisplayRepresentation(title: "Entrata"),
    ]

    var transactionType: TransactionType {
        switch self {
        case .uscita:  return .uscita
        case .entrata: return .entrata
        }
    }
}

// MARK: - Interactive Category Choice Entity (S-70j)

struct IntentCategoryChoice: AppEntity, Hashable, Sendable {
    static let typeDisplayRepresentation = TypeDisplayRepresentation(name: "Categoria")
    static let defaultQuery = IntentCategoryChoiceQuery()

    let id: String
    let displayTitle: String

    init(id: String, displayTitle: String) {
        self.id = id
        self.displayTitle = displayTitle
    }

    init(choice: IntentCategoryMenu.CategoryChoiceDisplay) {
        self.id = choice.id
        self.displayTitle = choice.title
    }

    var displayRepresentation: DisplayRepresentation {
        DisplayRepresentation(title: LocalizedStringResource("\(displayTitle)"))
    }

    static func == (lhs: IntentCategoryChoice, rhs: IntentCategoryChoice) -> Bool {
        lhs.id == rhs.id
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}

struct IntentCategoryChoiceQuery: EntityQuery {
    func entities(for identifiers: [String]) async throws -> [IntentCategoryChoice] {
        identifiers.map { id in
            IntentCategoryChoice(
                id: id,
                displayTitle: IntentCategoryMenu.localizedCategoryName(id)
            )
        }
    }

    @MainActor
    func suggestedEntities() async throws -> [IntentCategoryChoice] {
        let context = IntentContainer.shared?.mainContext
        let choices = IntentCategoryMenu.movementChoices(
            name: "",
            type: TransactionType.uscita.rawValue,
            context: context
        )
        return choices.map(IntentCategoryChoice.init(choice:))
    }
}

// MARK: - Unified Quick Add Movement Intent (S-70j)

struct AddMovementIntent: AppIntent {
    static let title: LocalizedStringResource = "Aggiungi movimento"
    static let description = IntentDescription("Aggiunge rapidamente un movimento al Money Tracker")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Tipo", description: "Uscita o entrata?")
    var movementType: MovementKind

    @Parameter(title: "Importo", description: "Importo del movimento")
    var amount: Double

    @Parameter(title: "Descrizione", description: "Descrizione del movimento")
    var name: String

    @Parameter(title: "Conto", description: "Quale conto hai usato?", optionsProvider: AccountOptionsProvider())
    var accountName: String?

    @Parameter(title: "Categoria", description: "Lascia vuoto per scegliere dopo aver inserito tipo e nome")
    var category: IntentCategoryChoice?

    static var parameterSummary: some ParameterSummary {
        Summary("Aggiungi \(\.$movementType) di \(\.$amount)€: \(\.$name) su \(\.$accountName) — \(\.$category)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0, !amount.isNaN, !amount.isInfinite, amount <= 1_000_000_000 else {
            throw $amount.needsValueError(IntentDialog(stringLiteral:
                String(localized: "L'importo deve essere un numero positivo (max 1 miliardo)")))
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw $name.needsValueError(IntentDialog(stringLiteral:
                String(localized: "Inserisci una descrizione per il movimento")))
        }
        guard let container = IntentContainer.shared else {
            throw NSError(
                domain: "MoneyTracker",
                code: 1,
                userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                    "Il database non è disponibile. Apri l'app per risolvere il problema.",
                    comment: ""
                )]
            )
        }
        let ctx = container.mainContext

        let chosenCategoryName: String
        if let preset = category?.id.trimmingCharacters(in: .whitespacesAndNewlines), !preset.isEmpty {
            chosenCategoryName = preset
        } else {
            let choices = IntentCategoryMenu.movementChoices(
                name: name,
                type: movementType.transactionType.rawValue,
                context: ctx
            ).map(IntentCategoryChoice.init(choice:))
            let selected = try await $category.requestDisambiguation(
                among: choices,
                dialog: IntentDialog(LocalizedStringResource("In quale categoria?"))
            )
            chosenCategoryName = selected.id
        }

        let saved = try Self.saveMovement(
            type: movementType,
            amount: amount,
            name: name,
            accountName: accountName,
            categoryName: chosenCategoryName,
            in: ctx
        )
        AccountBalanceCache.shared.invalidateAll()
        SyncService.shared.markTransactionDirty(saved.transaction.id)

        let accStr = saved.accountName.map { " su \($0)" } ?? ""
        let formatKey = movementType == .entrata ? "+%.2f %@ — salvato!" : "%.2f per %@ — salvato!"
        let msgBody = String(format: NSLocalizedString(formatKey, comment: ""), amount, name + accStr)
        let prefix = movementType == .entrata ? "💰" : "💸"
        return .result(dialog: "\(prefix) \(msgBody)")
    }

    @MainActor
    static func saveMovement(
        type: MovementKind,
        amount: Double,
        name: String,
        accountName: String?,
        categoryName: String,
        in context: ModelContext
    ) throws -> (transaction: Transaction, accountName: String?) {
        let accounts = try context.fetch(FetchDescriptor<Account>())
        let account = accounts.first { $0.name == accountName } ?? accounts.first
        let dbCats = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let trimmedCat = categoryName.trimmingCharacters(in: .whitespacesAndNewlines)
        let resolvedCat = trimmedCat.isEmpty
            ? (type == .entrata ? IntentCategoryMenu.incomeFallback(categories: dbCats.map(\.name)) : "Altro")
            : trimmedCat
        let catIcon = dbCats.first { $0.name == resolvedCat }?.icon
                   ?? DS.categoryIcon(for: resolvedCat)

        let tx = Transaction(
            name: name,
            amount: Decimal(roundedFromDouble: amount),
            type: type.transactionType,
            category: resolvedCat,
            categoryIcon: catIcon,
            date: Date(),
            isDone: true,
            notes: "",
            account: account
        )
        context.insert(tx)
        try context.save()
        return (tx, account?.name)
    }
}
