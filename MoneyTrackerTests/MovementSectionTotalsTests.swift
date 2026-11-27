import Foundation
import Testing
@testable import MoneyTracker

@Suite("Movement section totals")
@MainActor
struct MovementSectionTotalsTests {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeOccurrence(amount: Decimal, type: TransactionType, isFixed: Bool = true, category: String = "Casa") -> Occurrence {
        Occurrence(
            ruleId: UUID(),
            key: UUID().uuidString,
            originalDate: day(2026, 12, 10),
            date: day(2026, 12, 10),
            amount: amount,
            name: "Virtual",
            category: category,
            categoryIcon: "house",
            type: type.rawValue,
            accountId: nil,
            isFixed: isFixed,
            notes: "",
            isOverridden: false
        )
    }

    @Test func tuttiExcludesTransfersAndIncludesDonePlannedAndVirtual() {
        let doneExpense = Transaction(name: "Spesa", amount: 42, type: .uscita, category: "Cibo", date: day(2026, 11, 5), isDone: true)
        let plannedExpense = Transaction(name: "Bolletta", amount: 80, type: .uscita, category: "Casa", date: day(2026, 12, 5), isDone: false, isFixed: true)
        let doneIncome = Transaction(name: "Rimborso", amount: 150, type: .entrata, category: "Altro", date: day(2026, 11, 8), isDone: true)
        let transfer = Transaction(name: "Giroconto", amount: 500, type: .uscita, category: "Giroconto", date: day(2026, 11, 10), isDone: true, isFixed: true, isTransfer: true, transferGroupId: "grp1")
        let virtualIncome = makeOccurrence(amount: 2000, type: .entrata)
        let virtualExpense = makeOccurrence(amount: 30, type: .uscita)

        let totals = MovementSectionTotals.compute(
            real: [doneExpense, plannedExpense, doneIncome, transfer],
            virtual: [virtualIncome, virtualExpense]
        )

        #expect(totals == MovementSectionTotalsValue(expenses: 152, income: 2150, transferred: 500))
    }

    @Test func fisseExcludesFixedTransfers() {
        let fixedExpense = Transaction(name: "Affitto", amount: 800, type: .uscita, category: "Casa", date: day(2026, 11, 1), isDone: true, isFixed: true)
        let fixedTransfer = Transaction(name: "PAC", amount: 250, type: .uscita, category: "Giroconto", date: day(2026, 11, 2), isDone: true, isFixed: true, isTransfer: true, transferGroupId: "g1")
        let fixedVirtualIncome = makeOccurrence(amount: 1200, type: .entrata, isFixed: true)

        let totals = MovementSectionTotals.compute(real: [fixedExpense, fixedTransfer], virtual: [fixedVirtualIncome])
        #expect(totals.expenses == 800)
        #expect(totals.income == 1200)
        #expect(totals.transferred == 250)
    }

    @Test func usciteAndEntrateSumPassedRows() {
        let expensesOnly = [
            Transaction(name: "A", amount: 25, type: .uscita, date: day(2026, 11, 1), isDone: true),
            Transaction(name: "B", amount: 75, type: .uscita, date: day(2026, 11, 2), isDone: false),
        ]
        let expensesTotals = MovementSectionTotals.compute(real: expensesOnly, virtual: [makeOccurrence(amount: 10, type: .uscita)])
        #expect(expensesTotals == MovementSectionTotalsValue(expenses: 110, income: 0, transferred: 0))

        let incomeOnly = [
            Transaction(name: "Stipendio", amount: 1800, type: .entrata, date: day(2026, 11, 1), isDone: true),
        ]
        let incomeTotals = MovementSectionTotals.compute(real: incomeOnly, virtual: [makeOccurrence(amount: 200, type: .entrata)])
        #expect(incomeTotals == MovementSectionTotalsValue(expenses: 0, income: 2000, transferred: 0))
    }

    @Test func trasferitoDeduplicatesByGroupIdAndCountsOrphanLegsIndividually() {
        let leg1 = Transaction(name: "Giro", amount: 300, type: .uscita, category: "Giroconto", date: day(2026, 11, 3), isDone: true, isTransfer: true, transferGroupId: "ABC-123")
        let leg2 = Transaction(name: "Giro", amount: 300, type: .entrata, category: "Giroconto", date: day(2026, 11, 3), isDone: true, isTransfer: true, transferGroupId: "abc-123")
        let orphan1 = Transaction(name: "Orfano 1", amount: 50, type: .uscita, category: "Giroconto", date: day(2026, 11, 4), isDone: true, isTransfer: true, transferGroupId: "")
        let orphan2 = Transaction(name: "Orfano 2", amount: 75, type: .entrata, category: "Giroconto", date: day(2026, 11, 5), isDone: false, isTransfer: true, transferGroupId: "")

        let totals = MovementSectionTotals.compute(real: [leg1, leg2, orphan1, orphan2], virtual: [])
        #expect(totals.transferred == 425)
        #expect(totals.expenses == 0)
        #expect(totals.income == 0)
    }

    @Test func emptyListReturnsZero() {
        let totals = MovementSectionTotals.compute(real: [], virtual: [])
        #expect(totals == MovementSectionTotalsValue(expenses: 0, income: 0, transferred: 0))
    }

    @Test func decimalPrecisionExactForClassicBinaryTrapsAndHundredCentsRows() {
        let t1 = Transaction(name: "Uno", amount: Decimal(string: "0.10")!, type: .uscita, date: day(2026, 11, 1), isDone: true)
        let t2 = Transaction(name: "Due", amount: Decimal(string: "0.20")!, type: .uscita, date: day(2026, 11, 2), isDone: true)
        let classic = MovementSectionTotals.compute(real: [t1, t2], virtual: [])
        #expect(classic.expenses == Decimal(string: "0.30")!)

        let hundredRows = (0..<100).map { i in
            Transaction(name: "R\(i)", amount: Decimal(string: "1.19")!, type: .uscita, date: day(2026, 11, 1), isDone: true)
        }
        let many = MovementSectionTotals.compute(real: hundredRows, virtual: [])
        #expect(many.expenses == Decimal(string: "119.00")!)
    }
}
