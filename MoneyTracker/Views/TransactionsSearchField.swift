import SwiftUI

struct TransactionsSearchField: View {
    @Binding var text: String
    let identifier: String

    var body: some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
            TextField("", text: $text, prompt: Text("Cerca per nome").foregroundStyle(DS.smoke))
                .accessibilityLabel(Text("Cerca per nome"))
                .font(DS.Typo.rowName)
                .foregroundStyle(DS.ink)
                .submitLabel(.done)
                .accessibilityIdentifier(identifier)
            if !text.isEmpty {
                Button {
                    text = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.smoke)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
        .frame(minHeight: 46)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: DS.Layout.cardRadius).strokeBorder(DS.fog))
    }
}
