import CryptoKit
import Foundation
import Testing
@testable import MoneyTracker

@MainActor
struct E2EVaultRemoteTests {
    private let user = UUID()
    private let memory = InMemoryRemote()
    private let key = SymmetricKey(data: Data(repeating: 0x42, count: 32))

    private var vault: VaultRemote { VaultRemote(access: memory, dek: key, owner: user) }

    private struct Row: SyncRow, Equatable {
        let id: UUID
        let name: String
        let createdAt: Date
        let amount: Decimal

        enum CodingKeys: String, CodingKey {
            case id, name, amount
            case createdAt = "created_at"
        }
    }

    @Test func encryptsAndRoundTripsEveryKindWithExpectedJSON() async throws {
        let date = Date(timeIntervalSince1970: 1_700_000_000.125)
        for table in SyncTable.allCases {
            let row = Row(id: UUID(), name: "Nome privato 日本", createdAt: date, amount: 10.25)
            try await vault.upsert([row], table: table, userId: user)

            let record = try #require(memory.records[row.id])
            #expect(record.userId == user)
            #expect(record.kind == table.kind)
            #expect(record.keyId == (try VaultCrypto.keyId(dek: key)))
            #expect(record.payload.hasPrefix("bt1."))
            let wire = String(decoding: try JSONEncoder().encode(record), as: UTF8.self)
            #expect(!wire.contains("Nome privato"))
            let aad = Data("bucktrail/e2e/v1/row/\(table.kind)/\(row.id.uuidString.lowercased())/\(user.uuidString.lowercased())".utf8)
            let data = try VaultCrypto.open(record.payload, key: key, aad: aad)
            let json = String(decoding: data, as: UTF8.self)
            #expect(json.contains("\"amount\":10.25"))
            #expect(json.contains("\"created_at\":\"2023-11-14T22:13:20.125Z\""))

            let decoded: [Row] = try await vault.select(table: table, userId: user)
            #expect(decoded == [row])
        }
    }

    @Test func upsertsInBatchesAndDeletesOnlyRequestedKindAndUser() async throws {
        let otherUser = UUID()
        let rows = (0..<401).map {
            Row(id: UUID(), name: "Riga \($0)", createdAt: .distantPast, amount: 1)
        }
        try await vault.upsert(rows, table: .transactions, userId: user)
        #expect(memory.calls == [.upsertVault(200), .upsertVault(200), .upsertVault(1)])

        let differentKind = Row(id: UUID(), name: "Altro tipo", createdAt: .distantPast, amount: 0)
        let differentUser = Row(id: UUID(), name: "Altro utente", createdAt: .distantPast, amount: 0)
        try await vault.upsert([differentKind], table: .accounts, userId: user)
        try await VaultRemote(access: memory, dek: key, owner: otherUser)
            .upsert([differentUser], table: .transactions, userId: otherUser)
        #expect(try await vault.fetchIds(table: .transactions, userId: user) == Set(rows.map(\.id)))

        try await vault.delete(ids: rows.map(\.id) + [differentKind.id, differentUser.id],
                               table: .transactions, userId: user)
        #expect(Set(memory.records.keys) == [differentKind.id, differentUser.id])
    }

    @Test func rejectsInnerIDMismatchAndCiphertextMovedToAnotherRow() async throws {
        let row = Row(id: UUID(), name: "Riservato", createdAt: .distantPast, amount: 10)
        let outerID = UUID()
        let plain = try VaultJSON.encoder.encode(row)
        let wrongAAD = VaultCrypto.rowAAD(kind: "account", id: row.id, userID: user)
        let correctAAD = VaultCrypto.rowAAD(kind: "account", id: outerID, userID: user)
        let mismatched = try VaultCrypto.seal(plain, key: key, aad: correctAAD)
        memory.records[outerID] = VaultRecord(id: outerID, userId: user, kind: "account", keyId: try VaultCrypto.keyId(dek: key), payload: mismatched)
        await #expect(throws: VaultRemote.Failure.mismatchedID) {
            let _: [Row] = try await vault.select(table: .accounts, userId: user)
        }
        let relocated = try VaultCrypto.seal(plain, key: key, aad: wrongAAD)
        memory.records[outerID] = VaultRecord(id: outerID, userId: user, kind: "account", keyId: try VaultCrypto.keyId(dek: key), payload: relocated)
        await #expect(throws: VaultCrypto.Failure.authenticationFailed) {
            let _: [Row] = try await vault.select(table: .accounts, userId: user)
        }
    }

    @Test func staleKeyCannotDeleteOrReadRowsOfReplacementKey() async throws {
        let replacement = VaultRemote(access: memory, dek: SymmetricKey(size: .bits256), owner: user)
        let row = Row(id: UUID(), name: "Nuova chiave", createdAt: .distantPast, amount: 1)
        try await replacement.upsert([row], table: .accounts, userId: user)

        try await vault.delete(ids: [row.id], table: .accounts, userId: user)
        #expect(memory.records[row.id] != nil)
        await #expect(throws: VaultRemote.Failure.wrongKey) {
            let _: [Row] = try await vault.select(table: .accounts, userId: user)
        }
    }
}
