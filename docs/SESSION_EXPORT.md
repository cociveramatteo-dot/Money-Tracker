# MoneyTracker — Session Export Document

---

```yaml
---
title: "MoneyTracker iOS — Session Export"
date: 2026-07-03
stato: "In sviluppo attivo — Auth + Sync completati, tema sistema implementato"
progetto: "MoneyTracker — App iOS finanza personale"
tecnologie: [SwiftUI, SwiftData, Supabase, AltStore]
repository: "https://github.com/cociveramatteo-dot/Money-Tracker"
supabase_url: "https://zblpzufsikxhuzdtcucg.supabase.co"
url_scheme: "moneytracker://login-callback"
---
```

---

## 1. INDICE DEI MODULI AFFRONTATI

1. **MoneyTracker iOS App** — app finanza personale in SwiftUI + SwiftData
2. **Phase 1 — Auth Gate** — login/registrazione email+password con Supabase
3. **Phase 2 — Sync Service** — sincronizzazione bidirezionale SwiftData ↔ Supabase
4. **Sistema Tema** — semplificato a solo chiaro/scuro automatico da sistema iOS
5. **Deep Link** — gestione link email Supabase (conferma account, reset password)
6. **AltStore** — sideloading senza Apple Developer Program (evita €99/anno)
7. **GitHub Checkpoint** — repository remoto configurato e aggiornato

---

## 2. CONTESTO E DECISIONI ARCHITETTURALI

### MoneyTracker iOS App
App di finanza personale per uso personale su iPhone. Stack:
- **SwiftUI** per l'interfaccia
- **SwiftData** per la persistenza locale (modelli: `Account`, `Transaction`, `Budget`, `Goal`, `Category`)
- **Due container separati**: `realContainer` (dati reali) e `demoContainer` (dati demo, mai sincronizzati)
- **Design System (DS)**: colori semantici `ink`, `paper`, `fog`, `smoke` — derivati dal tema attivo
- La demo mode è attivabile da Impostazioni e mostra dati fittizi senza toccare i dati reali

### Phase 1 — Auth Gate
- **Backend scelto**: Supabase (open source, piano gratuito sufficiente)
- **Metodo**: Email + Password (Sign in with Apple e Google rimandate — richiedono Apple Developer Program o Google Cloud)
- **Pattern**: splash → login → app principale, guidato da `SupabaseManager.isLoggedIn`
- **Sessione**: persistita nel Keychain iOS tramite SDK Supabase

