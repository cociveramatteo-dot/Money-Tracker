package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.LocalStore
import com.bucktrail.android.sync.NotSignedInException
import com.bucktrail.android.sync.PullOutcome
import com.bucktrail.android.sync.PushResult
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SupabaseApi
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncFormatException
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.e2e.E2EMigrationMarker.Phase
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.currentCoroutineContext
import kotlinx.coroutines.ensureActive
import kotlinx.coroutines.withContext
import kotlinx.serialization.SerializationException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import java.io.File
import java.io.FileOutputStream
import java.security.SecureRandom
import java.time.Instant

internal typealias MigrationRows = Map<VaultKind, List<JsonObject>>

/** Operazioni invocate esclusivamente dentro la coda ops di SyncService. */
internal class E2EMigrator(
    private val auth: AuthManager,
    private val userId: String,
    private val engine: SyncEngine,
    private val store: LocalStore,
    private val plain: SupabaseApi,
    private val vault: VaultApi,
    private val secrets: MigrationSecrets,
    private val directory: File,
    private val validateRow: (JsonObject, String) -> Boolean,
    private val initialSync: suspend (SyncEngine) -> Boolean,
    private val pull: suspend (SyncEngine, Boolean) -> Boolean,
    private val progress: (Step) -> Unit,
    private val completedCopy: () -> Unit,
    private val log: (String) -> Unit,
    private val checkpoint: suspend (Step) -> Unit = {},
    private val clock: () -> Long = System::currentTimeMillis,
) {
    enum class Step { A0, A1, A2, A3, A4, A5, A6, A7, A8, D0, D1, D2, D3, D4, D5, D6, D7 }
    enum class Problem { StateChanged, Unavailable, Verification, ConcurrentActivation, InvalidPhrase, RecoveryNotConfirmed, Authentication }
    class Failure(val problem: Problem) : Exception(problem.name)

    private val owner = checkNotNull(canonicalUuid(userId))
    private val uid = owner.toString()

    suspend fun enable(phrase: String, recovery: String, confirmation: String) {
        validatePhrase(phrase)
        val recoveryBytes = RecoveryKey.parse(recovery)
        if (!RecoveryKey.format(recoveryBytes).substringAfterLast('-').equals(confirmation, ignoreCase = true)) {
            throw Failure(Problem.RecoveryNotConfirmed)
        }
        if (!engine.canPush(userId) || marker() != null || lookup() != E2ERowLookup.Absent) throw Failure(Problem.StateChanged)

        val aligned = synchronize(guardWrites(plain, null, canDelete = false), reconcile = false)
        step(Step.A0)
        backup(aligned)
        step(Step.A1)
        val dek = VaultCrypto.randomBytes(32)
        val keyId = VaultCrypto.keyId(dek)
        val generation = newGeneration()
        val (salt, wrapped) = phraseWrap(phrase, dek)
        val row = buildJsonObject {
            put("user_id", JsonPrimitive(uid)); put("state", JsonPrimitive("migrating"))
            put("version", JsonPrimitive(1)); put("kdf", JsonPrimitive("pbkdf2-sha256"))
            put("kdf_iterations", JsonPrimitive(VaultCrypto.defaultIterations)); put("salt", JsonPrimitive(salt))
            put("wrapped_key_passphrase", JsonPrimitive(wrapped))
            put("wrapped_key_recovery", JsonPrimitive(recoveryWrap(dek, recoveryBytes)))
            put("key_id", JsonPrimitive(keyId)); put("updated_at", JsonPrimitive(generation))
        }
        validateSession()
        secrets.save(uid, dek)
        val marker = begin(MigrationDirection.Enable, keyId, generation)
        step(Step.A2)
        try {
            request { vault.insertE2e(row, it) }
        } catch (e: ApiException) {
            if (e.status != 409 && e.code != "23505") throw e
            finish()
            throw Failure(Problem.ConcurrentActivation)
        }
        val current = row("migrating")
        if (!marker.owns(current)) throw Failure(Problem.StateChanged)
        step(Step.A3)
        activate(current, marker, dek)
    }

    suspend fun disable(authenticate: suspend () -> Boolean) {
        val active = row("active")
        if (marker() != null) throw Failure(Problem.StateChanged)
        val dek = requireKey(active)
        authenticate(authenticate)
        step(Step.D0)
        requirePlainEmpty(active)
        val encrypted = guardWrites(encrypted(dek), active)
        val aligned = synchronize(encrypted, reconcile = true)
        val copy = E2EVerifier.rows(aligned, uid)
        verify(copy, read(encrypted))
        step(Step.D1)
        backup(aligned)
        val generation = newGeneration(active)
        val marker = begin(MigrationDirection.Disable, keyId(active), generation)
        step(Step.D2)
        requirePlainEmpty(active)
        val disabling = patch(active, mapOf("state" to JsonPrimitive("disabling")), generation)
        step(Step.D3)
        deactivate(disabling, marker, dek)
    }

    suspend fun resume(marker: E2EMigrationMarker, current: JsonObject?) {
        validateSession()
        if (marker != marker()) throw Failure(Problem.StateChanged)
        if (current == null) {
            when {
                marker.direction == MigrationDirection.Enable -> finish()
                marker.phase == Phase.RollingBack -> throw Failure(Problem.StateChanged)
                marker.phase == Phase.Resetting -> completeReset(marker.keyId)
                marker.phase == Phase.DisableCleanup -> finishDisable(marker)
                else -> throw Failure(Problem.StateChanged)
            }
            return
        }
        if (!validateRow(current, uid) || !marker.owns(current)) throw Failure(Problem.StateChanged)
        val state = current.text("state")
        when {
            marker.phase == Phase.Resetting && state == "active" -> reset(current)
            marker.direction == MigrationDirection.Enable && state == "migrating" -> {
                if (marker.phase == Phase.RollingBack) rollbackEnable(current)
                else activate(current, marker, requireKey(current))
            }
            marker.direction == MigrationDirection.Enable && state == "active" && marker.phase == Phase.Verified ->
                finishEnable(current, requireKey(current))
            marker.direction == MigrationDirection.Disable && marker.phase == Phase.RollingBack &&
                state in setOf("active", "disabling") -> rollbackDisable(current, marker, requireKey(current))
            marker.direction == MigrationDirection.Disable && state == "disabling" ->
                deactivate(current, marker, requireKey(current))
            marker.direction == MigrationDirection.Disable && state == "active" && marker.phase == null ->
                secrets.clearMarker(uid)
            else -> throw Failure(Problem.StateChanged)
        }
    }

    /** A fresh form cannot finish a migration whose recovery key was shown on an earlier form. */
    internal suspend fun resumeForUi(direction: MigrationDirection, allowCommitted: Boolean = true): Boolean {
        val saved = marker() ?: return false
        if (saved.direction != direction) throw Failure(Problem.StateChanged)
        val current = (lookup() as? E2ERowLookup.Present)?.row
        if (current != null && !allowCommitted) throw Failure(Problem.StateChanged)
        resume(saved, current)
        if (saved.phase == Phase.RollingBack) throw Failure(Problem.Verification)
        if (current == null && direction == MigrationDirection.Enable) return false
        return !(direction == MigrationDirection.Disable && current?.text("state") == "active" && saved.phase == null)
    }

    suspend fun cancelEnable() {
        val current = row("migrating")
        val marker = marker()?.takeIf { it.direction == MigrationDirection.Enable && it.owns(current) }
            ?: throw Failure(Problem.StateChanged)
        requireKey(current)
        secrets.saveMarker(marker.copy(phase = Phase.RollingBack))
        rollbackEnable(current)
    }

    suspend fun unlock(phrase: String) {
        val row = row()
        val salt = VaultCrypto.decodeBase64URL(checkNotNull(row.text("salt")))
        val iterations = checkNotNull(row["kdf_iterations"] as? JsonPrimitive).content.toInt()
        val kek = withContext(Dispatchers.Default) { VaultCrypto.deriveKEK(phrase, salt, iterations) }
        val dek = try { unwrap(row, kek, VaultCrypto.WrapPurpose.passphrase) } finally { kek.fill(0) }
        unlock(row, dek)
    }

    suspend fun recover(recovery: String, newPhrase: String) {
        val row = row()
        val kek = VaultCrypto.recoveryKEK(RecoveryKey.parse(recovery))
        val dek = try { unwrap(row, kek, VaultCrypto.WrapPurpose.recovery) } finally { kek.fill(0) }
        val updated = updatePhrase(row, newPhrase, dek)
        unlock(updated, dek)
    }

    suspend fun changePhrase(newPhrase: String, authenticate: suspend () -> Boolean) {
        val row = row("active")
        val dek = requireKey(row)
        authenticate(authenticate)
        updatePhrase(row, newPhrase, dek)
    }

    suspend fun rotateRecovery(authenticate: suspend () -> Boolean): String {
        val row = row("active")
        val dek = requireKey(row)
        authenticate(authenticate)
        val bytes = RecoveryKey.generate()
        patch(row, mapOf("wrapped_key_recovery" to JsonPrimitive(recoveryWrap(dek, bytes))))
        return RecoveryKey.format(bytes)
    }

    suspend fun restartFromDevice(authenticate: suspend () -> Boolean) {
        val row = row("active")
        if (secrets.load(uid)?.keyId == keyId(row) || marker() != null) throw Failure(Problem.StateChanged)
        authenticate(authenticate)
        requirePlainEmpty(row)
        val generation = newGeneration(row)
        val marker = begin(MigrationDirection.Disable, keyId(row), generation, Phase.Resetting)
        val claimed = patch(row, emptyMap(), generation)
        if (!marker.owns(claimed)) throw Failure(Problem.StateChanged)
        reset(claimed)
    }

    private suspend fun unlock(row: JsonObject, dek: ByteArray) {
        requireCurrent(row)
        secrets.save(uid, dek)
        val localMarker = marker()?.takeIf { it.owns(row) }
        if (localMarker != null) {
            resume(localMarker, row)
        } else if (row.text("state") == "active") {
            val transport = guardWrites(encrypted(dek), row, canDelete = false)
            // Refuse a partial vault before the existing login path gets a chance to merge.
            val source = read(transport)
            verify(source, source)
            if (!initialSync(engine.using(transport, userId, completeSnapshot = true))) throw Failure(Problem.StateChanged)
        } else {
            val enabling = row.text("state") == "migrating"
            val source = read(if (enabling) plain else encrypted(dek))
            verify(source, source)
            val local = store.snapshot()
            if (local.isEmpty) {
                applyPull(if (enabling) plain else encrypted(dek), source)
                verify(source, E2EVerifier.rows(store.snapshot(), uid))
            } else {
                verify(source, E2EVerifier.rows(local, uid))
            }
            requireCurrent(row)
            backup(store.snapshot())
            val direction = if (enabling) MigrationDirection.Enable else MigrationDirection.Disable
            val generation = newGeneration(row)
            val marker = begin(direction, keyId(row), generation)
            // Claim the interrupted operation with a compare-and-set. A suspended
            // Android owner sees the new generation before its next write.
            val claimed = patch(row, emptyMap(), generation)
            resume(marker, claimed)
        }
    }

    private suspend fun activate(row: JsonObject, marker: E2EMigrationMarker, dek: ByteArray) {
        requireCurrent(row)
        val frozen = read(plain)
        val backedUp = loadBackup(marker)
        try {
            verify(backedUp, frozen)
        } catch (_: E2EVerifier.Mismatch) {
            abortEnable(row, marker)
        } catch (_: SyncFormatException) {
            abortEnable(row, marker)
        }
        val transport = guardWrites(encrypted(dek), row)
        val verified = copyAndVerify(transport, Step.A4, Step.A5, frozen) ?: abortEnable(row, marker)
        clearDeadVaultKeys(keyId(row), row)
        val generation = newGeneration(row)
        val cleanup = marker.copy(phase = Phase.Verified, activationGeneration = generation)
        validateSession()
        secrets.saveMarker(cleanup)
        request { token -> vault.activateE2e(row, generation, verified.mapKeys { it.key.wire }.mapValues { it.value.size }, token) }
        val active = row("active")
        if (!cleanup.owns(active)) throw Failure(Problem.StateChanged)
        step(Step.A6)
        finishEnable(active, dek)
    }

    private suspend fun abortEnable(row: JsonObject, marker: E2EMigrationMarker): Nothing {
        validateSession()
        secrets.saveMarker(marker.copy(phase = Phase.RollingBack))
        rollbackEnable(row)
        throw Failure(Problem.Verification)
    }

    private suspend fun deactivate(row: JsonObject, marker: E2EMigrationMarker, dek: ByteArray) {
        requireCurrent(row)
        val clear = guardWrites(plain, row, canDelete = false)
        val backup = loadBackup(marker)
        val vaultCopy = encrypted(dek)
        verify(backup, read(vaultCopy))
        val verified = copyAndVerify(clear, Step.D4, Step.D5)
        if (verified == null) {
            verify(backup, read(vaultCopy))
            validateSession()
            val rollback = marker.copy(phase = Phase.RollingBack)
            secrets.saveMarker(rollback)
            rollbackDisable(row, rollback, dek)
            throw Failure(Problem.Verification)
        }
        // A vault write that was already in flight on another device can land
        // after D1. Preserve it while the key metadata is still recoverable.
        verify(backup, read(vaultCopy))
        verify(verified, read(clear))
        validateSession()
        val cleanup = marker.copy(phase = Phase.DisableCleanup)
        secrets.saveMarker(cleanup)
        deleteRow(row)
        step(Step.D6)
        finishDisable(cleanup)
    }

    private suspend fun copyAndVerify(
        client: SupabaseApi, upload: Step, verification: Step, required: MigrationRows? = null,
    ): MigrationRows? {
        repeat(2) {
            val local = store.snapshot()
            val rows = E2EVerifier.rows(local, uid)
            try {
                if (required != null) requireSubset(required, rows)
                push(client, local, allTransactions = true, pruneOrphans = required != null, allowDestructive = required != null)
                step(upload)
                verify(rows, read(client))
            } catch (_: E2EVerifier.Mismatch) {
                return@repeat
            } catch (_: SyncFormatException) {
                return@repeat
            } catch (_: SerializationException) {
                return@repeat
            }
            step(verification)
            return rows
        }
        return null
    }

    private suspend fun finishEnable(row: JsonObject, dek: ByteArray) {
        val frozen = loadBackup(marker() ?: throw Failure(Problem.StateChanged))
        val encrypted = read(encrypted(dek))
        // A7 can resume well after A5. Check that every remaining plaintext ID
        // still has an authenticated, decodable encrypted copy.
        verify(encrypted, encrypted)
        clearPlain(row, encrypted, source = frozen)
        step(Step.A7)
        completedCopy()
        secrets.clearMarker(uid)
        step(Step.A8)
    }

    private suspend fun rollbackEnable(row: JsonObject) {
        request { token -> vault.rollbackActivation(row, token) }
        finish()
    }

    private suspend fun rollbackDisable(row: JsonObject, marker: E2EMigrationMarker, dek: ByteArray) {
        val safeCopy = loadBackup(marker)
        verify(safeCopy, read(encrypted(dek)))
        val active = if (row.text("state") == "active") row else changeState(row, "active")
        clearPlain(active, safeCopy, source = safeCopy)
        secrets.clearMarker(uid)
    }

    private suspend fun finishDisable(marker: E2EMigrationMarker) {
        val key = secrets.load(uid)?.takeIf { it.keyId == marker.keyId } ?: throw Failure(Problem.StateChanged)
        val remaining = read(encrypted(key.bytes))
        verify(loadBackup(marker), remaining, allowRemoteSubset = true)
        // Delete only IDs seen in the verified remainder, not any new entries
        // returned by later ID queries. A residual row pauses cleanup.
        clearVault(null, marker.keyId, remaining.mapValues { (kind, rows) -> E2EVerifier.ids(rows, kind) })
        try {
            clearDeadVaultKeys(marker.keyId, null)
        } catch (cancelled: CancellationException) {
            throw cancelled
        } catch (_: Exception) {
            validateSession()
            log("E2E: obsolete vault cleanup deferred")
        }
        step(Step.D7)
        completedCopy()
        finish()
    }

    private suspend fun reset(row: JsonObject) {
        requirePlainEmpty(row)
        clearVault(row, keyId(row))
        deleteRow(row)
        completeReset(keyId(row))
    }

    private suspend fun completeReset(keyId: String) {
        clearVault(null, keyId)
        val clear = guardWrites(plain, null, canDelete = false)
        if (!initialSync(engine.using(clear, userId, completeSnapshot = true))) throw Failure(Problem.StateChanged)
        finish()
    }

    private suspend fun clearPlain(active: JsonObject, copy: MigrationRows, source: MigrationRows) {
        val marker = marker() ?: throw Failure(Problem.StateChanged)
        val verified = marker.direction == MigrationDirection.Enable && marker.phase == Phase.Verified
        val rollback = marker.direction == MigrationDirection.Disable && marker.phase == Phase.RollingBack
        if (!(verified || rollback) || !marker.owns(active) || active.text("state") != "active") {
            throw Failure(Problem.StateChanged)
        }
        requireCurrent(active)
        val remaining = read(plain)
        requireSubset(remaining, copy)
        // An orphan or a concurrent legacy edit has no verified equivalent.
        // Keep the plaintext and the recovery marker for review.
        verify(source, remaining, allowRemoteSubset = true)
        val ordered = listOf(VaultKind.Transaction, VaultKind.Budget, VaultKind.Rule, VaultKind.Goal, VaultKind.Account)
        for (kind in ordered) {
            for (batch in E2EVerifier.ids(remaining.getValue(kind), kind).sorted().chunked(100)) {
                request { token ->
                    requireCurrent(active, token)
                    plain.deleteIn(kind.table, batch, uid, token)
                }
            }
        }
        requirePlainEmpty(active)
    }

    private suspend fun requirePlainEmpty(active: JsonObject) {
        for (kind in VaultKind.entries) {
            request { token ->
                requireCurrent(active, token)
                if (plain.selectAll(kind.table, uid, token, "id").isNotEmpty()) throw Failure(Problem.StateChanged)
            }
        }
        requireCurrent(active)
    }

    private suspend fun clearDeadVaultKeys(liveKey: String, expected: JsonObject?) =
        vault.clearDeadVaultKeys(uid, liveKey, ::request, { requireCurrent(expected, it) }) {
            validateSession()
            log("E2E: obsolete vault cleanup deferred")
        }

    private suspend fun clearVault(expected: JsonObject?, keyId: String, verified: Map<VaultKind, Set<String>> = emptyMap()) {
        for (kind in VaultKind.entries) {
            val ids = request { token ->
                requireCurrent(expected, token)
                E2EVerifier.ids(vault.selectVault(kind, uid, token, "id", keyId), kind)
            }
            if (expected == null && !verified[kind].orEmpty().containsAll(ids)) throw Failure(Problem.Verification)
            for (batch in ids.sorted().chunked(100)) {
                request { token ->
                    requireCurrent(expected, token)
                    vault.deleteVault(kind, batch, uid, token, keyId)
                }
            }
            request { token ->
                requireCurrent(expected, token)
                if (vault.selectVault(kind, uid, token, "id", keyId).isNotEmpty()) throw Failure(Problem.Verification)
            }
        }
    }

    private suspend fun synchronize(client: SupabaseApi, reconcile: Boolean): Snapshot {
        val initial = store.snapshot()
        push(client, initial, allTransactions = false, pruneOrphans = false, allowDestructive = false, reconcile = reconcile)
        val remote = read(client)
        verify(remote, remote)
        val local = E2EVerifier.rows(initial, uid)
        verify(local, E2EVerifier.rows(store.snapshot(), uid))
        if (reconcile) {
            val baseline = engine.migrationBaseline(userId) ?: throw Failure(Problem.Verification)
            for (kind in VaultKind.entries) {
                val expected = baseline.tables[kind.wire] ?: throw Failure(Problem.Verification)
                if (!E2EVerifier.ids(remote.getValue(kind), kind).containsAll(expected)) {
                    throw E2EVerifier.Mismatch(kind, "ids")
                }
            }
        } else {
            requireSubset(remote, local)
            requireSubset(local, remote)
        }
        applyPull(client, remote, reconcile)
        return store.snapshot()
    }

    private suspend fun applyPull(client: SupabaseApi, rows: MigrationRows, reconcile: Boolean = false) {
        val cached = object : SupabaseApi by client {
            override suspend fun selectAll(table: String, userId: String, token: String, columns: String): List<JsonObject> {
                validateSession()
                return rows.getValue(VaultKind.forTable(table))
            }
        }
        if (!pull(engine.using(cached, userId, completeSnapshot = true), reconcile)) throw Failure(Problem.Verification)
    }

    private suspend fun push(
        client: SupabaseApi, snapshot: Snapshot, allTransactions: Boolean, pruneOrphans: Boolean, allowDestructive: Boolean,
        reconcile: Boolean = false,
    ) {
        val result = withContext(Dispatchers.Default) {
            engine.using(client, userId, completeSnapshot = true, batchSize = 200)
                .pushMigration(snapshot, allTransactions, pruneOrphans, allowDestructive, reconcile)
        }
        if (result != PushResult.Done) throw Failure(Problem.Verification)
        validateSession()
    }

    private fun requireSubset(subset: MigrationRows, superset: MigrationRows) {
        for (kind in VaultKind.entries) {
            if (!E2EVerifier.ids(superset.getValue(kind), kind).containsAll(E2EVerifier.ids(subset.getValue(kind), kind))) {
                throw E2EVerifier.Mismatch(kind, "ids")
            }
        }
    }

    private fun guardWrites(client: SupabaseApi, expected: JsonObject?, canDelete: Boolean = true): SupabaseApi =
        object : SupabaseApi by client {
            override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) {
                requireCurrent(expected, token)
                client.upsert(table, rows, token)
            }
            override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) {
                if (!canDelete) return
                for (batch in ids.chunked(100)) {
                    requireCurrent(expected, token)
                    client.deleteIn(table, batch, userId, token)
                }
            }
        }

    private fun encrypted(dek: ByteArray) = VaultSupabaseApi(plain, vault, dek, uid)

    private suspend fun read(client: SupabaseApi): MigrationRows = withContext(Dispatchers.Default) {
        request { token ->
            VaultKind.entries.associateWith { kind ->
                validateSession()
                client.selectAll(kind.table, uid, token)
            }
        }
    }

    private suspend fun verify(local: MigrationRows, remote: MigrationRows, allowRemoteSubset: Boolean = false) =
        withContext(Dispatchers.Default) { E2EVerifier.verify(local, remote, uid, allowRemoteSubset, log) }

    private suspend fun row(state: String? = null): JsonObject {
        val row = (lookup() as? E2ERowLookup.Present)?.row ?: throw Failure(Problem.StateChanged)
        if (!validateRow(row, uid) || state != null && row.text("state") != state) throw Failure(Problem.StateChanged)
        return row
    }

    private suspend fun lookup(): E2ERowLookup = request { lookup(it) }

    private suspend fun lookup(token: String): E2ERowLookup {
        validateSession()
        val result = vault.getE2e(uid, token)
        validateSession()
        if (result == E2ERowLookup.Unavailable) throw Failure(Problem.Unavailable)
        return result
    }

    private suspend fun requireCurrent(expected: JsonObject?) = request { requireCurrent(expected, it) }

    private suspend fun requireCurrent(expected: JsonObject?, token: String) {
        val actual = lookup(token)
        if (expected == null && actual == E2ERowLookup.Absent) return
        if (expected != null && actual is E2ERowLookup.Present && validateRow(actual.row, uid) &&
            actual.row.sameGeneration(expected)) return
        throw Failure(Problem.StateChanged)
    }

    private suspend fun changeState(row: JsonObject, state: String): JsonObject =
        patch(row, mapOf("state" to JsonPrimitive(state)))

    private fun newGeneration(row: JsonObject? = null): String {
        val now = Instant.ofEpochMilli(clock())
        val last = row?.generation()?.let(Instant::parse)
        // Postgres retains microseconds. Entropy also distinguishes contenders
        // with identical clocks and the same prior generation.
        val offsetNanos = (SecureRandom().nextInt(999_999) + 1) * 1_000L
        return maxOf(now, last ?: now).plusNanos(offsetNanos).toString()
    }

    private suspend fun patch(
        row: JsonObject, fields: Map<String, JsonPrimitive>, generation: String? = row.generation(),
    ): JsonObject {
        val fieldsWithGeneration = if (generation == null) fields else fields + ("updated_at" to JsonPrimitive(generation))
        if (!request { vault.patchE2eIfCurrent(row, JsonObject(fieldsWithGeneration), it) }) throw Failure(Problem.StateChanged)
        val updated = row(fields["state"]?.content ?: row.text("state"))
        if (keyId(updated) != keyId(row) || updated.generation() != generation) throw Failure(Problem.StateChanged)
        return updated
    }

    private suspend fun deleteRow(row: JsonObject) {
        if (!request { vault.deleteE2eIfCurrent(row, it) }) throw Failure(Problem.StateChanged)
    }

    private fun keyId(row: JsonObject) = checkNotNull(row.text("key_id"))

    private fun requireKey(row: JsonObject): ByteArray =
        secrets.load(uid)?.takeIf { it.keyId == keyId(row) }?.bytes ?: throw Failure(Problem.StateChanged)

    private fun marker() = secrets.marker()?.takeIf { it.userId.equals(uid, ignoreCase = true) }

    private suspend fun begin(
        direction: MigrationDirection, keyId: String, generation: String, phase: Phase? = null,
    ): E2EMigrationMarker {
        validateSession()
        return E2EMigrationMarker(direction, uid, keyId, clock(), phase, generation).also(secrets::saveMarker)
    }

    private suspend fun finish() {
        validateSession()
        secrets.clear(uid)
    }

    private suspend fun backup(snapshot: Snapshot) {
        validateSession()
        val rows = E2EVerifier.rows(snapshot, uid)
        val encoded = E2EVerifier.backupJson(rows).toString()
        val file = directory.resolve("backup-${clock()}.json")
        withContext(Dispatchers.IO) {
            check(directory.mkdirs() || directory.isDirectory)
            val tmp = directory.resolve("writing")
            try {
                FileOutputStream(tmp).use {
                    it.write(encoded.encodeToByteArray())
                    it.fd.sync()
                }
                check(tmp.renameTo(file))
                directory.listFiles().orEmpty().filter { it.name.startsWith("backup-") && it != file }
                    .forEach { check(it.delete()) }
            } finally {
                if (tmp.exists()) tmp.delete()
            }
        }
    }

    private suspend fun loadBackup(marker: E2EMigrationMarker): MigrationRows = withContext(Dispatchers.IO) {
        val file = directory.listFiles().orEmpty().singleOrNull {
            it.name.matches(Regex("backup-[0-9]+\\.json"))
        } ?: throw Failure(Problem.Verification)
        val date = file.nameWithoutExtension.removePrefix("backup-").toLongOrNull()
        if (date == null || date > marker.startedAt) throw Failure(Problem.Verification)
        val json = Json.parseToJsonElement(file.readText()) as? JsonObject ?: throw Failure(Problem.Verification)
        E2EVerifier.backupRows(json)
    }

    private suspend fun authenticate(action: suspend () -> Boolean) {
        if (!action()) throw Failure(Problem.Authentication)
        validateSession()
    }

    private fun validatePhrase(phrase: String) {
        if (phrase.codePointCount(0, phrase.length) < 10) throw Failure(Problem.InvalidPhrase)
    }

    private suspend fun phraseWrap(phrase: String, dek: ByteArray): Pair<String, String> {
        validatePhrase(phrase)
        val salt = VaultCrypto.randomBytes(VaultCrypto.saltByteCount)
        val kek = withContext(Dispatchers.Default) { VaultCrypto.deriveKEK(phrase, salt) }
        return try {
            VaultCrypto.encodeBase64URL(salt) to
                VaultCrypto.wrap(dek, kek, VaultCrypto.wrapAAD(VaultCrypto.WrapPurpose.passphrase, owner))
        } finally {
            kek.fill(0)
        }
    }

    private suspend fun updatePhrase(row: JsonObject, phrase: String, dek: ByteArray): JsonObject {
        val (salt, wrapped) = phraseWrap(phrase, dek)
        return patch(row, mapOf(
            "salt" to JsonPrimitive(salt), "wrapped_key_passphrase" to JsonPrimitive(wrapped),
            "kdf_iterations" to JsonPrimitive(VaultCrypto.defaultIterations),
        ))
    }

    private fun recoveryWrap(dek: ByteArray, bytes: ByteArray): String {
        val kek = VaultCrypto.recoveryKEK(bytes)
        return try {
            VaultCrypto.wrap(dek, kek, VaultCrypto.wrapAAD(VaultCrypto.WrapPurpose.recovery, owner))
        } finally {
            kek.fill(0)
        }
    }

    private fun unwrap(row: JsonObject, kek: ByteArray, purpose: VaultCrypto.WrapPurpose): ByteArray {
        val envelope = checkNotNull(row.text("wrapped_key_${purpose.name}"))
        val dek = VaultCrypto.unwrap(envelope, kek, VaultCrypto.wrapAAD(purpose, owner))
        if (VaultCrypto.keyId(dek) != keyId(row)) throw Failure(Problem.StateChanged)
        return dek
    }

    private suspend fun step(step: Step) {
        validateSession()
        progress(step)
        checkpoint(step)
        validateSession()
    }

    private suspend fun validateSession() {
        currentCoroutineContext().ensureActive()
        if (auth.userId != userId) throw NotSignedInException()
    }

    private suspend fun <T> request(call: suspend (String) -> T): T = auth.authed { token ->
        validateSession()
        try {
            call(token).also { validateSession() }
        } catch (error: ApiException) {
            if (error.e2eStateChanged()) throw Failure(Problem.StateChanged)
            throw error
        }
    }
}
