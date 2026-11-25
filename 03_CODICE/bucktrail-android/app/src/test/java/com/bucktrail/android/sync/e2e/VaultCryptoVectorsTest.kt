package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.e2e.VaultCrypto.CryptoException
import com.bucktrail.android.sync.e2e.VaultCrypto.Failure
import com.bucktrail.android.sync.e2e.VaultCrypto.WrapPurpose
import java.io.File
import java.text.Normalizer
import java.util.UUID
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test

class VaultCryptoVectorsTest {
    private val fixtureFile = File(checkNotNull(System.getProperty("e2eVectors")))
    private val fixture = Json.parseToJsonElement(fixtureFile.readText()).jsonObject

    @Test fun aesGcmKnownAnswer() {
        val vector = fixture.group("aes_gcm_kat")
        val nonce = vector.bytes("nonce_hex")
        val plaintext = vector.bytes("plaintext_hex")
        val aad = vector.bytes("aad_hex")
        val key = vector.bytes("key_hex")
        val wire = VaultCrypto.sealForTest(plaintext, key, aad, nonce)
        assertEquals(vector.string("envelope"), wire)
        assertArrayEquals(
            nonce + vector.bytes("ciphertext_hex") + vector.bytes("tag_hex"),
            VaultCrypto.decodeBase64URL(wire.removePrefix("bt1."))
        )
        assertArrayEquals(plaintext, VaultCrypto.open(wire, key, aad))
    }

    @Test fun hkdfRfc5869() {
        val vector = fixture.group("hkdf_rfc5869")
        assertArrayEquals(
            vector.bytes("okm_hex"),
            VaultCrypto.hkdfForTest(
                vector.bytes("ikm_hex"), vector.bytes("salt_hex"), vector.bytes("info_hex"),
                vector.getValue("length").jsonPrimitive.int
            )
        )
    }

    @Test fun pbkdf2VectorsAndVerbatimWhitespace() {
        val vectors = fixture.getValue("pbkdf2").jsonArray.map { it.jsonObject }
        assertEquals(3, vectors.size)
        for (vector in vectors) {
            val phrase = vector.string("passphrase")
            val salt = VaultCrypto.decodeBase64URL(vector.string("salt"))
            val iterations = vector.getValue("iterations").jsonPrimitive.int
            val key = if (iterations == 1_000) VaultCrypto.deriveKEKForTest(phrase, salt, iterations)
                else VaultCrypto.deriveKEK(phrase, salt, iterations)
            assertArrayEquals(vector.bytes("kek_hex"), key)
        }

        val unicode = vectors.last()
        val phrase = unicode.string("passphrase")
        val nfc = Normalizer.normalize(phrase, Normalizer.Form.NFC)
        val salt = VaultCrypto.decodeBase64URL(unicode.string("salt"))
        assertTrue(phrase != nfc)
        val key = VaultCrypto.deriveKEK(nfc, salt)
        assertArrayEquals(unicode.bytes("kek_hex"), key)
        assertFalse(VaultCrypto.deriveKEK(" $nfc ", salt).contentEquals(key))
    }

    @Test fun crockfordVectors() {
        val vectors = fixture.getValue("crockford").jsonArray
        assertEquals(4, vectors.size)
        for (value in vectors) {
            val vector = value.jsonObject
            val bytes = vector.bytes("bytes_hex")
            assertEquals(vector.string("formatted"), RecoveryKey.format(bytes))
            assertArrayEquals(bytes, RecoveryKey.parse(vector.string("input")))
        }
        val generated = RecoveryKey.generate()
        assertEquals(20, generated.size)
        assertArrayEquals(generated, RecoveryKey.parse(RecoveryKey.format(generated)))
    }

