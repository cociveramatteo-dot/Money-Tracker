package com.bucktrail.android.sync.e2e

import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.sync.A1
import com.bucktrail.android.sync.A2
import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.R1
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SupabaseApi
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.account
import com.bucktrail.android.sync.budget
import com.bucktrail.android.sync.goal
import com.bucktrail.android.sync.rule
import com.bucktrail.android.sync.tx
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.awaitCancellation
import kotlinx.coroutines.cancel
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral
import org.junit.Assert.*
import org.junit.Test
import java.nio.file.Files
import java.util.UUID
import kotlin.coroutines.CoroutineContext

class E2EMigratorTest {
    @Test
    fun t7ActivatesVerifiedCopyOfAllKindsWithBatchesAndBackup() = runBlocking {
        MigrationDevice(coroutineContext, original = migrationSnapshot(205)).use { f ->
            val expected = f.store.snap
            f.enable { step ->
                if (step == E2EMigrator.Step.A5) {
                    assertEquals("migrating", f.remote.key()?.text("state"))
                    assertTrue(f.remote.plainDeletes.isEmpty())
                }
            }
            f.expectProtected(expected)
            assertEquals(listOf(100, 100, 5), f.remote.plainDeletes.filter { it.table == VaultKind.Transaction.table }.map { it.count })
            assertTrue(f.remote.plainDeletes.all { it.state == "active" && it.count <= 100 })
            assertTrue("vaultUpsert:200" in f.remote.base.readsAndWrites)
            val saved = f.backup.listFiles()?.single()?.readText() ?: error("Missing backup")
            assertEquals(E2EVerifier.backupJson(E2EVerifier.rows(expected, USER)).toString(), saved)
            f.service.signOutAndClear()
            assertFalse(f.backup.exists())
            assertNull(f.secrets.load(USER))
        }
    }

    @Test
    fun t8EnableIsResumableAtA2ThroughA7() = runBlocking {
        for (step in E2EMigrator.Step.entries.subList(2, 8)) {
            MigrationDevice(coroutineContext).use { f ->
                val expected = f.store.snap
                expectError<InterruptedMigration> { f.enable { if (it == step) throw InterruptedMigration() } }
                assertNotNull("marker after $step", f.secrets.marker())
                if (step != E2EMigrator.Step.A7) E2EVerifier.verify(E2EVerifier.rows(expected, USER), f.plainRows(), USER)
                if (step.ordinal <= E2EMigrator.Step.A5.ordinal) assertTrue(f.remote.plainDeletes.isEmpty())
                f.reopen()
                f.service.manualRefresh()
                if (step == E2EMigrator.Step.A2) {
                    assertNull(f.secrets.marker())
                    assertNull(f.secrets.load(USER))
                    f.enable()
                }
                f.service.manualRefresh()
                f.expectProtected(expected)
            }
        }
    }

    @Test
    fun t8DisableIsResumableAtD3ThroughD7() = runBlocking {
        for (step in E2EMigrator.Step.entries.subList(12, 17)) {
            MigrationDevice(coroutineContext).use { f ->
                val expected = f.store.snap
                f.enable()
                expectError<InterruptedMigration> { f.disable { if (it == step) throw InterruptedMigration() } }
                assertNotNull("marker after $step", f.secrets.marker())
                f.reopen()
                f.service.manualRefresh()
                f.service.manualRefresh()
                f.expectPlain(expected)
            }
        }
    }

    @Test
    fun t8ResumesHalfwayThroughPlainCleanupAndVaultCleanup() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val expected = f.store.snap
            f.remote.failPlainDelete = VaultKind.Budget.table
            expectError<InterruptedMigration> { f.enable() }
            assertEquals("active", f.remote.key()?.text("state"))
            assertTrue(f.remote.base.plain.rows(VaultKind.Transaction.table).isEmpty())
            assertTrue(f.remote.base.plain.rows(VaultKind.Budget.table).isNotEmpty())
            f.reopen()
            f.service.manualRefresh()
            f.expectProtected(expected)

