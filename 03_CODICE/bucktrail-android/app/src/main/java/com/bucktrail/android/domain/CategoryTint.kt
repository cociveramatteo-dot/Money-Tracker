package com.bucktrail.android.domain

/** Tinte categoria (`CategoryTint.swift`): mappa fissa per le predefinite, FNV-1a 32 bit % 4 per le altre. */
enum class CategoryTint {
    Green, Amber, Blue, Violet;

    companion object {
        private val fixed = mapOf(
            "Cibo" to Amber, "Trasporti" to Blue, "Svago" to Violet, "Shopping" to Amber, "Salute" to Green,
            "Casa" to Blue, "Abbonamenti" to Violet, "Lavoro" to Green, "Istruzione" to Violet, "Viaggi" to Blue,
            "Regali" to Amber, "Giroconto" to Blue, "Risparmio" to Green, "Altro" to Green,
        )

        /** FNV-1a 32 bit sui byte UTF-8 (offset 2166136261, primo 16777619). */
        fun stableHash(text: String): Long {
            var h = 2166136261L
            for (b in text.toByteArray(Charsets.UTF_8)) {
                h = h xor (b.toLong() and 0xFF)
                h = (h * 16777619L) and 0xFFFFFFFFL
            }
            return h
        }

        fun tint(category: String): CategoryTint = fixed[category] ?: entries[(stableHash(category) % 4).toInt()]
    }
}