    @Test fun envelopeAndWrappingVectors() {
        val row = fixture.group("envelope")
        val aad = VaultCrypto.rowAAD(
            row.string("kind").uppercase(), row.uuid("id"), row.uuid("user_id")
        )
        val rowKey = row.bytes("key_hex")
        val plaintext = row.utf8("plaintext")
        assertArrayEquals(row.utf8("aad"), aad)
        assertEquals(
            row.string("sealed"), VaultCrypto.sealForTest(plaintext, rowKey, aad, row.bytes("nonce_hex"))
        )
        assertArrayEquals(plaintext, VaultCrypto.open(row.string("sealed"), rowKey, aad))

        val wrap = fixture.group("wrap")
        val dek = wrap.bytes("dek_hex")
        val salt = VaultCrypto.decodeBase64URL(wrap.string("salt"))
        val phraseKek = VaultCrypto.deriveKEK(
            wrap.string("passphrase"), salt, wrap.getValue("iterations").jsonPrimitive.int
        )
        val recoveryKek = VaultCrypto.recoveryKEK(RecoveryKey.parse(wrap.string("recovery_key")))
        assertArrayEquals(wrap.bytes("recovery_kek_hex"), recoveryKek)
        for ((purpose, kek) in listOf(WrapPurpose.passphrase to phraseKek, WrapPurpose.recovery to recoveryKek)) {
            val aadForWrap = VaultCrypto.wrapAAD(purpose, wrap.uuid("user_id"))
            val envelope = wrap.string("wrapped_key_${purpose.name}")
            assertArrayEquals(wrap.utf8("${purpose.name}_aad"), aadForWrap)
            assertEquals(
                envelope, VaultCrypto.sealForTest(dek, kek, aadForWrap, wrap.bytes("${purpose.name}_nonce_hex"))
            )
            assertArrayEquals(dek, VaultCrypto.unwrap(envelope, kek, aadForWrap))
            assertArrayEquals(dek, VaultCrypto.unwrap(VaultCrypto.wrap(dek, kek, aadForWrap), kek, aadForWrap))
        }
        assertEquals(wrap.string("key_id"), VaultCrypto.keyId(dek))
    }

    @Test fun invalidEnvelopesAndCredentialsAreRejected() {
        val row = fixture.group("envelope")
        val bad = fixture.group("negative")
        val key = row.bytes("key_hex")
        val aad = row.utf8("aad")
        failsWith(Failure.authenticationFailed) { VaultCrypto.open(bad.string("tag_altered"), key, aad) }
        failsWith(Failure.unsupportedVersion) { VaultCrypto.open(bad.string("unsupported_version"), key, aad) }
        for (wire in listOf(
            bad.string("invalid_base64"), "", "junk", "bt1.", "bt1.A", "bt1.AA", "bt1.AB",
            "bt1.é", "bt.abc", "bt٢.abc", row.string("sealed") + "="
        )) {
            failsWith(Failure.malformed) { VaultCrypto.open(wire, key, aad) }
        }
        for (wrongAad in listOf("wrong_id_aad", "wrong_kind_aad", "wrong_user_aad")) {
            failsWith(Failure.authenticationFailed) {
                VaultCrypto.open(row.string("sealed"), key, bad.utf8(wrongAad))
            }
        }

        val wrap = fixture.group("wrap")
        val salt = VaultCrypto.decodeBase64URL(wrap.string("salt"))
        val wrongPhrase = VaultCrypto.deriveKEK(bad.string("wrong_passphrase"), salt)
        val wrongRecovery = VaultCrypto.recoveryKEK(RecoveryKey.parse(bad.string("wrong_recovery_key")))
        failsWith(Failure.authenticationFailed) {
            VaultCrypto.unwrap(wrap.string("wrapped_key_passphrase"), wrongPhrase, wrap.utf8("passphrase_aad"))
        }
        failsWith(Failure.authenticationFailed) {
            VaultCrypto.unwrap(wrap.string("wrapped_key_recovery"), wrongRecovery, wrap.utf8("recovery_aad"))
        }
        val recovery = wrap.string("recovery_key")
        for (input in listOf("", "U" + recovery.drop(1), recovery.dropLast(1), recovery + "0", "K" + recovery.drop(1))) {
            failsWith(Failure.malformed) { RecoveryKey.parse(input) }
        }
        for (iterations in listOf(Int.MIN_VALUE, 99_999, 10_000_001, Int.MAX_VALUE)) {
            failsWith(Failure.unsupportedVersion) { VaultCrypto.deriveKEK(wrap.string("passphrase"), salt, iterations) }
        }
        failsWith(Failure.malformed) { VaultCrypto.deriveKEK(wrap.string("passphrase"), ByteArray(15)) }
        failsWith(Failure.malformed) { VaultCrypto.deriveKEK("short", salt) }
        failsWith(Failure.malformed) { VaultCrypto.deriveKEK("👩‍🔬".repeat(9), salt) }
    }

