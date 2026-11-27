package com.bucktrail.android.ui

import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

class MovementSectionTotalsTest {
    private val zone: ZoneId = ZoneId.of("Europe/Rome")

    private fun millis(year: Int, month: Int, day: Int): Long =
        LocalDate.of(year, month, day).atTime(12, 0).atZone(zone).toInstant().toEpochMilli()

    private fun occurrence(amount: BigDecimal, type: String, isFixed: Boolean = true): Occurrence {
        val instant = LocalDate.of(2026, 12, 10).atTime(12, 0).atZone(zone).toInstant()
        return Occurrence(
            ruleId = UUID.randomUUID(),
            key = UUID.randomUUID().toString(),
            originalDate = instant,
            date = instant,
            amount = amount,
            name = "Virtual",
            category = "Casa",
            categoryIcon = "house",
            type = type,
            accountId = null,
            isFixed = isFixed,
            notes = "",
            isOverridden = false,
        )
    }

    @Test
    fun tuttiExcludesTransfersAndIncludesDonePlannedAndVirtual() {
        val doneExpense = TransactionEntity(id = "1", name = "Spesa", amountCents = 4200, type = Amounts.TYPE_EXPENSE, category = "Cibo", date = millis(2026, 11, 5), isDone = true)
        val plannedExpense = TransactionEntity(id = "2", name = "Bolletta", amountCents = 8000, type = Amounts.TYPE_EXPENSE, category = "Casa", date = millis(2026, 12, 5), isDone = false, isFixed = true)
        val doneIncome = TransactionEntity(id = "3", name = "Rimborso", amountCents = 15000, type = Amounts.TYPE_INCOME, category = "Altro", date = millis(2026, 11, 8), isDone = true)
        val transfer = TransactionEntity(id = "4", name = "Giroconto", amountCents = 50000, type = Amounts.TYPE_EXPENSE, category = "Giroconto", date = millis(2026, 11, 10), isDone = true, isFixed = true, isTransfer = true, transferGroupId = "grp1")
        val virtualIncome = occurrence(BigDecimal("2000.00"), Amounts.TYPE_INCOME)
        val virtualExpense = occurrence(BigDecimal("30.00"), Amounts.TYPE_EXPENSE)

        val totals = MovementSectionTotals.compute(
            real = listOf(doneExpense, plannedExpense, doneIncome, transfer),
            virtual = listOf(virtualIncome, virtualExpense),
        )

        assertEquals(0, BigDecimal("152.00").compareTo(totals.expenses))
        assertEquals(0, BigDecimal("2150.00").compareTo(totals.income))
        assertEquals(0, BigDecimal("500.00").compareTo(totals.transferred))
    }

    @Test
    fun fisseExcludesFixedTransfers() {
        val fixedExpense = TransactionEntity(id = "1", name = "Affitto", amountCents = 80000, type = Amounts.TYPE_EXPENSE, category = "Casa", date = millis(2026, 11, 1), isDone = true, isFixed = true)
        val fixedTransfer = TransactionEntity(id = "2", name = "PAC", amountCents = 25000, type = Amounts.TYPE_EXPENSE, category = "Giroconto", date = millis(2026, 11, 2), isDone = true, isFixed = true, isTransfer = true, transferGroupId = "g1")
        val fixedVirtualIncome = occurrence(BigDecimal("1200.00"), Amounts.TYPE_INCOME, isFixed = true)

        val totals = MovementSectionTotals.compute(listOf(fixedExpense, fixedTransfer), listOf(fixedVirtualIncome))
        assertEquals(0, BigDecimal("800.00").compareTo(totals.expenses))
        assertEquals(0, BigDecimal("1200.00").compareTo(totals.income))
        assertEquals(0, BigDecimal("250.00").compareTo(totals.transferred))
    }

    @Test
    fun trasferitoDeduplicatesByGroupIdAndCountsOrphanLegsIndividually() {
        val leg1 = TransactionEntity(id = "1", name = "Giro", amountCents = 30000, type = Amounts.TYPE_EXPENSE, category = "Giroconto", date = millis(2026, 11, 3), isDone = true, isTransfer = true, transferGroupId = "ABC-123")
        val leg2 = TransactionEntity(id = "2", name = "Giro", amountCents = 30000, type = Amounts.TYPE_INCOME, category = "Giroconto", date = millis(2026, 11, 3), isDone = true, isTransfer = true, transferGroupId = "abc-123")
        val orphan1 = TransactionEntity(id = "3", name = "O1", amountCents = 5000, type = Amounts.TYPE_EXPENSE, category = "Giroconto", date = millis(2026, 11, 4), isDone = true, isTransfer = true, transferGroupId = "")
        val orphan2 = TransactionEntity(id = "4", name = "O2", amountCents = 7500, type = Amounts.TYPE_INCOME, category = "Giroconto", date = millis(2026, 11, 5), isDone = false, isTransfer = true, transferGroupId = "")

        val totals = MovementSectionTotals.compute(listOf(leg1, leg2, orphan1, orphan2), emptyList())
        assertEquals(0, BigDecimal("425.00").compareTo(totals.transferred))
        assertEquals(0, BigDecimal.ZERO.compareTo(totals.expenses))
        assertEquals(0, BigDecimal.ZERO.compareTo(totals.income))
    }

    @Test
    fun emptyListReturnsZero() {
        val totals = MovementSectionTotals.compute(emptyList(), emptyList())
        assertEquals(0, BigDecimal.ZERO.compareTo(totals.expenses))
        assertEquals(0, BigDecimal.ZERO.compareTo(totals.income))
        assertEquals(0, BigDecimal.ZERO.compareTo(totals.transferred))
    }

    @Test
    fun decimalPrecisionExactForClassicBinaryTrapsAndHundredCentsRows() {
        val t1 = TransactionEntity(id = "1", name = "Uno", amountCents = 10, type = Amounts.TYPE_EXPENSE, category = "Cibo", date = millis(2026, 11, 1), isDone = true)
        val t2 = TransactionEntity(id = "2", name = "Due", amountCents = 20, type = Amounts.TYPE_EXPENSE, category = "Cibo", date = millis(2026, 11, 2), isDone = true)
        val classic = MovementSectionTotals.compute(listOf(t1, t2), emptyList())
        assertEquals(0, BigDecimal("0.30").compareTo(classic.expenses))

        val hundred = (0 until 100).map { i ->
            TransactionEntity(id = "r$i", name = "R$i", amountCents = 119, type = Amounts.TYPE_EXPENSE, category = "Cibo", date = millis(2026, 11, 1), isDone = true)
        }
        val many = MovementSectionTotals.compute(hundred, emptyList())
        assertEquals(0, BigDecimal("119.00").compareTo(many.expenses))
    }
}
