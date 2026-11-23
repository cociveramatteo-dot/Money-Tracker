package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Test

class CategoryTintTest {
    @Test fun defaultsAreFixed() {
        assertEquals(CategoryTint.Amber, CategoryTint.tint("Cibo"))
        assertEquals(CategoryTint.Blue, CategoryTint.tint("Trasporti"))
        assertEquals(CategoryTint.Violet, CategoryTint.tint("Svago"))
        assertEquals(CategoryTint.Green, CategoryTint.tint("Salute"))
        assertEquals(CategoryTint.Blue, CategoryTint.tint("Giroconto"))
    }

    @Test fun fnv1aIsStable() {
        assertEquals(2166136261L, CategoryTint.stableHash(""))
        assertEquals(0xE40C292CL, CategoryTint.stableHash("a"))
        assertEquals(0xBF9CF968L, CategoryTint.stableHash("foobar"))
    }

    @Test fun customCategoriesUseHashModFour() {
        for (name in listOf("Animali", "Palestra", "Hobby 🎸", "Caffè", "Rettifica saldo")) {
            assertEquals(CategoryTint.entries[(CategoryTint.stableHash(name) % 4).toInt()], CategoryTint.tint(name))
        }
    }
}
