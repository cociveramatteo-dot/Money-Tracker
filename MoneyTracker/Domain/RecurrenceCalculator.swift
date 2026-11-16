import Foundation
import CryptoKit

/// Pure recurrence values; no persistence or dependence on the user's calendar identifier.
nonisolated struct RecurrenceException: Codable, Sendable, Equatable {
    var skip: Bool = false
    var amount: String? = nil
    var date: Date? = nil
    var name: String? = nil
    var notes: String? = nil
    var category: String? = nil
    var categoryIcon: String? = nil
    var type: String? = nil
    var isFixed: Bool? = nil
    var accountId: UUID? = nil
    // Distinguishes an explicit “no account” override from an old exception without this field.
    var overridesAccount: Bool? = nil
}

nonisolated enum RecurrenceExceptionCodec {
    static func decode(_ json: String) -> [String: RecurrenceException] {
        guard let data = json.data(using: .utf8),
              let result = try? JSONDecoder().decode([String: RecurrenceException].self, from: data)
        else { return [:] }
        return result
    }

    static func encode(_ exceptions: [String: RecurrenceException]) throws -> String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys]
        return String(decoding: try encoder.encode(exceptions), as: UTF8.self)
    }
}

nonisolated struct RuleSnapshot: Sendable {
    var id: UUID
    var name: String
    var amount: Decimal
    var type: String
    var category: String
    var categoryIcon: String
    var notes: String = ""
    var isFixed: Bool = false
    var accountId: UUID? = nil
    var frequency: String
    var startDate: Date
    var endDate: Date? = nil
    var exceptions: [String: RecurrenceException] = [:]
}

nonisolated struct Occurrence: Sendable, Identifiable {
    var id: UUID { RecurrenceCalculator.occurrenceID(ruleId: ruleId, key: key) }
    let ruleId: UUID
    let key: String
    let originalDate: Date
    let date: Date
    let amount: Decimal
    let name: String
    let category: String
    let categoryIcon: String
    let type: String
    let accountId: UUID?
    let isFixed: Bool
    let notes: String
    let isOverridden: Bool
}

