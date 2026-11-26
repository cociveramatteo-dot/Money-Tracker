import SwiftData
import SwiftUI

struct E2ESettingsRow: View {
    @ObservedObject var controller: E2EController
    @Environment(\.dynamicTypeSize) private var typeSize
    @State private var showProtection = false

    var body: some View {
        if controller.serverSupported {
            Button {
                showProtection = true
            } label: {
                let layout = typeSize.isAccessibilitySize
                    ? AnyLayout(VStackLayout(alignment: .leading, spacing: DS.Space.s))
                    : AnyLayout(HStackLayout(spacing: DS.Space.s))
                layout {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        Text("e2e_titolo")
                            .scaledFont(size: 15)
                            .foregroundStyle(DS.ink)
                        Text(controller.lockReason == nil ? "e2e_sottotitolo" : "e2e_pausa")
                            .scaledFont(size: 11)
                            .foregroundStyle(controller.lockReason == nil ? DS.smoke : DS.plannedText)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)

                    HStack(spacing: DS.Space.s) {
                        if controller.protection == .active || controller.protection == .off {
                            Text(controller.protection == .active ? "e2e_stato_attiva" : "e2e_stato_disattivata")
                                .scaledFont(size: 11, weight: .semibold)
                                .foregroundStyle(controller.protection == .active ? DS.accent : DS.smoke)
                        }
                        Image(systemName: "chevron.right")
                            .scaledFont(size: 12)
                            .foregroundStyle(DS.smoke)
                            .accessibilityHidden(true)
                    }
                }
                .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("e2e_settings")
            .sheet(isPresented: $showProtection) {
                AdvancedProtectionView(controller: controller).id(controller.sessionID)
            }
            ThinDivider()
        }
    }
}

struct AdvancedProtectionView: View {
    private enum Sheet: String, Identifiable {
        case activate, changePhrase, unlock, recoveryKey
        var id: Self { self }
    }

    @ObservedObject var controller: E2EController
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var sheet: Sheet?
    @State private var confirmDisable = false
    @State private var confirmRotation = false
    @State private var recoveryKey = ""
    @State private var retry: E2EController.Operation?
    @State private var issue: E2EController.Issue?

    var body: some View {
        NavigationStack {
            E2EPage {
                if let operation = controller.operation, let direction = operation.direction {
                    E2EProgress(direction: direction, completed: controller.progress)
                } else {
                    protectionContent
                    if let issue {
                        E2EMessage(issue.text, color: DS.danger)
                        if let retry {
                            PrimaryButton(title: "e2e_riprova") { manage(retry) }
                        }
                    }
                    if controller.isBusy { ProgressView().tint(DS.accent) }
                }
            }
            .navigationTitle("e2e_titolo")
            .navigationBarTitleDisplayMode(.inline)
            .themedNavBar()
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    GhostButton(title: "Chiudi") { dismiss() }
                        .disabled(controller.isBusy)
                }
            }
        }
        .interactiveDismissDisabled(controller.isBusy)
        .sheet(item: $sheet, onDismiss: { recoveryKey = "" }) { screen in
            switch screen {
            case .activate:
                E2EActivationFlow(controller: controller, mode: .activate)
            case .changePhrase:
                E2EActivationFlow(controller: controller, mode: .change)
            case .unlock:
                E2EUnlockView(controller: controller)
            case .recoveryKey:
                E2ESheet(title: "e2e_chiave_titolo", canClose: false) {
                    RecoveryKeyCard(key: recoveryKey) { sheet = nil }
                }
                .interactiveDismissDisabled()
            }
        }
        .alert("e2e_disattiva_titolo", isPresented: $confirmDisable) {
            Button("Annulla", role: .cancel) {}
            Button("e2e_disattiva", role: .destructive) { manage(.disable) }
        } message: { Text("e2e_disattiva_testo") }
        .alert("e2e_nuova_chiave_titolo", isPresented: $confirmRotation) {
            Button("Annulla", role: .cancel) {}
            Button("e2e_nuova_chiave", role: .destructive) { manage(.rotateKey) }
        } message: { Text("e2e_nuova_chiave_nota") }
    }

    @ViewBuilder
    private var protectionContent: some View {
        switch controller.protection {
        case .off:
            E2EMessage("e2e_intro")
            E2EMessage("e2e_metadati")
            E2EMessage("e2e_avviso_perdita", color: DS.danger)
                .padding(DS.Space.l)
                .background(DS.dangerSoft, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
            E2EMessage("e2e_avviso_aggiorna")
            if E2EFeature.allowNewActivations {
                PrimaryButton(title: "e2e_attiva") { sheet = .activate }
                    .accessibilityIdentifier("e2e_activate")
                    .disabled(controller.isBusy)
            }
        case .active:
            E2EMessage("e2e_fatto", color: DS.accent)
                .accessibilityIdentifier("e2e_active")
            Group {
                E2EAction("e2e_cambia_frase") { sheet = .changePhrase }
                    .accessibilityIdentifier("e2e_change_phrase")
                ThinDivider()
                E2EAction("e2e_nuova_chiave", note: "e2e_nuova_chiave_nota") { confirmRotation = true }
                ThinDivider()
                E2EAction("e2e_disattiva", destructive: true) { confirmDisable = true }
                    .accessibilityIdentifier("e2e_disable")
            }
            .disabled(controller.isBusy)
        case .locked(.protectionRemoved, _):
            Text("e2e_rimossa_titolo")
                .scaledFont(size: 17, weight: .semibold)
                .foregroundStyle(DS.ink)
                .fixedSize(horizontal: false, vertical: true)
                .accessibilityAddTraits(.isHeader)
            E2EProtectionRemovedContent(controller: controller)
        case .locked(let reason, _):
            E2EMessage(reason == .transition ? "e2e_altro_dispositivo" : "e2e_pausa", color: DS.plannedText)
            PrimaryButton(title: "e2e_sblocca") { sheet = .unlock }
                .accessibilityIdentifier("e2e_unlock_open")
        case .pending(let direction, let canCancel):
            if controller.isBusy {
                E2EProgress(direction: direction, completed: 0)
            } else {
                if issue == nil {
                    E2EMessage("e2e_errore", color: DS.danger)
                    PrimaryButton(title: "e2e_riprova") { manage(.resume(direction)) }
                }
                if direction == .enable, canCancel {
                    E2EAction("e2e_annulla_attivazione", destructive: true) { manage(.cancelEnable) }
                }
            }
        case nil:
            if issue == nil { E2EMessage("e2e_errore", color: DS.danger) }
        }
    }

    private func manage(_ operation: E2EController.Operation) {
        issue = nil
        retry = nil
        Task {
            do {
                switch operation {
                case .disable:
                    try await controller.run(operation, context: context) { migrator in
                        let resumed = try await migrator.resumeForProtectionUI(.disable)
                        if !resumed { try await migrator.disable() }
                    }
                case .rotateKey:
                    recoveryKey = try await controller.run(operation, context: context) {
                        try await $0.rotateRecoveryKey()
                    }
                    sheet = .recoveryKey
                case .cancelEnable:
                    try await controller.run(operation, context: context) { try await $0.cancelEnable() }
                case .resume(let direction):
                    _ = try await controller.run(operation, context: context) {
                        try await $0.resumeForProtectionUI(direction)
                    }
                case .enable, .unlock, .changePhrase, .restart:
                    // Run by their own sheets (activation flow, unlock), never from here.
                    assertionFailure("Unexpected protection operation \(operation)")
                }
            } catch {
                issue = E2EController.issue(for: error)
                if issue != nil { retry = operation }
            }
        }
    }
}

