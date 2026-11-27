import SwiftUI

/// Campo segreto riutilizzabile (password, frase di sicurezza, chiave di recupero)
/// con pulsante occhio (`eye` / `eye.slash`), nessun correttore o suggerimento
/// quando visibile, e ripristino automatico a nascosto quando l'app va in background.
struct RevealableSecureField: View {
    enum Style {
        case auth
        case e2e
    }

    let placeholder: LocalizedStringKey
    @Binding var text: String
    var style: Style = .e2e
    var keyboardType: UIKeyboardType = .default
    var submitLabel: SubmitLabel = .done
    var accessibilityIdentifier: String? = nil

    @State private var isRevealed = false
    @FocusState private var isFocused: Bool
    @Environment(\.scenePhase) private var scenePhase

    static func shouldHide(on phase: ScenePhase) -> Bool {
        phase != .active
    }

    var body: some View {
        HStack(spacing: DS.Space.s) {
            Group {
                if isRevealed {
                    TextField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                        .textContentType(.none)
                } else {
                    SecureField(placeholder, text: $text)
                        .keyboardType(keyboardType)
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }
            }
            .focused($isFocused)
            .submitLabel(submitLabel)
            .scaledFont(size: 17)
            .foregroundStyle(DS.ink)
            .padding(.leading, style == .e2e ? DS.Space.l : 14)
            .padding(.vertical, style == .e2e ? DS.Space.l : 14)
            .modifier(OptionalAccessibilityIdentifier(id: accessibilityIdentifier))

            Button {
                let hadFocus = isFocused
                isRevealed.toggle()
                if hadFocus {
                    Task { @MainActor in isFocused = true }
                }
            } label: {
                Image(systemName: isRevealed ? "eye.slash" : "eye")
                    .scaledFont(size: 16)
                    .foregroundStyle(DS.smoke)
                    .frame(width: 44, height: 44)
                    .contentShape(Rectangle())
            }
            .buttonStyle(.plain)
            .padding(.trailing, DS.Space.xs)
            .accessibilityLabel(Text(isRevealed ? "Nascondi" : "Mostra"))
            .modifier(OptionalAccessibilityIdentifier(id: accessibilityIdentifier.map { "\($0)_toggle" }))
        }
        .background(backgroundShape)
        .overlay {
            if style == .e2e {
                RoundedRectangle(cornerRadius: DS.Layout.buttonRadius)
                    .strokeBorder(DS.filterBorder)
                    .allowsHitTesting(false)
            }
        }
        .privacySensitive()
        .onChange(of: scenePhase) { _, phase in
            if Self.shouldHide(on: phase) {
                isRevealed = false
            }
        }
    }

    @ViewBuilder
    private var backgroundShape: some View {
        if style == .e2e {
            RoundedRectangle(cornerRadius: DS.Layout.buttonRadius).fill(DS.surface)
        } else {
            RoundedRectangle(cornerRadius: 10).fill(DS.fog)
        }
    }
}

private struct OptionalAccessibilityIdentifier: ViewModifier {
    let id: String?

    func body(content: Content) -> some View {
        if let id {
            content.accessibilityIdentifier(id)
        } else {
            content
        }
    }
}
