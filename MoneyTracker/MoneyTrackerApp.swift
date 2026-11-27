import SwiftUI
import SwiftData
import Combine
import OSLog
import Auth

@main
struct MoneyTrackerApp: App {

    // A fallback store must never become the source of cloud writes or deletions.
    static private(set) var usingVolatileStore = false

    let realContainer: ModelContainer
    let demoContainer: ModelContainer

    // Keep lifecycle and recurrence state shared across all windows.
    @Environment(\.scenePhase) private var scenePhase
    @AppStorage("demoModeEnabled") private var demoModeEnabled = false
    @State private var recurrenceStatus = RecurrenceOperationStatus()
    @State private var recurrenceRefreshTask: Task<Void, Never>?
    @State private var recurrenceSyncedUserID: UUID?

    // MARK: - UI testing hook
    //
    // XCUITest lancia l'app con l'argomento "--uitesting" (vedi MoneyTrackerUITests/UITestLaunchHelper.swift).
    // In questo modo bypassiamo login Supabase/Face ID e forziamo la modalità demo,
    // ottenendo dati deterministici senza chiamate di rete durante i test.
    static var isUITesting: Bool {
        #if DEBUG
        if E2EUITestHarness.isRequested { return true }
        #endif
        return ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    // MARK: - Init

    init() {
        if Self.isUITesting {
            // Persisted advanced filters must not leak between UI test launches.
            for key in ["txFilterMin", "txFilterMax", "txFilterUseDates"] {
                UserDefaults.standard.removeObject(forKey: key)
            }
            UserDefaults.standard.set(true, forKey: "demoModeEnabled")
            UserDefaults.standard.set(false, forKey: "appLockEnabled")
            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
        }

        // Schema(versionedSchema:) invece di Schema([...]): necessario perché
        // MoneyTrackerMigrationPlan sappia riconoscere/convertire uno store SchemaV1
        // (importi Double) verso V2 (Decimal), poi V3 (RecurringRule, solo aggiunta).
        // Vedi Persistence/SchemaMigration.swift.
        let schema = Schema(versionedSchema: SchemaV3.self)

        // Store reale nel container App Group condiviso con l'estensione Intents
        // (Tocco posteriore/Siri/Shortcuts, vedi Persistence/SharedStore.swift) — senza
        // questo, quel processo separato salva in un file che l'app non legge mai.
        SharedStore.migrateLegacyStoreIfNeeded(schema: schema)
        let realConfig: ModelConfiguration
        if let sharedURL = SharedStore.mainStoreURL {
            realConfig = ModelConfiguration(
                schema: schema,
                url: sharedURL
                // cloudKitDatabase: .automatic   ← decommentare dopo aver abilitato iCloud
            )
        } else {
            // Capability "App Groups" non ancora attivata in Xcode per questo target:
            // ripiega sulla posizione precedente, non condivisa (vedi SharedStore.swift).
            realConfig = ModelConfiguration(
                schema: schema,
                isStoredInMemoryOnly: false
            )
        }

        FormatterCache.registerLocaleObserver()

        do {
            realContainer = try ModelContainer(
                for: schema,
                migrationPlan: MoneyTrackerMigrationPlan.self,
                configurations: realConfig
            )

            // SEC-02: protezione crittografica del db reale
            applyFileProtection(to: realConfig.url, level: .completeUntilFirstUserAuthentication)

            let ctx = realContainer.mainContext
            Category.seedIfNeeded(context: ctx)

            let notifEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") == nil
            if notifEnabled { SystemNotificationManager.shared.requestPermission() }
            SystemNotificationManager.shared.scheduleFixedReminderIfNeeded(context: ctx)

        } catch {
            Self.usingVolatileStore = true
            // Logga prima di ripiegare in-memory: senza questa riga un container reale
            // corrotto/non migrabile fallisce in silenzio ad ogni lancio — l'utente vede
            // un'app "vuota" (store effimero) senza nessuna traccia in Console.app/crash
            // report che spieghi perché i suoi dati non sono più lì.
            Logger.persistence.error("ModelContainer reale non creabile, fallback in-memory: \(error.localizedDescription, privacy: .public)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            realContainer = (try? ModelContainer(for: schema, configurations: fallback))
                ?? { fatalError("Impossibile creare ModelContainer: \(error)") }()
        }

        // "demo" come nome → SwiftData crea demo.store nella sua cartella standard.
        // url è una proprietà read-only calcolata da ModelConfiguration, non un parametro init.
        let demoConfig = ModelConfiguration("demo", schema: schema, isStoredInMemoryOnly: false)

        do {
            demoContainer = try ModelContainer(
                for: schema,
                migrationPlan: MoneyTrackerMigrationPlan.self,
                configurations: demoConfig
            )
            // Proteggi il file demo (accessibile dopo il primo sblocco post-riavvio)
            applyFileProtection(to: demoConfig.url, level: .completeUntilFirstUserAuthentication)
            let demoCtx = demoContainer.mainContext
            Category.seedIfNeeded(context: demoCtx)
            // Semina tutti i dati demo subito in init() — in modo sincrono, prima che
            // qualsiasi @Query si abboni al container. Così quando l'utente attiva la
            // modalità demo i dati sono già presenti e non serve nessun .task asincrono.
            DemoDataSeeder.seedIfNeeded(context: demoCtx)
            // Stato demo sempre pulito e deterministico a ogni lancio dei test UI —
            // altrimenti transazioni/conti aggiunti dal test precedente si accumulerebbero.
            if Self.isUITesting {
                DemoDataSeeder.forceReset(context: demoCtx)
            }
        } catch {
            // Fallback sicuro: in-memory (la demo funziona ma non persiste tra i lanci)
            Logger.persistence.error("ModelContainer demo non creabile, fallback in-memory: \(error.localizedDescription, privacy: .public)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            demoContainer = (try? ModelContainer(for: schema, configurations: fallback))
                ?? realContainer
        }
    }

    var body: some Scene {
        let rootView = RootView(
            realContainer: realContainer,
            demoContainer: demoContainer,
            demoModeEnabled: demoModeEnabled,
            scenePhase: scenePhase,
            recurrenceStatus: recurrenceStatus,
            scheduleRecurrenceRefresh: scheduleRecurrenceRefresh(afterLogin:)
        )
        // SwiftUI may ask for the already constructed view on its renderer queue.
        return WindowGroup { @Sendable in rootView }
    }

    // All lifecycle entry points share one queue: initial login sync, foreground
    // sync and clock/month changes must finish their pull before materialization.
    private func scheduleRecurrenceRefresh(afterLogin: Bool) {
        let auth = SupabaseManager.shared
        let previous = recurrenceRefreshTask
        recurrenceRefreshTask = Task { @MainActor in
            await previous?.value
            let isDemo = demoModeEnabled || Self.isUITesting
            let container = isDemo ? demoContainer : realContainer
            if !isDemo {
                guard auth.isLoggedIn else { return }
                guard let userID = auth.session?.user.id else { return }
                if afterLogin || recurrenceSyncedUserID != userID {
                    await SyncService.shared.syncOnLogin(context: container.mainContext)
                } else {
                    await SyncService.shared.syncOnForeground(context: container.mainContext)
                }
                guard auth.isLoggedIn, auth.session?.user.id == userID, !demoModeEnabled else { return }
                recurrenceSyncedUserID = userID
            }
            recurrenceStatus.perform {
                try RecurringMaterializer().materializeDue(context: container.mainContext)
            }
        }
    }
}

private struct RootView: View {
    let realContainer: ModelContainer
    let demoContainer: ModelContainer
    let demoModeEnabled: Bool
    let scenePhase: ScenePhase
    let recurrenceStatus: RecurrenceOperationStatus
    let scheduleRecurrenceRefresh: @MainActor (Bool) -> Void

    // Osserva lo stato di autenticazione per mostrare login / app.
    @ObservedObject private var auth = SupabaseManager.shared
    @ObservedObject private var syncService = SyncService.shared

    var body: some View {
        Group {
            if MoneyTrackerApp.isUITesting {
                uiTestView
            } else if auth.isLoading {
                // Splash — visibile solo per il tempo necessario a controllare
                // la sessione salvata nel Keychain (di solito < 0.5 s).
                splashView
            } else if !auth.isLoggedIn {
                LoginView()
            } else {
                // Face ID/Touch ID/passcode gate — applicato solo al contenuto
                // autenticato: protegge i dati finanziari già caricati quando
                // l'app torna in foreground, non la sola sessione Supabase.
                mainAppView
                    .appLockGate()
            }
        }
        .recurrenceErrorAlert(recurrenceStatus)
        .animation(.easeInOut(duration: 0.25), value: auth.isLoggedIn)
        // Login/restored session sync starts in mainAppView.task, after mounting
        // the active container. Logout never clears local data here.
        // Sync su lifecycle app (solo se loggato e non in demo).
        .onChange(of: scenePhase) { _, phase in
            switch phase {
            case .background:
                guard auth.isLoggedIn, !demoModeEnabled, !MoneyTrackerApp.isUITesting else { return }
                // Push quando l'app va in background — garantisce che i dati
                // siano su Supabase prima che l'utente chiuda l'app. Resiliente:
                // se fallisce (rete assente proprio ora), resta in coda e riparte
                // da solo al prossimo ritorno in foreground o al rientro della rete.
                Task { await SyncService.shared.pushResilient(context: realContainer.mainContext) }
            case .active:
                // Push resiliente (retry automatico con backoff se fallisce) e poi
                // pull solo se il push è andato a buon fine — vedi SyncService.syncOnForeground.
                scheduleRecurrenceRefresh(false)
            default:
                break
            }
        }
    }

    @ViewBuilder
    private var uiTestView: some View {
        #if DEBUG
        if E2EUITestHarness.isRequested {
            E2EUITestHarness()
        } else {
            mainAppView.appLockGate()
        }
        #else
        mainAppView.appLockGate()
        #endif
    }

    // MARK: - Splash

    private var splashView: some View {
        ZStack {
            DS.paper.ignoresSafeArea()
            VStack(spacing: DS.Space.m) {
                Image(systemName: "chart.pie.fill")
                    .scaledFont(size: 52, weight: .ultraLight)
                    .foregroundStyle(DS.ink)
                Text("MoneyTracker")
                    .scaledFont(size: 22, weight: .semibold)
                    .foregroundStyle(DS.ink)
            }
        }
    }

    // MARK: - Main app (utente loggato)

    private var mainAppView: some View {
        let activeContainer = demoModeEnabled ? demoContainer : realContainer

        return ZStack {
            VStack(spacing: 0) {
                // Il banner visibile è nell'overlay sopra le barre native.
                // Il segnaposto ne riserva l'altezza, anche alle taglie di accessibilità.
                if MoneyTrackerApp.usingVolatileStore {
                    volatileStoreBanner
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                }
                if demoModeEnabled && MoneyTrackerApp.usingVolatileStore {
                    demoBanner
                } else if demoModeEnabled {
                    demoBanner.hidden()
                        .fixedSize(horizontal: false, vertical: true)
                        .layoutPriority(1)
                        .zIndex(1)
                }
                ContentView()
                    .frame(maxHeight: .infinity)
                    .clipped()
            }
                .background(DS.paper)
                .modelContainer(activeContainer)
                .environment(\.accountModelContext, realContainer.mainContext)
                // .id() forza la ricreazione completa dell'albero di viste al cambio
                // di modalità, garantendo che @Query e @Environment siano agganciati
                // al container giusto senza residui del precedente.
                .id(demoModeEnabled ? "demo" : "real")
                // Indicatore di sync silenzioso — mai un alert: se la rete manca o il
                // cloud non risponde, l'utente vede "in corso"/"in sospeso", mai un
                // errore. Il retry automatico (SyncService) risolve da solo appena possibile.
                .overlay(alignment: .top) {
                    if !MoneyTrackerApp.usingVolatileStore {
                        if demoModeEnabled { demoBanner }
                        else { syncStatusBanner }
                    }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: syncService.status)
                .task(id: demoModeEnabled) {
                    scheduleRecurrenceRefresh(true)
                }
                .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                    scheduleRecurrenceRefresh(false)
                }
        }
        // Real-time sync: ogni volta che il real store salva, triggera un push
        // con debounce 1.5s. Così i dati arrivano su Supabase subito dopo l'inserimento.
        // Ignorato in demo mode (demoContainer ha il suo context separato).
        .onReceive(
            NotificationCenter.default.publisher(for: ModelContext.didSave)
                .receive(on: RunLoop.main)
        ) { notification in
            guard !demoModeEnabled, auth.isLoggedIn else { return }
            guard let ctx = notification.object as? ModelContext,
                  ctx === realContainer.mainContext else { return }
            // Registra QUALI transazioni sono cambiate in questo salvataggio, prima di
            // schedulare il push — permette a push() di caricare solo le righe toccate
            // invece dell'intera tabella (PROP-01, vedi SyncService.recordChanges).
            SyncService.shared.recordChanges(from: notification, context: ctx)
            SyncService.shared.schedulePush(context: realContainer.mainContext)
            // Registro immutabile di ogni creazione/modifica/cancellazione (PROP-02).
            AuditLogger.shared.record(from: notification, context: ctx)
        }
    }

    private var volatileStoreBanner: some View {
        Label {
            Text("Archivio non disponibile: chiudi e riapri l'app")
        } icon: {
            Image(systemName: "exclamationmark.triangle.fill")
        }
        .scaledFont(size: 13, weight: .semibold)
        .foregroundStyle(DS.plannedText)
        .padding(.horizontal, DS.Space.m)
        .padding(.vertical, DS.Space.s)
        .frame(maxWidth: .infinity)
        .background(DS.plannedSoft)
    }

    // MARK: - Demo banner

    @ViewBuilder private var demoBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .scaledFont(size: 10, weight: .bold)
            Text("MODALITÀ DEMO", comment: "Demo mode banner label")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .kerning(0.5)
        }
        .foregroundStyle(DS.plannedText)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(DS.plannedSoft, in: Capsule())
        .shadow(color: DS.ink.opacity(0.12), radius: 6, y: 2)
        .padding(.vertical, 4)
        .allowsHitTesting(false)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: demoModeEnabled)
    }

    // MARK: - Sync status banner
    //
    // Deliberatamente minimale e mai rosso/allarmante: anche "in sospeso" (retry
    // pianificato) è comunicato come stato normale, non come errore dell'utente.

    @ViewBuilder private var syncStatusBanner: some View {
        if let (icon, label, showSpinner) = syncStatusContent {
            HStack(spacing: 6) {
                if showSpinner {
                    ProgressView().tint(DS.paper).scaleEffect(0.65)
                } else {
                    Image(systemName: icon)
                        .scaledFont(size: 10, weight: .semibold)
                }
                Text(label)
                    .scaledFont(size: 11, weight: .medium)
            }
            .foregroundStyle(DS.paper)
            .padding(.horizontal, 12)
            .padding(.vertical, 5)
            .background(DS.ink.opacity(0.85), in: Capsule())
            .shadow(color: .black.opacity(0.14), radius: 5, y: 2)
            .padding(.top, 8)
            .allowsHitTesting(false)
            .transition(.move(edge: .top).combined(with: .opacity))
        }
    }

    private var syncStatusContent: (icon: String, label: String, showSpinner: Bool)? {
        switch syncService.status {
        case .idle:
            return nil
        case .syncing:
            return ("", String(localized: "Sincronizzazione…"), true)
        case .waitingForRetry:
            return ("clock.arrow.circlepath", String(localized: "Sincronizzazione in sospeso"), false)
        case .offline:
            return ("wifi.slash", String(localized: "Offline — riprenderà automaticamente"), false)
        }
    }
}

// MARK: - File protection helper

/// Applica la protezione crittografica al file SQLite + WAL + SHM indicati dall'URL.
/// Silenziosamente ignora i file non ancora esistenti (es. al primo avvio).
private func applyFileProtection(to url: URL, level: FileProtectionType) {
    for ext in ["", "-wal", "-shm"] {
        let path = url.path + ext
        guard FileManager.default.fileExists(atPath: path) else { continue }
        try? FileManager.default.setAttributes([.protectionKey: level], ofItemAtPath: path)
    }
}
