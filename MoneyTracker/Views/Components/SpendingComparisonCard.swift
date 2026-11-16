import SwiftUI

struct SpendingComparisonCard: View {
    let comparison: MonthlySpendingComparison?
    @Environment(\.locale) private var locale

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Confronto mese su mese").font(DS.Typo.rowName)
                .accessibilityIdentifier("statistics_comparison_title")
            if let comparison, comparison.comparedDays > 0 {
                Text(String(format: NSLocalizedString("Giorni 1–%lld · %@ / %@", comment: "Comparison periods"),
                                Int64(comparison.comparedDays),
                                comparison.currentPeriod.start.formatted(.dateTime.month(.abbreviated).year().locale(locale)),
                                comparison.previousPeriod.start.formatted(.dateTime.month(.abbreviated).year().locale(locale))))
                    .font(DS.Typo.caption).foregroundStyle(DS.smoke)
                row(comparison.total)
                    .accessibilityIdentifier("statistics_comparison_total")
                ForEach(comparison.categories, id: \.category) { change in
                    Rectangle().fill(DS.divider).frame(height: 1)
                    row(change)
                }
            } else {
                Label("Dati insufficienti.", systemImage: "arrow.left.and.right").font(DS.Typo.secondary).foregroundStyle(DS.smoke)
            }
        }
        .foregroundStyle(DS.ink).padding(16)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 22))
    }

    /// Sotto 100: 1-3 cifre significative; da 100 in su: nessun decimale (1234 resta 1234).
    static func formatPercentage(_ value: Decimal, locale: Locale) -> String {
        if value >= 100 {
            return value.formatted(.number.precision(.fractionLength(0)).locale(locale))
        }
        return value.formatted(.number.precision(.significantDigits(1...3)).locale(locale))
    }

    private func row(_ change: MonthlySpendingComparison.Change) -> some View {
        HStack(alignment: .top, spacing: 8) {
            Image(systemName: symbol(change.direction)).frame(width: 20)
                .accessibilityHidden(true)
            Text(sentence(change)).frame(maxWidth: .infinity, alignment: .leading)
                .fixedSize(horizontal: false, vertical: true)
        }
        .font(DS.Typo.secondary)
        .foregroundStyle(change.direction == .higher ? DS.danger : DS.ink)
        .accessibilityElement(children: .combine)
    }

    private func symbol(_ direction: MonthlySpendingComparison.Direction) -> String {
        switch direction {
        case .higher: return "arrow.up"
        case .lower: return "arrow.down"
        case .unchanged: return "arrow.right"
        case .noPreviousData: return "arrow.right"
        case .noData: return "arrow.left.and.right"
        }
    }

    private func sentence(_ change: MonthlySpendingComparison.Change) -> String {
        let category = change.category.map { NSLocalizedString($0, comment: "Category") }
        switch change.direction {
        case .higher, .lower: return changedSentence(change, category: category)
        case .unchanged: return unchangedSentence(category: category)
        case .noPreviousData: return noPreviousDataSentence(change, category: category)
        case .noData: return noDataSentence(category: category)
        }
    }

    private func changedSentence(_ change: MonthlySpendingComparison.Change, category: String?) -> String {
        guard let percentage = change.percentage else { return String(localized: "Dati insufficienti.") }
        let number = Self.formatPercentage(percentage, locale: locale)
        let isHigher = change.direction == .higher
        if let category {
            let key = isHigher ? "Questo mese hai speso il %@%% in più per %@"
                : "Questo mese hai speso il %@%% in meno per %@"
            return String(format: NSLocalizedString(key, comment: "Category comparison"), number, category)
        }
        let key = isHigher ? "Questo mese hai speso il %@%% in più in totale"
            : "Questo mese hai speso il %@%% in meno in totale"
        return String(format: NSLocalizedString(key, comment: "Total comparison"), number)
    }

    private func unchangedSentence(category: String?) -> String {
        if let category {
            return String(format: NSLocalizedString("Questo mese hai speso quanto nel periodo precedente per %@", comment: ""), category)
        }
        return String(localized: "Questo mese hai speso quanto nel periodo precedente in totale")
    }

    private func noPreviousDataSentence(_ change: MonthlySpendingComparison.Change, category: String?) -> String {
        if let category {
            return String(format: NSLocalizedString("Questo mese hai speso %@ per %@; nessuna spesa nel periodo precedente", comment: ""),
                          change.current.currencyFormatted, category)
        }
        return String(format: NSLocalizedString("Questo mese hai speso %@ in totale; nessuna spesa nel periodo precedente", comment: ""),
                      change.current.currencyFormatted)
    }

    private func noDataSentence(category: String?) -> String {
        if let category {
            return String(format: NSLocalizedString("Spesa pari a zero nei due periodi per %@", comment: ""), category)
        }
        return String(localized: "Spesa totale pari a zero nei due periodi")
    }
}
