package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SupabaseApi
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.account
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.file.Files
import java.util.UUID

class E2EDeadVaultCleanupRetryTest {
    @Test
    fun successfulPullRetriesFailedA4Cleanup() = verifyRetry(duringDisable = false)

    @Test
    fun d7RetriesFailedA4Cleanup() = verifyRetry(duringDisable = true)

    private fun verifyRetry(duringDisable: Boolean) = runBlocking {
        val base = FakeVaultSupabase()
        val deadDek = ByteArray(32) { 22 }
        val deadKey = VaultCrypto.keyId(deadDek)
        val obsolete = account(UUID.randomUUID().toString(), name = "Conto rimosso")
        val live = account(UUID.randomUUID().toString(), name = "Conto vivo")
        var failPull = false
        val obsoleteDeletes = mutableListOf<Pair<List<String>, String>>()
        val remote = object : SupabaseApi by base, VaultApi by base {
            override suspend fun selectVault(
                kind: VaultKind, userId: String, token: String, columns: String, keyId: String?,
            ): List<JsonObject> {
                if (failPull && columns == "*" && kind == VaultKind.Account) {
                    failPull = false
                    throw ApiException(ErrorKind.Network, 0, "offline")
                }
                return base.selectVault(kind, userId, token, columns, keyId)
            }

            override suspend fun deleteVault(
                kind: VaultKind, ids: List<String>, userId: String, token: String, keyId: String,
            ) {
                if (obsolete.id in ids) {
                    obsoleteDeletes += ids to keyId
                    if (obsoleteDeletes.size == 1) throw ApiException(ErrorKind.Network, 0, "offline")
                }
                base.deleteVault(kind, ids, userId, token, keyId)
            }
        }
        VaultSupabaseApi(remote, remote, deadDek, USER)
            .upsert(VaultKind.Account.table, listOf(SyncMapper.accountRow(obsolete, USER)), "token")
        val expected = Snapshot(accounts = listOf(live))
        val store = FakeLocalStore(expected)
        val state = MemorySyncState().apply { lastUserId = USER; syncedUserId = USER }
        val auth = AuthManager(remote, E2ETestSession(e2eTestSession(USER))).apply { bootstrap() }
        val scope = CoroutineScope(coroutineContext + SupervisorJob())
        val backup = Files.createTempDirectory("bucktrail-dead-vault-test").toFile()
        try {
            val controller = E2EController(remote, remote, MemoryE2ESecrets(), enabled = true, backupDirectory = backup)
            val engine = SyncEngine(remote, store, state, auth)
            val service = SyncService(scope, auth, engine, state, store, syncEnabled = { true },
                sleep = { awaitCancellation() }, e2e = controller)
            val recovery = RecoveryKey.format(RecoveryKey.generate())
            service.withE2EMigrator { it.enable(PHRASE, recovery, recovery.substringAfterLast('-').lowercase()) }
            assertEquals(listOf(listOf(obsolete.id) to deadKey), obsoleteDeletes)
            assertNotNull(base.records[obsolete.id])
            val liveRecord = base.records.getValue(live.id)
            assertEquals(base.keys[USER]?.text("key_id"), liveRecord.text("key_id"))

            if (duringDisable) {
                service.withE2EMigrator { it.disable { true } }
                assertNull(base.keys[USER])
                assertNull(base.records[live.id])
                assertEquals(listOf(live.id), base.selectAll(VaultKind.Account.table, USER, "token").map { it.text("id") })
            } else {
                failPull = true
                service.resolveDeleteConfirmation(delete = false)
                assertEquals(1, obsoleteDeletes.size)
                assertNotNull(base.records[obsolete.id])

                service.resolveDeleteConfirmation(delete = false)
                assertTrue(state.lastPull > 0)
                assertEquals(liveRecord, base.records[live.id])
            }
            assertEquals(List(2) { listOf(obsolete.id) to deadKey }, obsoleteDeletes)
            assertNull(base.records[obsolete.id])
            assertEquals(expected, store.snap)
        } finally {
            scope.cancel()
            backup.deleteRecursively()
        }
        Unit
    }
}
