import Foundation
import SwiftData
import Supabase
import OSLog
import Network
import Combine

// MARK: - Supabase DTOs
//
// Struct Codable che rispecchiano le colonne delle tabelle Supabase (snake_case).
// Vengono costruite dai modelli SwiftData locali e decodificate dalle risposte API.

struct SBRecurringRule: @MainActor SyncRow {
    let id: UUID
    let userId: UUID
    let name: String
    let type: String
    let category: String
    let categoryIcon: String
    let notes: String
    let amount: Decimal
    let isFixed: Bool
    let accountId: UUID?
    let frequency: String
    let startDate: Date
    let endDate: Date?
    let exceptionsJSON: String
    let materializedThrough: Date?
    let createdAt: Date

    enum CodingKeys: String, CodingKey {
        case id
        case userId = "user_id"
        case name
        case type
        case category
        case categoryIcon = "category_icon"
        case notes
        case amount
        case isFixed = "is_fixed"
        case accountId = "account_id"
        case frequency
        case startDate = "start_date"
        case endDate = "end_date"
        case exceptionsJSON = "exceptions"
        case materializedThrough = "materialized_through"
        case createdAt = "created_at"
    }

    init(_ rule: RecurringRule, userId: UUID) {
        self.id = rule.id
        self.userId = userId
        self.name = rule.name
        self.type = rule.type
        self.category = rule.category
        self.categoryIcon = rule.categoryIcon
        self.notes = rule.notes
        self.amount = rule.amount
        self.isFixed = rule.isFixed
        self.accountId = rule.accountId
        self.frequency = rule.frequency
        self.startDate = rule.startDate
        self.endDate = rule.endDate
        self.exceptionsJSON = rule.exceptionsJSON
        self.materializedThrough = rule.materializedThrough
        self.createdAt = rule.createdAt
    }

    // Encode nil as SQL NULL too: an edit can clear an account, end date or cursor.
    func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(id, forKey: .id)
        try container.encode(userId, forKey: .userId)
        try container.encode(name, forKey: .name)
        try container.encode(type, forKey: .type)
        try container.encode(category, forKey: .category)
        try container.encode(categoryIcon, forKey: .categoryIcon)
        try container.encode(notes, forKey: .notes)
        try container.encode(amount, forKey: .amount)
        try container.encode(isFixed, forKey: .isFixed)
        try container.encode(accountId, forKey: .accountId)
        try container.encode(frequency, forKey: .frequency)
        try container.encode(startDate, forKey: .startDate)
        try container.encode(endDate, forKey: .endDate)
        try container.encode(exceptionsJSON, forKey: .exceptionsJSON)
        try container.encode(materializedThrough, forKey: .materializedThrough)
        try container.encode(createdAt, forKey: .createdAt)
    }

    /// Remote fields win, except the materialization cursor which must never go backwards.
    func apply(to rule: RecurringRule) {
        if rule.name != name { rule.name = name }
        if rule.type != type { rule.type = type }
        if rule.category != category { rule.category = category }
        if rule.categoryIcon != categoryIcon { rule.categoryIcon = categoryIcon }
        if rule.notes != notes { rule.notes = notes }
        if rule.amount != amount { rule.amount = amount }
        if rule.isFixed != isFixed { rule.isFixed = isFixed }
        if rule.accountId != accountId { rule.accountId = accountId }
        if rule.frequency != frequency { rule.frequency = frequency }
        if rule.startDate != startDate { rule.startDate = startDate }
        if rule.endDate != endDate { rule.endDate = endDate }
        if rule.exceptionsJSON != exceptionsJSON { rule.exceptionsJSON = exceptionsJSON }
        if rule.createdAt != createdAt { rule.createdAt = createdAt }
        let watermark = [rule.materializedThrough, materializedThrough].compactMap { $0 }.max()
        if rule.materializedThrough != watermark { rule.materializedThrough = watermark }
    }
}

struct SBAccount: @MainActor SyncRow {
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

struct SBTransaction: @MainActor SyncRow {
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

struct SBBudget: @MainActor SyncRow {
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

struct SBGoal: @MainActor SyncRow {
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

// MARK: - SyncStatus
//
// Stato pubblico e osservabile del sync, pensato per essere mostrato in UI come un
// piccolo indicatore silenzioso ("Sincronizzazione…") — mai un alert, mai un errore
// bloccante. Un fallimento di rete è normale amministrazione, non un'emergenza da
// mostrare all'utente: viene assorbito qui e ritentato automaticamente.
enum SyncStatus: Equatable {
    case idle
    case syncing
    /// In attesa del prossimo tentativo automatico (circuit breaker con backoff).
    case waitingForRetry(attempt: Int)
    case offline
}

@MainActor
final class SyncService: ObservableObject {

    static let shared = SyncService()

    private let injectedRemote: (any SyncRemote)?
    private let injectedUserId: UUID?
    private let defaults: UserDefaults
    private let clearAuditLog: @MainActor () -> Void
    private let e2eEnabled: Bool
    private let e2eKeyStore = E2EKeyStore()
    private var e2eBackupDirectory = E2EMigrator.backupDirectory
    @Published private(set) var isMigrating = false

    private init() {
        injectedRemote = nil
        injectedUserId = nil
        defaults = .standard
        clearAuditLog = { AuditLogger.shared.clearAll() }
        e2eEnabled = E2EFeature.isEnabled
        startNetworkMonitoring()
    }

