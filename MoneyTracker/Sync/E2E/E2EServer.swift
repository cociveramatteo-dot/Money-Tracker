import Foundation
import Supabase

nonisolated enum E2EServerState: String, Codable, Sendable {
    case migrating, active, disabling
}

nonisolated struct E2EServerRow: Codable, Sendable {
    let userId: UUID
    var state: E2EServerState
    let version: Int
    let kdf: String
    var kdfIterations: Int
    var salt: String
    var wrappedKeyPassphrase: String
    var wrappedKeyRecovery: String
    let keyId: String
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case state, version, kdf, salt
        case userId = "user_id"
        case kdfIterations = "kdf_iterations"
        case wrappedKeyPassphrase = "wrapped_key_passphrase"
        case wrappedKeyRecovery = "wrapped_key_recovery"
        case keyId = "key_id"
        case updatedAt = "updated_at"
    }

    var hasSupportedParameters: Bool {
        let wrappedKeyBytes = 12 + 32 + 16 // GCM nonce, DEK, authentication tag.
        guard version == 1, kdf == "pbkdf2-sha256",
              VaultCrypto.supportedIterations.contains(kdfIterations),
              let saltBytes = try? VaultCrypto.decodeBase64URL(salt),
              saltBytes.count == VaultCrypto.saltByteCount,
              keyId.utf8.count == 16,
              keyId.utf8.allSatisfy({ (48...57).contains($0) || (97...102).contains($0) }) else {
            return false
        }
        return [wrappedKeyPassphrase, wrappedKeyRecovery].allSatisfy {
            $0.hasPrefix("bt1.") && $0.utf8.count < 512
                && (try? VaultCrypto.decodeBase64URL($0.dropFirst(4)).count) == wrappedKeyBytes
        }
    }

    static func generationDate(_ generation: String?) -> Date? {
        guard let generation else { return nil }
        return (try? Date.ISO8601FormatStyle(includingFractionalSeconds: true).parse(generation))
            ?? (try? Date.ISO8601FormatStyle().parse(generation))
    }

    static func sameGeneration(_ first: String?, _ second: String?) -> Bool {
        if first == second { return true }
        guard let date = generationDate(first) else { return false }
        return date == generationDate(second)
    }
}

nonisolated struct E2EServerPatch: Encodable, Sendable {
    var state: E2EServerState? = nil
    var kdfIterations: Int? = nil
    var salt: String? = nil
    var wrappedKeyPassphrase: String? = nil
    var wrappedKeyRecovery: String? = nil
    var updatedAt: String? = nil

    enum CodingKeys: String, CodingKey {
        case state, salt
        case kdfIterations = "kdf_iterations"
        case wrappedKeyPassphrase = "wrapped_key_passphrase"
        case wrappedKeyRecovery = "wrapped_key_recovery"
        case updatedAt = "updated_at"
    }
}

enum E2EServerLookup {
    case unavailable
    case absent
    case row(E2EServerRow)
}

@MainActor
protocol E2EServerAccess {
    func lookup(userId: UUID) async throws -> E2EServerLookup
    func insert(_ row: E2EServerRow) async throws
    func patch(_ changes: E2EServerPatch, userId: UUID) async throws
    func delete(userId: UUID) async throws
    func patch(_ changes: E2EServerPatch, ifCurrent row: E2EServerRow) async throws -> Bool
    func delete(ifCurrent row: E2EServerRow) async throws -> Bool
    func activate(ifCurrent row: E2EServerRow, generation: String, counts: [String: Int]) async throws -> Bool
    func rollbackActivation(ifCurrent row: E2EServerRow) async throws -> Bool
}

extension E2EServerAccess {
    // In-memory transports use the same generation transition without HTTP.
    func activate(ifCurrent row: E2EServerRow, generation: String, counts: [String: Int]) async throws -> Bool {
        try await patch(E2EServerPatch(state: .active, updatedAt: generation), ifCurrent: row)
    }

    func patch(_ changes: E2EServerPatch, ifCurrent row: E2EServerRow) async throws -> Bool {
        guard try await stillCurrent(row) else { return false }
        try await patch(changes, userId: row.userId)
        return true
    }

    func delete(ifCurrent row: E2EServerRow) async throws -> Bool {
        guard try await stillCurrent(row) else { return false }
        try await delete(userId: row.userId)
        return true
    }

    private func stillCurrent(_ expected: E2EServerRow) async throws -> Bool {
        guard case .row(let row) = try await lookup(userId: expected.userId) else { return false }
        try Task.checkCancellation()
        return row.userId == expected.userId && row.keyId == expected.keyId && row.state == expected.state
            && E2EServerRow.sameGeneration(row.updatedAt, expected.updatedAt)
    }
}

struct E2EServer: E2EServerAccess {
    private let client: PostgrestClient

