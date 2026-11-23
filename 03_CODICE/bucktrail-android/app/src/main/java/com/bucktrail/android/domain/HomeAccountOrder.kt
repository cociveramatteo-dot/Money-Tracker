package com.bucktrail.android.domain

/** Logica del foglio «Conti in home» (`HomeAccountOrderSheet`): selezione, ordine e salvataggio. */
object HomeAccountOrder {
    data class State(val items: List<String>, val shown: Set<String>)

    /** Lista salvata vuota: parte con tutti selezionati nell'ordine dato; altrimenti prima i salvati, poi i nuovi. */
    fun load(saved: List<String>, all: List<String>): State {
        if (saved.isEmpty()) return State(all, all.toSet())
        val ordered = saved.filter { it in all } + all.filter { it !in saved }
        return State(ordered, saved.toSet())
    }

    /** Non si può deselezionare l'ultimo; selezionare sposta il conto dopo l'ultimo già selezionato. */
    fun toggle(state: State, id: String): State {
        if (id in state.shown) return if (state.shown.size > 1) state.copy(shown = state.shown - id) else state
        val shown = state.shown + id
        val rest = state.items.filter { it != id }
        val insertAt = rest.indexOfLast { it in state.shown } + 1
        return State(rest.take(insertAt) + id + rest.drop(insertAt), shown)
    }

    fun move(items: List<String>, from: Int, to: Int): List<String> {
        if (from !in items.indices || to !in items.indices) return items
        return items.toMutableList().apply { add(to, removeAt(from)) }
    }

    fun save(state: State): List<String> = state.items.filter { it in state.shown }

    /** Un conto nuovo (non escluso) va in testa alla lista salvata, solo se esiste già una lista (anomalia iOS #2 non replicata). */
    fun withNewAccount(saved: List<String>, id: String): List<String> = if (saved.isEmpty()) saved else listOf(id) + saved.filter { it != id }
}
