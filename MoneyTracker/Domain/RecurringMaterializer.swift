import Foundation
import SwiftData

@MainActor
struct RecurringMaterializer {
    private let calendar: Calendar
    private let calculator: RecurrenceCalculator

    enum MaterializationError: Error, Equatable {
        case requiresMainContext
        case saveFailed
    }

    init(timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
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
        let oldestMonth = calendar.date(byAdding: .month, value: -35, to: currentMonth)!
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
            let watermark = previous.map(month) ?? calendar.date(
                byAdding: .month, value: -1, to: max(startMonth, currentMonth)
            )!
            guard watermark < currentMonth else {
                if previous == nil { updates.append((rule, previous, watermark)) }
                continue
            }
            var cursor = max(startMonth, oldestMonth, calendar.date(byAdding: .month, value: 1, to: watermark)!)
            let snapshot = RuleSnapshot(
                id: rule.id, name: rule.name, amount: rule.amount, type: rule.type,
                category: rule.category, categoryIcon: rule.categoryIcon, notes: rule.notes,
                isFixed: rule.isFixed, accountId: rule.accountId, frequency: rule.frequency,
                startDate: rule.startDate, endDate: rule.endDate,
                exceptions: RecurrenceExceptionCodec.decode(rule.exceptionsJSON)
            )
            while cursor <= currentMonth {
                let nextMonth = calendar.date(byAdding: .month, value: 1, to: cursor)!
                for occurrence in calculator.occurrences(rule: snapshot, in: DateInterval(start: cursor, end: nextMonth)) {
                    let id = occurrence.id
                    var descriptor = FetchDescriptor<Transaction>(predicate: #Predicate { $0.id == id })
                    descriptor.fetchLimit = 1
                    guard try context.fetch(descriptor).isEmpty, pendingIDs.insert(id).inserted else { continue }
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
        calculator.noon(calendar.dateInterval(of: .month, for: date)!.start)
    }
}
