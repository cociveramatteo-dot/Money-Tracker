import Testing
import Foundation
@testable import MoneyTracker

@MainActor
@Suite("Ordine di visualizzazione movimenti")
struct TransactionDisplayOrderTests {

    private var utcCalendar: Calendar {
        var c = Calendar(identifier: .gregorian)
        c.timeZone = TimeZone(identifier: "UTC")!
        return c
    }

    private func date(year: Int = 2026, month: Int = 11, day: Int, hour: Int, minute: Int = 0) -> Date {
        utcCalendar.date(from: DateComponents(year: year, month: month, day: day, hour: hour, minute: minute))!
    }

    @Test("Stesso giorno: il movimento creato per ultimo sta in cima anche se ha un'ora più bassa")
    func sameCalendarDayOrdersByCreatedAtDescendingIgnoringHour() {
        let laterHourCreatedFirst = Transaction(
            name: "Cena",
            amount: 30,
            type: .uscita,
            date: date(day: 27, hour: 22)
        )
        laterHourCreatedFirst.createdAt = date(day: 27, hour: 10)

        let earlierHourCreatedLast = Transaction(
            name: "Colazione",
            amount: 5,
            type: .uscita,
            date: date(day: 27, hour: 8)
        )
        earlierHourCreatedLast.createdAt = date(day: 27, hour: 11)

        let ordered = [laterHourCreatedFirst, earlierHourCreatedLast].sortedForDisplay(calendar: utcCalendar)
        #expect(ordered.map(\.name) == ["Colazione", "Cena"])
    }

    @Test("Giorni diversi: vince sempre il giorno di calendario più recente")
    func differentDaysOrderByCalendarDayDescending() {
        let yesterdayCreatedLater = Transaction(
            name: "Ieri",
            amount: 12,
            type: .uscita,
            date: date(day: 26, hour: 23, minute: 59)
        )
        yesterdayCreatedLater.createdAt = date(day: 27, hour: 18)

        let todayCreatedEarlier = Transaction(
            name: "Oggi",
            amount: 8,
            type: .uscita,
            date: date(day: 27, hour: 1)
        )
        todayCreatedEarlier.createdAt = date(day: 27, hour: 9)

        let ordered = [yesterdayCreatedLater, todayCreatedEarlier].sortedForDisplay(calendar: utcCalendar)
        #expect(ordered.map(\.name) == ["Oggi", "Ieri"])
    }
}
