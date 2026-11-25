import CryptoKit
import Foundation
import Testing
@testable import MoneyTracker

struct E2ECryptoTests {
    @Test func aesGCMKnownAnswer() throws {
        let vector = try Self.fixture().aesGcmKat
        let key = try Self.key(vector.keyHex)
        let plaintext = try Self.bytes(vector.plaintextHex)
        let aad = try Self.bytes(vector.aadHex)
        let nonce = try Self.bytes(vector.nonceHex)
        let wire = try VaultCrypto.sealForTest(plaintext, key: key, aad: aad, nonce: nonce)
        #expect(wire == vector.envelope)
        let combined = try VaultCrypto.decodeBase64URL(wire.dropFirst(4))
        let expectedCombined = try nonce + Self.bytes(vector.ciphertextHex) + Self.bytes(vector.tagHex)
        #expect(combined == expectedCombined)
        #expect(try VaultCrypto.open(vector.envelope, key: key, aad: aad) == plaintext)
    }

    @Test func hkdfRFC5869() throws {
        let vector = try Self.fixture().hkdfRfc5869
        let derived = try HKDF<SHA256>.deriveKey(
            inputKeyMaterial: Self.key(vector.ikmHex),
            salt: Self.bytes(vector.saltHex),
            info: Self.bytes(vector.infoHex),
            outputByteCount: vector.length
        )
        #expect(try Self.raw(derived) == Self.bytes(vector.okmHex))
    }

    @Test func pbkdf2VectorsAndVerbatimWhitespace() throws {
        let vectors = try Self.fixture().pbkdf2
        #expect(vectors.count == 3)
        for vector in vectors {
            let salt = try VaultCrypto.decodeBase64URL(vector.salt)
            let key = try vector.iterations == 1000
                ? VaultCrypto.deriveKEKForTest(passphrase: vector.passphrase, salt: salt, iterations: 1000)
                : VaultCrypto.deriveKEK(passphrase: vector.passphrase, salt: salt, iterations: vector.iterations)
            #expect(try Self.raw(key) == Self.bytes(vector.kekHex))
        }
        let unicode = try #require(vectors.last)
        let nfc = unicode.passphrase.precomposedStringWithCanonicalMapping
        #expect(Array(unicode.passphrase.utf8) != Array(nfc.utf8))
        let salt = try VaultCrypto.decodeBase64URL(unicode.salt)
        let nfcKey = try VaultCrypto.deriveKEK(passphrase: nfc, salt: salt)
        #expect(try Self.raw(nfcKey) == Self.bytes(unicode.kekHex))
        let spaced = try VaultCrypto.deriveKEK(passphrase: " " + nfc + " ", salt: salt)
        #expect(Self.raw(spaced) != Self.raw(nfcKey))
    }

    @Test func crockfordVectors() throws {
        let vectors = try Self.fixture().crockford
        #expect(vectors.count == 4)
        for vector in vectors {
            let bytes = try Self.bytes(vector.bytesHex)
            #expect(try RecoveryKey.format(bytes) == vector.formatted)
            #expect(try RecoveryKey.parse(vector.input) == bytes)
        }
        let random = try RecoveryKey.generate()
        #expect(random.count == 20)
        #expect(try RecoveryKey.parse(RecoveryKey.format(random)) == random)
    }

