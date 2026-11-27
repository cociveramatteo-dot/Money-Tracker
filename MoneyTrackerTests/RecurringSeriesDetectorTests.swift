import Foundation
import Testing
@testable import MoneyTracker

@Suite("Recurring series detector")
@MainActor
struct RecurringSeriesDetectorTests {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    @Test func requiresAtLeastThreeOccurrencesInThreeDistinctMonthsAndPreservesExactTotal() {
        let valid = [
            Transaction(name: "Palestra", amount: Decimal(string: "40.10")!, type: .uscita, category: "Salute", date: day(2026, 9, 5), isDone: true),
            Transaction(name: "Palestra", amount: Decimal(string: "40.20")!, type: .uscita, category: "Salute", date: day(2026, 10, 5), isDone: true),
            Transaction(name: "Palestra", amount: Decimal(string: "40.30")!, type: .uscita, category: "Salute", date: day(2026, 11, 5), isDone: true),
        ]
        let threeInTwoMonths = [
            Transaction(name: "Bar", amount: 5, type: .uscita, category: "Cibo", date: day(2026, 10, 1), isDone: true),
            Transaction(name: "Bar", amount: 5, type: .uscita, category: "Cibo", date: day(2026, 10, 15), isDone: true),
            Transaction(name: "Bar", amount: 5, type: .uscita, category: "Cibo", date: day(2026, 11, 1), isDone: true),
        ]
        let twoInTwoMonths = [
            Transaction(name: "Volo", amount: 200, type: .uscita, category: "Viaggi", date: day(2026, 9, 10), isDone: true),
            Transaction(name: "Volo", amount: 220, type: .uscita, category: "Viaggi", date: day(2026, 10, 10), isDone: true),
        ]

        let result = RecurringSeriesDetector.detect(from: valid + threeInTwoMonths + twoInTwoMonths)

        #expect(result.count == 1)
        let habit = result[0]
        #expect(habit.name == "Palestra")
        #expect(habit.count == 3)
        #expect(habit.frequency == "mensile")
        #expect(habit.totalAmount == Decimal(string: "120.60")!)
    }

    @Test func excludesTransfersBalanceAdjustmentsAndUnconfirmedTransactions() {
        let transfers = (1...5).map { month in
            Transaction(
                name: "Giroconto",
                amount: 180,
                type: .uscita,
                category: "Giroconto",
                date: day(2026, month, 5),
                isDone: true,
                isTransfer: true
            )
        }
        let adjustments = (1...5).map { month in
            Transaction(
                name: "Rettifica",
                amount: 50,
                type: .uscita,
                category: "Rettifica saldo",
                date: day(2026, month, 10),
                isDone: true
            )
        }
        let unconfirmed = (1...4).map { month in
            Transaction(
                name: "Affitto futuro",
                amount: 700,
                type: .uscita,
                category: "Casa",
                date: day(2026, month, 1),
                isDone: false
            )
        }

        let result = RecurringSeriesDetector.detect(from: transfers + adjustments + unconfirmed)
        #expect(result.isEmpty)
    }
}
