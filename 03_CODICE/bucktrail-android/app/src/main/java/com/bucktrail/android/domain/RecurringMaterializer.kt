package com.bucktrail.android.domain

import java.time.Instant
import java.util.UUID

/** Pianificazione pura della materializzazione (`RecurringMaterializer.materializeDue`): niente DB qui. */
object RecurringMaterializer {
    data class RuleState(val rule: RuleSnapshot, val materializedThrough: Instant?, val existingIds: Set<UUID>)

    data class Plan(
        /** Occorrenze da inserire come copie reali `isDone=false`, `templateId = ruleId` (maiuscolo). */
        val toInsert: List<Occurrence>,
        /** Regola -> nuovo watermark (mese corrente alle 12:00). */
        val watermarks: Map<UUID, Instant>,
    )

    private val valid = setOf("mensile", "settimanale", "annuale")

    /**
     * Watermark nullo = regola nuova: mai storico prima del mese corrente. Una regola in ritardo recupera al massimo
     * gli ultimi 36 mesi (corrente incluso). Le copie esistenti non si toccano mai.
     */
    fun plan(rules: List<RuleState>, now: Instant, calc: RecurrenceCalculator): Plan {
        fun month(date: Instant) = calc.noon(calc.monthStart(date))
        val currentMonth = month(now)
        val oldestMonth = calc.addMonths(currentMonth, -35)
        val updates = LinkedHashMap<UUID, Instant>()
        val pending = ArrayList<Occurrence>()
        val pendingIds = HashSet<UUID>()
        for (state in rules) {
            val rule = state.rule
            if (rule.frequency !in valid) continue
            val startMonth = month(rule.startDate)
            val previous = state.materializedThrough
            val watermark = previous?.let(::month) ?: calc.addMonths(maxOf(startMonth, currentMonth), -1)
            if (!watermark.isBefore(currentMonth)) {
                if (previous == null) updates[rule.id] = watermark
                continue
            }
            var cursor = maxOf(startMonth, oldestMonth, calc.addMonths(watermark, 1))
            while (!cursor.isAfter(currentMonth)) {
                val next = calc.addMonths(cursor, 1)
                if (!next.isAfter(cursor)) return Plan(emptyList(), emptyMap())
                for (o in calc.occurrences(rule, cursor, next)) {
                    if (o.id in state.existingIds || !pendingIds.add(o.id)) continue
                    pending.add(o)
                }
                cursor = next
            }
            updates[rule.id] = currentMonth
        }
        return Plan(pending, updates)
    }
}
