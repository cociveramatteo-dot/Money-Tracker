package com.bucktrail.android.sync.e2e

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.intOrNull

class E2EGate(private val vault: VaultApi, private val secrets: E2ESecrets, private val enabled: Boolean) {
    enum class LockReason { NeedsSecret, Transition, Unsupported }

    sealed interface Mode {
        data object Plain : Mode
        class Vault(val dek: ByteArray, val keyId: String) : Mode
        data class Locked(val reason: LockReason) : Mode
        data class Resume(val direction: MigrationDirection) : Mode
    }

    data class Resolution(
        val mode: Mode,
        val serverSupported: Boolean? = true,
        val needsPlainInitialSync: Boolean = false,
    )

    suspend fun resolve(userId: String, token: String, validateSession: () -> Unit = {}): Resolution {
        if (!enabled) return Resolution(Mode.Plain, serverSupported = null)
        val owner = requireNotNull(canonicalUuid(userId)).toString()
        val lookup = vault.getE2e(owner, token)
        validateSession()
        return when (lookup) {
            E2ERowLookup.Unavailable -> Resolution(Mode.Plain, serverSupported = false)
            E2ERowLookup.Absent -> {
                val hadKey = secrets.load(owner) != null
                if (hadKey) secrets.remove(owner)
                Resolution(Mode.Plain, needsPlainInitialSync = hadKey)
            }
            E2ERowLookup.Malformed -> Resolution(Mode.Locked(LockReason.Unsupported))
            is E2ERowLookup.Present -> resolveRow(lookup.row, owner)
        }
    }

    private fun resolveRow(row: JsonObject, owner: String): Resolution {
        val state = row.text("state")
        val keyId = row.text("key_id")
        if (canonicalUuid(row.text("user_id"))?.toString() != owner ||
            state !in setOf("active", "migrating", "disabling") ||
            !supported(row) || keyId == null || !KEY_ID.matches(keyId)
        ) return Resolution(Mode.Locked(LockReason.Unsupported))

        val local = secrets.load(owner)
        val matched = local?.takeIf { it.keyId == keyId }
        if (local != null && matched == null) secrets.remove(owner)
        if (state == "active") {
            return Resolution(matched?.let { Mode.Vault(it.bytes, it.keyId) } ?: Mode.Locked(LockReason.NeedsSecret))
        }

        val direction = if (state == "migrating") MigrationDirection.Enable else MigrationDirection.Disable
        val marker = secrets.marker()
        val canResume = matched != null && marker?.direction == direction && marker.keyId == keyId &&
            canonicalUuid(marker.userId)?.toString() == owner
        return Resolution(if (canResume) Mode.Resume(direction) else Mode.Locked(LockReason.Transition))
    }

    private fun supported(row: JsonObject): Boolean {
        fun number(key: String) = (row[key] as? JsonPrimitive)?.takeUnless { it.isString }?.intOrNull
        val iterations = number("kdf_iterations") ?: return false
        val salt = row.text("salt") ?: return false
        return number("version") == 1 && row.text("kdf") == "pbkdf2-sha256" &&
            iterations in VaultCrypto.supportedIterations && decodedSize(salt, VaultCrypto.saltByteCount) &&
            validWrap(row.text("wrapped_key_passphrase")) && validWrap(row.text("wrapped_key_recovery"))
    }

    private fun validWrap(value: String?): Boolean = value != null && value.length < 512 &&
        value.startsWith("bt1.") && decodedSize(value.substring(4), 12 + 32 + 16)

    private fun decodedSize(value: String, bytes: Int): Boolean =
        runCatching { VaultCrypto.decodeBase64URL(value).size == bytes }.getOrDefault(false)

    private companion object {
        val KEY_ID = Regex("[0-9a-f]{16}")
    }
}
