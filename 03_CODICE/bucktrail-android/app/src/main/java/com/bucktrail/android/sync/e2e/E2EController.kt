package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import android.util.Log
import com.bucktrail.android.sync.AuthManager
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
    )

    sealed interface Protection {
        data object Unavailable : Protection
        data object Off : Protection
        data object On : Protection
        data class Locked(val reason: E2EGate.LockReason) : Protection
        data class Activating(val completed: Int, val total: Int = 9) : Protection
        data class Disabling(val completed: Int, val total: Int = 8) : Protection
        data class Error(val reason: Reason) : Protection
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
        val protection = when (mode) {
            E2EGate.Mode.Plain -> if (resolution.serverSupported == true) Protection.Off else Protection.Unavailable
            is E2EGate.Mode.Vault -> Protection.On
            is E2EGate.Mode.Locked -> Protection.Locked(mode.reason)
            is E2EGate.Mode.Resume -> if (mode.direction == MigrationDirection.Enable) Protection.Activating(0) else Protection.Disabling(0)
        }
        _status.value = Status(userId, resolution.serverSupported, lock, resume, protection)

        val transport = when (mode) {
            E2EGate.Mode.Plain -> PlainWriteGuard(plain)
            is E2EGate.Mode.Vault -> VaultSupabaseApi(plain, vault, mode.dek, userId)
            else -> null
        }
        val pending = if (resume != null && marker != null) PendingMigration(marker, resolution.row) else null
        return Selection(transport, needsInitialSync, pending,
            completeSnapshot = migrationConfigured && (mode is E2EGate.Mode.Vault || needsInitialSync))
    }

    internal fun hasPendingMigration(userId: String): Boolean =
        migrationConfigured && secrets.marker()?.userId.equals(userId, ignoreCase = true)

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
    ) {
        val plainWriteRejected: Boolean get() = (transport as? PlainWriteGuard)?.rejected == true
    }

    internal suspend fun <T> migrate(
        auth: AuthManager, userId: String, engine: SyncEngine, store: LocalStore,
        initialSync: suspend (SyncEngine) -> Boolean, pull: suspend (SyncEngine) -> Boolean,
        completedCopy: () -> Unit,
        checkpoint: suspend (E2EMigrator.Step) -> Unit = {},
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
            log = { if (secrets is E2EKeyStore) Log.i("BucktrailE2E", it) },
            checkpoint = checkpoint,
        )
        try {
            val result = action(migrator)
            resolve(auth, userId)
            initialSyncCompleted()
            return result
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (error: Exception) {
            val reason = when (error) {
                is E2EMigrator.Failure -> Reason.valueOf(error.problem.name)
                is VaultCrypto.CryptoException -> Reason.Secret
                is ApiException -> Reason.Network
                else -> Reason.Verification
            }
            _status.value = _status.value.copy(protection = Protection.Error(reason))
            throw error
        }
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
