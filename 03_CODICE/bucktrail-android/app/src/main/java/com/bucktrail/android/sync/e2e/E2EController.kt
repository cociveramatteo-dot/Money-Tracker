package com.bucktrail.android.sync.e2e

import com.bucktrail.android.BuildConfig
import com.bucktrail.android.sync.ApiException
import android.util.Log
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.LocalStore
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.NotSignedInException
import com.bucktrail.android.sync.SupabaseApi
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.serialization.json.JsonObject
import java.io.File

/** Coordina gate, trasporti e stato della protezione. SyncService serializza le operazioni. */
class E2EController(
    private val plain: SupabaseApi, private val vault: VaultApi, private val secrets: E2ESecrets,
    val enabled: Boolean,
    private val backupDirectory: File? = (secrets as? E2EKeyStore)?.backupDirectory,
) {
    data class Status(
        val userId: String? = null,
        val serverSupported: Boolean? = null,
        val lockReason: E2EGate.LockReason? = null,
        val resume: MigrationDirection? = null,
        val protection: Protection = Protection.Unavailable,
        val busy: Boolean = false,
        val issue: Reason? = null,
        val canCancelActivation: Boolean = false,
        val remoteEnabling: Boolean = false,
    )

    sealed interface Protection {
        data object Unavailable : Protection
        data object Off : Protection
        data object On : Protection
        data class Locked(val reason: E2EGate.LockReason) : Protection
        data class Activating(val completed: Int, val total: Int = 9) : Protection
        data class Disabling(val completed: Int, val total: Int = 8) : Protection
    }

    enum class Reason { StateChanged, Unavailable, Verification, ConcurrentActivation, InvalidPhrase, RecoveryNotConfirmed, Authentication, Secret, Network }

    private val migrationSecrets = secrets as? MigrationSecrets
    private val migrationConfigured get() = migrationSecrets != null && backupDirectory != null

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
            gate.resolve(userId, token, ::validate, resumeCleanup = migrationConfigured)
        }
        validate()

        val mode = resolution.mode
        val owner = checkNotNull(canonicalUuid(userId)).toString()
        val marker = if (migrationConfigured) secrets.marker()?.takeIf { it.userId.equals(owner, true) } else null
        if (marker != null && (
                resolution.row?.let { !marker.owns(it) } == true ||
                resolution.serverSupported == true && mode == E2EGate.Mode.Plain ||
                mode is E2EGate.Mode.Vault && marker.direction == MigrationDirection.Disable && marker.phase == null
            )) migrationSecrets?.clearMarker(owner)
        val previous = _status.value
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
        publishStatus(userId, resolution)

        suspend fun requireActiveKey(token: String, keyId: String) {
            validate()
            val current = (vault.getE2e(owner, token) as? E2ERowLookup.Present)?.row
            if (current?.text("state") != "active" || current.text("key_id") != keyId) {
                throw ApiException(ErrorKind.Client, 400, "bt_e2e_key_mismatch", "P0001")
            }
            validate()
        }

        val transport = when (mode) {
            E2EGate.Mode.Plain -> E2EWriteGuard(plain)
            is E2EGate.Mode.Vault -> E2EWriteGuard(VaultSupabaseApi(plain, vault, mode.dek, userId)) { token ->
                requireActiveKey(token, mode.keyId)
            }
            else -> null
        }
        val pending = if (resume != null && marker != null) PendingMigration(marker, resolution.row) else null
        return Selection(transport, needsInitialSync, pending,
            completeSnapshot = migrationConfigured && (mode is E2EGate.Mode.Vault || needsInitialSync),
            firstAccess = resolution.mode == E2EGate.Mode.Plain && resolution.needsPlainInitialSync,
            afterPull = {
                if (migrationConfigured && mode is E2EGate.Mode.Vault) {
                    fun deferred() {
                        validate()
                        if (BuildConfig.DEBUG && secrets is E2EKeyStore) {
                            Log.i("BucktrailE2E", "E2E: obsolete vault cleanup deferred")
                        }
                    }
                    try {
                        vault.clearDeadVaultKeys(owner, mode.keyId, auth::authed, { requireActiveKey(it, mode.keyId) }, ::deferred)
                    } catch (cancelled: CancellationException) {
                        throw cancelled
                    } catch (_: Exception) {
                        deferred()
                    }
                }
            })
    }

    /**
     * «Continua senza protezione» dopo `ProtectionRemoved`: cancella la DEK e prepara il primo accesso in chiaro.
     * `false` se lo stato non è più quello mostrato all'utente (nessuna cancellazione).
     */
    internal fun acceptProtectionRemoved(userId: String): Boolean {
        val current = _status.value
        if (!enabled || current.userId != userId || current.lockReason != E2EGate.LockReason.ProtectionRemoved) return false
        secrets.clear(userId)
        needsInitialSync = true
        return true
    }

    private fun publishStatus(userId: String, resolution: E2EGate.Resolution) {
        val mode = resolution.mode
        val lock = (mode as? E2EGate.Mode.Locked)?.reason
        val resume = (mode as? E2EGate.Mode.Resume)?.direction
        val protection = when (mode) {
            E2EGate.Mode.Plain -> if (resolution.serverSupported == true) Protection.Off else Protection.Unavailable
            is E2EGate.Mode.Vault -> Protection.On
            is E2EGate.Mode.Locked -> Protection.Locked(mode.reason)
            is E2EGate.Mode.Resume -> if (mode.direction == MigrationDirection.Enable) Protection.Activating(0) else Protection.Disabling(0)
        }
        val migrating = resolution.row?.text("state") == "migrating"
        _status.value = Status(userId, resolution.serverSupported, lock, resume, protection,
            canCancelActivation = migrating && resume == MigrationDirection.Enable,
            remoteEnabling = migrating && lock == E2EGate.LockReason.Transition,
        )
    }

    private suspend fun readStatusForUi(auth: AuthManager, userId: String) {
        fun validate() {
            if (auth.userId != userId) throw NotSignedInException()
        }
        val readOnly = object : E2ESecrets by secrets {
            override fun remove(userId: String) = Unit
        }
        val resolution = auth.authed { token ->
            validate()
            E2EGate(vault, readOnly, enabled).resolve(userId, token, ::validate, resumeCleanup = migrationConfigured)
        }
        validate()
        publishStatus(userId, resolution)
    }

    internal fun hasPendingMigration(userId: String): Boolean =
        migrationConfigured && secrets.marker()?.userId.equals(userId, ignoreCase = true)

    internal fun isRestartingFromDevice(userId: String): Boolean =
        secrets.marker()?.let { it.userId.equals(userId, ignoreCase = true) && it.phase == E2EMigrationMarker.Phase.Resetting } == true

    internal fun initialSyncCompleted() {
        needsInitialSync = false
    }

    fun clearLocalData(userId: String?) {
        if (!enabled) return
        val owner = userId ?: _status.value.userId
        if (owner != null) {
            secrets.clear(owner)
            backupDirectory?.takeIf(File::exists)?.let { check(it.deleteRecursively()) }
        }
        _status.value = Status()
        protected = false
        lastVaultKeyId = null
        needsInitialSync = false
    }

    internal data class PendingMigration(val marker: E2EMigrationMarker, val row: JsonObject?)

    internal data class Selection(
        val transport: SupabaseApi?, val needsInitialSync: Boolean, val pending: PendingMigration?,
        val completeSnapshot: Boolean,
        val firstAccess: Boolean = false,
        val afterPull: suspend () -> Unit = {},
    ) {
        val writeRejected: Boolean get() = (transport as? E2EWriteGuard)?.rejected == true
        suspend fun validatePull(token: String) {
            if (completeSnapshot) (transport as? E2EWriteGuard)?.validatePull(token)
        }
    }

    internal suspend fun <T> migrate(
        auth: AuthManager, userId: String, engine: SyncEngine, store: LocalStore,
        initialSync: suspend (SyncEngine) -> Boolean, pull: suspend (SyncEngine, Boolean) -> Boolean,
        completedCopy: () -> Unit,
        checkpoint: suspend (E2EMigrator.Step) -> Unit = {},
        refreshOnSuccess: Boolean = true,
        readOnFailureForUi: Boolean = false,
        action: suspend (E2EMigrator) -> T,
    ): T {
        val directory = backupDirectory ?: throw E2EMigrator.Failure(E2EMigrator.Problem.Unavailable)
        val secured = migrationSecrets ?: throw E2EMigrator.Failure(E2EMigrator.Problem.Unavailable)
        val migrator = E2EMigrator(
            auth, userId, engine, store, plain, vault, secured, directory, gate::isSupportedRow, initialSync, pull,
            progress = { step ->
                val position = step.ordinal + 1
                val view = if (position <= 9) Protection.Activating(position) else Protection.Disabling(position - 9)
                _status.value = _status.value.copy(protection = view)
            },
            completedCopy = completedCopy,
            log = { if (BuildConfig.DEBUG && secrets is E2EKeyStore) Log.i("BucktrailE2E", it) },
            checkpoint = checkpoint,
        )
        val previous = _status.value
        _status.value = previous.copy(busy = true, issue = null)
        try {
            val result = action(migrator)
            if (auth.userId != userId) throw NotSignedInException()
            if (refreshOnSuccess) {
                resolve(auth, userId)
                initialSyncCompleted()
            } else {
                _status.value = previous.copy(issue = null)
            }
            return result
        } catch (cancelled: CancellationException) {
            if (auth.userId == userId) _status.value = previous
            throw cancelled
        } catch (error: Exception) {
            if (auth.userId == userId) {
                val reason = issueFor(error)
                _status.value = previous
                if (readOnFailureForUi && reason != Reason.Authentication && reason != Reason.Secret) {
                    try { readStatusForUi(auth, userId) }
                    catch (cancelled: CancellationException) { throw cancelled }
                    catch (_: Exception) { /* Keep the last known gate state when offline. */ }
                }
                if (auth.userId == userId) _status.value = _status.value.copy(issue = reason, busy = false)
            }
            throw error
        }
    }

    internal companion object {
        fun issueFor(error: Exception): Reason = when (error) {
            is E2EMigrator.Failure -> Reason.valueOf(error.problem.name)
            is VaultCrypto.CryptoException -> Reason.Secret
            is ApiException -> if (error.kind in setOf(ErrorKind.Network, ErrorKind.Server)) Reason.Network else Reason.Verification
            is java.io.IOException -> Reason.Network
            else -> Reason.Verification
        }
    }

    private class E2EWriteGuard(
        private val plain: SupabaseApi,
        private val validateKey: (suspend (String) -> Unit)? = null,
    ) : SupabaseApi by plain {
        var rejected: Boolean = false
            private set

        override suspend fun selectAll(table: String, userId: String, token: String, columns: String) =
            checkRequest { plain.selectAll(table, userId, token, columns) }

        override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) =
            checkRequest { plain.upsert(table, rows, token) }

        override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) =
            checkRequest { plain.deleteIn(table, ids, userId, token) }

        override suspend fun repairAccountLinks(links: Map<String, String>, token: String) =
            checkRequest { plain.repairAccountLinks(links, token) }

        suspend fun validatePull(token: String) = checkRequest { validateKey?.invoke(token) }

        private inline fun <T> checkRequest(block: () -> T): T {
            try {
                return block()
            } catch (e: ApiException) {
                if (e.e2eStateChanged() ||
                    (e.code == "P0001" && e.message in listOf("bt_e2e_active", "bt_e2e_migrating"))) {
                    rejected = true
                }
                throw e
            }
        }
    }
}