            f.remote.failVaultDelete = VaultKind.Budget
            expectError<InterruptedMigration> { f.disable() }
            assertNull(f.remote.key())
            assertTrue(f.remote.base.records.isNotEmpty())
            f.reopen()
            f.service.manualRefresh()
            f.service.manualRefresh()
            f.expectPlain(expected)
        }
    }

    @Test
    fun offlineDuringVerificationKeepsTheFrozenSourceUntilResume() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val snapshot = f.store.snap
            f.remote.failVaultRead = true
            val error = expectError<ApiException> { f.enable() }
            assertEquals(ErrorKind.Network, error.kind)
            assertEquals("migrating", f.remote.key()?.text("state"))
            assertTrue(f.remote.plainDeletes.isEmpty())
            E2EVerifier.verify(E2EVerifier.rows(snapshot, USER), f.plainRows(), USER)
            f.reopen()
            f.service.manualRefresh()
            f.expectProtected(snapshot)
        }
    }

    @Test
    fun t9BadAuthenticationTagRetriesTwiceAndLeavesClearCopyWhole() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val expected = f.store.snap
            f.remote.tamperVault = true
            val error = expectError<E2EMigrator.Failure> { f.enable() }
            assertEquals(E2EMigrator.Problem.Verification, error.problem)
            assertEquals(2, f.remote.corruptedReads)
            assertTrue(f.remote.plainDeletes.isEmpty())
            f.expectPlain(expected)
        }
    }

    @Test
    fun t9ExplicitCancelResumesRollbackWithoutClearingPlaintext() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val expected = f.store.snap
            expectError<InterruptedMigration> { f.enable { if (it == E2EMigrator.Step.A4) throw InterruptedMigration() } }
            f.remote.failVaultDelete = VaultKind.Account
            expectError<InterruptedMigration> { f.service.withE2EMigrator { it.cancelEnable() } }
            assertEquals(E2EMigrationMarker.Phase.RollingBack, f.secrets.marker()?.phase)
            f.reopen()
            f.service.manualRefresh()
            f.service.manualRefresh()
            assertTrue(f.remote.plainDeletes.isEmpty())
            f.expectPlain(expected)
        }
    }

    @Test
    fun failedDisableRestoresActiveBeforeClearingAndVerifiesOriginalVault() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val expected = f.store.snap
            f.enable()
            f.remote.shortPlainRead = true
            val e = expectError<E2EMigrator.Failure> { f.disable() }
            assertEquals(E2EMigrator.Problem.Verification, e.problem)
            assertEquals(2, f.remote.corruptedReads)
            assertTrue(f.remote.plainDeletes.all { it.state == "active" })
            f.expectProtected(expected)
        }
    }

    @Test
    fun rollbackPreservesLegacyWritesIncludingEditsToExistingIds() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            f.enable()
            val deletesBefore = f.remote.plainDeletes.size
            f.remote.shortPlainRead = true
            f.remote.duringStateChange = { state ->
                if (state == "active") {
                    val legacy = f.remote.base.plain.rows(VaultKind.Account.table).single()
                    f.remote.base.plain.put(VaultKind.Account.table, JsonObject(legacy + ("name" to JsonPrimitive("Modificato da legacy"))))
                }
            }
            expectError<E2EVerifier.Mismatch> { f.disable() }
            assertEquals("active", f.remote.key()?.text("state"))
            assertEquals(deletesBefore, f.remote.plainDeletes.size)
            assertEquals("Modificato da legacy", f.remote.base.plain.rows(VaultKind.Account.table).single().text("name"))
            assertEquals(E2EMigrationMarker.Phase.RollingBack, f.secrets.marker()?.phase)
        }
    }

    @Test
    fun a0RefusesUnalignedSourceAndNeverDeletesRemoteOnlyData() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            f.remote.base.plain.put(VaultKind.Account.table, SyncMapper.accountRow(account(A2), USER))
            expectError<E2EVerifier.Mismatch> { f.enable() }
            assertTrue(f.remote.plainDeletes.isEmpty())
            assertTrue(f.remote.base.plain.rows(VaultKind.Account.table).any { it.text("id").equals(A2, true) })
            assertNull(f.remote.key())
        }
    }

    @Test
    fun emptyArchiveAndGoalsWithoutAccountRoundTrip() = runBlocking {
        for (snapshot in listOf(Snapshot(), Snapshot(goals = listOf(goal(UUID.randomUUID().toString()))))) {
            MigrationDevice(coroutineContext, original = snapshot).use { f ->
                f.enable()
                f.expectProtected(snapshot)
                expectError<E2EMigrator.Failure> { f.service.withE2EMigrator { it.disable { false } } }
                f.expectProtected(snapshot)
                f.disable()
                f.expectPlain(snapshot)
            }
        }
    }

    @Test
    fun t13RecoveryRewrapRotationAndAuthenticatedRestart() = runBlocking {
        MigrationDevice(coroutineContext).use { f ->
            val expected = f.store.snap
            f.enable()
            val before = checkNotNull(f.remote.key())
            f.secrets.remove(USER)
            f.service.withE2EMigrator { it.recover(f.recovery, NEW_PHRASE) }
            val after = checkNotNull(f.remote.key())
            assertEquals(before.text("key_id"), after.text("key_id"))
            assertEquals(before.text("wrapped_key_recovery"), after.text("wrapped_key_recovery"))
            assertNotEquals(before.text("salt"), after.text("salt"))
            val rotated = f.service.withE2EMigrator { it.rotateRecovery { true } }
            f.secrets.remove(USER)
            expectError<VaultCrypto.CryptoException> { f.service.withE2EMigrator { it.unlock(PHRASE) } }
            expectError<VaultCrypto.CryptoException> { f.service.withE2EMigrator { it.recover(f.recovery, PHRASE) } }
            f.service.withE2EMigrator { it.unlock(NEW_PHRASE) }
            f.secrets.remove(USER)
            f.service.withE2EMigrator { it.recover(rotated, PHRASE) }
            f.secrets.remove(USER)
            f.service.withE2EMigrator { it.restartFromDevice { true } }
            f.expectPlain(expected)
        }
    }

    @OptIn(ExperimentalSerializationApi::class)
    @Test
    fun receiptMatchesSwiftVectorAndRejectsFieldIdAndRowAnomalies() {
        val owner = "abcdef00-0000-4000-8000-000000000001"
        val id = "abcdef00-0000-4000-8000-000000000002"
        val goal = GoalEntity(id, "A/B 日本", "🧾", 50_013, createdAt = 1_700_000_000_125)
        val expected = E2EVerifier.rows(Snapshot(goals = listOf(goal)), owner)
        val row = expected.getValue(VaultKind.Goal).single()
        val tolerance = JsonObject(row + mapOf(
            "target_amount" to JsonUnquotedLiteral("500.125"),
            "created_at" to JsonPrimitive("2023-11-14T22:13:20.126Z"),
        ) - "deadline")
        val receipt = E2EVerifier.verify(expected, expected + (VaultKind.Goal to listOf(tolerance)), owner)
        assertEquals("b513c49f5dc4941b8fc400e764ca49c1ea2b5b5c79878011a7d9a30eb9ed5fe6", receipt.combined)
        assertEquals(receipt.combined, receipt.byKind["goal"])

        for (bad in listOf(
            listOf(JsonObject(row + ("id" to JsonPrimitive(UUID.randomUUID().toString())))),
            listOf(JsonObject(row + ("name" to JsonPrimitive("Valore diverso")))),
            listOf(row, row),
            emptyList(),
        )) {
            assertThrows(E2EVerifier.Mismatch::class.java) {
                E2EVerifier.verify(expected, expected + (VaultKind.Goal to bad), owner)
            }
        }
    }
}

