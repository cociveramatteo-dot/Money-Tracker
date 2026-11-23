package com.bucktrail.android.data

import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Categories
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal

class TransactionOpsTest {
    private val input = TransactionOps.TransferInput("A1", "Conto", "A2", "Risparmi", 12_345, 1_000L, true, "nota")

    @Test fun newTransferHasTwoLinkedLegs() {
        val (out, inn) = TransactionOps.newTransfer(input, now = 5L, groupId = "G-1")
        assertEquals("A1", out.accountId); assertEquals("A2", inn.accountId)
        assertEquals("Trasferimento → Risparmi", out.name); assertEquals("Trasferimento ← Conto", inn.name)
        assertEquals(Amounts.TYPE_EXPENSE, out.type); assertEquals(Amounts.TYPE_INCOME, inn.type)
        assertEquals(12_345, out.amountCents); assertEquals(12_345, inn.amountCents)
        assertEquals("G-1", out.transferGroupId); assertEquals("G-1", inn.transferGroupId)
        assertTrue(out.isTransfer && inn.isTransfer && !out.isFixed)
        assertEquals(Categories.TRANSFER, out.category); assertEquals(Categories.TRANSFER_ICON, inn.categoryIcon)
        assertTrue(out.id != inn.id)
    }

    @Test fun generatedGroupIdIsUppercaseUuid() {
        val group = TransactionOps.newTransfer(input).first().transferGroupId
        assertEquals(group.uppercase(), group); assertEquals(36, group.length)
    }

    @Test fun updateKeepsIdsAndGroupAndChangesBothLegs() {
        val (out, inn) = TransactionOps.newTransfer(input, groupId = "G-1")
        val edited = TransactionOps.updateTransfer(out, inn, input.copy(toId = "A3", toName = "Cassa", amountCents = 500, done = false, notes = "x"))
        assertEquals(listOf(out.id, inn.id), edited.map { it.id })
        assertEquals("Trasferimento → Cassa", edited[0].name); assertEquals("A3", edited[1].accountId)
        assertTrue(edited.all { it.amountCents == 500L && !it.isDone && it.notes == "x" && it.transferGroupId == "G-1" })
    }

    @Test fun twinsMatchByGroupIgnoringCaseAndSelf() {
        val (out, inn) = TransactionOps.newTransfer(input, groupId = "G-1")
        val other = out.copy(id = "zzz", transferGroupId = "g-9")
        val all = listOf(out, inn, other)
        assertEquals(listOf(inn.id), TransactionOps.twinsOf(out.copy(transferGroupId = "g-1"), all).map { it.id })
        assertTrue(TransactionOps.twinsOf(out.copy(isTransfer = false), all).isEmpty())
    }

    @Test fun toggleDoneAppliesToBothLegs() {
        val (out, inn) = TransactionOps.newTransfer(input.copy(done = false))
        val toggled = TransactionOps.withDone(out, listOf(inn), true)
        assertTrue(toggled.all { it.isDone })
    }

    @Test fun adjustmentUsesAbsoluteAmountAndSign() {
        val change = AccountEditing.BalanceChange.Adjust(BigDecimal("-12.34"))
        val adj = TransactionOps.adjustment("A1", change, "Rettifica saldo", "arrow.triangle.2.circlepath", 99L)
        assertEquals(1234, adj.amountCents); assertEquals(Amounts.TYPE_EXPENSE, adj.type)
        assertEquals(Categories.ADJUSTMENT, adj.category); assertTrue(adj.isDone); assertEquals(99L, adj.date)
    }
}
