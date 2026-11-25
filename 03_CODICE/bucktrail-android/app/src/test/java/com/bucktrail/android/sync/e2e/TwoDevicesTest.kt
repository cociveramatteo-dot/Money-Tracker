package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.T3
import com.bucktrail.android.sync.tx
import com.bucktrail.android.sync.SyncStatus
import com.bucktrail.android.sync.USER
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.*
import org.junit.Test

class TwoDevicesTest {
    @Test
    fun t11BothDevicesMoveBetweenModesThroughExistingFirstExchange() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            MigrationDevice(coroutineContext, a.remote, Snapshot(), synced = false).use { b ->
                val snapshot = a.store.snap
                a.enable()
                val active = checkNotNull(a.remote.base.keys.remove(USER))
                b.state.syncedUserId = USER
                b.store.snap = snapshot
                a.remote.base.transitionOnNextPlainWrite = active
                b.service.pushOnBackground()
                assertEquals(E2EGate.LockReason.NeedsSecret, b.controller.status.value.lockReason)
                assertEquals(SyncStatus.Idle, b.service.status.value)
                assertTrue(a.remote.base.readsAndWrites.contains("reject:mt_accounts"))
                // Unlock must pull before considering B's stale snapshot for upload.
                b.store.snap = snapshot.copy(accounts = snapshot.accounts.map { it.copy(name = "Copia obsoleta") })
                b.service.withE2EMigrator { it.unlock(PHRASE) }
                E2EVerifier.verify(E2EVerifier.rows(snapshot, USER), E2EVerifier.rows(b.store.snap, USER), USER)

                b.disable()
                b.expectPlain(snapshot)
                awaitFirstPlainPull(a)
                assertNull(a.secrets.load(USER))
                assertEquals(E2EController.Protection.Off, a.controller.status.value.protection)
            }
        }
    }

    @Test
    fun onlyOneConcurrentActivationCanInsertTheKeyRow() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            MigrationDevice(coroutineContext, a.remote, a.store.snap).use { b ->
                val entered = CompletableDeferred<Unit>()
                val release = CompletableDeferred<Unit>()
                val loser = async {
                    expectError<E2EMigrator.Failure> {
                        a.enable { if (it == E2EMigrator.Step.A2) { entered.complete(Unit); release.await() } }
                    }
                }
                entered.await()
                try {
                    b.enable()
                    val winner = a.remote.key()
                    release.complete(Unit)
                    assertEquals(E2EMigrator.Problem.ConcurrentActivation, loser.await().problem)
                    assertEquals(winner, a.remote.key())
                    assertNull(a.secrets.marker())
                    assertNull(a.secrets.load(USER))
                    b.expectProtected(b.store.snap)
                } finally {
                    release.complete(Unit)
                }
            }
        }
    }

    @Test
    fun phraseTakeoverClaimsGenerationAndStopsThePreviousDevice() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            MigrationDevice(coroutineContext, a.remote, Snapshot(), synced = false).use { b ->
                val entered = CompletableDeferred<Unit>()
                val release = CompletableDeferred<Unit>()
                val first = async {
                    expectError<E2EMigrator.Failure> {
                        a.enable { if (it == E2EMigrator.Step.A3) { entered.complete(Unit); release.await() } }
                    }
                }
                entered.await()
                try {
                    val before = a.remote.key()?.generation()
                    b.service.manualRefresh()
                    assertEquals(E2EGate.LockReason.Transition, b.controller.status.value.lockReason)
                    b.service.withE2EMigrator { it.unlock(PHRASE) }
                    assertNotEquals(before, a.remote.key()?.generation())
                    val deletes = a.remote.plainDeletes.size
                    release.complete(Unit)
                    assertEquals(E2EMigrator.Problem.StateChanged, first.await().problem)
                    assertEquals(deletes, a.remote.plainDeletes.size)
                    b.expectProtected(a.store.snap)
                } finally {
                    release.complete(Unit)
                }
            }
        }
    }

    @Test
    fun anotherDeviceCannotDisableWhileA7StillHasPlaintext() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            MigrationDevice(coroutineContext, a.remote, Snapshot(), synced = false).use { b ->
                a.enable { step ->
                    if (step == E2EMigrator.Step.A6) {
                        b.service.withE2EMigrator { it.unlock(PHRASE) }
                        val error = expectError<E2EMigrator.Failure> { b.disable() }
                        assertEquals(E2EMigrator.Problem.StateChanged, error.problem)
                        assertEquals("active", a.remote.key()?.text("state"))
                        assertTrue(a.remote.plainDeletes.isEmpty())
                    }
                }
                a.expectProtected(a.store.snap)
            }
        }
    }

    @Test
    fun stateChangeBetweenThePlainReadAndDeleteStopsCleanup() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            val snapshot = a.store.snap
            val error = expectError<E2EMigrator.Failure> {
                a.enable { step ->
                    if (step == E2EMigrator.Step.A6) {
                        a.remote.afterPlainRead = { table ->
                            if (table == VaultKind.Rule.table) {
                                a.remote.base.keys[USER] = JsonObject(checkNotNull(a.remote.key()) + ("state" to JsonPrimitive("disabling")))
                                a.remote.afterPlainRead = {}
                            }
                        }
                    }
                }
            }
            assertEquals(E2EMigrator.Problem.StateChanged, error.problem)
            assertTrue(a.remote.plainDeletes.isEmpty())
            E2EVerifier.verify(E2EVerifier.rows(snapshot, USER), a.plainRows(), USER)
            Unit
        }
    }

    @Test
    fun lateVaultWriteFromTheOtherDeviceStopsDisableBeforeD6() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            MigrationDevice(coroutineContext, a.remote, Snapshot(), synced = false).use { b ->
                a.enable()
                b.service.withE2EMigrator { it.unlock(PHRASE) }
                val otherKey = checkNotNull(b.secrets.load(USER))
                val inFlight = VaultSupabaseApi(a.remote, a.remote, otherKey.bytes, USER)
                expectError<E2EVerifier.Mismatch> {
                    a.disable { step ->
                        if (step == E2EMigrator.Step.D5) {
                            inFlight.upsert(VaultKind.Transaction.table, listOf(SyncMapper.transactionRow(tx(T3, null), USER)), "token")
                        }
                    }
                }
                assertEquals("disabling", a.remote.key()?.text("state"))
                assertTrue(T3 in a.remote.base.records)
                assertTrue(a.remote.base.readsAndWrites.none { it.startsWith("e2eDelete") })
            }
        }
    }

    @Test
    fun cleanupAfterD6KeepsAnUnverifiedLateVaultRow() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            a.enable()
            val ownerKey = checkNotNull(a.secrets.load(USER))
            val inFlight = VaultSupabaseApi(a.remote, a.remote, ownerKey.bytes, USER)
            expectError<E2EVerifier.Mismatch> {
                a.disable { step ->
                    if (step == E2EMigrator.Step.D6) {
                        inFlight.upsert(VaultKind.Transaction.table, listOf(SyncMapper.transactionRow(tx(T3, null), USER)), "token")
                    }
                }
            }
            assertNull(a.remote.key())
            assertTrue(T3 in a.remote.base.records)
            assertEquals(E2EMigrationMarker.Phase.DisableCleanup, a.secrets.marker()?.phase)
            a.reopen()
            a.service.manualRefresh()
            assertTrue(T3 in a.remote.base.records)
        }
    }

    @Test
    fun automaticSyncWaitsForMigrationInTheSameOpsMutex() = runBlocking {
        MigrationDevice(coroutineContext).use { a ->
            val entered = CompletableDeferred<Unit>()
            val release = CompletableDeferred<Unit>()
            val enabling = async { a.enable { if (it == E2EMigrator.Step.A3) { entered.complete(Unit); release.await() } } }
            entered.await()
            try {
                val count = a.remote.base.readsAndWrites.size
                val refresh = async { a.service.manualRefresh() }
                yield()
                assertFalse(refresh.isCompleted)
                assertEquals(count, a.remote.base.readsAndWrites.size)
                release.complete(Unit)
                enabling.await()
                refresh.await()
                a.expectProtected(a.store.snap)
            } finally {
                release.complete(Unit)
            }
        }
    }

    private suspend fun awaitFirstPlainPull(device: MigrationDevice) {
        val reads = device.remote.base.plain.count("select:mt_accounts")
        device.service.syncOnForeground()
        assertTrue(device.remote.base.plain.count("select:mt_accounts") >= reads + 2)
    }
}
