package com.bucktrail.android.domain

import java.text.Normalizer

/**
 * Classificatore on-device (porta di `KeywordCategoryClassifier.swift`): T1 esatto x4, T2 prefisso input x2.5/1.5,
 * T3 prefisso keyword x3, T4 stem italiano x2, T5 Levenshtein 1 x1.5; frasi multi-parola x3; soglia punteggio >= 6.
 */
class KeywordCategoryClassifier(keywords: Map<String, List<String>>) {
    private class Pair(val word: String, val cat: String)

    private val flat: List<Pair> = keywords.flatMap { (cat, words) -> words.map { Pair(fold(it), cat) } }
        .sortedByDescending { it.word.length }
    private val cache = object : LinkedHashMap<String, String>(16, 0.75f, true) {
        override fun removeEldestEntry(eldest: MutableMap.MutableEntry<String, String>?) = size > 2000
    }

    fun classify(name: String): String {
        val trimmed = name.trim { it == ' ' || it == '\t' }
        if (trimmed.isEmpty()) return OTHER
        synchronized(cache) { cache[trimmed]?.let { return it } }
        val norm = fold(trimmed)
        val words = norm.split(nonLetters).filter { it.length >= 2 }
        if (words.isEmpty()) return OTHER
        val scores = HashMap<String, Double>()
        for (pair in flat) {
            val kw = pair.word
            val parts = kw.split(" ").filter { it.isNotEmpty() }
            val score = if (parts.size > 1) {
                if (norm.contains(kw)) kw.length * 3.0 else 0.0
            } else {
                words.fold(0.0) { best, w -> maxOf(best, singleWordScore(w, kw)) } * kw.length
            }
            if (score > 0) scores[pair.cat] = (scores[pair.cat] ?: 0.0) + score
        }
        val best = scores.maxByOrNull { it.value }
        val result = if (best != null && best.value >= 6.0) best.key else OTHER
        synchronized(cache) { cache[trimmed] = result }
        return result
    }

    private fun singleWordScore(input: String, keyword: String): Double {
        if (input == keyword) return 4.0
        if (keyword.startsWith(input) && input.length >= 3) {
            val ratio = input.length.toDouble() / keyword.length
            if (ratio >= 0.60) return 2.5
            if (input.length >= 5) return 1.5
            return 0.0
        }
        if (input.startsWith(keyword)) {
            val ratio = keyword.length.toDouble() / input.length
            return if (ratio >= 0.60) 3.0 else 0.0
        }
        val iStem = stem(input)
        val kStem = stem(keyword)
        if (iStem.length >= 3 && iStem == kStem) return 2.0
        if (iStem.length >= 3 && (input == kStem || iStem == keyword)) return 2.0
        if (input.length >= 5 && keyword.length >= 5 && kotlin.math.abs(input.length - keyword.length) <= 2 &&
            levenshtein(input, keyword) == 1
        ) return 1.5
        return 0.0
    }

    companion object {
        const val OTHER = "Altro"
        private val nonLetters = Regex("[^\\p{L}\\p{M}]+")
        private val marks = Regex("\\p{Mn}+")
        private val suffixes = listOf(
            "abilita", "abilità", "issimo", "issima", "issimi", "issime", "azione", "azioni", "amento", "amenti",
            "imento", "imenti", "mente", "arsi", "ersi", "irsi", "ando", "endo", "are", "ere", "ire",
            "ato", "ata", "ati", "ate", "uto", "uta", "uti", "ute", "ito", "ita", "iti", "ite",
            "eria", "erie", "ario", "aria", "ino", "ina", "ini", "ine", "one", "oni", "gli", "he", "hi",
            "le", "li", "i", "e", "a", "o",
        )

        /** Minuscolo + rimozione dei diacritici. */
        fun fold(text: String): String = Normalizer.normalize(text.lowercase(), Normalizer.Form.NFD).replace(marks, "")

        private fun stem(word: String): String {
            for (s in suffixes) if (word.endsWith(s) && word.length - s.length >= 3) return word.dropLast(s.length)
            return word
        }

        private fun levenshtein(a: String, b: String): Int {
            if (a.isEmpty()) return b.length
            if (b.isEmpty()) return a.length
            var prev = IntArray(b.length + 1) { it }
            for (i in 1..a.length) {
                val curr = IntArray(b.length + 1)
                curr[0] = i
                for (j in 1..b.length) {
                    curr[j] = if (a[i - 1] == b[j - 1]) prev[j - 1] else 1 + minOf(prev[j - 1], prev[j], curr[j - 1])
                }
                prev = curr
            }
            return prev[b.length]
        }
    }
}
