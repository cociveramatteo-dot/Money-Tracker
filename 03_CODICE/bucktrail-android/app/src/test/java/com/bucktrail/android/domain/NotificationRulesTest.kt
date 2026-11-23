package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNotNull
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime

class NotificationRulesTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val nov = YearMonth.of(2026, 11)
    private fun spend(amount: String, category: String = "Cibo", done: Boolean = true, transfer: Boolean = false, day: Int = 5, account: String = "a") =
        TransactionData("t$amount$day$category", account, "x", BigDecimal(amount), "Uscita", category, date = Instant.parse("2026-11-${"%02d".format(day)}T10:00:00Z"), isDone = done, isTransfer = transfer)
    private fun budget(limit: String, category: String = "Cibo", account: String? = null, month: Int = 11, id: String = "b1") =
        Budgeting.BudgetData(id, account, category, BigDecimal(limit), month, 2026)

    @Test fun belowEightyPercentGivesNoAlert() =
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("100")), listOf(spend("79.99")), nov, zone).isEmpty())

    @Test fun atEightyPercentIsNearLimitWithTruncatedPercent() {
        val a = NotificationRules.budgetAlerts(listOf(budget("100")), listOf(spend("80")), nov, zone).single()
        assertFalse(a.exceeded); assertEquals(80, a.percent)
        val b = NotificationRules.budgetAlerts(listOf(budget("200")), listOf(spend("179")), nov, zone).single()
        assertEquals(89, b.percent) // 89,5% -> 89, come Int(pct*100)
    }

    @Test fun reachingOrPassingTheLimitIsExceeded() {
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("100")), listOf(spend("100")), nov, zone).single().exceeded)
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("100")), listOf(spend("250")), nov, zone).single().exceeded)
    }

    @Test fun plannedTransfersOtherMonthsAndOtherCategoriesDoNotCount() {
        val txs = listOf(spend("90", done = false), spend("90", transfer = true), spend("90", category = "Svago"))
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("100")), txs, nov, zone).isEmpty())
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("100", month = 10)), listOf(spend("95")), nov, zone).isEmpty())
    }

    @Test fun globalAndAccountBudgetsAndZeroLimit() {
        val txs = listOf(spend("60", "Cibo"), spend("30", "Svago", account = "b"))
        assertEquals(1, NotificationRules.budgetAlerts(listOf(budget("100", "Tutti")), txs, nov, zone).size)
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("100", "Tutti", account = "a")), txs, nov, zone).isEmpty())
        assertTrue(NotificationRules.budgetAlerts(listOf(budget("0")), txs, nov, zone).isEmpty())
    }

    @Test fun fixedPendingCountsOnlyUnpaidFixedOfTheMonth() {
        val fixed = { done: Boolean, day: Int, fixed: Boolean ->
            TransactionData("f$done$day$fixed", "a", "x", BigDecimal.TEN, "Uscita", date = Instant.parse("2026-11-${"%02d".format(day)}T10:00:00Z"), isDone = done, isFixed = fixed)
        }
        val txs = listOf(fixed(false, 3, true), fixed(false, 20, true), fixed(true, 4, true), fixed(false, 5, false)) +
            TransactionData("old", "a", "x", BigDecimal.TEN, "Uscita", date = Instant.parse("2026-10-30T10:00:00Z"), isDone = false, isFixed = true)
        assertEquals(2, NotificationRules.fixedPending(txs, nov, zone))
    }

    @Test fun goalReminderIsSevenDaysBeforeAndOnlyIfFuture() {
        val deadline = Instant.parse("2026-12-25T09:00:00Z")
        val now = Instant.parse("2026-11-23T08:00:00Z")
        assertEquals(Instant.parse("2026-12-18T09:00:00Z"), NotificationRules.goalReminderAt(deadline, now, zone))
        assertNull(NotificationRules.goalReminderAt(Instant.parse("2026-11-28T09:00:00Z"), now, zone))
        assertNull(NotificationRules.goalReminderAt(Instant.parse("2026-11-30T08:00:00Z"), now, zone)) // il promemoria sarebbe adesso: non nel futuro
        assertNotNull(NotificationRules.goalReminderAt(Instant.parse("2026-11-30T09:00:00Z"), now, zone))
    }

    @Test fun balanceThresholdIsStrictlyBelow() {
        assertTrue(NotificationRules.balanceBelow(BigDecimal("99.99"), BigDecimal("100")))
        assertFalse(NotificationRules.balanceBelow(BigDecimal("100"), BigDecimal("100")))
        assertFalse(NotificationRules.balanceBelow(BigDecimal("-5"), BigDecimal("0.00")))
        assertFalse(NotificationRules.balanceBelow(BigDecimal("-5"), null))
    }

    @Test fun nextMonthlyIsTheNextFirstAtTheGivenHour() {
        val at = { s: String -> ZonedDateTime.parse(s) }
        assertEquals(at("2026-12-01T09:00+01:00[Europe/Rome]"), NotificationRules.nextMonthly(at("2026-11-23T12:00+01:00[Europe/Rome]"), 9))
        assertEquals(at("2026-11-01T09:00+01:00[Europe/Rome]"), NotificationRules.nextMonthly(at("2026-10-31T23:59+01:00[Europe/Rome]"), 9))
        assertEquals(at("2026-12-01T10:00+01:00[Europe/Rome]"), NotificationRules.nextMonthly(at("2026-11-01T10:00+01:00[Europe/Rome]"), 10)) // esattamente adesso: il mese dopo
        assertEquals(at("2027-01-01T09:00+01:00[Europe/Rome]"), NotificationRules.nextMonthly(at("2026-12-15T00:00+01:00[Europe/Rome]"), 9))
    }

    @Test fun idsMatchIos() {
        assertEquals("budget_x", NotificationRules.budgetId("x")); assertEquals("goal_x", NotificationRules.goalId("x"))
        assertEquals("balance_x", NotificationRules.balanceId("x")); assertEquals("fixed_reminder", NotificationRules.ID_FIXED)
        assertEquals("monthly_report", NotificationRules.ID_MONTHLY_REPORT)
    }
}
