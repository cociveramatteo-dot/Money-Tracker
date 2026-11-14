import Foundation
import Testing
@testable import MoneyTracker

@Suite("Recurrence presentation cache")
@MainActor
struct RecurrencePresentationCacheTests {
    @Test("Invalidates on rule edits, interval changes and timezone changes")
    func invalidation() throws {
        let utc = try #require(TimeZone(secondsFromGMT: 0))
        let tokyo = try #require(TimeZone(identifier: "Asia/Tokyo"))
        let start = Date(timeIntervalSince1970: 1_767_225_600) // 2026-01-01 UTC
        let rule = RecurringRule(name: "Series", amount: 10, type: "uscita",
                                 frequency: "mensile", startDate: start)
        rule.startDate = start
        let january = DateInterval(start: start, duration: 31 * 86_400)
        let february = DateInterval(start: january.end, duration: 28 * 86_400)
        let cache = RecurrencePresentationCache()
        let first = cache.occurrences(rules: [rule], in: january, timeZone: utc)
        #expect(first.count == 1)
        #expect(cache.occurrences(rules: [rule], in: january, timeZone: utc).first?.date == first.first?.date)

        rule.name = "Edited"
        rule.amount = 25
        let edited = cache.occurrences(rules: [rule], in: january, timeZone: utc)
        #expect(edited.first?.name == "Edited")
        #expect(edited.first?.amount == 25)

        let next = cache.occurrences(rules: [rule], in: february, timeZone: utc)
        #expect(next.count == 1)
        #expect(next.first?.key == "2026-02-01")
        let shifted = cache.occurrences(rules: [rule], in: february, timeZone: tokyo)
        #expect(shifted.count == 1)
        #expect(shifted.first?.date != next.first?.date)
        #expect(shifted.first?.date == RecurrenceCalculator(timeZone: tokyo)
            .occurrences(rule: RecurringSeriesEditor.snapshot(rule), in: february).first?.date)
        #expect(cache.occurrences(rules: [], in: february, timeZone: tokyo).isEmpty)
    }
}
