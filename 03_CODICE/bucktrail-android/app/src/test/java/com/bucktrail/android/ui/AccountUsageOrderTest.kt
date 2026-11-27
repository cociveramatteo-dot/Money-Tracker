package com.bucktrail.android.ui

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.forms.sortAccountsByUsage
import org.junit.Assert.assertEquals
import org.junit.Test

class AccountUsageOrderTest {
    private fun tx(accountId: String?) = TransactionEntity(
        id = java.util.UUID.randomUUID().toString(),
        accountId = accountId,
        name = "Test",
        amountCents = 1000,
        type = Amounts.TYPE_EXPENSE,
        date = 1_700_000_000_000L,
    )

    @Test
    fun sortsByUsageDescendingAndPreservesOrderOnTies() {
        val a1 = AccountEntity("a1", "Primo")
        val a2 = AccountEntity("a2", "Secondo")
        val a3 = AccountEntity("a3", "Terzo")
        val a4 = AccountEntity("a4", "Quarto")

        val history = listOf(
            tx("a3"), tx("a3"), tx("a3"),
            tx("a1"), tx("a2"), tx(null),
        )

        val ordered = sortAccountsByUsage(listOf(a1, a2, a3, a4), history)
        assertEquals(listOf("Terzo", "Primo", "Secondo", "Quarto"), ordered.map { it.name })
    }

    @Test
    fun emptyHistoryKeepsExistingOrder() {
        val a1 = AccountEntity("a1", "A")
        val a2 = AccountEntity("a2", "B")
        assertEquals(listOf("A", "B"), sortAccountsByUsage(listOf(a1, a2), emptyList()).map { it.name })
    }
}
