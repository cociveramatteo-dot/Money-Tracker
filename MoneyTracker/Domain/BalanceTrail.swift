import Foundation

/// Serie del saldo del mese per la TrailView della Home (funzione pura, nessun accesso ai modelli).
///
/// Coerenza con i saldi dell'app (`AccountBalanceCache`):
/// - `currentBalance` = saldo attuale = ultimo punto reale;
/// - `expectedBalance` = `currentBalance` + somma di tutti i movimenti non ancora fatti = «Saldo atteso»
///   (uguale a `futureBalance`), anche per i pianificati scaduti o oltre fine mese: vengono
///   ancorati a oggi / all'ultimo giorno del mese, così l'ultimo punto proiettato coincide sempre.
nonisolated struct BalanceTrail: Equatable, Sendable {

    nonisolated struct Entry: Equatable, Sendable {
        let date: Date
        let signedAmount: Decimal
        let isDone: Bool
    }

    nonisolated struct Point: Equatable, Sendable {
        /// Giorno del mese, 1-based.
        let day: Int
        let balance: Decimal
    }

    let daysInMonth: Int
    let today: Int
    let currentBalance: Decimal
    let expectedBalance: Decimal
    /// Saldo a fine giornata dal giorno 1 a oggi (ultimo punto = `currentBalance`).
    let actual: [Point]
    /// Da oggi a fine mese (primo = `currentBalance`, ultimo = `expectedBalance`); vuota senza pianificati.
    let projected: [Point]
    /// Un punto per ogni movimento pianificato: giorno e saldo dopo averlo applicato (in ordine di giorno).
    let plannedMarks: [Point]
    let plannedCount: Int
    /// Somma dei pianificati (`expectedBalance - currentBalance`).
    let plannedDelta: Decimal

    var hasPlanned: Bool { plannedCount > 0 }

    static func make(
        currentBalance: Decimal,
        entries: [Entry],
        now: Date,
        calendar: Calendar = .current
    ) -> BalanceTrail {
        let monthStart = calendar.dateInterval(of: .month, for: now)?.start ?? now
        let daysInMonth = calendar.range(of: .day, in: .month, for: now)?.count ?? 30
        let today = min(max(calendar.component(.day, from: now), 1), daysInMonth)

        func day(of date: Date) -> Int {
            guard calendar.isDate(date, equalTo: monthStart, toGranularity: .month) else {
                return date < monthStart ? 1 : daysInMonth
            }
            return calendar.component(.day, from: date)
        }

        // Fatti: ancorati a [1, oggi]. Il saldo a fine giorno d = attuale − fatti dei giorni successivi.
        var doneByDay = [Int: Decimal]()
        // Pianificati: ancorati a [oggi, fine mese].
        var plannedByDay = [Int: Decimal]()
        var plannedDays = [Int]()
        for entry in entries {
            if entry.isDone {
                let d = min(day(of: entry.date), today)
                doneByDay[d, default: 0] += entry.signedAmount
            } else {
                let d = max(day(of: entry.date), today)
                plannedByDay[d, default: 0] += entry.signedAmount
                plannedDays.append(d)
            }
        }

        var actualReversed = [Point]()
        var running = currentBalance
        for d in stride(from: today, through: 1, by: -1) {
            actualReversed.append(Point(day: d, balance: running))
            running -= doneByDay[d] ?? 0
        }
        let actual = Array(actualReversed.reversed())

        let plannedDelta = plannedByDay.values.reduce(Decimal(0), +)
        var projected = [Point]()
        var marks = [Point]()
        if !plannedDays.isEmpty {
            var cumulative = currentBalance
            for d in today...daysInMonth {
                cumulative += plannedByDay[d] ?? 0
                projected.append(Point(day: d, balance: cumulative))
            }
            // Un segno per movimento: tutti quelli dello stesso giorno condividono il saldo a fine giorno.
            let balanceByDay = Dictionary(uniqueKeysWithValues: projected.map { ($0.day, $0.balance) })
            marks = plannedDays.sorted().compactMap { d in balanceByDay[d].map { Point(day: d, balance: $0) } }
        }

        return BalanceTrail(
            daysInMonth: daysInMonth,
            today: today,
            currentBalance: currentBalance,
            expectedBalance: currentBalance + plannedDelta,
            actual: actual,
            projected: projected,
            plannedMarks: marks,
            plannedCount: plannedDays.count,
            plannedDelta: plannedDelta
        )
    }
}
