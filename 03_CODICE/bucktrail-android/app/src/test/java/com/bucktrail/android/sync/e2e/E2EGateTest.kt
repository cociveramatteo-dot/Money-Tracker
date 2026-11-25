package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.A1
import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.SyncStatus
import com.bucktrail.android.sync.T1
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.account
import com.bucktrail.android.sync.tx
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import org.junit.Assert.*
import org.junit.Test
import java.util.UUID
import kotlin.coroutines.CoroutineContext

class E2EGateTest {
    private val remote = FakeVaultSupabase()
    private val secrets = MemoryE2ESecrets()
    private val gate = E2EGate(remote, secrets, enabled = true)
    private val key = ByteArray(32) { 11 }
    private val otherKey = ByteArray(32) { 21 }
    private val token = "token"

    @Test
    fun disabledAbsentAndUnavailableAreDistinct() = runBlocking {
        val disabled = E2EGate(remote, secrets, enabled = false).resolve(USER, token)
        assertEquals(E2EGate.Mode.Plain, disabled.mode)
        assertNull(disabled.serverSupported)
        assertTrue(remote.readsAndWrites.isEmpty())

        val empty = gate.resolve(USER, token)
        assertEquals(E2EGate.Mode.Plain, empty.mode)
        assertEquals(true, empty.serverSupported)
        assertFalse(empty.needsPlainInitialSync)

        secrets.save(USER, key)
        remote.available = false
        val unavailable = gate.resolve(USER, token)
        assertEquals(E2EGate.Mode.Plain, unavailable.mode)
        assertEquals(false, unavailable.serverSupported)
        assertArrayEquals(key, secrets.load(USER)?.bytes)

        remote.available = true
        val removed = gate.resolve(USER, token)
        assertEquals(E2EGate.Mode.Plain, removed.mode)
        assertTrue(removed.needsPlainInitialSync)
        assertNull(secrets.load(USER))
    }

    @Test
    fun activeNeedsMatchingKeyAndClearsOnlyStaleKey() = runBlocking {
        val anotherUser = UUID.randomUUID().toString()
        remote.keys[USER] = row()
        assertLocked(E2EGate.LockReason.NeedsSecret, gate.resolve(USER, token))
        secrets.save(anotherUser, key)
        secrets.save(USER, key)
        val match = gate.resolve(USER, token).mode as E2EGate.Mode.Vault
        assertArrayEquals(key, match.dek)

        remote.keys[USER] = row(dek = otherKey)
        assertLocked(E2EGate.LockReason.NeedsSecret, gate.resolve(USER, token))
        assertNull(secrets.load(USER))
        assertArrayEquals(key, secrets.load(anotherUser)?.bytes)
    }

    @Test
    fun resumptionRequiresMatchingDirectionOwnerAndKey() = runBlocking {
        for ((state, direction) in listOf("migrating" to MigrationDirection.Enable, "disabling" to MigrationDirection.Disable)) {
            val keyId = VaultCrypto.keyId(key)
            remote.keys[USER] = row(state = state)
            secrets.clear(USER)
            assertLocked(E2EGate.LockReason.Transition, gate.resolve(USER, token))
            val marker = E2EMigrationMarker(direction, USER, keyId, 5)
            secrets.saveMarker(marker)
            assertLocked(E2EGate.LockReason.Transition, gate.resolve(USER, token))
            secrets.save(USER, key)
            val otherDirection = MigrationDirection.entries.single { it != direction }
            for (mismatch in listOf(marker.copy(direction = otherDirection), marker.copy(userId = UUID.randomUUID().toString()), marker.copy(keyId = "0000000000000000"))) {
                secrets.saveMarker(mismatch)
                assertLocked(E2EGate.LockReason.Transition, gate.resolve(USER, token))
            }
            secrets.saveMarker(marker)
            assertEquals(E2EGate.Mode.Resume(direction), gate.resolve(USER, token).mode)
        }
    }

    @Test
    fun unsupportedParametersPauseWithoutWritingOrDiscardingKey() = runBlocking {
        val mismatches = listOf(
            "version" to JsonPrimitive(2), "kdf_iterations" to JsonPrimitive(99_999),
            "kdf_iterations" to JsonPrimitive(10_000_001), "kdf_iterations" to JsonPrimitive("600000"),
            "kdf" to JsonPrimitive("unknown"), "state" to JsonPrimitive("unknown"),
            "salt" to JsonPrimitive("invalid"), "wrapped_key_recovery" to JsonPrimitive("bt2.invalid"),
            "user_id" to JsonPrimitive(UUID.randomUUID().toString()),
        )
        service(coroutineContext).use { fixture ->
            secrets.save(USER, key)
            for (mismatch in mismatches) {
                remote.keys[USER] = JsonObject(row() + mismatch)
                fixture.service.pushOnBackground()
                assertEquals(E2EGate.LockReason.Unsupported, fixture.controller.status.value.lockReason)
                assertEquals(SyncStatus.Idle, fixture.service.status.value)
            }
            assertEquals(List(mismatches.size) { "e2eGet:$USER" }, remote.readsAndWrites)
            assertTrue(remote.plain.calls.isEmpty())
            assertArrayEquals(key, secrets.load(USER)?.bytes)
        }
    }

