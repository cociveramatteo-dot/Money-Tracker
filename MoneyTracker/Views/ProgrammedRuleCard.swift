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
        let tint = CategoryTint.tint(for: rule.category)
        return VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                Image(systemName: rule.categoryIcon.isEmpty ? DS.categoryIcon(for: rule.category) : rule.categoryIcon)
                    .scaledFont(size: 16)
                    .foregroundStyle(tint.foreground)
                    .frame(width: 38, height: 38)
                    .background(tint.background, in: RoundedRectangle(cornerRadius: 12))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: DS.Space.m) {
                            Text(rule.name).fixedSize(horizontal: true, vertical: false)
                            Spacer(minLength: 0)
                            amount
                        }
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text(rule.name).fixedSize(horizontal: false, vertical: true)
                            amount
                        }
                    }
                    .font(DS.Typo.rowName)
                    .foregroundStyle(DS.ink)
                    Text(LocalizedStringKey(rule.frequency == "mensile" ? "Mensile" : rule.frequency == "annuale" ? "Annuale" : "Settimanale"))
                        .font(DS.Typo.caption)
                        .foregroundStyle(DS.smoke)
                    Group {
                        if let endDate = rule.endDate {
                            Text(endDate < start ? "Terminata" : "Termina il")
                            Text(endDate.dayMonthFormatted)
                        } else { Text("Attiva") }
                    }
                    .font(DS.Typo.caption)
                    .foregroundStyle(DS.smoke)
                }
            }
            Rectangle().fill(DS.divider).frame(height: 1).accessibilityHidden(true)
            if let next {
                Button {
                    onSelect(RecurrenceSelection(rule: rule, occurrence: next))
                } label: {
                    HStack(alignment: .firstTextBaseline, spacing: DS.Space.s) {
                        Text(verbatim: String(localized: "Prossima occorrenza") + " · " + next.date.dayMonthFormatted)
                            .fixedSize(horizontal: false, vertical: true)
                        Spacer(minLength: 0)
                        Image(systemName: "chevron.right").accessibilityHidden(true)
                    }
                    .foregroundStyle(DS.plannedText)
                    .frame(minHeight: 44)
                    .contentShape(Rectangle())
                }
                .accessibilityIdentifier("editRecurrence_\(rule.name)")
            } else {
                // Ended or fully skipped series remain editable through their original anchor.
                Button {
                    var base = RecurringSeriesEditor.snapshot(rule)
                    base.exceptions = [:]; base.endDate = nil
                    guard let end = calendar.date(byAdding: .day, value: 1, to: rule.startDate) else { return }
                    if let first = RecurrenceCalculator().occurrences(rule: base, in: DateInterval(start: rule.startDate, end: end)).first {
                        onSelect(RecurrenceSelection(rule: rule, occurrence: first))
                    }
                } label: {
                    Text("Modifica")
                        .foregroundStyle(DS.accent)
                        .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                        .contentShape(Rectangle())
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .buttonStyle(.plain)
        .font(DS.Typo.secondary)
        .tint(DS.plannedText)
        .padding(DS.Space.l)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
        .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DS.fog))
    }

    private var amount: some View {
        Text(rule.amount.currencyFormatted)
            .font(DS.Typo.rowAmount)
            .foregroundStyle(DS.plannedText)
            .fixedSize()
    }

}

struct VirtualOccurrenceRow: View {
    let occurrence: Occurrence
    let onSelect: () -> Void

    var body: some View {
        Button(action: onSelect) {
            HStack(alignment: .top, spacing: DS.Space.m) {
                Image(systemName: occurrence.categoryIcon.isEmpty ? DS.categoryIcon(for: occurrence.category) : occurrence.categoryIcon)
                    .scaledFont(size: 16)
                    .foregroundStyle(DS.plannedText)
                    .frame(width: 38, height: 38)
                    .overlay(RoundedRectangle(cornerRadius: 12)
                        .strokeBorder(DS.planned, style: StrokeStyle(lineWidth: 1, dash: [3, 3])))
                    .accessibilityHidden(true)
                VStack(alignment: .leading, spacing: DS.Space.xs) {
                    ViewThatFits(in: .horizontal) {
                        HStack(alignment: .firstTextBaseline, spacing: DS.Space.m) {
                            Text(occurrence.name).fixedSize()
                            Spacer(minLength: 0)
                            amount
                        }
                        VStack(alignment: .leading, spacing: DS.Space.xs) {
                            Text(occurrence.name).fixedSize(horizontal: false, vertical: true)
                            amount
                        }
                    }
                    .font(DS.Typo.rowName)
                    .foregroundStyle(DS.ink)
                    Text(occurrence.date.dayMonthFormatted)
                    Text("Virtuale · esclusa dai totali")
                        .fixedSize(horizontal: false, vertical: true)
                }
                .font(DS.Typo.caption)
                .foregroundStyle(DS.smoke)
            }
            .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
            .padding(.vertical, DS.Space.s)
            .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityElement(children: .combine)
        .listRowBackground(DS.surface)
    }

    private var amount: some View {
        Text(occurrence.amount.currencyFormatted)
            .font(DS.Typo.rowAmount)
            .foregroundStyle(DS.plannedText)
            .fixedSize()
    }
}
