package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class HomeAccountOrderTest {
    private val all = listOf("a", "b", "c", "d")

    @Test fun emptySavedListStartsWithEverythingSelected() {
        val s = HomeAccountOrder.load(emptyList(), all)
        assertEquals(all, s.items); assertEquals(all.toSet(), s.shown)
    }

    @Test fun savedOrderFirstThenNewAccounts() {
        val s = HomeAccountOrder.load(listOf("c", "a", "gone"), all)
        assertEquals(listOf("c", "a", "b", "d"), s.items); assertEquals(setOf("c", "a", "gone"), s.shown)
    }

    @Test fun lastSelectedCannotBeDeselected() {
        var s = HomeAccountOrder.State(all, setOf("a", "b"))
        s = HomeAccountOrder.toggle(s, "a"); assertEquals(setOf("b"), s.shown)
        s = HomeAccountOrder.toggle(s, "b"); assertEquals(setOf("b"), s.shown)
    }

    @Test fun selectingMovesAfterLastSelected() {
        val s = HomeAccountOrder.toggle(HomeAccountOrder.State(all, setOf("a", "b")), "d")
        assertEquals(listOf("a", "b", "d", "c"), s.items); assertEquals(setOf("a", "b", "d"), s.shown)
    }

    @Test fun saveKeepsOrderOfSelectedOnly() =
        assertEquals(listOf("c", "a"), HomeAccountOrder.save(HomeAccountOrder.State(listOf("c", "b", "a"), setOf("a", "c"))))

    @Test fun moveAndBounds() {
        assertEquals(listOf("b", "a", "c"), HomeAccountOrder.move(listOf("a", "b", "c"), 0, 1))
        assertEquals(listOf("a", "b", "c"), HomeAccountOrder.move(listOf("a", "b", "c"), 0, -1))
    }

    @Test fun newAccountGoesFirstOnlyWhenListExists() {
        assertEquals(emptyList<String>(), HomeAccountOrder.withNewAccount(emptyList(), "n"))
        assertEquals(listOf("n", "a"), HomeAccountOrder.withNewAccount(listOf("a"), "n"))
    }
}
