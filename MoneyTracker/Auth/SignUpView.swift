import SwiftUI

// MARK: - SignUpView

struct SignUpView: View {

    @ObservedObject private var auth = SupabaseManager.shared
    @Environment(\.dismiss) private var dismiss

    @State private var email           = ""
    @State private var password        = ""
    @State private var confirmPassword = ""
    @State private var isLoading       = false
    @State private var errorMessage: String?    = nil
    @State private var successMessage: String?  = nil

    // MARK: - Body

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

    // MARK: - Sections

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
            AuthField(label: "Email",
                      placeholder: "nome@email.com",
                      text: $email,
                      keyboardType: .emailAddress)

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Password")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.smoke)
                SecureField("Minimo 6 caratteri", text: $password)
                    .padding(14)
                    .background(DS.fog)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(DS.ink)
            }

            VStack(alignment: .leading, spacing: DS.Space.xs) {
                Text("Conferma password")
                    .font(.system(size: 12, weight: .medium))
                    .foregroundStyle(DS.smoke)
                SecureField("Ripeti la password", text: $confirmPassword)
                    .padding(14)
                    .background(DS.fog)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .foregroundStyle(DS.ink)
                // Mismatch hint — compare in real time
                if !confirmPassword.isEmpty && confirmPassword != password {
                    Text("Le password non coincidono")
                        .font(.system(size: 11))
                        .foregroundStyle(.red)
                        .padding(.top, 2)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
    }

    @ViewBuilder private var feedbackSection: some View {
        if let msg = errorMessage {
            Text(msg)
                .font(.system(size: 13))
                .foregroundStyle(.red)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.m)
        }
        if let msg = successMessage {
            VStack(spacing: DS.Space.s) {
                Image(systemName: "envelope.badge.checkmark.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(.green)
                Text(msg)
                    .font(.system(size: 14))
                    .foregroundStyle(DS.smoke)
                    .multilineTextAlignment(.center)
                Button("Torna al login") { dismiss() }
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.ink)
                    .padding(.top, DS.Space.s)
            }
            .padding(.horizontal, DS.Layout.margin)
            .padding(.top, DS.Space.xl)
        }
    }

    @ViewBuilder private var registerButton: some View {
        if successMessage == nil {
            Button {
                Task { await signUp() }
            } label: {
                ZStack {
                    if isLoading {
                        ProgressView().tint(DS.paper)
                    } else {
                        Text("Registrati")
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
    }

    // MARK: - Logic

    private var canSubmit: Bool {
        !email.isEmpty && password.count >= 6 && password == confirmPassword
    }

    private func signUp() async {
        isLoading     = true
        errorMessage  = nil
        successMessage = nil
        do {
            try await auth.signUp(email: email, password: password)
            // Se la conferma email è attiva su Supabase, session sarà ancora nil
            // e l'utente vedrà il messaggio sotto. Altrimenti viene loggato automaticamente.
            if !auth.isLoggedIn {
                successMessage = "Account creato! Controlla la tua email e clicca il link di conferma per accedere."
            }
            // Se isLoggedIn è già true, MoneyTrackerApp mostrerà automaticamente l'app.
        } catch {
            errorMessage = signUpError(error)
        }
        isLoading = false
    }

    private func signUpError(_ error: Error) -> String {
        let raw = error.localizedDescription.lowercased()
        if raw.contains("already registered") || raw.contains("already exists") || raw.contains("user already") {
            return "Esiste già un account con questa email."
        }
        if raw.contains("password") && raw.contains("6") {
            return "La password deve avere almeno 6 caratteri."
        }
        if raw.contains("invalid email") {
            return "Indirizzo email non valido."
        }
        if raw.contains("rate limit") || raw.contains("too many") {
            return "Troppi tentativi. Aspetta qualche minuto e riprova."
        }
        return "Errore: \(error.localizedDescription)"
    }
}
