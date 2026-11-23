package com.bucktrail.android.domain

import com.bucktrail.android.domain.Budgeting.BudgetData
import com.bucktrail.android.domain.Budgeting.GoalData
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneOffset

class BudgetingTest {
    private fun tx(amount: String, cat: String, account: String? = "a", done: Boolean = true, transfer: Boolean = false, month: Int = 11, type: String = "Uscita") =
        TransactionData("t$amount$cat$month", account, "x", BigDecimal(amount), type, cat,
            date = Instant.parse("2026-%02d-10T12:00:00Z".format(month)), isDone = done, isTransfer = transfer)
    private val nov = YearMonth.of(2026, 11)

    @Test fun spentCountsOnlyDoneExpensesOfTheMonthAndCategorySet() {
        val txs = listOf(tx("30", "Cibo"), tx("20", "Svago"), tx("10", "Cibo", done = false), tx("5", "Cibo", transfer = true),
            tx("7", "Cibo", month = 10), tx("9", "Cibo", type = "Entrata"), tx("4", "Cibo", account = "b"))
        val all = BudgetData("1", null, "Tutti", BigDecimal(100), 11, 2026)
        assertEquals(0, BigDecimal(54).compareTo(Budgeting.spent(all, nov, txs, ZoneOffset.UTC)))
        val cibo = BudgetData("2", "a", Budgeting.categoryString(listOf("Cibo")), BigDecimal(100), 11, 2026)
        assertEquals(0, BigDecimal(30).compareTo(Budgeting.spent(cibo, nov, txs, ZoneOffset.UTC)))
    }

    @Test fun progressStatusAndGoals() {
        assertEquals(0.5, Budgeting.progress(BigDecimal(50), BigDecimal(100)), 1e-9)
        assertEquals(1.0, Budgeting.progress(BigDecimal(150), BigDecimal(100)), 1e-9)
        assertEquals(0.0, Budgeting.progress(BigDecimal(5), BigDecimal.ZERO), 1e-9)
        assertEquals(Budgeting.Status.Ok, Budgeting.status(0.79))
        assertEquals(Budgeting.Status.Threshold, Budgeting.status(0.8))
        assertEquals(Budgeting.Status.Over, Budgeting.status(1.0))
        assertEquals("Cibo,Svago", Budgeting.categoryString(listOf("Svago", "Cibo")))
        assertEquals(setOf("Cibo", "Svago"), Budgeting.categorySet("Cibo,Svago")); assertEquals(emptySet<String>(), Budgeting.categorySet("Tutti"))
        val goals = listOf(GoalData("g", BigDecimal(100), BigDecimal(50)), GoalData("h", BigDecimal(300), BigDecimal(350)))
        assertEquals(1.0, Budgeting.goalProgress(goals[1]), 1e-9)
        assertEquals(0, BigDecimal.ZERO.compareTo(Budgeting.goalRemaining(goals[1])))
        assertEquals(1.0, Budgeting.overallGoalProgress(goals), 1e-9)
        assertEquals(0.0, Budgeting.overallGoalProgress(emptyList()), 1e-9)
    }
}
