package com.bucktrail.android.sync

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SyncMergeTest {
    @Test fun identicalSnapshotsProduceAnEmptyPlan() {
        val s = Snapshot(listOf(account(A1)), listOf(tx(T1, A1)), listOf(budget("dddddddd-0000-4000-8000-000000000001", A1)), listOf(goal("eeeeeeee-0000-4000-8000-000000000001")), listOf(rule(R1, A1)))
        assertTrue(SyncMerge.plan(s, s, emptySet())!!.isEmpty)
    }

    @Test fun guardWhenCloudHasNoAccountsButDeviceHas() {
        assertNull(SyncMerge.plan(Snapshot(accounts = listOf(account(A1))), Snapshot(), emptySet()))
    }

    @Test fun emptyEverywhereIsAnEmptyPlan() {
        assertTrue(SyncMerge.plan(Snapshot(), Snapshot(), emptySet())!!.isEmpty)
    }

    @Test fun rulesAreKeptWhenCloudRulesAreEmptyButDeviceHasSome() {
        val plan = SyncMerge.plan(Snapshot(accounts = listOf(account(A1)), rules = listOf(rule(R1, A1))), Snapshot(accounts = listOf(account(A1))), emptySet())!!
        assertTrue(plan.deleteRuleIds.isEmpty())
    }

    @Test fun transactionAccountIsKeptWhenRemoteHasNone() {
        val local = Snapshot(listOf(account(A1)), listOf(tx(T1, A1)))
        val remote = Snapshot(listOf(account(A1)), listOf(tx(T1, null)))
        assertTrue(SyncMerge.plan(local, remote, emptySet())!!.transactions.isEmpty())
    }

    @Test fun transactionPointingToUnknownAccountBecomesUnassignedInsteadOfBreakingTheForeignKey() {
        val plan = SyncMerge.plan(Snapshot(), Snapshot(listOf(account(A1)), listOf(tx(T1, A2))), emptySet())!!
        assertNull(plan.transactions.single().accountId)
    }

    @Test fun createdAtOfExistingRowsIsNotOverwrittenExceptForRules() {
        val local = Snapshot(listOf(account(A1)), listOf(tx(T1, A1)), rules = listOf(rule(R1, A1)))
        val remote = Snapshot(listOf(account(A1).copy(createdAt = 1)), listOf(tx(T1, A1).copy(createdAt = 1, name = "x")), rules = listOf(rule(R1, A1).copy(createdAt = 1)))
        val plan = SyncMerge.plan(local, remote, emptySet())!!
        assertTrue(plan.accounts.isEmpty())
        assertEquals(1_700_000_000_000, plan.transactions.single().createdAt)
        assertEquals(1L, plan.rules.single().createdAt)
    }
}
