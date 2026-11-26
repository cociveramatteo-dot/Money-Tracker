import CryptoKit
import Foundation
import Testing
@testable import MoneyTracker

@MainActor
struct E2EVaultConcurrencyTests {
    @Test func encodesAndDecodesEveryBatchOffMainThread() async throws {
        let owner = UUID()
        let memory = InMemoryRemote()
        let remote = VaultRemote(access: memory, dek: SymmetricKey(size: .bits256), owner: owner)
        let rows = (0..<401).map { _ in Row(id: UUID()) }

        try await remote.upsert(rows, table: .transactions, userId: owner)
        #expect(memory.calls == [.upsertVault(200), .upsertVault(200), .upsertVault(1)])

        let decoded: [Row] = try await remote.select(table: .transactions, userId: owner)
        #expect(decoded.count == rows.count)
        #expect(Set(decoded.map(\.id)) == Set(rows.map(\.id)))
    }

    private struct Row: SyncRow {
        enum Failure: Error {
            case encodedOnMainThread, decodedOnMainThread
        }

        let id: UUID

        init(id: UUID) {
            self.id = id
        }

        init(from decoder: Decoder) throws {
            guard !Thread.isMainThread else { throw Failure.decodedOnMainThread }
            id = try decoder.singleValueContainer().decode(UUID.self)
        }

        func encode(to encoder: Encoder) throws {
            guard !Thread.isMainThread else { throw Failure.encodedOnMainThread }
            var container = encoder.singleValueContainer()
            try container.encode(id)
        }
    }
}
