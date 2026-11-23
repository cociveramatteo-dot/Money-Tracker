package com.bucktrail.android.sync

import com.bucktrail.android.data.BucktrailDao

/** Il database reale (mai quello demo) visto dal sync. */
class RoomLocalStore(private val dao: () -> BucktrailDao) : LocalStore {
    override suspend fun snapshot(): Snapshot = dao().let { Snapshot(it.accounts(), it.transactions(), it.budgets(), it.goals(), it.rules()) }
    override suspend fun apply(plan: SyncPlan) = dao().applySyncPlan(plan)
    override suspend fun clear() = dao().clearLocalData()
}
