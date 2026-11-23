package com.bucktrail.android.domain

/** Regole di Gestione categorie (§4.8). */
object CategoryEditing {
    /** Duplicato = stesso nome (senza distinzione di maiuscole), escludendo la categoria stessa. */
    fun isDuplicate(name: String, existing: List<Pair<String, String>>, selfId: String?): Boolean {
        val n = name.trim().lowercase()
        return n.isNotEmpty() && existing.any { (id, other) -> id != selfId && other.trim().lowercase() == n }
    }

    /** Riscrive un nome nel campo `category` di un budget (nomi ordinati e ri-uniti); `Tutti` resta tale. */
    fun renameInBudget(raw: String, old: String, new: String): String {
        if (raw == "Tutti") return raw
        val names = Budgeting.categorySet(raw)
        if (old !in names) return raw
        return Budgeting.categoryString((names - old) + new)
    }

    enum class DeleteMessage { None, One, Many }

    fun deleteMessage(count: Int): DeleteMessage = when { count <= 0 -> DeleteMessage.None; count == 1 -> DeleteMessage.One; else -> DeleteMessage.Many }
}
