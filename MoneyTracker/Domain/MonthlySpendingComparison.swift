import Foundation

/// Confronto puro delle uscite effettuate, su intervalli con lo stesso numero di giorni.
/// Non legge modelli, clock, store o impostazioni globali: tutti gli input sono espliciti.
nonisolated struct MonthlySpendingComparison: Equatable, Sendable {
    nonisolated struct Entry: Equatable, Sendable {
        let date: Date
        let amount: Decimal
        let category: String
        let isExpense: Bool
        let isDone: Bool
        let isTransfer: Bool
    }
    nonisolated enum Direction: Equatable, Sendable {
        case higher, lower, unchanged, noPreviousData, noData
    }
    nonisolated struct Change: Equatable, Sendable {
        /// nil identifica il totale; i nomi categoria restano canonici, non localizzati.
        let category: String?
        let current: Decimal
        let previous: Decimal
        let direction: Direction
        /// Magnitudine percentuale in Decimal; nil se la base è zero/non rappresentabile.
        let percentage: Decimal?
    }

    let comparedDays: Int
    /// Intervalli usati come [start, end), incluso l'intero ultimo giorno.
    let currentPeriod: DateInterval
    let previousPeriod: DateInterval
    let total: Change
    let categories: [Change]

    static func make(entries: [Entry], month: Date, now: Date,
                     calendar: Calendar) -> MonthlySpendingComparison? {
        guard let currentMonth = calendar.dateInterval(of: .month, for: month),
              let referenceMonth = calendar.dateInterval(of: .month, for: now),
              let previousDate = calendar.date(byAdding: .month, value: -1, to: currentMonth.start),
              let previousMonth = calendar.dateInterval(of: .month, for: previousDate),
              let currentDays = calendar.range(of: .day, in: .month, for: currentMonth.start),
              let previousDays = calendar.range(of: .day, in: .month, for: previousMonth.start)
        else { return nil }

        let elapsedDays: Int
        if currentMonth.start == referenceMonth.start {
            elapsedDays = calendar.component(.day, from: now)
        } else if currentMonth.start < referenceMonth.start {
            elapsedDays = currentDays.count
        } else {
            elapsedDays = 0  // nessun giorno trascorso nel mese futuro
        }
        let days = min(elapsedDays, currentDays.count, previousDays.count)
        guard let currentEnd = calendar.date(byAdding: .day, value: days, to: currentMonth.start),
              let previousEnd = calendar.date(byAdding: .day, value: days, to: previousMonth.start)
        else { return nil }
        let currentPeriod = DateInterval(start: currentMonth.start, end: currentEnd)
        let previousPeriod = DateInterval(start: previousMonth.start, end: previousEnd)
        var current: [String: Decimal] = [:]
        var previous: [String: Decimal] = [:]
        for entry in entries where entry.isExpense && entry.isDone && !entry.isTransfer && !entry.amount.isNaN {
            if entry.date >= currentPeriod.start && entry.date < currentPeriod.end {
                current[entry.category, default: 0] += entry.amount
            } else if entry.date >= previousPeriod.start && entry.date < previousPeriod.end {
                previous[entry.category, default: 0] += entry.amount
            }
        }
        let categories = Set(current.keys).union(previous.keys).sorted().map {
            change(category: $0, current: current[$0] ?? 0, previous: previous[$0] ?? 0)
        }.sorted {  // variazione assoluta decrescente; a parità, alfabetico
            let a = abs($0.current - $0.previous), b = abs($1.current - $1.previous)
            return a != b ? a > b : ($0.category ?? "") < ($1.category ?? "")
        }
        let totalCurrent = categories.reduce(Decimal(0)) { $0 + $1.current }
        let totalPrevious = categories.reduce(Decimal(0)) { $0 + $1.previous }
        guard !totalCurrent.isNaN, !totalPrevious.isNaN else { return nil }
        return .init(comparedDays: days, currentPeriod: currentPeriod, previousPeriod: previousPeriod,
                     total: change(category: nil, current: totalCurrent, previous: totalPrevious), categories: categories)
    }

    private static func change(category: String?, current: Decimal, previous: Decimal) -> Change {
        let direction: Direction
        let percentage: Decimal?
        if current == 0 && previous == 0 {
            direction = .noData
            percentage = nil
        } else if previous == 0 {
            direction = .noPreviousData
            percentage = nil
        } else {
            direction = current > previous ? .higher : current < previous ? .lower : .unchanged
            let result = abs(current - previous) / abs(previous) * 100
            percentage = result.isNaN ? nil : result
        }
        return .init(category: category, current: current, previous: previous,
                     direction: direction, percentage: percentage)
    }
}
