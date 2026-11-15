import Foundation
import SwiftData
import Observation

/// Presentation state shared by editor/materialization callers. S-13g binds `errorMessage`
/// to its alert; failures are retained until acknowledged, never reduced to a log.
@MainActor @Observable
final class RecurrenceOperationStatus {
    var errorMessage: String?

    @discardableResult
    func perform(_ operation: () throws -> Void) -> Bool {
        do { try operation(); return true }
        catch {
            errorMessage = NSLocalizedString("Impossibile aggiornare le ricorrenze. Riprova.", comment: "Recurrence persistence error")
                + "\n" + error.localizedDescription
            return false
        }
    }
}

@MainActor
struct RecurringSeriesEditor {
    enum Scope { case onlyThis, following, all }
    enum Action {
        /// onlyThis stores every editable value as an occurrence override.
        /// following anchors the replacement at the selected original date. all uses the supplied anchor.
        case edit(Scope, RuleSnapshot)
        case delete(Scope)
        case skipMonth
        case terminate(afterThis: Bool)
    }
    enum EditorError: LocalizedError {
        case requiresMainContext, invalidOccurrence, invalidValues, crossMonthOverride
        var errorDescription: String? {
            switch self {
            case .requiresMainContext: return "Le ricorrenze richiedono il contesto principale."
            case .invalidOccurrence: return "L’occorrenza non appartiene alla serie."
            case .invalidValues: return "I valori della ricorrenza non sono validi."
            case .crossMonthOverride: return "La data deve restare nello stesso mese."
            }
        }
    }

    private let calendar: Calendar
    private let calculator: RecurrenceCalculator
    // Injectable persistence boundary lets tests prove failure recovery without corrupting a store.
    private let save: (ModelContext) throws -> Void

