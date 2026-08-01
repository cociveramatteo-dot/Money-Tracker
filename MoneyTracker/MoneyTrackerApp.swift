import SwiftUI
import SwiftData
import Combine

@main
struct MoneyTrackerApp: App {

    let realContainer: ModelContainer
    let demoContainer: ModelContainer

    @AppStorage("demoModeEnabled") private var demoModeEnabled = false
    // Tour overlay is rendered HERE (app level) so it sits above UITabBarController
    // and UITabBar — the only z-position from which the tab bar can be highlighted.
    @ObservedObject private var tourManager = TourManager.shared

    // MARK: - UI testing hook
    //
    // XCUITest lancia l'app con l'argomento "--uitesting" (vedi MoneyTrackerUITests/UITestLaunchHelper.swift).
    // In questo modo bypassiamo login Supabase/Face ID e forziamo la modalità demo,
    // ottenendo dati deterministici senza chiamate di rete durante i test.
    static var isUITesting: Bool {
        ProcessInfo.processInfo.arguments.contains("--uitesting")
    }

    // MARK: - Init

    init() {
        if Self.isUITesting {
            UserDefaults.standard.set(true, forKey: "demoModeEnabled")
            UserDefaults.standard.set(false, forKey: "appLockEnabled")
            UserDefaults.standard.set(true, forKey: "notificationsEnabled")
            // Il tour di onboarding (panoramica + mini-tour contestuali) intercetterebbe
            // i tap degli XCUITest: vanno marcati come già visti così i test partono
            // direttamente sull'app, senza dover gestire nessun overlay del tour.
            UserDefaults.standard.set(true, forKey: "onboarding.tour.overview.completed.v1")
            for hint in ContextualHint.allCases {
                UserDefaults.standard.set(true, forKey: "hint.\(hint.rawValue).seen")
            }
            UserDefaults.standard.set(true, forKey: "hint.settings.seen")
        }

        // Schema(versionedSchema:) invece di Schema([...]): necessario perché
        // MoneyTrackerMigrationPlan sappia riconoscere/convertire uno store SchemaV1
        // (importi Double) esistente verso SchemaV2 (Decimal). Vedi Domain/SchemaMigration.swift.
        let schema = Schema(versionedSchema: SchemaV2.self)

        let realConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // cloudKitDatabase: .automatic   ← decommentare dopo aver abilitato iCloud
        )

        FormatterCache.registerLocaleObserver()