internal const val PHRASE = "sentiero tra le betulle"
internal const val NEW_PHRASE = "sentiero lungo il torrente"
internal class InterruptedMigration : Exception()

internal suspend inline fun <reified T : Exception> expectError(crossinline block: suspend () -> Unit): T {
    try {
        block()
    } catch (error: Exception) {
        if (error is T) return error
        throw error
    }
    throw AssertionError("Expected ${T::class.simpleName}")
}

internal fun migrationSnapshot(transactions: Int = 2): Snapshot = Snapshot(
    accounts = listOf(account(A1, name = "Conto 日本")),
    transactions = List(transactions) { tx(UUID.randomUUID().toString(), A1, name = "Movimento $it 🧾") },
    budgets = listOf(budget(UUID.randomUUID().toString(), A1)),
    goals = listOf(goal(UUID.randomUUID().toString())),
    rules = listOf(rule(R1, A1)),
)

internal class MigrationDevice(
    private val context: CoroutineContext,
    val remote: MigrationRemote = MigrationRemote(),
    original: Snapshot = migrationSnapshot(),
    synced: Boolean = true,
) : AutoCloseable {
    val store = FakeLocalStore(original)
    val state = MemorySyncState().apply { lastUserId = USER; syncedUserId = if (synced) USER else null }
    val secrets: MigrationSecrets = object : MigrationSecrets, E2ESecrets by MemoryE2ESecrets() {
        override fun clearMarker(userId: String) {
            val key = load(userId)
            clear(userId)
            if (key != null) save(userId, key.bytes)
        }
    }
    val backup = Files.createTempDirectory("bucktrail-e2e-test").toFile()
    val recovery = RecoveryKey.format(RecoveryKey.generate())
    val auth = AuthManager(remote, E2ETestSession(e2eTestSession(USER))).apply { bootstrap() }
    val engine = SyncEngine(remote, store, state, auth, onClear = { controller.clearLocalData(state.lastUserId) })
    private var scope = CoroutineScope(context + SupervisorJob())
    lateinit var controller: E2EController
        private set
    lateinit var service: SyncService
        private set

    init { reopen() }

    fun reopen() {
        scope.cancel()
        scope = CoroutineScope(context + SupervisorJob())
        controller = E2EController(remote, remote, secrets, enabled = true, backupDirectory = backup)
        service = SyncService(scope, auth, engine, state, store, syncEnabled = { true }, sleep = { awaitCancellation() }, e2e = controller)
    }

    suspend fun enable(checkpoint: suspend (E2EMigrator.Step) -> Unit = {}) {
        service.withE2EMigrator(checkpoint) { it.enable(PHRASE, recovery, recovery.substringAfterLast('-').lowercase()) }
    }

    suspend fun disable(checkpoint: suspend (E2EMigrator.Step) -> Unit = {}) {
        service.withE2EMigrator(checkpoint) { it.disable { true } }
    }

    suspend fun plainRows(): MigrationRows = VaultKind.entries.associateWith { remote.selectAll(it.table, USER, "token") }

    suspend fun expectProtected(snapshot: Snapshot) {
        assertEquals("active", remote.key()?.text("state"))
        assertNull(secrets.marker())
        assertTrue(plainRows().values.all { it.isEmpty() })
        val key = checkNotNull(secrets.load(USER))
        val encrypted = VaultSupabaseApi(remote, remote, key.bytes, USER)
        E2EVerifier.verify(E2EVerifier.rows(snapshot, USER), VaultKind.entries.associateWith { encrypted.selectAll(it.table, USER, "token") }, USER)
    }

    suspend fun expectPlain(snapshot: Snapshot) {
        assertNull(remote.key())
        assertNull(secrets.load(USER))
        assertNull(secrets.marker())
        assertTrue(remote.base.records.isEmpty())
        E2EVerifier.verify(E2EVerifier.rows(snapshot, USER), plainRows(), USER)
    }

    override fun close() {
        scope.cancel()
        backup.deleteRecursively()
    }
}

