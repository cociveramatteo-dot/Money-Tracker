package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.e2e.VaultCrypto.CryptoException
import com.bucktrail.android.sync.e2e.VaultCrypto.Failure

internal object RecoveryKey {
    const val byteCount = 20
    private const val alphabet = "0123456789ABCDEFGHJKMNPQRSTVWXYZ"
    private const val characterCount = 32

    fun generate(): ByteArray = VaultCrypto.randomBytes(byteCount)

    fun format(bytes: ByteArray): String {
        if (bytes.size != byteCount) throw CryptoException(Failure.malformed)
        return buildString {
            var buffer = 0
            var bits = 0
            var characters = 0
            for (byte in bytes) {
                buffer = (buffer shl 8) or (byte.toInt() and 0xff)
                bits += 8
                while (bits >= 5) {
                    bits -= 5
                    if (characters > 0 && characters % 4 == 0) append('-')
                    append(alphabet[(buffer ushr bits) and 31])
                    characters++
                }
            }
        }
    }

    fun parse(text: String): ByteArray {
        val bytes = ByteArray(byteCount)
        var buffer = 0
        var bits = 0
        var characters = 0
        var written = 0
        for (character in text) {
            if (character == '-' || character == ' ' || character in '\t'..'\r') continue
            val upper = if (character in 'a'..'z') character.uppercaseChar() else character
            val symbol = when (upper) {
                'O' -> '0'
                'I', 'L' -> '1'
                else -> upper
            }
            val value = alphabet.indexOf(symbol)
            if (value < 0 || characters >= characterCount) throw CryptoException(Failure.malformed)
            characters++
            buffer = (buffer shl 5) or value
            bits += 5
            if (bits >= 8) {
                bits -= 8
                bytes[written++] = (buffer ushr bits).toByte()
            }
        }
        if (characters != characterCount) throw CryptoException(Failure.malformed)
        return bytes
    }
}
