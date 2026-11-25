import CommonCrypto
import CryptoKit
import Foundation

nonisolated enum VaultCrypto {
    enum Failure: Error, Equatable {
        case malformed
        case unsupportedVersion
        case authenticationFailed
        case operationFailed
    }

    enum WrapPurpose: String {
        case passphrase
        case recovery
    }

    static let defaultIterations = 600_000
    static let supportedIterations = 100_000...10_000_000
    static let saltByteCount = 16

    private static let prefix = "bt1."
    private static let keyByteCount = 32
    private static let nonceByteCount = 12
    private static let tagByteCount = 16
    private static let envelopeLimit = 65_536 // The ASCII envelope must fit mt_vault.payload.
    private static let maxPlaintextBytes = (envelopeLimit - 1 - prefix.utf8.count) * 3 / 4
        - nonceByteCount - tagByteCount

    static func rowAAD(kind: String, id: UUID, userID: UUID) -> Data {
        Data("bucktrail/e2e/v1/row/\(kind.lowercased())/\(id.uuidString.lowercased())/\(userID.uuidString.lowercased())".utf8)
    }

    static func wrapAAD(_ purpose: WrapPurpose, userID: UUID) -> Data {
        Data("bucktrail/e2e/v1/wrap/\(purpose.rawValue)/\(userID.uuidString.lowercased())".utf8)
    }

    static func seal(_ plaintext: Data, key: SymmetricKey, aad: Data) throws -> String {
        try seal(plaintext, key: key, aad: aad, nonce: nil)
    }

    #if DEBUG
    // A deterministic nonce is available only to build and verify the shared fixtures.
    static func sealForTest(_ plaintext: Data, key: SymmetricKey, aad: Data, nonce: Data) throws -> String {
        guard nonce.count == nonceByteCount else { throw Failure.malformed }
        return try seal(plaintext, key: key, aad: aad, nonce: AES.GCM.Nonce(data: nonce))
    }
    #endif

    private static func seal(
        _ plaintext: Data, key: SymmetricKey, aad: Data, nonce: AES.GCM.Nonce?
    ) throws -> String {
        guard key.bitCount == keyByteCount * 8, plaintext.count <= maxPlaintextBytes else {
            throw Failure.malformed
        }
        let box = try AES.GCM.seal(plaintext, using: key, nonce: nonce, authenticating: aad)
        guard let combined = box.combined else { throw Failure.operationFailed }
        return prefix + encodeBase64URL(combined)
    }

    static func open(_ envelope: String, key: SymmetricKey, aad: Data) throws -> Data {
        guard envelope.utf8.count < envelopeLimit, key.bitCount == keyByteCount * 8 else {
            throw Failure.malformed
        }
        guard envelope.hasPrefix(prefix) else {
            if let dot = envelope.firstIndex(of: "."), envelope.hasPrefix("bt") {
                let version = envelope[..<dot].dropFirst(2).utf8
                if !version.isEmpty && version.allSatisfy({ (48...57).contains($0) }) {
                    throw Failure.unsupportedVersion
                }
            }
            throw Failure.malformed
        }
        let combined = try decodeBase64URL(envelope.dropFirst(prefix.count))
        guard combined.count >= nonceByteCount + tagByteCount else { throw Failure.malformed }
        let box = try AES.GCM.SealedBox(combined: combined)
        do {
            return try AES.GCM.open(box, using: key, authenticating: aad)
        } catch CryptoKitError.authenticationFailure {
            throw Failure.authenticationFailed
        }
    }

    // PBKDF2 is synchronous. Call it off the main actor when handling a user action.
    static func deriveKEK(
        passphrase: String, salt: Data, iterations: Int = defaultIterations
    ) throws -> SymmetricKey {
        guard supportedIterations.contains(iterations) else { throw Failure.unsupportedVersion }
        return try pbkdf2(passphrase: passphrase, salt: salt, iterations: UInt32(iterations))
    }

    #if DEBUG
    static func deriveKEKForTest(passphrase: String, salt: Data, iterations: UInt32) throws -> SymmetricKey {
        try pbkdf2(passphrase: passphrase, salt: salt, iterations: iterations)
    }
    #endif

    private static func pbkdf2(passphrase: String, salt: Data, iterations: UInt32) throws -> SymmetricKey {
        guard passphrase.count >= 10, salt.count == saltByteCount, iterations > 0 else {
            throw Failure.malformed
        }
        let password = passphrase.precomposedStringWithCanonicalMapping
        var output = Data(count: keyByteCount)
        let status = password.withCString { passwordBytes in
            salt.withUnsafeBytes { saltBytes in
                output.withUnsafeMutableBytes { outputBytes in
                    CCKeyDerivationPBKDF(
                        CCPBKDFAlgorithm(kCCPBKDF2), passwordBytes, password.utf8.count,
                        saltBytes.bindMemory(to: UInt8.self).baseAddress, saltBytes.count,
                        CCPseudoRandomAlgorithm(kCCPRFHmacAlgSHA256), iterations,
                        outputBytes.bindMemory(to: UInt8.self).baseAddress, outputBytes.count
                    )
                }
            }
        }
        guard status == kCCSuccess else { throw Failure.operationFailed }
        return SymmetricKey(data: output)
    }

    static func recoveryKEK(_ recoveryBytes: Data) throws -> SymmetricKey {
        guard recoveryBytes.count == RecoveryKey.byteCount else { throw Failure.malformed }
        return HKDF<SHA256>.deriveKey(
            inputKeyMaterial: SymmetricKey(data: recoveryBytes),
            info: Data("bucktrail/e2e/v1/recovery".utf8),
            outputByteCount: keyByteCount
        )
    }

    static func wrap(_ dek: SymmetricKey, key: SymmetricKey, aad: Data) throws -> String {
        guard dek.bitCount == keyByteCount * 8 else { throw Failure.malformed }
        return try seal(dek.withUnsafeBytes { Data($0) }, key: key, aad: aad)
    }

    static func unwrap(_ envelope: String, key: SymmetricKey, aad: Data) throws -> SymmetricKey {
        let dek = try open(envelope, key: key, aad: aad)
        guard dek.count == keyByteCount else { throw Failure.malformed }
        return SymmetricKey(data: dek)
    }

    static func keyId(dek: SymmetricKey) throws -> String {
        guard dek.bitCount == keyByteCount * 8 else { throw Failure.malformed }
        let mac = HMAC<SHA256>.authenticationCode(for: Data("bucktrail/e2e/v1/key-id".utf8), using: dek)
        return mac.prefix(8).map { String(format: "%02x", $0) }.joined()
    }

    static func encodeBase64URL(_ data: Data) -> String {
        data.base64EncodedString()
            .replacingOccurrences(of: "+", with: "-")
            .replacingOccurrences(of: "/", with: "_")
            .replacingOccurrences(of: "=", with: "")
    }

    static func decodeBase64URL(_ value: some StringProtocol) throws -> Data {
        guard value.utf8.allSatisfy({ byte in
            switch byte {
            case 65...90, 97...122, 48...57, 45, 95: true
            default: false
            }
        }) else { throw Failure.malformed }
        let standard = value.replacingOccurrences(of: "-", with: "+").replacingOccurrences(of: "_", with: "/")
        let padding = (4 - standard.utf8.count % 4) % 4
        guard padding != 3,
              let decoded = Data(base64Encoded: standard + String(repeating: "=", count: padding)),
              encodeBase64URL(decoded) == value else { throw Failure.malformed }
        return decoded
    }
}
