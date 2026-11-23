package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId

class StatisticsTest {
    private val zone = ZoneId.of("Europe/Rome")
    private fun tx(date: String, amount: String, type: String, category: String = "Cibo", done: Boolean = true, transfer: Boolean = false) =
        TransactionData("$date$amount$category", "a", "t", BigDecimal(amount), type, category, date = Instant.parse("${date}T10:00:00Z"), isDone = done, isTransfer = transfer)

    private val txs = listOf(
        tx("2026-11-03", "100", "Uscita", "Cibo"), tx("2026-11-10", "50.50", "Uscita", "Svago"), tx("2026-11-12", "30", "Uscita", "Cibo"),
        tx("2026-11-15", "1000", "Entrata", "Lavoro"), tx("2026-11-20", "999", "Uscita", "Cibo", done = false),
        tx("2026-11-21", "180", "Uscita", "Giroconto", transfer = true), tx("2026-10-05", "200", "Uscita"), tx("2025-06-01", "40", "Uscita"),
    )
    private val byMonth = Statistics.byMonth(txs, zone)
    private val nov = YearMonth.of(2026, 11)

    @Test fun totalsIgnorePlannedAndTransfers() {
        val t = Statistics.totalsOf(nov, byMonth)
        assertEquals(BigDecimal("180.50"), t.expenses)
        assertEquals(BigDecimal("1000"), t.income)
    }

    @Test fun categoriesSortedByAmountDescending() {
        val cats = Statistics.categories(txs, nov, zone)
        assertEquals(listOf("Cibo", "Svago"), cats.map { it.name })
        assertEquals(BigDecimal("130"), cats[0].amount)
        assertEquals(72, Statistics.percentOfTotal(cats[0].amount, BigDecimal("180.50")))
    }

    @Test fun trendEndsAtSelectedMonthOldestFirst() {
        val trend = Statistics.trend(byMonth, nov, 6)
        assertEquals(6, trend.size)
        assertEquals(YearMonth.of(2026, 6), trend.first().month)
        assertEquals(nov, trend.last().month)
        assertEquals(BigDecimal("200"), trend[4].expenses)
    }

    @Test fun averageUsesOnlyMonthsWithValue() {
        val l12 = Statistics.trend(byMonth, nov, 12)
        // ottobre 200 e novembre 180,50 (giugno 2025 è fuori dai 12 mesi): media su 2 mesi, non su 12
        assertEquals(0, BigDecimal("190.25").compareTo(Statistics.averageExpenses(l12).setScale(2, java.math.RoundingMode.HALF_UP)))
        assertEquals(0, BigDecimal("1000").compareTo(Statistics.averageIncome(l12).setScale(0, java.math.RoundingMode.HALF_UP)))
        assertEquals(BigDecimal.ZERO, Statistics.averageExpenses(emptyList()))
    }

    @Test fun yearTotalsAndDelta() {
        assertEquals(BigDecimal("380.50"), Statistics.yearTotals(byMonth, 2026).expenses)
        assertEquals(BigDecimal("40"), Statistics.yearTotals(byMonth, 2025).expenses)
        assertEquals(851, Statistics.deltaPercent(BigDecimal("380.50"), BigDecimal("40")))
        assertTrue(Statistics.prevMonthSpent(byMonth, nov).signum() > 0)
        assertEquals(BigDecimal("200"), Statistics.prevMonthSpent(byMonth, nov))
    }

    @Test fun percentOfZeroTotalIsZero() = assertEquals(0, Statistics.percentOfTotal(BigDecimal.TEN, BigDecimal.ZERO))
}