    @Test
    fun networkAndServerErrorsUseBackoffWithoutDataRequests() = runBlocking {
        for (error in listOf(ApiException(ErrorKind.Network, 0, "offline"), ApiException(ErrorKind.Server, 503, "unavailable"))) {
            remote.metadataError = error
            remote.readsAndWrites.clear()
            service(coroutineContext).use { fixture ->
                fixture.service.manualRefresh()
                yield()
                assertEquals(SyncStatus.WaitingForRetry(1), fixture.service.status.value)
                assertEquals(listOf(2_000L), fixture.sleeps)
                assertTrue(fixture.state.hasPendingChanges)
                assertEquals(listOf("e2eGet:$USER"), remote.readsAndWrites)
                assertTrue(remote.plain.calls.isEmpty())
            }
        }
    }

    @Test
    fun pauseHasNoBackoffAndUploadsDirtyEditAfterUnlock() = runBlocking {
        service(coroutineContext).use { fixture ->
            val acc = account(A1)
            val old = tx(T1, A1, name = "Before lock")
            val edit = old.copy(name = "Edited while locked")
            val vault = VaultSupabaseApi(remote, remote, key, USER)
            vault.upsert(VaultKind.Account.table, listOf(SyncMapper.accountRow(acc, USER)), token)
            vault.upsert(VaultKind.Transaction.table, listOf(SyncMapper.transactionRow(old, USER)), token)
            remote.readsAndWrites.clear()
            remote.keys[USER] = row()
            fixture.store.snap = Snapshot(accounts = listOf(acc), transactions = listOf(edit))
            fixture.state.markDirty(listOf(T1), 3)
            fixture.service.manualRefresh()
            yield()
            assertEquals(E2EGate.LockReason.NeedsSecret, fixture.controller.status.value.lockReason)
            assertEquals(SyncStatus.Idle, fixture.service.status.value)
            assertTrue(fixture.sleeps.isEmpty())
            assertTrue(fixture.state.hasPendingChanges)
            assertEquals(mapOf(T1 to 3L), fixture.state.dirty())
            assertEquals(listOf("e2eGet:$USER"), remote.readsAndWrites)

            secrets.save(USER, key)
            fixture.service.pushOnBackground()
            assertNull(fixture.controller.status.value.lockReason)
            assertFalse(fixture.state.hasPendingChanges)
            assertTrue(fixture.state.dirty().isEmpty())
            assertEquals(2, remote.readsAndWrites.count { it == "e2eGet:$USER" })
            val uploaded = vault.selectAll(VaultKind.Transaction.table, USER, token).single()
            assertEquals(edit, SyncMapper.transaction(uploaded))
            assertTrue(remote.plain.calls.isEmpty())
        }
    }

    @Test
    fun plainWriteRejectedByTriggerImmediatelyRechecksAndPauses() = runBlocking {
        service(coroutineContext).use { fixture ->
            remote.transitionOnNextPlainWrite = row(state = "migrating")
            fixture.service.pushOnBackground()
            yield()
            assertEquals(listOf("e2eGet:$USER", "reject:mt_accounts", "e2eGet:$USER"), remote.readsAndWrites)
            assertEquals(E2EGate.LockReason.Transition, fixture.controller.status.value.lockReason)
            assertEquals(SyncStatus.Idle, fixture.service.status.value)
            assertTrue(fixture.state.hasPendingChanges)
            assertTrue(fixture.sleeps.isEmpty())
            assertTrue(remote.plain.rows("mt_accounts").isEmpty())
        }
    }

    @Test
    fun deletionConsentFromPlainModeDoesNotApplyToNewVault() = runBlocking {
        service(coroutineContext).use { fixture ->
            fixture.store.snap = Snapshot()
            remote.plain.put(VaultKind.Account.table, SyncMapper.accountRow(account(A1), USER))
            fixture.service.pushOnBackground()
            assertNotNull(fixture.service.deleteConfirmation.value)

            val vault = VaultSupabaseApi(remote, remote, key, USER)
            vault.upsert(VaultKind.Account.table, listOf(SyncMapper.accountRow(account(A1), USER)), token)
            remote.keys[USER] = row()
            secrets.save(USER, key)
            fixture.service.resolveDeleteConfirmation(delete = true)

            assertNotNull(fixture.service.deleteConfirmation.value)
            assertTrue(A1 in remote.records)
            assertTrue(remote.readsAndWrites.none { it.startsWith("vaultDelete") })
        }
    }

    @Test
    fun disappearedRowRestartsInitialSyncEvenWithinPullCooldown() = runBlocking {
        service(coroutineContext).use { fixture ->
            secrets.save(USER, key)
            fixture.state.lastPull = 100
            assertFalse(fixture.service.shouldPull)
            fixture.service.syncOnForeground()
            assertNull(secrets.load(USER))
            assertEquals(listOf("e2eGet:$USER"), remote.readsAndWrites)
            // La sync su login esegue il pull anche senza cooldown scaduto.
            assertEquals(1_000L, fixture.state.lastPull)
            assertEquals(2, remote.plain.count("select:mt_accounts"))
        }
    }

