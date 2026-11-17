import Foundation
import Testing
@testable import MoneyTracker

@Suite("Strict amount parsing")
@MainActor
struct StrictAmountParsingTests {
    @Test("Rejects partial numbers and malformed grouping")
    func rejectsPartialNumbers() {
        for input in ["12abc", "1.234,56", "1,234.56", "12.3.4", "12-3", "12\n", "12€"] {
            #expect(Decimal.parseAmount(input) == nil)
        }
    }

    @Test("Rejects empty input and bare signs")
    func rejectsEmptyInput() {
        for input in ["", "-", "+", ".", ","] {
            #expect(Decimal.parseAmount(input) == nil)
        }
    }

    @Test("Preserves supported decimal forms and signs")
    func preservesValidInputs() {
        let cases = [("-5,5", "-5.5"), ("10,50", "10.5"), ("10.50", "10.5"),
                     ("500", "500"), ("+5.5", "5.5"), (".5", "0.5"), ("5.", "5"),
                     ("10.999", "11"), ("10.994", "10.99"), ("10.995", "11")]
        for (input, expected) in cases {
            #expect(Decimal.parseAmount(input) == Decimal(string: expected))
        }
    }
}
