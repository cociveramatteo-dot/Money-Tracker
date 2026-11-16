import Foundation
import Testing
@testable import MoneyTracker

@Suite("Monthly spending comparison")
struct MonthlySpendingComparisonTests {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return result
    }
    private func date(_ day: Int, month: Int = 11, hour: Int = 12) throws -> Date {
        try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: hour)))
    }
    private func entry(_ day: Int, _ amount: Decimal, category: String = "Cibo", month: Int = 11,
                       done: Bool = true, transfer: Bool = false, expense: Bool = true, hour: Int = 12) throws -> MonthlySpendingComparison.Entry {
        .init(date: try date(day, month: month, hour: hour), amount: amount, category: category,
              isExpense: expense, isDone: done, isTransfer: transfer)
    }
    private func compare(_ entries: [MonthlySpendingComparison.Entry], day: Int = 15,
                         month: Int = 11, referenceMonth: Int = 11) throws -> MonthlySpendingComparison {
        try #require(MonthlySpendingComparison.make(entries: entries, month: try date(1, month: month),
                     now: try date(day, month: referenceMonth), calendar: calendar))
    }

    @Test("An empty previous month has no percentage baseline")
    func previousEmpty() throws {
        let result = try compare([entry(4, 100)])
        #expect(result.total.current == 100)
        #expect(result.total.previous == 0)
        #expect(result.total.direction == .noPreviousData)
        #expect(result.total.percentage == nil)
    }
    @Test("Zero divided by zero is represented as no data, never an invented rate")
    func zeroBaseline() throws {
        let result = try compare([entry(1, 0), entry(1, 0, month: 10)])
        #expect(result.total.direction == .noData)
        #expect(result.total.percentage == nil)
        #expect(result.categories.first?.percentage == nil)
    }
    @Test("A new category and a disappearing category remain separate from the total")
    func newCategory() throws {
        let result = try compare([entry(2, 50, category: "Cibo", month: 10),
                                  entry(2, 75, category: "Casa")])
        let added = try #require(result.categories.first { $0.category == "Casa" })
        let removed = try #require(result.categories.first { $0.category == "Cibo" })
        #expect(added.direction == .noPreviousData && added.percentage == nil)
        #expect(removed.direction == .lower && removed.percentage == 100)
        #expect(result.total.direction == .higher && result.total.percentage == 50)
    }
    @Test("Mid-month compares complete days 1–15 in both months, with half-open boundaries")
    func matchingDays() throws {
        let entries = try [entry(1, 50), entry(15, 62), entry(16, 900), entry(16, 700, hour: 0),
                           entry(1, 40, month: 10), entry(15, 60, month: 10), entry(16, 800, month: 10),
                           entry(16, 600, month: 10, hour: 0)]
        let result = try compare(entries)
        #expect(result.comparedDays == 15)
        #expect(result.total.current == 112 && result.total.previous == 100)
        #expect(result.total.percentage == 12)
        #expect(result.currentPeriod.end == (try date(16, hour: 0)))
        #expect(result.previousPeriod.end == (try date(16, month: 10, hour: 0)))
    }
    @Test("Completed months of different lengths use the common number of days")
    func shortMonth() throws {
        let result = try compare([entry(28, 90, month: 3), entry(29, 900, month: 3),
                                  entry(28, 80, month: 2)], month: 3)
        #expect(result.comparedDays == 28)
        #expect(result.total.current == 90 && result.total.previous == 80)
        #expect(result.total.percentage == Decimal(125) / 10)
    }
    @Test("Income, transfers and planned transactions are excluded; amounts stay Decimal")
    func eligibilityAndPrecision() throws {
        let result = try compare([entry(1, Decimal(29) / 100), entry(1, Decimal(58) / 100, month: 10),
                                  entry(1, 100, done: false), entry(1, 100, transfer: true),
                                  entry(1, 100, expense: false)])
        #expect(result.total.current == Decimal(29) / 100)
        #expect(result.total.previous == Decimal(58) / 100)
        #expect(result.total.direction == .lower && result.total.percentage == 50)
    }
    @Test("Future selected months do not compare days that have not elapsed")
    func futureMonth() throws {
        let result = try compare([entry(1, 100, month: 12)], month: 12)
        #expect(result.comparedDays == 0)
        #expect(result.total.direction == .noData)
        #expect(result.categories.isEmpty)
    }
}

@Suite("Monthly comparison ordering and percentage format")
struct MonthlyComparisonOrderingTests {
    private var calendar: Calendar {
        var result = Calendar(identifier: .gregorian)
        result.timeZone = TimeZone(secondsFromGMT: 0) ?? .gmt
        return result
    }
    private func entry(_ day: Int, _ amount: Decimal, _ category: String, month: Int = 11) throws -> MonthlySpendingComparison.Entry {
        let date = try #require(calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12)))
        return .init(date: date, amount: amount, category: category, isExpense: true, isDone: true, isTransfer: false)
    }

    @Test("Categories are ordered by absolute change descending, ties alphabetical")
    func ordering() throws {
        let entries = [try entry(2, 100, "Zeta"), try entry(2, 150, "Beta", month: 10),
                       try entry(3, 50, "Alfa"), try entry(3, 100, "Alfa", month: 10),
                       try entry(4, 10, "Cibo"), try entry(4, 60, "Cibo", month: 10),
                       try entry(5, 500, "Gamma")]
        let now = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 15)))
        let month = try #require(calendar.date(from: DateComponents(year: 2026, month: 11, day: 1)))
        let result = try #require(MonthlySpendingComparison.make(entries: entries, month: month, now: now, calendar: calendar))
        // Gamma 500, Beta 150, poi Alfa/Cibo/Zeta... Alfa 50, Cibo 50, Zeta 100
        #expect(result.categories.map(\.category) == ["Gamma", "Beta", "Zeta", "Alfa", "Cibo"])
    }

    @Test("Percentages of 100 or more keep every integer digit")
    func largePercentage() {
        let en = Locale(identifier: "en_US")
        #expect(SpendingComparisonCard.formatPercentage(1234, locale: en) == "1,234")
        #expect(SpendingComparisonCard.formatPercentage(100, locale: en) == "100")
        #expect(SpendingComparisonCard.formatPercentage(Decimal(string: "12.345")!, locale: en) == "12.3")
    }
}
