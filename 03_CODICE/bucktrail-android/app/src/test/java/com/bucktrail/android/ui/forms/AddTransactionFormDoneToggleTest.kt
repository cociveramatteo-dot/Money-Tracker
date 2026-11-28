package com.bucktrail.android.ui.forms

import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.time.LocalDate

class AddTransactionFormDoneToggleTest {
    private val today = LocalDate.of(2026, 11, 28)
    private val past = LocalDate.of(2026, 10, 15)
    private val future = LocalDate.of(2026, 12, 10)

    @Test
    fun overdueNonFixedPlannedShowsDoneToggleOnlyWhenPlannedOnOpen() {
        assertFalse(shouldShowDoneToggle(fixed = false, date = past, today = today, wasPlannedOnOpen = false))
        assertTrue(shouldShowDoneToggle(fixed = false, date = past, today = today, wasPlannedOnOpen = true))
    }

    @Test
    fun todayDoneNonFixedHidesToggleWhileFixedOrFutureAlwaysShows() {
        assertFalse(shouldShowDoneToggle(fixed = false, date = today, today = today, wasPlannedOnOpen = false))
        assertTrue(shouldShowDoneToggle(fixed = true, date = past, today = today, wasPlannedOnOpen = false))
        assertTrue(shouldShowDoneToggle(fixed = false, date = future, today = today, wasPlannedOnOpen = false))
    }
}
