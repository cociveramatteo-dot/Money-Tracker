package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.time.Instant

class ClassifierTest {
    private val classifier = KeywordCategoryClassifier(mapOf(
        "Cibo" to listOf("pizza", "supermercato", "ristorante"),
        "Trasporti" to listOf("benzina", "treno", "autobus"),
        "Svago" to listOf("cinema", "netflix"),
    ))

    @Test fun exactMatch() {
        assertEquals("Cibo", classifier.classify("pizza"))
        assertEquals("Trasporti", classifier.classify("benzina"))
    }
    @Test fun containsKeyword() {
        assertEquals("Cibo", classifier.classify("Pizza da Mario"))
        assertEquals("Svago", classifier.classify("Netflix abbonamento mensile"))
    }
    @Test fun noMatchEmptyAndEmptyDictionary() {
        assertEquals("Altro", classifier.classify("xyz123 sconosciuto"))
        assertEquals("Altro", classifier.classify(""))
        assertEquals("Altro", classifier.classify("   "))
        assertEquals("Altro", KeywordCategoryClassifier(emptyMap()).classify("pizza"))
    }
    @Test fun italianPluralMatchesViaStemming() = assertEquals("Cibo", classifier.classify("Cena al ristoranti del porto"))

    private fun m(name: String = "Mc", cat: String = "Cibo", at: Long = 1, done: Boolean = true, transfer: Boolean = false) =
        LastUsedCategory.Movement(name, cat, Instant.ofEpochSecond(at), done, transfer)
    private fun suggest(name: String, h: List<LastUsedCategory.Movement>, cats: Set<String> = setOf("Cibo", "Svago", "Altro")) =
        LastUsedCategory.suggest(name, h, cats)

    @Test fun lastUsedBasics() {
        assertNull(suggest("Mc", emptyList()))
        assertNull(suggest("Nuovo", listOf(m()))); assertNull(suggest("M", listOf(m()))); assertNull(suggest("Mcc", listOf(m())))
        assertNull(suggest("  ", listOf(m(" "))))
        assertEquals("Cibo", suggest("  CAFE\u0301   del\tPORTO ", listOf(m("Café del Porto"))))
    }
    @Test fun lastUsedLatestWinsRegardlessOfOrder() {
        val h = listOf(m("Mc", "Svago", 3), m("Mc", "Cibo", 1))
        assertEquals("Svago", suggest("mc", h)); assertEquals("Svago", suggest("mc", h.reversed()))
    }
    @Test fun lastUsedIgnoresPlannedTransfersAndDeletedCategories() {
        assertEquals("Cibo", suggest("Mc", listOf(m(), m("Mc", "Svago", 3, done = false), m("Mc", "Svago", 4, transfer = true))))
        assertNull(suggest("Mc", listOf(m(done = false), m(transfer = true))))
        assertNull(suggest("Mc", listOf(m(), m("Mc", "Eliminata", 2))))
        assertNull(suggest("Mc", listOf(m()), emptySet()))
        assertEquals("Altro", suggest("Mc", listOf(m("Mc", "Altro"))))
    }
}
