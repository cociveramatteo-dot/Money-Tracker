import SwiftUI

// MARK: - LoginView

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

    // MARK: - Body

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

    // MARK: - Sections

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
            // Email
            AuthField(label: "Email",
                      placeholder: "nome@email.com",
                      text: $email,
                      keyboardType: .emailAddress)

            // Password
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
        Button {
            Task { await signIn() }
        } label: {
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
            resetEmail = email   // pre-compila con l'email inserita
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

    // MARK: - Logic

    private var canSubmit: Bool { !email.isEmpty && !password.isEmpty }

    private func signIn() async {
        isLoading     = true
        errorMessage  = nil
        do {
            try await auth.signIn(email: email, password: password)
            // Il listener in SupabaseManager aggiorna session automaticamente.
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

    /// Mappa i messaggi di errore Supabase in testo italiano leggibile.
    private func authError(_ error: Error) -> String {
        let raw = error.localizedDescription.lowercased()
        if raw.contains("invalid login") || raw.contains("invalid credentials") || raw.contains("invalid email or password") {
            return "Email o password non corretti."
        }
        if raw.contains("email not confirmed") {
            return "Conferma la tua email prima di accedere."
        }
        if raw.contains("rate limit") || raw.contains("too many") {
            return "Troppi tentativi. Aspetta qualche minuto e riprova."
        }
        if raw.contains("network") || raw.contains("connection") {
            return "Nessuna connessione. Controlla la rete e riprova."
        }
        return "Errore: \(error.localizedDescription)"
    }
}

// MARK: - AuthField (riutilizzabile da LoginView e SignUpView)

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