struct E2EPage<Content: View>: View {
    @ViewBuilder var content: Content

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: DS.Space.l) { content }
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(DS.Layout.margin)
        }
        .background(DS.paper)
        .tint(DS.accent)
        .scrollDismissesKeyboard(.interactively)
    }
}

struct E2ESheet<Content: View>: View {
    let title: LocalizedStringKey
    var canClose = true
    @ViewBuilder var content: Content
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            E2EPage {
                Text(title)
                    .scaledFont(size: 22, weight: .semibold)
                    .foregroundStyle(DS.ink)
                    .fixedSize(horizontal: false, vertical: true)
                    .accessibilityAddTraits(.isHeader)
                content
            }
                .navigationBarTitleDisplayMode(.inline)
                .themedNavBar()
                .toolbar {
                    if canClose {
                        ToolbarItem(placement: .topBarTrailing) {
                            GhostButton(title: "Chiudi") { dismiss() }
                                .accessibilityIdentifier("e2e_close")
                        }
                    }
                }
        }
        .interactiveDismissDisabled(!canClose)
    }
}

struct E2EMessage: View {
    let text: LocalizedStringKey
    var color: Color = DS.ink

    init(_ text: LocalizedStringKey, color: Color = DS.ink) {
        self.text = text
        self.color = color
    }

    var body: some View {
        Text(text)
            .scaledFont(size: 15)
            .foregroundStyle(color)
            .fixedSize(horizontal: false, vertical: true)
    }
}

struct E2EAction: View {
    let title: LocalizedStringKey
    var note: LocalizedStringKey?
    var destructive: Bool
    let action: () -> Void

    init(_ title: LocalizedStringKey, note: LocalizedStringKey? = nil, destructive: Bool = false,
         action: @escaping () -> Void) {
        self.title = title
        self.note = note
        self.destructive = destructive
        self.action = action
    }

    var body: some View {
        Button(role: destructive ? .destructive : nil, action: action) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                E2EMessage(title, color: destructive ? DS.danger : DS.accent)
                if let note { E2EMessage(note, color: DS.smoke) }
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
    }
}

struct E2EProgress: View {
    let direction: E2EMigrationDirection
    let completed: Int
    private var total: Int { direction == .enable ? 9 : 8 }

    var body: some View {
        E2EMessage(direction == .enable ? "e2e_in_corso" : "e2e_disattivazione_in_corso")
            .accessibilityIdentifier("e2e_progress")
        ProgressView(value: Double(completed), total: Double(total))
            .tint(DS.accent)
            .accessibilityLabel(direction == .enable ? "e2e_in_corso" : "e2e_disattivazione_in_corso")
        Text(verbatim: "\(completed) / \(total)")
            .scaledFont(size: 15, weight: .semibold)
            .monospacedDigit()
            .foregroundStyle(DS.smoke)
            .accessibilityHidden(true)
    }
}
