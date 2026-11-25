import CryptoKit
import Foundation
import Security

struct E2EKeyStore {
    private let service: String

    init(service: String = "com.bucktrail.e2e.dek") {
        self.service = service
    }

    struct Entry {
        let dek: SymmetricKey
        let keyId: String
    }

    enum Failure: Error {
        case keychain(OSStatus)
        case invalidEntry
    }

    private struct StoredEntry: Codable {
        let dek: String
        let keyId: String
        let userId: String

        enum CodingKeys: String, CodingKey {
            case dek
            case keyId = "key_id"
            case userId = "user_id"
        }
    }

    func load(userId: UUID) throws -> Entry? {
        var query = identity(userId: userId)
        query[kSecReturnData as String] = true
        query[kSecMatchLimit as String] = kSecMatchLimitOne
        var result: CFTypeRef?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        if status == errSecItemNotFound { return nil }
        guard status == errSecSuccess else { throw Failure.keychain(status) }
        guard let data = result as? Data,
              let stored = try? JSONDecoder().decode(StoredEntry.self, from: data),
              stored.userId == userId.uuidString.lowercased(),
              let bytes = try? VaultCrypto.decodeBase64URL(stored.dek),
              bytes.count == 32 else {
            throw Failure.invalidEntry
        }
        let dek = SymmetricKey(data: bytes)
        guard try VaultCrypto.keyId(dek: dek) == stored.keyId else { throw Failure.invalidEntry }
        return Entry(dek: dek, keyId: stored.keyId)
    }

    func save(_ dek: SymmetricKey, userId: UUID) throws {
        let stored = StoredEntry(dek: dek.withUnsafeBytes { VaultCrypto.encodeBase64URL(Data($0)) },
                                 keyId: try VaultCrypto.keyId(dek: dek),
                                 userId: userId.uuidString.lowercased())
        let query = identity(userId: userId)
        let attributes: [String: Any] = [
            kSecValueData as String: try JSONEncoder().encode(stored),
            kSecAttrAccessible as String: kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly
        ]
        var status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
        if status == errSecItemNotFound {
            let item = query.merging(attributes) { _, value in value }
            status = SecItemAdd(item as CFDictionary, nil)
            if status == errSecDuplicateItem {
                status = SecItemUpdate(query as CFDictionary, attributes as CFDictionary)
            }
        }
        guard status == errSecSuccess else { throw Failure.keychain(status) }
    }

    func remove(userId: UUID) throws {
        let status = SecItemDelete(identity(userId: userId) as CFDictionary)
        guard status == errSecSuccess || status == errSecItemNotFound else {
            throw Failure.keychain(status)
        }
    }

    private func identity(userId: UUID) -> [String: Any] {
        [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: service,
            kSecAttrAccount as String: userId.uuidString.lowercased(),
            kSecAttrSynchronizable as String: false
        ]
    }
}
