import Foundation
import Testing
@testable import MoneyTracker

@Suite("Account usage order")
@MainActor
struct AccountUsageOrderTests {
    @Test func ordersByUsageDescendingAndPreservesOrderOnTies() {
        let first = Account(name: "Primo", type: .conto)
        let second = Account(name: "Secondo", type: .carta)
        let third = Account(name: "Terzo", type: .contanti)
        let fourth = Account(name: "Quarto", type: .risparmio)

        let counts: [UUID: Int] = [
            third.id: 5,
            first.id: 2,
            second.id: 2,
            // fourth has 0
        ]

        let ordered = AddTransactionView.orderByUsage([first, second, third, fourth], counts: counts)
        #expect(ordered.map(\.name) == ["Terzo", "Primo", "Secondo", "Quarto"])
    }

    @Test func emptyCountsKeepOriginalOrder() {
        let a = Account(name: "A", type: .conto)
        let b = Account(name: "B", type: .carta)
        let ordered = AddTransactionView.orderByUsage([a, b], counts: [:])
        #expect(ordered.map(\.name) == ["A", "B"])
    }
}
