package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.A1
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.account
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.coroutines.yield
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test

class E2EFlagOffTest {
    @Test
    fun loginAndBothPushAndPullUseOnlyOriginalPlainCalls() = runBlocking {
        val remote = FakeVaultSupabase()
        val auth = AuthManager(remote, E2ETestSession(e2eTestSession(USER))).also { it.bootstrap() }
        val state = MemorySyncState()
        val store = FakeLocalStore(Snapshot(accounts = listOf(account(A1))))
        val scope = CoroutineScope(coroutineContext + SupervisorJob())
        try {
            val engine = SyncEngine(remote, store, state, auth)
            val disabled = E2EController(remote, remote, MemoryE2ESecrets(), enabled = false)
            val service = SyncService(scope, auth, engine, state, store, syncEnabled = { true }, e2e = disabled)
            service.start()
            yield()
            assertEquals(USER, state.syncedUserId)
            val selects = VaultKind.entries.map { "select:${it.table}" }
            val push = selects + "upsert:mt_accounts:1"
            assertEquals(listOf("select:mt_accounts") + push, remote.plain.calls)
            remote.plain.calls.clear()
            service.manualRefresh()
            assertEquals(push + selects, remote.plain.calls)
            assertTrue(remote.readsAndWrites.isEmpty())
        } finally {
            scope.cancel()
        }
    }
}
