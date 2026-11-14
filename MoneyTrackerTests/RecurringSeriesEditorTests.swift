import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Recurring series editor", .serialized) @MainActor
struct RecurringSeriesEditorTests {
    let zone = TimeZone(identifier: "Europe/Rome")!
    var calendar: Calendar {
        var calendar = Calendar(identifier: .gregorian); calendar.timeZone = zone; return calendar
    }
    func date(_ month: Int, _ day: Int = 1) -> Date {
        calendar.date(from: DateComponents(year: 2026, month: month, day: day, hour: 12))!
    }
    func setup(frequency: String = "mensile", start: Int = 1) throws -> (ModelContainer, RecurringRule) {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let rule = RecurringRule(name: "Base", amount: Decimal(string: "0.2")!, type: "Uscita",
                                 frequency: frequency, startDate: date(start))
        container.mainContext.insert(rule)
        try container.mainContext.save()
        return (container, rule)
    }
    func copies(_ context: ModelContext) throws -> [Transaction] { try context.fetch(FetchDescriptor<Transaction>()) }
    var editor: RecurringSeriesEditor { RecurringSeriesEditor(timeZone: zone) }
    func materialize(_ context: ModelContext, month: Int = 3) throws {
        try RecurringMaterializer(timeZone: zone).materializeDue(context: context, now: date(month))
    }

    @Test func onlyThisOverrideAndDelete() throws {
        let (container, rule) = try setup()
        let context = container.mainContext
        try materialize(context)
        var values = RecurringSeriesEditor.snapshot(rule)
        values.amount = Decimal(string: "0.1")!; values.name = "Override"; values.startDate = date(3, 15)
        try editor.apply(.edit(.onlyThis, values), to: rule, originalDate: date(3), context: context, now: date(3))
        let copy = try #require(copies(context).first)
        #expect(copy.amount == Decimal(string: "0.1")! && copy.date == date(3, 15))
        #expect(copy.name == "Override" && rule.amount == Decimal(string: "0.2")!)
        #expect(RecurrenceExceptionCodec.decode(rule.exceptionsJSON)["2026-03-01"]?.amount == "0.1")
        try editor.apply(.delete(.onlyThis), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(try copies(context).isEmpty)
        #expect(RecurrenceExceptionCodec.decode(rule.exceptionsJSON)["2026-03-01"]?.skip == true)
        try materialize(context)
        #expect(try copies(context).isEmpty)
    }

    @Test func skipWeeklyMonthKeepsDone() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try materialize(context)
        let done = try #require(copies(context).first)
        done.isDone = true; try context.save()
        try editor.apply(.skipMonth, to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(try copies(context).map(\.id) == [done.id])
        #expect(RecurrenceExceptionCodec.decode(rule.exceptionsJSON).count == 5)
        #expect(done.isDone && done.amount == Decimal(string: "0.2")!)
    }

    @Test func terminateAndDeleteFollowing() throws {
        for after in [false, true] {
            let (container, rule) = try setup(frequency: "settimanale", start: 3)
            let context = container.mainContext
            try materialize(context)
            let done = try #require(copies(context).first { $0.date == date(3, 22) })
            done.isDone = true; try context.save()
            try editor.apply(.terminate(afterThis: after), to: rule, originalDate: date(3, 15), context: context, now: date(3))
            #expect(rule.endDate == date(3, after ? 15 : 14))
            #expect(try copies(context).count == (after ? 4 : 3))
            #expect(done.isDone)
        }
        let (container, rule) = try setup()
        try materialize(container.mainContext)
        try editor.apply(.delete(.following), to: rule, originalDate: date(3), context: container.mainContext, now: date(3))
        #expect(try copies(container.mainContext).isEmpty)
        #expect(rule.endDate == date(2, 28))
    }

    @Test func deleteAllAfterTerminatingBeforeFirstOccurrence() throws {
        let (container, rule) = try setup()
        let context = container.mainContext
        try materialize(context)
        try editor.apply(.terminate(afterThis: false), to: rule, originalDate: date(1), context: context, now: date(3))
        #expect(try #require(rule.endDate) < rule.startDate)
        let result = try editor.apply(.delete(.all), to: rule, originalDate: date(1), context: context, now: date(3))
        #expect(result == nil)
        #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0)
        #expect(try copies(context).isEmpty)
    }

    @Test func editAllReconcilesAndPreservesDone() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try materialize(context)
        let done = try #require(copies(context).first { $0.date == date(3, 8) })
        done.isDone = true; try context.save()
        var values = RecurringSeriesEditor.snapshot(rule)
        values.amount = Decimal(string: "0.1")!; values.name = "New"
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(done.amount == Decimal(string: "0.2")! && done.name == "Base")
        #expect(try copies(context).filter { !$0.isDone }.allSatisfy { $0.name == "New" && $0.amount == Decimal(string: "0.1")! })
        values.frequency = "mensile"; values.startDate = date(3, 20)
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(try copies(context).count == 2)
        #expect(rule.exceptionsJSON == "{}")
        #expect(try copies(context).contains { !$0.isDone && $0.date == date(3, 20) })
    }

