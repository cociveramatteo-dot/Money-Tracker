package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.A1
import com.bucktrail.android.sync.FakeLocalStore
import com.bucktrail.android.sync.FixedAuth
import com.bucktrail.android.sync.MemorySyncState
import com.bucktrail.android.sync.PullOutcome
import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.T1
import com.bucktrail.android.sync.T2
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.account
import com.bucktrail.android.sync.budget
import com.bucktrail.android.sync.goal
import com.bucktrail.android.sync.rule
import com.bucktrail.android.sync.tx
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.*
import org.junit.Test
import java.util.UUID

class VaultSupabaseApiTest {
    private val server = FakeVaultSupabase()
    private val dek = ByteArray(32) { 42 }
    private val remote = VaultSupabaseApi(server, server, dek, USER.uppercase())
    private val token = "token"

    @Test
    fun sendsOnlyAuthenticatedCiphertextAndRoundTripsMapperRows() = runBlocking {
        val rows = VaultKind.entries.zip(
            listOf(
                SyncMapper.accountRow(account(A1, "名義 privata"), USER),
                SyncMapper.transactionRow(tx(UUID.randomUUID().toString(), A1, -1250, "Caffè 日本 🔑"), USER),
                SyncMapper.budgetRow(budget(UUID.randomUUID().toString(), null), USER),
                SyncMapper.goalRow(goal(UUID.randomUUID().toString()), USER),
                SyncMapper.ruleRow(rule(UUID.randomUUID().toString(), null), USER),
            ),
        )
        for ((kind, row) in rows) {
            remote.upsert(kind.table, listOf(row), token)
            val id = checkNotNull(row.text("id")).lowercase()
            val record = server.records.getValue(id)
            assertEquals(setOf("id", "user_id", "kind", "payload", "key_id"), record.keys)
            assertFalse(record.toString().contains("名義 privata"))
            assertFalse(record.toString().contains("Caffè"))
            val aad = "bucktrail/e2e/v1/row/${kind.wire}/$id/$USER".encodeToByteArray()
            assertEquals(row.toString(), VaultCrypto.open(checkNotNull(record.text("payload")), dek, aad).decodeToString())
            assertEquals(listOf(row), remote.selectAll(kind.table, USER, token))
            assertEquals(listOf(JsonObject(mapOf("id" to JsonPrimitive(id)))), remote.selectAll(kind.table, USER, token, "id"))
        }
        remote.rpc("fake_rpc", token)
        assertEquals(listOf("rpc:fake_rpc"), server.plain.calls)
    }

    @Test
    fun batchesUploadsAndScopesDeletesByOwnerAndKind() = runBlocking {
        val rows = List(401) { SyncMapper.transactionRow(tx(UUID.randomUUID().toString(), null), USER) }
        remote.upsert(VaultKind.Transaction.table, rows, token)
        assertEquals(listOf("vaultUpsert:200", "vaultUpsert:200", "vaultUpsert:1"), server.readsAndWrites)
        val other = UUID.randomUUID().toString()
        VaultSupabaseApi(server, server, dek, other)
            .upsert(VaultKind.Transaction.table, listOf(SyncMapper.transactionRow(tx(T1, null), other)), token)
        remote.upsert(VaultKind.Account.table, listOf(SyncMapper.accountRow(account(A1), USER)), token)
        remote.deleteIn(VaultKind.Transaction.table, rows.map { checkNotNull(it.text("id")) } + listOf(T1, A1), USER, token)
        assertEquals(setOf(T1, A1), server.records.keys)
        assertEquals(0, remote.selectAll(VaultKind.Transaction.table, USER, token).size)
    }

    @Test
    fun unreadableRowsReturnIdOnlyAndEnginePreservesLocalCopy() = runBlocking {
        val acc = account(A1)
        val local = tx(T1, A1, name = "Local edit")
        val incoming = tx(T2, A1, name = "From vault")
        remote.upsert(VaultKind.Account.table, listOf(SyncMapper.accountRow(acc, USER)), token)
        remote.upsert(VaultKind.Transaction.table, listOf(SyncMapper.transactionRow(local, USER), SyncMapper.transactionRow(incoming, USER)), token)
        val valid = server.records.getValue(T1)
        val wrongInnerId = SyncMapper.transactionRow(incoming, USER).toString().encodeToByteArray()
        val wrongPayload = VaultCrypto.seal(wrongInnerId, dek, VaultCrypto.rowAAD("transaction", UUID.fromString(T1), UUID.fromString(USER)))
        val idOnly = JsonObject(mapOf("id" to JsonPrimitive(T1)))
        for (bad in listOf("bt1.invalid", checkNotNull(server.records[T2]?.text("payload")), wrongPayload)) {
            server.records[T1] = JsonObject(valid + ("payload" to JsonPrimitive(bad)))
            assertEquals(idOnly, remote.selectAll(VaultKind.Transaction.table, USER, token).first { it.text("id") == T1 })
        }
        val localStore = FakeLocalStore(Snapshot(accounts = listOf(acc), transactions = listOf(local)))
        val engine = SyncEngine(remote, localStore, MemorySyncState(), FixedAuth())
        assertEquals(PullOutcome.Done, engine.pull())
        assertEquals(1, engine.lastIgnoredRows)
        assertEquals(setOf(local, incoming), localStore.snap.transactions.toSet())
    }
}
