package com.bucktrail.android.data

import com.bucktrail.android.domain.AuditDiff
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.rules.TemporaryFolder

class AuditLogTest {
    @get:Rule val tmp = TemporaryFolder()

    private fun ledger(vararg tx: TransactionEntity, accounts: List<AccountEntity> = emptyList(), budgets: List<BudgetEntity> = emptyList(), goals: List<GoalEntity> = emptyList()) =
        LedgerState(accounts = accounts, transactions = tx.toList(), budgets = budgets, goals = goals)
    private val t1 = TransactionEntity("1", null, "Pizza", 1_250, "Uscita", date = 1)

    @Test fun diffFindsCreatedUpdatedDeleted() {
        val before = ledger(t1).auditItems()
        val updated = ledger(t1.copy(amountCents = 2_000), TransactionEntity("2", null, "Stipendio", 150_000, "Entrata", date = 2)).auditItems()
        val events = AuditDiff.diff(before, updated)
        assertEquals(setOf("updated" to "Pizza — 20.00 (Uscita)", "created" to "Stipendio — 1500.00 (Entrata)"), events.map { it.action to it.summary }.toSet())
        val gone = AuditDiff.diff(updated, before)
        assertEquals(listOf(AuditDiff.Event(AuditDiff.TRANSACTION, "deleted", "—")), gone.filter { it.action == "deleted" })
    }

    @Test fun summariesMatchIosFormats() {
        val l = ledger(accounts = listOf(AccountEntity("a", "Conto", initialBalanceCents = 290_000)), budgets = listOf(BudgetEntity("b", null, "Cibo", monthlyLimitCents = 30_000, month = 11, year = 2026)),
            goals = listOf(GoalEntity("g", "Vacanza", targetCents = 280_000)))
        assertEquals(
            setOf("Conto — saldo iniziale 2900.00", "Cibo — 300.00/mese", "Vacanza — obiettivo 2800.00"),
            l.auditItems().map { it.summary }.toSet(),
        )
    }

    @Test fun unchangedStateProducesNoEvents() = assertTrue(AuditDiff.diff(ledger(t1).auditItems(), ledger(t1).auditItems()).isEmpty())

    @Test fun logIsAppendOnlyNewestFirstAndClearable() {
        val log = AuditLog(tmp.newFile("audit-log.jsonl"))
        log.append(listOf(AuditDiff.Event("Transaction", "created", "A — 1.00 (Uscita)")), now = 100)
        log.append(listOf(AuditDiff.Event("Account", "deleted", "—"), AuditDiff.Event("Goal", "updated", "G — obiettivo 5.00")), now = 200)
        val all = log.readAll()
        assertEquals(3, all.size)
        assertEquals(listOf("updated", "deleted", "created"), all.map { it.action })
        assertEquals(100L, all.last().timestamp)
        log.append(emptyList())
        assertEquals(3, log.readAll().size)
        log.clearAll()
        assertTrue(log.readAll().isEmpty())
        assertFalse(java.io.File(tmp.root, "audit-log.jsonl").exists())
    }
}
