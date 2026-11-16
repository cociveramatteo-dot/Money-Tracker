import Foundation
import Testing
@testable import MoneyTracker

@Suite("Pure recurrence calculator")
struct RecurrenceCalculatorTests {
    private let calculator = RecurrenceCalculator(timeZone: TimeZone(identifier: "Europe/Rome")!)

    private func date(_ year: Int, _ month: Int, _ day: Int, hour: Int = 12) -> Date {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        return calendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour))!
    }

    private func rule(_ frequency: String = "mensile", start: Date) -> RuleSnapshot {
        RuleSnapshot(id: UUID(), name: "Affitto", amount: Decimal(string: "0.2")!, type: "Uscita",
                     category: "Casa", categoryIcon: "house", frequency: frequency, startDate: start)
    }

    @Test("Monthly clamping always returns to the anchor", arguments: [2027, 2028])
    func monthly(year: Int) {
        let result = calculator.occurrences(rule: rule(start: date(year, 1, 31)),
                                           in: DateInterval(start: date(year, 1, 1), end: date(year, 5, 1)))
        #expect(result.map(\.key) == ["\(year)-01-31", "\(year)-02-\(year == 2028 ? 29 : 28)", "\(year)-03-31", "\(year)-04-30"])
    }

    @Test("Leap day returns in leap years")
    func yearly() {
        let result = calculator.occurrences(rule: rule("annuale", start: date(2024, 2, 29)),
                                           in: DateInterval(start: date(2024, 1, 1), end: date(2029, 1, 1)))
        #expect(result.map(\.key) == ["2024-02-29", "2025-02-28", "2026-02-28", "2027-02-28", "2028-02-29"])
    }

    @Test("Weekly dates stay at noon over both DST changes", arguments: [3, 10])
    func weeklyDST(month: Int) {
        let result = calculator.occurrences(rule: rule("settimanale", start: date(2026, month, 1, hour: 1)),
                                           in: DateInterval(start: date(2026, month, 1, hour: 0), end: date(2026, month + 1, 1, hour: 0)))
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = TimeZone(identifier: "Europe/Rome")!
        #expect(result.count == 5)
        for occurrence in result { #expect(calendar.component(.hour, from: occurrence.date) == 12) }
        for pair in zip(result, result.dropFirst()) {
            #expect(calendar.dateComponents([.day], from: pair.0.date, to: pair.1.date).day == 7)
            #expect(calendar.component(.weekday, from: pair.0.date) == calendar.component(.weekday, from: pair.1.date))
        }
    }

    @Test("Mid-month start, inclusive end, and half-open interval")
    func boundaries() {
        var input = rule("settimanale", start: date(2026, 3, 15, hour: 0))
        input.endDate = date(2026, 3, 29, hour: 0)
        let interval = DateInterval(start: date(2026, 3, 1, hour: 0), end: date(2026, 4, 1, hour: 0))
        #expect(calculator.occurrences(rule: input, in: interval).map(\.key) == ["2026-03-15", "2026-03-22", "2026-03-29"])
        #expect(calculator.occurrences(rule: input, in: DateInterval(start: date(2026, 3, 15), end: date(2026, 3, 22))).count == 1)
        input.endDate = date(2026, 3, 14)
        #expect(calculator.occurrences(rule: input, in: interval).isEmpty)
    }

    @Test("Interval ending at midnight of the 1st excludes the end month")
    func halfOpenEndAtMonthStart() {
        let interval = DateInterval(start: date(2026, 3, 1, hour: 0), end: date(2026, 4, 1, hour: 0))
        let weekly = calculator.occurrences(rule: rule("settimanale", start: date(2026, 3, 1, hour: 0)), in: interval)
        #expect(weekly.map(\.key) == ["2026-03-01", "2026-03-08", "2026-03-15", "2026-03-22", "2026-03-29"])
        let monthly = calculator.occurrences(rule: rule(start: date(2026, 1, 1, hour: 0)), in: interval)
        #expect(monthly.map(\.key) == ["2026-03-01"])
    }

    @Test("Normal editor preserves occurrence position and clamped anchors")
    func normalEditorAnchor() {
        let monthly = rule(start: date(2026, 1, 31))
        #expect(calculator.anchorForSeriesEdit(rule: monthly, originalDate: date(2026, 2, 28), date: date(2026, 2, 28)) == date(2026, 1, 31))
        #expect(calculator.anchorForSeriesEdit(rule: monthly, originalDate: date(2026, 2, 28), date: date(2026, 2, 27)) == date(2026, 1, 27))
        #expect(calculator.anchorForSeriesEdit(rule: monthly, originalDate: date(2026, 2, 28), date: date(2026, 3, 15)) == date(2026, 2, 15))
        let weekly = rule("settimanale", start: date(2026, 3, 1))
        #expect(calculator.anchorForSeriesEdit(rule: weekly, originalDate: date(2026, 3, 15), date: date(2026, 3, 18)) == date(2026, 3, 4))
        let annual = rule("annuale", start: date(2024, 2, 29))
        #expect(calculator.anchorForSeriesEdit(rule: annual, originalDate: date(2025, 2, 28), date: date(2025, 2, 28)) == date(2024, 2, 29))
        #expect(calculator.anchorForSeriesEdit(rule: annual, originalDate: date(2025, 2, 28), date: date(2025, 2, 27)) == date(2024, 2, 27))
    }

    @Test("Skip, overrides, exact Decimal, and defensive codec")
    func exceptions() throws {
        var input = rule(start: date(2026, 1, 15))
        input.exceptions = ["2026-01-15": RecurrenceException(skip: true),
                            "2026-02-15": RecurrenceException(amount: "0.1", date: date(2026, 2, 20), name: "Altro", notes: "Nota")]
        let json = try RecurrenceExceptionCodec.encode(input.exceptions)
        #expect(RecurrenceExceptionCodec.decode(json) == input.exceptions)
        #expect(RecurrenceExceptionCodec.decode("broken").isEmpty)
        #expect(RecurrenceExceptionCodec.decode("[]").isEmpty)
        #expect(RecurrenceExceptionCodec.decode("{\"x\":{\"skip\":true,\"amount\":3}}").isEmpty)
        let result = calculator.occurrences(rule: input, in: DateInterval(start: date(2026, 1, 1), end: date(2026, 4, 1)))
        #expect(result.count == 2)
        #expect(result[0].date == date(2026, 2, 20))
        #expect(result[0].originalDate == date(2026, 2, 15))
        #expect(result[0].key == "2026-02-15")
        #expect(result[0].name == "Altro" && result[0].notes == "Nota" && result[0].isOverridden)
        #expect(result.reduce(Decimal.zero) { $0 + $1.amount } == Decimal(string: "0.3")!)
        #expect(!result[1].isOverridden)
        #expect(calculator.occurrences(rule: input, in: DateInterval(start: date(2026, 2, 19), end: date(2026, 2, 21))).count == 1)
    }

    @Test("Skip all five weeks of a month")
    func skipMonth() {
        var input = rule("settimanale", start: date(2026, 3, 1))
        let interval = DateInterval(start: date(2026, 3, 1), end: date(2026, 4, 1))
        for occurrence in calculator.occurrences(rule: input, in: interval) {
            input.exceptions[occurrence.key] = RecurrenceException(skip: true)
        }
        #expect(input.exceptions.count == 5)
        #expect(calculator.occurrences(rule: input, in: interval).isEmpty)
        #expect(calculator.occurrences(rule: input, in: DateInterval(start: date(2026, 4, 1), end: date(2026, 5, 1))).count == 4)
    }

    @Test("No twelve-month horizon", arguments: ["mensile", "settimanale", "annuale"])
    func future(frequency: String) {
        let input = rule(frequency, start: date(2026, 1, 15))
        let result = calculator.occurrences(rule: input, in: DateInterval(start: date(2027, 1, 1), end: date(2027, 3, 1)))
        #expect(!result.isEmpty)
        if frequency == "mensile" { #expect(result.map(\.key) == ["2027-01-15", "2027-02-15"]) }
    }

    @Test("Gregorian civil dates are independent of locale and first weekday")
    func calendarIndependence() {
        let input = rule("settimanale", start: date(2026, 3, 1))
        let interval = DateInterval(start: date(2026, 3, 1), end: date(2026, 4, 1))
        let expected = calculator.occurrences(rule: input, in: interval).map(\.key)
        for firstWeekday in [1, 2] {
            var japanese = Calendar(identifier: .japanese)
            japanese.locale = Locale(identifier: "ja_JP")
            japanese.firstWeekday = firstWeekday
            japanese.timeZone = TimeZone(identifier: "Europe/Rome")!
            // Only the device timezone crosses the API boundary; identifier/locale/week settings cannot leak in.
            let other = RecurrenceCalculator(timeZone: japanese.timeZone)
            #expect(other.occurrences(rule: input, in: interval).map(\.key) == expected)
        }
    }

    @Test("UUIDv5 matches the RFC reference vector and is deterministic")
    func identifiers() {
        let namespace = UUID(uuidString: "6ba7b810-9dad-11d1-80b4-00c04fd430c8")!
        #expect(RecurrenceCalculator.occurrenceID(ruleId: namespace, key: "www.widgets.com").uuidString.lowercased() == "21f7f8de-8051-5b89-8680-0195ef798b6a")
        let first = RecurrenceCalculator.occurrenceID(ruleId: namespace, key: "2026-01-01")
        #expect(first == RecurrenceCalculator.occurrenceID(ruleId: namespace, key: "2026-01-01"))
        #expect(first != RecurrenceCalculator.occurrenceID(ruleId: namespace, key: "2026-01-02"))
        #expect(first != RecurrenceCalculator.occurrenceID(ruleId: UUID(), key: "2026-01-01"))
        #expect(first.uuid.6 >> 4 == 5)
        #expect(first.uuid.8 >> 6 == 2)
    }

    @Test("Invalid frequency and cross-month or malformed overrides are harmless")
    func invalidValues() {
        var input = rule(start: date(2026, 1, 15))
        input.exceptions["2026-01-15"] = RecurrenceException(amount: "invalid", date: date(2026, 2, 1))
        let interval = DateInterval(start: date(2026, 1, 1), end: date(2026, 2, 1))
        let result = calculator.occurrences(rule: input, in: interval)
        #expect(result.first?.date == date(2026, 1, 15))
        #expect(result.first?.amount == input.amount)
        input.frequency = "invalid"
        #expect(calculator.occurrences(rule: input, in: interval).isEmpty)
    }
}
