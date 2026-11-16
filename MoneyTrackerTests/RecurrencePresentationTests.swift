import Testing
import Foundation
import SwiftData
@testable import MoneyTracker

@Suite @MainActor
struct RecurrencePresentationTests {
    private func date(_ month: Int, _ day: Int) -> Date {
        Calendar(identifier: .gregorian).date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }

    @Test func resolvesOriginalDateAfterCopyWasMovedBackwards() throws {
        let container = try ModelContainer(for: Schema(versionedSchema: SchemaV3.self), configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let context = container.mainContext
        let rule = RecurringRule(name: "Rent", amount: 100, type: "uscita", frequency: "mensile", startDate: date(1, 15), materializedThrough: date(11, 1))
        context.insert(rule)
        let copy = Transaction(name: "Moved", amount: 120, type: .uscita, category: "Altro", date: date(2, 3), templateId: rule.id.uuidString)
        copy.id = RecurrenceCalculator.occurrenceID(ruleId: rule.id, key: "2026-11-15")
        context.insert(copy)
        let selection = try #require(RecurrenceSelection.resolve(copy, rules: [rule]))
        #expect(selection.occurrence.originalDate == date(11, 15))
        #expect(selection.rule.id == rule.id)
    }

    @Test func legacyCopyDoesNotOpenSeriesEditor() {
        let copy = Transaction(name: "Legacy", amount: 10, type: .uscita, category: "Altro", templateId: UUID().uuidString)
        #expect(RecurrenceSelection.resolve(copy, rules: []) == nil)
    }
}
