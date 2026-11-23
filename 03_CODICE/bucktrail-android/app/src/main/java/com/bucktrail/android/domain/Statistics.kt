package com.bucktrail.android.domain

import java.math.BigDecimal
import java.math.RoundingMode
import java.time.YearMonth
import java.time.ZoneId

/** Statistiche (§3.9, §4.5): tutti i totali usano `isDone && !isTransfer`, stesse formule di `StatisticsView`. */
object Statistics {
    data class CategoryStat(val name: String, val icon: String, val amount: BigDecimal)
    data class MonthStat(val month: YearMonth, val expenses: BigDecimal, val income: BigDecimal)
    data class Totals(val expenses: BigDecimal, val income: BigDecimal)

    private fun valid(t: TransactionData) = t.isDone && !t.isTransfer

    /** Totali per mese di calendario (le chiavi assenti valgono zero). */
    fun byMonth(transactions: List<TransactionData>, zone: ZoneId): Map<YearMonth, Totals> {
        val out = HashMap<YearMonth, Totals>()
        for (t in transactions) {
            if (!valid(t)) continue
            val m = YearMonth.from(t.date.atZone(zone))
            val cur = out[m] ?: Totals(BigDecimal.ZERO, BigDecimal.ZERO)
            out[m] = if (t.type == Amounts.TYPE_EXPENSE) cur.copy(expenses = cur.expenses + t.amount) else cur.copy(income = cur.income + t.amount)
        }
        return out
    }

    fun totalsOf(month: YearMonth, byMonth: Map<YearMonth, Totals>): Totals = byMonth[month] ?: Totals(BigDecimal.ZERO, BigDecimal.ZERO)

    /** Uscite del mese per categoria, dall'importo più alto (a parità, per nome). */
    fun categories(transactions: List<TransactionData>, month: YearMonth, zone: ZoneId): List<CategoryStat> {
        val acc = LinkedHashMap<String, Pair<String, BigDecimal>>()
        for (t in transactions) {
            if (!valid(t) || t.type != Amounts.TYPE_EXPENSE || YearMonth.from(t.date.atZone(zone)) != month) continue
            val cur = acc[t.category]
            acc[t.category] = (cur?.first ?: t.categoryIcon) to ((cur?.second ?: BigDecimal.ZERO) + t.amount)
        }
        return acc.map { (name, v) -> CategoryStat(name, v.first, v.second) }.sortedWith(compareByDescending<CategoryStat> { it.amount }.thenBy { it.name })
    }

    /** Ultimi `months` mesi che finiscono a `selected` (inclusivo), dal più vecchio. */
    fun trend(byMonth: Map<YearMonth, Totals>, selected: YearMonth, months: Int): List<MonthStat> =
        (months - 1 downTo 0).map { offset ->
            val m = selected.minusMonths(offset.toLong())
            val t = totalsOf(m, byMonth)
            MonthStat(m, t.expenses, t.income)
        }

    fun prevMonthSpent(byMonth: Map<YearMonth, Totals>, selected: YearMonth): BigDecimal = totalsOf(selected.minusMonths(1), byMonth).expenses

    /** Media sui soli mesi con valore > 0 (non su 12 fissi). */
    fun averageExpenses(stats: List<MonthStat>): BigDecimal = average(stats.map { it.expenses })
    fun averageIncome(stats: List<MonthStat>): BigDecimal = average(stats.map { it.income })

    private fun average(values: List<BigDecimal>): BigDecimal {
        val nonZero = values.filter { it.signum() > 0 }
        if (nonZero.isEmpty()) return BigDecimal.ZERO
        return nonZero.fold(BigDecimal.ZERO) { a, v -> a + v }.divide(BigDecimal(nonZero.size), 6, RoundingMode.HALF_EVEN)
    }

    /** Somma dei mesi dell'anno (tutti i mesi presenti, anche futuri se fatti). */
    fun yearTotals(byMonth: Map<YearMonth, Totals>, year: Int): Totals =
        byMonth.filterKeys { it.year == year }.values.fold(Totals(BigDecimal.ZERO, BigDecimal.ZERO)) { a, t -> Totals(a.expenses + t.expenses, a.income + t.income) }

    /** `%.0f%%` della quota sul totale; 0 se il totale è 0. */
    fun percentOfTotal(amount: BigDecimal, total: BigDecimal): Int =
        if (total.signum() > 0) Math.round(amount.toDouble() / total.toDouble() * 100).toInt() else 0

    /** Variazione percentuale assoluta rispetto a `prev` (> 0), arrotondata come `%.0f`. */
    fun deltaPercent(current: BigDecimal, prev: BigDecimal): Int = Math.round(Math.abs((current - prev).toDouble() / prev.toDouble() * 100)).toInt()
}
