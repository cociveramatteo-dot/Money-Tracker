package com.bucktrail.android.domain

import com.bucktrail.android.domain.BalanceTrail.Entry
import com.bucktrail.android.domain.BalanceTrail.Point
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneOffset

/** Vettori da BalanceTrailTests.swift (UTC, novembre 2026, oggi = 13). */
class BalanceTrailTest {
    private val zone = ZoneOffset.UTC
    private fun date(day: Int, month: Int = 11) = LocalDate.of(2026, month, day).atTime(12, 0).toInstant(ZoneOffset.UTC)
    private fun entry(day: Int, amount: String, done: Boolean, month: Int = 11) = Entry(date(day, month), BigDecimal(amount), done)
    private fun pt(day: Int, balance: String) = Point(day, BigDecimal(balance))
    private fun make(current: String, entries: List<Entry>, now: Int = 13) = BalanceTrail.make(BigDecimal(current), entries, date(now), zone)

    @Test fun noPlanned() {
        val t = make("100", listOf(entry(2, "-20", true), entry(10, "50", true)))
        assertEquals(13, t.today); assertEquals(30, t.daysInMonth); assertEquals(13, t.actual.size)
        assertEquals(pt(13, "100"), t.actual.last())
        assertEquals(pt(9, "50"), t.actual.first { it.day == 9 })
        assertEquals(pt(1, "70"), t.actual.first())
        assertTrue(t.projected.isEmpty()); assertTrue(t.plannedMarks.isEmpty()); assertFalse(t.hasPlanned)
        assertEquals(0, BigDecimal(100).compareTo(t.expectedBalance))
    }

    @Test fun projectionMatchesExpected() {
        val t = make("1000", listOf(entry(5, "-100", true), entry(20, "-300", false), entry(25, "50", false)))
        assertTrue(t.hasPlanned); assertEquals(2, t.plannedCount)
        assertEquals(0, BigDecimal(-250).compareTo(t.plannedDelta))
        assertEquals(0, BigDecimal(750).compareTo(t.expectedBalance))
        assertEquals(pt(13, "1000"), t.projected.first()); assertEquals(pt(30, "750"), t.projected.last())
        assertEquals(listOf(pt(20, "700"), pt(25, "750")), t.plannedMarks)
    }

    @Test fun overdueAndBeyondMonthStayInExpectedBalance() {
        val t = make("500", listOf(entry(3, "-40", false), entry(2, "-60", false, month = 12)))
        assertEquals(0, BigDecimal(400).compareTo(t.expectedBalance))
        assertEquals(pt(30, "400"), t.projected.last())
        assertEquals(listOf(pt(13, "460"), pt(30, "400")), t.plannedMarks)
    }

    @Test fun doneOutOfRangeDoesNotBreakTheSeries() {
        val t = make("200", listOf(entry(28, "-10", true), entry(20, "30", true, month = 10)))
        assertEquals(pt(13, "200"), t.actual.last())
        assertEquals(pt(12, "210"), t.actual.first { it.day == 12 })
        assertEquals(1, t.actual.first().day); assertEquals(0, BigDecimal(210).compareTo(t.actual.first().balance))
    }

    @Test fun emptyAndFirstDay() {
        val t = make("0", emptyList(), now = 1)
        assertEquals(listOf(pt(1, "0")), t.actual); assertTrue(t.projected.isEmpty())
    }

    @Test fun exactDecimal() {
        val t = make("10.10", listOf(entry(20, "-0.20", false)))
        assertEquals(0, BigDecimal("9.90").compareTo(t.expectedBalance))
    }
}
