import AppIntents
import SwiftData
import Foundation

// MARK: - Shared ModelContainer helper
//
// Singleton: AppIntents run in a separate process; creating a new ModelContainer
// per intent call is wasteful and risks write conflicts. This static container is
// created once for the lifetime of the extension process.
// SEC-01: replaced try! with try? so a corrupted/migrating store surfaces as a
// user-visible error dialog instead of a hard crash in the Shortcuts extension.

private enum IntentContainer {
    static let shared: ModelContainer? = {
        // Stesso schema versionato dell'app principale (Domain/SchemaMigration.swift):
        // l'extension Shortcuts apre lo stesso store e deve poter applicare la stessa
        // migrazione Double→Decimal se non è già stata eseguita dall'app host.
        let schema = Schema(versionedSchema: SchemaV2.self)
        let config = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)
        return try? ModelContainer(for: schema, migrationPlan: MoneyTrackerMigrationPlan.self, configurations: config)
    }()
}

// MARK: - Quick Add Expense Intent

struct AddExpenseIntent: AppIntent {
    static let title: LocalizedStringResource = "Aggiungi spesa"
    static let description = IntentDescription("Aggiunge rapidamente una spesa al Money Tracker")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Nome", description: "Cosa hai comprato?")
    var name: String

    @Parameter(title: "Importo", description: "Quanto hai speso?")
    var amount: Double

    @Parameter(title: "Conto", description: "Quale conto hai usato?", optionsProvider: AccountOptionsProvider())
    var accountName: String?

    // categoryName: optional, shown in parameterSummary so the user can pre-set it
    // in the Shortcuts editor. In perform(), CategoryClassifier runs first; the
    // explicit category overrides only when provided AND the classifier has no match.
    @Parameter(title: "Categoria", description: "Lascia vuoto per auto-detect", optionsProvider: CategoryOptionsProvider())
    var categoryName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Aggiungi \(\.$amount)€ per \(\.$name) su \(\.$accountName) — \(\.$categoryName)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0, !amount.isNaN, !amount.isInfinite, amount <= 1_000_000_000 else {
            throw $amount.needsValueError(IntentDialog(stringLiteral:
                String(localized: "L'importo deve essere un numero positivo (max 1 miliardo)")))
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw $name.needsValueError(IntentDialog(stringLiteral:
                String(localized: "Inserisci una descrizione per la spesa")))
        }
        // SEC-01: guard against store initialisation failure
        guard let container = IntentContainer.shared else {
            throw NSError(domain: "MoneyTracker", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                              "Il database non è disponibile. Apri l'app per risolvere il problema.", comment: "")])
        }
        let ctx = container.mainContext

        let accounts = try ctx.fetch(FetchDescriptor<Account>())
        let account  = accounts.first { $0.name == accountName } ?? accounts.first

        // ── Smart category logic ──
        // 1. Classifier has priority when it finds a specific match (not "Altro")
        // 2. Explicit user-provided category overrides the "Altro" fallback
        // 3. If neither matches, default to "Altro" — never block with a throw
        let detected = KeywordCategoryClassifier.shared.classify(name)
        let catName: String
        if detected != "Altro" && !detected.isEmpty {
            catName = detected
        } else if let provided = categoryName, !provided.isEmpty {
            catName = provided
        } else {
            catName = "Altro"
        }

        let dbCats  = try ctx.fetch(FetchDescriptor<Category>())
        let catIcon = dbCats.first { $0.name == catName }?.icon
                   ?? DS.categoryIcon(for: catName)

        let tx = Transaction(
            name:         name,
            amount:       Decimal(roundedFromDouble: amount),
            type:         .uscita,
            category:     catName,
            categoryIcon: catIcon,
            date:         Date(),
            isDone:       true,
            notes:        "",
            account:      account
        )
        ctx.insert(tx)
        try ctx.save()
        AccountBalanceCache.shared.invalidateAll()   // PERF-04: fuori dal choke point di safeSave(), va invalidata a mano
        // Girando in un processo separato, questo save() non genera la notifica
        // osservata da recordChanges() nel processo principale — va marcata a mano,
        // altrimenti il prossimo pull la considera orfana e la cancella (vedi SyncService).
        SyncService.shared.markTransactionDirty(tx.id)

        let accStr  = account.map { " su \($0.name)" } ?? ""
        let msgBody = String(format: NSLocalizedString("%.2f per %@ — salvato!", comment: ""), amount, name + accStr)
        return .result(dialog: "💸 \(msgBody)")
    }
}

// MARK: - Quick Add Income Intent

struct AddIncomeIntent: AppIntent {
    static let title: LocalizedStringResource = "Aggiungi entrata"
    static let description = IntentDescription("Aggiunge rapidamente un'entrata al Money Tracker")
    static let openAppWhenRun: Bool = false

    @Parameter(title: "Nome", description: "Descrizione entrata")
    var name: String

    @Parameter(title: "Importo", description: "Quanto hai ricevuto?")
    var amount: Double

    @Parameter(title: "Conto", description: "Su quale conto?", optionsProvider: AccountOptionsProvider())
    var accountName: String?

