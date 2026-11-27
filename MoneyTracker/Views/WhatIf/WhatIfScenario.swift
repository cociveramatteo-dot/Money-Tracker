import Foundation

struct WhatIfBaseline: Identifiable, Equatable {
    let id: String
    let name: String?
    let today: Decimal
    let endOfMonth: Decimal
    let isExcludedFromTotal: Bool

    init(id: String, name: String?, today: Decimal, endOfMonth: Decimal, isExcludedFromTotal: Bool = false) {
        self.id = id
        self.name = name
        self.today = today
        self.endOfMonth = endOfMonth
        self.isExcludedFromTotal = isExcludedFromTotal
    }
}

struct WhatIfHypothesis: Identifiable, Equatable {
    let id: UUID
    var amountText: String
    var isIncome: Bool
    var name: String
    var isOn: Bool

    init(id: UUID = UUID(), amountText: String = "", isIncome: Bool = false, name: String = "", isOn: Bool = true) {
        self.id = id
        self.amountText = amountText
        self.isIncome = isIncome
        self.name = name
        self.isOn = isOn
    }
}

enum WhatIfScenario {
    static let maxHypotheses = 20
    static let maxAmount: Decimal = 1_000_000_000

    /// Parses a positive amount up to 1e9 using `Decimal.parseAmount`.
    /// Sign is controlled solely by the − / + toggle; leading `+` or `-` is rejected.
    static func amount(of text: String) -> Decimal? {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("-"), !trimmed.contains("+") else { return nil }
        guard let parsed = Decimal.parseAmount(trimmed), parsed > 0, parsed <= maxAmount else { return nil }
        return parsed
    }

    static func isInvalidInput(_ text: String) -> Bool {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        return !trimmed.isEmpty && amount(of: trimmed) == nil
    }

    static func delta(_ items: [WhatIfHypothesis]) -> Decimal {
        items.reduce(Decimal.zero) { partial, item in
            guard item.isOn, let value = amount(of: item.amountText) else { return partial }
            return partial + (item.isIncome ? value : -value)
        }
    }

    static func result(
        baseline: WhatIfBaseline,
        items: [WhatIfHypothesis]
    ) -> (todayNow: Decimal, todayWith: Decimal, endNow: Decimal, endWith: Decimal, delta: Decimal) {
        let totalDelta = delta(items)
        return (
            todayNow: baseline.today,
            todayWith: baseline.today + totalDelta,
            endNow: baseline.endOfMonth,
            endWith: baseline.endOfMonth + totalDelta,
            delta: totalDelta
        )
    }
}