        do {
            realContainer = try ModelContainer(
                for: schema,
                migrationPlan: MoneyTrackerMigrationPlan.self,
                configurations: realConfig
            )

            // SEC-02: protezione crittografica del db reale
            applyFileProtection(to: realConfig.url, level: .complete)

            let ctx = realContainer.mainContext
            Category.seedIfNeeded(context: ctx)

            let notifEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") == nil
            if notifEnabled { SystemNotificationManager.shared.requestPermission() }
            SystemNotificationManager.shared.scheduleFixedReminderIfNeeded(context: ctx)

        } catch {
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
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            demoContainer = (try? ModelContainer(for: schema, configurations: fallback))
                ?? realContainer
        }
    }

    // Osserva lo stato di autenticazione per mostrare login / app.
    @ObservedObject private var auth = SupabaseManager.shared
    @ObservedObject private var syncService = SyncService.shared
    // Permette di rilevare quando l'app va in background o torna in foreground.
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if Self.isUITesting {
                    // Bypassa login/splash: gli XCUITest devono partire già dentro
                    // l'app, su dati demo deterministici, senza rete.
                    mainAppView
                        .appLockGate()
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
            .animation(.easeInOut(duration: 0.25), value: auth.isLoggedIn)
            // Sync al login / logout.
            .onChange(of: auth.isLoggedIn) { _, loggedIn in
                if loggedIn {
                    guard !demoModeEnabled else { return }
                    Task { await SyncService.shared.syncOnLogin(context: realContainer.mainContext) }
                } else {
                    // Logout: svuota subito il real store locale.
                    // Così il prossimo utente che accede non vede i dati del precedente.
                    SyncService.shared.clearLocalData(context: realContainer.mainContext)
                }
            }
            // Sync su lifecycle app (solo se loggato e non in demo).
            .onChange(of: scenePhase) { _, phase in
                guard auth.isLoggedIn, !demoModeEnabled else { return }
                switch phase {
                case .background:
                    // Push quando l'app va in background — garantisce che i dati
                    // siano su Supabase prima che l'utente chiuda l'app. Resiliente:
                    // se fallisce (rete assente proprio ora), resta in coda e riparte
                    // da solo al prossimo ritorno in foreground o al rientro della rete.
                    Task { await SyncService.shared.pushResilient(context: realContainer.mainContext) }
                case .active:
                    // Push resiliente (retry automatico con backoff se fallisce) e poi
                    // pull solo se il push è andato a buon fine — vedi SyncService.syncOnForeground.
                    Task { await SyncService.shared.syncOnForeground(context: realContainer.mainContext) }
                default:
                    break
                }
            }
        }
    }

    // MARK: - Splash

    private var splashView: some View {
        ZStack {
            DS.paper.ignoresSafeArea()
            VStack(spacing: DS.Space.m) {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 52, weight: .ultraLight))
                    .foregroundStyle(DS.ink)
                Text("MoneyTracker")
                    .font(.system(size: 22, weight: .semibold))
                    .foregroundStyle(DS.ink)
            }
        }
    }

    // MARK: - Main app (utente loggato)

    private var mainAppView: some View {
        let activeContainer = demoModeEnabled ? demoContainer : realContainer

        return ZStack {
            ContentView()
                .modelContainer(activeContainer)
                // .id() forza la ricreazione completa dell'albero di viste al cambio
                // di modalità, garantendo che @Query e @Environment siano agganciati
                // al container giusto senza residui del precedente.
                .id(demoModeEnabled ? "demo" : "real")
                // Banner "DEMO" — in cima, sotto la status bar / Dynamic Island.
                .overlay(alignment: .top) {
                    if demoModeEnabled { demoBanner }
                }
                // Indicatore di sync silenzioso — mai un alert: se la rete manca o il
                // cloud non risponde, l'utente vede "in corso"/"in sospeso", mai un
                // errore. Il retry automatico (SyncService) risolve da solo appena possibile.
                .overlay(alignment: .top) {
                    if !demoModeEnabled { syncStatusBanner }
                }
                .animation(.spring(response: 0.4, dampingFraction: 0.75), value: syncService.status)
                .task {
                    // Il seeding demo avviene in init() — qui processiamo solo le ricorrenti.
                    // PERF-05: gira su un @ModelActor in background, non sul main actor,
                    // così il primo render dopo il login non aspetta il fetch+confronto+save.
                    let engine = RecurringTransactionActor(modelContainer: activeContainer)
                    await engine.processRecurring()
                }
                // .task sopra parte solo al primo montaggio della view (o al cambio
                // demo/reale via .id) — se l'app resta viva in background e torna in
                // foreground senza restart, non veniva mai rieseguito. Risultato: le
                // ricorrenti del mese nuovo non comparivano finché l'utente non
                // chiudeva e riapriva l'app da zero. La guardia giornaliera dentro
                // processRecurring() rende sicuro rilanciarlo a ogni ritorno attivo.
                .onChange(of: scenePhase) { _, phase in
                    guard phase == .active else { return }
                    Task {
                        let engine = RecurringTransactionActor(modelContainer: activeContainer)
                        await engine.processRecurring()
                    }
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
        // Tour overlay — collects .tourAnchor() preferences from all descendants
        // and renders the spotlight ABOVE everything including UITabBar.
        .onChange(of: tourManager.isActive) { _, active in
            guard active else { return }
            DemoDataSeeder.forceReset(context: demoContainer.mainContext)
        }
        .overlayPreferenceValue(TourAnchorKey.self) { anchors in
            // I mini-tour contestuali (Livello 2) vivono in questa stessa view ma
            // scattano DOPO che la panoramica è finita (isActive == false) — vanno
            // montati anche in quel caso, altrimenti activeHint non ha mai una view
            // che lo disegni e "Ho capito" non si vede mai.
            if tourManager.isActive || tourManager.activeHint != nil {
                TourOverlayView(anchors: anchors)
                    .ignoresSafeArea()
                    .transition(.opacity)
            }
        }
    }

    // MARK: - Demo banner

    @ViewBuilder private var demoBanner: some View {
        HStack(spacing: 6) {
            Image(systemName: "eye.fill")
                .font(.system(size: 10, weight: .bold))
            Text("MODALITÀ DEMO", comment: "Demo mode banner label")
                .font(.system(size: 11, weight: .bold, design: .monospaced))
                .kerning(0.5)
        }
        .foregroundStyle(.white)
        .padding(.horizontal, 12)
        .padding(.vertical, 5)
        .background(Color.orange.opacity(0.92), in: Capsule())
        .shadow(color: .black.opacity(0.18), radius: 6, y: 2)
        .padding(.top, 8) // dentro la safe area top, sotto Dynamic Island / notch
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
                        .font(.system(size: 10, weight: .semibold))
                }
                Text(label)
                    .font(.system(size: 11, weight: .medium))
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