    @Test
    fun interruptedTransitionExposesResumeWithoutSyncing() = runBlocking {
        service(coroutineContext).use { fixture ->
            remote.keys[USER] = row(state = "disabling")
            secrets.save(USER, key)
            secrets.saveMarker(E2EMigrationMarker(MigrationDirection.Disable, USER, VaultCrypto.keyId(key), 12))
            fixture.service.syncOnForeground()
            assertEquals(MigrationDirection.Disable, fixture.controller.status.value.resume)
            assertEquals(SyncStatus.Idle, fixture.service.status.value)
            assertTrue(fixture.state.hasPendingChanges)
            assertEquals(listOf("e2eGet:$USER"), remote.readsAndWrites)
            assertTrue(remote.plain.calls.isEmpty())
        }
    }

    @Test
    fun changeUserWhileNewVaultIsLockedClearsPreviousDataAndKey() = runBlocking {
        val previous = UUID.randomUUID().toString()
        secrets.save(previous, otherKey)
        secrets.saveMarker(E2EMigrationMarker(MigrationDirection.Enable, previous, VaultCrypto.keyId(otherKey), 4))
        remote.keys[USER] = row()
        service(coroutineContext, lastUser = previous).use { fixture ->
            fixture.service.start()
            yield()
            assertEquals(E2EGate.LockReason.NeedsSecret, fixture.controller.status.value.lockReason)
            assertNull(secrets.load(previous))
            assertNull(secrets.marker())
            assertTrue(fixture.store.snap.isEmpty)
            assertEquals(1, fixture.store.clearCount)
            assertEquals(listOf("e2eGet:$USER"), remote.readsAndWrites)
            assertTrue(remote.plain.calls.isEmpty())
        }
    }

    @Test
    fun explicitLogoutClearsOnlyItsKeyAndMarker() = runBlocking {
        val anotherUser = UUID.randomUUID().toString()
        secrets.save(anotherUser, otherKey)
        secrets.save(USER, key)
        secrets.saveMarker(E2EMigrationMarker(MigrationDirection.Enable, USER, VaultCrypto.keyId(key), 2))
        service(coroutineContext).use { fixture ->
            remote.keys[USER] = row()
            fixture.service.signOutAndClear()
            assertNull(secrets.load(USER))
            assertNull(secrets.marker())
            assertArrayEquals(otherKey, secrets.load(anotherUser)?.bytes)
            assertTrue(fixture.store.snap.isEmpty)
            assertNull(fixture.controller.status.value.userId)
        }
    }

    private fun assertLocked(reason: E2EGate.LockReason, actual: E2EGate.Resolution) {
        assertEquals(E2EGate.Mode.Locked(reason), actual.mode)
        assertEquals(true, actual.serverSupported)
    }

    private fun row(state: String = "active", dek: ByteArray = key): JsonObject = buildJsonObject {
        val user = UUID.fromString(USER)
        put("user_id", JsonPrimitive(USER))
        put("state", JsonPrimitive(state))
        put("version", JsonPrimitive(1))
        put("kdf", JsonPrimitive("pbkdf2-sha256"))
        put("kdf_iterations", JsonPrimitive(600_000))
        put("salt", JsonPrimitive(VaultCrypto.encodeBase64URL(ByteArray(16))))
        put("wrapped_key_passphrase", JsonPrimitive(VaultCrypto.wrap(dek, otherKey, VaultCrypto.wrapAAD(VaultCrypto.WrapPurpose.passphrase, user))))
        put("wrapped_key_recovery", JsonPrimitive(VaultCrypto.wrap(dek, otherKey, VaultCrypto.wrapAAD(VaultCrypto.WrapPurpose.recovery, user))))
        put("key_id", JsonPrimitive(VaultCrypto.keyId(dek)))
    }

    private fun service(context: CoroutineContext, lastUser: String = USER) = Fixture(context, lastUser)

    private inner class Fixture(context: CoroutineContext, lastUser: String) : AutoCloseable {
        val state = MemorySyncState().apply { lastUserId = lastUser; syncedUserId = lastUser }
        val store = FakeLocalStore(Snapshot(accounts = listOf(account(A1))))
        val controller = E2EController(remote, remote, secrets, enabled = true)
        val sleeps = mutableListOf<Long>()
        private val scope = CoroutineScope(context + SupervisorJob())
        private val auth = AuthManager(remote, E2ETestSession(e2eTestSession(USER))).also { it.bootstrap() }
        private val engine = SyncEngine(remote, store, state, auth, nowMillis = { 1_000 },
            onClear = { controller.clearLocalData(state.lastUserId) })
        val service = SyncService(scope, auth, engine, state, store, syncEnabled = { true }, nowMillis = { 1_000 },
            sleep = { sleeps += it; awaitCancellation() }, e2e = controller)

        override fun close() = scope.cancel()
    }
}
