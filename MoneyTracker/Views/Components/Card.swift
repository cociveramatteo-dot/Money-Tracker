import SwiftUI

/// Contenitore standard Sentiero, senza dipendenze dai modelli dell'app.
struct Card<Content: View>: View {
    @ViewBuilder var content: () -> Content

    var body: some View {
        content()
            .padding(DS.Space.l)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
    }
}

#Preview("Light", traits: .fixedLayout(width: 360, height: 180)) {
    Card { Text("Card").font(DS.Typo.sectionTitle).foregroundStyle(DS.ink) }
        .padding().background(DS.paper).environment(\.colorScheme, .light)
}
#Preview("Dark", traits: .fixedLayout(width: 360, height: 180)) {
    Card { Text("Card").font(DS.Typo.sectionTitle).foregroundStyle(DS.ink) }
        .padding().background(DS.paper).environment(\.colorScheme, .dark)
}
