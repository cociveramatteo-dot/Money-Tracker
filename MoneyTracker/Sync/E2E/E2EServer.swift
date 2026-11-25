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
    var updatedAt: Date? = nil

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
}

nonisolated struct E2EServerPatch: Encodable, Sendable {
    var state: E2EServerState? = nil
    var kdfIterations: Int? = nil
    var salt: String? = nil
    var wrappedKeyPassphrase: String? = nil
    var wrappedKeyRecovery: String? = nil

    enum CodingKeys: String, CodingKey {
        case state, salt
        case kdfIterations = "kdf_iterations"
        case wrappedKeyPassphrase = "wrapped_key_passphrase"
        case wrappedKeyRecovery = "wrapped_key_recovery"
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
}

extension E2EServerAccess {
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
    }
}

struct E2EServer: E2EServerAccess {
    private let client: PostgrestClient

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
        let updated: [E2EServerRow] = try await client.from("mt_e2e").update(changes)
            .eq("user_id", value: row.userId.uuidString.lowercased())
            .eq("key_id", value: row.keyId).eq("state", value: row.state.rawValue)
            .select().execute().value
        return updated.count == 1
    }

    func delete(ifCurrent row: E2EServerRow) async throws -> Bool {
        let deleted: [E2EServerRow] = try await client.from("mt_e2e").delete()
            .eq("user_id", value: row.userId.uuidString.lowercased())
            .eq("key_id", value: row.keyId).eq("state", value: row.state.rawValue)
            .select().execute().value
        return deleted.count == 1
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
}
