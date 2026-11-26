package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.FixedAuth
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.PullOutcome
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.goal
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.util.UUID

class E2EDeadVaultKeyTest {
    @Test
    fun reactivationAfterInterruptedD7CleansDeadKeyAndRestoresSync() = runBlocking {
        val remote = MigrationRemote()
        val original = migrationSnapshot()
        val oldGoal = original.goals.single()
        MigrationDevice(coroutineContext, remote, original).use { first ->
            first.enable()
            val deadKey = checkNotNull(remote.key()?.text("key_id"))
            remote.failVaultDelete = VaultKind.Goal
            expectError<InterruptedMigration> { first.disable() }
            assertNull(remote.key())
            assertEquals(deadKey, remote.base.records.getValue(oldGoal.id).text("key_id"))
            assertEquals(E2EMigrationMarker.Phase.DisableCleanup, first.secrets.marker()?.phase)

            // The goal is deleted in plain mode while the old encrypted row still exists.
            remote.deleteIn(VaultKind.Goal.table, listOf(oldGoal.id), USER, "token")
            val expected = original.copy(goals = emptyList())
            MigrationDevice(coroutineContext, remote, expected).use { second ->
                second.enable()
                val liveKey = checkNotNull(remote.key()?.text("key_id"))
                assertNotEquals(deadKey, liveKey)
                assertFalse(remote.base.records.values.any { it.text("key_id") == deadKey })
                second.expectProtected(expected)

                first.service.manualRefresh()
                assertNull(first.secrets.marker())
                assertEquals(E2EGate.LockReason.NeedsSecret, first.controller.status.value.lockReason)
                first.service.withE2EMigrator { it.unlock(PHRASE) }
                first.service.manualRefresh()
                assertEquals(expected, first.store.snap)
                assertTrue(first.state.lastPull > 0)
            }
        }
    }

    @Test
    fun ordinaryPullIgnoresDeadRowsIfCleanupWasDeferred() = runBlocking {
        val remote = FakeVaultSupabase()
        val data = migrationSnapshot()
        val current = VaultSupabaseApi(remote, remote, ByteArray(32) { 11 }, USER)
        val obsolete = VaultSupabaseApi(remote, remote, ByteArray(32) { 22 }, USER)
        for ((kind, rows) in E2EVerifier.rows(data, USER)) {
            current.upsert(kind.table, rows, "token")
        }
        val oldGoal = goal(UUID.randomUUID().toString())
        obsolete.upsert(VaultKind.Goal.table, listOf(SyncMapper.goalRow(oldGoal, USER)), "token")

        val local = FakeLocalStore(Snapshot())
        val engine = SyncEngine(current, local, MemorySyncState(), FixedAuth())
        assertEquals(PullOutcome.Done, engine.pull())
        E2EVerifier.verify(E2EVerifier.rows(data, USER), E2EVerifier.rows(local.snap, USER), USER)
        assertTrue(remote.records.containsKey(oldGoal.id))
    }
}
