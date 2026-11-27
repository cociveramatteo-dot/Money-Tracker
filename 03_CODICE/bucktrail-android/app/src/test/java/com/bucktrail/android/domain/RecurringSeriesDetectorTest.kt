package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class RecurringSeriesDetectorTest {
    private val zone: ZoneId = ZoneId.of("Europe/Rome")

    private fun instant(year: Int, month: Int, day: Int): Instant =
        LocalDate.of(year, month, day).atTime(12, 0).atZone(zone).toInstant()

    @Test
    fun requiresAtLeastThreeOccurrencesInThreeDistinctMonthsAndPreservesExactTotal() {
        val valid = listOf(
            TransactionData("1", null, "Palestra", BigDecimal("40.10"), Amounts.TYPE_EXPENSE, "Salute", date = instant(2026, 9, 5)),
            TransactionData("2", null, "Palestra", BigDecimal("40.20"), Amounts.TYPE_EXPENSE, "Salute", date = instant(2026, 10, 5)),
            TransactionData("3", null, "Palestra", BigDecimal("40.30"), Amounts.TYPE_EXPENSE, "Salute", date = instant(2026, 11, 5)),
        )
        val threeInTwoMonths = listOf(
            TransactionData("4", null, "Bar", BigDecimal("5.00"), Amounts.TYPE_EXPENSE, "Cibo", date = instant(2026, 10, 1)),
            TransactionData("5", null, "Bar", BigDecimal("5.00"), Amounts.TYPE_EXPENSE, "Cibo", date = instant(2026, 10, 15)),
            TransactionData("6", null, "Bar", BigDecimal("5.00"), Amounts.TYPE_EXPENSE, "Cibo", date = instant(2026, 11, 1)),
        )
        val twoInTwoMonths = listOf(
            TransactionData("7", null, "Volo", BigDecimal("200.00"), Amounts.TYPE_EXPENSE, "Viaggi", date = instant(2026, 9, 10)),
            TransactionData("8", null, "Volo", BigDecimal("220.00"), Amounts.TYPE_EXPENSE, "Viaggi", date = instant(2026, 10, 10)),
        )

        val result = RecurringSeriesDetector.detect(valid + threeInTwoMonths + twoInTwoMonths, zone)

        assertEquals(1, result.size)
        val habit = result[0]
        assertEquals("Palestra", habit.name)
        assertEquals(3, habit.count)
        assertEquals("mensile", habit.frequency)
        assertEquals(0, BigDecimal("120.60").compareTo(habit.totalAmount))
    }

    @Test
    fun excludesTransfersBalanceAdjustmentsAndUnconfirmedTransactions() {
        val transfers = (1..5).map { month ->
            TransactionData(
                "tr$month", null, "Giroconto", BigDecimal("180.00"), Amounts.TYPE_EXPENSE,
                "Giroconto", date = instant(2026, month, 5), isDone = true, isTransfer = true,
            )
        }
        val adjustments = (1..5).map { month ->
            TransactionData(
                "adj$month", null, "Rettifica", BigDecimal("50.00"), Amounts.TYPE_EXPENSE,
                Categories.ADJUSTMENT, date = instant(2026, month, 10), isDone = true,
            )
        }
        val unconfirmed = (1..4).map { month ->
            TransactionData(
                "unc$month", null, "Affitto futuro", BigDecimal("700.00"), Amounts.TYPE_EXPENSE,
                "Casa", date = instant(2026, month, 1), isDone = false,
            )
        }

        val result = RecurringSeriesDetector.detect(transfers + adjustments + unconfirmed, zone)
        assertTrue(result.isEmpty())
    }
}