    /// Isolated service for tests, with no network monitor or live app state.
    init(remote: any SyncRemote, userId: UUID, defaults: UserDefaults,
         e2eLaunchArguments: [String]? = nil, e2eBackupDirectory: URL? = nil,
         clearAuditLog: @escaping @MainActor () -> Void = {}) {
        injectedRemote = remote
        injectedUserId = userId
        self.defaults = defaults
        self.clearAuditLog = clearAuditLog
        self.e2eBackupDirectory = e2eBackupDirectory ?? FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        #if DEBUG
        e2eEnabled = e2eLaunchArguments.map(E2EFeature.isEnabled(arguments:)) ?? E2EFeature.isEnabled
        #else
        e2eEnabled = E2EFeature.isEnabled
        #endif
    }

    private var auth: SupabaseManager { .shared }
    private var remote: any SyncRemote { injectedRemote ?? PlainRemote(client: auth.client) }
    private var userId: UUID? { injectedUserId ?? auth.session?.user.id }
    private var isUsingVolatileStore: Bool { injectedRemote == nil && MoneyTrackerApp.usingVolatileStore }

    private let lastPullKey  = "syncService.lastPull"
    private let lastUserKey  = "syncService.lastUserId"
    private let pullCooldown: TimeInterval = 300   // 5 minuti

    // Task di debounce per il push real-time (annullato e ricreato ad ogni salvataggio)
    private var debounceTask: Task<Void, Never>?

    // MARK: - Resilienza: circuit breaker + retry con backoff + rilevamento rete
    //
    // Un push che fallisce (rete assente, Supabase temporaneamente irraggiungibile)
    // non viene semplicemente loggato e dimenticato: resta "in sospeso" (sopravvive
    // al riavvio dell'app tramite UserDefaults) e viene ritentato automaticamente con
    // un ritardo crescente (2s, 4s, 8s... fino a un tetto di 60s) per non martellare
    // di richieste un servizio già in difficoltà. Un NWPathMonitor tiene d'occhio la
    // connessione: appena torna, il prossimo tentativo parte subito, senza aspettare
    // il backoff residuo.
    @Published private(set) var status: SyncStatus = .idle
    private let pendingChangesKey = "syncService.hasPendingChanges"
    private var consecutiveFailures = 0
    private let maxBackoff: TimeInterval = 60
    private var retryTask: Task<Void, Never>?
    private lazy var pathMonitor = NWPathMonitor()
    /// Ultimo context "reale" usato per un sync — serve ai retry automatici innescati
    /// dal path monitor, che non hanno un chiamante diretto da cui riceverlo.
    private var lastContext: ModelContext?
    private var e2eRetryOperation: E2EOperation?

    /// true se esistono modifiche locali non ancora confermate su Supabase.
    private var hasPendingChanges: Bool {
        get { defaults.bool(forKey: pendingChangesKey) }
        set { defaults.set(newValue, forKey: pendingChangesKey) }
    }

    private func startNetworkMonitoring() {
        pathMonitor.pathUpdateHandler = { [weak self] path in
            guard let self else { return }
            Task { @MainActor in
                if path.status == .satisfied {
                    // La rete è tornata: se c'erano modifiche in sospeso, non aspettare
                    // il resto del backoff — riprova subito.
                    if self.status == .offline { self.status = .idle }
                    if self.hasPendingChanges, let ctx = self.lastContext {
                        self.retryTask?.cancel()
                        if let operation = self.e2eRetryOperation {
                            await self.runE2ESync(operation, context: ctx)
                        } else {
                            await self.pushResilient(context: ctx)
                        }
                    }
                } else {
                    self.status = .offline
                }
            }
        }
        pathMonitor.start(queue: DispatchQueue(label: "SyncService.NWPathMonitor"))
    }

    /// Push con circuit breaker: aggiorna lo stato pubblico, e se fallisce pianifica
    /// da solo il prossimo tentativo invece di richiedere un intervento esterno.
    @discardableResult
    func pushResilient(context: ModelContext) async -> Bool {
        guard !isUsingVolatileStore else { return false }
        if e2eEnabled { return await runE2ESync(.push, context: context) }
        lastContext = context
        status = .syncing
        let ok = await push(context: context)
        if ok {
            consecutiveFailures = 0
            hasPendingChanges   = false
            status = .idle
        } else {
            consecutiveFailures += 1
            hasPendingChanges    = true
            scheduleRetry(context: context)
        }
        return ok
    }

    private func scheduleRetry(context: ModelContext, e2eOperation: E2EOperation? = nil) {
        guard !isUsingVolatileStore else { return }
        retryTask?.cancel()
        e2eRetryOperation = e2eOperation
        let delay = min(pow(2.0, Double(consecutiveFailures)), maxBackoff)
        status = .waitingForRetry(attempt: consecutiveFailures)
        Logger.persistence.info("SyncService: push fallito, nuovo tentativo tra \(delay, format: .fixed(precision: 0))s (tentativo #\(self.consecutiveFailures))")
        retryTask = Task { [weak self] in
            try? await Task.sleep(for: .seconds(delay))
            guard !Task.isCancelled, let self else { return }
            if let e2eOperation {
                await self.runE2ESync(e2eOperation, context: context)
            } else {
                await self.pushResilient(context: context)
            }
        }
    }

