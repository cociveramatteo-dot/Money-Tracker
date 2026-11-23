package com.bucktrail.android.domain

import com.bucktrail.android.domain.TransactionFiltering.Criteria
import com.bucktrail.android.domain.TransactionFiltering.Row
import com.bucktrail.android.domain.TransactionFiltering.TypeFilter
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

class TransactionFilteringTest {
    private val zone = ZoneId.of("Europe/Rome")
    private fun row(name: String, day: String, amount: String = "10", type: String = Amounts.TYPE_EXPENSE, fixed: Boolean = false,
                    transfer: Boolean = false, category: String = "Cibo") =
        Row(name, type, fixed, transfer, category, BigDecimal(amount), LocalDate.parse(day).atTime(12, 0).atZone(zone).toInstant())

    private val rows = listOf(
        row("Caffè Città", "2026-11-05", "1.50"),
        row("Affitto", "2026-11-01", "800", fixed = true, category = "Casa"),
        row("Stipendio", "2026-11-27", "2000", Amounts.TYPE_INCOME, category = "Lavoro"),
        row("Trasferimento → Risparmi", "2026-11-10", "200", transfer = true, category = "Giroconto"),
        row("Pizza", "2026-10-30", "12"),
    )
    private val nov = YearMonth.of(2026, 11)
    private fun names(c: Criteria) = TransactionFiltering.filter(rows, c, zone) { it }.map { it.name }

    @Test fun monthOnly() = assertEquals(listOf("Caffè Città", "Affitto", "Stipendio", "Trasferimento → Risparmi"), names(Criteria(month = nov)))

    @Test fun searchIgnoresMonthAndDiacritics() {
        assertEquals(listOf("Caffè Città"), names(Criteria(query = "citta", month = YearMonth.of(2026, 1))))
        assertEquals(listOf("Pizza"), names(Criteria(query = "PIZ", month = nov)))
    }

    @Test fun typeChips() {
        assertEquals(listOf("Affitto"), names(Criteria(type = TypeFilter.Fixed, month = nov)))
        assertEquals(listOf("Trasferimento → Risparmi"), names(Criteria(type = TypeFilter.Transfer, month = nov)))
        assertEquals(listOf("Caffè Città", "Affitto"), names(Criteria(type = TypeFilter.Expense, month = nov)))
        assertEquals(listOf("Stipendio"), names(Criteria(type = TypeFilter.Income, month = nov)))
    }

    @Test fun categoryAndAmountBounds() {
        assertEquals(listOf("Affitto"), names(Criteria(category = "Casa", month = nov)))
        assertEquals(listOf("Affitto", "Stipendio"), names(Criteria(month = nov, minText = "500")))
        assertEquals(listOf("Caffè Città"), names(Criteria(month = nov, maxText = "1,5")))
        assertEquals(listOf("Trasferimento → Risparmi"), names(Criteria(month = nov, minText = "100", maxText = "800.00", type = TypeFilter.Transfer)))
    }

    @Test fun customPeriodReplacesMonth() {
        val c = Criteria(month = nov, useDates = true, from = LocalDate.parse("2026-10-30"), to = LocalDate.parse("2026-11-05"))
        assertEquals(listOf("Caffè Città", "Affitto", "Pizza"), names(c))
    }

    @Test fun badgeCountAndSummary() {
        assertEquals(0, TransactionFiltering.activeCount("", "", false))
        assertEquals(3, TransactionFiltering.activeCount("1", "2", true))
        assertEquals(TransactionFiltering.SummaryKind.AtLeast, TransactionFiltering.summaryKind("1", "", false))
        assertEquals(TransactionFiltering.SummaryKind.AtMost, TransactionFiltering.summaryKind("", "9", false))
        assertEquals(TransactionFiltering.SummaryKind.Range, TransactionFiltering.summaryKind("1", "9", false))
        assertEquals(TransactionFiltering.SummaryKind.Count, TransactionFiltering.summaryKind("1", "9", true))
        assertEquals(TransactionFiltering.SummaryKind.Count, TransactionFiltering.summaryKind("", "", true))
    }
}
