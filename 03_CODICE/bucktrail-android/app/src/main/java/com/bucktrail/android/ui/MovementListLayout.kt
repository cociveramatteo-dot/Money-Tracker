package com.bucktrail.android.ui

import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import com.bucktrail.android.ui.screens.amountValue
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

sealed interface MovementItem {
    val date: Instant
    val createdAt: Long
    val id: String
    val signedAmount: BigDecimal
    val isPlanned: Boolean

    data class Real(val tx: TransactionEntity) : MovementItem {
        override val date: Instant = Instant.ofEpochMilli(tx.date)
        override val createdAt: Long = tx.createdAt
        override val id: String = tx.id
        override val signedAmount: BigDecimal =
            if (tx.isTransfer) BigDecimal.ZERO else Amounts.signed(tx.amountValue(), tx.type)
        override val isPlanned: Boolean = !tx.isDone
    }

    data class Virtual(val rule: RecurringRuleEntity, val occurrence: Occurrence) : MovementItem {
        override val date: Instant = occurrence.date
        override val createdAt: Long = Long.MIN_VALUE
        override val id: String = occurrence.id.toString()
        override val signedAmount: BigDecimal = Amounts.signed(occurrence.amount, occurrence.type)
        override val isPlanned: Boolean = true
    }
}

object MovementListLayout {
    data class DayGroup(val day: LocalDate, val items: List<MovementItem>)
    data class Result(val planned: List<MovementItem>, val days: List<DayGroup>)

    /**
     * Nei mesi futuri raggruppa i pianificati (reali non effettuati + virtuali) in cima in ordine
     * crescente di giorno; nei mesi correnti e passati lascia tutte le righe nei gruppi giornalieri.
     */
    fun make(
        real: List<TransactionEntity>,
        virtual: List<Pair<RecurringRuleEntity, Occurrence>>,
        isFutureMonth: Boolean,
        zone: ZoneId,
    ): Result {
        val realItems = real.map { MovementItem.Real(it) }
        val virtualItems = virtual.map { (rule, occ) -> MovementItem.Virtual(rule, occ) }

        return if (isFutureMonth) {
            val planned = (realItems.filter { it.isPlanned } + virtualItems).sortedWith(
                compareBy<MovementItem> { it.date.atZone(zone).toLocalDate() }
                    .thenByDescending { it.createdAt }
                    .thenBy { it.id },
            )
            val completed = realItems.filter { !it.isPlanned }
            Result(planned = planned, days = groupByDayDescending(completed, zone))
        } else {
            Result(planned = emptyList(), days = groupByDayDescending(realItems + virtualItems, zone))
        }
    }

    private fun groupByDayDescending(items: List<MovementItem>, zone: ZoneId): List<DayGroup> {
        val sorted = items.sortedWith(
            compareByDescending<MovementItem> { it.date.atZone(zone).toLocalDate() }
                .thenByDescending { it.createdAt }
                .thenBy { it.id },
        )
        val groups = ArrayList<DayGroup>()
        var currentDay: LocalDate? = null
        var currentItems = ArrayList<MovementItem>()
        for (item in sorted) {
            val day = item.date.atZone(zone).toLocalDate()
            if (day != currentDay) {
                if (currentDay != null) groups.add(DayGroup(currentDay, currentItems))
                currentDay = day
                currentItems = ArrayList()
            }
            currentItems.add(item)
        }
        if (currentDay != null) groups.add(DayGroup(currentDay, currentItems))
        return groups
    }
}
