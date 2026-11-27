import SwiftData
import SwiftUI

struct E2EActivationFlow: View {
    enum Mode { case activate, change }
    private enum Screen { case phrase, recovery, done }

    @ObservedObject var controller: E2EController
    let mode: Mode
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var screen = Screen.phrase
    @State private var phrase = E2EPhrase()
    @State private var key = ""
    @State private var confirmation = ""
    @State private var attemptedActivation = false
    @State private var issue: E2EController.Issue?

    private var title: LocalizedStringKey {
        if controller.operation == .enable || controller.operation == .cancelEnable { return "e2e_titolo" }
        return switch screen {
        case .phrase: mode == .activate ? "e2e_frase_titolo" : "e2e_cambia_frase"
        case .recovery: "e2e_chiave_titolo"
        case .done: "e2e_titolo"
        }
    }

    var body: some View {
        E2ESheet(title: title, canClose: !controller.isBusy) {
            if let operation = controller.operation, operation == .enable || operation == .cancelEnable {
                E2EProgress(direction: .enable, completed: controller.progress)
            } else {
                switch screen {
                case .phrase:
                    E2EPhraseFields(phrase: $phrase)
                    if let issue { E2EMessage(issue.text, color: DS.danger) }
                    PrimaryButton(title: "Continua") { advance() }
                        .accessibilityIdentifier("e2e_continue")
                        .disabled(controller.isBusy)
                    if controller.isBusy { ProgressView().tint(DS.accent) }
                case .recovery:
                    recoveryContent
                case .done:
                    E2EMessage(mode == .activate ? "e2e_fatto" : "e2e_frase_cambiata", color: DS.accent)
                        .accessibilityIdentifier(mode == .activate ? "e2e_active" : "e2e_phrase_updated")
                }
            }
        }
    }

    @ViewBuilder
    private var recoveryContent: some View {
        if let issue {
            E2EMessage(issue.text, color: issue == .concurrentActivation ? DS.plannedText : DS.danger)
                .accessibilityIdentifier("e2e_migration_error")
            if issue != .concurrentActivation, controller.lockReason == nil {
                PrimaryButton(title: "e2e_riprova") { activate() }
                    .accessibilityIdentifier("e2e_retry")
                    .disabled(controller.isBusy)
            }
            if controller.canCancelEnable {
                E2EAction("e2e_annulla_attivazione", destructive: true) { cancelActivation() }
                    .accessibilityIdentifier("e2e_cancel")
                    .disabled(controller.isBusy)
            }
        } else {
            RecoveryKeyCard(key: key, confirmation: $confirmation) { activate() }
                .disabled(controller.isBusy)
        }
    }

    private func advance() {
        guard phrase.validate() else { return }
        issue = nil
        if mode == .activate {
            do {
                key = try E2EMigrator.makeRecoveryKey()
                screen = .recovery
            } catch {
                issue = .failed
            }
        } else {
            Task {
                do {
                    try await controller.run(.changePhrase, context: context) {
                        try await $0.changePassphrase(phrase.value)
                    }
                    phrase = E2EPhrase()
                    screen = .done
                } catch {
                    issue = E2EController.issue(for: error)
                }
            }
        }
    }

    private func activate() {
        issue = nil
        Task {
            do {
                try await controller.run(.enable, context: context) { migrator in
                    let resumed = try await migrator.resumeForProtectionUI(.enable, allowCommitted: attemptedActivation)
                    if !resumed {
                        attemptedActivation = true
                        try await migrator.enable(passphrase: phrase.value, recoveryKey: key, confirmation: confirmation)
                    }
                }
                phrase = E2EPhrase()
                key = ""
                confirmation = ""
                screen = .done
            } catch {
                if (error as? E2EMigrator.Failure) == .stateChanged, controller.anotherDeviceIsEnabling {
                    issue = .concurrentActivation
                } else {
                    issue = E2EController.issue(for: error)
                }
            }
        }
    }

    private func cancelActivation() {
        Task {
            do {
                try await controller.run(.cancelEnable, context: context) { try await $0.cancelEnable() }
                dismiss()
            } catch {
                issue = E2EController.issue(for: error)
            }
        }
    }
}

struct E2EPhrase {
    var value = ""
    var repeated = ""
    var error: LocalizedStringKey?

    mutating func validate() -> Bool {
        if value.count < 10 { error = "e2e_frase_corta" }
        else if value != repeated { error = "e2e_frase_diverse" }
        else { error = nil }
        return error == nil
    }
}

struct E2EPhraseFields: View {
    @Binding var phrase: E2EPhrase

    var body: some View {
        E2EMessage("e2e_frase_aiuto", color: DS.smoke)
        RevealableSecureField(
            placeholder: "e2e_frase_campo",
            text: $phrase.value,
            style: .e2e,
            accessibilityIdentifier: "e2e_phrase"
        )
        RevealableSecureField(
            placeholder: "e2e_frase_ripeti",
            text: $phrase.repeated,
            style: .e2e,
            accessibilityIdentifier: "e2e_repeat"
        )
        if let error = phrase.error {
            E2EMessage(error, color: DS.danger)
                .accessibilityIdentifier("e2e_phrase_error")
        }
    }
}

extension View {
    func e2eField() -> some View {
        self
            .scaledFont(size: 17)
            .foregroundStyle(DS.ink)
            .padding(DS.Space.l)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
            .overlay {
                RoundedRectangle(cornerRadius: DS.Layout.buttonRadius)
                    .strokeBorder(DS.filterBorder)
                    .allowsHitTesting(false)
            }
            .submitLabel(.done)
            .textInputAutocapitalization(.never)
            .autocorrectionDisabled()
            .privacySensitive()
    }
}
