import Foundation
import Testing
@testable import MoneyTracker

@Suite("Recurring date collisions", .serialized) @MainActor
struct RecurringCollisionTests {
    @Test func twoCopiesMovedToSameDayKeepDistinctIDs() throws {
        let fixture = RecurringSeriesEditorTests()
        let (container, rule) = try fixture.setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try fixture.materialize(context)
        let before = try fixture.copies(context)
        let originalIDs = Set(before.map(\.id))
        var values = RecurringSeriesEditor.snapshot(rule)
        values.startDate = fixture.date(3, 10)
        for day in [1, 8] {
            try fixture.editor.apply(.edit(.onlyThis, values), to: rule,
                originalDate: fixture.date(3, day), context: context, now: fixture.date(3))
        }
        try fixture.materialize(context)
        let rows = try fixture.copies(context)
        #expect(rows.filter { $0.date == fixture.date(3, 10) }.count == 2)
        #expect(rows.count == before.count)
        #expect(Set(rows.map(\.id)).count == rows.count)
        #expect(Set(rows.map(\.id)) == originalIDs)
        let virtual = RecurrenceCalculator(timeZone: fixture.zone).occurrences(
            rule: RecurringSeriesEditor.snapshot(rule),
            in: DateInterval(start: fixture.date(3), end: fixture.date(4)))
        #expect(virtual.filter { $0.date == fixture.date(3, 10) }.count == 2)
        #expect(Set(virtual.map(\.id)).count == virtual.count)
    }
}
