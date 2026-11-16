import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Recurring Decimal round trip", .serialized) @MainActor
struct RecurringDecimalRoundTripTests {
    @Test func centsSurviveSwiftDataAndDTOJSON() throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: directory) }
        let config = ModelConfiguration(schema: schema, url: directory.appendingPathComponent("decimal.store"))
        let userID = UUID()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        for text in ["0.29", "1234.56", "999999.99"] {
            let amount = try #require(Decimal(string: text, locale: Locale(identifier: "en_US_POSIX")))
            let id = try saveRule(amount: amount, schema: schema, config: config)
            // Reopen the disk store: do not read back the same registered model instance.
            let container = try ModelContainer(for: schema, configurations: config)
            let context = container.mainContext
            let saved = try #require(context.fetch(FetchDescriptor<RecurringRule>(
                predicate: #Predicate { $0.id == id })).first)
            #expect(saved.amount == amount, "SwiftData changed \(text)")
            let data = try encoder.encode(SBRecurringRule(saved, userId: userID))
            let decoded = try decoder.decode(SBRecurringRule.self, from: data)
            #expect(decoded.amount == amount, "DTO JSON changed \(text)")
            #expect(decoded.id == id && decoded.userId == userID)
            let target = RecurringRule(name: "Target", amount: 0, type: "Uscita",
                                       frequency: "mensile", startDate: saved.startDate)
            decoded.apply(to: target)
            #expect(target.amount == amount, "DTO application changed \(text)")
        }
    }

    private func saveRule(amount: Decimal, schema: Schema, config: ModelConfiguration) throws -> UUID {
        let container = try ModelContainer(for: schema, configurations: config)
        let rule = RecurringRule(name: "Decimal", amount: amount, type: "Uscita",
                                 frequency: "mensile", startDate: Date(timeIntervalSince1970: 1_700_000_000))
        container.mainContext.insert(rule)
        try container.mainContext.save()
        return rule.id
    }
}
