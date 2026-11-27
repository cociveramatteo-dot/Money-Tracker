package com.bucktrail.android.sync

import com.bucktrail.android.sync.e2e.VaultKind

data class SyncBaseline(
    val user: String,
    val tables: Map<String, Set<String>> = emptyMap(),
    // A push can run again before a pull removes these rows from the local store.
    val deletedElsewhere: Map<String, Set<String>> = emptyMap(),
    // The pull saw these IDs, but had no local copy and could not decode them.
    val ignoredWithoutLocal: Map<String, Set<String>> = emptyMap(),
) {
    data class Plan(
        val upload: Set<String>,
        val deleteRemote: Set<String>,
        val deletedElsewhere: Set<String>,
        val newBase: Set<String>,
    )

    fun base(kind: VaultKind, local: Set<String>? = null): Set<String>? {
        val synced = tables[kind.wire] ?: return null
        val pending = deletedElsewhere[kind.wire].orEmpty()
        val ignored = ignoredWithoutLocal[kind.wire].orEmpty()
        return (synced - (ignored - local.orEmpty())) + (pending intersect (local ?: pending))
    }

    fun recordPush(kind: VaultKind, plan: Plan): SyncBaseline {
        val pending = deletedElsewhere - kind.wire
        return copy(
            tables = tables + (kind.wire to plan.newBase),
            deletedElsewhere = if (plan.deletedElsewhere.isEmpty()) pending else pending + (kind.wire to plan.deletedElsewhere),
            ignoredWithoutLocal = ignoredWithoutLocal - kind.wire,
        )
    }

    companion object {
        fun plan(local: Set<String>, remote: Set<String>, base: Set<String>?, dirty: Set<String> = emptySet(),
                 fullUpsert: Boolean): Plan {
            val common = local intersect remote
            val deletedElsewhere = (local - remote) intersect base.orEmpty()
            val eligible = if (fullUpsert) local else local intersect dirty
            val newLocal = if (base == null) emptySet() else local - remote - base
            val upload = (eligible + newLocal) - deletedElsewhere
            return Plan(upload, (remote - local) intersect base.orEmpty(), deletedElsewhere, common + upload)
        }
    }
}