### Phase 2 — Sync Service
- **Isolamento multi-utente**: al logout i dati locali vengono cancellati immediatamente; al login si verifica se l'utente è cambiato (via `lastUserKey` in UserDefaults) e si cancella prima di sincronizzare
- **Prima sync al login** (`syncOnLogin`): se Supabase è vuoto → push (dati locali al cloud); se ha dati → pull (cloud è fonte di verità)
- **Sync real-time**: `ModelContext.didSave` notification + debounce 1.5s → push automatico dopo ogni inserimento/modifica
- **Sync lifecycle**: foreground → push poi pull (se ≥5 min dall'ultimo); background → push
- **Guard anti-cancellazione**: in `pull()`, se Supabase è vuoto ma il locale ha dati, si interrompe (evita di cancellare dati non ancora caricati)
- **RLS (Row Level Security)**: tutte le tabelle Supabase filtrano per `auth.uid() = user_id` — sicurezza lato server

### Sistema Tema
- **Decisione**: eliminati tutti i temi colorati (Foresta, Oceano, Rosso, Rosa, ecc.) — rimasti solo `classico` (chiaro) e `notte` (scuro)
- **Automatico**: il tema segue il sistema iOS — nessun bottone manuale, nessun picker
- **Implementazione**: `@Environment(\.colorScheme)` in MoneyTrackerApp → `ThemeManager.set()` → `DS.invalidateThemeCache(theme)` (passa il tema direttamente, NON legge UserDefaults)
- **Bug risolto**: `DS.invalidateThemeCache()` leggeva UserDefaults dove il tema non veniva più salvato → ora riceve il tema come parametro diretto

### Deep Link
- **URL Scheme**: `moneytracker` registrato in Xcode → Info → URL Types
- **Redirect URL**: `moneytracker://login-callback` configurata in Supabase Dashboard → Authentication → URL Configuration
- **Gestione**: `.onOpenURL` in MoneyTrackerApp → `client.auth.session(from: url)`

### AltStore
- AltServer (Mac) + AltStore (iPhone) installati
- MoneyTracker installato via IPA manuale (derivato da DerivedData dopo `cmd+R`)
- Rinnovo automatico ogni 7 giorni via WiFi con AltServer attivo
- **Limite account gratuito**: max 3 app installate via AltStore contemporaneamente

---

## 3. CONFIGURAZIONI ESTERNE

### Supabase
- **Project URL**: `https://zblpzufsikxhuzdtcucg.supabase.co`
- **Anon Key**: `eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibHB6dWZzaWt4aHV6ZHRjdWNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MTE1MzcsImV4cCI6MjA5ODM4NzUzN30.lezj5CD6yYjSK2-HeGSjU1kaE29G3B_ojiFhSz-8pgg`
- **Authentication → URL Configuration → Site URL**: `moneytracker://login-callback`
- **Redirect URLs**: `moneytracker://login-callback`
- **Rate Limits**: aumentati per sviluppo (ricordare di ripristinarli prima del rilascio)

### GitHub
- **Repository**: `https://github.com/cociveramatteo-dot/Money-Tracker`
- **Branch**: `main`
- **Ultimo commit**: "sistema account"
- **Autenticazione**: Personal Access Token (non password — GitHub non accetta più le password per git push)

---

## 4. ARCHIVIO CODICE DEFINITIVO

---

### `MoneyTracker/MoneyTrackerApp.swift`

```swift
import SwiftUI
import SwiftData
import Supabase

@main
struct MoneyTrackerApp: App {

    let realContainer: ModelContainer
    let demoContainer: ModelContainer

    @StateObject  private var themeManager = ThemeManager()
    @AppStorage("demoModeEnabled") private var demoModeEnabled = false
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
        )

        FormatterCache.registerLocaleObserver()

        do {
            realContainer = try ModelContainer(for: schema, configurations: realConfig)
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

        let demoConfig = ModelConfiguration("demo", schema: schema, isStoredInMemoryOnly: false)

        do {
            demoContainer = try ModelContainer(for: schema, configurations: demoConfig)
            applyFileProtection(to: demoConfig.url, level: .completeUntilFirstUserAuthentication)
            let demoCtx = demoContainer.mainContext
            Category.seedIfNeeded(context: demoCtx)
            DemoDataSeeder.seedIfNeeded(context: demoCtx)
        } catch {
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            demoContainer = (try? ModelContainer(for: schema, configurations: fallback))
                ?? realContainer
        }
    }

    @ObservedObject private var auth = SupabaseManager.shared
    @Environment(\.scenePhase) private var scenePhase
    @Environment(\.colorScheme) private var colorScheme

    // MARK: - Body

    var body: some Scene {
        WindowGroup {
            Group {
                if auth.isLoading {
                    splashView
                } else if !auth.isLoggedIn {
                    LoginView()
                        .environmentObject(themeManager)
                } else {
                    mainAppView
                }
            }
            .animation(.easeInOut(duration: 0.25), value: auth.isLoggedIn)
            .preferredColorScheme(themeManager.current == .notte ? .dark : .light)
            .onChange(of: colorScheme, initial: true) { _, scheme in
                themeManager.set(scheme == .dark ? .notte : .classico)
            }
            .onOpenURL { url in
                Task {
                    try? await SupabaseManager.shared.client.auth.session(from: url)
                }
            }
            .onChange(of: auth.isLoggedIn) { _, loggedIn in
                if loggedIn {
                    guard !demoModeEnabled else { return }
                    Task { await SyncService.shared.syncOnLogin(context: realContainer.mainContext) }
                } else {
                    SyncService.shared.clearLocalData(context: realContainer.mainContext)
                }
            }
            .onChange(of: scenePhase) { _, phase in
                guard auth.isLoggedIn, !demoModeEnabled else { return }
                switch phase {
                case .background:
                    Task { await SyncService.shared.push(context: realContainer.mainContext) }
                case .active:
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

    // MARK: - Main app

    private var mainAppView: some View {
        let activeContainer = demoModeEnabled ? demoContainer : realContainer

        return ZStack {
            ContentView()
                .environmentObject(themeManager)
                .modelContainer(activeContainer)
                .id(demoModeEnabled ? "demo" : "real")
                .overlay(alignment: .top) {
                    if demoModeEnabled { demoBanner }
                }
                .task {
                    Transaction.processRecurring(context: activeContainer.mainContext)
                }
        }
        .onReceive(NotificationCenter.default.publisher(for: ModelContext.didSave)) { notification in
            guard !demoModeEnabled, auth.isLoggedIn else { return }
            guard let ctx = notification.object as? ModelContext,
                  ctx === realContainer.mainContext else { return }
            SyncService.shared.schedulePush(context: realContainer.mainContext)
        }
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
        .padding(.top, 8)
        .allowsHitTesting(false)
        .transition(.move(edge: .top).combined(with: .opacity))
        .animation(.spring(response: 0.4, dampingFraction: 0.75), value: demoModeEnabled)
    }
}

// MARK: - File protection helper

private func applyFileProtection(to url: URL, level: FileProtectionType) {
    for ext in ["", "-wal", "-shm"] {
        let path = url.path + ext
        guard FileManager.default.fileExists(atPath: path) else { continue }
        try? FileManager.default.setAttributes([.protectionKey: level], ofItemAtPath: path)
    }
}
```

---

### `MoneyTracker/Auth/SupabaseManager.swift`

```swift
import Foundation
import Combine
import Supabase

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://zblpzufsikxhuzdtcucg.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibHB6dWZzaWt4aHV6ZHRjdWNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MTE1MzcsImV4cCI6MjA5ODM4NzUzN30.lezj5CD6yYjSK2-HeGSjU1kaE29G3B_ojiFhSz-8pgg"
    )

    @Published var session: Session? = nil
    @Published var isLoading = true

    private init() {
        Task { await bootstrap() }
    }

    private func bootstrap() async {
        session = try? await client.auth.session
        isLoading = false
        for await (_, newSession) in client.auth.authStateChanges {
            session = newSession
        }
    }

    var isLoggedIn: Bool { session != nil }
    var userEmail: String? { session?.user.email }

    private static let redirectURL = URL(string: "moneytracker://login-callback")!

    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password,
                                     redirectTo: Self.redirectURL)
    }

    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    func signOut() async throws {
        try await client.auth.signOut()
    }

    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email,
                                                    redirectTo: Self.redirectURL)
    }
}
```

---

### `MoneyTracker/Auth/LoginView.swift`

```swift
import SwiftUI

struct LoginView: View {

    @ObservedObject private var auth = SupabaseManager.shared

    @State private var email           = ""
    @State private var password        = ""
    @State private var isLoading       = false
    @State private var errorMessage: String? = nil
    @State private var showSignUp      = false
    @State private var showReset       = false
    @State private var resetEmail      = ""
    @State private var resetSent       = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    heroSection
                    formSection
                    errorSection
                    loginButton
                    forgotButton
                    divider
                    signUpButton
                    Spacer(minLength: 48)
                }
            }
            .background(DS.paper)
            .scrollBounceBehavior(.basedOnSize)
            .navigationDestination(isPresented: $showSignUp) {
                SignUpView()
            }
            .alert("Reimposta password", isPresented: $showReset) {
                TextField("Email", text: $resetEmail)
                    .keyboardType(.emailAddress)
                    .autocorrectionDisabled()
                Button("Invia link") { Task { await sendReset() } }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text(resetSent
                     ? "Email inviata! Controlla la tua casella."
                     : "Inserisci la tua email e ti mandiamo un link per reimpostare la password.")
            }
        }
    }

    private var heroSection: some View {
        VStack(spacing: DS.Space.m) {
            Image(systemName: "chart.pie.fill")
                .font(.system(size: 52, weight: .ultraLight))
                .foregroundStyle(DS.ink)
            Text("MoneyTracker")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DS.ink)
            Text("Accedi per continuare")
                .font(.system(size: 15))
                .foregroundStyle(DS.smoke)
        }
        .padding(.top, 64)
        .padding(.bottom, 48)
    }

    private var formSection: some View {
        VStack(spacing: DS.Space.m) {
            AuthField(label: "Email",
                      placeholder: "nome@email.com",
                      text: $email,
                      keyboardType: .emailAddress)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Password")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.smoke)
                SecureField("••••••••", text: $password)
                    .padding(14)
                    .background(DS.fog)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(DS.ink)
            }
        }
        .padding(.horizontal, DS.Layout.margin)
    }

    @ViewBuilder private var errorSection: some View {
        if let msg = errorMessage {
            Text(msg)
                .font(.system(size: 13))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.m)
        }
    }

    private var loginButton: some View {
        Button { Task { await signIn() } } label: {
            ZStack {
                if isLoading {
                    ProgressView().tint(DS.paper)
                } else {
                    Text("Accedi")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.paper)
                }
            }
            .frame(maxWidth: .infinity)
            .frame(height: 50)
            .background(canSubmit ? DS.ink : DS.fog)
            .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .disabled(!canSubmit || isLoading)
        .padding(.horizontal, DS.Layout.margin)
        .padding(.top, DS.Space.l)
        .animation(.easeInOut(duration: 0.15), value: canSubmit)
    }

    private var forgotButton: some View {
        Button {
            resetEmail = email
            showReset  = true
        } label: {
            Text("Password dimenticata?")
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
        }
        .padding(.top, DS.Space.m)
    }

    private var divider: some View {
        HStack(spacing: 0) {
            Rectangle().fill(DS.fog).frame(height: 1)
            Text("oppure")
                .font(.system(size: 12))
                .foregroundStyle(DS.smoke)
                .padding(.horizontal, 12)
            Rectangle().fill(DS.fog).frame(height: 1)
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.vertical, DS.Space.l)
    }

    private var signUpButton: some View {
        Button { showSignUp = true } label: {
            Text("Crea un account")
                .font(.system(size: 16, weight: .medium))
                .foregroundStyle(DS.ink)
                .frame(maxWidth: .infinity)
                .frame(height: 50)
                .background(DS.fog)
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
        .padding(.horizontal, DS.Layout.margin)
    }

    private var canSubmit: Bool { !email.isEmpty && !password.isEmpty }

    private func signIn() async {
        isLoading    = true
        errorMessage = nil
        do {
            try await auth.signIn(email: email, password: password)
        } catch {
            errorMessage = authError(error)
        }
        isLoading = false
    }

    private func sendReset() async {
        guard !resetEmail.isEmpty else { return }
        try? await auth.resetPassword(email: resetEmail)
        resetSent = true
    }

    private func authError(_ error: Error) -> String {
        let raw = error.localizedDescription.lowercased()
        if raw.contains("invalid login") || raw.contains("invalid credentials") || raw.contains("invalid email or password") {
            return "Email o password non corretti."
        }
        if raw.contains("email not confirmed") { return "Conferma la tua email prima di accedere." }
        if raw.contains("rate limit") || raw.contains("too many") { return "Troppi tentativi. Aspetta qualche minuto e riprova." }
        if raw.contains("network") || raw.contains("connection") { return "Nessuna connessione. Controlla la rete e riprova." }
        return "Errore: \(error.localizedDescription)"
    }
}

// MARK: - AuthField

struct AuthField: View {
    let label: String
    let placeholder: String
    @Binding var text: String
    var keyboardType: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text(label)
                .font(.system(size: 12, weight: .medium))
                .foregroundStyle(DS.smoke)
            TextField(placeholder, text: $text)
                .keyboardType(keyboardType)
                .autocorrectionDisabled()
                .textInputAutocapitalization(.never)
                .padding(14)
                .background(DS.fog)
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .foregroundStyle(DS.ink)
        }
    }
}
```

---

### `MoneyTracker/Auth/SignUpView.swift`

```swift
import SwiftUI

struct SignUpView: View {

    @ObservedObject private var auth = SupabaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var isLoading       = false
    @State private var errorMessage: String?   = nil
    @State private var successMessage: String? = nil

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                heroSection
                formSection
                feedbackSection
                registerButton
                Spacer(minLength: 48)
            }
        }
        .background(DS.paper)
        .scrollBounceBehavior(.basedOnSize)
        .navigationTitle("Crea account")
        .navigationBarTitleDisplayMode(.inline)
    }

    private var heroSection: some View {
        VStack(spacing: DS.Space.s) {
            Text("Benvenuto")
                .font(.system(size: 28, weight: .semibold))
                .foregroundStyle(DS.ink)
            Text("Crea il tuo account per iniziare")
                .font(.system(size: 15))
                .foregroundStyle(DS.smoke)
        }
        .padding(.top, 40)
        .padding(.bottom, 36)
    }

    private var formSection: some View {
        VStack(spacing: DS.Space.m) {
            AuthField(label: "Email", placeholder: "nome@email.com", text: $email, keyboardType: .emailAddress)
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Password").font(.system(size: 12, weight: .medium)).foregroundStyle(DS.smoke)
                SecureField("Minimo 6 caratteri", text: $password)
                    .padding(14).background(DS.fog).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(DS.ink)
            }
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Conferma password").font(.system(size: 12, weight: .medium)).foregroundStyle(DS.smoke)
                SecureField("Ripeti la password", text: $confirmPassword)
                    .padding(14).background(DS.fog).clipShape(RoundedRectangle(cornerRadius: 10)).foregroundStyle(DS.ink)
                if !confirmPassword.isEmpty && confirmPassword != password {
                    Text("Le password non coincidono").font(.system(size: 11)).foregroundStyle(.red).padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
    }

    @ViewBuilder private var feedbackSection: some View {
        if let msg = errorMessage {
            Text(msg).font(.system(size: 13)).foregroundStyle(.red)
                .multilineTextAlignment(.center).padding(.horizontal, DS.Layout.margin).padding(.top, DS.Space.m)
        }
        if let msg = successMessage {
            VStack(spacing: DS.Space.s) {
                Image(systemName: "envelope.badge.checkmark.fill").font(.system(size: 32)).foregroundStyle(.green)
                Text(msg).font(.system(size: 14)).foregroundStyle(DS.smoke).multilineTextAlignment(.center)
                Button("Torna al login") { dismiss() }
                    .font(.system(size: 15, weight: .medium)).foregroundStyle(DS.ink).padding(.top, DS.Space.s)
            }
            .padding(.horizontal, DS.Layout.margin).padding(.top, DS.Space.xl)
        }
    }

    @ViewBuilder private var registerButton: some View {
        if successMessage == nil {
            Button { Task { await signUp() } } label: {
                ZStack {
                    if isLoading { ProgressView().tint(DS.paper) }
                    else { Text("Registrati").font(.system(size: 16, weight: .semibold)).foregroundStyle(DS.paper) }
                }
                .frame(maxWidth: .infinity).frame(height: 50)
                .background(canSubmit ? DS.ink : DS.fog)
                .clipShape(RoundedRectangle(cornerRadius: 12))
            }
            .disabled(!canSubmit || isLoading)
            .padding(.horizontal, DS.Layout.margin).padding(.top, DS.Space.l)
            .animation(.easeInOut(duration: 0.15), value: canSubmit)
        }
    }

    private var canSubmit: Bool { !email.isEmpty && password.count >= 6 && password == confirmPassword }

    private func signUp() async {
        isLoading = true; errorMessage = nil; successMessage = nil
        do {
            try await auth.signUp(email: email, password: password)
            if !auth.isLoggedIn {
                successMessage = "Account creato! Controlla la tua email e clicca il link di conferma per accedere."
            }
        } catch { errorMessage = signUpError(error) }
        isLoading = false
    }

    private func signUpError(_ error: Error) -> String {
        let raw = error.localizedDescription.lowercased()
        if raw.contains("already registered") || raw.contains("already exists") { return "Esiste già un account con questa email." }
        if raw.contains("password") && raw.contains("6") { return "La password deve avere almeno 6 caratteri." }
        if raw.contains("invalid email") { return "Indirizzo email non valido." }
        if raw.contains("rate limit") || raw.contains("too many") { return "Troppi tentativi. Aspetta qualche minuto e riprova." }
        return "Errore: \(error.localizedDescription)"
    }
}
```

---

### `MoneyTracker/Sync/SyncService.swift`

> **Nota**: File lungo (~500 righe). Di seguito la struttura completa con le parti chiave. Il file su disco è la versione definitiva.

**Sezioni principali:**
- DTOs privati Codable: `SBAccount`, `SBTransaction`, `SBBudget`, `SBGoal` (con CodingKeys snake_case)
- `syncOnLogin(context:)` — prima sync: controlla lastUserKey, eventuale clearLocalData, poi push se vuoto / pull se ha dati
- `schedulePush(context:)` — debounce 1.5s, chiamato da `ModelContext.didSave`
- `push(context:)` — upsert tutti i 4 modelli + deleteOrphans
- `pull(context:)` — fetch da Supabase, upsert locale, cancella orfani locali (con guard: se remoto vuoto e locale ha dati, skip)
- `clearLocalData(context:)` — cancella Transaction, Budget, Goal, Account in ordine (cascade); chiamato al logout
- `shouldPull: Bool` — true se ≥5 min dall'ultimo pull (UserDefaults key: `syncService.lastPull`)

**Chiavi UserDefaults usate:**
- `syncService.lastPull` — data ultimo pull riuscito
- `syncService.lastUserId` — UUID stringa dell'ultimo utente loggato (per rilevare cambio utente)

---

### `MoneyTracker/Theme.swift` — sezioni modificate

```swift
// MARK: - AppTheme (solo 2 temi)

enum AppTheme: String, CaseIterable, Identifiable {
    case classico = "Classico"   // light
    case notte    = "Notte"      // dark

    var id: String { rawValue }

    var ink: Color {
        switch self {
        case .classico: return Color(hex: "111111")
        case .notte:    return Color(hex: "F0F0F0")
        }
    }
    var paper: Color {
        switch self {
        case .classico: return Color(hex: "FAFAFA")
        case .notte:    return Color(hex: "111111")
        }
    }
    var fog: Color {
        switch self {
        case .classico: return Color(hex: "E0E0E0")
        case .notte:    return Color(hex: "2A2A2A")
        }
    }
    var smoke: Color {
        switch self {
        case .classico: return Color(hex: "888888")
        case .notte:    return Color(hex: "909090")
        }
    }
}

// MARK: - ThemeManager

@MainActor
final class ThemeManager: ObservableObject {
    @Published var current: AppTheme = .classico

    init() {
        DS.invalidateThemeCache(.classico)
    }

    func set(_ theme: AppTheme) {
        guard current != theme else { return }
        current = theme
        DS.invalidateThemeCache(theme)   // passa direttamente — NON legge UserDefaults
    }
}

// MARK: - DS (solo la parte colori, modificata)

@MainActor
enum DS {
    // ...spacing e layout invariati...

    private static var _cachedTheme: AppTheme = .classico

    static func invalidateThemeCache(_ theme: AppTheme) {
        _cachedTheme = theme
    }

    private static var activeTheme: AppTheme { _cachedTheme }

    static var ink:   Color { activeTheme.ink   }
    static var paper: Color { activeTheme.paper }
    static var fog:   Color { activeTheme.fog   }
    static var smoke: Color { activeTheme.smoke }
}

// MARK: - Navbar modifier (sostituisce ThemePickerToolbarModifier)

struct ThemeNavBarModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbarBackground(DS.paper, for: .navigationBar)
            .toolbarBackground(.visible, for: .navigationBar)
    }
}

extension View {
    // Nome mantenuto per compatibilità con le 5 viste che lo usano
    func themePickerButton() -> some View {
        modifier(ThemeNavBarModifier())
    }
}
```

---

### `supabase_tables.sql` — SQL per Supabase SQL Editor

```sql
CREATE TABLE public.mt_accounts (
    id                     UUID PRIMARY KEY,
    user_id                UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name                   TEXT NOT NULL,
    type                   TEXT NOT NULL,
    initial_balance        DOUBLE PRECISION NOT NULL DEFAULT 0,
    color_hex              TEXT NOT NULL DEFAULT '1A1A1A',
    created_at             TIMESTAMPTZ NOT NULL,
    is_archived            BOOLEAN NOT NULL DEFAULT FALSE,
    is_excluded_from_total BOOLEAN NOT NULL DEFAULT FALSE
);
ALTER TABLE public.mt_accounts ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own accounts" ON public.mt_accounts FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.mt_transactions (
    id                   UUID PRIMARY KEY,
    user_id              UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id           UUID REFERENCES public.mt_accounts(id) ON DELETE SET NULL,
    name                 TEXT NOT NULL,
    amount               DOUBLE PRECISION NOT NULL,
    type                 TEXT NOT NULL,
    category             TEXT NOT NULL DEFAULT '',
    category_icon        TEXT NOT NULL DEFAULT '',
    date                 TIMESTAMPTZ NOT NULL,
    is_done              BOOLEAN NOT NULL DEFAULT TRUE,
    is_fixed             BOOLEAN NOT NULL DEFAULT FALSE,
    is_transfer          BOOLEAN NOT NULL DEFAULT FALSE,
    transfer_group_id    TEXT NOT NULL DEFAULT '',
    notes                TEXT NOT NULL DEFAULT '',
    recurring_frequency  TEXT NOT NULL DEFAULT '',
    template_id          TEXT NOT NULL DEFAULT '',
    created_at           TIMESTAMPTZ NOT NULL
);
ALTER TABLE public.mt_transactions ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own transactions" ON public.mt_transactions FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.mt_budgets (
    id            UUID PRIMARY KEY,
    user_id       UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    account_id    UUID REFERENCES public.mt_accounts(id) ON DELETE SET NULL,
    category      TEXT NOT NULL,
    category_icon TEXT NOT NULL DEFAULT '',
    monthly_limit DOUBLE PRECISION NOT NULL,
    month         INTEGER NOT NULL,
    year          INTEGER NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL
);
ALTER TABLE public.mt_budgets ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own budgets" ON public.mt_budgets FOR ALL USING (auth.uid() = user_id);

CREATE TABLE public.mt_goals (
    id             UUID PRIMARY KEY,
    user_id        UUID NOT NULL REFERENCES auth.users(id) ON DELETE CASCADE,
    name           TEXT NOT NULL,
    emoji          TEXT NOT NULL DEFAULT 'target',
    target_amount  DOUBLE PRECISION NOT NULL,
    current_amount DOUBLE PRECISION NOT NULL DEFAULT 0,
    deadline       TIMESTAMPTZ,
    is_completed   BOOLEAN NOT NULL DEFAULT FALSE,
    created_at     TIMESTAMPTZ NOT NULL
);
ALTER TABLE public.mt_goals ENABLE ROW LEVEL SECURITY;
CREATE POLICY "own goals" ON public.mt_goals FOR ALL USING (auth.uid() = user_id);
```

---

### Comando Git Checkpoint

```bash
cd ~/Desktop/MoneyTracker && git add -A && git commit -m "<descrizione>" && git push
```

### Comando IPA manuale per AltStore

```bash
cd ~/Library/Developer/Xcode/DerivedData && \
APP=$(find . -name "MoneyTracker.app" -path "*/Debug-iphoneos/*" | head -1) && \
mkdir -p /tmp/Payload && \
cp -r "$APP" /tmp/Payload/ && \
cd /tmp && zip -r ~/Desktop/MoneyTracker.ipa Payload && \
rm -rf /tmp/Payload && \
echo "IPA salvato sul Desktop"
```

---

## 5. TASK IN SOSPESO E PROSSIMI PASSI

### 🔴 Da verificare subito
- [ ] **Test tema chiaro/scuro** — verificare che il fix `DS.invalidateThemeCache(theme)` abbia risolto i bug visivi (spazi neri in light, notte non funzionante)
- [ ] **Test deep link email** — cliccare link di conferma/reset da email reale e verificare che apra l'app (richiede URL scheme `moneytracker` in Xcode → Info → URL Types + Supabase configurato)
- [ ] **Test sync end-to-end** — inserire dati, chiudere app, riaprire, verificare persistenza su Supabase

### 🟡 Funzionalità demandate
- [ ] **Sign in with Apple** — richiede Apple Developer Program (€99/anno) o risoluzione capability in Xcode
- [ ] **Google Sign-In** — richiede Google Cloud Console + GoogleSignIn-iOS SDK + URL scheme aggiuntivo
- [ ] **Widget iOS** — widget che legge dal realContainer per mostrare saldo/transazioni recenti sulla home screen
- [ ] **Push notifications** — es. avviso quando si supera il budget mensile (richiede server-side logic o Supabase Edge Functions)
- [ ] **Supabase Email Confirmation** — decidere se abilitare/disabilitare la conferma email obbligatoria (ora disabilitata per comodità in sviluppo)

### 🟢 Ottimizzazioni future
- [ ] Ripristinare rate limits Supabase prima del rilascio pubblico
- [ ] Aggiungere gestione errori più granulare nel SyncService (retry logic)
- [ ] Test su dispositivo fisico in dark mode per verificare il tema notte

---

## 6. PROMPT DI RE-ONBOARDING

Copia e incolla questo prompt all'inizio della nuova chat, insieme a questo documento:

---

```
Sei il mio assistente di sviluppo per l'app iOS "MoneyTracker" (SwiftUI + SwiftData).
Ti allego il Session Export Document della sessione precedente: leggilo interamente prima di rispondere.

Contesto rapido:
- App finanza personale in Swift/SwiftUI/SwiftData
- Auth tramite Supabase (email+password), sync bidirezionale SwiftData ↔ Supabase
- Repository: https://github.com/cociveramatteo-dot/Money-Tracker
- Progetto in locale: ~/Desktop/MoneyTracker
- La cartella è montata e puoi leggere e scrivere i file direttamente

Dalla sessione precedente abbiamo appena:
1. Implementato auth gate (LoginView, SignUpView, SupabaseManager)
2. Implementato SyncService bidirezionale con sync real-time via ModelContext.didSave
3. Semplificato il sistema tema a solo chiaro/scuro automatico da sistema iOS
4. Configurato deep link moneytracker:// per email Supabase
5. Installato l'app via AltStore per evitare il limite 7 giorni

Il task più urgente è: [DESCRIVI QUI COSA VUOI FARE].

Prima di scrivere codice, leggi i file rilevanti dal progetto con il tool Read.
```
