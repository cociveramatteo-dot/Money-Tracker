import Foundation
import Combine
import Supabase

// MARK: - SupabaseManager
//
// Singleton che gestisce il client Supabase e lo stato di autenticazione.
// Osservato da MoneyTrackerApp e da qualsiasi vista che ha bisogno di
// reagire al login/logout (es. SettingsView).

@MainActor
final class SupabaseManager: ObservableObject {

    static let shared = SupabaseManager()

    // MARK: - Client

    let client = SupabaseClient(
        supabaseURL: URL(string: "https://zblpzufsikxhuzdtcucg.supabase.co")!,
        supabaseKey: "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InpibHB6dWZzaWt4aHV6ZHRjdWNnIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODI4MTE1MzcsImV4cCI6MjA5ODM4NzUzN30.lezj5CD6yYjSK2-HeGSjU1kaE29G3B_ojiFhSz-8pgg",
        options: SupabaseClientOptions(
            auth: .init(
                // Opt-in al comportamento che diventerà default nella v3 del SDK
                // (PR supabase-swift #822/#844): la sessione salvata nel Keychain
                // viene emessa SUBITO come .initialSession, anche se scaduta —
                // il SDK la rinfresca in background ed emette .tokenRefreshed o
                // .signedOut. Vantaggi: splash istantaneo (niente attesa di rete)
                // e l'utente offline non viene buttato al login.
                emitLocalSessionAsInitialSession: true
            )
        )
    )

    // MARK: - State

    /// Sessione corrente — nil = utente non loggato.
    @Published var session: Session? = nil

    /// true durante il check iniziale della sessione salvata.
    @Published var isLoading = true

    // MARK: - Init

    private init() {
        Task { await bootstrap() }
    }

    /// Unico punto di verità: il flusso authStateChanges.
    /// Con emitLocalSessionAsInitialSession la sessione locale arriva
    /// immediatamente come .initialSession (anche se scaduta: verrà
    /// rinfrescata in background). Se il refresh fallisce definitivamente
    /// il SDK emette .signedOut → session = nil → schermata di login.
    private func bootstrap() async {
        for await (event, newSession) in client.auth.authStateChanges {
            session = newSession
            if event == .initialSession { isLoading = false }
        }
    }

    // MARK: - Computed

    var isLoggedIn: Bool { session != nil }

    /// Email dell'utente loggato, se disponibile.
    var userEmail: String? { session?.user.email }

    // MARK: - Auth actions

    // URL scheme dell'app — deve corrispondere a quello configurato in
    // Xcode (Info → URL Types) e in Supabase (Authentication → URL Configuration).
    private static let redirectURL = URL(string: "moneytracker://login-callback")!

    /// Registrazione con email e password.
    /// Se Supabase ha la conferma email attiva, `session` sarà nil finché
    /// l'utente non clicca il link. In quel caso mostrare un messaggio all'utente.
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password,
                                     redirectTo: Self.redirectURL)
    }

    /// Login con email e password.
    func signIn(email: String, password: String) async throws {
        try await client.auth.signIn(email: email, password: password)
    }

    /// Logout — invalida la sessione locale e sul server.
    func signOut() async throws {
        try await client.auth.signOut()
    }

    /// Invia email di reset password.
    func resetPassword(email: String) async throws {
        try await client.auth.resetPasswordForEmail(email,
                                                    redirectTo: Self.redirectURL)
    }
}
