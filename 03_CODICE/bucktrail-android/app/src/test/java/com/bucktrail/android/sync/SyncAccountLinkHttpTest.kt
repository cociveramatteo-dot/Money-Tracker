package com.bucktrail.android.sync

import com.bucktrail.android.data.TransactionEntity
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.File
import java.net.HttpURLConnection
import java.net.URI
import java.util.concurrent.TimeUnit

class SyncAccountLinkHttpTest {
    @Test fun lostLinkIsRepairedWithoutEchoAndExplicitUnlinkIsKept() = runBlocking {
        val script = listOf(File("scripts/fake-supabase.py"), File("../scripts/fake-supabase.py"))
            .first { it.isFile }
        val log = File.createTempFile("bucktrail-fake-supabase", ".log")
        val server = ProcessBuilder("python3", script.absolutePath, "0").redirectErrorStream(true)
            .redirectOutput(log).apply { environment().keys.removeIf { it.startsWith("FAKE_") } }.start()
        try {
            val addressPattern = Regex("http://127\\.0\\.0\\.1:\\d+")
            val deadline = System.nanoTime() + TimeUnit.SECONDS.toNanos(5)
            var address = addressPattern.find(log.readText())?.value
            while (address == null && server.isAlive && System.nanoTime() < deadline) {
                Thread.sleep(20)
                address = addressPattern.find(log.readText())?.value
            }
            val base = requireNotNull(address) { log.readText() }
            val http = HttpSupabaseApi(base, "fake-key")
            val session = http.signIn("demo@test.it", "password1")
            val owner = session.userId
            val token = session.accessToken
            val auth = object : SyncEngine.AuthGateway {
                override val userId = owner
                override suspend fun <T> authed(block: suspend (String) -> T): T = block(token)
            }

            var transactionUpserts = 0
            val api = object : SupabaseApi by http {
                override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) {
                    if (table == "mt_transactions") transactionUpserts += rows.size
                    http.upsert(table, rows, token)
                }
            }

            val account = account(A1)
            val lost = tx(T1, A1, cents = 1200).copy(isDone = true)
            val intact = tx(T2, A1, cents = 300).copy(isDone = true)
            suspend fun seedAccount() = http.upsert("mt_accounts", listOf(SyncMapper.accountRow(account, owner)), token)
            suspend fun seedTransactions(vararg rows: TransactionEntity) =
                http.upsert("mt_transactions", rows.map { SyncMapper.transactionRow(it, owner) }, token)
            suspend fun remoteLink(id: String) = http.selectAll("mt_transactions", owner, token)
                .first { it["id"]?.jsonPrimitive?.content == id }["account_id"]?.jsonPrimitive?.contentOrNull

            seedAccount()
            seedTransactions(lost)
            val firstStore = FakeLocalStore()
            val firstState = MemorySyncState()
            val first = SyncEngine(api, firstStore, firstState, auth)
            assertEquals(LoginSyncResult.Pulled, first.syncOnLogin())

            // An older client deletes the account directly, then recreates the same ID.
            fun simulateLegacyDelete() {
                val delete = URI.create("$base/rest/v1/mt_accounts?id=eq.$A1&user_id=eq.$owner")
                    .toURL().openConnection() as HttpURLConnection
                try {
                    delete.requestMethod = "DELETE"
                    delete.setRequestProperty("Authorization", "Bearer $token")
                    assertEquals(204, delete.responseCode)
                } finally {
                    delete.disconnect()
                }
            }
            simulateLegacyDelete()
            seedAccount()
            seedTransactions(intact)
            firstStore.snap = firstStore.snap.copy(transactions = listOf(lost, intact))
            assertNull(remoteLink(T1))
            assertEquals(A1, remoteLink(T2))

            val secondStore = FakeLocalStore()
            val secondState = MemorySyncState()
            val second = SyncEngine(api, secondStore, secondState, auth)
            assertEquals(LoginSyncResult.Pulled, second.syncOnLogin())
            assertTrue(second.push())
            assertEquals(0, transactionUpserts)
            assertNull(secondStore.snap.transactions.first { it.id == T1 }.accountId)

            assertEquals(PullOutcome.Done, first.pull())
            assertEquals(A1, remoteLink(T1))
            assertEquals(0, transactionUpserts)
            assertEquals(PullOutcome.Done, second.pull())
            val linked = secondStore.snap.transactions.filter { it.accountId == A1 }
            assertEquals(setOf(T1, T2), linked.map { it.id }.toSet())
            assertEquals(8500L, account.initialBalanceCents - linked.filter { it.isDone }.sumOf { it.amountCents })

            seedTransactions(lost.copy(accountId = null))
            assertEquals(PullOutcome.Done, second.pull())
            assertNull(secondStore.snap.transactions.first { it.id == T1 }.accountId)
            assertNull(remoteLink(T1))

            // A partial local store cannot delete the server's account or its linked records.
            secondStore.snap = Snapshot(transactions = listOf(lost.copy(accountId = null)))
            assertTrue(second.push())
            assertEquals(A1, remoteLink(T2))
            assertEquals(PullOutcome.Done, second.pull())
            assertEquals(listOf(A1), secondStore.snap.accounts.map { it.id })

            // With the account really gone, S-51g still removes the account and keeps T2.
            simulateLegacyDelete()
            assertEquals(PullOutcome.Done, second.pull())
            assertTrue(secondStore.snap.accounts.isEmpty())
            assertNull(secondStore.snap.transactions.first { it.id == T2 }.accountId)
            assertTrue(second.push())
            assertEquals(0, transactionUpserts)
        } finally {
            server.destroy()
            if (!server.waitFor(3, TimeUnit.SECONDS)) server.destroyForcibly()
            log.delete()
        }
        Unit
    }
}
