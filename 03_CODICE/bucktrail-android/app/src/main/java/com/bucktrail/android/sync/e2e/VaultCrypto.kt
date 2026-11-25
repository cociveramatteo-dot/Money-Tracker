package com.bucktrail.android.sync.e2e

import java.security.GeneralSecurityException
import java.security.ProviderException
import java.security.SecureRandom
import java.text.Normalizer
import java.util.Base64
import java.util.Locale
import java.util.UUID
import java.util.regex.Pattern
import javax.crypto.BadPaddingException
import javax.crypto.Cipher
import javax.crypto.Mac
import javax.crypto.SecretKeyFactory
import javax.crypto.spec.GCMParameterSpec
import javax.crypto.spec.PBEKeySpec
import javax.crypto.spec.SecretKeySpec

internal object VaultCrypto {
    enum class Failure { malformed, unsupportedVersion, authenticationFailed, operationFailed }
    class CryptoException(val failure: Failure, cause: Throwable? = null) :
        GeneralSecurityException(failure.name, cause)

    enum class WrapPurpose { passphrase, recovery }

    const val defaultIterations = 600_000
    val supportedIterations = 100_000..10_000_000
    const val saltByteCount = 16

    private const val prefix = "bt1."
    private const val keyByteCount = 32
    private const val nonceByteCount = 12
    private const val tagByteCount = 16
    private const val envelopeLimit = 65_536
    // The ASCII envelope must fit mt_vault.payload, as on iOS.
    private val maxPlaintextBytes = (envelopeLimit - 1 - prefix.length) * 3 / 4 -
        nonceByteCount - tagByteCount
    private const val hexDigits = "0123456789abcdef"
    private const val hmacAlgorithm = "HmacSHA256"
    private val grapheme = Pattern.compile("\\X")
    private val random by lazy { SecureRandom() }

    fun rowAAD(kind: String, id: UUID, userID: UUID): ByteArray =
        "bucktrail/e2e/v1/row/${kind.lowercase(Locale.ROOT)}/$id/$userID".toByteArray()

    fun wrapAAD(purpose: WrapPurpose, userID: UUID): ByteArray =
        "bucktrail/e2e/v1/wrap/${purpose.name}/$userID".toByteArray()

    fun seal(plaintext: ByteArray, key: ByteArray, aad: ByteArray): String =
        sealWithNonce(plaintext, key, aad, randomBytes(nonceByteCount))

    internal fun sealForTest(
        plaintext: ByteArray, key: ByteArray, aad: ByteArray, nonce: ByteArray
    ): String = sealWithNonce(plaintext, key, aad, nonce)

    private fun sealWithNonce(plaintext: ByteArray, key: ByteArray, aad: ByteArray, nonce: ByteArray): String {
        if (key.size != keyByteCount || plaintext.size > maxPlaintextBytes || nonce.size != nonceByteCount) {
            throw CryptoException(Failure.malformed)
        }
        return cryptoOperation {
            val cipher = gcm(Cipher.ENCRYPT_MODE, key, nonce, aad)
            prefix + encodeBase64URL(nonce + cipher.doFinal(plaintext))
        }
    }

    fun open(envelope: String, key: ByteArray, aad: ByteArray): ByteArray {
        if (key.size != keyByteCount || envelope.length >= envelopeLimit ||
            envelope.toByteArray().size >= envelopeLimit
        ) {
            throw CryptoException(Failure.malformed)
        }
        if (!envelope.startsWith(prefix)) {
            val dot = envelope.indexOf('.')
            if (dot > 2 && envelope.startsWith("bt") && (2 until dot).all { envelope[it] in '0'..'9' }) {
                throw CryptoException(Failure.unsupportedVersion)
            }
            throw CryptoException(Failure.malformed)
        }
        val combined = decodeBase64URL(envelope.substring(prefix.length))
        if (combined.size < nonceByteCount + tagByteCount) throw CryptoException(Failure.malformed)

        return cryptoOperation {
            val nonce = combined.copyOfRange(0, nonceByteCount)
            val cipher = gcm(Cipher.DECRYPT_MODE, key, nonce, aad)
            try {
                cipher.doFinal(combined, nonceByteCount, combined.size - nonceByteCount)
            } catch (error: BadPaddingException) {
                throw CryptoException(Failure.authenticationFailed, error)
            }
        }
    }

    private fun gcm(mode: Int, key: ByteArray, nonce: ByteArray, aad: ByteArray): Cipher =
        Cipher.getInstance("AES/GCM/NoPadding").apply {
            init(mode, SecretKeySpec(key, "AES"), GCMParameterSpec(tagByteCount * 8, nonce))
            updateAAD(aad)
        }

