import SwiftData
import SwiftUI

struct E2EUnlockPrompt: ViewModifier {
    @ObservedObject var controller: E2EController
    var requiresAccount = true
    @AppStorage("demoModeEnabled") private var demoModeEnabled = false
    @State private var showUnlock = false

    private var eligible: Bool {
        !requiresAccount || (!demoModeEnabled && SupabaseManager.shared.isLoggedIn)
    }

    func body(content: Content) -> some View {
        content
            .onChange(of: eligible ? controller.lockReason : nil, initial: true) { _, reason in
                if reason != nil, controller.takeUnlockPrompt() { showUnlock = true }
            }
            .sheet(isPresented: $showUnlock) {
                E2EUnlockView(controller: controller).id(controller.sessionID)
            }
    }
}

struct E2EUnlockView: View {
    @ObservedObject var controller: E2EController
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var secret = ""
    @State private var phrase = E2EPhrase()
    @State private var useRecoveryKey = false
    @State private var confirmRestart = false
    @State private var issue: E2EController.Issue?

    var body: some View {
        E2ESheet(title: controller.lockReason == .protectionRemoved ? "e2e_rimossa_titolo" : "e2e_sblocca_titolo",
                 canClose: !controller.isBusy) {
            if controller.operation == .restart {
                E2EProgress(direction: .disable, completed: controller.progress)
            } else if controller.lockReason == .protectionRemoved {
                E2EProtectionRemovedContent(controller: controller) { dismiss() }
            } else if let reason = controller.lockReason, reason != .unsupported {
                unlockContent(reason)
            } else {
                E2EMessage(issue?.text ?? "e2e_errore", color: DS.danger)
            }
        }
        .alert("e2e_ricomincia_titolo", isPresented: $confirmRestart) {
            Button("Annulla", role: .cancel) {}
            Button("e2e_ricomincia", role: .destructive) {
                perform(.restart) { try await $0.restartFromDevice() }
            }
        } message: { Text("e2e_ricomincia_testo") }
    }

    @ViewBuilder
    private func unlockContent(_ reason: E2EGate.LockReason) -> some View {
        E2EMessage(reason == .transition ? "e2e_altro_dispositivo" : "e2e_sblocca_testo")
        Group {
            SecureField(useRecoveryKey ? "e2e_chiave_campo" : "e2e_frase_campo", text: $secret)
                .e2eField()
                .accessibilityIdentifier("e2e_unlock_secret")
            if useRecoveryKey {
                SectionLabel(text: "e2e_frase_titolo")
                E2EPhraseFields(phrase: $phrase)
            }
            if let issue {
                E2EMessage(issue.text, color: DS.danger)
                    .accessibilityIdentifier("e2e_unlock_error")
            }
            PrimaryButton(title: "e2e_sblocca") { unlock() }
                .accessibilityIdentifier("e2e_unlock")
                .disabled(secret.isEmpty)

            E2EAction(useRecoveryKey ? "e2e_usa_frase" : "e2e_usa_chiave") {
                secret = ""
                phrase = E2EPhrase()
                issue = nil
                useRecoveryKey.toggle()
            }
            .accessibilityIdentifier("e2e_unlock_method")
            if reason == .needsSecret {
                E2EAction("e2e_perse_entrambe", destructive: true) { confirmRestart = true }
                    .accessibilityIdentifier("e2e_restart")
            }
        }
        .disabled(controller.isBusy)
        if controller.isBusy { ProgressView().tint(DS.accent) }
    }

    private func unlock() {
        guard !useRecoveryKey || phrase.validate() else { return }
        let credential: E2EMigrator.Secret = useRecoveryKey
            ? .recovery(secret, newPassphrase: phrase.value) : .passphrase(secret)
        perform(.unlock) { try await $0.unlock(credential) }
    }

    private func perform(_ operation: E2EController.Operation,
                         action: @escaping (E2EMigrator) async throws -> Void) {
        issue = nil
        Task {
            do {
                try await controller.run(operation, context: context, action: action)
                secret = ""
                phrase = E2EPhrase()
                dismiss()
            } catch {
                issue = E2EController.issue(for: error, checkingSecret: operation == .unlock)
            }
        }
    }
}

/// `protectionRemoved`: the server row is gone while this device still holds a key.
struct E2EProtectionRemovedContent: View {
    @ObservedObject var controller: E2EController
    var onContinued: () -> Void = {}
    @Environment(\.modelContext) private var context
    @State private var working = false
    @State private var failed = false
    @State private var confirmSignOut = false

    var body: some View {
        E2EMessage("e2e_rimossa_testo", color: DS.plannedText)
            .accessibilityIdentifier("e2e_protection_removed")
        if failed {
            E2EMessage("e2e_errore", color: DS.danger)
        }
        Group {
            PrimaryButton(title: "e2e_rimossa_continua") { run { await controller.continueWithoutProtection(context: context) } }
                .accessibilityIdentifier("e2e_continue_unprotected")
            E2EAction("e2e_rimossa_esci", destructive: true) { confirmSignOut = true }
                .accessibilityIdentifier("e2e_sign_out")
        }
        .disabled(working || controller.isBusy)
        // Same confirmation as the sign-out in Settings.
        .confirmationDialog("Esci dall'account?", isPresented: $confirmSignOut, titleVisibility: .visible) {
            Button("Esci", role: .destructive) {
                run {
                    await controller.signOut(context: context)
                    return true
                }
            }
            Button("Annulla", role: .cancel) {}
        } message: {
            Text("Dovrai effettuare di nuovo il login la prossima volta.")
        }
        if working {
            ProgressView().tint(DS.accent)
                .accessibilityLabel(Text("e2e_rimossa_continua"))
        }
    }

    private func run(_ action: @escaping () async -> Bool) {
        guard !working else { return }
        working = true
        failed = false
        Task {
            let succeeded = await action()
            working = false
            failed = !succeeded
            if succeeded { onContinued() }
        }
    }
}
