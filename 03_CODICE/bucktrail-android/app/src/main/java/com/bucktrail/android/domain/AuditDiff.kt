package com.bucktrail.android.domain

/**
 * Cronologia modifiche (§4.11): confronta due istantanee e produce gli eventi `created`/`updated`/`deleted`
 * per movimenti, conti, budget e obiettivi (non categorie né regole), come la notifica di salvataggio iOS.
 */
object AuditDiff {
    data class Item(val type: String, val id: String, val summary: String, val fingerprint: Any)
    data class Event(val type: String, val action: String, val summary: String)

    const val TRANSACTION = "Transaction"
    const val ACCOUNT = "Account"
    const val BUDGET = "Budget"
    const val GOAL = "Goal"
    const val DELETED_SUMMARY = "—"

    fun diff(old: Collection<Item>, new: Collection<Item>): List<Event> {
        val before = old.associateBy { it.type to it.id }
        val after = new.associateBy { it.type to it.id }
        val events = ArrayList<Event>()
        for ((key, item) in after) {
            val prev = before[key]
            if (prev == null) events += Event(item.type, "created", item.summary)
            else if (prev.fingerprint != item.fingerprint) events += Event(item.type, "updated", item.summary)
        }
        for ((key, item) in before) if (key !in after) events += Event(item.type, "deleted", DELETED_SUMMARY)
        return events
    }
}
