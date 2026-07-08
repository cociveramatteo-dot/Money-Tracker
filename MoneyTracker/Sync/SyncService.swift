import Foundation
import SwiftData
import Supabase
import OSLog

// MARK: - Supabase DTOs
//
// Struct Codable che rispecchiano le colonne delle tabelle Supabase (snake_case).
// Vengono costruite dai modelli SwiftData locali e decodificate dalle risposte API.

private struct SBAccount: Codable {
    let id:                   UUID
    let userId:               UUID
    let name:                 String
    let type:                 String
    let initialBalance:       Decimal
    let colorHex:             String
    let createdAt:            Date
    let isArchived:           Bool
    let isExcludedFromTotal:  Bool

    enum CodingKeys: String, CodingKey {
        case id
        case userId               = "user_id"
        case name, type
        case initialBalance       = "initial_balance"
        case colorHex             = "color_hex"
        case createdAt            = "created_at"
        case isArchived           = "is_archived"
        case isExcludedFromTotal  = "is_excluded_from_total"
    }

    init(_ a: Account, userId: UUID) {
        id                  = a.id
        self.userId         = userId
        name                = a.name
        type                = a.type
        initialBalance      = a.initialBalance
        colorHex            = a.colorHex
        createdAt           = a.createdAt
        isArchived          = a.isArchived
        isExcludedFromTotal = a.isExcludedFromTotal
    }
}

private struct SBTransaction: Codable {
    let id:                 UUID
    let userId:             UUID
    let accountId:          UUID?
    let name:               String
    let amount:             Decimal
    let type:               String
    let category:           String
    let categoryIcon:       String
    let date:               Date
    let isDone:             Bool
    let isFixed:            Bool
    let isTransfer:         Bool
    let transferGroupId:    String
    let notes:              String
    let recurringFrequency: String
    let templateId:         String
    let createdAt:          Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId           = "user_id"
        case accountId        = "account_id"
        case name, amount, type, category
        case categoryIcon     = "category_icon"
        case date
        case isDone           = "is_done"
        case isFixed          = "is_fixed"
        case isTransfer       = "is_transfer"
        case transferGroupId  = "transfer_group_id"
        case notes
        case recurringFrequency = "recurring_frequency"
        case templateId       = "template_id"
        case createdAt        = "created_at"
    }

    init(_ t: Transaction, userId: UUID) {
        id                  = t.id
        self.userId         = userId
        accountId           = t.account?.id
        name                = t.name
        amount              = t.amount
        type                = t.type
        category            = t.category
        categoryIcon        = t.categoryIcon
        date                = t.date
        isDone              = t.isDone
        isFixed             = t.isFixed
        isTransfer          = t.isTransfer
        transferGroupId     = t.transferGroupId
        notes               = t.notes
        recurringFrequency  = t.recurringFrequency
        templateId          = t.templateId
        createdAt           = t.createdAt
    }
}

private struct SBBudget: Codable {
    let id:           UUID
    let userId:       UUID
    let accountId:    UUID?
    let category:     String
    let categoryIcon: String
    let monthlyLimit: Decimal
    let month:        Int
    let year:         Int
    let createdAt:    Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId       = "user_id"
        case accountId    = "account_id"
        case category
        case categoryIcon = "category_icon"
        case monthlyLimit = "monthly_limit"
        case month, year
        case createdAt    = "created_at"
    }

    init(_ b: Budget, userId: UUID) {
        id            = b.id
        self.userId   = userId
        accountId     = b.account?.id
        category      = b.category
        categoryIcon  = b.categoryIcon
        monthlyLimit  = b.monthlyLimit
        month         = b.month
        year          = b.year
        createdAt     = b.createdAt
    }
}

