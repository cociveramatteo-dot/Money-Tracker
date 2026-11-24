import Foundation
import SwiftData

@MainActor
struct RecurringMaterializer {
    private let calculator: RecurrenceCalculator

    enum MaterializationError: Error, Equatable {
        case requiresMainContext
        case saveFailed
    }

    init(timeZone: TimeZone = .current) {
        self.calculator = RecurrenceCalculator(timeZone: timeZone)
    }

    /// Nil watermark means a new rule: never manufacture history before the current month.
    /// Older watermarks recover at most the latest 36 months, including the current one.
    /// Existing transactions (even edited or completed ones) are never modified.
    @discardableResult
    func materializeDue(context: ModelContext, now: Date = Date()) throws -> Int {
        guard context === context.container.mainContext else {
            throw MaterializationError.requiresMainContext
        }
        let currentMonth = month(of: now)
        let oldestMonth = calculator.adding(.month, value: -35, to: currentMonth)
        let rules = try context.fetch(FetchDescriptor<RecurringRule>())
        // Resolve every fetch before mutating the mainContext: a fetch failure must not
        // leave a partially advanced watermark, nor roll back unrelated user edits.
        var updates: [(rule: RecurringRule, previous: Date?, through: Date)] = []
        var pending: [Occurrence] = []
        var pendingIDs: Set<UUID> = []
        for rule in rules {
            guard ["mensile", "settimanale", "annuale"].contains(rule.frequency) else { continue }
            let startMonth = month(of: rule.startDate)
            let previous = rule.materializedThrough
            let watermark = previous.map(month) ?? calculator.adding(.month, value: -1, to: max(startMonth, currentMonth))
            guard watermark < currentMonth else {
                if previous == nil { updates.append((rule, previous, watermark)) }
                continue
            }
            var cursor = max(startMonth, oldestMonth, calculator.adding(.month, value: 1, to: watermark))
            let snapshot = RecurringSeriesEditor.snapshot(rule)
            let ruleIdString = rule.id.uuidString
            let existing = try context.fetch(FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.templateId == ruleIdString }))
            let existingIDs = Set(existing.map(\.id))
            while cursor <= currentMonth {
                let nextMonth = calculator.adding(.month, value: 1, to: cursor)
                // No mutations have occurred: preserve watermarks if the calendar cannot advance.
                // Unreachable with a valid calendar: defends against a calendar fallback that does not advance.
                // It exits before any mutation, so there is no infinite loop and no half-written watermark.
                guard nextMonth > cursor else { return 0 }
                for occurrence in calculator.occurrences(rule: snapshot, in: DateInterval(start: cursor, end: nextMonth)) {
                    let id = occurrence.id
                    guard !existingIDs.contains(id), pendingIDs.insert(id).inserted else { continue }
                    pending.append(occurrence)
                }
                cursor = nextMonth
            }
            updates.append((rule, previous, currentMonth))
        }
        guard !updates.isEmpty else { return 0 }
        let accounts = pending.isEmpty ? [] : try context.fetch(FetchDescriptor<Account>())
        var inserted: [Transaction] = []
        for occurrence in pending {
            let transaction = Transaction(
                name: occurrence.name, amount: occurrence.amount,
                type: TransactionType(rawValue: occurrence.type) ?? .uscita,
                category: occurrence.category, categoryIcon: occurrence.categoryIcon,
                date: occurrence.date, isDone: false, isFixed: occurrence.isFixed,
                notes: occurrence.notes, recurringFrequency: "", templateId: occurrence.ruleId.uuidString,
                account: accounts.first { $0.id == occurrence.accountId }
            )
            transaction.id = occurrence.id
            context.insert(transaction)
            inserted.append(transaction)
        }
        for update in updates { update.rule.materializedThrough = update.through }
        guard context.safeSave() else {
            // Restore only our changes; rollback() would discard unrelated edits in the UI.
            for update in updates { update.rule.materializedThrough = update.previous }
            for transaction in inserted { context.delete(transaction) }
            throw MaterializationError.saveFailed
        }
        return inserted.count
    }

    private func month(of date: Date) -> Date {
        calculator.noon(calculator.monthStart(date))
    }
}
