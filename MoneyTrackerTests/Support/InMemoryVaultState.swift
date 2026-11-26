import Foundation
@testable import MoneyTracker

extension InMemoryRemote {
    // Mirrors the filtered key projection independently of the gate's full metadata lookup.
    func hasActiveVaultKey(userId: UUID, keyId: String) async throws -> Bool {
        if let lookupError { throw lookupError }
        guard supportsE2E, let row = e2eRows[userId] else { return false }
        return row.userId == userId && row.state == .active && row.keyId == keyId
    }
}