private struct SBGoal: Codable {
    let id:            UUID
    let userId:        UUID
    let name:          String
    let emoji:         String
    let targetAmount:  Decimal
    let currentAmount: Decimal
    let deadline:      Date?
    let isCompleted:   Bool
    let createdAt:     Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId        = "user_id"
        case name, emoji
        case targetAmount  = "target_amount"
        case currentAmount = "current_amount"
        case deadline
        case isCompleted   = "is_completed"
        case createdAt     = "created_at"
    }

    init(_ g: Goal, userId: UUID) {
        id            = g.id
        self.userId   = userId
        name          = g.name
        emoji         = g.emoji
        targetAmount  = g.targetAmount
        currentAmount = g.currentAmount
        deadline      = g.deadline
        isCompleted   = g.isCompleted
        createdAt     = g.createdAt
    }
}

// MARK: - SyncService
//
// Responsabile della sincronizzazione bidirezionale tra SwiftData (locale)
// e le tabelle Supabase (cloud).
//
// Strategia:
//   push() — carica tutti i dati locali su Supabase (upsert + cancella gli orfani)
//   pull() — scarica tutti i dati da Supabase e aggiorna il locale
//   syncOnLogin() — al primo login usa push se Supabase è vuoto,
//                   altrimenti pull (per non sovrascrivere dati da un altro dispositivo)
//
// Il sync avviene su:
//   • Login (syncOnLogin)
//   • App va in background (push)
//   • App torna in foreground dopo ≥5 min (pull)

@MainActor
final class SyncService {

    static let shared = SyncService()
    private init() {}

    private var auth:   SupabaseManager { .shared }
    private var client: SupabaseClient  { auth.client }

    private let lastPullKey  = "syncService.lastPull"
    private let lastUserKey  = "syncService.lastUserId"
    private let pullCooldown: TimeInterval = 300   // 5 minuti

    // Task di debounce per il push real-time (annullato e ricreato ad ogni salvataggio)
    private var debounceTask: Task<Void, Never>?

    /// true se è passato abbastanza tempo dall'ultimo pull.
    var shouldPull: Bool {
        guard let last = UserDefaults.standard.object(forKey: lastPullKey) as? Date else { return true }
        return Date().timeIntervalSince(last) > pullCooldown
    }

    // MARK: - Manual refresh (pull-to-refresh)

    /// Refresh esplicito dell'utente (tirare giù per aggiornare). A differenza del pull
    /// automatico su foreground, ignora il cooldown di 5 minuti perché è un'azione
    /// intenzionale. No-op se non loggato o in modalità demo (la demo ha un container
    /// locale separato, non collegato a Supabase).
    func manualRefresh(context: ModelContext) async {
        guard auth.isLoggedIn, !UserDefaults.standard.bool(forKey: "demoModeEnabled") else { return }
        await pull(context: context)
    }

    // MARK: - Sync on login

    /// Primo sync dopo il login:
    /// • Se l'utente è diverso dall'ultimo → svuota locale prima (isolamento dati)
    /// • Se Supabase non ha dati → push (dati locali esistenti vanno sul cloud)
    /// • Se Supabase ha già dati  → pull (il cloud è la fonte di verità)
    func syncOnLogin(context: ModelContext) async {
        guard let userId = auth.session?.user.id else { return }

        // Isolamento multi-utente: se l'utente è cambiato, svuota il locale
        // (gestisce anche crash / force quit che hanno saltato il logout)
        let lastUserId = UserDefaults.standard.string(forKey: lastUserKey)
        if lastUserId != userId.uuidString {
            clearLocalData(context: context)
        }
        UserDefaults.standard.set(userId.uuidString, forKey: lastUserKey)

        do {
            let remoteIds = try await fetchIds(table: "mt_accounts", userId: userId)
            if remoteIds.isEmpty {
                // Nuovo utente o primo dispositivo: porta i dati locali su Supabase
                await push(context: context)
            } else {
                // Dati già presenti: scarica dal cloud
                await pull(context: context)
            }
        } catch {
            // Fallback: prova comunque a fare push
            await push(context: context)
        }
    }

    // MARK: - Real-time push (debounced)

