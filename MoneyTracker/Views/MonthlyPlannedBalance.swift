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

    /// Cache per `AccountsView`: evita di ricalcolare le scansioni di tutti i movimenti dei conti
    /// a ogni render non legato a dati o giorno di proiezione. Non è @Observable: si scrive solo la scatola interna.
    final class Cache {
        private var fingerprint: Int?
        private var cached: [PersistentIdentifier: Decimal] = [:]

        func expectedByAccountID(
            for accounts: [Account],
            day: Date,
            calendar: Calendar = .current
        ) -> [PersistentIdentifier: Decimal] {
            let fp = Self.fingerprint(accounts: accounts, day: day)
            if fingerprint == fp { return cached }
            let result = MonthlyPlannedBalance.expectedByAccountID(for: accounts, day: day, calendar: calendar)
            fingerprint = fp
            cached = result
            return result
        }

        private static func fingerprint(accounts: [Account], day: Date) -> Int {
            var hasher = Hasher()
            hasher.combine(day)
            hasher.combine(accounts.count)
            for account in accounts {
                hasher.combine(account.persistentModelID)
                hasher.combine(account.currentBalance)
                hasher.combine(account.transactions.count)
                for t in account.transactions {
                    hasher.combine(t.persistentModelID)
                    hasher.combine(t.date)
                    hasher.combine(t.amount)
                    hasher.combine(t.type)
                    hasher.combine(t.isDone)
                    hasher.combine(t.isFixed)
                    hasher.combine(t.isTransfer)
                    hasher.combine(t.templateId)
                    hasher.combine(t.recurringFrequency)
                }
            }
            return hasher.finalize()
        }
    }
}
