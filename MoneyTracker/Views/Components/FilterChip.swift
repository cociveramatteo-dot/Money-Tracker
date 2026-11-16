import SwiftUI

struct FilterChip: View {
    enum Style { case primary, secondary, advanced }
    let title: Text
    var isActive = false
    var style: Style = .primary
    let action: () -> Void

    private var foreground: Color {
        isActive ? (style == .advanced ? DS.accent : DS.surface) : DS.ink
    }
    private var background: Color {
        isActive ? (style == .advanced ? DS.accentSoft : DS.ink) : DS.surface
    }

    var body: some View {
        Button(action: action) {
            HStack(spacing: DS.Space.s) {
                title.font(DS.Typo.rowName).fontWeight(isActive ? .semibold : .medium)
                if style == .advanced && isActive {
                    Image(systemName: "xmark").font(DS.Typo.caption).accessibilityHidden(true)
                }
            }
            .foregroundStyle(foreground)
            .padding(.horizontal, DS.Space.l)
            .frame(minHeight: 44)
            .background(background, in: Capsule())
            .overlay {
                if !isActive {
                    Capsule().strokeBorder(DS.fog, style: StrokeStyle(lineWidth: 1, dash: style == .secondary ? [3, 3] : []))
                }
            }
        }
        .buttonStyle(.plain)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

#Preview("Light") {
    HStack { FilterChip(title: Text("Tutti"), isActive: true) {}; FilterChip(title: Text("Mese"), style: .secondary) {} }
        .padding().background(DS.paper).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    HStack { FilterChip(title: Text("Tutti"), isActive: true) {}; FilterChip(title: Text("Cibo"), isActive: true, style: .advanced) {} }
        .padding().background(DS.paper).environment(\.colorScheme, .dark)
}