    @Test fun tenThousandRandomNoncesDoNotRepeat() {
        val key = fixture.group("envelope").bytes("key_hex")
        val nonces = HashSet<List<Byte>>(10_000)
        repeat(10_000) {
            val wire = VaultCrypto.seal(byteArrayOf(), key, byteArrayOf())
            val nonce = VaultCrypto.decodeBase64URL(wire.removePrefix("bt1.")).take(12)
            assertEquals(12, nonce.size)
            assertTrue("Repeated GCM nonce", nonces.add(nonce))
        }
    }

    @Test fun productionDoesNotInjectNonces() {
        val source = fixtureFile.toPath()
            .resolveSibling("../../03_CODICE/bucktrail-android/app/src/main").normalize().toFile()
        val cryptoFile = source.resolve("java/com/bucktrail/android/sync/e2e/VaultCrypto.kt")
        assertTrue(cryptoFile.isFile)
        val testEntry = Regex("""\bsealForTest\b""")
        val nonceEntry = Regex("""\bsealWithNonce\b""")
        for (file in source.walkTopDown().filter { it.isFile && it.extension in setOf("kt", "java") }) {
            val text = file.readText()
            if (file == cryptoFile) {
                assertEquals(1, testEntry.findAll(text).count())
                // The only calls are from the random-nonce API and the test entry.
                assertEquals(3, nonceEntry.findAll(text).count())
                assertTrue(text.contains("sealWithNonce(plaintext, key, aad, randomBytes(nonceByteCount))"))
            } else {
                assertFalse(file.name, testEntry.containsMatchIn(text) || nonceEntry.containsMatchIn(text))
            }
        }
    }

    @Test fun envelopeSizeAndKeyBoundaries() {
        val key = fixture.group("envelope").bytes("key_hex")
        val aad = byteArrayOf()
        val empty = VaultCrypto.seal(byteArrayOf(), key, aad)
        assertArrayEquals(byteArrayOf(), VaultCrypto.open(empty, key, aad))
        val largest = ByteArray(49_120) { 0x41 }
        val wire = VaultCrypto.seal(largest, key, aad)
        assertEquals(65_535, wire.length)
        assertArrayEquals(largest, VaultCrypto.open(wire, key, aad))
        failsWith(Failure.malformed) { VaultCrypto.seal(largest + 0.toByte(), key, aad) }
        failsWith(Failure.malformed) { VaultCrypto.open(wire + "A", key, aad) }
        failsWith(Failure.malformed) { VaultCrypto.seal(byteArrayOf(), ByteArray(16), aad) }
        failsWith(Failure.malformed) { VaultCrypto.unwrap(empty, key, aad) }
        failsWith(Failure.malformed) { VaultCrypto.recoveryKEK(ByteArray(19)) }
    }

    private fun failsWith(failure: Failure, call: () -> Unit) {
        assertEquals(failure, assertThrows(CryptoException::class.java) { call() }.failure)
    }

    private fun JsonObject.group(name: String) = getValue(name).jsonObject
    private fun JsonObject.string(name: String) = getValue(name).jsonPrimitive.content
    private fun JsonObject.bytes(name: String) = string(name).chunked(2).map { it.toInt(16).toByte() }.toByteArray()
    private fun JsonObject.utf8(name: String) = string(name).toByteArray()
    private fun JsonObject.uuid(name: String) = UUID.fromString(string(name))
}
