import SwiftUI
import UIKit
import UniformTypeIdentifiers

struct RecoveryKeyCard: View {
    let key: String
    var confirmation: Binding<String>?
    let onSaved: () -> Void
    @State private var copied = false
    @State private var confirmationPulse = false

    private var groups: [Substring] { key.split(separator: "-") }

    private var matchesLastGroup: Bool {
        guard let last = groups.last, let confirmation else { return false }
        return String(last).caseInsensitiveCompare(confirmation.wrappedValue) == .orderedSame
    }

    var body: some View {
        let row1 = groups.prefix(4).joined(separator: "-")
        let row2 = groups.dropFirst(4).joined(separator: "-")
        ScrollView(.horizontal) {
            Text(verbatim: "\(row1)\n\(row2)")
                .monospaced()
                .scaledFont(size: 18, weight: .semibold)
                .foregroundStyle(DS.ink)
                .textSelection(.enabled)
                .speechSpellsOutCharacters()
                .accessibilityIdentifier("e2e_recovery_key")
                .padding(DS.Space.l)
                .fixedSize(horizontal: true, vertical: true)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
        .overlay {
            RoundedRectangle(cornerRadius: DS.Layout.cardRadius)
                .strokeBorder(DS.filterBorder)
                .allowsHitTesting(false)
        }
        .privacySensitive()

        ViewThatFits(in: .horizontal) {
            HStack(spacing: DS.Space.l) { keyActions }
            VStack(alignment: .leading, spacing: DS.Space.m) { keyActions }
        }

        E2EMessage("e2e_chiave_testo", color: DS.smoke)
        if let confirmation {
            let formattedConfirmation = Binding<String>(
                get: {
                    _ = confirmationPulse
                    return confirmation.wrappedValue
                },
                set: { incoming in
                    let formatted = RecoveryKeyInputFormatter.format(incoming, previous: confirmation.wrappedValue)
                    if formatted == confirmation.wrappedValue && incoming != confirmation.wrappedValue {
                        confirmationPulse.toggle()
                    }
                    confirmation.wrappedValue = formatted
                }
            )
            TextField("e2e_chiave_conferma", text: formattedConfirmation)
                .e2eField()
                .keyboardType(.asciiCapable)
                .accessibilityIdentifier("e2e_key_confirmation")
        }
        PrimaryButton(title: "e2e_chiave_salvata", action: onSaved)
            .disabled(confirmation != nil && !matchesLastGroup)
            .accessibilityIdentifier("e2e_key_saved")
    }

    @ViewBuilder
    private var keyActions: some View {
        GhostButton(title: copied ? "e2e_copiata" : "e2e_copia") {
            UIPasteboard.general.setItems(
                [[UTType.plainText.identifier: key]],
                options: [.localOnly: true, .expirationDate: Date().addingTimeInterval(120)]
            )
            copied = true
            UIAccessibility.post(notification: .announcement, argument: String(localized: "e2e_copiata"))
        }
        .task(id: copied) {
            guard copied else { return }
            try? await Task.sleep(for: .seconds(2))
            if !Task.isCancelled { copied = false }
        }
        ShareLink(item: key) {
            Text("e2e_condividi")
                .scaledFont(size: 15)
                .foregroundStyle(DS.accent)
        }
    }
}
