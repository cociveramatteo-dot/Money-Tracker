import Foundation

// MARK: - RecurringSeries
//
// Un pagamento/incasso che si ripete nel tempo, rilevato automaticamente per
// nome+categoria+tipo — non richiede un template esplicito (recurringFrequency)
// né il flag isFixed. Serve a intercettare anche casi come lo stipendio: importo
// variabile, inserito a mano ogni mese, senza alcuna marcatura "fissa".

struct RecurringSeries: Identifiable, Equatable {
    let id: String                     // "\(name)|\(category)|\(type)"
    let name: String                   // dall'occorrenza più recente
    let category: String
    let categoryIcon: String
    let transactionType: TransactionType
    let frequency: String              // "settimanale" | "mensile" | "annuale" | "irregolare"
    let isVariableAmount: Bool
    let count: Int
    let totalAmount: Decimal
    let average: Decimal
    let lastAmount: Decimal
    let firstDate: Date
    let lastDate: Date
    let occurrences: [Transaction]     // isDone == true, ordinate per data crescente

    static func == (lhs: RecurringSeries, rhs: RecurringSeries) -> Bool { lhs.id == rhs.id }
}

// MARK: - RecurringSeriesDetector

enum RecurringSeriesDetector {

    /// Rileva le serie ricorrenti tra le transazioni fornite. Esclude i
    /// trasferimenti (non hanno una categoria significativa) e le transazioni
    /// non ancora confermate (isDone == false, non sono "successe" davvero).
    static func detect(from transactions: [Transaction]) -> [RecurringSeries] {
        let candidates = transactions.filter { $0.isDone && !$0.isTransfer }

        var order: [String] = []
        var buckets: [String: [Transaction]] = [:]
        for t in candidates {
            let key = groupKey(for: t)
            if buckets[key] == nil { order.append(key) }
            buckets[key, default: []].append(t)
        }

        var series: [RecurringSeries] = []
        for key in order {
            guard let items = buckets[key], items.count >= 2 else { continue }
            let sorted = items.sorted { $0.date < $1.date }

            let distinctMonths = Set(sorted.map { monthKey($0.date) })
            guard distinctMonths.count >= 2 else { continue }

            let count = sorted.count
            let totalAmount = sorted.reduce(Decimal(0)) { $0 + $1.amount }
            let average = totalAmount / Decimal(count)
            let lastAmount = sorted.last!.amount
            let firstDate = sorted.first!.date
            let lastDate = sorted.last!.date
            let isVariableAmount = !sorted.allSatisfy { $0.amount == sorted[0].amount }

            let explicitFrequency = sorted.first { !$0.recurringFrequency.isEmpty }?.recurringFrequency
            let frequency = explicitFrequency ?? inferFrequency(sortedByDate: sorted)

            let mostRecent = sorted.last!
            series.append(RecurringSeries(
                id: key,
                name: mostRecent.name,
                category: mostRecent.category,
                categoryIcon: mostRecent.categoryIcon,
                transactionType: mostRecent.transactionType,
                frequency: frequency,
                isVariableAmount: isVariableAmount,
                count: count,
                totalAmount: totalAmount,
                average: average,
                lastAmount: lastAmount,
                firstDate: firstDate,
                lastDate: lastDate,
                occurrences: sorted
            ))
        }

        return series.sorted { abs($0.totalAmount) > abs($1.totalAmount) }
    }

    private static func groupKey(for t: Transaction) -> String {
        let normalizedName = t.name.trimmingCharacters(in: .whitespacesAndNewlines).lowercased()
        return "\(normalizedName)|\(t.category)|\(t.type)"
    }

    private static func monthKey(_ date: Date) -> String {
        let comps = Calendar.current.dateComponents([.year, .month], from: date)
        return "\(comps.year ?? 0)-\(comps.month ?? 0)"
    }

    /// Inferisce la cadenza dal gap medio in giorni tra occorrenze consecutive,
    /// quando nessuna occorrenza porta un `recurringFrequency` esplicito.
    private static func inferFrequency(sortedByDate items: [Transaction]) -> String {
        let cal = Calendar.current
        var gaps: [Int] = []
        for i in 1..<items.count {
            let days = cal.dateComponents([.day], from: items[i - 1].date, to: items[i].date).day ?? 0
            gaps.append(abs(days))
        }
        guard !gaps.isEmpty else { return "irregolare" }
        let avgGap = Double(gaps.reduce(0, +)) / Double(gaps.count)

        switch avgGap {
        case ...10:      return "settimanale"
        case 10...45:    return "mensile"
        case 45...200:   return "irregolare"
        default:         return "annuale"
        }
    }
}
