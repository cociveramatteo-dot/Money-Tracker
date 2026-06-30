import SwiftUI
import SwiftData

@main
struct MoneyTrackerApp: App {

    let realContainer: ModelContainer
    let demoContainer: ModelContainer

    @StateObject  private var themeManager = ThemeManager()
    @AppStorage("demoModeEnabled") private var demoModeEnabled = false
    // Tour overlay is rendered HERE (app level) so it sits above UITabBarController
    // and UITabBar — the only z-position from which the tab bar can be highlighted.
    @ObservedObject private var tourManager = TourManager.shared

    // MARK: - Init

    init() {
        let schema = Schema([
            Account.self,
            Transaction.self,
            Budget.self,
            Goal.self,
            Category.self
        ])

        let realConfig = ModelConfiguration(
            schema: schema,
            isStoredInMemoryOnly: false
            // cloudKitDatabase: .automatic   ← decommentare dopo aver abilitato iCloud
        )

        FormatterCache.registerLocaleObserver()

        do {
            realContainer = try ModelContainer(for: schema, configurations: realConfig)

            // SEC-02: protezione crittografica del db reale
            applyFileProtection(to: realConfig.url, level: .complete)

            let ctx = realContainer.mainContext
            Category.seedIfNeeded(context: ctx)

            let notifEnabled = UserDefaults.standard.object(forKey: "notificationsEnabled") == nil
            if notifEnabled { NotificationManager.shared.requestPermission() }
            NotificationManager.shared.scheduleFixedReminderIfNeeded(context: ctx)

        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            realContainer = (try? ModelContainer(for: schema, configurations: fallback))
                ?? { fatalError("Impossibile creare ModelContainer: \(error)") }()
        }

        // "demo" come nome → SwiftData crea demo.store nella sua cartella standard.
        // url è una proprietà read-only calcolata da ModelConfiguration, non un parametro init.
        let demoConfig = ModelConfiguration("demo", schema: schema, isStoredInMemoryOnly: false)

        do {
            demoContainer = try ModelContainer(for: schema, configurations: demoConfig)
            // Proteggi il file demo (accessibile dopo il primo sblocco post-riavvio)
            applyFileProtection(to: demoConfig.url, level: .completeUntilFirstUserAuthentication)
            let demoCtx = demoContainer.mainContext
            Category.seedIfNeeded(context: demoCtx)
            // Semina tutti i dati demo subito in init() — in modo sincrono, prima che
            // qualsiasi @Query si abboni al container. Così quando l'utente attiva la
            // modalità demo i dati sono già presenti e non serve nessun .task asincrono.
            DemoDataSeeder.seedIfNeeded(context: demoCtx)
        } catch {
            // Fallback sicuro: in-memory (la demo funziona ma non persiste tra i lanci)
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            demoContainer = (try? ModelContainer(for: schema, configurations: fallback))
                ?? realContainer
        }
    }

    // Osserva lo stato di autenticazione per mostrare login / app.
    @ObservedObject private var auth = SupabaseManager.shared
    // Permette di rilevare quando l'app va in background o torna in foreground.
    @Environment(\.scenePhase) private var scenePhase

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    // Splash — visibile solo per il tempo necessario a controllare
                    // la sessione salvata nel Keychain (di solito < 0.5 s).
                    splashView
                } else if !auth.isLoggedIn {
                    LoginView()
                        .environmentObject(themeManager)
                        .preferredColorScheme(themeManager.current.preferredColorScheme)
                } else {
                    mainAppView
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
                    // siano su Supabase prima che l'utente chiuda l'app.
                    Task { await SyncService.shared.push(context: realContainer.mainContext) }
                case .active:
                    // Prima push: assicura che Supabase abbia i dati più recenti.
                    // Poi pull (se passati ≥5 min): porta eventuali modifiche da altri dispositivi.
                    // L'ordine push→pull è fondamentale: evita che il pull cancelli dati
                    // locali non ancora caricati su Supabase.
                    Task {
                        await SyncService.shared.push(context: realContainer.mainContext)
                        if SyncService.shared.shouldPull {
                            await SyncService.shared.pull(context: realContainer.mainContext)
                        }
                    }
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
                .environmentObject(themeManager)
                .modelContainer(activeContainer)
                .preferredColorScheme(themeManager.current.preferredColorScheme)
                // .id() forza la ricreazione completa dell'albero di viste al cambio
                // di modalità, garantendo che @Query e @Environment siano agganciati
                // al container giusto senza residui del precedente.
                .id(demoModeEnabled ? "demo" : "real")
                // Banner "DEMO" — in cima, sotto la status bar / Dynamic Island.
                .overlay(alignment: .top) {
                    if demoModeEnabled { demoBanner }
                }
                .task {
                    // Il seeding demo avviene in init() — qui processiamo solo le ricorrenti.
                    Transaction.processRecurring(context: activeContainer.mainContext)
                }
        }
        // Real-time sync: ogni volta che il real store salva, triggera un push
        // con debounce 1.5s. Così i dati arrivano su Supabase subito dopo l'inserimento.
        // Ignorato in demo mode (demoContainer ha il suo context separato).
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { notification in
            guard !demoModeEnabled, auth.isLoggedIn else { return }
            guard let ctx = notification.object as? ModelContext,
                  ctx === realContainer.mainContext else { return }
            SyncService.shared.schedulePush(context: realContainer.mainContext)
        }
        // Tour overlay — collects .tourAnchor() preferences from all descendants
        // and renders the spotlight ABOVE everything including UITabBar.
        .onChange(of: tourManager.isActive) { _, active in
            guard active else { return }
            DemoDataSeeder.forceReset(context: demoContainer.mainContext)
        }
        .overlayPreferenceValue(TourAnchorKey.self) { anchors in
            if tourManager.isActive {
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
