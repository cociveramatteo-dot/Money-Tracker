import Foundation
import Testing
@testable import MoneyTracker

@Suite("Next month summary")
@MainActor
struct NextMonthSummaryTests {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone.current
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func totalsCombineTransactionsAndVirtualsDeduplicatingMaterializedIds() {
        let nextMonth = day(2026, 12, 1)
        let sameMonthFixedExpense = Transaction(
            name: "Affitto",
            amount: 800,
            type: .uscita,
            category: "Casa",
            date: day(2026, 12, 5),
            isDone: false,
            isFixed: true
        )
        let sameMonthFixedIncome = Transaction(
            name: "Stipendio",
            amount: 2000,
            type: .entrata,
            category: "Stipendio",
            date: day(2026, 12, 10),
            isDone: false,
            isFixed: true
        )
        let sameMonthVariableIncome = Transaction(
            name: "Rimborso",
            amount: 150,
            type: .entrata,
            category: "Altro",
            date: day(2026, 12, 15),
            isDone: false,
            isFixed: false
        )
        let sameMonthTransfer = Transaction(
            name: "Giroconto",
            amount: 500,
            type: .uscita,
            category: "Trasferimento",
            date: day(2026, 12, 12),
            isDone: true,
            isFixed: true,
            isTransfer: true
        )
        let otherMonthFixed = Transaction(
            name: "Gennaio",
            amount: 999,
            type: .uscita,
            category: "Casa",
            date: day(2027, 1, 5),
            isDone: false,
            isFixed: true
        )

        let ruleA = UUID()
        let keyA = "2026-12-20"
        let virtualFixedExpense = Occurrence(
            ruleId: ruleA,
            key: keyA,
            originalDate: day(2026, 12, 20),
            date: day(2026, 12, 20),
            amount: 60,
            name: "Palestra",
            category: "Salute",
            categoryIcon: "figure.run",
            type: TransactionType.uscita.rawValue,
            accountId: nil,
            isFixed: true,
            notes: "",
            isOverridden: false
        )
        let virtualVariableIncome = Occurrence(
            ruleId: UUID(),
            key: "2026-12-22",
            originalDate: day(2026, 12, 22),
            date: day(2026, 12, 22),
            amount: 300,
            name: "Consulenza",
            category: "Lavoro",
            categoryIcon: "briefcase",
            type: TransactionType.entrata.rawValue,
            accountId: nil,
            isFixed: false,
            notes: "",
            isOverridden: false
        )

        // Materialized clone with same ID as virtualFixedExpense must not double-count
        let duplicateReal = Transaction(
            name: "Palestra",
            amount: 60,
            type: .uscita,
            category: "Salute",
            date: day(2026, 12, 20),
            isDone: true,
            isFixed: true
        )
        duplicateReal.id = virtualFixedExpense.id

        let totals = TransactionsView.nextMonthTotals(
            transactions: [
                sameMonthFixedExpense,
                sameMonthFixedIncome,
                sameMonthVariableIncome,
                sameMonthTransfer,
                otherMonthFixed,
                duplicateReal,
            ],
            virtualOccurrences: [virtualFixedExpense, virtualVariableIncome],
            nextMonth: nextMonth,
            selectedCategory: ""
        )

        #expect(totals == TransactionsView.NextMonthTotals(
            fixedExpenses: 860,
            fixedIncome: 2000,
            income: 2450
        ))
    }

    @Test func categoryFilterRestrictsBothTransactionsAndVirtualOccurrences() {
        let nextMonth = day(2026, 12, 1)
        let casaExpense = Transaction(
            name: "Affitto",
            amount: 700,
            type: .uscita,
            category: "Casa",
            date: day(2026, 12, 3),
            isFixed: true
        )
        let saluteExpense = Occurrence(
            ruleId: UUID(),
            key: "2026-12-10",
            originalDate: day(2026, 12, 10),
            date: day(2026, 12, 10),
            amount: 50,
            name: "Palestra",
            category: "Salute",
            categoryIcon: "figure.run",
            type: TransactionType.uscita.rawValue,
            accountId: nil,
            isFixed: true,
            notes: "",
            isOverridden: false
        )

        let casaTotals = TransactionsView.nextMonthTotals(
            transactions: [casaExpense],
            virtualOccurrences: [saluteExpense],
            nextMonth: nextMonth,
            selectedCategory: "Casa"
        )
        #expect(casaTotals == TransactionsView.NextMonthTotals(fixedExpenses: 700, fixedIncome: 0, income: 0))

        let saluteTotals = TransactionsView.nextMonthTotals(
            transactions: [casaExpense],
            virtualOccurrences: [saluteExpense],
            nextMonth: nextMonth,
            selectedCategory: "Salute"
        )
        #expect(saluteTotals == TransactionsView.NextMonthTotals(fixedExpenses: 50, fixedIncome: 0, income: 0))
    }
}
