package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.FixedAuth
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.PullOutcome
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.USER
import kotlinx.coroutines.runBlocking
import org.junit.Assert.*
import org.junit.Test

class OldClientTest {
    @Test
    fun t10UnchangedEngineCannotWriteOrEraseAfterActivation() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val snapshot = f.store.snap
            f.enable()
            val store = FakeLocalStore(snapshot)
            val state = MemorySyncState().apply { lastUserId = USER; syncedUserId = USER }
            val legacy = SyncEngine(f.remote.base, store, state, FixedAuth())
            val vaultBefore = f.remote.base.records.toMap()
            val calls = f.remote.base.plain.calls.size
            assertFalse(legacy.push())
            assertEquals(PullOutcome.Skipped, legacy.pull())
            assertEquals(snapshot, store.snap)
            assertEquals(vaultBefore, f.remote.base.records)
            assertTrue(f.remote.base.plain.calls.drop(calls).none { it.startsWith("delete") || it.startsWith("upsert") })
            assertTrue(f.remote.base.readsAndWrites.contains("reject:mt_accounts"))
        }
    }
}
