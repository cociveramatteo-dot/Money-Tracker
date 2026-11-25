import CryptoKit
import Foundation

enum E2EMigrationDirection: String, Codable {
    case enable, disable
}

struct E2EMigrationMarker: Codable {
    static let defaultsKey = "e2e.migration"
    let direction: E2EMigrationDirection
    let userId: UUID
    let keyId: String
    let startedAt: Int64

    enum CodingKeys: String, CodingKey {
        case direction
        case userId = "user_id"
        case keyId = "key_id"
        case startedAt = "started_at"
    }
}

struct E2EGate {
    enum LockReason: Equatable {
        case needsSecret, transition, unsupported
    }

    enum Mode {
        case plain
        case vault(SymmetricKey)
        case locked(LockReason)
        case resume(E2EMigrationDirection)
    }

    struct Resolution {
        let mode: Mode
        var serverSupported: Bool? = true
        var needsPlainInitialSync = false
    }

    let server: any E2EServerAccess
    let keyStore: E2EKeyStore

    func resolve(userId: UUID, enabled: Bool = E2EFeature.isEnabled,
                 marker: E2EMigrationMarker? = nil,
                 validateSession: () throws -> Void = {}) async throws -> Resolution {
        guard enabled else { return Resolution(mode: .plain, serverSupported: nil) }
        let lookup: E2EServerLookup
        do {
            lookup = try await server.lookup(userId: userId)
        } catch is DecodingError {
            return Resolution(mode: .locked(.unsupported))
        }
        try validateSession()

        switch lookup {
        case .unavailable:
            return Resolution(mode: .plain, serverSupported: false)
        case .absent:
            let hadKey = try keyStore.load(userId: userId) != nil
            if hadKey { try keyStore.remove(userId: userId) }
            return Resolution(mode: .plain, needsPlainInitialSync: hadKey)
        case .row(let row):
            guard row.userId == userId, row.hasSupportedParameters else {
                return Resolution(mode: .locked(.unsupported))
            }
            let local = try keyStore.load(userId: userId)
            let matchingKey = local.flatMap { $0.keyId == row.keyId ? $0.dek : nil }
            if local != nil && matchingKey == nil {
                try keyStore.remove(userId: userId)
            }

            switch row.state {
            case .active:
                if let matchingKey { return Resolution(mode: .vault(matchingKey)) }
                return Resolution(mode: .locked(.needsSecret))
            case .migrating, .disabling:
                let direction: E2EMigrationDirection = row.state == .migrating ? .enable : .disable
                if matchingKey != nil, let marker,
                   marker.userId == userId, marker.direction == direction, marker.keyId == row.keyId {
                    return Resolution(mode: .resume(direction))
                }
                return Resolution(mode: .locked(.transition))
            }
        }
    }
}
