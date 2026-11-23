package com.bucktrail.android.domain

import java.math.BigDecimal
import java.math.MathContext
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import java.time.ZonedDateTime

/** Regole delle notifiche (§5.5): chi e quando, senza dipendenze Android (testabile in JVM). */
object NotificationRules {
    const val ID_FIXED = "fixed_reminder"
    const val ID_MONTHLY_REPORT = "monthly_report"
    fun budgetId(id: String) = "budget_$id"
    fun goalId(id: String) = "goal_$id"
    fun balanceId(id: String) = "balance_$id"

    const val FIXED_HOUR = 9
    const val REPORT_HOUR = 10
    const val BUDGET_DELAY_MS = 2_000L
    const val BALANCE_DELAY_MS = 1_000L

    /** `pct` = spesa/limite (non limitata a 1): >= 1 «sforato», altrimenti «quasi esaurito» con `percent`. */
    data class BudgetAlert(val budgetId: String, val categoryRaw: String, val accountId: String?, val pct: Double) {
        val exceeded get() = pct >= 1.0
        /** `Int(pct * 100)` come iOS (troncamento sul `Double`). */
        val percent get() = (pct * 100).toInt()
    }

    /** Budget del mese con almeno l'80% utilizzato (limite > 0). Le spese contano `isDone && !isTransfer` come in Pianifica. */
    fun budgetAlerts(budgets: List<Budgeting.BudgetData>, transactions: List<TransactionData>, month: YearMonth, zone: ZoneId): List<BudgetAlert> =
        budgets.filter { it.month == month.monthValue && it.year == month.year }.mapNotNull { b ->
            if (b.monthlyLimit.signum() <= 0) return@mapNotNull null
            val spent = Budgeting.spent(b, month, transactions, zone)
            val pct = spent.divide(b.monthlyLimit, MathContext.DECIMAL128).toDouble()
            if (pct >= 0.8) BudgetAlert(b.id, b.category, b.accountId, pct) else null
        }

    /** Spese fisse del mese ancora da segnare come pagate. */
    fun fixedPending(transactions: List<TransactionData>, month: YearMonth, zone: ZoneId): Int =
        transactions.count { it.isFixed && !it.isDone && YearMonth.from(it.date.atZone(zone)) == month }

    /** 7 giorni civili prima della scadenza, alla stessa ora; `null` se non è nel futuro. */
    fun goalReminderAt(deadline: Instant, now: Instant, zone: ZoneId): Instant? {
        val at = deadline.atZone(zone).minusDays(7).toInstant()
        return at.takeIf { it.isAfter(now) }
    }

    /** `saldo < soglia` con soglia > 0. */
    fun balanceBelow(balance: BigDecimal, threshold: BigDecimal?): Boolean = threshold != null && threshold.signum() > 0 && balance < threshold

    /** Prossimo 1° del mese all'ora indicata, strettamente dopo `now`. */
    fun nextMonthly(now: ZonedDateTime, hour: Int): ZonedDateTime {
        val thisMonth = now.toLocalDate().withDayOfMonth(1).atTime(hour, 0).atZone(now.zone)
        return if (thisMonth.isAfter(now)) thisMonth else thisMonth.plusMonths(1)
    }
}
