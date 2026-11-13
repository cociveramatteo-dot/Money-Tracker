import SwiftUI

struct HeroCard: View {
    let title: Text
    let amount: Text
    let secondaryTitle: Text
    let secondaryAmount: Text

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.l) {
            title.font(DS.Typo.secondary).foregroundStyle(DS.heroSecondary)
            amount.font(DS.Typo.heroAmount).tracking(DS.Typo.heroAmountTracking)
                .foregroundStyle(DS.heroText)
            Rectangle().fill(DS.heroDivider).frame(height: 1).accessibilityHidden(true)
            HStack(alignment: .firstTextBaseline, spacing: DS.Space.m) {
                secondaryTitle.font(DS.Typo.caption).foregroundStyle(DS.heroSecondary)
                Spacer(minLength: DS.Space.s)
                secondaryAmount.font(DS.Typo.rowAmount).foregroundStyle(DS.heroPlanned)
            }
        }
        .padding(DS.Space.xl)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.hero, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
        .accessibilityElement(children: .combine)
    }
}

#Preview("Light") {
    HeroCard(title: Text("Saldo"), amount: Text("1.250 €"), secondaryTitle: Text("Atteso"), secondaryAmount: Text("1.400 €"))
        .padding().background(DS.paper).environment(\.colorScheme, .light)
}
#Preview("Dark") {
    HeroCard(title: Text("Saldo"), amount: Text("1.250 €"), secondaryTitle: Text("Atteso"), secondaryAmount: Text("1.400 €"))
        .padding().background(DS.paper).environment(\.colorScheme, .dark)
}
