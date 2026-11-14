import Foundation

/// A single presentation interval, replaced when any recurrence input changes.
/// Reference storage avoids publishing cache writes during SwiftUI rendering.
final class RecurrencePresentationCache {
    private struct RuleKey: Equatable {
        let id: UUID
        let name: String
        let amount: Decimal
        let type: String
        let category: String
        let categoryIcon: String
        let notes: String
        let isFixed: Bool
        let accountId: UUID?
        let frequency: String
        let startDate: Date
        let endDate: Date?
        let exceptions: String

        init(_ rule: RecurringRule) {
            id = rule.id; name = rule.name; amount = rule.amount; type = rule.type
            category = rule.category; categoryIcon = rule.categoryIcon; notes = rule.notes
            isFixed = rule.isFixed; accountId = rule.accountId; frequency = rule.frequency
            startDate = rule.startDate; endDate = rule.endDate; exceptions = rule.exceptionsJSON
        }
    }

    private var keys: [RuleKey] = []
    private var interval: DateInterval?
    private var timeZone: TimeZone?
    private var values: [Occurrence] = []

    func occurrences(rules: [RecurringRule], in interval: DateInterval, timeZone: TimeZone = .current) -> [Occurrence] {
        let keys = rules.map(RuleKey.init)
        if self.keys != keys || self.interval != interval || self.timeZone != timeZone {
            values = rules.flatMap {
                RecurrenceCalculator(timeZone: timeZone).occurrences(rule: RecurringSeriesEditor.snapshot($0), in: interval)
            }
            self.keys = keys
            self.interval = interval
            self.timeZone = timeZone
        }
        return values
    }
}