    /// Schedula un push con debounce di 1.5 secondi.
    /// Chiamato automaticamente ad ogni salvataggio del ModelContext.
    /// Se arrivano più salvataggi ravvicinati, parte un solo push.
    func schedulePush(context: ModelContext) {
        guard auth.isLoggedIn else { return }
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            await push(context: context)
        }
    }

    // MARK: - Clear local data (on logout)

    /// Cancella tutti i dati locali reali (NON demo).
    /// Chiamato al logout per garantire che il prossimo utente
    /// non veda i dati del precedente.
    func clearLocalData(context: ModelContext) {
        // Ordine importante: prima le dipendenze, poi gli account (cascade)
        try? context.delete(model: Transaction.self)
        try? context.delete(model: Budget.self)
        try? context.delete(model: Goal.self)
        try? context.delete(model: Account.self)
        context.safeSave()
        UserDefaults.standard.removeObject(forKey: lastPullKey)
    }

    // MARK: - Push (SwiftData → Supabase)

    func push(context: ModelContext) async {
        guard let userId = auth.session?.user.id else { return }
        Logger.persistence.info("SyncService: push started")

        do {
            let accounts     = (try? context.fetch(FetchDescriptor<Account>()))     ?? []
            let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
            let budgets      = (try? context.fetch(FetchDescriptor<Budget>()))      ?? []
            let goals        = (try? context.fetch(FetchDescriptor<Goal>()))        ?? []

            // Accounts
            if !accounts.isEmpty {
                let sb = accounts.map { SBAccount($0, userId: userId) }
                try await client.from("mt_accounts").upsert(sb).execute()
            }
            try await deleteOrphans(table: "mt_accounts",
                                    userId: userId,
                                    localIds: Set(accounts.map { $0.id }))

            // Transactions
            if !transactions.isEmpty {
                let sb = transactions.map { SBTransaction($0, userId: userId) }
                try await client.from("mt_transactions").upsert(sb).execute()
            }
            try await deleteOrphans(table: "mt_transactions",
                                    userId: userId,
                                    localIds: Set(transactions.map { $0.id }))

            // Budgets
            if !budgets.isEmpty {
                let sb = budgets.map { SBBudget($0, userId: userId) }
                try await client.from("mt_budgets").upsert(sb).execute()
            }
            try await deleteOrphans(table: "mt_budgets",
                                    userId: userId,
                                    localIds: Set(budgets.map { $0.id }))

            // Goals
            if !goals.isEmpty {
                let sb = goals.map { SBGoal($0, userId: userId) }
                try await client.from("mt_goals").upsert(sb).execute()
            }
            try await deleteOrphans(table: "mt_goals",
                                    userId: userId,
                                    localIds: Set(goals.map { $0.id }))

            Logger.persistence.info("SyncService: push complete")
        } catch {
            Logger.persistence.error("SyncService push error: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Pull (Supabase → SwiftData)

    func pull(context: ModelContext) async {
        guard let userId = auth.session?.user.id else { return }
        Logger.persistence.info("SyncService: pull started")

        do {
            // ── 1. ACCOUNTS ────────────────────────────────────────────────
            let sbAccounts: [SBAccount] = try await client.from("mt_accounts")
                .select().eq("user_id", value: userId.uuidString).execute().value

            // Guard: se Supabase è vuoto ma il locale ha dati, interrompi.
            // Significa che il push precedente non è ancora avvenuto — non cancellare
            // dati locali validi che l'utente ha appena inserito.
            let localAccountCount = (try? context.fetchCount(FetchDescriptor<Account>())) ?? 0
            if sbAccounts.isEmpty && localAccountCount > 0 {
                Logger.persistence.warning("SyncService: pull skipped — remote empty, local has data")
                return
            }

            let localAccounts    = (try? context.fetch(FetchDescriptor<Account>())) ?? []
            let localAccountById = Dictionary(localAccounts.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var accountMap       = [UUID: Account]()
            var pulledAccountIds = Set<UUID>()

            for sb in sbAccounts {
                pulledAccountIds.insert(sb.id)
                let acc: Account
                if let existing = localAccountById[sb.id] {
                    if existing.name                != sb.name                { existing.name                = sb.name }
                    if existing.type                != sb.type                { existing.type                = sb.type }
                    if existing.initialBalance      != sb.initialBalance      { existing.initialBalance      = sb.initialBalance }
                    if existing.colorHex            != sb.colorHex            { existing.colorHex            = sb.colorHex }
                    if existing.isArchived          != sb.isArchived          { existing.isArchived          = sb.isArchived }
                    if existing.isExcludedFromTotal != sb.isExcludedFromTotal { existing.isExcludedFromTotal = sb.isExcludedFromTotal }
                    acc = existing
                } else {
                    let a = Account(name: sb.name,
                                    type: AccountType(rawValue: sb.type) ?? .conto,
                                    initialBalance: sb.initialBalance,
                                    colorHex: sb.colorHex,
                                    isExcludedFromTotal: sb.isExcludedFromTotal)
                    a.id        = sb.id
                    a.createdAt = sb.createdAt
                    a.isArchived = sb.isArchived
                    context.insert(a)
                    acc = a
                }
                accountMap[sb.id] = acc
            }
            // Cancella account locali non presenti su Supabase
            for local in localAccounts where !pulledAccountIds.contains(local.id) {
                context.delete(local)   // cascade elimina anche le sue transaction/budget
            }

            // ── 2. TRANSACTIONS ────────────────────────────────────────────
            let sbTx: [SBTransaction] = try await client.from("mt_transactions")
                .select().eq("user_id", value: userId.uuidString).execute().value

            let localTx    = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
            let localTxMap = Dictionary(localTx.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var pulledTxIds = Set<UUID>()

            for sb in sbTx {
                pulledTxIds.insert(sb.id)
                if let existing = localTxMap[sb.id] {
                    if existing.name               != sb.name               { existing.name               = sb.name }
                    if existing.amount             != sb.amount             { existing.amount             = sb.amount }
                    if existing.type               != sb.type               { existing.type               = sb.type }
                    if existing.category           != sb.category           { existing.category           = sb.category }
                    if existing.categoryIcon       != sb.categoryIcon       { existing.categoryIcon       = sb.categoryIcon }
                    if existing.date               != sb.date               { existing.date               = sb.date }
                    if existing.isDone             != sb.isDone             { existing.isDone             = sb.isDone }
                    if existing.isFixed            != sb.isFixed            { existing.isFixed            = sb.isFixed }
                    if existing.isTransfer         != sb.isTransfer         { existing.isTransfer         = sb.isTransfer }
                    if existing.transferGroupId    != sb.transferGroupId    { existing.transferGroupId    = sb.transferGroupId }
                    if existing.notes              != sb.notes              { existing.notes              = sb.notes }
                    if existing.recurringFrequency != sb.recurringFrequency { existing.recurringFrequency = sb.recurringFrequency }
                    if existing.templateId         != sb.templateId         { existing.templateId         = sb.templateId }
                    if let accId = sb.accountId, existing.account?.id != accId { existing.account = accountMap[accId] }
                } else {
                    let t = Transaction(
                        name:               sb.name,
                        amount:             sb.amount,
                        type:               TransactionType(rawValue: sb.type) ?? .uscita,
                        category:           sb.category,
                        categoryIcon:       sb.categoryIcon,
                        date:               sb.date,
                        isDone:             sb.isDone,
                        isFixed:            sb.isFixed,
                        isTransfer:         sb.isTransfer,
                        transferGroupId:    sb.transferGroupId,
                        notes:              sb.notes,
                        recurringFrequency: sb.recurringFrequency,
                        templateId:         sb.templateId,
                        account:            sb.accountId.flatMap { accountMap[$0] }
                    )
                    t.id        = sb.id
                    t.createdAt = sb.createdAt
                    context.insert(t)
                }
            }
            for local in localTx where !pulledTxIds.contains(local.id) {
                context.delete(local)
            }

            // ── 3. BUDGETS ─────────────────────────────────────────────────
            let sbBudgets: [SBBudget] = try await client.from("mt_budgets")
                .select().eq("user_id", value: userId.uuidString).execute().value

            let localBudgets    = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
            let localBudgetMap  = Dictionary(localBudgets.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var pulledBudgetIds = Set<UUID>()

            for sb in sbBudgets {
                pulledBudgetIds.insert(sb.id)
                if let existing = localBudgetMap[sb.id] {
                    if existing.category     != sb.category     { existing.category     = sb.category }
                    if existing.categoryIcon != sb.categoryIcon { existing.categoryIcon = sb.categoryIcon }
                    if existing.monthlyLimit != sb.monthlyLimit { existing.monthlyLimit = sb.monthlyLimit }
                    if existing.month        != sb.month        { existing.month        = sb.month }
                    if existing.year         != sb.year         { existing.year         = sb.year }
                    if let accId = sb.accountId, existing.account?.id != accId { existing.account = accountMap[accId] }
                } else {
                    let b = Budget(category: sb.category,
                                   categoryIcon: sb.categoryIcon,
                                   monthlyLimit: sb.monthlyLimit,
                                   month: sb.month,
                                   year: sb.year,
                                   account: sb.accountId.flatMap { accountMap[$0] })
                    b.id        = sb.id
                    b.createdAt = sb.createdAt
                    context.insert(b)
                }
            }
            for local in localBudgets where !pulledBudgetIds.contains(local.id) {
                context.delete(local)
            }

            // ── 4. GOALS ───────────────────────────────────────────────────
            let sbGoals: [SBGoal] = try await client.from("mt_goals")
                .select().eq("user_id", value: userId.uuidString).execute().value

            let localGoals    = (try? context.fetch(FetchDescriptor<Goal>())) ?? []
            let localGoalMap  = Dictionary(localGoals.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var pulledGoalIds = Set<UUID>()

            for sb in sbGoals {
                pulledGoalIds.insert(sb.id)
                if let existing = localGoalMap[sb.id] {
                    if existing.name          != sb.name          { existing.name          = sb.name }
                    if existing.emoji         != sb.emoji         { existing.emoji         = sb.emoji }
                    if existing.targetAmount  != sb.targetAmount  { existing.targetAmount  = sb.targetAmount }
                    if existing.currentAmount != sb.currentAmount { existing.currentAmount = sb.currentAmount }
                    if existing.deadline      != sb.deadline      { existing.deadline      = sb.deadline }
                    if existing.isCompleted   != sb.isCompleted   { existing.isCompleted   = sb.isCompleted }
                } else {
                    let g = Goal(name: sb.name,
                                 targetAmount: sb.targetAmount,
                                 currentAmount: sb.currentAmount,
                                 emoji: sb.emoji,
                                 deadline: sb.deadline)
                    g.id          = sb.id
                    g.createdAt   = sb.createdAt
                    g.isCompleted = sb.isCompleted
                    context.insert(g)
                }
            }
            for local in localGoals where !pulledGoalIds.contains(local.id) {
                context.delete(local)
            }

            context.safeSave()
            UserDefaults.standard.set(Date(), forKey: lastPullKey)
            Logger.persistence.info("SyncService: pull complete")

        } catch {
            Logger.persistence.error("SyncService pull error: \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Helpers

    /// Recupera gli UUID di tutti i record di un utente in una tabella.
    private func fetchIds(table: String, userId: UUID) async throws -> Set<UUID> {
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = try await client.from(table)
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return Set(rows.map { $0.id })
    }

    /// Elimina da Supabase i record che esistono in remoto ma non localmente.
    private func deleteOrphans(table: String, userId: UUID, localIds: Set<UUID>) async throws {
        let remoteIds = try await fetchIds(table: table, userId: userId)
        let orphans   = remoteIds.subtracting(localIds)
        for id in orphans {
            try await client.from(table)
                .delete()
                .eq("id", value: id.uuidString)
                .execute()
        }
    }
}