    private struct Activation: Encodable {
        let p_key_id: String
        let p_from_generation: String
        let p_to_generation: String
        let p_counts: [String: Int]
    }

    private struct ActivationRollback: Encodable {
        let p_key_id: String
        let p_generation: String
    }

    init(client: SupabaseClient) {
        var configuration = client.schema("public").configuration
        let fetch = configuration.fetch
        configuration.retryEnabled = false
        configuration.fetch = { request in
            let (data, response) = try await fetch(request)
            if let response = response as? HTTPURLResponse,
               response.statusCode == 404 || (500..<600).contains(response.statusCode) {
                // The SDK otherwise drops the HTTP status for JSON error bodies.
                throw HTTPError(data: Data(), response: response)
            }
            return (data, response)
        }
        self.client = PostgrestClient(configuration: configuration)
    }

    func lookup(userId: UUID) async throws -> E2EServerLookup {
        do {
            let rows: [E2EServerRow] = try await client.from("mt_e2e")
                .select().eq("user_id", value: userId.uuidString.lowercased())
                .execute().value
            guard rows.count <= 1 else { throw DecodingError.dataCorrupted(.init(
                codingPath: [], debugDescription: "Multiple E2E rows for one user"
            )) }
            return rows.first.map(E2EServerLookup.row) ?? .absent
        } catch where Self.isUnavailable(error) {
            return .unavailable
        }
    }

    func insert(_ row: E2EServerRow) async throws {
        try await client.from("mt_e2e").insert(row, returning: .minimal).execute()
    }

    func patch(_ changes: E2EServerPatch, userId: UUID) async throws {
        try await client.from("mt_e2e").update(changes, returning: .minimal)
            .eq("user_id", value: userId.uuidString.lowercased()).execute()
    }

    func delete(userId: UUID) async throws {
        try await client.from("mt_e2e").delete()
            .eq("user_id", value: userId.uuidString.lowercased()).execute()
    }

    func patch(_ changes: E2EServerPatch, ifCurrent row: E2EServerRow) async throws -> Bool {
        let query = try client.from("mt_e2e").update(changes)
            .eq("user_id", value: row.userId.uuidString.lowercased())
            .eq("key_id", value: row.keyId).eq("state", value: row.state.rawValue)
        if let generation = row.updatedAt { _ = query.eq("updated_at", value: generation) }
        else { _ = query.is("updated_at", value: nil) }
        let updated: [E2EServerRow] = try await query.select().execute().value
        return updated.count == 1
    }

    func delete(ifCurrent row: E2EServerRow) async throws -> Bool {
        let query = client.from("mt_e2e").delete()
            .eq("user_id", value: row.userId.uuidString.lowercased())
            .eq("key_id", value: row.keyId).eq("state", value: row.state.rawValue)
        if let generation = row.updatedAt { _ = query.eq("updated_at", value: generation) }
        else { _ = query.is("updated_at", value: nil) }
        let deleted: [E2EServerRow] = try await query.select().execute().value
        return deleted.count == 1
    }

    func activate(ifCurrent row: E2EServerRow, generation: String, counts: [String: Int]) async throws -> Bool {
        guard row.state == .migrating, let current = row.updatedAt else { return false }
        do {
            try await client.rpc("mt_e2e_activate", params: Activation(
                p_key_id: row.keyId, p_from_generation: current,
                p_to_generation: generation, p_counts: counts
            )).execute()
            return true
        } catch where Self.operationStateChanged(error) {
            return false
        }
    }

    func rollbackActivation(ifCurrent row: E2EServerRow) async throws -> Bool {
        guard row.state == .migrating, let generation = row.updatedAt else { return false }
        do {
            try await client.rpc("mt_e2e_rollback", params: ActivationRollback(
                p_key_id: row.keyId, p_generation: generation
            )).execute()
            return true
        } catch where Self.operationStateChanged(error) {
            return false
        }
    }

    private static func isUnavailable(_ error: any Error) -> Bool {
        if let code = (error as? PostgrestError)?.code {
            return code == "PGRST205" || code == "42P01"
        }
        return (error as? HTTPError)?.response.statusCode == 404
    }

    static func blockedPlainWrite(_ error: any Error) -> Bool {
        guard let error = error as? PostgrestError, error.code == "P0001" else { return false }
        return error.message == "bt_e2e_active" || error.message == "bt_e2e_migrating"
    }

    static func operationStateChanged(_ error: any Error) -> Bool {
        guard let error = error as? PostgrestError, error.code == "P0001" else { return false }
        return ["bt_e2e_state_changed", "bt_e2e_counts", "bt_e2e_key_mismatch",
                "bt_e2e_vault_locked", "bt_e2e_use_activate", "bt_e2e_use_rollback"].contains(error.message)
    }
}
