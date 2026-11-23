package com.bucktrail.android.domain

import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/**
 * Serie del saldo del mese per la TrailView (funzione pura, porta di `BalanceTrail.swift`).
 * Ultimo punto reale = saldo attuale; ultimo punto proiettato = saldo atteso (anche per pianificati
 * scaduti o oltre fine mese, ancorati a oggi / all'ultimo giorno).
 */
data class BalanceTrail(
    val daysInMonth: Int,
    val today: Int,
    val currentBalance: BigDecimal,
    val expectedBalance: BigDecimal,
    val actual: List<Point>,
    val projected: List<Point>,
    val plannedMarks: List<Point>,
    val plannedCount: Int,
    val plannedDelta: BigDecimal,
) {
    data class Entry(val date: Instant, val signedAmount: BigDecimal, val isDone: Boolean)
    data class Point(val day: Int, val balance: BigDecimal) {
        override fun equals(other: Any?) = other is Point && day == other.day && balance.compareTo(other.balance) == 0
        override fun hashCode() = day * 31 + balance.stripTrailingZeros().hashCode()
    }

    val hasPlanned: Boolean get() = plannedCount > 0

    companion object {
        fun make(currentBalance: BigDecimal, entries: List<Entry>, now: Instant, zone: ZoneId): BalanceTrail {
            val nowDay = now.atZone(zone).toLocalDate()
            val month = YearMonth.from(nowDay)
            val daysInMonth = month.lengthOfMonth()
            val today = nowDay.dayOfMonth.coerceIn(1, daysInMonth)

            fun dayOf(date: Instant): Int {
                val d: LocalDate = date.atZone(zone).toLocalDate()
                val m = YearMonth.from(d)
                return if (m == month) d.dayOfMonth else if (m < month) 1 else daysInMonth
            }

            val doneByDay = HashMap<Int, BigDecimal>()
            val plannedByDay = HashMap<Int, BigDecimal>()
            val plannedDays = ArrayList<Int>()
            for (e in entries) {
                if (e.isDone) {
                    val d = minOf(dayOf(e.date), today)
                    doneByDay[d] = (doneByDay[d] ?: BigDecimal.ZERO) + e.signedAmount
                } else {
                    val d = maxOf(dayOf(e.date), today)
                    plannedByDay[d] = (plannedByDay[d] ?: BigDecimal.ZERO) + e.signedAmount
                    plannedDays.add(d)
                }
            }
            val reversed = ArrayList<Point>()
            var running = currentBalance
            for (d in today downTo 1) {
                reversed.add(Point(d, running))
                running -= doneByDay[d] ?: BigDecimal.ZERO
            }
            val plannedDelta = plannedByDay.values.fold(BigDecimal.ZERO) { a, b -> a + b }
            val projected = ArrayList<Point>()
            var marks = emptyList<Point>()
            if (plannedDays.isNotEmpty()) {
                var cumulative = currentBalance
                for (d in today..daysInMonth) {
                    cumulative += plannedByDay[d] ?: BigDecimal.ZERO
                    projected.add(Point(d, cumulative))
                }
                val byDay = projected.associate { it.day to it.balance }
                marks = plannedDays.sorted().mapNotNull { d -> byDay[d]?.let { Point(d, it) } }
            }
            return BalanceTrail(
                daysInMonth, today, currentBalance, currentBalance + plannedDelta,
                reversed.reversed(), projected, marks, plannedDays.size, plannedDelta,
            )
        }
    }
}