    /// Sync completo su foreground (cold start o ritorno dell'app in primo piano):
    /// push resiliente, poi pull solo se il push è riuscito e il cooldown è scaduto.
    /// Centralizza qui la logica prima duplicata/inline in MoneyTrackerApp.
    func syncOnForeground(context: ModelContext) async {
        if e2eEnabled {
            await runE2ESync(.foreground, context: context)
            return
        }
        let pushed = await pushResilient(context: context)
        if pushed && shouldPull {
            await pull(context: context)
        }
    }

    // MARK: - Dirty tracking (sync incrementale — PROP-01)
    //
    // Solo per Transaction: è l'unica tabella che può crescere a migliaia di righe
    // (specie con un'eventuale integrazione bancaria futura). Conti/budget/obiettivi
    // restano sempre poche decine per utente, quindi continuano a essere caricati per
    // intero ad ogni push — la complessità del dirty-tracking non varrebbe il beneficio.
    //
    // Come funziona: ogni volta che il context salva, SwiftData dice esattamente quali
    // record sono stati inseriti/modificati (notification.userInfo). Registriamo qui
    // solo i loro UUID (Set<UUID>, persistito in UserDefaults — sopravvive anche se
    // l'app viene chiusa prima di riuscire a sincronizzare). push() userà questo elenco
    // per caricare SOLO le righe davvero cambiate, non l'intera tabella.
    private let dirtyTransactionIdsKey = "syncService.dirtyTransactionIds"

    private var dirtyTransactionIds: Set<UUID> {
        get {
            guard let data = defaults.data(forKey: dirtyTransactionIdsKey),
                  let ids  = try? JSONDecoder().decode(Set<UUID>.self, from: data) else { return [] }
            return ids
        }
        set {
            guard let data = try? JSONEncoder().encode(newValue) else { return }
            defaults.set(data, forKey: dirtyTransactionIdsKey)
        }
    }

