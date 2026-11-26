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
    var phase: Phase? = nil
    var generation: String? = nil
    var activationGeneration: String? = nil

    enum Phase: String, Codable {
        case verified, rollingBack, resetting
    }

    enum CodingKeys: String, CodingKey {
        case direction, phase, generation
        case activationGeneration = "activation_generation"
        case userId = "user_id"
        case keyId = "key_id"
        case startedAt = "started_at"
    }

    func owns(_ row: E2EServerRow) -> Bool {
        let expected = row.state == .active && direction == .enable && phase == .verified
            ? activationGeneration ?? generation : generation
        return userId == row.userId && keyId == row.keyId
            && E2EServerRow.sameGeneration(expected, row.updatedAt)
    }
}

struct E2EGate {
    enum LockReason: Equatable {
        case needsSecret, transition, unsupported
        /// The server row is gone while this device still holds a DEK: the
        /// user must confirm before the data syncs again without encryption.
        case protectionRemoved
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
        var row: E2EServerRow?
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

        let ownMarker = marker?.userId == userId ? marker : nil
        switch lookup {
        case .unavailable:
            // A device that already holds E2E state must never fall back to plain
            // just because the server lost (or never had) the feature.
            let hasKey = try keyStore.load(userId: userId) != nil
            if ownMarker != nil || hasKey {
                return Resolution(mode: .locked(.unsupported))
            }
            return Resolution(mode: .plain, serverSupported: false)
        case .absent:
            return try resolveAbsent(userId: userId, marker: ownMarker)
        case .row(let row):
            guard row.userId == userId, row.hasSupportedParameters else {
                return Resolution(mode: .locked(.unsupported))
            }
            let local = try keyStore.load(userId: userId)
            let matchingKey = local.flatMap { $0.keyId == row.keyId ? $0.dek : nil }
            if local != nil && matchingKey == nil {
                try keyStore.remove(userId: userId)
            }

            if let marker, marker.owns(row) {
                switch (row.state, marker.direction, marker.phase) {
                case (.active, .enable, .verified), (.active, .disable, .rollingBack):
                    if matchingKey != nil {
                        return Resolution(mode: .resume(marker.direction), row: row)
                    }
                case (.active, .disable, .resetting):
                    return Resolution(mode: .resume(.disable), row: row)
                default:
                    break
                }
            }

            switch row.state {
            case .active:
                if let matchingKey { return Resolution(mode: .vault(matchingKey), row: row) }
                return Resolution(mode: .locked(.needsSecret), row: row)
            case .migrating, .disabling:
                let direction: E2EMigrationDirection = row.state == .migrating ? .enable : .disable
                if matchingKey != nil, let marker,
                   marker.direction == direction, marker.owns(row) {
                    return Resolution(mode: .resume(direction), row: row)
                }
                return Resolution(mode: .locked(.transition), row: row)
            }
        }
    }

    /// No `mt_e2e` row. The caller removes a disable marker when the mode is
    /// plain or `protectionRemoved` (the gate has no access to the defaults).
    private func resolveAbsent(userId: UUID, marker: E2EMigrationMarker?) throws -> Resolution {
        if let marker, marker.direction == .disable {
            switch marker.phase {
            case .verified, .resetting:
                // D5–D7 or a restart already deleted the row: finish the cleanup.
                return Resolution(mode: .resume(.disable))
            case nil:
                // D2 without D3: the server never left plain mode. The first
                // exchange pulls before pushing and never deletes remote rows.
                try keyStore.remove(userId: userId)
                return Resolution(mode: .plain, needsPlainInitialSync: true)
            case .rollingBack:
                break
            }
        }
        let hasKey = try keyStore.load(userId: userId) != nil
        if hasKey, marker == nil || marker?.direction == .disable {
            return Resolution(mode: .locked(.protectionRemoved))
        }
        if hasKey { try keyStore.remove(userId: userId) }
        return Resolution(mode: .plain, needsPlainInitialSync: hasKey || marker?.direction == .disable)
    }
}
