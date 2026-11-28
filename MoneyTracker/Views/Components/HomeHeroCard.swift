import SwiftUI

/// Hero della Home: saldo attuale, TrailView, saldo atteso. Riceve testi già formattati.
struct HomeHeroCard: View {
    let amount: Text
    let trail: BalanceTrail
    let monthStart: Date
    let monthEnd: Date
    /// Presenti solo se ci sono pianificati.
    var expectedAmount: Text? = nil
    var plannedSummary: Text? = nil

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.xs) {
            Text("Saldo attuale").font(DS.Typo.secondary).foregroundStyle(DS.heroSecondary)
            amount.font(DS.Typo.heroAmount).tracking(DS.Typo.heroAmountTracking)
                .foregroundStyle(DS.heroText).lineLimit(1).minimumScaleFactor(0.6)
                .accessibilityIdentifier("home_actualBalance")
            TrailView(trail: trail, monthStart: monthStart, monthEnd: monthEnd)
                .padding(.top, DS.Space.m)
            if let expectedAmount {
                Rectangle().fill(DS.heroDivider).frame(height: 1)
                    .padding(.top, DS.Space.m).accessibilityHidden(true)
                HStack(alignment: .top, spacing: DS.Space.m) {
                    VStack(alignment: .leading, spacing: 2) {
                        Text("Saldo atteso a fine mese").font(DS.Typo.caption).foregroundStyle(DS.heroSecondary)
                        expectedAmount.font(DS.Typo.sectionTitle).foregroundStyle(DS.heroPlanned)
                            .lineLimit(1).minimumScaleFactor(0.7)
                            .accessibilityIdentifier("home_expectedBalance")
                    }
                    Spacer(minLength: DS.Space.s)
                    if let plannedSummary {
                        plannedSummary.font(DS.Typo.caption).foregroundStyle(DS.heroSecondary)
                            .multilineTextAlignment(.trailing)
                    }
                }
                .padding(.top, DS.Space.s)
            }
        }
        .padding(.horizontal, 20).padding(.top, 20).padding(.bottom, DS.Space.l)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.hero, in: RoundedRectangle(cornerRadius: 26))
        .accessibilityElement(children: .contain)
    }
}
