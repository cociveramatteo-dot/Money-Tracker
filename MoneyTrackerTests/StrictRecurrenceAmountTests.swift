import Foundation
import Testing
@testable import MoneyTracker

@Suite("Strict recurrence override amounts")
struct StrictRecurrenceAmountTests {
    @Test("Rejects partial overrides and preserves exact valid precision")
    func validatesWholeOverride() throws {
        let calculator = RecurrenceCalculator(timeZone: try #require(TimeZone(secondsFromGMT: 0)))
        let date = try #require(ISO8601DateFormatter().date(from: "2026-01-01T12:00:00Z"))
        var rule = RuleSnapshot(id: UUID(), name: "Test", amount: 7, type: "Uscita",
                                category: "Casa", categoryIcon: "house", frequency: "mensile", startDate: date)
        for text in ["12abc", "1.234,56", "", "12\n", "0.1234567890123456789", "-5.5"] {
            rule.exceptions = ["2026-01-01": RecurrenceException(amount: text)]
            let occurrences = calculator.occurrences(rule: rule, in: calculator.monthInterval(date))
            let occurrence = try #require(occurrences.first)
            let expected = ["0.1234567890123456789", "-5.5"].contains(text) ? Decimal(string: text) : rule.amount
            #expect(occurrence.amount == expected)
        }
    }
}
