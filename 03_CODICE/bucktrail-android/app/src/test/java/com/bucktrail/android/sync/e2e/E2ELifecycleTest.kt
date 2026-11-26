package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.NotSignedInException
import com.bucktrail.android.sync.SupabaseApi
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.USER
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.nio.file.Files
import kotlin.coroutines.CoroutineContext

class E2ELifecycleTest {
    @Test
    fun logoutErasesLocalProtectionAndNextLoginLocks() = runBlocking {
        Device(coroutineContext).use { device ->
            device.enable()
            device.recordMarker()
            device.service.signOutAndClear()
            device.expectErased()
            assertNull(device.auth.userId)
            assertEquals("active", device.remote.base.keys[USER]?.text("state"))

            device.session.stored = e2eTestSession(USER)
            device.auth.bootstrap()
            device.service.manualRefresh()
            assertEquals(E2EGate.LockReason.NeedsSecret, device.controller.status.value.lockReason)
        }
    }

    @Test
    fun userChangeErasesOldKeyBackupAndLocalMovementsBeforeTheGate() = runBlocking {
        Device(coroutineContext).use { device ->
            device.enable()
            device.recordMarker()
            device.auth.signIn("another-fixture", "fixture")
            device.service.manualRefresh()

            assertNull(device.secrets.load(USER))
            assertFalse(device.backup.exists())
            assertNull(device.secrets.marker())
            assertTrue(device.store.snap.isEmpty)
            assertTrue(device.remote.base.plain.rows("mt_transactions").none { it.text("user_id") == OTHER })
            assertEquals(OTHER, device.state.lastUserId)
        }
    }

    @Test
    fun rpcFailureLeavesAccountAndDataIntact() = runBlocking {
        Device(coroutineContext).use { device ->
            device.enable()
            device.recordMarker()
            device.remote.failRpc = true
            expectError<ApiException> { device.service.deleteAccountAndClear() }

            assertEquals(listOf("rpc"), device.remote.erasures)
            assertNotNull(device.secrets.load(USER))
            assertNotNull(device.secrets.marker())
            assertTrue(device.backup.exists())
            assertFalse(device.store.snap.isEmpty)
            assertEquals(USER, device.auth.userId)
        }
    }

    @Test
    fun deletionRetryCannotUseACurrentSessionForAnotherAccount() = runBlocking {
        val fake = FakeVaultSupabase()
        lateinit var auth: AuthManager
        var requests = 0
        var refreshes = 0
        val api = object : SupabaseApi by fake {
            override suspend fun signIn(email: String, password: String) = e2eTestSession(OTHER)
            override suspend fun refresh(refreshToken: String) = e2eTestSession(OTHER).also { refreshes++ }

            override suspend fun rpc(function: String, token: String) {
                requests++
                auth.signIn("another-fixture", "fixture")
                throw ApiException(ErrorKind.Unauthorized, 401, "fixture")
            }
        }
        auth = AuthManager(api, E2ETestSession(e2eTestSession(USER))).apply { bootstrap() }

        expectError<NotSignedInException> { auth.deleteAccountToken(USER) }
        assertEquals(OTHER, auth.userId)
        assertEquals(1, requests)
        assertEquals(0, refreshes)
    }

    @Test
    fun rpcSuccessCascadesVaultAndErasesLocalData() = runBlocking {
        Device(coroutineContext).use { device ->
            device.enable()
            device.recordMarker()
            device.service.deleteAccountAndClear()

            assertEquals(listOf("rpc", "logout"), device.remote.erasures)
            device.expectErased()
            assertNull(device.auth.userId)
            assertTrue(device.remote.base.records.isEmpty())
        }
    }

    @Test
    fun disabledFeatureUsesOnlyTheExistingRpcAndLogout() = runBlocking {
        Device(coroutineContext, enabled = false).use { device ->
            device.service.deleteAccountAndClear()
            assertEquals(listOf("rpc", "logout"), device.remote.erasures)
            assertTrue(device.store.snap.isEmpty)
        }
    }

    private class Device(context: CoroutineContext, enabled: Boolean = true) : AutoCloseable {
        val remote = ErasureRemote()
        val store = FakeLocalStore(migrationSnapshot())
        val state = MemorySyncState().apply { lastUserId = USER; syncedUserId = USER }
        val backup = Files.createTempDirectory("bucktrail-lifecycle-").toFile()
        val secrets: MigrationSecrets = object : MigrationSecrets, E2ESecrets by MemoryE2ESecrets() {
            override fun clearMarker(userId: String) {
                val key = load(userId)
                clear(userId)
                key?.let { save(userId, it.bytes) }
            }
        }
        val controller = E2EController(remote, remote, secrets, enabled, backup)
        private val scope = CoroutineScope(context + SupervisorJob())
        val session = E2ETestSession(e2eTestSession(USER))
        val auth = AuthManager(remote, session).apply { bootstrap() }
        private val engine = SyncEngine(remote, store, state, auth, onClear = controller::clearLocalData)
        val service = SyncService(scope, auth, engine, state, store, syncEnabled = { true },
            sleep = { awaitCancellation() }, e2e = controller.takeIf { enabled })

        suspend fun enable() {
            val recovery = RecoveryKey.format(RecoveryKey.generate())
            service.withE2EMigrator { it.enable(PHRASE, recovery, recovery.substringAfterLast('-')) }
        }

        fun recordMarker() {
            val row = checkNotNull(remote.base.keys[USER])
            secrets.saveMarker(E2EMigrationMarker(MigrationDirection.Enable, USER, checkNotNull(row.text("key_id")), 0))
        }

        fun expectErased() {
            assertNull(secrets.load(USER))
            assertNull(secrets.marker())
            assertFalse(backup.exists())
            assertTrue(store.snap.isEmpty)
            assertNull(state.lastUserId)
            assertTrue(state.dirty().isEmpty())
            assertEquals(E2EController.Status(), controller.status.value)
        }

        override fun close() {
            scope.cancel()
            backup.deleteRecursively()
        }
    }

    private class ErasureRemote(val base: FakeVaultSupabase = FakeVaultSupabase()) :
        SupabaseApi by base, VaultApi by base {
        val erasures = mutableListOf<String>()
        var failRpc = false

        override suspend fun signIn(email: String, password: String) = e2eTestSession(OTHER)

        override suspend fun rpc(function: String, token: String) {
            assertEquals("delete_own_account", function)
            assertTrue(token == "token")
            erasures += "rpc"
            if (failRpc) throw ApiException(ErrorKind.Server, 503, "fixture")
            base.records.entries.removeAll { it.value.text("user_id") == USER }
            base.keys.remove(USER)
        }

        override suspend fun signOut(accessToken: String) { erasures += "logout" }
    }

    private companion object {
        const val OTHER = "22222222-3333-4444-5555-666666666666"
    }
}
