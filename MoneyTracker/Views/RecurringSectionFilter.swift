import Foundation

enum RecurringSectionFilter {
    /// Filtra le occorrenze materializzate delle serie programmate per la sezione inline «Ricorrenti»:
    /// solo righe con `templateId` presente in `ruleIDs` e sempre nel mese scelto (anche con ricerca attiva).
    static func filterTransactions(
        _ transactions: [Transaction],
        ruleIDs: Set<String>,
        selectedMonth: Date,
        query: String,
        selectedCategory: String,
        minAmount: Decimal?,
        maxAmount: Decimal?,
        useCustomDates: Bool,
        fromDate: Date,
        toDate: Date,
        calendar: Calendar = .current
    ) -> [Transaction] {
        let trimmedQuery = query.trimmingCharacters(in: .whitespacesAndNewlines)
        let from = calendar.startOfDay(for: fromDate)
        let to = calendar.date(byAdding: .day, value: 1, to: calendar.startOfDay(for: toDate)) ?? toDate

        return transactions.filter { t in
            guard !t.templateId.isEmpty, ruleIDs.contains(t.templateId) else { return false }
            guard calendar.isDate(t.date, equalTo: selectedMonth, toGranularity: .month) else { return false }
            if useCustomDates {
                guard t.date >= from && t.date < to else { return false }
            }
            guard trimmedQuery.isEmpty || t.name.localizedCaseInsensitiveContains(trimmedQuery) else { return false }
            guard selectedCategory.isEmpty || t.category == selectedCategory else { return false }
            if let minAmount, t.amount < minAmount { return false }
            if let maxAmount, t.amount > maxAmount { return false }
            return true
        }
    }
}
