import SwiftUI

/// Tab bar flottante Sentiero: capsula, h 66, raggio 24, margini 14.
/// Lo stato di selezione resta del chiamante (stessi indici della TabView).
struct FloatingTabBar: View {
    struct Item: Identifiable {
        let id: Int
        let title: LocalizedStringKey
        let symbol: String
        let identifier: String
    }

    let items: [Item]
    @Binding var selection: Int

    var body: some View {
        HStack(spacing: 0) {
            ForEach(items) { item in
                let active = selection == item.id
                Button { selection = item.id } label: {
                    VStack(spacing: 2) {
                        Image(systemName: item.symbol)
                            .font(.system(size: 17, weight: active ? .semibold : .regular))
                            .frame(width: 44, height: 28)
                            .background(active ? DS.accentSoft : .clear, in: Capsule())
                        Text(item.title)
                            .font(active ? DS.Typo.tabLabelActive : DS.Typo.tabLabel)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .foregroundStyle(active ? DS.ink : DS.smoke)
                    .frame(maxWidth: .infinity, minHeight: 66)
                    .contentShape(Rectangle())
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier(item.identifier)
                .accessibilityAddTraits(active ? [.isSelected] : [])
            }
        }
        .padding(.horizontal, DS.Space.xs)
        .frame(minHeight: 66)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 24))
        .shadow(color: DS.ink.opacity(0.10), radius: 14, y: 8)
        .padding(.horizontal, 14)
        .padding(.bottom, 20)
    }

    /// Spazio da riservare ai contenuti sotto la barra (66 + 20 + respiro).
    static let reservedHeight: CGFloat = 66 + 20 + 8
}

#Preview("Light") {
    @Previewable @State var tab = 0
    FloatingTabBar(items: [
        .init(id: 0, title: "Home", symbol: "house", identifier: "tab_home"),
        .init(id: 1, title: "Movimenti", symbol: "list.bullet", identifier: "tab_movimenti"),
        .init(id: 2, title: "Statistiche", symbol: "chart.bar", identifier: "tab_statistiche"),
        .init(id: 3, title: "Pianifica", symbol: "scope", identifier: "tab_pianifica"),
        .init(id: 4, title: "Conti", symbol: "creditcard", identifier: "tab_conti"),
    ], selection: $tab)
    .background(DS.paper).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    @Previewable @State var tab = 1
    FloatingTabBar(items: [
        .init(id: 0, title: "Home", symbol: "house", identifier: "tab_home"),
        .init(id: 1, title: "Movimenti", symbol: "list.bullet", identifier: "tab_movimenti"),
        .init(id: 2, title: "Statistiche", symbol: "chart.bar", identifier: "tab_statistiche"),
        .init(id: 3, title: "Pianifica", symbol: "scope", identifier: "tab_pianifica"),
        .init(id: 4, title: "Conti", symbol: "creditcard", identifier: "tab_conti"),
    ], selection: $tab)
    .background(DS.paper).environment(\.colorScheme, .dark)
}
