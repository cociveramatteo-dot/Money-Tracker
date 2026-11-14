import SwiftUI

struct ProgrammedRuleCard: View {
    let rule: RecurringRule
    let onSelect: (RecurrenceSelection) -> Void
    @State private var cache = RecurrencePresentationCache()

    private func nextOccurrence(start: Date, calendar: Calendar) -> Occurrence? {
        guard let end = calendar.date(byAdding: .year, value: 2, to: max(start, rule.startDate)) else { return nil }
        return cache.occurrences(rules: [rule], in: DateInterval(start: start, end: end)).first
    }

    var body: some View {
        let calendar = Calendar(identifier: .gregorian)
        let start = calendar.startOfDay(for: Date())
        let next = nextOccurrence(start: start, calendar: calendar)
        return VStack(alignment: .leading, spacing: DS.Space.s) {
            Text(rule.name).foregroundStyle(DS.ink)
            Text(rule.amount.currencyFormatted + " · " + NSLocalizedString(rule.frequency == "mensile" ? "Mensile" : rule.frequency == "annuale" ? "Annuale" : "Settimanale", comment: ""))
                .foregroundStyle(DS.smoke)
            if let endDate = rule.endDate {
                Text(endDate < start ? "Terminata" : "Termina il")
                Text(endDate.dayMonthFormatted)
            } else { Text("Attiva") }
            if let next {
                Button {
                    onSelect(RecurrenceSelection(rule: rule, occurrence: next))
                } label: { Text(verbatim: String(localized: "Prossima occorrenza") + " · " + next.date.dayMonthFormatted) }
                .accessibilityIdentifier("editRecurrence_\(rule.name)")
            } else {
                // Ended or fully skipped series remain editable through their original anchor.
                Button("Modifica") {
                    var base = RecurringSeriesEditor.snapshot(rule)
                    base.exceptions = [:]; base.endDate = nil
                    guard let end = calendar.date(byAdding: .day, value: 1, to: rule.startDate) else { return }
                    if let first = RecurrenceCalculator().occurrences(rule: base, in: DateInterval(start: rule.startDate, end: end)).first {
                        onSelect(RecurrenceSelection(rule: rule, occurrence: first))
                    }
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(DS.Space.m)
        .background(DS.surface)
    }

}

struct VirtualOccurrenceRow: View {
    let occurrence: Occurrence
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            VStack(alignment: .leading) {
                Text(occurrence.name).foregroundStyle(DS.ink)
                Text(occurrence.date.dayMonthFormatted + " · " + occurrence.amount.currencyFormatted)
                    .foregroundStyle(DS.smoke)
                Text("Virtuale · esclusa dai totali").font(.caption).foregroundStyle(DS.smoke)
            }
        }
        .listRowBackground(DS.surface)
    }
}
