import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@Suite("Recurring rule sync", .serialized)
@MainActor
struct RecurringRuleSyncTests {
    private func container() throws -> ModelContainer {
        let schema = Schema(versionedSchema: SchemaV3.self)
        return try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
    }

    private func rule(watermark: Date? = nil) -> RecurringRule {
        RecurringRule(name: "Affitto", amount: Decimal(string: "123.4567890123456789")!,
                      type: "uscita", category: "Casa", categoryIcon: "house", notes: "日本語",
                      isFixed: true, accountId: UUID(), frequency: "mensile",
                      startDate: Date(timeIntervalSince1970: 1_700_000_000),
                      endDate: Date(timeIntervalSince1970: 1_800_000_000),
                      exceptionsJSON: "{\"2026-11-01\":{\"skip\":true}}",
                      materializedThrough: watermark)
    }

    @Test func dtoRoundTripAndNulls() throws {
        let input = rule(watermark: Date(timeIntervalSince1970: 1_750_000_000))
        let userId = UUID()
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .iso8601
        let data = try encoder.encode(SBRecurringRule(input, userId: userId))
        let json = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(Set(json.keys) == Set(["id", "user_id", "name", "type", "category", "category_icon", "notes", "amount", "is_fixed", "account_id", "frequency", "start_date", "end_date", "exceptions", "materialized_through", "created_at"]))
        let decoded = try decoder.decode(SBRecurringRule.self, from: data)
        #expect(decoded.userId == userId)
        #expect(decoded.amount == input.amount)
        #expect(decoded.exceptionsJSON == input.exceptionsJSON)
        #expect(decoded.accountId == input.accountId)
        input.accountId = nil
        input.endDate = nil
        input.materializedThrough = nil
        let emptyData = try encoder.encode(SBRecurringRule(input, userId: userId))
        let empty = try #require(JSONSerialization.jsonObject(with: emptyData) as? [String: Any])
        for key in ["account_id", "end_date", "materialized_through"] { #expect(empty[key] is NSNull) }
        let nilDecoded = try decoder.decode(SBRecurringRule.self, from: emptyData)
        #expect(nilDecoded.accountId == nil && nilDecoded.endDate == nil && nilDecoded.materializedThrough == nil)
    }

    @Test func watermarkNeverRegresses() {
        let earlier = Date(timeIntervalSince1970: 100)
        let later = Date(timeIntervalSince1970: 200)
        for local in [nil, earlier, later] as [Date?] {
            for remote in [nil, earlier, later] as [Date?] {
                let target = rule(watermark: local)
                let source = rule(watermark: remote)
                source.accountId = nil
                source.endDate = nil
                source.name = "Remoto"
                SBRecurringRule(source, userId: UUID()).apply(to: target)
                #expect(target.materializedThrough == [local, remote].compactMap { $0 }.max())
                #expect(target.name == "Remoto" && target.accountId == nil && target.endDate == nil)
            }
        }
    }

    @Test func pullInsertsUpdatesAndDeletesOrphans() throws {
        let store = try container()
        let context = store.mainContext
        let existing = rule(watermark: Date(timeIntervalSince1970: 300))
        let orphan = rule()
        context.insert(existing)
        context.insert(orphan)
        try context.save()
        let remote = rule(watermark: Date(timeIntervalSince1970: 100))
        remote.id = existing.id
        remote.name = "Aggiornato"
        let added = rule()
        added.amount = Decimal(string: "0.2")!
        let rows = [remote, added].map { SBRecurringRule($0, userId: UUID()) }
        try SyncService.mergeRecurringRules(rows, context: context)
        try context.save()
        let result = try context.fetch(FetchDescriptor<RecurringRule>())
        #expect(Set(result.map(\.id)) == Set([existing.id, added.id]))
        #expect(existing.name == remote.name)
        #expect(existing.materializedThrough == Date(timeIntervalSince1970: 300))
        let inserted = try #require(result.first { $0.id == added.id })
        #expect(inserted.amount == added.amount && inserted.exceptionsJSON == added.exceptionsJSON)
        #expect(inserted.startDate == added.startDate && inserted.createdAt == added.createdAt)
    }

    @Test func emptyRemotePreservesLocalRulesAwaitingPush() throws {
        let store = try container()
        let context = store.mainContext
        let watermark = Date(timeIntervalSince1970: 300)
        let local = rule(watermark: watermark)
        context.insert(local)
        try context.save()
        let localId = local.id
        let exceptions = local.exceptionsJSON

        try SyncService.mergeRecurringRules([], context: context)
        try context.save()

        let result = try context.fetch(FetchDescriptor<RecurringRule>())
        #expect(result.count == 1)
        let preserved = try #require(result.first)
        #expect(preserved.id == localId)
        #expect(preserved.materializedThrough == watermark)
        #expect(preserved.exceptionsJSON == exceptions)
    }

    @Test func logoutDeletesRules() throws {
        let store = try container()
        let context = store.mainContext
        context.insert(rule())
        try context.save()
        SyncService.shared.clearLocalData(context: context)
        #expect(try context.fetchCount(FetchDescriptor<RecurringRule>()) == 0)
    }
}
