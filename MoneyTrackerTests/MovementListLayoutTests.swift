import Foundation
import Testing
@testable import MoneyTracker

@Suite("Movement list layout")
@MainActor
struct MovementListLayoutTests {
    private static let calendar: Calendar = {
        var cal = Calendar(identifier: .gregorian)
        cal.timeZone = TimeZone(identifier: "Europe/Rome") ?? .current
        return cal
    }()

    private func day(_ year: Int, _ month: Int, _ day: Int) -> Date {
        Self.calendar.date(from: DateComponents(year: year, month: month, day: day, hour: 12))!
    }

    private func makeOccurrence(name: String, date: Date, amount: Decimal, type: TransactionType) -> Occurrence {
        Occurrence(
            ruleId: UUID(),
            key: "\(name)-\(date.timeIntervalSince1970)",
            originalDate: date,
            date: date,
            amount: amount,
            name: name,
            category: "Casa",
            categoryIcon: "house",
            type: type.rawValue,
            accountId: nil,
            isFixed: true,
            notes: "",
            isOverridden: false
        )
    }

    @Test func futureMonthCombinesPlannedAndVirtualsInAscendingOrderExcludingTransfersFromTotal() {
        let realPlannedLater = Transaction(
            name: "Bolletta",
            amount: 80,
            type: .uscita,
            category: "Casa",
            date: day(2026, 12, 20),
            isDone: false
        )
        let realPlannedEarlier = Transaction(
            name: "Regalo",
            amount: 50,
            type: .uscita,
            category: "Regali",
            date: day(2026, 12, 5),
            isDone: false
        )
        let realPlannedTransfer = Transaction(
            name: "Giroconto",
            amount: 500,
            type: .uscita,
            category: "Altro",
            date: day(2026, 12, 10),
            isDone: false,
            isTransfer: true
        )
        let realDone = Transaction(
            name: "Anticipo",
            amount: 100,
            type: .entrata,
            category: "Lavoro",
            date: day(2026, 12, 1),
            isDone: true
        )
        let virtualIncome = makeOccurrence(name: "Stipendio", date: day(2026, 12, 15), amount: 2000, type: .entrata)
        let virtualEarly = makeOccurrence(name: "Abbonamento", date: day(2026, 12, 2), amount: 12, type: .uscita)

        let result = MovementListLayout.make(
            real: [realPlannedLater, realPlannedEarlier, realPlannedTransfer, realDone],
            virtual: [virtualIncome, virtualEarly],
            isFutureMonth: true,
            calendar: Self.calendar
        )

        #expect(result.planned.count == 5)
        #expect(result.planned.map {
            switch $0 {
            case .real(let t): return t.name
            case .virtual(let o): return o.name
            }
        } == ["Abbonamento", "Regalo", "Giroconto", "Stipendio", "Bolletta"])

        let plannedTotal = result.planned.reduce(Decimal.zero) { $0 + $1.signedAmount }
        #expect(plannedTotal == Decimal(string: "1858")!) // +2000 - 12 - 50 - 80 (transfer excluded)
        #expect(result.days.count == 1)
        #expect(result.days[0].items.count == 1)
        #expect(result.planned.count + result.days.flatMap(\.items).count == 6)
    }

    @Test func currentMonthKeepsPlannedInsideDayGroupsInDisplayOrder() {
        let older = Transaction(
            name: "Spesa vecchia",
            amount: 20,
            type: .uscita,
            date: day(2026, 11, 10),
            isDone: true
        )
        older.createdAt = day(2026, 11, 10)

        let sameDayEarlier = Transaction(
            name: "Prima",
            amount: 10,
            type: .uscita,
            date: day(2026, 11, 20),
            isDone: true
        )
        sameDayEarlier.createdAt = day(2026, 11, 20)

        let sameDayPlannedNewer = Transaction(
            name: "Pianificata nuova",
            amount: 45,
            type: .uscita,
            date: day(2026, 11, 20),
            isDone: false
        )
        sameDayPlannedNewer.createdAt = day(2026, 11, 20).addingTimeInterval(3600)

        let result = MovementListLayout.make(
            real: [older, sameDayEarlier, sameDayPlannedNewer],
            virtual: [],
            isFutureMonth: false,
            calendar: Self.calendar
        )

        #expect(result.planned.isEmpty)
        #expect(result.days.count == 2)
        #expect(result.days[0].day == Self.calendar.startOfDay(for: day(2026, 11, 20)))
        #expect(result.days[0].items.map(\.rawID) == [sameDayPlannedNewer.id, sameDayEarlier.id])
        #expect(result.days[1].day == Self.calendar.startOfDay(for: day(2026, 11, 10)))
        #expect(result.days.flatMap(\.items).count == 3)
    }

    @Test func pastMonthWithUnconfirmedTransactionShowsItInDayGroupWithoutTopSection() {
        let pastPlanned = Transaction(
            name: "Pianificata passata",
            amount: 30,
            type: .uscita,
            date: day(2026, 10, 12),
            isDone: false
        )
        let pastDone = Transaction(
            name: "Fatta passata",
            amount: 15,
            type: .entrata,
            date: day(2026, 10, 12),
            isDone: true
        )
        pastDone.createdAt = pastPlanned.createdAt.addingTimeInterval(60)

        let result = MovementListLayout.make(
            real: [pastPlanned, pastDone],
            virtual: [],
            isFutureMonth: false,
            calendar: Self.calendar
        )

        #expect(result.planned.isEmpty)
        #expect(result.days.count == 1)
        #expect(result.days[0].items.count == 2)
        #expect(result.days[0].items.map(\.rawID) == [pastDone.id, pastPlanned.id])
    }

    @Test func preservesExactItemCountAcrossEmptyAndMixedInputs() {
        let real = [
            Transaction(name: "A", amount: 10, type: .uscita, date: day(2026, 12, 1), isDone: true),
            Transaction(name: "B", amount: 20, type: .uscita, date: day(2026, 12, 1), isDone: false),
        ]
        let virtual = [
            makeOccurrence(name: "V", date: day(2026, 12, 2), amount: 30, type: .uscita),
        ]

        let future = MovementListLayout.make(real: real, virtual: virtual, isFutureMonth: true, calendar: Self.calendar)
        let current = MovementListLayout.make(real: real, virtual: virtual, isFutureMonth: false, calendar: Self.calendar)
        let empty = MovementListLayout.make(real: [], virtual: [], isFutureMonth: true, calendar: Self.calendar)

        #expect(future.planned.count + future.days.flatMap(\.items).count == real.count + virtual.count)
        #expect(current.planned.count + current.days.flatMap(\.items).count == real.count + virtual.count)
        #expect(empty.planned.isEmpty && empty.days.isEmpty)
    }
}
