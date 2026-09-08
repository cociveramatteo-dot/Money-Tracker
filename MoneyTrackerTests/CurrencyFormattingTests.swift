import Testing
import Foundation
@testable import MoneyTracker

/// Verifica `Decimal.parseAmount(_:)`: normalizzazione virgola/punto e arrotondamento
/// a 2 cifre decimali (BUG storico: senza arrotondamento un input come "10.999" veniva
/// salvato esatto in `Transaction.amount` mentre ogni punto della UI arrotonda a 2
/// cifre in visualizzazione, disallineando saldo mostrato e somma delle righe).
@Suite("Decimal.parseAmount")
struct CurrencyFormattingTests {

    @Test("Accetta sia virgola che punto come separatore decimale")
    func acceptsCommaAndDot() {
        #expect(Decimal.parseAmount("10,50") == Decimal(string: "10.50"))
        #expect(Decimal.parseAmount("10.50") == Decimal(string: "10.50"))
    }

    @Test("Arrotonda a 2 cifre decimali un input con più cifre")
    func roundsToTwoDecimalDigits() {
        #expect(Decimal.parseAmount("10.999") == Decimal(string: "11.00"))
        #expect(Decimal.parseAmount("10.994") == Decimal(string: "10.99"))
        #expect(Decimal.parseAmount("10.995") == Decimal(string: "11.00"))
    }

    @Test("Input non numerico restituisce nil")
    func invalidInputReturnsNil() {
        #expect(Decimal.parseAmount("abc") == nil)
        #expect(Decimal.parseAmount("") == nil)
    }

    @Test("Importi interi restano invariati")
    func wholeNumbersUnaffected() {
        #expect(Decimal.parseAmount("500") == Decimal(500))
    }
}
