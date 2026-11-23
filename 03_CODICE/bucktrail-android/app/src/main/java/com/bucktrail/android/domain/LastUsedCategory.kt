package com.bucktrail.android.domain

import java.text.Normalizer
import java.time.Instant

/** Suggerimento dalla cronologia: vince il movimento normale inserito più di recente (per `createdAt`). */
object LastUsedCategory {
    data class Movement(val name: String, val category: String, val createdAt: Instant, val isDone: Boolean, val isTransfer: Boolean)

    fun suggest(name: String, history: List<Movement>, availableCategories: Set<String>): String? {
        val key = normalized(name)
        if (key.isEmpty()) return null
        var latest: Movement? = null
        for (m in history) {
            if (!m.isDone || m.isTransfer || normalized(m.name) != key) continue
            // a parità di createdAt vince l'ultimo inserito
            if (latest == null || m.createdAt >= latest.createdAt) latest = m
        }
        return latest?.category?.takeIf { it in availableCategories }
    }

    private fun normalized(name: String): String =
        Normalizer.normalize(name, Normalizer.Form.NFD).replace(Regex("\\p{Mn}+"), "").lowercase()
            .split(Regex("\\s+")).filter { it.isNotEmpty() }.joinToString(" ")
}
