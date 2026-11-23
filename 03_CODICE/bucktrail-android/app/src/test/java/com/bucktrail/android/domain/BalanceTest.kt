package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant

class BalanceTest {
    private val t0 = Instant.parse("2026-11-10T12:00:00Z")
    private fun tx(id: String, account: String, amount: String, type: String, done: Boolean) =
        TransactionData(id, account, id, BigDecimal(amount), type, date = t0, isDone = done)

    @Test fun currentSumsOnlyDoneAndFutureSumsAll() {
        val a = AccountData("a", "Conto", "Conto Bancario", BigDecimal(100))
        val txs = listOf(tx("1", "a", "30", "Uscita", true), tx("2", "a", "50", "Uscita", false))
        assertEquals(BigDecimal(70), Balance.current(a, txs))
        assertEquals(BigDecimal(20), Balance.future(a, txs))
        assertEquals(BigDecimal(-50), Balance.plannedDelta(a, txs))
    }

    @Test fun decimalAvoidsBinaryRoundingErrors() {
        val a = AccountData("a", "Conto", "Conto Bancario", BigDecimal.ZERO)
        val txs = listOf(tx("1", "a", "0.1", "Entrata", true), tx("2", "a", "0.2", "Entrata", true))
        assertEquals(0, BigDecimal("0.3").compareTo(Balance.current(a, txs)))
    }

    @Test fun totalsSkipArchivedAndExcludedAccounts() {
        val a = AccountData("a", "A", "Contanti", BigDecimal(10))
        val b = AccountData("b", "B", "Carta", BigDecimal(20), isArchived = true)
        val c = AccountData("c", "C", "Risparmio", BigDecimal(30), isExcludedFromTotal = true)
        val txs = listOf(tx("1", "a", "5", "Uscita", false))
        assertEquals(BigDecimal(10), Balance.total(listOf(a, b, c), txs))
        assertEquals(BigDecimal(5), Balance.totalFuture(listOf(a, b, c), txs))
    }
}
