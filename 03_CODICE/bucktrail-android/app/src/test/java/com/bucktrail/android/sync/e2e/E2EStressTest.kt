package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.R1
import com.bucktrail.android.sync.SyncMapper
import com.bucktrail.android.sync.USER
import com.bucktrail.android.sync.rule
import kotlinx.coroutines.CompletableDeferred
import kotlinx.coroutines.async
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class E2EStressTest {
    @Test
    fun twentyThousandMovementsMigrateAndVerifyInMemory() = runBlocking {
        val snapshot = migrationSnapshot(transactions = 20_000).let {
            it.copy(transactions = listOf(it.transactions.first().copy(name = "長い名前 🧾 ".repeat(128))) + it.transactions.drop(1))
        }
        MigrationDevice(coroutineContext, original = snapshot).use { f ->
            val start = System.nanoTime()
            f.enable()
            val migrated = System.nanoTime()
            f.expectProtected(snapshot)
            assertEquals(20_000, f.remote.base.records.values.count { it.text("kind") == "transaction" })
            val readMs = (System.nanoTime() - migrated) / 1_000_000
            val migrateMs = (migrated - start) / 1_000_000
            println("S-50l Android : 20000 movimenti, migrazione ${migrateMs} ms, lettura e verifica ${readMs} ms")
        }
    }

    @Test
    fun exceptionsNearEnvelopeLimitRoundTripAndOversizeFailsClosed() = runBlocking {
        val remote = FakeVaultSupabase()
        val transport = VaultSupabaseApi(remote, remote, ByteArray(32) { 1 }, USER)
        val kind = VaultKind.Rule
        fun row(length: Int) = SyncMapper.ruleRow(rule(R1, null, exceptions =
            """{"2026-01-01":{"notes":"${"x".repeat(length)}"}}"""), USER)
        val near = row(48_300)
        transport.upsert(kind.table, listOf(near), "token")
        val restored = transport.selectAll(kind.table, USER, "token").single()
        assertTrue(restored.text("exceptions") == near.text("exceptions"))
        val envelope = checkNotNull(remote.records[R1]?.text("payload")).length
        assertTrue(envelope in 64_000 until 65_536)

        val oversized = row(63_500)
        remote.plain.put(kind.table, oversized)
        expectError<VaultCrypto.CryptoException> { transport.upsert(kind.table, listOf(oversized), "token") }
        assertTrue(remote.records[R1]?.text("payload")?.length == envelope)
        assertTrue(remote.plain.rows(kind.table).single().text("exceptions") == oversized.text("exceptions"))
        println("S-50l Android : busta accettata $envelope byte, exceptions eccedente rifiutata con il chiaro intatto")
    }

    @Test
    fun networkLossAtEveryCheckpointRecoversWithoutLosingRows() = runBlocking {
        val steps = E2EMigrator.Step.entries
        for (step in steps) {
            val expected = migrationSnapshot()
            MigrationDevice(coroutineContext, original = expected).use { f ->
                val enabling = step.name.startsWith("A")
                if (!enabling) f.enable()
                val stop: suspend (E2EMigrator.Step) -> Unit = { current ->
                    if (current == step) throw ApiException(ErrorKind.Network, 0, "fixture network loss")
                }
                val error = expectError<ApiException> { if (enabling) f.enable(stop) else f.disable(stop) }
                assertEquals(ErrorKind.Network, error.kind)
                f.reopen()
                f.service.manualRefresh()
                if (enabling) {
                    if (f.remote.key() == null) f.enable()
                    f.expectProtected(expected)
                } else {
                    if (f.remote.key()?.text("state") == "active") f.disable()
                    f.expectPlain(expected)
                }
            }
        }
        println("S-50l Android : ${steps.size} interruzioni, ricevute verificate dopo ogni ripresa")
    }

    @Test
    fun concurrentActivationReportsK46WithoutErasingWinnerData() = runBlocking {
        MigrationDevice(coroutineContext).use { first ->
            MigrationDevice(coroutineContext, first.remote, first.store.snap).use { second ->
                val paused = CompletableDeferred<Unit>()
                val resume = CompletableDeferred<Unit>()
                val loser = async {
                    expectError<E2EMigrator.Failure> {
                        first.enable {
                            if (it == E2EMigrator.Step.A2) {
                                paused.complete(Unit)
                                resume.await()
                            }
                        }
                    }
                }
                paused.await()
                try {
                    second.enable()
                    val winner = second.remote.key()
                    resume.complete(Unit)
                    assertEquals(E2EController.Reason.ConcurrentActivation, E2EController.issueFor(loser.await()))
                    assertNull(first.secrets.load(USER))
                    assertTrue(second.secrets.load(USER) != null)
                    assertEquals(winner, second.remote.key())
                    assertFalse(second.remote.base.records.isEmpty())
                    second.expectProtected(second.store.snap)
                } finally {
                    resume.complete(Unit)
                }
            }
        }
    }
}
