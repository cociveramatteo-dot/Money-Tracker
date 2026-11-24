import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

/// S-16: quanto resta esatto un `Decimal` dopo il passaggio da SwiftData (salvataggio + nuovo fetch).
@Suite("Precisione Decimal in SwiftData", .serialized)
@MainActor
struct DecimalPersistenceTests {
    private func roundTrip(_ text: String) throws -> Decimal {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = container.mainContext
        let rule = RecurringRule(name: "Prova", amount: Decimal(string: text)!, type: "Uscita", frequency: "mensile", startDate: Date())
        context.insert(rule)
        try context.save()
        let fetched = try context.fetch(FetchDescriptor<RecurringRule>())
        return try #require(fetched.first).amount
    }

    @Test("Gli importi reali (fino al tetto di 1 miliardo, 2 decimali) tornano identici")
    func realisticAmountsAreExact() throws {
        for text in ["0.01", "0.2", "12.50", "1234.56", "99999.99", "123456789.12", "1000000000.00"] {
            let value = Decimal(string: text)!
            #expect(try roundTrip(text) == value, "importo \(text) alterato dalla persistenza")
        }
    }

    @Test("Il caso estremo a 19 cifre significative resta entro 1e-9 (limite noto, non raggiungibile dall'interfaccia)")
    func extremePrecisionStaysClose() throws {
        let original = Decimal(string: "123.4567890123456789")!
        let stored = try roundTrip("123.4567890123456789")
        let difference = abs(NSDecimalNumber(decimal: stored - original).doubleValue)
        print("S16-DIFF stored=\(stored) original=\(original) diff=\(difference)")
        #expect(difference < 1e-9)
    }
}