    @Test func splitDropsFutureExceptionsAndReconciles() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        rule.exceptionsJSON = try RecurrenceExceptionCodec.encode([
            "2026-03-01": RecurrenceException(name: "Earlier"), "2026-04-05": RecurrenceException(skip: true)])
        try materialize(context)
        var values = RecurringSeriesEditor.snapshot(rule); values.amount = 5
        let fresh = try #require(try editor.apply(.edit(.following, values), to: rule, originalDate: date(3, 15), context: context, now: date(3)))
        #expect(fresh.id != rule.id && fresh.startDate == date(3, 15))
        #expect(rule.endDate == date(3, 14) && fresh.exceptionsJSON == "{}")
        #expect(RecurrenceExceptionCodec.decode(rule.exceptionsJSON).count == 1)
        #expect(try copies(context).filter { $0.templateId == fresh.id.uuidString }.count == 3)
        #expect(try copies(context).filter { $0.templateId == rule.id.uuidString }.count == 2)
    }

    @Test func deleteAllAndOnlyThisNeverTouchDoneOrLegacy() throws {
        for scope in [RecurringSeriesEditor.Scope.onlyThis, .all] {
            let (container, rule) = try setup()
            let context = container.mainContext
            try materialize(context)
            let done = try #require(copies(context).first); done.isDone = true
            let legacy = Transaction(name: "Legacy", amount: 10, type: .uscita, recurringFrequency: "mensile")
            context.insert(legacy); try context.save()
            try editor.apply(.delete(scope), to: rule, originalDate: date(3), context: context, now: date(3))
            #expect(try copies(context).count == 2)
            #expect(done.isDone && legacy.recurringFrequency == "mensile")
            #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == (scope == .all ? 0 : 1))
        }
    }

    @Test func futureNilWatermarkStaysDueAndDoesNotCreateHistory() throws {
        let (container, rule) = try setup(start: 8)
        let context = container.mainContext
        var values = RecurringSeriesEditor.snapshot(rule); values.amount = 4
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(8), context: context, now: date(3))
        #expect(rule.materializedThrough == nil)
        #expect(try copies(context).isEmpty)
        try materialize(context)
        #expect(try copies(context).isEmpty)
        try materialize(context, month: 8)
        #expect(try copies(context).count == 1)
        #expect(try copies(context).first?.amount == 4)
    }

    @Test func virtualOverrideAndCrossMonthValidation() throws {
        let (container, rule) = try setup()
        let context = container.mainContext
        var values = RecurringSeriesEditor.snapshot(rule); values.startDate = date(8, 10)
        try editor.apply(.edit(.onlyThis, values), to: rule, originalDate: date(8), context: context, now: date(3))
        #expect(try copies(context).isEmpty)
        values.startDate = date(9)
        #expect(throws: RecurringSeriesEditor.EditorError.self) {
            try editor.apply(.edit(.onlyThis, values), to: rule, originalDate: date(8), context: context)
        }
        #expect(RecurrenceExceptionCodec.decode(rule.exceptionsJSON)["2026-08-01"]?.date == date(8, 10))
        let other = ModelContext(container)
        #expect(throws: RecurringSeriesEditor.EditorError.self) {
            try editor.apply(.delete(.all), to: rule, originalDate: date(8), context: other)
        }
    }

    @Test func saveFailureIsVisibleAndRestoresOnlyOwnChanges() throws {
        struct Failure: Error {}
        let (container, rule) = try setup()
        let context = container.mainContext
        try materialize(context)
        let unrelated = Transaction(name: "Pending", amount: 8, type: .entrata)
        context.insert(unrelated)
        let failing = RecurringSeriesEditor(timeZone: zone, save: { _ in throw Failure() })
        var values = RecurringSeriesEditor.snapshot(rule); values.amount = 9
        let status = RecurrenceOperationStatus()
        #expect(!status.perform {
            try failing.apply(.edit(.all, values), to: rule, originalDate: date(3), context: context, now: date(3))
        })
        #expect(status.errorMessage?.isEmpty == false)
        #expect(rule.amount == Decimal(string: "0.2")!)
        #expect(try copies(context).first { $0.templateId == rule.id.uuidString }?.amount == Decimal(string: "0.2")!)
        #expect(try copies(context).contains { $0.id == unrelated.id })
        #expect(!status.perform { throw RecurringMaterializer.MaterializationError.saveFailed })
        #expect(status.errorMessage != nil)
    }
    @Test func deletionAndSplitFailuresRestorePersistedObjects() throws {
        struct Failure: Error {}
        for action in [0, 1, 2] {
            let (container, rule) = try setup()
            let context = container.mainContext
            try materialize(context)
            let originalID = try #require(copies(context).first?.id)
            let failing = RecurringSeriesEditor(timeZone: zone, save: { _ in throw Failure() })
            let values = RecurringSeriesEditor.snapshot(rule)
            let command: RecurringSeriesEditor.Action = action == 0 ? .delete(.all)
                : action == 1 ? .edit(.following, values) : .delete(.onlyThis)
            #expect(throws: Failure.self) {
                try failing.apply(command, to: rule, originalDate: date(3), context: context, now: date(3))
            }
            try context.save()
            #expect(try copies(context).map(\.id) == [originalID])
            #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 1)
            #expect(rule.endDate == nil && rule.exceptionsJSON == "{}")
        }
    }

    @Test func allFrequenciesAndDoneEdits() throws {
        for frequency in ["mensile", "settimanale", "annuale"] {
            let (container, rule) = try setup(frequency: frequency, start: 3)
            let context = container.mainContext
            try materialize(context)
            let done = try #require(copies(context).first { $0.date == date(3) })
            done.isDone = true; try context.save()
            var values = RecurringSeriesEditor.snapshot(rule)
            values.amount = 7; values.startDate = date(3, 2)
            try editor.apply(.edit(.onlyThis, values), to: rule, originalDate: date(3), context: context, now: date(3))
            #expect(done.amount == Decimal(string: "0.2")! && done.date == date(3))
            try editor.apply(.delete(.all), to: rule, originalDate: date(3), context: context, now: date(3))
            #expect(try copies(context).map(\.id) == [done.id])
        }
    }

    @Test func splitDoesNotDuplicateCompletedCurrentOccurrence() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try materialize(context)
        let done = try #require(copies(context).first { $0.date == date(3, 22) })
        done.isDone = true; try context.save()
        var values = RecurringSeriesEditor.snapshot(rule); values.amount = 8
        try editor.apply(.edit(.following, values), to: rule, originalDate: date(3, 15), context: context, now: date(3))
        #expect(try copies(context).count == 5)
        #expect(try copies(context).filter { $0.date == date(3, 22) }.map(\.id) == [done.id])
        #expect(done.amount == Decimal(string: "0.2")! && done.isDone)
        try materialize(context)
        #expect(try copies(context).count == 5)
    }

}
