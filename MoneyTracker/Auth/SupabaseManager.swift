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
            auth: SupabaseClientOptions.AuthOptions(
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

    /// Carica la sessione persistita e avvia il listener di cambio stato.
    private func bootstrap() async {
        // Prova a recuperare la sessione salvata nel Keychain.
        session = try? await client.auth.session
        isLoading = false

        // Ascolta tutti i cambi di stato futuri (login, logout, token refresh...).
        // MainActor.run garantisce che session venga aggiornato sul main thread
        // anche se il SDK Supabase consegna l'evento su un thread background.
        for await (_, newSession) in client.auth.authStateChanges {
            await MainActor.run { session = newSession }
        }
    }

    // MARK: - Computed

    var isLoggedIn: Bool { session != nil }

    /// Email dell'utente loggato, se disponibile.
    var userEmail: String? { session?.user.email }

    // MARK: - Auth actions

    /// Registrazione con email e password.
    /// Se Supabase ha la conferma email attiva, `session` sarà nil finché
    /// l'utente non clicca il link. In quel caso mostrare un messaggio all'utente.
    func signUp(email: String, password: String) async throws {
        try await client.auth.signUp(email: email, password: password)
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
        try await client.auth.resetPasswordForEmail(email)
    }

    /// Diritto all'oblio (GDPR art. 17): elimina definitivamente l'account Supabase
    /// dell'utente loggato e tutti i suoi dati (conti, movimenti, budget, obiettivi).
    /// Esegue una funzione lato database che opera solo sull'utente della sessione
    /// corrente (vedi migrazione `gdpr_right_to_erasure`) — irreversibile.
    /// Il chiamante deve poi ripulire lo store locale e disconnettersi.
    func deleteAccount() async throws {
        try await client.rpc("delete_own_account").execute()
    }
}
