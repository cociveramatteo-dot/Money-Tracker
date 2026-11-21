package com.bucktrail.android

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test

class AmountsTest {
    @Test fun keepsExactCents() {
        assertEquals(2450L, parseCents("24,50")!!)
        assertEquals(-124L, parseCents("-1.24")!!)
        assertEquals(1L, parseCents("0,01")!!)
    }

    @Test fun rejectsAmbiguousOrUnrepresentableAmounts() {
        listOf("1.024,50", "1,234", "1e3", "", "12345678901").forEach {
            assertNull(it, parseCents(it))
        }
    }
}
