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

    @Test func deleteMonthlyFixedSeriesAllScopes() throws {
        for scope in [RecurringSeriesEditor.Scope.onlyThis, .following, .all] {
            let (container, rule) = try setup()
            let context = container.mainContext
            rule.isFixed = true
            for month in 1...4 { try materialize(context, month: month) }
            let unrelated = Transaction(name: "Unrelated", amount: 5, type: .uscita)
            context.insert(unrelated)
            try context.save()
            let ruleID = rule.id.uuidString
            let result = try editor.apply(.delete(scope), to: rule, originalDate: date(3), context: context, now: date(3))
            let remaining = try copies(context)
            #expect(remaining.contains { $0.id == unrelated.id })
            let seriesDates = Set(remaining.filter { $0.templateId == ruleID }.map(\.date))
            switch scope {
            case .onlyThis: #expect(seriesDates == Set([date(1), date(2), date(4)]))
            case .following: #expect(seriesDates == Set([date(1), date(2)]))
            case .all: #expect(seriesDates.isEmpty && result == nil)
            }
            #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == (scope == .all ? 0 : 1))
            try materialize(context, month: 5)
            #expect(try copies(context).filter { $0.templateId == ruleID && $0.date == date(3) }.isEmpty)
            if scope != .onlyThis {
                #expect(try copies(context).filter { $0.templateId == ruleID && $0.date >= date(3) }.isEmpty)
            }
        }
    }

    // S-24 regression: the original civil day includes morning transactions.
    @Test func deleteFollowingIncludesSelectedCopyBeforeNoon() throws {
        let (container, rule) = try setup(start: 3)
        let context = container.mainContext
        rule.isFixed = true
        try materialize(context)
        let copy = try #require(copies(context).first)
        copy.date = try #require(calendar.date(bySettingHour: 8, minute: 0, second: 0, of: date(3)))
        try context.save()
        try editor.apply(.delete(.following), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(try copies(context).isEmpty, "Following must include the selected civil day, including morning transactions")
    }

    @Test func everyFieldRespectsScopeAcrossHistoryAndFuture() throws {
        for scope in [RecurringSeriesEditor.Scope.onlyThis, .following, .all] {
            let (container, rule) = try setup()
            let context = container.mainContext
            let account = Account(name: "Series account", type: .conto)
            context.insert(account)
            rule.accountId = account.id
            for month in 1...4 { try materialize(context, month: month) }
            for copy in try copies(context) where copy.date == date(1) || copy.date == date(3) { copy.isDone = true }
            try context.save()
            var values = RecurringSeriesEditor.snapshot(rule)
            values.name = "Uniform"; values.amount = 42; values.category = "Casa"; values.categoryIcon = "house"
            values.type = TransactionType.entrata.rawValue; values.notes = "New notes"; values.isFixed = true
            values.accountId = nil
            if scope == .onlyThis { values.startDate = date(3, 15) }
            let result = try #require(try editor.apply(.edit(scope, values), to: rule, originalDate: date(3), context: context, now: date(3)))
            let rows = try copies(context)
            #expect(rows.count == 4)
            for copy in rows {
                let month = calendar.component(.month, from: copy.date)
                let changed = scope == .all || (scope == .following ? month >= 3 : month == 3)
                #expect(copy.name == (changed ? "Uniform" : "Base"))
                #expect(copy.amount == (changed ? 42 : Decimal(string: "0.2")!))
                #expect(copy.category == (changed ? "Casa" : "Altro"))
                #expect(copy.categoryIcon == (changed ? "house" : "circle.dotted"))
                #expect(copy.type == (changed ? TransactionType.entrata.rawValue : TransactionType.uscita.rawValue))
                #expect(copy.notes == (changed ? "New notes" : ""))
                #expect(copy.isFixed == changed)
                #expect(copy.account?.id == (changed ? nil : account.id))
                #expect(copy.isDone == (month == 1 || month == 3))
            }
            let future = try #require(RecurrenceCalculator(timeZone: zone).occurrences(
                rule: RecurringSeriesEditor.snapshot(result), in: DateInterval(start: date(5), end: date(6))).first)
            #expect(future.name == (scope == .onlyThis ? "Base" : "Uniform"))
            #expect(future.category == (scope == .onlyThis ? "Altro" : "Casa"))
            #expect(future.accountId == (scope == .onlyThis ? account.id : nil))
            if scope == .onlyThis {
                // No materialized copy: all override fields must also survive JSON/virtual rendering.
                values.startDate = date(8, 15)
                try editor.apply(.edit(.onlyThis, values), to: rule, originalDate: date(8), context: context, now: date(4))
                let virtual = try #require(RecurrenceCalculator(timeZone: zone).occurrences(
                    rule: RecurringSeriesEditor.snapshot(rule), in: DateInterval(start: date(8), end: date(9))).first)
                #expect(virtual.name == "Uniform" && virtual.amount == 42 && virtual.notes == "New notes")
                #expect(virtual.category == "Casa" && virtual.categoryIcon == "house" && virtual.type == TransactionType.entrata.rawValue)
                #expect(virtual.isFixed && virtual.accountId == nil && virtual.date == date(8, 15))
                try materialize(context, month: 8)
                #expect(try copies(context).first { $0.id == virtual.id }?.category == "Casa")
            }
        }
    }

    @Test func allReplacesPriorOverridesButPreservesSkipsAndCompletion() throws {
        let (container, rule) = try setup()
        let context = container.mainContext
        for month in 1...4 { try materialize(context, month: month) }
        var single = RecurringSeriesEditor.snapshot(rule)
        single.name = "Single"; single.amount = 7; single.category = "Casa"; single.startDate = date(3, 15)
        try editor.apply(.edit(.onlyThis, single), to: rule, originalDate: date(3), context: context, now: date(4))
        try editor.apply(.delete(.onlyThis), to: rule, originalDate: date(2), context: context, now: date(4))
        let completed = try #require(copies(context).first { $0.date == date(1) })
        completed.isDone = true
        var all = RecurringSeriesEditor.snapshot(rule)
        all.name = "All"; all.amount = 9; all.category = "Salute"; all.categoryIcon = "heart"
        try editor.apply(.edit(.all, all), to: rule, originalDate: date(3), context: context, now: date(4))
        #expect(completed.name == "All" && completed.isDone)
        #expect(try copies(context).allSatisfy { $0.name == "All" && $0.amount == 9 && $0.category == "Salute" })
        #expect(try copies(context).contains { $0.date == date(3) })
        #expect(try copies(context).allSatisfy { $0.date != date(3, 15) && $0.date != date(2) })
        let exceptions = RecurrenceExceptionCodec.decode(rule.exceptionsJSON)
        #expect(exceptions.count == 1 && exceptions["2026-02-01"]?.skip == true)
    }

    @Test func deleteFollowingUsesOriginalDayOfMovedCopy() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try materialize(context)
        var override = RecurringSeriesEditor.snapshot(rule)
        override.startDate = date(3, 2)
        try editor.apply(.edit(.onlyThis, override), to: rule, originalDate: date(3, 15), context: context, now: date(3))
        try editor.apply(.delete(.following), to: rule, originalDate: date(3, 15), context: context, now: date(3))
        #expect(try copies(context).map(\.date).sorted() == [date(3), date(3, 8)])
    }

    @Test func allDateChangeReschedulesHistoryAndClampsShortMonths() throws {
        let (container, rule) = try setup()
        let context = container.mainContext
        rule.startDate = date(1, 31)
        for month in 1...3 { try materialize(context, month: month) }
        let done = try #require(copies(context).first { $0.date == date(1, 31) })
        done.isDone = true
        var values = RecurringSeriesEditor.snapshot(rule); values.startDate = date(1, 30)
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(3, 31), context: context, now: date(3))
        #expect(try copies(context).map(\.date).sorted() == [date(1, 30), date(2, 28), date(3, 30)])
        #expect(done.isDone && done.date == date(1, 30))
        for copy in try copies(context) {
            #expect(copy.id == RecurrenceCalculator.occurrenceID(ruleId: rule.id, key: RecurrenceCalculator(timeZone: zone).key(for: copy.date)))
        }
        try materialize(context, month: 4)
        #expect(try copies(context).map(\.date).sorted() == [date(1, 30), date(2, 28), date(3, 30), date(4, 30)])
    }

    @Test func failedRescheduleRestoresDatesIdentitiesAndOverrides() throws {
        struct Failure: Error {}
        for scope in [RecurringSeriesEditor.Scope.all, .following] {
            let (container, rule) = try setup()
            let context = container.mainContext
            for month in 1...4 { try materialize(context, month: month) }
            let rows = try copies(context)
            let ids = rows.map(\.id), dates = rows.map(\.date), templates = rows.map(\.templateId)
            var values = RecurringSeriesEditor.snapshot(rule)
            values.startDate = date(1, 15); values.frequency = "settimanale"; values.category = "Casa"
            let failing = RecurringSeriesEditor(timeZone: zone, save: { _ in throw Failure() })
            #expect(throws: Failure.self) {
                try failing.apply(.edit(scope, values), to: rule, originalDate: date(3), context: context, now: date(3))
            }
            try context.save()
            #expect(rows.map(\.id) == ids && rows.map(\.date) == dates && rows.map(\.templateId) == templates)
            #expect(rows.allSatisfy { $0.category == "Altro" })
            #expect(try copies(context).count == 4)
            #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 1)
        }
    }

    @Test func categoryEditsOnCopyAndAllSeries() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try materialize(context)
        let copy = try #require(copies(context).first { $0.date == date(3) })
        let originalCategory = rule.category
        let originalExceptions = rule.exceptionsJSON
        copy.category = "Casa"; copy.categoryIcon = "house"
        try context.save()
        try materialize(context, month: 4)
        #expect(copy.category == "Casa" && copy.categoryIcon == "house")
        #expect(rule.category == originalCategory && rule.exceptionsJSON == originalExceptions)
        #expect(try copies(context).filter { $0.id != copy.id }.allSatisfy { $0.category == originalCategory })
        copy.isDone = true; try context.save()
        var values = RecurringSeriesEditor.snapshot(rule)
        values.category = "Trasporti"; values.categoryIcon = "car"
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(rule.category == "Trasporti" && rule.categoryIcon == "car")
        #expect(copy.category == "Trasporti" && copy.categoryIcon == "car")
        #expect(try copies(context).filter { !$0.isDone && calendar.isDate($0.date, equalTo: date(3), toGranularity: .month) }
            .allSatisfy { $0.category == "Trasporti" && $0.categoryIcon == "car" })
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

    @Test func editAllReconcilesAndUpdatesDone() throws {
        let (container, rule) = try setup(frequency: "settimanale", start: 3)
        let context = container.mainContext
        try materialize(context)
        let done = try #require(copies(context).first { $0.date == date(3, 8) })
        done.isDone = true; try context.save()
        var values = RecurringSeriesEditor.snapshot(rule)
        values.amount = Decimal(string: "0.1")!; values.name = "New"
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(done.amount == Decimal(string: "0.1")! && done.name == "New" && done.isDone)
        #expect(try copies(context).filter { !$0.isDone }.allSatisfy { $0.name == "New" && $0.amount == Decimal(string: "0.1")! })
        values.frequency = "mensile"; values.startDate = date(3, 20)
        try editor.apply(.edit(.all, values), to: rule, originalDate: date(3), context: context, now: date(3))
        #expect(try copies(context).count == 5)
        #expect(done.date == date(4, 20) && done.isDone)
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
            #expect(done.amount == 7 && done.date == date(3, 2) && done.isDone)
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
        #expect(done.amount == 8 && done.isDone)
        try materialize(context)
        #expect(try copies(context).count == 5)
    }

}
