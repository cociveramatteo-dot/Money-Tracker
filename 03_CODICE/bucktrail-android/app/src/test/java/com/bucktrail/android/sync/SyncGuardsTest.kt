package com.bucktrail.android.sync

import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test

/** Guardia anti-cancellazione del cloud (DB vuoto o calo anomalo) e righe remote assurde che non bloccano il pull. */
class SyncGuardsTest {
    private val api = FakeSupabase()
    private val state = MemorySyncState().also { it.syncedUserId = USER; it.lastUserId = USER }
    private val auth = FixedAuth()
    private fun engine(local: FakeLocalStore) = SyncEngine(api, local, state, auth, nowMillis = { 1_000L })
    private fun ids(n: Int) = (1..n).map { "bbbbbbbb-0000-4000-8000-%012d".format(it) }

    @Test fun guardMath() {
        assertFalse(DeletionGuard.requiresConfirmation(deletions = 0, localCount = 0, baseline = 500))
        assertTrue("DB vuoto con cose da cancellare", DeletionGuard.requiresConfirmation(1, 0, 3))
        assertFalse("pochi record: nessun calo anomalo", DeletionGuard.requiresConfirmation(4, 1, 5))
        assertTrue("sotto la metà dell'ultimo stato", DeletionGuard.requiresConfirmation(60, 39, 100))
        assertFalse("giusto la metà", DeletionGuard.requiresConfirmation(50, 50, 100))
    }

    @Test fun emptyLocalDatabaseNeverWipesTheCloudWithoutConfirmation() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1), tx(T2, A1))))
        val local = FakeLocalStore(Snapshot())
        val e = engine(local)
        val r = e.pushDetailed()
        assertEquals(PushResult.NeedsConfirmation(deletions = 3, baseline = 3), r)
        assertFalse(e.push())
        assertEquals("nessuna scrittura né cancellazione", 0, api.count("upsert:") + api.count("delete:"))
        assertEquals(3, api.rows("mt_accounts").size + api.rows("mt_transactions").size)
        // dopo la conferma esplicita si cancella
        assertEquals(PushResult.Done, e.pushDetailed(allowDestructive = true))
        assertEquals(0, api.rows("mt_accounts").size + api.rows("mt_transactions").size)
    }

    @Test fun anomalousDropComparedToTheLastSyncedStateNeedsConfirmation() = runBlocking {
        val many = ids(40)
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = many.map { tx(it, A1) }))
        state.lastSyncedCount = 41
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = many.take(10).map { tx(it, A1) }))
        val r = engine(local).pushDetailed()
        assertEquals(PushResult.NeedsConfirmation(deletions = 30, baseline = 41), r)
        assertEquals(41, api.rows("mt_accounts").size + api.rows("mt_transactions").size)
    }

    @Test fun normalDeletionsAndAPushWithNothingToDeleteAreNotBlocked() = runBlocking {
        val many = ids(40)
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = many.map { tx(it, A1) }))
        state.lastSyncedCount = 41
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = many.take(30).map { tx(it, A1) }))
        val e = engine(local)
        assertEquals(PushResult.Done, e.pushDetailed())
        assertEquals(31, api.rows("mt_accounts").size + api.rows("mt_transactions").size)
        assertEquals("il nuovo stato è la base", 31, state.lastSyncedCount)
        // DB locale vuoto ma cloud già vuoto: niente da cancellare, nessun blocco
        api.tables.clear()
        assertEquals(PushResult.Done, engine(FakeLocalStore(Snapshot())).pushDetailed())
    }

    @Test fun serviceStyleLoginWithResumedSessionAsksInsteadOfWipingTheCloud() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1))))
        val r = engine(FakeLocalStore(Snapshot())).syncOnLogin()
        assertTrue(r is LoginSyncResult.NeedsDeleteConfirmation)
        assertEquals(0, api.count("delete:"))
    }

    private fun poisoned(base: JsonObject, key: String, value: String) = JsonObject(base + (key to JsonPrimitive(value)))

    @Test fun absurdAmountRowIsIgnoredWithoutBlockingThePullOrDeletingTheLocalCopy() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1, 10_00), tx(T2, A1, 20_00))))
        // T2 avvelenata sul cloud: 10^20 euro (non entra in un Long); T3 oltre il limite dei saldi
        api.put("mt_transactions", poisoned(SyncMapper.transactionRow(tx(T2, A1), USER), "amount", "100000000000000000000.00"))
        api.put("mt_transactions", poisoned(SyncMapper.transactionRow(tx(T3, A1), USER), "amount", "5000000000000.00"))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1, 1_00), tx(T2, A1, 20_00))))
        val e = engine(local)
        assertEquals(PullOutcome.Done, e.pull())
        assertEquals(2, e.lastIgnoredRows)
        val byId = local.snap.transactions.associateBy { it.id }
        assertEquals("la riga buona si aggiorna", 10_00L, byId[T1]!!.amountCents)
        assertEquals("la copia locale della riga ignorata resta", 20_00L, byId[T2]!!.amountCents)
        assertFalse("la riga assurda non entra", byId.containsKey(T3))
    }

    @Test fun absurdAccountRowKeepsTheLocalAccountAndItsTransactions() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1), account(A2)), transactions = listOf(tx(T1, A2))))
        api.put("mt_accounts", poisoned(SyncMapper.accountRow(account(A2), USER), "initial_balance", "99999999999999999999999.00"))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A2, "Mio")), transactions = listOf(tx(T1, A2))))
        val e = engine(local)
        assertEquals(PullOutcome.Done, e.pull())
        assertEquals(1, e.lastIgnoredRows)
        assertEquals(setOf(A1, A2), local.snap.accounts.map { it.id }.toSet())
        assertEquals("Mio", local.snap.accounts.first { it.id == A2 }.name)
        assertEquals(listOf(T1), local.snap.transactions.map { it.id })
    }

    @Test fun transactionOfAnIgnoredUnknownAccountIsStoredWithoutAccountNotDangling() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1), account(A2)), transactions = listOf(tx(T1, A2))))
        api.put("mt_accounts", poisoned(SyncMapper.accountRow(account(A2), USER), "initial_balance", "1e40"))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1))))
        assertEquals(PullOutcome.Done, engine(local).pull())
        assertEquals(null, local.snap.transactions.single().accountId)
    }

    @Test fun pullRecordsTheSyncedCountAndClearResetsIt() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1), tx(T2, A1))))
        val e = engine(FakeLocalStore(Snapshot()))
        assertEquals(PullOutcome.Done, e.pull())
        assertEquals(3, state.lastSyncedCount)
        e.clearLocalData()
        assertEquals(-1, state.lastSyncedCount)
    }
}
