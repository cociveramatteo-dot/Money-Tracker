package com.bucktrail.android.sync.e2e

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.bucktrail.android.sync.e2e.VaultCrypto.CryptoException
import com.bucktrail.android.sync.e2e.VaultCrypto.Failure
import com.bucktrail.android.sync.e2e.VaultCrypto.WrapPurpose
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.int
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Assert.assertThrows
import org.junit.Test
import org.junit.runner.RunWith

@RunWith(AndroidJUnit4::class)
class E2EVectorsInstrumentedTest {
    private val fixture by lazy {
        val assets = InstrumentationRegistry.getInstrumentation().context.assets
        val json = assets.open("e2e-vectors-v1.json").bufferedReader().use { it.readText() }
        Json.parseToJsonElement(json).jsonObject
    }

    @Test fun androidProviderMatchesPbkdf2VectorsIncludingUnicode() {
        val vectors = fixture.getValue("pbkdf2").jsonArray
        assertEquals(3, vectors.size)
        for (value in vectors) {
            val vector = value.jsonObject
            val salt = VaultCrypto.decodeBase64URL(vector.text("salt"))
            val phrase = vector.text("passphrase")
            val iterations = vector.getValue("iterations").jsonPrimitive.int
            val key = if (iterations == 1_000) VaultCrypto.deriveKEKForTest(phrase, salt, iterations)
                else VaultCrypto.deriveKEK(phrase, salt, iterations)
            assertArrayEquals(vector.bytes("kek_hex"), key)
        }
    }

    @Test fun androidProviderMatchesHkdfAndCrockfordVectors() {
        val hkdf = fixture.getValue("hkdf_rfc5869").jsonObject
        assertArrayEquals(
            hkdf.bytes("okm_hex"),
            VaultCrypto.hkdfForTest(
                hkdf.bytes("ikm_hex"), hkdf.bytes("salt_hex"), hkdf.bytes("info_hex"),
                hkdf.getValue("length").jsonPrimitive.int
            )
        )

        val vectors = fixture.getValue("crockford").jsonArray
        assertEquals(4, vectors.size)
        for (value in vectors) {
            val vector = value.jsonObject
            assertEquals(vector.text("formatted"), RecoveryKey.format(vector.bytes("bytes_hex")))
            assertArrayEquals(vector.bytes("bytes_hex"), RecoveryKey.parse(vector.text("input")))
        }
    }

    @Test fun androidProviderMatchesAesEnvelopeAndWrapVectors() {
        val aes = fixture.getValue("aes_gcm_kat").jsonObject
        val knownAnswer = VaultCrypto.sealForTest(
            aes.bytes("plaintext_hex"), aes.bytes("key_hex"), aes.bytes("aad_hex"), aes.bytes("nonce_hex")
        )
        assertEquals(aes.text("envelope"), knownAnswer)
        assertArrayEquals(
            aes.bytes("plaintext_hex"), VaultCrypto.open(knownAnswer, aes.bytes("key_hex"), aes.bytes("aad_hex"))
        )

        val row = fixture.getValue("envelope").jsonObject
        val aad = row.text("aad").toByteArray()
        val plaintext = row.text("plaintext").toByteArray()
        assertEquals(
            row.text("sealed"), VaultCrypto.sealForTest(plaintext, row.bytes("key_hex"), aad, row.bytes("nonce_hex"))
        )
        assertArrayEquals(plaintext, VaultCrypto.open(row.text("sealed"), row.bytes("key_hex"), aad))

        val wrap = fixture.getValue("wrap").jsonObject
        val dek = wrap.bytes("dek_hex")
        val salt = VaultCrypto.decodeBase64URL(wrap.text("salt"))
        val phraseKek = VaultCrypto.deriveKEK(wrap.text("passphrase"), salt)
        val recoveryKek = VaultCrypto.recoveryKEK(RecoveryKey.parse(wrap.text("recovery_key")))
        assertArrayEquals(wrap.bytes("recovery_kek_hex"), recoveryKek)
        assertEquals(wrap.text("key_id"), VaultCrypto.keyId(dek))
        for ((purpose, kek) in listOf(WrapPurpose.passphrase to phraseKek, WrapPurpose.recovery to recoveryKek)) {
            val name = purpose.name
            val wrapAad = wrap.text("${name}_aad").toByteArray()
            val envelope = wrap.text("wrapped_key_$name")
            assertEquals(envelope, VaultCrypto.sealForTest(dek, kek, wrapAad, wrap.bytes("${name}_nonce_hex")))
            assertArrayEquals(dek, VaultCrypto.unwrap(envelope, kek, wrapAad))
        }
    }

    @Test fun androidProviderSealsAndOpensEmptyPayloadWithRandomNonce() {
        val key = fixture.getValue("envelope").jsonObject.bytes("key_hex")
        val empty = byteArrayOf()
        val wire = VaultCrypto.seal(empty, key, empty)
        assertArrayEquals(empty, VaultCrypto.open(wire, key, empty))
    }

    @Test fun androidProviderRejectsTamperingAndWrongCredentials() {
        val bad = fixture.getValue("negative").jsonObject
        val row = fixture.getValue("envelope").jsonObject
        val key = row.bytes("key_hex")
        val aad = row.text("aad").toByteArray()
        for ((name, failure) in listOf(
            "tag_altered" to Failure.authenticationFailed,
            "unsupported_version" to Failure.unsupportedVersion,
            "invalid_base64" to Failure.malformed
        )) {
            failsWith(failure) { VaultCrypto.open(bad.text(name), key, aad) }
        }
        for (name in listOf("wrong_id_aad", "wrong_kind_aad", "wrong_user_aad")) {
            failsWith(Failure.authenticationFailed) {
                VaultCrypto.open(row.text("sealed"), key, bad.text(name).toByteArray())
            }
        }
        val wrap = fixture.getValue("wrap").jsonObject
        val salt = VaultCrypto.decodeBase64URL(wrap.text("salt"))
        val wrongPhrase = VaultCrypto.deriveKEK(bad.text("wrong_passphrase"), salt)
        val wrongRecovery = VaultCrypto.recoveryKEK(RecoveryKey.parse(bad.text("wrong_recovery_key")))
        failsWith(Failure.authenticationFailed) {
            VaultCrypto.unwrap(wrap.text("wrapped_key_passphrase"), wrongPhrase, wrap.text("passphrase_aad").toByteArray())
        }
        failsWith(Failure.authenticationFailed) {
            VaultCrypto.unwrap(wrap.text("wrapped_key_recovery"), wrongRecovery, wrap.text("recovery_aad").toByteArray())
        }
    }

    private fun failsWith(failure: Failure, call: () -> Unit) {
        assertEquals(failure, assertThrows(CryptoException::class.java) { call() }.failure)
    }

    private fun JsonObject.text(name: String) = getValue(name).jsonPrimitive.content
    private fun JsonObject.bytes(name: String) = text(name).chunked(2).map { it.toInt(16).toByte() }.toByteArray()
}
