package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

class FuturePlannedRulesTest {
    private val zone = ZoneId.of("UTC")
    private fun at(day: Int, month: Int) =
        LocalDate.of(2026, month, day).atTime(12, 0).atZone(zone).toInstant()

    @Test
    fun singlePlannedMovementsCountOnlyInTheirMonth() {
        val nov = YearMonth.of(2026, 11)
        val dec = YearMonth.of(2026, 12)

        val nonFixedNextMonth = TransactionData("t1", "a1", "Cena", BigDecimal("60"), Amounts.TYPE_EXPENSE, date = at(10, 12), isDone = false, isFixed = false)
        val incomeNextMonth = TransactionData("t2", "a1", "Stipendio", BigDecimal("1500"), Amounts.TYPE_INCOME, date = at(10, 12), isDone = false, isFixed = true)
        val nonFixedThisMonth = TransactionData("t3", "a1", "Pranzo", BigDecimal("25"), Amounts.TYPE_EXPENSE, date = at(29, 11), isDone = false, isFixed = false)
        val recurringNextMonth = TransactionData("t4", "a1", "Affitto", BigDecimal("700"), Amounts.TYPE_EXPENSE, date = at(10, 12), isDone = false, isFixed = true, templateId = "r1")
        val transferNextMonth = TransactionData("t5", "a1", "Giro", BigDecimal("100"), Amounts.TYPE_EXPENSE, date = at(10, 12), isDone = false, isTransfer = true)

        assertFalse(HomeProjection.countsInMonth(nonFixedNextMonth, nov, zone))
        assertFalse(HomeProjection.countsInMonth(incomeNextMonth, nov, zone))
        assertTrue(HomeProjection.countsInMonth(nonFixedNextMonth, dec, zone))
        assertTrue(HomeProjection.countsInMonth(incomeNextMonth, dec, zone))
        assertTrue(HomeProjection.countsInMonth(nonFixedThisMonth, nov, zone))
        assertTrue(HomeProjection.countsInMonth(recurringNextMonth, nov, zone))
        assertTrue(HomeProjection.countsInMonth(transferNextMonth, nov, zone))

        val account = AccountData("a1", "Conto", "Conto Bancario", BigDecimal("1000.00"))
        val projection = HomeProjection.make(listOf(account), listOf(nonFixedNextMonth, incomeNextMonth, nonFixedThisMonth), LocalDate.of(2026, 11, 28), zone)
        assertEquals(0, BigDecimal("975.00").compareTo(projection.trail.expectedBalance))
    }

    @Test
    fun swipeAllowsPlanningDoneMovementsWithFutureDate() {
        assertTrue(SwipeRules.canToggleDone(isFixed = false, isDone = true, isFutureDate = true))
        assertFalse(SwipeRules.canToggleDone(isFixed = false, isDone = true, isFutureDate = false))
    }
}
