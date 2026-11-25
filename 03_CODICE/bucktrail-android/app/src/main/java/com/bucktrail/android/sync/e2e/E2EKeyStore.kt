package com.bucktrail.android.sync.e2e

import android.content.Context
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.longOrNull
import java.security.KeyStore
import javax.crypto.AEADBadTagException
import javax.crypto.Cipher
import javax.crypto.KeyGenerator
import javax.crypto.SecretKey
import javax.crypto.spec.GCMParameterSpec

interface E2ESecrets {
    fun load(userId: String): LocalDek?
    fun save(userId: String, dek: ByteArray)
    fun remove(userId: String)
    fun marker(): E2EMigrationMarker?
    fun saveMarker(marker: E2EMigrationMarker)
    fun clear(userId: String)
}

class LocalDek(val bytes: ByteArray, val keyId: String)

enum class MigrationDirection(val wire: String) { Enable("enable"), Disable("disable") }

data class E2EMigrationMarker(
    val direction: MigrationDirection, val userId: String, val keyId: String, val startedAt: Long,
)

class E2EKeyStore(context: Context) : E2ESecrets {
    private val prefs = context.applicationContext.getSharedPreferences("bucktrail_e2e", Context.MODE_PRIVATE)

    @Synchronized
    override fun load(userId: String): LocalDek? {
        val owner = owner(userId)
        val encrypted = prefs.getString(slot(owner), null) ?: return null
        val key = existingKey() ?: return null
        val bytes = runCatching { VaultCrypto.decodeBase64URL(encrypted) }.getOrNull() ?: return null
        if (bytes.size <= IV_SIZE + TAG_SIZE) return null

        val cipher = Cipher.getInstance(TRANSFORM)
        cipher.init(Cipher.DECRYPT_MODE, key, GCMParameterSpec(TAG_SIZE * 8, bytes, 0, IV_SIZE))
        cipher.updateAAD(owner.encodeToByteArray())
        val plaintext = try {
            cipher.doFinal(bytes, IV_SIZE, bytes.size - IV_SIZE)
        } catch (_: AEADBadTagException) {
            return null
        }
        val stored = decodeObject(plaintext.decodeToString()) ?: return null
        if (canonicalUuid(stored.text("user_id"))?.toString() != owner) return null
        val encoded = stored.text("dek") ?: return null
        val dek = runCatching { VaultCrypto.decodeBase64URL(encoded) }.getOrNull() ?: return null
        if (dek.size != 32) return null
        val keyId = VaultCrypto.keyId(dek)
        return if (stored.text("key_id") == keyId) LocalDek(dek, keyId) else null
    }

    @Synchronized
    override fun save(userId: String, dek: ByteArray) {
        val owner = owner(userId)
        val value = buildJsonObject {
            put("user_id", JsonPrimitive(owner))
            put("key_id", JsonPrimitive(VaultCrypto.keyId(dek)))
            put("dek", JsonPrimitive(VaultCrypto.encodeBase64URL(dek)))
        }.toString().encodeToByteArray()
        val cipher = Cipher.getInstance(TRANSFORM)
        cipher.init(Cipher.ENCRYPT_MODE, existingKey() ?: generateKey())
        cipher.updateAAD(owner.encodeToByteArray())
        val ciphertext = cipher.iv + cipher.doFinal(value)
        check(prefs.edit().putString(slot(owner), VaultCrypto.encodeBase64URL(ciphertext)).commit())
    }

    @Synchronized
    override fun remove(userId: String) {
        check(prefs.edit().remove(slot(owner(userId))).commit())
    }

    @Synchronized
    override fun marker(): E2EMigrationMarker? {
        val row = prefs.getString(MIGRATION, null)?.let(::decodeObject) ?: return null
        val direction = MigrationDirection.entries.firstOrNull { it.wire == row.text("direction") } ?: return null
        val userId = canonicalUuid(row.text("user_id"))?.toString() ?: return null
        val keyId = row.text("key_id") ?: return null
        val startedAt = (row["started_at"] as? JsonPrimitive)?.longOrNull ?: return null
        return E2EMigrationMarker(direction, userId, keyId, startedAt)
    }

    @Synchronized
    override fun saveMarker(marker: E2EMigrationMarker) {
        val json = buildJsonObject {
            put("direction", JsonPrimitive(marker.direction.wire))
            put("user_id", JsonPrimitive(owner(marker.userId)))
            put("key_id", JsonPrimitive(marker.keyId))
            put("started_at", JsonPrimitive(marker.startedAt))
        }
        check(prefs.edit().putString(MIGRATION, json.toString()).commit())
    }

    @Synchronized
    override fun clear(userId: String) {
        val owner = owner(userId)
        val edit = prefs.edit().remove(slot(owner))
        if (marker()?.userId == owner) edit.remove(MIGRATION)
        check(edit.commit())
    }

    private fun existingKey(): SecretKey? =
        KeyStore.getInstance(PROVIDER).apply { load(null) }.getKey(ALIAS, null) as? SecretKey

    private fun generateKey(): SecretKey = KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_AES, PROVIDER).apply {
        init(
            KeyGenParameterSpec.Builder(ALIAS, KeyProperties.PURPOSE_ENCRYPT or KeyProperties.PURPOSE_DECRYPT)
                .setBlockModes(KeyProperties.BLOCK_MODE_GCM)
                .setEncryptionPaddings(KeyProperties.ENCRYPTION_PADDING_NONE)
                .setKeySize(256)
                .build(),
        )
    }.generateKey()

    private fun owner(userId: String): String = requireNotNull(canonicalUuid(userId)).toString()

    private fun slot(owner: String) = "dek.$owner"

    private fun decodeObject(text: String): JsonObject? =
        runCatching { Json.parseToJsonElement(text) as? JsonObject }.getOrNull()

    private companion object {
        const val PROVIDER = "AndroidKeyStore"
        const val ALIAS = "bucktrail_e2e_key"
        const val TRANSFORM = "AES/GCM/NoPadding"
        const val IV_SIZE = 12
        const val TAG_SIZE = 16
        const val MIGRATION = "migration"
    }
}
