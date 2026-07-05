import Foundation
import SwiftData

// MARK: - Schema versioning (Double → Decimal migration)
//
// L'app è sempre stata distribuita con importi monetari in `Double` (nessuno
// schema versionato prima d'ora). Per convertire in modo lossless gli store già
// installati sui dispositivi degli utenti, SwiftData ha bisogno di due cose:
//   1. Uno snapshot congelato della forma con cui il DB esiste oggi su disco (SchemaV1).
//   2. Un piano di migrazione custom che sappia trasformare quei valori Double nei
//      Decimal della SchemaV2 (i modelli live in Models.swift).
//
// SchemaV1 NON va mai modificato: è un fossile, serve solo a far riconoscere a
// SwiftData lo store esistente e a poterne leggere i vecchi valori Double durante
// la migrazione. `Category` non cambia tra le due versioni (nessun campo monetario)
// quindi è condivisa: non serve una copia in SchemaV1.

enum SchemaV1: VersionedSchema {
    static let versionIdentifier = Schema.Version(1, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Account.self, Transaction.self, Budget.self, Goal.self, Category.self]
    }

    @Model
    final class Account {
        var id: UUID
        var name: String
        var type: String
        var initialBalance: Double
        var colorHex: String
        var createdAt: Date
        var isArchived: Bool
        var isExcludedFromTotal: Bool

        @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
        var transactions: [Transaction]

        @Relationship(deleteRule: .cascade, inverse: \Budget.account)
        var budgets: [Budget]

        init(name: String, type: String, initialBalance: Double, colorHex: String,
             isArchived: Bool, isExcludedFromTotal: Bool) {
            self.id                  = UUID()
            self.name                = name
            self.type                = type
            self.initialBalance      = initialBalance
            self.colorHex            = colorHex
            self.createdAt           = Date()
            self.isArchived          = isArchived
            self.isExcludedFromTotal = isExcludedFromTotal
            self.transactions        = []
            self.budgets             = []
        }
    }

    @Model
    final class Transaction {
        var id: UUID
        var name: String
        var amount: Double
        var type: String
        var category: String
        var categoryIcon: String
        var date: Date
        var isDone: Bool
        var isFixed: Bool
        var isTransfer: Bool
        var transferGroupId: String
        var notes: String
        var recurringFrequency: String
        var templateId: String
        var createdAt: Date

        var account: Account?

        init(name: String, amount: Double, type: String, category: String, categoryIcon: String,
             date: Date, isDone: Bool, isFixed: Bool, isTransfer: Bool, transferGroupId: String,
             notes: String, recurringFrequency: String, templateId: String, account: Account?) {
            self.id                 = UUID()
            self.name               = name
            self.amount             = amount
            self.type               = type
            self.category           = category
            self.categoryIcon       = categoryIcon
            self.date               = date
            self.isDone             = isDone
            self.isFixed            = isFixed
            self.isTransfer         = isTransfer
            self.transferGroupId    = transferGroupId
            self.notes              = notes
            self.recurringFrequency = recurringFrequency
            self.templateId         = templateId
            self.createdAt          = Date()
            self.account            = account
        }
    }

    @Model
    final class Budget {
        var id: UUID
        var category: String
        var categoryIcon: String
        var monthlyLimit: Double
        var month: Int
        var year: Int
        var createdAt: Date

        @Relationship(deleteRule: .nullify)
        var account: Account?

        init(category: String, categoryIcon: String, monthlyLimit: Double, month: Int, year: Int, account: Account?) {
            self.id           = UUID()
            self.category     = category
            self.categoryIcon = categoryIcon
            self.monthlyLimit = monthlyLimit
            self.month        = month
            self.year         = year
            self.createdAt    = Date()
            self.account      = account
        }
    }

    @Model
    final class Goal {
        var id: UUID
        var name: String
        var emoji: String
        var targetAmount: Double
        var currentAmount: Double
        var deadline: Date?
        var isCompleted: Bool
        var createdAt: Date

        init(name: String, targetAmount: Double, currentAmount: Double, emoji: String, deadline: Date?) {
            self.id            = UUID()
            self.name          = name
            self.emoji         = emoji
            self.targetAmount  = targetAmount
            self.currentAmount = currentAmount
            self.deadline      = deadline
            self.isCompleted   = false
            self.createdAt     = Date()
        }
    }
}

// MARK: - Schema V2 (attuale — importi in Decimal)
//
// Nessun tipo da ridichiarare: SchemaV2 punta semplicemente ai modelli live
// definiti in Models.swift (Account/Transaction/Budget/Goal/Category con Decimal).

enum SchemaV2: VersionedSchema {
    static let versionIdentifier = Schema.Version(2, 0, 0)

    static var models: [any PersistentModel.Type] {
        [Account.self, Transaction.self, Budget.self, Goal.self, Category.self]
    }
}

// MARK: - Migration plan

