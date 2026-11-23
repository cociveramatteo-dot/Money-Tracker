package com.bucktrail.android.sync

import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SyncEngineTest {
    private val api = FakeSupabase()
    private val state = MemorySyncState()
    private val auth = FixedAuth()
    private fun engine(local: FakeLocalStore, chunk: Int = 500) = SyncEngine(api, local, state, auth, nowMillis = { 1_000L }, chunk = chunk)

    private val full = Snapshot(
        accounts = listOf(account(A1), account(A2, "Risparmi")),
        transactions = listOf(tx(T1, A1), tx(T2, A2, 5_00), tx(T3, A1, 1_00)),
        budgets = listOf(budget("dddddddd-0000-4000-8000-000000000001", A1)),
        goals = listOf(goal("eeeeeeee-0000-4000-8000-000000000001")),
        rules = listOf(rule(R1, A1)),
    )

    @Test fun pushIsRefusedUntilTheFirstExchangeSucceeded() = runBlocking {
        val local = FakeLocalStore(Snapshot()) // DB vuoto (es. reinstallazione)
        api.seed(full)                          // il cloud ha i dati
        assertFalse(engine(local).push())
        assertTrue("nessuna richiesta: né scritture né cancellazioni", api.calls.isEmpty())
        assertEquals(5, api.rows("mt_transactions").size + api.rows("mt_accounts").size)
    }

    @Test fun loginWithEmptyCloudPushesEverythingWithIosCompatibleRows() = runBlocking {
        val local = FakeLocalStore(full)
        val result = engine(local).syncOnLogin()
        assertEquals(LoginSyncResult.Pushed, result)
        assertEquals(USER, state.syncedUserId); assertEquals(USER, state.lastUserId)
        assertEquals(2, api.rows("mt_accounts").size); assertEquals(3, api.rows("mt_transactions").size)
        assertEquals(1, api.rows("mt_budgets").size); assertEquals(1, api.rows("mt_goals").size); assertEquals(1, api.rows("mt_recurring_rules").size)
        assertTrue(api.rows("mt_transactions").all { it["id"]!!.jsonPrimitive.content == it["id"]!!.jsonPrimitive.content.uppercase() })
        assertEquals(0, api.count("delete:"))
    }

    @Test fun loginWithCloudDataAndEmptyDeviceOnlyPulls() = runBlocking {
        api.seed(full)
        val local = FakeLocalStore(Snapshot())
        val result = engine(local).syncOnLogin()
        assertEquals(LoginSyncResult.Pulled, result)
        assertEquals(full.copy(), local.snap.copy(
            accounts = local.snap.accounts.sortedBy { it.id }, transactions = local.snap.transactions.sortedBy { it.id },
        ).let { it })
        assertEquals("nessuna scrittura sul cloud durante il pull", 0, api.count("upsert:") + api.count("delete:"))
        assertEquals(USER, state.syncedUserId); assertEquals(1_000L, state.lastPull)
    }

    @Test fun deviceDataCreatedWithoutAccountNeedsADecisionAndIsNotTouched() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A2, "Cloud"))))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1, "Locale")), transactions = listOf(tx(T1, A1))))
        val e = engine(local)
        assertEquals(LoginSyncResult.NeedsDecision, e.syncOnLogin())
        assertEquals("Locale", local.snap.accounts.single().name)
        assertEquals(0, local.clearCount); assertEquals(0, api.count("upsert:") + api.count("delete:"))
        assertNull(state.syncedUserId)
        // scelta: usa il cloud
        assertEquals(LoginSyncResult.Pulled, e.syncOnLogin(useCloud = true))
        assertEquals("Cloud", local.snap.accounts.single().name)
        assertTrue(local.snap.transactions.isEmpty())
        assertEquals(0, api.count("delete:")) // il cloud non perde nulla
    }

    @Test fun anotherUsersDataIsClearedBeforeSyncing() = runBlocking {
        state.lastUserId = "99999999-0000-0000-0000-000000000000"; state.syncedUserId = "99999999-0000-0000-0000-000000000000"
        state.markDirty(listOf(T1), 5)
        api.seed(Snapshot(accounts = listOf(account(A2, "Mio"))))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1, "Altrui")), transactions = listOf(tx(T1, A1))))
        assertEquals(LoginSyncResult.Pulled, engine(local).syncOnLogin())
        assertEquals(1, local.clearCount)
        assertEquals(listOf("Mio"), local.snap.accounts.map { it.name })
        assertTrue(state.dirty().isEmpty())
    }

    @Test fun failedRemoteLookupAtLoginNeverFallsBackToABlindPush() = runBlocking {
        api.failSelectOn = "mt_accounts"
        val local = FakeLocalStore(full)
        assertEquals(LoginSyncResult.Failed, engine(local).syncOnLogin())
        assertEquals(0, api.count("upsert:") + api.count("delete:"))
        assertNull(state.syncedUserId)
    }

    @Test fun pullAbortsAndKeepsEverythingWhenAMiddleRequestFails() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1, "Nuovo nome")), transactions = listOf(tx(T2, A1))))
        state.syncedUserId = USER
        api.failSelectOn = "mt_budgets"
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1, "Vecchio")), transactions = listOf(tx(T1, A1))))
        assertEquals(PullOutcome.Failed, engine(local).pull())
        assertEquals(0, local.applyCount); assertEquals("Vecchio", local.snap.accounts.single().name); assertEquals(0L, state.lastPull)
    }

    @Test fun pullIsAllOrNothingWhenTheLocalTransactionFails() = runBlocking {
        api.seed(full)
        val local = FakeLocalStore(Snapshot()).also { it.failApply = true }
        assertEquals(PullOutcome.Failed, engine(local).pull())
        assertTrue(local.snap.isEmpty); assertEquals(0L, state.lastPull)
    }

    @Test fun pullGuardSkipsWhenCloudHasNoAccountsButDeviceDoes() = runBlocking {
        val local = FakeLocalStore(full)
        assertEquals(PullOutcome.Skipped, engine(local).pull())
        assertEquals(full, local.snap); assertEquals(0L, state.lastPull)
    }

    @Test fun pullDoesNotDeleteTransactionsStillWaitingToBeUploaded() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1))))
        state.markDirty(listOf(T2), 7)
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1), tx(T2, A1), tx(T3, A1))))
        assertEquals(PullOutcome.Done, engine(local).pull())
        assertEquals(setOf(T1, T2), local.snap.transactions.map { it.id }.toSet()) // T3 (cancellato altrove) via, T2 (sporco) resta
    }

    @Test fun remoteWinsFieldByFieldAndRuleWatermarkNeverGoesBack() = runBlocking {
        api.seed(Snapshot(
            accounts = listOf(account(A1, "Rinominato", 500_00)), transactions = listOf(tx(T1, A1, 99_00, name = "Dal cloud")),
            rules = listOf(rule(R1, A1, through = 1_000)),
        ))
        val localRule = rule(R1, A1, through = 2_000)
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1, "Vecchio")), transactions = listOf(tx(T1, A1, 1_00, name = "Locale")), rules = listOf(localRule)))
        assertEquals(PullOutcome.Done, engine(local).pull())
        assertEquals("Rinominato", local.snap.accounts.single().name); assertEquals(500_00L, local.snap.accounts.single().initialBalanceCents)
        assertEquals("Dal cloud", local.snap.transactions.single().name); assertEquals(99_00L, local.snap.transactions.single().amountCents)
        assertEquals(2_000L, local.snap.rules.single().materializedThrough)
    }

    @Test fun deletingAnAccountRemotelyCascadesLocally() = runBlocking {
        api.seed(Snapshot(accounts = listOf(account(A1))))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1), account(A2)), transactions = listOf(tx(T2, A2)), budgets = listOf(budget("dddddddd-0000-4000-8000-000000000001", A2))))
        assertEquals(PullOutcome.Done, engine(local).pull())
        assertEquals(listOf(A1), local.snap.accounts.map { it.id }); assertTrue(local.snap.transactions.isEmpty()); assertTrue(local.snap.budgets.isEmpty())
    }

    @Test fun pushUploadsDirtyAndMissingAndDeletesOrphansWithOneRequestEach() = runBlocking {
        state.syncedUserId = USER
        // cloud: T1 (vecchio), T2 e uno in più "X" cancellato in locale
        val x = "bbbbbbbb-0000-4000-8000-0000000000ff"
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1, 1_00), tx(T2, A1, 2_00), tx(x, A1, 3_00))))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1, 9_99), tx(T2, A1, 2_00), tx(T3, A1, 7_00))))
        state.markDirty(listOf(T1), 5)
        assertTrue(engine(local).push())
        val byId = api.rows("mt_transactions").associateBy { it["id"]!!.jsonPrimitive.content.lowercase() }
        assertEquals("9.99", byId[T1]!!["amount"]!!.jsonPrimitive.content)   // sporco: caricato
        assertEquals("7.00", byId[T3]!!["amount"]!!.jsonPrimitive.content)   // assente dal cloud: caricato anche se non sporco
        assertFalse(byId.containsKey(x))                                     // orfano: cancellato
        assertEquals(1, api.deleted.count { it.first == "mt_transactions" })
        assertEquals(listOf("BBBBBBBB-0000-4000-8000-0000000000FF"), api.deleted.first { it.first == "mt_transactions" }.second)
        assertTrue(state.dirty().isEmpty())
        assertEquals("T2 non toccato: solo T1 e T3", "upsert:mt_transactions:2", api.calls.first { it.startsWith("upsert:mt_transactions") })
    }

    @Test fun editAfterTheSnapshotStaysDirtyForTheNextPush() = runBlocking {
        state.syncedUserId = USER
        api.seed(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1))))
        state.markDirty(listOf(T1), 5)
        // modifica concorrente: durante l'upload la marcatura cambia
        val racing = object : LocalStore {
            val inner = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = listOf(tx(T1, A1, 9_00))))
            override suspend fun snapshot() = inner.snapshot().also { state.markDirty(listOf(T1), 6) }
            override suspend fun apply(plan: SyncPlan) = inner.apply(plan)
            override suspend fun clear() = inner.clear()
        }
        assertTrue(SyncEngine(api, racing, state, auth).push())
        // la marcatura ricevuta durante il push (stamp 6) non viene cancellata dal push che aveva visto stamp 5
        assertEquals(mapOf(T1 to 6L), state.dirty())
    }

    @Test fun failedPushKeepsDirtyAndReportsFalse() = runBlocking {
        state.syncedUserId = USER
        api.failUpsertOn = "mt_transactions"
        val local = FakeLocalStore(full)
        state.markDirty(listOf(T1), 5)
        assertFalse(engine(local).push())
        assertEquals(mapOf(T1 to 5L), state.dirty())
    }

    @Test fun largeUploadsAreChunked() = runBlocking {
        state.syncedUserId = USER
        val many = (1..7).map { tx("bbbbbbbb-0000-4000-8000-00000000010$it", A1) }
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1)), transactions = many))
        assertTrue(engine(local, chunk = 3).push())
        assertEquals(listOf("upsert:mt_transactions:3", "upsert:mt_transactions:3", "upsert:mt_transactions:1"), api.calls.filter { it.startsWith("upsert:mt_transactions") })
    }

    @Test fun roundTripBetweenTwoDevicesIsLossless() = runBlocking {
        // dispositivo A (Android) -> cloud -> dispositivo B (Android): stessi dati
        val a = FakeLocalStore(full)
        assertEquals(LoginSyncResult.Pushed, engine(a).syncOnLogin())
        val b = FakeLocalStore(Snapshot()); val stateB = MemorySyncState()
        assertEquals(LoginSyncResult.Pulled, SyncEngine(api, b, stateB, auth).syncOnLogin())
        assertEquals(full.accounts.sortedBy { it.id }, b.snap.accounts.sortedBy { it.id })
        assertEquals(full.transactions.sortedBy { it.id }, b.snap.transactions.sortedBy { it.id })
        assertEquals(full.budgets, b.snap.budgets); assertEquals(full.goals, b.snap.goals); assertEquals(full.rules, b.snap.rules)
    }

    @Test fun clearLocalDataResetsEverythingOfTheUser() = runBlocking {
        state.syncedUserId = USER; state.lastUserId = USER; state.lastPull = 5; state.hasPendingChanges = true; state.markDirty(listOf(T1), 1)
        val local = FakeLocalStore(full)
        engine(local).clearLocalData()
        assertTrue(local.snap.isEmpty); assertNull(state.syncedUserId); assertNull(state.lastUserId); assertEquals(0L, state.lastPull)
        assertFalse(state.hasPendingChanges); assertTrue(state.dirty().isEmpty())
    }

    @Test fun resumedSessionPushesBeforePulling() = runBlocking {
        state.syncedUserId = USER; state.lastUserId = USER
        api.seed(Snapshot(accounts = listOf(account(A1, "Cloud")), transactions = listOf(tx(T1, A1))))
        val local = FakeLocalStore(Snapshot(accounts = listOf(account(A1, "Cloud")), transactions = listOf(tx(T1, A1), tx(T2, A1, 4_00))))
        state.markDirty(listOf(T2), 3)
        assertEquals(LoginSyncResult.Pulled, engine(local).syncOnLogin())
        val order = api.calls.indexOfFirst { it.startsWith("upsert:mt_transactions") } < api.calls.indexOfLast { it == "select:mt_transactions" }
        assertTrue("prima il push, poi il pull", order)
        assertTrue(local.snap.transactions.any { it.id == T2 })
    }
}