/** Decorates the existing trigger fake without changing its fixtures or behavior. */
internal class MigrationRemote(
    val base: FakeVaultSupabase = FakeVaultSupabase(),
) : SupabaseApi by base, VaultApi by base {
    data class PlainDelete(val table: String, val state: String?, val count: Int)
    val plainDeletes = mutableListOf<PlainDelete>()
    var tamperVault = false
    var shortPlainRead = false
    var corruptedReads = 0
    var failPlainDelete: String? = null
    var failVaultDelete: VaultKind? = null
    var failVaultRead = false
    var afterPlainRead: suspend (String) -> Unit = {}
    var duringStateChange: (String?) -> Unit = {}

    fun key() = base.keys[USER]

    override suspend fun selectAll(table: String, userId: String, token: String, columns: String): List<JsonObject> {
        val rows = base.selectAll(table, userId, token, columns)
        afterPlainRead(table)
        if (shortPlainRead && columns == "*" && table == VaultKind.Transaction.table && key()?.text("state") == "disabling") {
            corruptedReads++
            return emptyList()
        }
        return rows
    }

    override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) {
        if (table == failPlainDelete) {
            failPlainDelete = null
            throw InterruptedMigration()
        }
        plainDeletes.add(PlainDelete(table, key()?.text("state"), ids.size))
        base.deleteIn(table, ids, userId, token)
    }

    override suspend fun selectVault(kind: VaultKind, userId: String, token: String, columns: String, keyId: String?): List<JsonObject> {
        if (failVaultRead && columns == "*") {
            failVaultRead = false
            throw ApiException(ErrorKind.Network, 0, "offline")
        }
        val rows = base.selectVault(kind, userId, token, columns, keyId)
        if (!tamperVault || columns != "*" || kind != VaultKind.Transaction || rows.isEmpty()) return rows
        corruptedReads++
        val first = rows.first()
        val data = VaultCrypto.decodeBase64URL(checkNotNull(first.text("payload")).removePrefix("bt1."))
        data[data.lastIndex] = (data.last().toInt() xor 1).toByte()
        return listOf(JsonObject(first + ("payload" to JsonPrimitive("bt1." + VaultCrypto.encodeBase64URL(data))))) + rows.drop(1)
    }

    override suspend fun deleteVault(kind: VaultKind, ids: List<String>, userId: String, token: String, keyId: String) {
        if (kind == failVaultDelete) {
            failVaultDelete = null
            throw InterruptedMigration()
        }
        base.deleteVault(kind, ids, userId, token, keyId)
    }

    override suspend fun activateE2e(row: JsonObject, generation: String, counts: Map<String, Int>, token: String) {
        base.activateE2e(row, generation, counts, token)
        duringStateChange("active")
    }

    override suspend fun patchE2eIfCurrent(row: JsonObject, changes: JsonObject, token: String): Boolean {
        if (!key().sameGeneration(row)) return false
        base.patchE2e(USER, changes, token)
        duringStateChange(changes.text("state"))
        return true
    }

    override suspend fun deleteE2eIfCurrent(row: JsonObject, token: String): Boolean {
        if (!key().sameGeneration(row)) return false
        base.deleteE2e(USER, token)
        return true
    }
}