enum MoneyTrackerMigrationPlan: SchemaMigrationPlan {
    static var schemas: [any VersionedSchema.Type] {
        [SchemaV1.self, SchemaV2.self]
    }

    static var stages: [MigrationStage] {
        [migrateV1toV2]
    }

    // Buffer temporaneo: `willMigrate` legge i Double dalla SchemaV1 (prima che la
    // colonna cambi tipo) e li tiene da parte per `didMigrate`, che li riscrive come
    // Decimal sui modelli live una volta completata la migrazione strutturale.
    // Conversione Decimal(Double) — non "inventa" precisione che i vecchi valori
    // Double non avevano già, ma da qui in avanti non se ne perde altra.
    private static let migrateV1toV2 = MigrationStage.custom(
        fromVersion: SchemaV1.self,
        toVersion: SchemaV2.self,
        willMigrate: { context in
            let accounts = (try? context.fetch(FetchDescriptor<SchemaV1.Account>())) ?? []
            for a in accounts {
                DecimalMigrationBuffer.shared.stashAccountInitialBalance(id: a.id, value: a.initialBalance)
            }
            let transactions = (try? context.fetch(FetchDescriptor<SchemaV1.Transaction>())) ?? []
            for t in transactions {
                DecimalMigrationBuffer.shared.stashTransactionAmount(id: t.id, value: t.amount)
            }
            let budgets = (try? context.fetch(FetchDescriptor<SchemaV1.Budget>())) ?? []
            for b in budgets {
                DecimalMigrationBuffer.shared.stashBudgetMonthlyLimit(id: b.id, value: b.monthlyLimit)
            }
            let goals = (try? context.fetch(FetchDescriptor<SchemaV1.Goal>())) ?? []
            for g in goals {
                DecimalMigrationBuffer.shared.stashGoalAmounts(id: g.id, target: g.targetAmount, current: g.currentAmount)
            }
            try? context.save()
        },
        didMigrate: { context in
            let accounts = (try? context.fetch(FetchDescriptor<Account>())) ?? []
            for a in accounts {
                if let old = DecimalMigrationBuffer.shared.accountInitialBalance(id: a.id) {
                    a.initialBalance = Decimal(old)
                }
            }
            let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
            for t in transactions {
                if let old = DecimalMigrationBuffer.shared.transactionAmount(id: t.id) {
                    t.amount = Decimal(old)
                }
            }
            let budgets = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
            for b in budgets {
                if let old = DecimalMigrationBuffer.shared.budgetMonthlyLimit(id: b.id) {
                    b.monthlyLimit = Decimal(old)
                }
            }
            let goals = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
            for g in goals {
                if let old = DecimalMigrationBuffer.shared.goalAmounts(id: g.id) {
                    g.targetAmount  = Decimal(old.target)
                    g.currentAmount = Decimal(old.current)
                }
            }
            try? context.save()
            DecimalMigrationBuffer.shared.clear()
        }
    )
}

/// Buffer thread-safe usato solo durante la migrazione V1→V2: vive per la durata della
/// singola custom stage, non è mai esposto fuori da SchemaMigration.swift.
private final class DecimalMigrationBuffer: @unchecked Sendable {
    static let shared = DecimalMigrationBuffer()
    private init() {}

    private let lock = NSLock()
    private var accountInitialBalances: [UUID: Double] = [:]
    private var transactionAmounts:     [UUID: Double] = [:]
    private var budgetMonthlyLimits:    [UUID: Double] = [:]
    private var goalAmountPairs:        [UUID: (target: Double, current: Double)] = [:]

    func stashAccountInitialBalance(id: UUID, value: Double) {
        lock.lock(); accountInitialBalances[id] = value; lock.unlock()
    }
    func stashTransactionAmount(id: UUID, value: Double) {
        lock.lock(); transactionAmounts[id] = value; lock.unlock()
    }
    func stashBudgetMonthlyLimit(id: UUID, value: Double) {
        lock.lock(); budgetMonthlyLimits[id] = value; lock.unlock()
    }
    func stashGoalAmounts(id: UUID, target: Double, current: Double) {
        lock.lock(); goalAmountPairs[id] = (target, current); lock.unlock()
    }

    func accountInitialBalance(id: UUID) -> Double? {
        lock.lock(); defer { lock.unlock() }; return accountInitialBalances[id]
    }
    func transactionAmount(id: UUID) -> Double? {
        lock.lock(); defer { lock.unlock() }; return transactionAmounts[id]
    }
    func budgetMonthlyLimit(id: UUID) -> Double? {
        lock.lock(); defer { lock.unlock() }; return budgetMonthlyLimits[id]
    }
    func goalAmounts(id: UUID) -> (target: Double, current: Double)? {
        lock.lock(); defer { lock.unlock() }; return goalAmountPairs[id]
    }

    func clear() {
        lock.lock()
        accountInitialBalances.removeAll()
        transactionAmounts.removeAll()
        budgetMonthlyLimits.removeAll()
        goalAmountPairs.removeAll()
        lock.unlock()
    }
}
