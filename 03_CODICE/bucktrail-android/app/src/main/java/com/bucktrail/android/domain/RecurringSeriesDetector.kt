package com.bucktrail.android.domain

import java.math.BigDecimal
import java.math.MathContext
import java.time.YearMonth
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import kotlin.math.abs

data class RecurringSeries(
    val id: String, val name: String, val category: String, val categoryIcon: String, val type: String,
    val frequency: String, val isVariableAmount: Boolean, val count: Int, val totalAmount: BigDecimal,
    val average: BigDecimal, val lastAmount: BigDecimal, val occurrences: List<TransactionData>,
)

/** Abitudini rilevate per nome+categoria+tipo (almeno 3 occorrenze in 3 mesi diversi, esclusi trasferimenti e rettifiche saldo). */
object RecurringSeriesDetector {
    fun detect(transactions: List<TransactionData>, zone: ZoneId): List<RecurringSeries> {
        val buckets = LinkedHashMap<String, MutableList<TransactionData>>()
        for (t in transactions) {
            if (!t.isDone || t.isTransfer || t.category == Categories.ADJUSTMENT) continue
            buckets.getOrPut("${t.name.trim().lowercase()}|${t.category}|${t.type}") { ArrayList() }.add(t)
        }
        val result = ArrayList<RecurringSeries>()
        for ((key, items) in buckets) {
            if (items.size < 3) continue
            val sorted = items.sortedBy { it.date }
            val months = sorted.map { YearMonth.from(it.date.atZone(zone)) }.toSet()
            if (months.size < 3) continue
            val total = sorted.fold(BigDecimal.ZERO) { a, t -> a + t.amount }
            val last = sorted.last()
            val explicit = sorted.firstOrNull { it.recurringFrequency.isNotEmpty() }?.recurringFrequency
            result.add(
                RecurringSeries(
                    id = key, name = last.name, category = last.category, categoryIcon = last.categoryIcon, type = last.type,
                    frequency = explicit ?: inferFrequency(sorted, zone),
                    isVariableAmount = !sorted.all { it.amount.compareTo(sorted[0].amount) == 0 },
                    count = sorted.size, totalAmount = total,
                    average = total.divide(BigDecimal(sorted.size), MathContext.DECIMAL128),
                    lastAmount = last.amount, occurrences = sorted,
                )
            )
        }
        return result.sortedByDescending { it.totalAmount.abs() }
    }

    private fun inferFrequency(items: List<TransactionData>, zone: ZoneId): String {
        val gaps = (1 until items.size).map {
            abs(ChronoUnit.DAYS.between(items[it - 1].date.atZone(zone).toLocalDate(), items[it].date.atZone(zone).toLocalDate()))
        }
        if (gaps.isEmpty()) return "irregolare"
        val avg = gaps.sum().toDouble() / gaps.size
        return when {
            avg <= 10 -> "settimanale"
            avg <= 45 -> "mensile"
            avg <= 200 -> "irregolare"
            else -> "annuale"
        }
    }
}