    init(timeZone: TimeZone = .current, save: @escaping (ModelContext) throws -> Void = { try $0.save() }) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
        calculator = RecurrenceCalculator(timeZone: timeZone)
        self.save = save
    }

    static func snapshot(_ rule: RecurringRule) -> RuleSnapshot {
        RuleSnapshot(id: rule.id, name: rule.name, amount: rule.amount, type: rule.type,
                     category: rule.category, categoryIcon: rule.categoryIcon, notes: rule.notes,
                     isFixed: rule.isFixed, accountId: rule.accountId, frequency: rule.frequency,
                     startDate: rule.startDate, endDate: rule.endDate,
                     exceptions: RecurrenceExceptionCodec.decode(rule.exceptionsJSON))
    }

    /// The original civil date identifies even an overridden or skipped occurrence.
    /// Returns the replacement rule for a split, otherwise the original rule (nil on delete-all).
    @discardableResult
    func apply(_ action: Action, to rule: RecurringRule, originalDate: Date,
               context: ModelContext, now: Date = Date()) throws -> RecurringRule? {
        guard context === context.container.mainContext else { throw EditorError.requiresMainContext }
        let original = calculator.noon(originalDate)
        var base = Self.snapshot(rule)
        base.exceptions = [:]
        base.endDate = nil
        let interval = calendar.dateInterval(of: .month, for: original)!
        guard rule.modelContext === context,
              calculator.occurrences(rule: base, in: interval).contains(where: { $0.originalDate == original })
        else { throw EditorError.invalidOccurrence }
        let old = Self.snapshot(rule)
        let oldJSON = rule.exceptionsJSON
        let oldWatermark = rule.materializedThrough
        // All reads precede mutations; legacy transactions have unrelated template IDs.
        let transactions = try context.fetch(FetchDescriptor<Transaction>())
        let copies = transactions.filter { $0.templateId == rule.id.uuidString }
        let accounts = try context.fetch(FetchDescriptor<Account>())
        var undo: [() -> Void] = []
        var deletions: [Transaction] = []
        var inserted: [Transaction] = []
        var replacement: RecurringRule?
        var deleteRule = false
        var result: RecurringRule? = rule
        let key = calculator.key(for: original)
        var exceptions = old.exceptions
        let previousDay = calendar.date(byAdding: .day, value: -1, to: original)!
        // IDs identify the original civil day even if the effective date was moved.
        var originalDays: [UUID: Date]?
        func originalDay(_ copy: Transaction) -> Date {
            if originalDays == nil {
                let lastDate = max(copies.map(\.date).max() ?? original, oldWatermark ?? original, original)
                let end = calendar.date(byAdding: .month, value: 1, to: lastDate)!
                originalDays = Dictionary(uniqueKeysWithValues: calculator.occurrences(
                    rule: base, in: DateInterval(start: base.startDate, end: max(end, base.startDate.addingTimeInterval(1))))
                    .map { ($0.id, $0.originalDate) })
            }
            return originalDays?[copy.id] ?? calculator.noon(copy.date)
        }

        func remove(_ predicate: (Transaction) -> Bool) {
            deletions.append(contentsOf: copies.filter { !$0.isDone && predicate($0) })
        }
        func update(_ transaction: Transaction, _ occurrence: Occurrence) {
            let name = transaction.name, amount = transaction.amount, date = transaction.date
            let notes = transaction.notes, category = transaction.category, icon = transaction.categoryIcon
            let type = transaction.type, fixed = transaction.isFixed, account = transaction.account
            let id = transaction.id, template = transaction.templateId
            undo.append {
                transaction.name = name; transaction.amount = amount; transaction.date = date
                transaction.notes = notes; transaction.category = category; transaction.categoryIcon = icon
                transaction.type = type; transaction.isFixed = fixed; transaction.account = account
                transaction.id = id; transaction.templateId = template
            }
            transaction.name = occurrence.name; transaction.amount = occurrence.amount; transaction.date = occurrence.date
            transaction.notes = occurrence.notes; transaction.category = occurrence.category
            transaction.categoryIcon = occurrence.categoryIcon; transaction.type = occurrence.type
            transaction.isFixed = occurrence.isFixed
            transaction.account = accounts.first { $0.id == occurrence.accountId }
        }
        func occurrence(_ values: RuleSnapshot, on day: Date) -> Occurrence {
            Occurrence(ruleId: values.id, key: calculator.key(for: day), originalDate: day,
                       date: calculator.noon(day), amount: values.amount, name: values.name,
                       category: values.category, categoryIcon: values.categoryIcon, type: values.type,
                       accountId: values.accountId, isFixed: values.isFixed, notes: values.notes, isOverridden: false)
        }
        // Match occurrence positions when the anchor/frequency changes (including short months).
        func rescheduledDay(_ day: Date, from source: RuleSnapshot, to target: RuleSnapshot) -> Date {
            let index: Int
            if source.frequency == "settimanale" {
                index = max(0, (calendar.dateComponents([.day], from: source.startDate, to: day).day ?? 0) / 7)
            } else {
                let a = calendar.dateInterval(of: .month, for: source.startDate)!.start
                let b = calendar.dateInterval(of: .month, for: day)!.start
                index = max(0, (calendar.dateComponents([.month], from: a, to: b).month ?? 0) / (source.frequency == "annuale" ? 12 : 1))
            }
            if target.frequency == "settimanale" {
                return calendar.date(byAdding: .day, value: index * 7, to: calculator.noon(target.startDate))!
            }
            let anchorMonth = calendar.dateInterval(of: .month, for: target.startDate)!.start
            let month = calendar.date(byAdding: .month, value: index * (target.frequency == "annuale" ? 12 : 1), to: anchorMonth)!
            let dayOfMonth = min(calendar.component(.day, from: target.startDate), calendar.range(of: .day, in: .month, for: month)!.count)
            return calendar.date(byAdding: .day, value: dayOfMonth - 1, to: calculator.noon(month))!
        }
        func reconcile(_ target: RecurringRule) {
            let month = calendar.dateInterval(of: .month, for: now)!
            let desired = calculator.occurrences(rule: Self.snapshot(target), in: month)
            let ids = Set(desired.map(\.id))
            // Deterministic IDs identify original dates even when a copy was moved manually.
            let relevant = transactions.filter { $0.templateId == target.id.uuidString }
            for copy in relevant where !copy.isDone && copy.date >= month.start && copy.date < month.end && !ids.contains(copy.id) {
                deletions.append(copy)
            }
            for occurrence in desired {
                if let existing = transactions.first(where: { $0.id == occurrence.id }) {
                    update(existing, occurrence)
                } else {
                    let copy = Transaction(name: occurrence.name, amount: occurrence.amount,
                                           type: TransactionType(rawValue: occurrence.type) ?? .uscita,
                                           category: occurrence.category, categoryIcon: occurrence.categoryIcon,
                                           date: occurrence.date, isDone: false, isFixed: occurrence.isFixed,
                                           notes: occurrence.notes, templateId: target.id.uuidString,
                                           account: accounts.first { $0.id == occurrence.accountId })
                    copy.id = occurrence.id
                    context.insert(copy); inserted.append(copy)
                }
            }
            // Reconciliation is explicit and only creates the current month, never history.
            // A future rule keeps nil so its first month is still due at the right time.
            if target.startDate < month.end { target.materializedThrough = max(target.materializedThrough ?? calculator.noon(month.start), calculator.noon(month.start)) }
        }

        do {
            switch action {
            case let .edit(scope, values):
                guard ["mensile", "settimanale", "annuale"].contains(values.frequency),
                      TransactionType(rawValue: values.type) != nil, !values.amount.isNaN,
                      values.amount >= 0,
                      values.endDate.map({ calculator.noon($0) >= calculator.noon(scope == .following ? original : values.startDate) }) ?? true else { throw EditorError.invalidValues }
                switch scope {
                case .onlyThis:
                    guard calendar.isDate(values.startDate, equalTo: original, toGranularity: .month)
                    else { throw EditorError.crossMonthOverride }
                    exceptions[key] = RecurrenceException(amount: NSDecimalNumber(decimal: values.amount).stringValue,
                                                         date: calculator.noon(values.startDate), name: values.name, notes: values.notes,
                                                         category: values.category, categoryIcon: values.categoryIcon,
                                                         type: values.type, isFixed: values.isFixed,
                                                         accountId: values.accountId, overridesAccount: true)
                    rule.exceptionsJSON = try RecurrenceExceptionCodec.encode(exceptions)
                    guard let occurrence = calculator.occurrences(rule: Self.snapshot(rule), in: interval).first(where: { $0.key == key })
                    else { throw EditorError.invalidOccurrence }
                    if let copy = copies.first(where: { $0.id == occurrence.id }) { update(copy, occurrence) }
                case .following:
                    rule.endDate = previousDay
                    rule.exceptionsJSON = try RecurrenceExceptionCodec.encode(exceptions.filter { $0.key < key })
                    let fresh = RecurringRule(name: values.name, amount: values.amount, type: values.type,
                                              category: values.category, categoryIcon: values.categoryIcon, notes: values.notes,
                                              isFixed: values.isFixed, accountId: values.accountId, frequency: values.frequency,
                                              startDate: original, endDate: values.endDate)
                    replacement = fresh; result = fresh; context.insert(fresh)
                    // Keep every existing occurrence in scope, including completed history.
                    // Reparent its deterministic identity so materialization cannot duplicate it.
                    var source = old; source.startDate = original
                    let target = Self.snapshot(fresh)
                    for copy in copies where originalDay(copy) >= original {
                        let day = rescheduledDay(originalDay(copy), from: source, to: target)
                        update(copy, occurrence(target, on: day))
                        if let end = target.endDate, day > calculator.noon(end), !copy.isDone { deletions.append(copy) }
                        copy.id = RecurrenceCalculator.occurrenceID(ruleId: fresh.id, key: calculator.key(for: day))
                        copy.templateId = fresh.id.uuidString
                    }
                    reconcile(fresh)
                case .all:
                    assign(values, to: rule)
                    let sameSchedule = old.frequency == values.frequency
                        && calculator.key(for: old.startDate) == calculator.key(for: values.startDate)
                    // A series edit replaces prior field/date overrides; explicit skips stay skipped.
                    rule.exceptionsJSON = try RecurrenceExceptionCodec.encode(sameSchedule
                        ? old.exceptions.filter { $0.value.skip } : [:])
                    for copy in copies {
                        let day = rescheduledDay(originalDay(copy), from: old, to: values)
                        update(copy, occurrence(values, on: day))
                        if let end = values.endDate, day > calculator.noon(end), !copy.isDone { deletions.append(copy) }
                        copy.id = RecurrenceCalculator.occurrenceID(ruleId: rule.id, key: calculator.key(for: day))
                    }
                    reconcile(rule)
                }
            case let .delete(scope):
                switch scope {
                case .onlyThis:
                    exceptions[key] = RecurrenceException(skip: true)
                    rule.exceptionsJSON = try RecurrenceExceptionCodec.encode(exceptions)
                    let id = RecurrenceCalculator.occurrenceID(ruleId: rule.id, key: key)
                    remove { $0.id == id }
                case .following:
                    rule.endDate = previousDay; remove { originalDay($0) >= original }
                case .all:
                    remove { _ in true }; deleteRule = true; result = nil
                }
            case .skipMonth:
                for occurrence in calculator.occurrences(rule: base, in: interval) {
                    exceptions[occurrence.key] = RecurrenceException(skip: true)
                }
                rule.exceptionsJSON = try RecurrenceExceptionCodec.encode(exceptions)
                remove { calendar.isDate($0.date, equalTo: original, toGranularity: .month) }
            case let .terminate(afterThis):
                rule.endDate = afterThis ? original : previousDay
                remove { afterThis ? originalDay($0) > original : originalDay($0) >= original }
            }
            var deletionIDs: Set<UUID> = []
            deletions = deletions.filter { deletionIDs.insert($0.id).inserted }
            for copy in deletions { context.delete(copy) }
            if deleteRule { context.delete(rule) }
            try save(context)
            AccountBalanceCache.shared.invalidateAll()
            return result
        } catch {
            // Restore only this operation, preserving unrelated pending mainContext edits.
            if deleteRule { context.insert(rule) }
            assign(old, to: rule); rule.exceptionsJSON = oldJSON; rule.materializedThrough = oldWatermark
            for copy in deletions { context.insert(copy) }
            for restore in undo.reversed() { restore() }
            for copy in inserted { context.delete(copy) }
            if let replacement { context.delete(replacement) }
            throw error
        }
    }

    private func assign(_ values: RuleSnapshot, to rule: RecurringRule) {
        rule.name = values.name; rule.amount = values.amount; rule.type = values.type
        rule.category = values.category; rule.categoryIcon = values.categoryIcon; rule.notes = values.notes
        rule.isFixed = values.isFixed; rule.accountId = values.accountId; rule.frequency = values.frequency
        rule.startDate = calculator.noon(values.startDate); rule.endDate = values.endDate.map(calculator.noon)
    }
}
