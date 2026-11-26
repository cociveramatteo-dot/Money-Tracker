import CryptoKit
import Foundation
import Supabase

nonisolated struct VaultRecord: Codable, Sendable {
    let id: UUID
    let userId: UUID
    let kind: String
    let keyId: String
    let payload: String

    enum CodingKeys: String, CodingKey {
        case id, kind, payload
        case userId = "user_id"
        case keyId = "key_id"
    }
}

nonisolated struct VaultKeyRow: Decodable {
    let id: UUID
    let keyId: String?

    enum CodingKeys: String, CodingKey {
        case id
        case keyId = "key_id"
    }
}

@MainActor
protocol VaultAccess {
    func vaultIds(table: SyncTable, userId: UUID, keyId: String) async throws -> Set<UUID>
    func vaultRows(table: SyncTable, userId: UUID, keyId: String?) async throws -> [VaultRecord]
    func vaultKeyRows(table: SyncTable, userId: UUID) async throws -> [VaultKeyRow]
    func upsertVault(_ rows: [VaultRecord]) async throws
    func deleteVault(ids: [UUID], table: SyncTable, userId: UUID, keyId: String) async throws
}

extension VaultAccess {
    func vaultKeyRows(table: SyncTable, userId: UUID) async throws -> [VaultKeyRow] {
        try await vaultRows(table: table, userId: userId, keyId: nil).map {
            VaultKeyRow(id: $0.id, keyId: $0.keyId)
        }
    }
}

struct SupabaseVaultAccess: VaultAccess {
    let client: SupabaseClient

    private struct IDRow: Decodable {
        let id: UUID
    }

    func vaultIds(table: SyncTable, userId: UUID, keyId: String) async throws -> Set<UUID> {
        let rows: [IDRow] = try await read(columns: "id", table: table, userId: userId, keyId: keyId, id: \.id)
        return Set(rows.map(\.id))
    }

    func vaultRows(table: SyncTable, userId: UUID, keyId: String?) async throws -> [VaultRecord] {
        try await read(columns: "*", table: table, userId: userId, keyId: keyId, id: \.id)
    }

    func vaultKeyRows(table: SyncTable, userId: UUID) async throws -> [VaultKeyRow] {
        try await read(columns: "id,key_id", table: table, userId: userId, keyId: nil, id: \.id)
    }

    private func read<Row: Decodable>(columns: String, table: SyncTable, userId: UUID,
                                      keyId: String?, id: KeyPath<Row, UUID>) async throws -> [Row] {
        // Full rows carry the ciphertext: smaller pages keep each response light.
        let pageSize = columns == "*" ? 200 : 1000
        var rows: [Row] = []
        var cursor: UUID?
        repeat {
            let query = client.from("mt_vault").select(columns)
                .eq("user_id", value: userId.uuidString.lowercased())
                .eq("kind", value: table.kind)
            if let keyId { _ = query.eq("key_id", value: keyId) }
            if let cursor { _ = query.gt("id", value: cursor.uuidString.lowercased()) }
            let page: [Row] = try await query.order("id").limit(pageSize).execute().value
            rows.append(contentsOf: page)
            cursor = page.count == pageSize ? page.last?[keyPath: id] : nil
        } while cursor != nil
        return rows
    }

    func upsertVault(_ rows: [VaultRecord]) async throws {
        try await client.from("mt_vault").upsert(rows, returning: .minimal).execute()
    }

    func deleteVault(ids: [UUID], table: SyncTable, userId: UUID, keyId: String) async throws {
        try await client.from("mt_vault").delete()
            .in("id", values: ids.map { $0.uuidString.lowercased() })
            .eq("user_id", value: userId.uuidString.lowercased())
            .eq("kind", value: table.kind)
            .eq("key_id", value: keyId)
            .execute()
    }
}

struct VaultRemote: SyncRemote {
    enum Failure: Error {
        case wrongUser, wrongKind, wrongKey, mismatchedID
    }

    let access: any VaultAccess
    let dek: SymmetricKey
    let owner: UUID
    // Sync and migration scope reads. Unscoped diagnostics can still detect a mismatched row.
    var scopeReads = false
    private let batchSize = 200

    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
        guard userId == owner else { throw Failure.wrongUser }
        return try await access.vaultIds(table: table, userId: owner, keyId: VaultCrypto.keyId(dek: dek))
    }

    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
        guard userId == owner else { throw Failure.wrongUser }
        let keyId = try VaultCrypto.keyId(dek: dek)
        let records = try await access.vaultRows(table: table, userId: owner, keyId: scopeReads ? keyId : nil)
        let decoder = VaultJSON.decoder
        return try records.map { record in
            guard record.userId == owner else { throw Failure.wrongUser }
            guard record.kind == table.kind else { throw Failure.wrongKind }
            guard record.keyId == keyId else { throw Failure.wrongKey }
            let aad = VaultCrypto.rowAAD(kind: table.kind, id: record.id, userID: owner)
            let data = try VaultCrypto.open(record.payload, key: dek, aad: aad)
            let row = try decoder.decode(Row.self, from: data)
            guard row.id == record.id else { throw Failure.mismatchedID }
            return row
        }
    }

    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
        guard userId == owner else { throw Failure.wrongUser }
        let keyId = try VaultCrypto.keyId(dek: dek)
        let encoder = VaultJSON.encoder
        for offset in stride(from: 0, to: rows.count, by: batchSize) {
            let end = min(offset + batchSize, rows.count)
            let batch = try rows[offset..<end].map { row in
                let aad = VaultCrypto.rowAAD(kind: table.kind, id: row.id, userID: owner)
                return VaultRecord(id: row.id, userId: owner, kind: table.kind, keyId: keyId,
                                   payload: try VaultCrypto.seal(encoder.encode(row), key: dek, aad: aad))
            }
            try await access.upsertVault(batch)
        }
    }

    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
        guard userId == owner else { throw Failure.wrongUser }
        let keyId = try VaultCrypto.keyId(dek: dek)
        for offset in stride(from: 0, to: ids.count, by: batchSize) {
            let end = min(offset + batchSize, ids.count)
            try await access.deleteVault(ids: Array(ids[offset..<end]), table: table, userId: owner, keyId: keyId)
        }
    }
}
