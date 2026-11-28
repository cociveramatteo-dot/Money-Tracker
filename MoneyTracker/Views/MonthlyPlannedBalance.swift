import Foundation
import SwiftData

/// Previsione di fine mese per conto, allineata alla regola `ProjectionRules.countsInProjection`.
enum MonthlyPlannedBalance {
    static func plannedDelta(for account: Account, day: Date, calendar: Calendar = .current) -> Decimal {
        account.transactions.reduce(Decimal(0)) { sum, transaction in
            guard !transaction.isDone,
                  ProjectionRules.countsInProjection(transaction, projectionDay: day, calendar: calendar)
            else { return sum }
            return sum + transaction.signedAmount
        }
    }

    static func expected(for account: Account, day: Date, calendar: Calendar = .current) -> Decimal {
        account.currentBalance + plannedDelta(for: account, day: day, calendar: calendar)
    }

    static func expectedByAccountID(
        for accounts: [Account],
        day: Date,
        calendar: Calendar = .current
    ) -> [PersistentIdentifier: Decimal] {
        var result: [PersistentIdentifier: Decimal] = [:]
        result.reserveCapacity(accounts.count)
        for account in accounts {
            result[account.persistentModelID] = expected(for: account, day: day, calendar: calendar)
        }
        return result
    }
}
