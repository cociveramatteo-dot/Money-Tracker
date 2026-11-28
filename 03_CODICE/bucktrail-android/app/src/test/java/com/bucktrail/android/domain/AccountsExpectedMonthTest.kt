package com.bucktrail.android.domain

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.ui.WhatIfScenario
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId

class AccountsExpectedMonthTest {
    private val zone = ZoneId.of("UTC")
    private fun at(day: Int, month: Int) =
        LocalDate.of(2026, month, day).atTime(12, 0).atZone(zone).toInstant()

    @Test
    fun singleFixedExpenseCountsOnlyInItsMonth() {
        val account = AccountData("a1", "Conto", "Conto Bancario", BigDecimal("1000.00"))
        val decFixed = TransactionData(
            id = "t1", accountId = "a1", name = "Assicurazione",
            amount = BigDecimal("200.00"), type = Amounts.TYPE_EXPENSE,
            date = at(12, 12), isDone = false, isFixed = true,
        )
        assertEquals(0, BigDecimal("1000.00").compareTo(
            Balance.expectedInMonth(account, listOf(decFixed), LocalDate.of(2026, 11, 28), zone)
        ))
        assertEquals(0, BigDecimal("800.00").compareTo(
            Balance.expectedInMonth(account, listOf(decFixed), LocalDate.of(2026, 12, 1), zone)
        ))
    }

    @Test
    fun nonFixedRecurringAndDoneMovements() {
        val account = AccountData("a1", "Carta", "Carta", BigDecimal("1000.00"))
        val txs = listOf(
            TransactionData("t1", "a1", "Fatta", BigDecimal("100.00"), Amounts.TYPE_EXPENSE, date = at(10, 11), isDone = true),
            TransactionData("t2", "a1", "Cena", BigDecimal("50.00"), Amounts.TYPE_EXPENSE, date = at(29, 11), isDone = false, isFixed = false),
            TransactionData("t3", "a1", "Palestra", BigDecimal("40.00"), Amounts.TYPE_EXPENSE, date = at(30, 11), isDone = false, isFixed = true, templateId = "r1", recurringFrequency = "mensile"),
        )
        assertEquals(0, BigDecimal("900.00").compareTo(Balance.current(account, txs)))
        assertEquals(0, BigDecimal("810.00").compareTo(
            Balance.expectedInMonth(account, txs, LocalDate.of(2026, 11, 28), zone)
        ))
    }

    @Test
    fun accountWithoutPlannedMatchesCurrentAndTotalExcludesOtherMonthFixed() {
        val a1 = AccountData("a1", "Conto", "Conto Bancario", BigDecimal("1000.00"))
        val a2 = AccountData("a2", "Risparmi", "Risparmio", BigDecimal("2500.00"))
        val a3 = AccountData("a3", "Escluso", "Carta", BigDecimal("500.00"), isExcludedFromTotal = true)
        val txs = listOf(
            TransactionData("t1", "a1", "Fissa dic", BigDecimal("200.00"), Amounts.TYPE_EXPENSE, date = at(12, 12), isDone = false, isFixed = true),
            TransactionData("t2", "a2", "Versamento", BigDecimal("200.00"), Amounts.TYPE_INCOME, date = at(5, 11), isDone = true),
            TransactionData("t3", "a3", "Fissa dic escluso", BigDecimal("150.00"), Amounts.TYPE_EXPENSE, date = at(12, 12), isDone = false, isFixed = true),
        )
        val nov28 = LocalDate.of(2026, 11, 28)
        assertEquals(0, Balance.current(a2, txs).compareTo(Balance.expectedInMonth(a2, txs, nov28, zone)))
        assertEquals(0, BigDecimal("3700.00").compareTo(Balance.totalExpectedInMonth(listOf(a1, a2, a3), txs, nov28, zone)))

        val excludedEntity = AccountEntity("a3", "Escluso", "Carta", initialBalanceCents = 500_00, isExcludedFromTotal = true)
        val decTxEntity = TransactionEntity("t3", "a3", "Fissa dic escluso", amountCents = 150_00, type = Amounts.TYPE_EXPENSE, date = at(12, 12).toEpochMilli(), isDone = false, isFixed = true)
        val projection = HomeProjection.make(listOf(a1, a2, a3), txs, nov28, zone)
        val baselines = WhatIfScenario.baselines(listOf(excludedEntity), listOf(decTxEntity), projection, emptyMap(), nov28, zone)
        assertEquals(0, BigDecimal("500.00").compareTo(baselines.last().endOfMonth))
    }
}