    @Test func envelopeAndWrappingVectors() throws {
        let fixture = try Self.fixture()
        let row = fixture.envelope
        let rowID = try #require(UUID(uuidString: row.id))
        let userID = try #require(UUID(uuidString: row.userId))
        let rowAAD = VaultCrypto.rowAAD(kind: row.kind.uppercased(), id: rowID, userID: userID)
        #expect(rowAAD == Data(row.aad.utf8))
        let rowKey = try Self.key(row.keyHex)
        let cleartext = Data(row.plaintext.utf8)
        let sealed = try VaultCrypto.sealForTest(cleartext, key: rowKey, aad: rowAAD, nonce: Self.bytes(row.nonceHex))

        let wrap = fixture.wrap
        let wrapUser = try #require(UUID(uuidString: wrap.userId))
        let dek = try Self.key(wrap.dekHex)
        let salt = try VaultCrypto.decodeBase64URL(wrap.salt)
        let passwordKey = try VaultCrypto.deriveKEK(passphrase: wrap.passphrase, salt: salt, iterations: wrap.iterations)
        let recoveryKey = try VaultCrypto.recoveryKEK(RecoveryKey.parse(wrap.recoveryKey))
        #expect(try Self.raw(recoveryKey) == Self.bytes(wrap.recoveryKekHex))
        let passphraseAAD = VaultCrypto.wrapAAD(.passphrase, userID: wrapUser)
        let recoveryAAD = VaultCrypto.wrapAAD(.recovery, userID: wrapUser)
        #expect(passphraseAAD == Data(wrap.passphraseAad.utf8))
        #expect(recoveryAAD == Data(wrap.recoveryAad.utf8))
        let sealedPassword = try VaultCrypto.sealForTest(
            Self.raw(dek), key: passwordKey, aad: passphraseAAD, nonce: Self.bytes(wrap.passphraseNonceHex)
        )
        let sealedRecovery = try VaultCrypto.sealForTest(
            Self.raw(dek), key: recoveryKey, aad: recoveryAAD, nonce: Self.bytes(wrap.recoveryNonceHex)
        )
        #expect(sealed == row.sealed)
        #expect(try VaultCrypto.open(row.sealed, key: rowKey, aad: rowAAD) == cleartext)
        #expect(sealedPassword == wrap.wrappedKeyPassphrase)
        #expect(sealedRecovery == wrap.wrappedKeyRecovery)
        #expect(try Self.raw(VaultCrypto.unwrap(wrap.wrappedKeyPassphrase, key: passwordKey, aad: passphraseAAD)) == Self.raw(dek))
        #expect(try Self.raw(VaultCrypto.unwrap(wrap.wrappedKeyRecovery, key: recoveryKey, aad: recoveryAAD)) == Self.raw(dek))
        #expect(try VaultCrypto.keyId(dek: dek) == wrap.keyId)
        let randomWrap = try VaultCrypto.wrap(dek, key: recoveryKey, aad: recoveryAAD)
        #expect(try Self.raw(VaultCrypto.unwrap(randomWrap, key: recoveryKey, aad: recoveryAAD)) == Self.raw(dek))
    }

