import Foundation
import Testing
@testable import MoneyTracker

@Suite("Recurring section filter")
@MainActor
struct RecurringSectionFilterTests {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func keepsOnlyExistingRulesWithinSelectedMonthEvenWhenSearching() {
        let activeRuleID = UUID().uuidString
        let deletedRuleID = UUID().uuidString

        let inMonthActive = Transaction(
            name: "Bolletta Enel",
            amount: 90,
            type: .uscita,
            category: "Casa",
            date: day(2026, 11, 15),
            isDone: true,
            isFixed: true,
            templateId: activeRuleID
        )
        let otherMonthActive = Transaction(
            name: "Bolletta Enel",
            amount: 85,
            type: .uscita,
            category: "Casa",
            date: day(2026, 10, 15),
            isDone: true,
            isFixed: true,
            templateId: activeRuleID
        )
        let inMonthDeletedRule = Transaction(
            name: "Vecchio Abbonamento",
            amount: 12,
            type: .uscita,
            category: "Abbonamenti",
            date: day(2026, 11, 12),
            isDone: true,
            isFixed: true,
            templateId: deletedRuleID
        )
        let manualTx = Transaction(
            name: "Bolletta Enel",
            amount: 40,
            type: .uscita,
            category: "Casa",
            date: day(2026, 11, 20),
            isDone: true,
            templateId: ""
        )

        let filtered = RecurringSectionFilter.filterTransactions(
            [inMonthActive, otherMonthActive, inMonthDeletedRule, manualTx],
            ruleIDs: [activeRuleID],
            selectedMonth: day(2026, 11, 1),
            query: "Bolletta",
            selectedCategory: "",
            minAmount: nil,
            maxAmount: nil,
            useCustomDates: false,
            fromDate: day(2026, 10, 1),
            toDate: day(2026, 11, 30),
            calendar: Self.calendar
        )

        #expect(filtered.map(\.id) == [inMonthActive.id])
    }

    @Test func appliesCategoryAndAmountFilters() {
        let ruleA = UUID().uuidString
        let ruleB = UUID().uuidString

        let txCasa = Transaction(
            name: "Affitto",
            amount: 750,
            type: .uscita,
            category: "Casa",
            date: day(2026, 11, 3),
            isDone: false,
            isFixed: true,
            templateId: ruleA
        )
        let txSaluteSmall = Transaction(
            name: "Palestra",
            amount: 45,
            type: .uscita,
            category: "Salute",
            date: day(2026, 11, 5),
            isDone: true,
            isFixed: true,
            templateId: ruleB
        )

        let onlyCasa = RecurringSectionFilter.filterTransactions(
            [txCasa, txSaluteSmall],
            ruleIDs: [ruleA, ruleB],
            selectedMonth: day(2026, 11, 1),
            query: "",
            selectedCategory: "Casa",
            minAmount: nil,
            maxAmount: nil,
            useCustomDates: false,
            fromDate: day(2026, 11, 1),
            toDate: day(2026, 11, 30),
            calendar: Self.calendar
        )
        #expect(onlyCasa.map(\.id) == [txCasa.id])

        let min500 = RecurringSectionFilter.filterTransactions(
            [txCasa, txSaluteSmall],
            ruleIDs: [ruleA, ruleB],
            selectedMonth: day(2026, 11, 1),
            query: "",
            selectedCategory: "",
            minAmount: 500,
            maxAmount: 800,
            useCustomDates: false,
            fromDate: day(2026, 11, 1),
            toDate: day(2026, 11, 30),
            calendar: Self.calendar
        )
        #expect(min500.map(\.id) == [txCasa.id])
    }
}