    /// Estrae dalla notifica di salvataggio quali `Transaction` sono state create o
    /// modificate e le aggiunge all'elenco "da sincronizzare". Le cancellazioni non
    /// servono qui: sono già gestite correttamente e in modo efficiente da
    /// `deleteOrphans` (confronto dei soli ID, non dei dati completi).
    func recordChanges(from notification: Notification, context: ModelContext) {
        let inserted = (notification.userInfo?[ModelContext.NotificationKey.insertedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? []
        let updated  = (notification.userInfo?[ModelContext.NotificationKey.updatedIdentifiers.rawValue]  as? [PersistentIdentifier]) ?? []
        let changed  = inserted + updated
        guard !changed.isEmpty else { return }

        var ids = dirtyTransactionIds
        var addedAny = false
        for pid in changed where pid.entityName == "Transaction" {
            // model(for:) risolve anche identificatori non ancora "registrati" in questo
            // context (fault-fetch da disco) — sicuro qui perché il salvataggio è appena
            // avvenuto, gli oggetti sono per forza ancora validi in questo istante.
            if let t = context.model(for: pid) as? Transaction {
                ids.insert(t.id)
                addedAny = true
            }
        }
        if addedAny { dirtyTransactionIds = ids }
    }

    /// Marca esplicitamente una transazione come "da sincronizzare".
    /// Usato dagli App Intent (es. tocco posteriore/Siri, vedi Intents/AddExpenseIntent.swift):
    /// girano in un processo separato dall'app, quindi il loro ctx.save() non genera
    /// mai la notifica ModelContext.didSave osservata da recordChanges() nel processo
    /// principale. Senza questa marcatura esplicita, la transazione resta fuori dal
    /// prossimo push e il pull successivo la considera orfana (cancellata altrove) e
    /// la elimina anche in locale — pur essendo stata salvata correttamente.
    func markTransactionDirty(_ id: UUID) {
        var ids = dirtyTransactionIds
        ids.insert(id)
        dirtyTransactionIds = ids
        hasPendingChanges = true
    }

    /// true se è passato abbastanza tempo dall'ultimo pull.
    var shouldPull: Bool {
        guard let last = defaults.object(forKey: lastPullKey) as? Date else { return true }
        return Date().timeIntervalSince(last) > pullCooldown
    }

    // MARK: - Manual refresh (pull-to-refresh)

    /// Refresh esplicito dell'utente (tirare giù per aggiornare). A differenza del pull
    /// automatico su foreground, ignora il cooldown di 5 minuti perché è un'azione
    /// intenzionale. No-op se non loggato o in modalità demo (la demo ha un container
    /// locale separato, non collegato a Supabase).
    /// Push prima del pull, come su foreground: se il push fallisce (offline/rete
    /// instabile), il pull viene saltato per non cancellare modifiche locali non ancora
    /// caricate sul cloud.
    func manualRefresh(context: ModelContext) async {
        if e2eEnabled {
            await runE2ESync(.refresh, context: context)
            return
        }
        guard auth.isLoggedIn, !defaults.bool(forKey: "demoModeEnabled") else { return }
        guard await pushResilient(context: context) else { return }
        await pull(context: context)
    }

    // MARK: - Sync on login

    /// Primo sync dopo il login:
    /// • Se l'utente è diverso dall'ultimo → svuota locale prima (isolamento dati)
    /// • Se Supabase non ha dati → push (dati locali esistenti vanno sul cloud)
    /// • Se Supabase ha già dati  → pull (il cloud è la fonte di verità)
    func syncOnLogin(context: ModelContext) async {
        if e2eEnabled {
            await runE2ESync(.login, context: context)
            return
        }
        guard let userId else { return }

        // Isolamento multi-utente: se l'utente è cambiato, svuota il locale
        // (gestisce anche crash / force quit che hanno saltato il logout)
        let lastUserId = defaults.string(forKey: lastUserKey)
        if lastUserId != userId.uuidString {
            clearLocalData(context: context)
        }
        defaults.set(userId.uuidString, forKey: lastUserKey)

        do {
            let remoteIds = try await remote.fetchIds(table: .accounts, userId: userId)
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
        guard !isUsingVolatileStore else { return }
        guard e2eEnabled ? userId != nil : auth.isLoggedIn else { return }
        lastContext = context
        hasPendingChanges = true
        debounceTask?.cancel()
        debounceTask = Task { [weak self] in
            guard let self else { return }
            try? await Task.sleep(for: .milliseconds(1500))
            guard !Task.isCancelled else { return }
            // Una modifica appena fatta è un buon segnale per riprovare subito,
            // anche se un retry automatico precedente stava aspettando un backoff lungo.
            self.consecutiveFailures = 0
            self.retryTask?.cancel()
            await self.pushResilient(context: context)
        }
    }

    // MARK: - Clear local data (on logout)

    /// Cancella tutti i dati locali reali (NON demo).
    /// Chiamato al logout per garantire che il prossimo utente
    /// non veda i dati del precedente.
    func clearLocalData(context: ModelContext) {
        if e2eEnabled {
            let previousUser = defaults.string(forKey: lastUserKey).flatMap(UUID.init(uuidString:))
            clearE2ESession(userId: previousUser ?? userId)
            defaults.removeObject(forKey: lastUserKey)
        }
        clearLocalStore(context: context)
    }

    private func clearLocalStore(context: ModelContext) {
        // Ordine importante: prima le dipendenze, poi gli account (cascade). Ogni
        // cancellazione è loggata se fallisce: un fallimento silenzioso qui vorrebbe
        // dire che il prossimo utente sullo stesso dispositivo può ritrovarsi a vedere
        // i dati finanziari di quello precedente — non deve mai passare inosservato.
        do { try context.delete(model: Transaction.self) }
        catch { Logger.persistence.error("clearLocalData: delete Transaction failed → \(error.localizedDescription, privacy: .public)") }
        do { try context.delete(model: RecurringRule.self) }
        catch { Logger.persistence.error("clearLocalData: delete RecurringRule failed → \(error.localizedDescription, privacy: .public)") }
        do { try context.delete(model: Budget.self) }
        catch { Logger.persistence.error("clearLocalData: delete Budget failed → \(error.localizedDescription, privacy: .public)") }
        do { try context.delete(model: Goal.self) }
        catch { Logger.persistence.error("clearLocalData: delete Goal failed → \(error.localizedDescription, privacy: .public)") }
        do { try context.delete(model: Account.self) }
        catch { Logger.persistence.error("clearLocalData: delete Account failed → \(error.localizedDescription, privacy: .public)") }
        context.safeSave()
        defaults.removeObject(forKey: lastPullKey)
        // Il registro modifiche (PROP-02) non deve mai sopravvivere ai dati a cui si
        // riferisce, né restare leggibile da un utente diverso sullo stesso dispositivo.
        clearAuditLog()
    }

    // MARK: - Push (SwiftData → Supabase)

    /// Ritorna true solo se il push è arrivato in fondo senza errori. Il chiamante deve
    /// usare questo valore per decidere se è sicuro fare un pull subito dopo: un pull dopo
    /// un push fallito (rete caduta a metà) tratterebbe le modifiche locali non ancora
    /// caricate come "cancellate altrove" e le eliminerebbe (vedi pull(), sezione DELETE).
    @discardableResult
    func push(context: ModelContext) async -> Bool {
        guard !isUsingVolatileStore else { return false }
        guard let userId else { return false }
        if e2eEnabled { return await runE2ESync(.push, context: context) }

        do {
            try await upload(context: context, remote: remote, userId: userId)
            return true
        } catch {
            Logger.persistence.error("SyncService push error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    private func upload(context: ModelContext, remote: any SyncRemote, userId: UUID,
                        validateSession: () throws -> Void = {},
                        forceAllTransactions: Bool = false, preservingDirtyTransactions: Bool = false,
                        allowingOrphanDeletion: Bool = true) async throws {
        func prune(_ table: SyncTable, _ ids: [UUID]) async throws {
            guard allowingOrphanDeletion else { return }
            try await deleteOrphans(remote: remote, table: table, userId: userId,
                                    validateSession: validateSession, localIds: Set(ids))
        }
        Logger.persistence.info("SyncService: push started")
        do {
            let accounts     = try context.fetch(FetchDescriptor<Account>())
            let transactions = try context.fetch(FetchDescriptor<Transaction>())
            let budgets      = try context.fetch(FetchDescriptor<Budget>())
            let goals        = try context.fetch(FetchDescriptor<Goal>())

            // Fetch must succeed before orphan deletion: a failed read is not an empty store.
            let rules = try context.fetch(FetchDescriptor<RecurringRule>())

            // Accounts
            try validateSession()
            if !accounts.isEmpty {
                let sb = accounts.map { SBAccount($0, userId: userId) }
                try await remote.upsert(sb, table: .accounts, userId: userId)
            }
            try await prune(.accounts, accounts.map(\.id))

            // Transactions — sync incrementale: carica solo le righe segnate come
            // cambiate da recordChanges(), non l'intera tabella (vedi sezione dedicata
            // sopra). deleteOrphans confronta comunque TUTTI gli id locali/remoti: quel
            // confronto è già economico di suo (solo UUID, non i dati completi) e deve
            // vedere l'intero set per rilevare correttamente le cancellazioni.
            let dirtyIds = forceAllTransactions ? Set(transactions.map(\.id)) : dirtyTransactionIds
            let dirtyTransactions = dirtyIds.isEmpty ? [] : transactions.filter { dirtyIds.contains($0.id) }
            try validateSession()
            if !dirtyTransactions.isEmpty {
                let sb = dirtyTransactions.map { SBTransaction($0, userId: userId) }
                try await remote.upsert(sb, table: .transactions, userId: userId)
                // Rimuove dal set "sporco" solo gli id appena caricati con successo — se
                // nel frattempo ne sono arrivati altri (salvataggio concorrente), restano
                // in coda per il prossimo push invece di andare persi.
                try validateSession()
                if !preservingDirtyTransactions { dirtyTransactionIds.subtract(dirtyTransactions.map(\.id)) }
            }
            try await prune(.transactions, transactions.map(\.id))

            // Budgets
            try validateSession()
            if !budgets.isEmpty {
                let sb = budgets.map { SBBudget($0, userId: userId) }
                try await remote.upsert(sb, table: .budgets, userId: userId)
            }
            try await prune(.budgets, budgets.map(\.id))

            // Goals
            try validateSession()
            if !goals.isEmpty {
                let sb = goals.map { SBGoal($0, userId: userId) }
                try await remote.upsert(sb, table: .goals, userId: userId)
            }
            try await prune(.goals, goals.map(\.id))

            // Rules use a full upsert, like budgets (including watermark and exceptions).
            try validateSession()
            if !rules.isEmpty {
                let sb = rules.map { SBRecurringRule($0, userId: userId) }
                try await remote.upsert(sb, table: .recurringRules, userId: userId)
            }
            try await prune(.recurringRules, rules.map(\.id))

            Logger.persistence.info("SyncService: push complete")
        }
    }

    // MARK: - Pull (Supabase → SwiftData)

    func pull(context: ModelContext) async {
        guard let userId else { return }
        if e2eEnabled {
            await runE2ESync(.pull, context: context)
            return
        }
        do {
            try await download(context: context, remote: remote, userId: userId)
        } catch {
            Logger.persistence.error("SyncService pull error: \(error.localizedDescription, privacy: .public)")
        }
    }

    private func downloadE2E(context: ModelContext, remote: any SyncRemote, userId: UUID,
                             validateSession: () throws -> Void) async throws {
        // Finish all reads before touching SwiftData: a bad vault row or a
        // stale session must not look like a remote deletion.
        let snapshot = try await PullRows(remote: remote, userId: userId)
        try validateSession()
        try await download(context: context, remote: remote, userId: userId, snapshot: snapshot)
    }

    private func download(context: ModelContext, remote: any SyncRemote, userId: UUID,
                          snapshot: PullRows? = nil, strictSave: Bool = false) async throws {
        Logger.persistence.info("SyncService: pull started")
        do {
            // ── 1. ACCOUNTS ────────────────────────────────────────────────
            let sbAccounts: [SBAccount] = if let snapshot {
                snapshot.accounts
            } else {
                try await remote.select(table: .accounts, userId: userId)
            }

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
            let sbTx: [SBTransaction] = if let snapshot {
                snapshot.transactions
            } else {
                try await remote.select(table: .transactions, userId: userId)
            }

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
            // Non cancellare transazioni locali ancora "sporche" (create/modificate ma
            // non ancora confermate su Supabase, es. subito dopo l'inserimento o se
            // markTransactionDirty è stato chiamato dall'Intent del Tocco posteriore
            // ma il push non è ancora partito/riuscito). Senza questo controllo, un
            // pull che arriva prima che quelle righe siano state caricate le tratta
            // come "cancellate su un altro dispositivo" e le elimina anche qui — pur
            // essendo state salvate correttamente e mai sincronizzate altrove.
            let stillDirty = dirtyTransactionIds
            if !strictSave {
                for local in localTx where !pulledTxIds.contains(local.id) && !stillDirty.contains(local.id) {
                    context.delete(local)
                }
            }

            // ── 3. BUDGETS ─────────────────────────────────────────────────
            let sbBudgets: [SBBudget] = if let snapshot {
                snapshot.budgets
            } else {
                try await remote.select(table: .budgets, userId: userId)
            }

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
            let sbGoals: [SBGoal] = if let snapshot {
                snapshot.goals
            } else {
                try await remote.select(table: .goals, userId: userId)
            }

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

            let sbRules: [SBRecurringRule] = if let snapshot {
                snapshot.rules
            } else {
                try await remote.select(table: .recurringRules, userId: userId)
            }
            try Self.mergeRecurringRules(sbRules, context: context)

            if strictSave {
                do { try context.save() }
                catch {
                    context.rollback()
                    throw error
                }
                AccountBalanceCache.shared.invalidateAll()
            } else {
                context.safeSave()
            }
            defaults.set(Date(), forKey: lastPullKey)
            Logger.persistence.info("SyncService: pull complete")
        }
    }

    /// Shared by the pull and in-memory tests; save remains part of the enclosing pull.
    static func mergeRecurringRules(_ rows: [SBRecurringRule], context: ModelContext) throws {
        let locals = try context.fetch(FetchDescriptor<RecurringRule>())
        // Preserve local rules awaiting their first push, as with accounts.
        if rows.isEmpty && !locals.isEmpty { return }
        let byId = Dictionary(locals.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
        for row in rows {
            if let existing = byId[row.id] {
                row.apply(to: existing)
            } else {
                let rule = RecurringRule(id: row.id, name: row.name, amount: row.amount,
                                         type: row.type, frequency: row.frequency, startDate: row.startDate)
                row.apply(to: rule)
                context.insert(rule)
            }
        }
        let remoteIds = Set(rows.map { $0.id })
        for local in locals where !remoteIds.contains(local.id) { context.delete(local) }
    }

    // MARK: - Helpers

    /// Elimina da Supabase i record che esistono in remoto ma non localmente.
    /// Una sola richiesta batch (non una per riga): con N record orfani, il pattern
    /// precedente faceva N round-trip di rete sequenziali (classico N+1) — qui è O(1)
    /// indipendentemente da quanti record vanno cancellati.
    private func deleteOrphans(remote: any SyncRemote, table: SyncTable, userId: UUID,
                               validateSession: () throws -> Void, localIds: Set<UUID>) async throws {
        guard !isUsingVolatileStore else { return }
        try validateSession()
        let remoteIds = try await remote.fetchIds(table: table, userId: userId)
        try validateSession()
        let orphans   = remoteIds.subtracting(localIds)
        guard !orphans.isEmpty else { return }
        try await remote.delete(ids: Array(orphans), table: table, userId: userId)
    }

    // MARK: - E2E operations

    private enum E2EOperation {
        case push, foreground, refresh, login, pull
    }

    private typealias PullRows = E2EVerifier.Snapshot

    @Published private(set) var e2eServerSupported: Bool?
    @Published private(set) var e2eLockReason: E2EGate.LockReason?
    private(set) var e2eMigrationToResume: E2EMigrationDirection?
    private var e2eSessionGeneration = UUID()
    private var e2eTask: (id: UUID, work: Task<Bool, Never>)?
    private let initialSyncKey = "e2e.initialSyncUser"

    private func clearE2ESession(userId: UUID?) {
        e2eSessionGeneration = UUID()
        e2eTask?.work.cancel()
        e2eTask = nil
        debounceTask?.cancel()
        retryTask?.cancel()
        e2eRetryOperation = nil
        lastContext = nil
        hasPendingChanges = false
        dirtyTransactionIds = []
        consecutiveFailures = 0
        status = .idle
        e2eLockReason = nil
        e2eServerSupported = nil
        e2eMigrationToResume = nil
        defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
        defaults.removeObject(forKey: initialSyncKey)
        do {
            try FileManager.default.removeItem(at: e2eBackupDirectory)
        } catch let error as CocoaError where error.code == .fileNoSuchFile {
            // No migration backup on this device.
        } catch {
            Logger.persistence.error("SyncService: E2E backup removal failed")
        }
        if let userId {
            do { try e2eKeyStore.remove(userId: userId) }
            catch { Logger.persistence.error("SyncService: E2E key removal failed") }
        }
    }

    private func prepareE2ELogin(userId: UUID, context: ModelContext) -> Bool {
        let previousUser = defaults.string(forKey: lastUserKey).flatMap(UUID.init(uuidString:))
        guard previousUser != userId else { return true }
        clearE2ESession(userId: previousUser)
        clearLocalStore(context: context)
        // A failed batch delete must never allow the old store to be uploaded
        // under new credentials.
        do {
            guard try context.fetchCount(FetchDescriptor<Account>()) == 0,
                  try context.fetchCount(FetchDescriptor<Transaction>()) == 0,
                  try context.fetchCount(FetchDescriptor<Budget>()) == 0,
                  try context.fetchCount(FetchDescriptor<Goal>()) == 0,
                  try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0 else {
                Logger.persistence.error("SyncService: E2E login stopped because local data remains")
                return false
            }
        } catch {
            Logger.persistence.error("SyncService: E2E login could not verify the local store")
            return false
        }
        defaults.set(userId.uuidString, forKey: lastUserKey)
        return true
    }

    @discardableResult
    private func runE2ESync(_ operation: E2EOperation, context: ModelContext) async -> Bool {
        guard !isMigrating, !isUsingVolatileStore, !defaults.bool(forKey: "demoModeEnabled"),
              let userId else { return false }
        if operation == .login, !prepareE2ELogin(userId: userId, context: context) { return false }
        guard defaults.string(forKey: lastUserKey).flatMap(UUID.init(uuidString:)) == userId else { return false }

        let generation = e2eSessionGeneration
        let previous = e2eTask?.work
        let id = UUID()
        let work = Task { @MainActor in
            _ = await previous?.value
            return await performE2ESync(operation, context: context, userId: userId, generation: generation)
        }
        e2eTask = (id, work)
        let success = await work.value
        if e2eTask?.id == id { e2eTask = nil }
        return success
    }

    private func performE2ESync(_ operation: E2EOperation, context: ModelContext,
                                userId: UUID, generation: UUID) async -> Bool {
        func validateSession() throws {
            guard self.userId == userId, e2eSessionGeneration == generation else { throw CancellationError() }
            try Task.checkCancellation()
        }
        guard (try? validateSession()) != nil else { return false }
        guard let backend = e2eBackend else { return false }
        let (server, vault) = backend

        retryTask?.cancel()
        e2eRetryOperation = nil
        lastContext = context
        status = .syncing
        let gate = E2EGate(server: server, keyStore: e2eKeyStore)
        let marker = E2EMigrator.marker(in: defaults, userId: userId)
        var retryOperation = operation
        if operation == .login { defaults.set(userId.uuidString, forKey: initialSyncKey) }

        do {
            if injectedRemote == nil {
                let session = try await auth.client.auth.session
                guard session.user.id == userId else { throw CancellationError() }
                try validateSession()
            }
            let resolution = try await gate.resolve(userId: userId, enabled: e2eEnabled,
                                                     marker: marker, validateSession: validateSession)
            try validateSession()
            if try await resumeE2E(resolution, marker: marker, context: context, userId: userId,
                                   backend: backend, validateSession: validateSession) { return true }
            if resolution.needsPlainInitialSync { defaults.set(userId.uuidString, forKey: initialSyncKey) }

            guard let selectedRemote = e2eRemote(for: resolution, plain: remote, vault: vault, userId: userId)
            else { return pauseE2ESync() }
            var initialSync = defaults.string(forKey: initialSyncKey) == userId.uuidString
            var didPush = false

            do {
                if initialSync {
                    didPush = try await initialE2ESync(context: context, remote: selectedRemote,
                                                     userId: userId, validateSession: validateSession)
                } else if operation != .pull {
                    try await upload(context: context, remote: selectedRemote, userId: userId,
                                     validateSession: validateSession)
                    didPush = true
                }
            } catch where E2EServer.blockedPlainWrite(error) {
                try validateSession()
                let refreshed = try await gate.resolve(userId: userId, enabled: e2eEnabled,
                                                        marker: marker, validateSession: validateSession)
                try validateSession()
                if try await resumeE2E(refreshed, marker: marker, context: context, userId: userId,
                                       backend: backend, validateSession: validateSession) { return true }
                guard let refreshedRemote = e2eRemote(for: refreshed, plain: remote, vault: vault, userId: userId)
                else { return pauseE2ESync() }
                guard case .vault = refreshed.mode else { throw error }
                defaults.set(userId.uuidString, forKey: initialSyncKey)
                initialSync = true
                didPush = try await initialE2ESync(context: context, remote: refreshedRemote,
                                                 userId: userId, validateSession: validateSession)
            }

            try validateSession()
            if didPush { hasPendingChanges = !dirtyTransactionIds.isEmpty }
            if initialSync {
                defaults.removeObject(forKey: initialSyncKey)
            } else if operation == .pull || operation == .refresh || (operation == .foreground && shouldPull) {
                retryOperation = .pull
                try await downloadE2E(context: context, remote: selectedRemote, userId: userId,
                                      validateSession: validateSession)
            }
            try validateSession()
            consecutiveFailures = 0
            status = .idle
            return didPush || operation != .push
        } catch is CancellationError {
            return false
        } catch E2EMigrator.Failure.verificationFailed {
            return pauseE2ESync()
        } catch {
            guard (try? validateSession()) != nil else { return false }
            Logger.persistence.error("SyncService: E2E sync operation failed")
            hasPendingChanges = true
            consecutiveFailures += 1
            scheduleRetry(context: context, e2eOperation: retryOperation)
            return false
        }
    }

    private typealias E2EBackend = (any E2EServerAccess, any VaultAccess)

    private var e2eBackend: E2EBackend? {
        if let injectedRemote {
            guard let backend = injectedRemote as? (any E2EServerAccess & VaultAccess) else { return nil }
            return (backend, backend)
        }
        return (E2EServer(client: auth.client), SupabaseVaultAccess(client: auth.client))
    }

    // Settings actions and automatic resume share the same service and transport.
    // UI supplies the localized device-authentication reason (K48).
    func withE2EMigrator<T>(context: ModelContext, authenticationReason: String,
                           checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                           authenticateForTest: (() async throws -> Void)? = nil,
                           action: (E2EMigrator) async throws -> T) async throws -> T {
        guard e2eEnabled, !isMigrating, !isUsingVolatileStore,
              !defaults.bool(forKey: "demoModeEnabled"), let userId, let backend = e2eBackend,
              defaults.string(forKey: lastUserKey).flatMap(UUID.init(uuidString:)) == userId else {
            throw E2EMigrator.Failure.unavailable
        }
        let generation = e2eSessionGeneration
        func validateSession() throws {
            guard self.userId == userId, e2eSessionGeneration == generation else { throw CancellationError() }
            try Task.checkCancellation()
        }
        while let previous = e2eTask {
            _ = await previous.work.value
            if e2eTask?.id == previous.id { e2eTask = nil }
            try validateSession()
        }
        guard !isMigrating else { throw E2EMigrator.Failure.stateChanged }
        isMigrating = true
        status = .syncing
        retryTask?.cancel()
        e2eRetryOperation = nil
        defer {
            isMigrating = false
            if e2eSessionGeneration == generation { status = .idle }
        }
        if injectedRemote == nil {
            let session = try await auth.client.auth.session
            guard session.user.id == userId else { throw CancellationError() }
        }
        try validateSession()
        #if DEBUG
        let authenticate = authenticateForTest ?? { try await E2EMigrator.authenticateDevice(reason: authenticationReason) }
        let stepHook = checkpoint
        #else
        let authenticate = { try await E2EMigrator.authenticateDevice(reason: authenticationReason) }
        let stepHook: (E2EMigrator.Step) throws -> Void = { _ in }
        #endif
        let migrator = makeMigrator(context: context, userId: userId, backend: backend,
                                    validateSession: validateSession, checkpoint: stepHook, authenticate: authenticate)
        let result = try await action(migrator)
        try validateSession()
        e2eLockReason = nil
        if hasPendingChanges { schedulePush(context: context) }
        return result
    }

    private func makeMigrator(context: ModelContext, userId: UUID, backend: E2EBackend,
                              validateSession: @escaping () throws -> Void,
                              checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                              authenticate: @escaping () async throws -> Void = {
                                  throw E2EMigrator.Failure.authenticationRequired
                              }) -> E2EMigrator {
        let plain: any SyncRemote = injectedRemote ?? PlainRemote(client: auth.client, forMigration: true)
        return E2EMigrator(userId: userId, defaults: defaults, keyStore: e2eKeyStore,
                           server: backend.0, vault: backend.1, plain: plain,
                           backupDirectory: e2eBackupDirectory, checkpoint: checkpoint,
                           validateSession: validateSession, authenticate: authenticate,
                           snapshot: { try PullRows(context: context, userId: userId) },
                           push: { remote, deleteOrphans, allTransactions in
                               self.hasPendingChanges = true
                               try await self.upload(context: context, remote: remote, userId: userId,
                                                     validateSession: validateSession, forceAllTransactions: allTransactions,
                                                     preservingDirtyTransactions: true, allowingOrphanDeletion: deleteOrphans)
                           }, pull: { rows in
                               try validateSession()
                               try await self.download(context: context, remote: plain, userId: userId,
                                                       snapshot: rows, strictSave: true)
                           }, initialSync: { remote in
                               self.defaults.set(userId.uuidString, forKey: self.initialSyncKey)
                               let pushed = try await self.initialE2ESync(context: context, remote: remote,
                                                                         userId: userId, validateSession: validateSession,
                                                                         forceAllTransactions: true)
                               try validateSession()
                               if pushed { self.hasPendingChanges = !self.dirtyTransactionIds.isEmpty }
                               self.defaults.removeObject(forKey: self.initialSyncKey)
                           })
    }

    private func resumeE2E(_ resolution: E2EGate.Resolution, marker: E2EMigrationMarker?,
                           context: ModelContext, userId: UUID, backend: E2EBackend,
                           validateSession: @escaping () throws -> Void) async throws -> Bool {
        guard let marker else { return false }
        if let row = resolution.row, row.keyId != marker.keyId {
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
            return false
        }
        switch resolution.mode {
        case .resume(let direction):
            e2eMigrationToResume = direction
        case .plain where resolution.serverSupported == true && marker.direction == .enable:
            // A2 without A3, or rollback completed on the server.
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
            return false
        case .vault where marker.direction == .disable && marker.phase == nil:
            // D2 without D3.
            defaults.removeObject(forKey: E2EMigrationMarker.defaultsKey)
            return false
        default:
            return false
        }
        isMigrating = true
        defer { isMigrating = false }
        e2eServerSupported = resolution.serverSupported
        let migrator = makeMigrator(context: context, userId: userId, backend: backend,
                                    validateSession: validateSession)
        try await migrator.resume(marker, row: resolution.row)
        try validateSession()
        e2eLockReason = nil
        e2eMigrationToResume = nil
        // This operation completed the first exchange itself. Keep edits made
        // during migration queued for the next push in the destination mode.
        defaults.removeObject(forKey: initialSyncKey)
        consecutiveFailures = 0
        status = .idle
        if hasPendingChanges { schedulePush(context: context) }
        return true
    }

    private func e2eRemote(for resolution: E2EGate.Resolution, plain: any SyncRemote,
                           vault: any VaultAccess, userId: UUID) -> (any SyncRemote)? {
        e2eServerSupported = resolution.serverSupported
        e2eLockReason = nil
        e2eMigrationToResume = nil
        switch resolution.mode {
        case .plain: return plain
        case .vault(let dek): return VaultRemote(access: vault, dek: dek, owner: userId)
        case .locked(let reason): e2eLockReason = reason
        case .resume(let direction): e2eMigrationToResume = direction
        }
        return nil
    }

    private func pauseE2ESync() -> Bool {
        consecutiveFailures = 0
        hasPendingChanges = true
        status = .idle
        return false
    }

    private func initialE2ESync(context: ModelContext, remote: any SyncRemote, userId: UUID,
                                validateSession: () throws -> Void,
                                forceAllTransactions: Bool = false) async throws -> Bool {
        for table in SyncTable.allCases {
            let ids = try await remote.fetchIds(table: table, userId: userId)
            try validateSession()
            if !ids.isEmpty {
                try await downloadE2E(context: context, remote: remote, userId: userId,
                                      validateSession: validateSession)
                return false
            }
        }
        try await upload(context: context, remote: remote, userId: userId,
                         validateSession: validateSession, forceAllTransactions: forceAllTransactions,
                         preservingDirtyTransactions: forceAllTransactions, allowingOrphanDeletion: !forceAllTransactions)
        return true
    }
}
