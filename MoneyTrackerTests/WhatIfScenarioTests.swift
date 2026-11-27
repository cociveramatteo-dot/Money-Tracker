import Foundation
import Testing
@testable import MoneyTracker

@Suite("What-if scenario")
@MainActor
struct WhatIfScenarioTests {
    @Test func emptyReturnsZeroDelta() {
        #expect(WhatIfScenario.delta([]) == .zero)
    }

    @Test func sumsExpenseAndIncomeAndIgnoresDisabled() {
        let items = [
            WhatIfHypothesis(amountText: "150", isIncome: false, name: "cena", isOn: true),
            WhatIfHypothesis(amountText: "350", isIncome: true, name: "lavoretto", isOn: true),
            WhatIfHypothesis(amountText: "999", isIncome: false, name: "spenta", isOn: false),
        ]
        #expect(WhatIfScenario.delta(items) == Decimal(200))
    }

    @Test func validatesBoundsSignAndDecimalPrecision() {
        #expect(WhatIfScenario.amount(of: "") == nil)
        #expect(WhatIfScenario.amount(of: "0") == nil)
        #expect(WhatIfScenario.amount(of: "abc") == nil)
        #expect(WhatIfScenario.amount(of: "-10") == nil)
        #expect(WhatIfScenario.amount(of: "+10") == nil)
        #expect(WhatIfScenario.amount(of: "1000000001") == nil)
        #expect(WhatIfScenario.amount(of: "1000000000") == Decimal(1_000_000_000))
        #expect(WhatIfScenario.amount(of: "12,345") == Decimal.parseAmount("12,345"))

        #expect(!WhatIfScenario.isInvalidInput(""))
        #expect(!WhatIfScenario.isInvalidInput("   "))
        #expect(WhatIfScenario.isInvalidInput("abc"))
        #expect(WhatIfScenario.isInvalidInput("-15"))
        #expect(!WhatIfScenario.isInvalidInput("15,50"))

        let decimalItems = [
            WhatIfHypothesis(amountText: "0.1", isIncome: true, isOn: true),
            WhatIfHypothesis(amountText: "0,2", isIncome: true, isOn: true),
        ]
        #expect(WhatIfScenario.delta(decimalItems) == Decimal(string: "0.3", locale: Locale(identifier: "en_US_POSIX")))
    }

    @Test func appliesDeltaToTodayAndEndOfMonthIncludingNegativeBaseline() {
        let baseline = WhatIfBaseline(
            id: "acc",
            name: "Carta",
            today: Decimal(-50),
            endOfMonth: Decimal(-120)
        )
        let items = [
            WhatIfHypothesis(amountText: "150", isIncome: false, name: "spesa", isOn: true),
            WhatIfHypothesis(amountText: "abc", isIncome: true, name: "invalida", isOn: true),
        ]
        let res = WhatIfScenario.result(baseline: baseline, items: items)
        #expect(res.delta == Decimal(-150))
        #expect(res.todayNow == Decimal(-50))
        #expect(res.todayWith == Decimal(-200))
        #expect(res.endNow == Decimal(-120))
        #expect(res.endWith == Decimal(-270))
    }
}