nonisolated struct RecurrenceCalculator: Sendable {
    private let calendar: Calendar

    init(timeZone: TimeZone = .current) {
        var calendar = Calendar(identifier: .gregorian)
        calendar.timeZone = timeZone
        self.calendar = calendar
    }

    /// Calendar failures preserve the input date instead of crashing.
    func adding(_ component: Calendar.Component, value: Int, to date: Date) -> Date {
        guard let result = calendar.date(byAdding: component, value: value, to: date) else { return date }
        return result
    }

    func monthInterval(_ date: Date) -> DateInterval {
        guard let interval = calendar.dateInterval(of: .month, for: date) else {
            return DateInterval(start: date, end: date)
        }
        return interval
    }

    func monthStart(_ date: Date) -> Date { monthInterval(date).start }

    func daysInMonth(_ date: Date) -> Int {
        guard let days = calendar.range(of: .day, in: .month, for: date) else {
            return calendar.component(.day, from: date)
        }
        return days.count
    }

    func noon(_ date: Date) -> Date {
        guard let result = calendar.date(bySettingHour: 12, minute: 0, second: 0, of: date) else { return date }
        return result
    }

    func key(for date: Date) -> String {
        String(format: "%04d-%02d-%02d", calendar.component(.year, from: date),
               calendar.component(.month, from: date), calendar.component(.day, from: date))
    }

    /// Translate the date shown for a selected copy back to its series anchor.
    /// An unchanged clamped date (e.g. February 28 for a day-31 series) keeps the anchor.
    func anchorForSeriesEdit(rule: RuleSnapshot, originalDate: Date, date: Date) -> Date {
        guard !calendar.isDate(date, inSameDayAs: originalDate) else { return rule.startDate }
        if rule.frequency == "settimanale" {
            let days = calendar.dateComponents([.day], from: noon(originalDate), to: noon(date)).day ?? 0
            return adding(.day, value: days, to: noon(rule.startDate))
        }
        let originalMonth = monthStart(originalDate)
        let editedMonth = monthStart(date)
        let months = calendar.dateComponents([.month], from: originalMonth, to: editedMonth).month ?? 0
        let anchorMonth = monthStart(rule.startDate)
        let month = adding(.month, value: months, to: anchorMonth)
        let day = min(calendar.component(.day, from: date), daysInMonth(month))
        return adding(.day, value: day - 1, to: noon(month))
    }

    /// Intervals are half-open [start, end). End dates on rules are inclusive civil days.
    /// Selection uses the effective date, including an override within the original month.
    func occurrences(rule: RuleSnapshot, in interval: DateInterval) -> [Occurrence] {
        guard interval.duration > 0 else { return [] }
        let start = noon(rule.startDate)
        let end = rule.endDate.map(noon)
        let anchor = calendar.dateComponents([.year, .month, .day], from: start)
        let firstMonth = monthStart(interval.start)
        let lastMonth = monthInterval(interval.end.addingTimeInterval(-1)).end
        var dates: [Date] = []
        switch rule.frequency {
        case "settimanale":
            let days = calendar.dateComponents([.day], from: calendar.startOfDay(for: start),
                                               to: calendar.startOfDay(for: firstMonth)).day ?? 0
            var k = max(0, days / 7)
            while let date = calendar.date(byAdding: .day, value: k * 7, to: start), date < lastMonth {
                if date >= firstMonth { dates.append(date) }
                k += 1
            }
        case "mensile", "annuale":
            let anchorMonth = monthStart(start)
            let difference = calendar.dateComponents([.month], from: anchorMonth, to: firstMonth).month ?? 0
            let step = rule.frequency == "mensile" ? 1 : 12
            var n = max(0, difference / step)
            while let month = calendar.date(byAdding: .month, value: n * step, to: anchorMonth), month < lastMonth {
                let day = min((anchor.day ?? calendar.component(.day, from: start)), daysInMonth(month))
                let date = adding(.day, value: day - 1, to: noon(month))
                if date >= firstMonth { dates.append(date) }
                n += 1
            }
        default: return []
        }
        return dates.compactMap { original in
            guard original >= start, end.map({ original <= $0 }) ?? true else { return nil }
            let key = key(for: original)
            let exception = rule.exceptions[key]
            guard exception?.skip != true else { return nil }
            // The editor enforces this too; ignore invalid cross-month overrides defensively.
            let overrideDate = exception?.date.map(noon)
            let date = overrideDate.flatMap {
                calendar.isDate($0, equalTo: original, toGranularity: .month) ? $0 : nil
            } ?? original
            guard date >= interval.start, date < interval.end else { return nil }
            return Occurrence(ruleId: rule.id, key: key, originalDate: original, date: date,
                              amount: exception?.amount.flatMap { Decimal(string: $0, locale: Locale(identifier: "en_US_POSIX")) } ?? rule.amount,
                              name: exception?.name ?? rule.name, category: exception?.category ?? rule.category,
                              categoryIcon: exception?.categoryIcon ?? rule.categoryIcon, type: exception?.type ?? rule.type,
                              accountId: exception?.overridesAccount == true ? exception?.accountId : rule.accountId,
                              isFixed: exception?.isFixed ?? rule.isFixed, notes: exception?.notes ?? rule.notes,
                              isOverridden: exception != nil)
        }.sorted { $0.date == $1.date ? $0.key < $1.key : $0.date < $1.date }
    }

    /// RFC 9562 UUIDv5: namespace bytes followed by the UTF-8 civil-day key.
    static func occurrenceID(ruleId: UUID, key: String) -> UUID {
        var namespace = ruleId.uuid
        let data = withUnsafeBytes(of: &namespace) { Data($0) } + Data(key.utf8)
        var bytes = Array(Insecure.SHA1.hash(data: data).prefix(16))
        bytes[6] = (bytes[6] & 0x0f) | 0x50
        bytes[8] = (bytes[8] & 0x3f) | 0x80
        return UUID(uuid: (bytes[0], bytes[1], bytes[2], bytes[3], bytes[4], bytes[5], bytes[6], bytes[7],
                           bytes[8], bytes[9], bytes[10], bytes[11], bytes[12], bytes[13], bytes[14], bytes[15]))
    }
}
