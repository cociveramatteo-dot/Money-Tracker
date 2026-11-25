package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.NotSignedInException
import com.bucktrail.android.sync.SupabaseApi
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.JsonObject

/** Stato del gate e scelta del trasporto. La ripresa della migrazione verrà collegata in S-50i. */
class E2EController(
    private val plain: SupabaseApi, private val vault: VaultApi, private val secrets: E2ESecrets,
    val enabled: Boolean,
) {
    data class Status(
        val userId: String? = null,
        val serverSupported: Boolean? = null,
        val lockReason: E2EGate.LockReason? = null,
        val resume: MigrationDirection? = null,
    )

    private val gate = E2EGate(vault, secrets, enabled)
    private val _status = MutableStateFlow(Status())
    val status = _status.asStateFlow()
    private var protected = false
    private var lastVaultKeyId: String? = null
    private var needsInitialSync = false

    internal suspend fun resolve(auth: AuthManager, userId: String): Selection {
        fun validate() {
            if (auth.userId != userId) throw NotSignedInException()
        }
        validate()
        _status.value.userId?.takeIf { it != userId }?.let(::clearLocalData)
        val resolution = auth.authed { token ->
            validate()
            gate.resolve(userId, token, ::validate)
        }
        validate()

        val mode = resolution.mode
        val previous = _status.value
        val lock = (mode as? E2EGate.Mode.Locked)?.reason
        val resume = (mode as? E2EGate.Mode.Resume)?.direction
        val restart = when (mode) {
            E2EGate.Mode.Plain -> resolution.needsPlainInitialSync || (resolution.serverSupported == true && protected)
            is E2EGate.Mode.Vault -> previous.userId == userId &&
                (previous.serverSupported == false || lastVaultKeyId != mode.keyId)
            else -> false
        }
        needsInitialSync = needsInitialSync || restart
        if (resolution.serverSupported == true) {
            protected = mode != E2EGate.Mode.Plain
            lastVaultKeyId = (mode as? E2EGate.Mode.Vault)?.keyId
        }
        _status.value = Status(userId, resolution.serverSupported, lock, resume)

        val transport = when (mode) {
            E2EGate.Mode.Plain -> PlainWriteGuard(plain)
            is E2EGate.Mode.Vault -> VaultSupabaseApi(plain, vault, mode.dek, userId)
            else -> null
        }
        return Selection(transport, needsInitialSync)
    }

    internal fun initialSyncCompleted() {
        needsInitialSync = false
    }

    fun clearLocalData(userId: String?) {
        if (!enabled) return
        val owner = userId ?: _status.value.userId
        if (owner != null) secrets.clear(owner)
        _status.value = Status()
        protected = false
        lastVaultKeyId = null
        needsInitialSync = false
    }

    internal data class Selection(val transport: SupabaseApi?, val needsInitialSync: Boolean) {
        val plainWriteRejected: Boolean get() = (transport as? PlainWriteGuard)?.rejected == true
    }

    private class PlainWriteGuard(private val plain: SupabaseApi) : SupabaseApi by plain {
        var rejected: Boolean = false
            private set

        override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) =
            checkWrite { plain.upsert(table, rows, token) }

        override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) =
            checkWrite { plain.deleteIn(table, ids, userId, token) }

        private inline fun checkWrite(block: () -> Unit) {
            try {
                block()
            } catch (e: ApiException) {
                if (e.code == "P0001" && e.message in listOf("bt_e2e_active", "bt_e2e_migrating")) {
                    rejected = true
                }
                throw e
            }
        }
    }
}