    static var parameterSummary: some ParameterSummary {
        Summary("Aggiungi entrata di \(\.$amount)€: \(\.$name)")
    }

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard amount > 0, !amount.isNaN, !amount.isInfinite, amount <= 1_000_000_000 else {
            throw $amount.needsValueError(IntentDialog(stringLiteral:
                String(localized: "L'importo deve essere un numero positivo (max 1 miliardo)")))
        }
        guard !name.trimmingCharacters(in: .whitespaces).isEmpty else {
            throw $name.needsValueError(IntentDialog(stringLiteral:
                String(localized: "Inserisci una descrizione per l'entrata")))
        }
        guard let container = IntentContainer.shared else {
            throw NSError(domain: "MoneyTracker", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                              "Il database non è disponibile. Apri l'app per risolvere il problema.", comment: "")])
        }
        let ctx = container.mainContext

        let accounts = try ctx.fetch(FetchDescriptor<Account>())
        let account  = accounts.first { $0.name == accountName } ?? accounts.first

        let categories = (try? ctx.fetch(FetchDescriptor<Category>())) ?? []
        let suggestedName = KeywordCategoryClassifier.shared.classify(name)
        let incCatName: String
        if suggestedName != "Altro" && !suggestedName.isEmpty {
            incCatName = suggestedName
        } else {
            incCatName = categories.first { $0.name == "Lavoro" }?.name
                      ?? categories.first?.name
                      ?? "Lavoro"
        }
        let incCatIcon = categories.first { $0.name == incCatName }?.icon
                      ?? DS.categoryIcon(for: incCatName)
        let tx = Transaction(
            name:         name,
            amount:       Decimal(roundedFromDouble: amount),
            type:         .entrata,
            category:     incCatName,
            categoryIcon: incCatIcon,
            date:         Date(),
            isDone:       true,
            notes:        "",
            account:      account
        )
        ctx.insert(tx)
        try ctx.save()
        AccountBalanceCache.shared.invalidateAll()   // PERF-04: fuori dal choke point di safeSave(), va invalidata a mano
        // Vedi commento in AddExpenseIntent: senza questa marcatura esplicita, il
        // prossimo pull tratterebbe questa transazione come cancellata altrove.
        SyncService.shared.markTransactionDirty(tx.id)

        let accStr  = account.map { " su \($0.name)" } ?? ""
        let incBody = String(format: NSLocalizedString("+%.2f %@ — salvato!", comment: ""), amount, name + accStr)
        return .result(dialog: "💰 \(incBody)")
    }
}

// MARK: - Balance Check Intent

struct CheckBalanceIntent: AppIntent {
    static let title: LocalizedStringResource = "Controlla saldo"
    static let description = IntentDescription("Mostra il saldo attuale di tutti i conti")
    static let openAppWhenRun: Bool = false
    // SEC-04: IntentAuthenticationPolicy.requiresLocalAuthentication rimosso in iOS 26 SDK.
    // Protezione biometrica da re-implementare quando l'API stabile sarà documentata.

    @MainActor
    func perform() async throws -> some IntentResult & ProvidesDialog {
        guard let container = IntentContainer.shared else {
            throw NSError(domain: "MoneyTracker", code: 1,
                          userInfo: [NSLocalizedDescriptionKey: NSLocalizedString(
                              "Il database non è disponibile. Apri l'app per risolvere il problema.", comment: "")])
        }
        let ctx = container.mainContext

        let accounts = try ctx.fetch(
            FetchDescriptor<Account>(predicate: #Predicate { !$0.isArchived })
        )
        if accounts.isEmpty {
            let msg = NSLocalizedString("Nessun conto trovato. Apri l'app per aggiungerne uno.", comment: "")
            return .result(dialog: "\(msg)")
        }

        let included = accounts.filter { !$0.isExcludedFromTotal }
        let total    = included.reduce(Decimal(0)) { $0 + $1.currentBalance }
        let header   = String(format: NSLocalizedString("💰 Saldo totale: %@", comment: ""), total.currencyFormatted)
        var lines    = header + "\n"
        for acc in accounts {
            lines += "\(acc.emoji) \(acc.name): \(acc.currentBalance.currencyFormatted)\n"
        }
        return .result(dialog: IntentDialog(stringLiteral: lines))
    }
}

// MARK: - Account Options Provider

struct AccountOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        guard let container = IntentContainer.shared else { return [] }
        let ctx = container.mainContext
        let accounts = try ctx.fetch(
            FetchDescriptor<Account>(predicate: #Predicate { !$0.isArchived })
        )
        return accounts.map { $0.name }
    }
}

// MARK: - Category Options Provider

struct CategoryOptionsProvider: DynamicOptionsProvider {
    func results() async throws -> [String] {
        guard let container = IntentContainer.shared else { return [] }
        let ctx = container.mainContext
        let dbCats = (try? ctx.fetch(FetchDescriptor<Category>())) ?? []
        let defaults = ["Cibo", "Trasporti", "Svago", "Shopping", "Salute",
                        "Casa", "Abbonamenti", "Lavoro", "Istruzione", "Viaggi", "Regali", "Altro"]
        let custom = dbCats.map { $0.name }
        // Custom categories first, then any built-in not already present
        return custom + defaults.filter { !custom.contains($0) }
    }
}

// MARK: - App Shortcuts

struct MoneyTrackerShortcuts: AppShortcutsProvider {
    static var appShortcuts: [AppShortcut] {
        AppShortcut(
            intent: AddExpenseIntent(),
            phrases: [
                "Aggiungi spesa su \(.applicationName)",
                "Nuova spesa \(.applicationName)",
                "Ho speso con \(.applicationName)"
            ],
            shortTitle: "Aggiungi spesa",
            systemImageName: "minus.circle.fill"
        )
        AppShortcut(
            intent: AddIncomeIntent(),
            phrases: [
                "Aggiungi entrata su \(.applicationName)",
                "Ho ricevuto soldi con \(.applicationName)"
            ],
            shortTitle: "Aggiungi entrata",
            systemImageName: "plus.circle.fill"
        )
        AppShortcut(
            intent: CheckBalanceIntent(),
            phrases: [
                "Controlla saldo \(.applicationName)",
                "Quanto ho su \(.applicationName)"
            ],
            shortTitle: "Saldo conti",
            systemImageName: "creditcard.fill"
        )
    }
}
