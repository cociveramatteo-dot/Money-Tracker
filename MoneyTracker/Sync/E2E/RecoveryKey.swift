import Foundation
import Security

nonisolated enum RecoveryKey {
    static let byteCount = 20
    private static let alphabet = Array("0123456789ABCDEFGHJKMNPQRSTVWXYZ".utf8)
    private static let characterCount = 32

    static func generate() throws -> Data {
        var bytes = [UInt8](repeating: 0, count: byteCount)
        guard SecRandomCopyBytes(kSecRandomDefault, byteCount, &bytes) == errSecSuccess else {
            throw VaultCrypto.Failure.operationFailed
        }
        return Data(bytes)
    }

    static func format(_ bytes: Data) throws -> String {
        guard bytes.count == byteCount else { throw VaultCrypto.Failure.malformed }
        var text = [UInt8]()
        var buffer: UInt16 = 0
        var bits = 0
        var characters = 0
        for byte in bytes {
            buffer = (buffer << 8) | UInt16(byte)
            bits += 8
            while bits >= 5 {
                bits -= 5
                if characters > 0 && characters.isMultiple(of: 4) { text.append(45) }
                text.append(alphabet[Int((buffer >> bits) & 31)])
                characters += 1
            }
        }
        return String(decoding: text, as: UTF8.self)
    }

    static func parse(_ text: String) throws -> Data {
        var bytes = Data()
        var buffer: UInt16 = 0
        var bits = 0
        var characters = 0
        for byte in text.utf8 {
            if byte == 45 || byte == 32 || (9...13).contains(byte) { continue }
            let uppercase = (97...122).contains(byte) ? byte - 32 : byte
            let symbol: UInt8
            switch uppercase {
            case 79: symbol = 48 // O → 0
            case 73, 76: symbol = 49 // I, L → 1
            default: symbol = uppercase
            }
            guard characters < characterCount, let value = alphabet.firstIndex(of: symbol) else {
                throw VaultCrypto.Failure.malformed
            }
            characters += 1
            buffer = (buffer << 5) | UInt16(value)
            bits += 5
            if bits >= 8 {
                bits -= 8
                bytes.append(UInt8(truncatingIfNeeded: buffer >> bits))
            }
        }
        guard characters == characterCount else { throw VaultCrypto.Failure.malformed }
        return bytes
    }
}
