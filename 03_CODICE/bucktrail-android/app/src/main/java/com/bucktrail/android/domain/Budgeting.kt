package com.bucktrail.android.domain

import java.math.BigDecimal
import java.math.MathContext
import java.time.YearMonth
import java.time.ZoneId

/** Budget e obiettivi (§3.5, §3.6): funzioni pure, stesse formule di `PianificaView`. */
object Budgeting {
    data class BudgetData(val id: String, val accountId: String?, val category: String, val monthlyLimit: BigDecimal, val month: Int, val year: Int)
    data class GoalData(val id: String, val target: BigDecimal, val current: BigDecimal)

    enum class Status { Ok, Threshold, Over }

    /** Categorie del budget: `"Tutti"` = insieme vuoto (tutte), altrimenti nomi separati da virgola. */
    fun categorySet(raw: String): Set<String> =
        if (raw == "Tutti") emptySet() else raw.split(",").map { it.trim() }.filter { it.isNotEmpty() }.toSet()

    /** Nomi ordinati alfabeticamente e uniti da `,` (formato salvato). */
    fun categoryString(names: Collection<String>): String =
        if (names.isEmpty()) "Tutti" else names.sorted().joinToString(",")

    fun spent(budget: BudgetData, month: YearMonth, transactions: List<TransactionData>, zone: ZoneId): BigDecimal {
        val cats = categorySet(budget.category)
        return transactions.asSequence().filter {
            it.isDone && it.type == Amounts.TYPE_EXPENSE && !it.isTransfer &&
                YearMonth.from(it.date.atZone(zone)) == month &&
                (cats.isEmpty() || it.category in cats) &&
                (budget.accountId == null || it.accountId == budget.accountId)
        }.fold(BigDecimal.ZERO) { a, t -> a + t.amount }
    }

    /** `min(spent/limit, 1)`; 0 se limite <= 0. */
    fun progress(spent: BigDecimal, limit: BigDecimal): Double =
        if (limit.signum() <= 0) 0.0 else minOf(spent.divide(limit, MathContext.DECIMAL64).toDouble(), 1.0)

    fun status(progress: Double): Status = when {
        progress >= 1.0 -> Status.Over
        progress >= 0.8 -> Status.Threshold
        else -> Status.Ok
    }

    fun goalProgress(goal: GoalData): Double =
        if (goal.target.signum() <= 0) 0.0 else minOf(goal.current.divide(goal.target, MathContext.DECIMAL64).toDouble(), 1.0)

    fun goalRemaining(goal: GoalData): BigDecimal = (goal.target - goal.current).max(BigDecimal.ZERO)

    fun overallGoalProgress(goals: List<GoalData>): Double {
        if (goals.isEmpty()) return 0.0
        val target = goals.fold(BigDecimal.ZERO) { a, g -> a + g.target }
        val current = goals.fold(BigDecimal.ZERO) { a, g -> a + g.current }
        return if (target.signum() <= 0) 0.0 else minOf(current.divide(target, MathContext.DECIMAL64).toDouble(), 1.0)
    }
}