    // PBKDF2 is synchronous. Call it off the UI thread when handling a user action.
    fun deriveKEK(passphrase: String, salt: ByteArray, iterations: Int = defaultIterations): ByteArray {
        if (iterations !in supportedIterations) throw CryptoException(Failure.unsupportedVersion)
        return pbkdf2(passphrase, salt, iterations)
    }

    internal fun deriveKEKForTest(passphrase: String, salt: ByteArray, iterations: Int): ByteArray =
        pbkdf2(passphrase, salt, iterations)

    private fun pbkdf2(passphrase: String, salt: ByteArray, iterations: Int): ByteArray {
        if (salt.size != saltByteCount || iterations <= 0) throw CryptoException(Failure.malformed)
        val characters = grapheme.matcher(passphrase)
        repeat(10) {
            if (!characters.find()) throw CryptoException(Failure.malformed)
        }
        val password = Normalizer.normalize(passphrase, Normalizer.Form.NFC).toCharArray()
        val spec = try {
            PBEKeySpec(password, salt, iterations, keyByteCount * 8)
        } finally {
            password.fill('\u0000')
        }
        return try {
            cryptoOperation {
                SecretKeyFactory.getInstance("PBKDF2WithHmacSHA256").generateSecret(spec).encoded
            }
        } finally {
            spec.clearPassword()
        }
    }

    fun recoveryKEK(recoveryBytes: ByteArray): ByteArray {
        if (recoveryBytes.size != RecoveryKey.byteCount) throw CryptoException(Failure.malformed)
        return hkdf(recoveryBytes, byteArrayOf(), "bucktrail/e2e/v1/recovery".toByteArray(), keyByteCount)
    }

    internal fun hkdfForTest(ikm: ByteArray, salt: ByteArray, info: ByteArray, length: Int): ByteArray =
        hkdf(ikm, salt, info, length)

    private fun hkdf(ikm: ByteArray, salt: ByteArray, info: ByteArray, length: Int): ByteArray {
        if (length !in 0..(255 * keyByteCount)) throw CryptoException(Failure.malformed)
        return cryptoOperation {
            val mac = Mac.getInstance(hmacAlgorithm)
            val extractSalt = if (salt.isEmpty()) ByteArray(keyByteCount) else salt
            mac.init(SecretKeySpec(extractSalt, hmacAlgorithm))
            val prk = mac.doFinal(ikm)
            try {
                mac.init(SecretKeySpec(prk, hmacAlgorithm))
                val output = ByteArray(length)
                var previous = byteArrayOf()
                var written = 0
                var counter = 1
                while (written < length) {
                    mac.update(previous)
                    mac.update(info)
                    previous = mac.doFinal(byteArrayOf(counter.toByte()))
                    val count = minOf(previous.size, length - written)
                    previous.copyInto(output, destinationOffset = written, endIndex = count)
                    written += count
                    counter++
                }
                output
            } finally {
                prk.fill(0)
            }
        }
    }

    fun wrap(dek: ByteArray, key: ByteArray, aad: ByteArray): String {
        if (dek.size != keyByteCount) throw CryptoException(Failure.malformed)
        return seal(dek, key, aad)
    }

    fun unwrap(envelope: String, key: ByteArray, aad: ByteArray): ByteArray {
        val dek = open(envelope, key, aad)
        if (dek.size != keyByteCount) throw CryptoException(Failure.malformed)
        return dek
    }

    fun keyId(dek: ByteArray): String {
        if (dek.size != keyByteCount) throw CryptoException(Failure.malformed)
        return cryptoOperation {
            val mac = Mac.getInstance(hmacAlgorithm)
            mac.init(SecretKeySpec(dek, hmacAlgorithm))
            val digest = mac.doFinal("bucktrail/e2e/v1/key-id".toByteArray())
            buildString(16) {
                for (i in 0 until 8) {
                    val byte = digest[i].toInt() and 0xff
                    append(hexDigits[byte ushr 4])
                    append(hexDigits[byte and 15])
                }
            }
        }
    }

    fun encodeBase64URL(data: ByteArray): String =
        Base64.getUrlEncoder().withoutPadding().encodeToString(data)

    fun decodeBase64URL(value: String): ByteArray {
        val decoded = try {
            Base64.getUrlDecoder().decode(value)
        } catch (error: IllegalArgumentException) {
            throw CryptoException(Failure.malformed, error)
        }
        if (encodeBase64URL(decoded) != value) throw CryptoException(Failure.malformed)
        return decoded
    }

    internal fun randomBytes(size: Int): ByteArray =
        cryptoOperation { ByteArray(size).also(random::nextBytes) }

    private inline fun <T> cryptoOperation(block: () -> T): T = try {
        block()
    } catch (error: CryptoException) {
        throw error
    } catch (error: GeneralSecurityException) {
        throw CryptoException(Failure.operationFailed, error)
    } catch (error: ProviderException) {
        throw CryptoException(Failure.operationFailed, error)
    }
}
