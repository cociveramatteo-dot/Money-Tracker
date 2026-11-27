package com.bucktrail.android.ui

import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.RecurrenceCalculator
import com.bucktrail.android.ui.screens.NextMonthSummary
import com.bucktrail.android.ui.screens.computeNextMonthSummary
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.UUID

class NextMonthSummaryTest {
    private val zone: ZoneId = ZoneId.of("Europe/Rome")

    private fun millis(year: Int, month: Int, day: Int): Long =
        LocalDate.of(year, month, day).atTime(12, 0).atZone(zone).toInstant().toEpochMilli()

    @Test
    fun computesFixedAndIncomeTotalsWithVirtualsAndDeduplication() {
        val nextMonth = YearMonth.of(2026, 12)
        val today = LocalDate.of(2026, 11, 27)
        val ruleId = UUID.randomUUID().toString()
        val rule = RecurringRuleEntity(
            id = ruleId,
            name = "Palestra",
            amountCents = 6000,
            category = "Salute",
            categoryIcon = "figure.run",
            type = Amounts.TYPE_EXPENSE,
            frequency = "mensile",
            startDate = millis(2026, 11, 20),
            isFixed = true,
        )
        val extraRule = RecurringRuleEntity(
            id = UUID.randomUUID().toString(),
            name = "Consulenza",
            amountCents = 30000,
            category = "Lavoro",
            categoryIcon = "briefcase",
            type = Amounts.TYPE_INCOME,
            frequency = "mensile",
            startDate = millis(2026, 11, 22),
            isFixed = false,
        )
        // Materialized occurrence for December 20 should deduplicate virtual occurrence from `rule`
        val materializedId = RecurrenceCalculator.occurrenceId(UUID.fromString(ruleId), "2026-12-20").toString()
        val txs = listOf(
            TransactionEntity(id = materializedId, name = "Palestra", amountCents = 6000, type = Amounts.TYPE_EXPENSE, category = "Salute", date = millis(2026, 12, 20), isFixed = true),
            TransactionEntity(id = "t1", name = "Affitto", amountCents = 80000, type = Amounts.TYPE_EXPENSE, category = "Casa", date = millis(2026, 12, 5), isFixed = true),
            TransactionEntity(id = "t2", name = "Stipendio", amountCents = 200000, type = Amounts.TYPE_INCOME, category = "Stipendio", date = millis(2026, 12, 10), isFixed = true),
            TransactionEntity(id = "t3", name = "Rimborso", amountCents = 15000, type = Amounts.TYPE_INCOME, category = "Altro", date = millis(2026, 12, 15), isFixed = false),
            TransactionEntity(id = "t4", name = "Giroconto", amountCents = 50000, type = Amounts.TYPE_EXPENSE, category = "Trasf", date = millis(2026, 12, 12), isFixed = true, isTransfer = true),
            TransactionEntity(id = "t5", name = "Gennaio", amountCents = 99900, type = Amounts.TYPE_EXPENSE, category = "Casa", date = millis(2027, 1, 5), isFixed = true),
        )

        val summary = computeNextMonthSummary(txs, listOf(rule, extraRule), nextMonth, today, category = null, zone = zone)
        assertEquals(
            NextMonthSummary(
                fixedExpenses = BigDecimal("860.00"),
                fixedIncome = BigDecimal("2000.00"),
                income = BigDecimal("2450.00"),
            ),
            summary,
        )
    }

    @Test
    fun respectsCategoryFilterAndSkipsVirtualsForNonFutureMonths() {
        val december = YearMonth.of(2026, 12)
        val janToday = LocalDate.of(2026, 12, 5)
        val rule = RecurringRuleEntity(
            id = UUID.randomUUID().toString(),
            name = "Abbonamento",
            amountCents = 2500,
            category = "Salute",
            categoryIcon = "figure.run",
            type = Amounts.TYPE_EXPENSE,
            frequency = "mensile",
            startDate = millis(2026, 11, 15),
            isFixed = true,
        )
        val casa = TransactionEntity(id = "c1", name = "Affitto", amountCents = 70000, type = Amounts.TYPE_EXPENSE, category = "Casa", date = millis(2026, 12, 3), isFixed = true)

        val currentMonthSummary = computeNextMonthSummary(listOf(casa), listOf(rule), december, janToday, category = null, zone = zone)
        assertEquals(0, BigDecimal("700.00").compareTo(currentMonthSummary.fixedExpenses))

        val futureNextMonth = YearMonth.of(2027, 1)
        val saluteOnly = computeNextMonthSummary(listOf(casa), listOf(rule), futureNextMonth, janToday, category = "Salute", zone = zone)
        assertEquals(0, BigDecimal("25.00").compareTo(saluteOnly.fixedExpenses))
    }
}
