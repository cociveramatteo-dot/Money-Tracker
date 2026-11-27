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

nonisolated struct SBRecurringRule: SyncRow {
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

    @MainActor
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
    @MainActor
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

nonisolated struct SBAccount: SyncRow {
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

    @MainActor
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

nonisolated struct SBTransaction: SyncRow {
    let id:                 UUID
    let userId:             UUID
    var accountId:          UUID?
    var accountLinkCleared: Bool?
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
        case accountLinkCleared = "account_link_cleared"
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

    func encode(to encoder: Encoder) throws {
        try encode(to: encoder, explicitNullAccount: false)
    }

    func encode(to encoder: Encoder, explicitNullAccount: Bool) throws {
        var values = encoder.container(keyedBy: CodingKeys.self)
        try values.encode(id, forKey: .id)
        try values.encode(userId, forKey: .userId)
        if explicitNullAccount {
            try values.encode(accountId, forKey: .accountId)
        } else {
            try values.encodeIfPresent(accountId, forKey: .accountId)
        }
        try values.encode(name, forKey: .name)
        try values.encode(amount, forKey: .amount)
        try values.encode(type, forKey: .type)
        try values.encode(category, forKey: .category)
        try values.encode(categoryIcon, forKey: .categoryIcon)
        try values.encode(date, forKey: .date)
        try values.encode(isDone, forKey: .isDone)
        try values.encode(isFixed, forKey: .isFixed)
        try values.encode(isTransfer, forKey: .isTransfer)
        try values.encode(transferGroupId, forKey: .transferGroupId)
        try values.encode(notes, forKey: .notes)
        try values.encode(recurringFrequency, forKey: .recurringFrequency)
        try values.encode(templateId, forKey: .templateId)
        try values.encode(createdAt, forKey: .createdAt)
    }

    @MainActor
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

nonisolated struct SBBudget: SyncRow {
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

    @MainActor
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

nonisolated struct SBGoal: SyncRow {
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

    @MainActor
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

    typealias PullRows = E2EVerifier.Snapshot

    let injectedRemote: (any SyncRemote)?
    private let injectedUserId: UUID?
    private let injectedVolatileStore: Bool?
    let defaults: UserDefaults
    private let clearAuditLog: @MainActor () -> Void
    let e2eEnabled: Bool
    let e2eKeyStore: E2EKeyStore
    private(set) var e2eBackupDirectory = E2EMigrator.backupDirectory
    @Published var isMigrating = false
    @Published var e2eProtection: E2EController.Protection?
    var e2eProtectionUser: UUID?
    var e2eSessionGeneration = UUID()
    @Published var e2eServerSupported: Bool?
    @Published var e2eLockReason: E2EGate.LockReason?
    var e2eMigrationToResume: E2EMigrationDirection?
    var closingAccount = false
    var e2eTask: (id: UUID, work: Task<Bool, Never>)?
    let initialSyncKey = "e2e.initialSyncUser"

    private init() {
        injectedRemote = nil
        injectedUserId = nil
        injectedVolatileStore = nil
        defaults = .standard
        clearAuditLog = { AuditLogger.shared.clearAll() }
        e2eEnabled = E2EFeature.isEnabled
        e2eKeyStore = E2EKeyStore()
        startNetworkMonitoring()
    }

    /// Isolated service for tests, with no network monitor or live app state.
    init(remote: any SyncRemote, userId: UUID, defaults: UserDefaults,
         e2eLaunchArguments: [String]? = nil, e2eBackupDirectory: URL? = nil,
         e2eKeyStore: E2EKeyStore = E2EKeyStore(),
         volatileStore: Bool = false,
         clearAuditLog: @escaping @MainActor () -> Void = {}) {
        injectedRemote = remote
        injectedUserId = userId
        injectedVolatileStore = volatileStore
        self.defaults = defaults
        self.clearAuditLog = clearAuditLog
        self.e2eKeyStore = e2eKeyStore
        self.e2eBackupDirectory = e2eBackupDirectory ?? FileManager.default.temporaryDirectory
            .appending(path: UUID().uuidString, directoryHint: .isDirectory)
        #if DEBUG
        e2eEnabled = e2eLaunchArguments.map(E2EFeature.isEnabled(arguments:)) ?? E2EFeature.isEnabled
        #else
        e2eEnabled = E2EFeature.isEnabled
        #endif
    }

    var auth: SupabaseManager { .shared }
    var remote: any SyncRemote { injectedRemote ?? PlainRemote(client: auth.client) }
    var userId: UUID? { injectedUserId ?? auth.session?.user.id }
    var isUsingVolatileStore: Bool { injectedVolatileStore ?? MoneyTrackerApp.usingVolatileStore }

    /// The account whose data the local store currently holds.
    var lastSyncedUser: UUID? {
        defaults.string(forKey: Self.lastUserKey).flatMap(UUID.init(uuidString:))
    }

    private func ownsPlainStore(userId: UUID) -> Bool {
        defaults.string(forKey: Self.lastUserKey).map { $0 == userId.uuidString } ?? true
    }

    private let lastPullKey  = "syncService.lastPull"
    static let lastUserKey = "syncService.lastUserId"
    static let demoModeKey = "demoModeEnabled"
    private let pullCooldown: TimeInterval = 300   // 5 minuti

    // Task di debounce per il push real-time (annullato e ricreato ad ogni salvataggio)
    var debounceTask: Task<Void, Never>?

    // MARK: - Resilienza: circuit breaker + retry con backoff + rilevamento rete
    //
    // Un push che fallisce (rete assente, Supabase temporaneamente irraggiungibile)
    // non viene semplicemente loggato e dimenticato: resta "in sospeso" (sopravvive
    // al riavvio dell'app tramite UserDefaults) e viene ritentato automaticamente con
    // un ritardo crescente (2s, 4s, 8s... fino a un tetto di 60s) per non martellare
    // di richieste un servizio già in difficoltà. Un NWPathMonitor tiene d'occhio la
    // connessione: appena torna, il prossimo tentativo parte subito, senza aspettare
    // il backoff residuo.
    @Published var status: SyncStatus = .idle
    private let pendingChangesKey = "syncService.hasPendingChanges"
    var consecutiveFailures = 0
    private let maxBackoff: TimeInterval = 60
    var retryTask: Task<Void, Never>?
    private lazy var pathMonitor = NWPathMonitor()
    /// Ultimo context "reale" usato per un sync — serve ai retry automatici innescati
    /// dal path monitor, che non hanno un chiamante diretto da cui riceverlo.
    var lastContext: ModelContext?
    var e2eRetryOperation: E2EOperation?

    /// true se esistono modifiche locali non ancora confermate su Supabase.
    var hasPendingChanges: Bool {
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

    func scheduleRetry(context: ModelContext, e2eOperation: E2EOperation? = nil) {
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

    var dirtyTransactionIds: Set<UUID> {
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
    // Checked at notification delivery, before Combine defers processing to the main run loop.
    private var isApplyingRemoteSave = false

    func shouldObserveSave(_ notification: Notification, context: ModelContext) -> Bool {
        (notification.object as? ModelContext) === context && !isApplyingRemoteSave
    }

    func recordChanges(from notification: Notification, context: ModelContext) {
        guard shouldObserveSave(notification, context: context) else { return }
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
        guard userId != nil, !defaults.bool(forKey: Self.demoModeKey) else { return }
        guard await pushResilient(context: context) else { return }
        await pull(context: context)
    }

    // MARK: - Sync on login

    /// Primo sync dopo il login:
    /// • Se l'utente è diverso dall'ultimo → svuota locale prima (isolamento dati)
    /// • Se Supabase non ha dati → push (dati locali esistenti vanno sul cloud)
    /// • Se Supabase ha già dati  → pull (il cloud è la fonte di verità)
    func syncOnLogin(context: ModelContext) async {
        guard !isUsingVolatileStore else { return }
        if e2eEnabled {
            await runE2ESync(.login, context: context)
            return
        }
        guard let userId else { return }

        // Isolamento multi-utente: se l'utente è cambiato, svuota il locale
        // (gestisce anche crash / force quit che hanno saltato il logout)
        let lastUserId = defaults.string(forKey: Self.lastUserKey)
        if lastUserId != userId.uuidString, !clearLocalData(context: context) {
            return
        }
        defaults.set(userId.uuidString, forKey: Self.lastUserKey)

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
    @discardableResult
    func clearLocalData(context: ModelContext, retiredUser: UUID? = nil) -> Bool {
        if e2eEnabled {
            let previousUser = lastSyncedUser
            let owner = previousUser ?? retiredUser ?? userId ?? e2eProtectionUser
            clearE2ESession(userId: owner)
            if let retiredUser, retiredUser != owner { removeE2EKey(userId: retiredUser) }
        }
        guard clearLocalStore(context: context) else { return false }
        if e2eEnabled { defaults.removeObject(forKey: Self.lastUserKey) }
        return true
    }

    #if DEBUG
    /// Times `clearLocalStore` had to fall back to per-instance deletion (tests only).
    private(set) var clearLocalStoreFallbackCount = 0
    #endif

    func clearLocalStore(context: ModelContext) -> Bool {
        isApplyingRemoteSave = true
        defer { isApplyingRemoteSave = false }
        if let owner = lastSyncedUser { setAccountDeletions([], userId: owner) }
        // Batch deletion first, accounts before their transactions and budgets:
        // batch-deleting a transaction cannot nullify its account inverse. If it
        // still fails (or misses unsaved inserts), delete instances so SwiftData
        // handles relationships and unlinked rows together.
        func isEmpty<Model: PersistentModel>(_ type: Model.Type) throws -> Bool {
            try context.fetchCount(FetchDescriptor<Model>()) == 0
        }
        func deleteAll<Model: PersistentModel>(_ type: Model.Type) throws {
            for row in try context.fetch(FetchDescriptor<Model>()) {
                context.delete(row)
            }
        }
        struct BatchDeleteIncomplete: Error {}
        do {
            try context.transaction {
                try context.delete(model: Account.self)
                try context.delete(model: Transaction.self)
                try context.delete(model: RecurringRule.self)
                try context.delete(model: Budget.self)
                try context.delete(model: Goal.self)
                guard try isEmpty(Transaction.self), try isEmpty(RecurringRule.self), try isEmpty(Budget.self),
                      try isEmpty(Goal.self), try isEmpty(Account.self) else { throw BatchDeleteIncomplete() }
            }
        } catch {
            context.rollback()
            #if DEBUG
            clearLocalStoreFallbackCount += 1
            #endif
            do {
                try context.transaction {
                    try deleteAll(Transaction.self)
                    try deleteAll(RecurringRule.self)
                    try deleteAll(Budget.self)
                    try deleteAll(Goal.self)
                    try deleteAll(Account.self)
                }
            } catch {
                context.rollback()
                Logger.persistence.error("SyncService: local account data removal failed")
                return false
            }
        }
        defaults.removeObject(forKey: lastPullKey)
        defaults.removeObject(forKey: SyncBaseline.key)
        clearAuditLog()
        return true
    }

    func signOutAndClear(context: ModelContext, pushPending: Bool = true) async {
        await signOutAndClear(context: context, pushPending: pushPending) { owner in
            try? await self.auth.signOut(expectedUser: owner)
        }
    }

    func signOutAndClear(context: ModelContext, pushPending: Bool = true,
                         signOut: (UUID?) async -> Void) async {
        guard !closingAccount else { return }
        let owner = userId
        if pushPending { await pushResilient(context: context) }
        guard !closingAccount, userId == owner else { return }
        guard e2eEnabled else {
            await signOut(owner)
            clearLocalData(context: context)
            return
        }

        closingAccount = true
        clearLocalData(context: context, retiredUser: owner)
        await signOut(owner)
        closingAccount = false
        if let current = userId, current != owner { await syncOnLogin(context: context) }
    }

    private func accountDeletions(userId: UUID) -> Set<UUID> {
        let ids = defaults.stringArray(forKey: "syncService.accountDeletions." + userId.uuidString) ?? []
        return Set(ids.compactMap(UUID.init(uuidString:)))
    }

    private func setAccountDeletions(_ ids: Set<UUID>, userId: UUID) {
        defaults.set(ids.map(\.uuidString), forKey: "syncService.accountDeletions." + userId.uuidString)
    }

    func deleteLedgerAccount(_ account: Account, context: ModelContext) {
        let id = account.id
        context.delete(account)
        guard context.safeSave(), !defaults.bool(forKey: Self.demoModeKey),
              let userId, lastSyncedUser == userId else { return }
        setAccountDeletions(accountDeletions(userId: userId).union([id]), userId: userId)
        schedulePush(context: context)
    }

    func deleteAccount(context: ModelContext) async throws {
        guard e2eEnabled else {
            try await auth.deleteAccount()
            clearLocalData(context: context)
            try? await auth.signOut()
            return
        }
        try await deleteEncryptedAccount(
            context: context,
            deleteRemote: { try await self.auth.deleteAccount(expectedUser: $0) },
            signOut: { try? await self.auth.signOut(expectedUser: $0) }
        )
    }

    func deleteEncryptedAccount(context: ModelContext, deleteRemote: (UUID) async throws -> Void,
                                signOut: (UUID) async -> Void) async throws {
        guard e2eEnabled, let owner = userId, !isMigrating, !closingAccount else {
            throw E2EMigrator.Failure.stateChanged
        }
        closingAccount = true
        do {
            _ = await e2eTask?.work.value
            guard userId == owner else { throw CancellationError() }
            try await deleteRemote(owner)
        } catch {
            closingAccount = false
            throw error
        }
        clearLocalData(context: context, retiredUser: owner)
        if userId == owner { await signOut(owner) }
        closingAccount = false
        if let current = userId, current != owner { await syncOnLogin(context: context) }
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
        guard ownsPlainStore(userId: userId) else { return false }

        do {
            try await upload(context: context, remote: remote, userId: userId, validateSession: {
                guard self.userId == userId, ownsPlainStore(userId: userId) else { throw CancellationError() }
            })
            return true
        } catch {
            Logger.persistence.error("SyncService push error: \(error.localizedDescription, privacy: .public)")
            return false
        }
    }

    enum UploadMode {
        case incremental
        case migrationPreflight
        case migrationReconcile
        case migrationCopy(pruningOrphans: Bool)

        fileprivate var usesBaseline: Bool {
            switch self {
            case .incremental, .migrationReconcile: true
            case .migrationPreflight, .migrationCopy: false
            }
        }
    }

    func upload(context: ModelContext, remote: any SyncRemote, userId: UUID,
                validateSession: () throws -> Void = {}, mode: UploadMode = .incremental) async throws {
        var deferredAccounts = Set<UUID>()
        var protectedTransactions = Set<UUID>()

        func syncTable<Model, Row: SyncRow>(_ models: [Model], id: KeyPath<Model, UUID>, table: SyncTable,
                                            makeRow: (Model, UUID) -> Row) async throws {
            let local = Set(models.map { $0[keyPath: id] })
            try validateSession()
            if mode.usesBaseline {
                let remoteIds = try await remote.fetchIds(table: table, userId: userId)
                try validateSession()
                let baseline = SyncBaseline.load(from: defaults, user: userId)
                let base = baseline.base(for: table, local: local)
                var dirty = table == .transactions ? dirtyTransactionIds : []
                if case .migrationReconcile = mode, base == nil {
                    dirty.formUnion(local.subtracting(remoteIds))
                }
                let plan = SyncBaseline.plan(local: local, remote: remoteIds, base: base,
                                             dirty: dirty, fullUpsert: table != .transactions)
                let rows = models.filter { plan.upload.contains($0[keyPath: id]) }.map { makeRow($0, userId) }
                if !rows.isEmpty {
                    try await remote.upsert(rows, table: table, userId: userId)
                    try validateSession()
                }
                var toDelete = plan.deleteRemote
                if table == .accounts, !toDelete.isEmpty {
                    let protected = toDelete.subtracting(accountDeletions(userId: userId))
                    if !protected.isEmpty {
                        let rows: [SBTransaction] = try await remote.select(table: .transactions, userId: userId)
                        try validateSession()
                        protectedTransactions = Set(rows.compactMap { row in
                            guard let id = row.accountId, protected.contains(id) else { return nil }
                            return row.id
                        })
                    }
                    deferredAccounts = toDelete.subtracting(protected)
                    toDelete = []
                }
                if table == .transactions { toDelete.subtract(protectedTransactions) }
                if !toDelete.isEmpty {
                    try await remote.delete(ids: Array(toDelete), table: table, userId: userId)
                    try validateSession()
                }
                var updated = SyncBaseline.load(from: defaults, user: userId)
                updated.recordPush(.init(upload: plan.upload, deleteRemote: toDelete,
                                         deletedElsewhere: plan.deletedElsewhere,
                                         newBase: plan.newBase.union(plan.deleteRemote.subtracting(toDelete))), table: table)
                try updated.save(to: defaults)
                // Migration still has to verify the snapshot. An edit during that push must stay dirty if it fails.
                if table == .transactions, case .incremental = mode {
                    dirtyTransactionIds.subtract(plan.upload.union(plan.deletedElsewhere))
                }
                return
            }

            let rows = models.filter {
                if table != .transactions { return true }
                if case .migrationCopy = mode { return true }
                return dirtyTransactionIds.contains($0[keyPath: id])
            }.map { makeRow($0, userId) }
            if !rows.isEmpty {
                try await remote.upsert(rows, table: table, userId: userId)
                if table == .transactions { try validateSession() }
            }
            if case .migrationCopy(pruningOrphans: true) = mode {
                let remoteIds = try await remote.fetchIds(table: table, userId: userId)
                try validateSession()
                let orphans = remoteIds.subtracting(local)
                if table == .accounts {
                    deferredAccounts = orphans
                } else if !orphans.isEmpty {
                    try await remote.delete(ids: Array(orphans), table: table, userId: userId)
                    try validateSession()
                }
            }
        }
        Logger.persistence.info("SyncService: push started")
        do {
            let accounts     = try context.fetch(FetchDescriptor<Account>())
            let transactions = try context.fetch(FetchDescriptor<Transaction>())
            let budgets      = try context.fetch(FetchDescriptor<Budget>())
            let goals        = try context.fetch(FetchDescriptor<Goal>())

            // Fetch must succeed before orphan deletion: a failed read is not an empty store.
            let rules = try context.fetch(FetchDescriptor<RecurringRule>())

            try await syncTable(accounts, id: \.id, table: .accounts, makeRow: SBAccount.init)
            try await syncTable(transactions, id: \.id, table: .transactions, makeRow: SBTransaction.init)
            try await syncTable(budgets, id: \.id, table: .budgets, makeRow: SBBudget.init)
            try await syncTable(goals, id: \.id, table: .goals, makeRow: SBGoal.init)
            try await syncTable(rules, id: \.id, table: .recurringRules, makeRow: SBRecurringRule.init)

            if !deferredAccounts.isEmpty {
                let rows: [SBTransaction] = try await remote.select(table: .transactions, userId: userId)
                try validateSession()
                let deletable = deferredAccounts.subtracting(rows.compactMap(\.accountId))
                if !deletable.isEmpty {
                    try await remote.delete(ids: Array(deletable), table: .accounts, userId: userId)
                    try validateSession()
                    if mode.usesBaseline {
                        var updated = SyncBaseline.load(from: defaults, user: userId)
                        updated.tables[SyncTable.accounts.kind]?.subtract(deletable)
                        try updated.save(to: defaults)
                        setAccountDeletions(accountDeletions(userId: userId).subtracting(deletable), userId: userId)
                    }
                }
                if case .migrationCopy(pruningOrphans: true) = mode, deletable != deferredAccounts {
                    throw AccountSyncError.stillReferenced
                }
            }
            Logger.persistence.info("SyncService: push complete")
        }
    }

    // MARK: - Pull (Supabase → SwiftData)

    func pull(context: ModelContext) async {
        guard !isUsingVolatileStore, let userId else { return }
        if e2eEnabled {
            await runE2ESync(.pull, context: context)
            return
        }
        guard ownsPlainStore(userId: userId) else { return }
        do {
            try await download(context: context, remote: remote, userId: userId)
        } catch {
            Logger.persistence.error("SyncService pull error: \(error.localizedDescription, privacy: .public)")
        }
    }

    @discardableResult
    func download(context: ModelContext, remote: any SyncRemote, userId: UUID,
                  snapshot: PullRows? = nil, forMigration: Bool = false,
                  reconcileMigration: Bool = false) async throws -> Bool {
        guard !isUsingVolatileStore else { return false }
        // forMigration: E2E migration pull. Keeps local transactions missing from
        // the snapshot and fails (with rollback) instead of a best-effort save.
        let usesBaseline = !forMigration || reconcileMigration
        Logger.persistence.info("SyncService: pull started")
        do {
            // ── 1. ACCOUNTS ────────────────────────────────────────────────
            let sbAccounts: [SBAccount] = if let snapshot {
                snapshot.accounts
            } else {
                try await remote.select(table: .accounts, userId: userId)
            }

            let baseline = SyncBaseline.load(from: defaults, user: userId)
            let accountsBeforeRead = try context.fetch(FetchDescriptor<Account>())
            let knownAccountIds = usesBaseline ? baseline.base(for: .accounts) ?? [] : []
            // Un remoto senza conti può indicare un primo push ancora da fare.
            if sbAccounts.isEmpty && !accountsBeforeRead.isEmpty &&
                !accountsBeforeRead.contains(where: { knownAccountIds.contains($0.id) }) {
                Logger.persistence.warning("SyncService: pull skipped — remote empty, local has data")
                return false
            }

            let sbTx: [SBTransaction] = if let snapshot {
                snapshot.transactions
            } else {
                try await remote.select(table: .transactions, userId: userId)
            }
            let sbBudgets: [SBBudget] = if let snapshot {
                snapshot.budgets
            } else {
                try await remote.select(table: .budgets, userId: userId)
            }
            let sbGoals: [SBGoal] = if let snapshot {
                snapshot.goals
            } else {
                try await remote.select(table: .goals, userId: userId)
            }
            let sbRules: [SBRecurringRule] = if let snapshot {
                snapshot.rules
            } else {
                try await remote.select(table: .recurringRules, userId: userId)
            }
            guard self.userId == userId, !Task.isCancelled else { return false }
            // Commit pending user edits before tagging the pull's own save.
            if context.hasChanges, !context.safeSave() { return false }
            let localAccounts = try context.fetch(FetchDescriptor<Account>())
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
            let pendingAccounts = sbAccounts.isEmpty ? Set(localAccounts.map(\.id)).subtracting(knownAccountIds) : []
            // A transaction still pointing to an absent account is evidence of an incomplete view.
            let referencedAccounts = Set(sbTx.compactMap(\.accountId))
            let retainedAccounts = pendingAccounts.union(referencedAccounts)
            for local in localAccounts where retainedAccounts.contains(local.id) {
                accountMap[local.id] = local
            }
            let deletedAccounts = localAccounts.filter { accountMap[$0.id] == nil }
            let deletedAccountIds = Set(deletedAccounts.map(\.id))

            // ── 2. TRANSACTIONS ────────────────────────────────────────────

            let localTx    = try context.fetch(FetchDescriptor<Transaction>())
            let localTxMap = Dictionary(localTx.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
            var pulledTxIds = Set<UUID>()
            var linksToRepair = [UUID: UUID]()
            let dirty = dirtyTransactionIds
            let encrypted = remote is VaultRemote
            let brokenReferences = sbTx.count { $0.accountId != nil && $0.accountId.flatMap { accountMap[$0] } == nil }
            if brokenReferences > 0 {
                Logger.persistence.warning("SyncService: \(brokenReferences) downloaded transactions reference a missing account")
            }

            for sb in sbTx {
                pulledTxIds.insert(sb.id)
                if let existing = localTxMap[sb.id] {
                    if dirty.contains(sb.id), !forMigration { continue }
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
                    if let account = sb.accountId.flatMap({ accountMap[$0] }) {
                        if existing.account?.id != account.id { existing.account = account }
                    } else if sb.accountLinkCleared == true || (encrypted && !forMigration) {
                        if existing.account != nil { existing.account = nil }
                    } else if !forMigration, sb.accountLinkCleared == false,
                              let accountId = existing.account?.id, pulledAccountIds.contains(accountId) {
                        linksToRepair[sb.id] = accountId
                    }
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
            // mai confermate su Supabase, es. subito dopo l'inserimento o se
            // markTransactionDirty è stato chiamato dall'Intent del Tocco posteriore
            // ma il push non è ancora partito/riuscito). Senza questo controllo, un
            // pull che arriva prima che quelle righe siano state caricate le tratta
            // come "cancellate su un altro dispositivo" e le elimina anche qui — pur
            // essendo state salvate correttamente e mai sincronizzate altrove.
            let localTxIds = Set(localTx.map(\.id))
            let knownTxIds = baseline.base(for: .transactions, local: localTxIds) ?? []
            let remotelyDeletedTx = localTxIds.subtracting(pulledTxIds).intersection(knownTxIds)
            let stillDirty = dirtyTransactionIds.subtracting(remotelyDeletedTx)
            if usesBaseline {
                for local in localTx where !pulledTxIds.contains(local.id) && !stillDirty.contains(local.id) {
                    if reconcileMigration && !remotelyDeletedTx.contains(local.id) { continue }
                    if let accountId = local.account?.id, pendingAccounts.contains(accountId) { continue }
                    context.delete(local)
                }
            }

            for local in localTx where pulledTxIds.contains(local.id) || stillDirty.contains(local.id) {
                if let id = local.account?.id, deletedAccountIds.contains(id) { local.account = nil }
            }
            for account in deletedAccounts { context.delete(account) }

            // ── 3. BUDGETS ─────────────────────────────────────────────────

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
                if let accountId = local.account?.id, pendingAccounts.contains(accountId) { continue }
                context.delete(local)
            }

            // ── 4. GOALS ───────────────────────────────────────────────────

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

            try Self.mergeRecurringRules(sbRules, context: context,
                                         knownIds: usesBaseline ? baseline.base(for: .recurringRules) ?? [] : [])

            let saved: Bool
            do {
                isApplyingRemoteSave = true
                defer { isApplyingRemoteSave = false }
                if forMigration {
                    do { try context.save() }
                    catch {
                        context.rollback()
                        throw error
                    }
                    AccountBalanceCache.shared.invalidateAll()
                    saved = true
                } else {
                    saved = context.safeSave()
                }
            }
            if saved, usesBaseline, self.userId == userId {
                let updated = SyncBaseline(user: userId, tables: [
                    SyncTable.accounts.kind: pulledAccountIds.union(referencedAccounts.intersection(localAccountById.keys)),
                    SyncTable.transactions.kind: pulledTxIds,
                    SyncTable.budgets.kind: pulledBudgetIds,
                    SyncTable.goals.kind: pulledGoalIds,
                    SyncTable.recurringRules.kind: Set(sbRules.map(\.id))
                ])
                try updated.save(to: defaults)
                dirtyTransactionIds.subtract(remotelyDeletedTx)
                setAccountDeletions([], userId: userId)
            }
            defaults.set(Date(), forKey: lastPullKey)
            if saved, self.userId == userId, !linksToRepair.isEmpty {
                Logger.persistence.warning("SyncService: repairing \(linksToRepair.count) transaction account links")
                do {
                    try await remote.repairAccountLinks(linksToRepair, userId: userId)
                } catch {
                    Logger.persistence.warning("SyncService: account links will be retried on the next pull")
                }
            }
            Logger.persistence.info("SyncService: pull complete")
            return saved
        }
    }

    /// Shared by the pull and in-memory tests; save remains part of the enclosing pull.
    static func mergeRecurringRules(_ rows: [SBRecurringRule], context: ModelContext, knownIds: Set<UUID> = []) throws {
        let locals = try context.fetch(FetchDescriptor<RecurringRule>())
        // Preserve local rules awaiting their first push, as with accounts.
        if rows.isEmpty {
            for local in locals where knownIds.contains(local.id) { context.delete(local) }
            return
        }
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

}