    @Test func invalidEnvelopesAndCredentialsAreRejected() throws {
        let fixture = try Self.fixture()
        let row = fixture.envelope
        let rowKey = try Self.key(row.keyHex)
        let aad = Data(row.aad.utf8)
        let bad = fixture.negative
        #expect(throws: VaultCrypto.Failure.authenticationFailed) {
            try VaultCrypto.open(bad.tagAltered, key: rowKey, aad: aad)
        }
        #expect(throws: VaultCrypto.Failure.unsupportedVersion) {
            try VaultCrypto.open(bad.unsupportedVersion, key: rowKey, aad: aad)
        }
        for malformed in [bad.invalidBase64, "", "junk", "bt1.", "bt1.AA", "bt1.AB", row.sealed + "="] {
            #expect(throws: VaultCrypto.Failure.malformed) {
                try VaultCrypto.open(malformed, key: rowKey, aad: aad)
            }
        }
        for wrongAAD in [bad.wrongIdAad, bad.wrongKindAad, bad.wrongUserAad] {
            #expect(throws: VaultCrypto.Failure.authenticationFailed) {
                try VaultCrypto.open(row.sealed, key: rowKey, aad: Data(wrongAAD.utf8))
            }
        }

        let wrap = fixture.wrap
        let salt = try VaultCrypto.decodeBase64URL(wrap.salt)
        let wrongPassword = try VaultCrypto.deriveKEK(passphrase: bad.wrongPassphrase, salt: salt)
        let wrongRecovery = try VaultCrypto.recoveryKEK(RecoveryKey.parse(bad.wrongRecoveryKey))
        #expect(throws: VaultCrypto.Failure.authenticationFailed) {
            try VaultCrypto.unwrap(wrap.wrappedKeyPassphrase, key: wrongPassword, aad: Data(wrap.passphraseAad.utf8))
        }
        #expect(throws: VaultCrypto.Failure.authenticationFailed) {
            try VaultCrypto.unwrap(wrap.wrappedKeyRecovery, key: wrongRecovery, aad: Data(wrap.recoveryAad.utf8))
        }
        for malformed in ["", "U" + wrap.recoveryKey.dropFirst(), String(wrap.recoveryKey.dropLast()), wrap.recoveryKey + "0"] {
            #expect(throws: VaultCrypto.Failure.malformed) { try RecoveryKey.parse(malformed) }
        }
        for iterations in [Int.min, 99_999, 10_000_001, Int.max] {
            #expect(throws: VaultCrypto.Failure.unsupportedVersion) {
                try VaultCrypto.deriveKEK(passphrase: wrap.passphrase, salt: salt, iterations: iterations)
            }
        }
        #expect(throws: VaultCrypto.Failure.malformed) {
            try VaultCrypto.deriveKEK(passphrase: wrap.passphrase, salt: Data(salt.dropLast()))
        }
        #expect(throws: VaultCrypto.Failure.malformed) {
            try VaultCrypto.deriveKEK(passphrase: "short", salt: salt)
        }
    }

    @Test func randomNoncesDoNotRepeat() throws {
        let key = SymmetricKey(size: .bits256)
        var nonces = Set<Data>()
        for _ in 0..<10_000 {
            let envelope = try VaultCrypto.seal(Data(), key: key, aad: Data())
            let nonce = try VaultCrypto.decodeBase64URL(envelope.dropFirst(4)).prefix(12)
            nonces.insert(Data(nonce))
        }
        #expect(nonces.count == 10_000)
    }

    @Test func envelopeSizeAndKeyBoundaries() throws {
        let key = SymmetricKey(size: .bits256)
        let shorterKey = SymmetricKey(size: .bits128)
        let aad = Data()
        let empty = try VaultCrypto.seal(Data(), key: key, aad: aad)
        #expect(try VaultCrypto.open(empty, key: key, aad: aad).isEmpty)
        let largest = Data(repeating: 0x41, count: 49_120)
        let envelope = try VaultCrypto.seal(largest, key: key, aad: aad)
        #expect(envelope.utf8.count == 65_535)
        #expect(try VaultCrypto.open(envelope, key: key, aad: aad) == largest)
        #expect(throws: VaultCrypto.Failure.malformed) {
            try VaultCrypto.seal(largest + Data([0]), key: key, aad: aad)
        }
        #expect(throws: VaultCrypto.Failure.malformed) {
            try VaultCrypto.open(envelope + "A", key: key, aad: aad)
        }
        #expect(throws: VaultCrypto.Failure.malformed) { try VaultCrypto.seal(Data(), key: shorterKey, aad: aad) }
        #expect(throws: VaultCrypto.Failure.malformed) { try VaultCrypto.unwrap(empty, key: key, aad: aad) }
        #expect(throws: VaultCrypto.Failure.malformed) { try VaultCrypto.recoveryKEK(Data(repeating: 0, count: 19)) }
    }

    @Test func jsonUsesSortedKeysDecimalNumbersAndUTCMilliseconds() throws {
        struct Row: Codable, Equatable {
            let updatedAt: Date
            let amount: Decimal

            enum CodingKeys: String, CodingKey {
                case updatedAt = "updated_at"
                case amount
            }
        }
        let row = Row(updatedAt: Date(timeIntervalSince1970: 1_700_000_000.125), amount: Decimal(1234) / 100)
        let encoded = try VaultJSON.encoder.encode(row)
        #expect(String(decoding: encoded, as: UTF8.self) == #"{"amount":12.34,"updated_at":"2023-11-14T22:13:20.125Z"}"#)
        for value in ["2023-11-14T22:13:20.125Z", "2023-11-14T22:13:20.125+00:00"] {
            let json = Data("{\"updated_at\":\"\(value)\",\"amount\":12.34}".utf8)
            #expect(try VaultJSON.decoder.decode(Row.self, from: json) == row)
        }
        for value in ["2023-11-14T22:13:20Z", "2023-11-14T22:13:20+00:00"] {
            let json = Data("{\"updated_at\":\"\(value)\",\"amount\":12.34}".utf8)
            let decoded = try VaultJSON.decoder.decode(Row.self, from: json)
            #expect(decoded.updatedAt == Date(timeIntervalSince1970: 1_700_000_000))
        }
        #expect(throws: DecodingError.self) {
            try VaultJSON.decoder.decode(Row.self, from: Data(#"{"amount":1,"updated_at":"invalid"}"#.utf8))
        }
    }

    @Test func featureIsOffByDefault() {
        #expect(!E2EFeature.isEnabled)
        #expect(E2EFeature.allowNewActivations)
    }

    private static func fixture() throws -> Fixture {
        let bundle = Bundle(for: FixtureBundle.self)
        let url = try #require(bundle.url(forResource: "e2e-vectors-v1", withExtension: "json", subdirectory: "Fixtures")
            ?? bundle.url(forResource: "e2e-vectors-v1", withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        return try decoder.decode(Fixture.self, from: Data(contentsOf: url))
    }

    private static func bytes(_ hex: String) throws -> Data {
        let input = Array(hex.utf8)
        #expect(input.count.isMultiple(of: 2))
        let result = try stride(from: 0, to: input.count, by: 2).map { offset in
            try #require(UInt8(String(decoding: input[offset..<min(offset + 2, input.count)], as: UTF8.self), radix: 16))
        }
        return Data(result)
    }

    private static func key(_ hex: String) throws -> SymmetricKey {
        try SymmetricKey(data: bytes(hex))
    }

    private static func raw(_ key: SymmetricKey) -> Data {
        key.withUnsafeBytes { Data($0) }
    }

    private final class FixtureBundle {}

    private struct Fixture: Decodable {
        let aesGcmKat: AES
        let hkdfRfc5869: HKDFVector
        let pbkdf2: [PBKDF2]
        let crockford: [Crockford]
        let envelope: Envelope
        let wrap: Wrap
        let negative: Negative

        struct AES: Decodable {
            let keyHex, nonceHex, aadHex, plaintextHex, ciphertextHex, tagHex, envelope: String
        }

        struct HKDFVector: Decodable {
            let ikmHex, saltHex, infoHex, okmHex: String
            let length: Int
        }

        struct PBKDF2: Decodable {
            let passphrase, salt, kekHex: String
            let iterations: Int
        }

        struct Crockford: Decodable {
            let bytesHex, formatted, input: String
        }

        struct Envelope: Decodable {
            let keyHex, nonceHex, kind, id, userId, aad, plaintext, sealed: String
        }

        struct Wrap: Decodable {
            let userId, passphrase, salt, dekHex, recoveryKey, recoveryKekHex: String
            let passphraseAad, recoveryAad, passphraseNonceHex, recoveryNonceHex: String
            let wrappedKeyPassphrase, wrappedKeyRecovery, keyId: String
            let iterations: Int
        }

        struct Negative: Decodable {
            let tagAltered, unsupportedVersion, invalidBase64, wrongIdAad, wrongKindAad, wrongUserAad: String
            let wrongPassphrase, wrongRecoveryKey: String
        }
    }
}
