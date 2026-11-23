package com.bucktrail.android.data

import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import com.bucktrail.android.domain.RecurrenceCalculator
import com.bucktrail.android.domain.RecurrenceException
import com.bucktrail.android.domain.RecurrenceExceptionCodec
import com.bucktrail.android.domain.RecurringMaterializer
import com.bucktrail.android.domain.RuleSnapshot
import java.math.BigDecimal
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.util.UUID

/**
 * Editor delle serie (`RecurringSeriesEditor.swift`) e materializzazione su dati reali, come funzioni pure:
 * leggono lo stato, restituiscono le modifiche da applicare in un'unica transazione Room (rollback = non applicarle).
 */
object RecurringOps {
    enum class Scope { OnlyThis, Following, All }

    sealed interface Action {
        data class Edit(val scope: Scope, val values: RuleSnapshot) : Action
        data class Delete(val scope: Scope) : Action
        data object SkipMonth : Action
        data class Terminate(val afterThis: Boolean) : Action
    }

    enum class Problem { InvalidOccurrence, InvalidValues, CrossMonthOverride }
    class EditorException(val problem: Problem) : Exception(problem.name)

    data class Changes(
        val upsertTransactions: List<TransactionEntity> = emptyList(),
        val deleteTransactionIds: List<String> = emptyList(),
        val upsertRules: List<RecurringRuleEntity> = emptyList(),
        val deleteRuleId: String? = null,
    ) {
        val isEmpty get() = upsertTransactions.isEmpty() && deleteTransactionIds.isEmpty() && upsertRules.isEmpty() && deleteRuleId == null
    }

    private val validFrequencies = setOf("mensile", "settimanale", "annuale")

    private class Work(val origId: String?, var t: TransactionEntity, var deleted: Boolean = false)

    /** Applica le modifiche in memoria (usato dai test e come riferimento della transazione Room). */
    fun applyTo(changes: Changes, rules: List<RecurringRuleEntity>, transactions: List<TransactionEntity>): Pair<List<RecurringRuleEntity>, List<TransactionEntity>> {
        val newRules = rules.filter { it.id != changes.deleteRuleId }.associateBy { it.id }.toMutableMap()
        changes.upsertRules.forEach { newRules[it.id] = it }
        val txs = transactions.filter { it.id !in changes.deleteTransactionIds }.associateBy { it.id }.toMutableMap()
        changes.upsertTransactions.forEach { txs[it.id] = it }
        return newRules.values.toList() to txs.values.toList()
    }

    fun snapshot(rule: RecurringRuleEntity): RuleSnapshot = rule.toSnapshot()

    private fun RecurringRuleEntity.withSnapshotFields(v: RuleSnapshot, calc: RecurrenceCalculator) = copy(
        name = v.name, amountCents = Amounts.toCents(v.amount), type = v.type, category = v.category, categoryIcon = v.categoryIcon,
        notes = v.notes, isFixed = v.isFixed, accountId = v.accountId?.toString(), frequency = v.frequency,
        startDate = calc.noon(v.startDate).toEpochMilli(), endDate = v.endDate?.let { calc.noon(it).toEpochMilli() },
    )

    private fun amountString(a: BigDecimal): String = a.stripTrailingZeros().toPlainString()

    fun apply(
        action: Action, rule: RecurringRuleEntity, originalDate: Instant, transactions: List<TransactionEntity>,
        accountIds: Set<String>, now: Instant, zone: ZoneId,
    ): Changes {
        val calc = RecurrenceCalculator(zone)
        val original = calc.noon(originalDate)
        val ruleId = UUID.fromString(rule.id)
        val base = rule.toSnapshot().copy(exceptions = emptyMap(), endDate = null)
        val monthStart = calc.monthStart(original)
        val monthEnd = calc.addMonths(monthStart, 1)
        if (calc.occurrences(base, monthStart, monthEnd).none { it.originalDate == original }) throw EditorException(Problem.InvalidOccurrence)

        val old = rule.toSnapshot()
        val copies = transactions.filter { it.templateId.equals(rule.id, ignoreCase = true) }
        val work = transactions.map { Work(it.id, it) }.toMutableList()
        val copyWork = work.filter { it.t.templateId.equals(rule.id, ignoreCase = true) }
        val deletions = ArrayList<Work>()
        var ruleE = rule
        val extraRules = ArrayList<RecurringRuleEntity>()
        var deleteRule = false
        val key = calc.key(original)
        var exceptions = old.exceptions
        val previousDay = calc.addDays(original, -1)

        var originalDays: Map<UUID, Instant>? = null
        fun originalDay(w: Work): Instant {
            if (originalDays == null) {
                val lastDate = maxOf(copies.maxOfOrNull { Instant.ofEpochMilli(it.date) } ?: original, rule.materializedThrough?.let(Instant::ofEpochMilli) ?: original, original)
                val end = calc.addMonths(lastDate, 1)
                originalDays = calc.occurrences(base, base.startDate, maxOf(end, base.startDate.plusSeconds(1))).associate { it.id to it.originalDate }
            }
            return runCatching { UUID.fromString(w.t.id) }.getOrNull()?.let { originalDays!![it] } ?: calc.noon(Instant.ofEpochMilli(w.t.date))
        }
        fun remove(pred: (Work) -> Boolean) { deletions += copyWork.filter { !it.t.isDone && pred(it) } }
        fun resolveAccount(id: UUID?): String? = id?.toString()?.takeIf { it in accountIds }
        fun update(w: Work, o: Occurrence) {
            w.t = w.t.copy(
                name = o.name, amountCents = Amounts.toCents(o.amount), date = o.date.toEpochMilli(), notes = o.notes,
                category = o.category, categoryIcon = o.categoryIcon, type = o.type, isFixed = o.isFixed, accountId = resolveAccount(o.accountId),
            )
        }
        fun occurrence(v: RuleSnapshot, day: Instant) = Occurrence(
            v.id, calc.key(day), day, calc.noon(day), v.amount, v.name, v.category, v.categoryIcon, v.type, v.accountId, v.isFixed, v.notes, false,
        )
        fun daysInMonth(d: Instant) = YearMonth.from(calc.day(d)).lengthOfMonth()
        fun rescheduledDay(day: Instant, from: RuleSnapshot, to: RuleSnapshot): Instant {
            val index: Long = if (from.frequency == "settimanale") maxOf(0L, ChronoUnit.DAYS.between(calc.day(from.startDate), calc.day(day)) / 7)
            else maxOf(0L, ChronoUnit.MONTHS.between(YearMonth.from(calc.day(from.startDate)), YearMonth.from(calc.day(day))) / (if (from.frequency == "annuale") 12 else 1))
            if (to.frequency == "settimanale") return calc.addDays(calc.noon(to.startDate), index * 7)
            val month = YearMonth.from(calc.day(to.startDate)).plusMonths(index * (if (to.frequency == "annuale") 12 else 1))
            val dom = minOf(calc.day(to.startDate).dayOfMonth, month.lengthOfMonth())
            return calc.noon(month.atDay(dom).atTime(12, 0).atZone(zone).toInstant())
        }
        fun reconcile(target: RecurringRuleEntity): RecurringRuleEntity {
            val mStart = calc.monthStart(now); val mEnd = calc.addMonths(mStart, 1)
            val desired = calc.occurrences(target.toSnapshot(), mStart, mEnd)
            val ids = desired.map { it.id.toString() }.toSet()
            for (w in work.filter { it.t.templateId.equals(target.id, true) }) {
                val d = Instant.ofEpochMilli(w.t.date)
                if (!w.t.isDone && !d.isBefore(mStart) && d.isBefore(mEnd) && w.t.id !in ids) deletions += w
            }
            for (o in desired) {
                val existing = work.firstOrNull { it.t.id == o.id.toString() && !it.deleted }
                if (existing != null) update(existing, o)
                else work += Work(null, TransactionEntity(
                    id = o.id.toString(), accountId = resolveAccount(o.accountId), name = o.name, amountCents = Amounts.toCents(o.amount), type = o.type,
                    category = o.category, categoryIcon = o.categoryIcon, date = o.date.toEpochMilli(), isDone = false, isFixed = o.isFixed,
                    notes = o.notes, templateId = target.id.uppercase(), createdAt = now.toEpochMilli(),
                ))
            }
            val start = Instant.ofEpochMilli(target.startDate)
            return if (start.isBefore(mEnd)) {
                val floor = calc.noon(mStart).toEpochMilli()
                target.copy(materializedThrough = maxOf(target.materializedThrough ?: floor, floor))
            } else target
        }

        when (action) {
            is Action.Edit -> {
                val v = action.values
                val minEnd = calc.noon(if (action.scope == Scope.Following) original else v.startDate)
                if (v.frequency !in validFrequencies || v.type !in setOf(Amounts.TYPE_EXPENSE, Amounts.TYPE_INCOME) ||
                    v.amount.signum() < 0 || v.endDate?.let { calc.noon(it).isBefore(minEnd) } == true
                ) throw EditorException(Problem.InvalidValues)
                when (action.scope) {
                    Scope.OnlyThis -> {
                        if (YearMonth.from(calc.day(v.startDate)) != YearMonth.from(calc.day(original))) throw EditorException(Problem.CrossMonthOverride)
                        exceptions = exceptions + (key to RecurrenceException(
                            amount = amountString(v.amount), date = calc.noon(v.startDate), name = v.name, notes = v.notes, category = v.category,
                            categoryIcon = v.categoryIcon, type = v.type, isFixed = v.isFixed, accountId = v.accountId, overridesAccount = true,
                        ))
                        ruleE = ruleE.copy(exceptionsJson = RecurrenceExceptionCodec.encode(exceptions))
                        val occ = calc.occurrences(ruleE.toSnapshot(), monthStart, monthEnd).firstOrNull { it.key == key } ?: throw EditorException(Problem.InvalidOccurrence)
                        copyWork.firstOrNull { it.t.id == occ.id.toString() }?.let { update(it, occ) }
                    }
                    Scope.Following -> {
                        ruleE = ruleE.copy(endDate = previousDay.toEpochMilli(),
                            exceptionsJson = RecurrenceExceptionCodec.encode(exceptions.filter { it.key < key }))
                        val fresh = RecurringRuleEntity(
                            name = v.name, type = v.type, category = v.category, categoryIcon = v.categoryIcon, notes = v.notes,
                            amountCents = Amounts.toCents(v.amount), isFixed = v.isFixed, accountId = v.accountId?.toString(), frequency = v.frequency,
                            startDate = original.toEpochMilli(), endDate = v.endDate?.let { calc.noon(it).toEpochMilli() }, createdAt = now.toEpochMilli(),
                        )
                        val source = old.copy(startDate = original)
                        val target = fresh.toSnapshot()
                        for (w in copyWork) {
                            if (originalDay(w).isBefore(original)) continue
                            val day = rescheduledDay(originalDay(w), source, target)
                            update(w, occurrence(target, day))
                            if (target.endDate != null && day.isAfter(calc.noon(target.endDate!!)) && !w.t.isDone) deletions += w
                            w.t = w.t.copy(id = RecurrenceCalculator.occurrenceId(target.id, calc.key(day)).toString(), templateId = fresh.id.uppercase())
                        }
                        extraRules += reconcile(fresh)
                    }
                    Scope.All -> {
                        ruleE = ruleE.withSnapshotFields(v, calc)
                        val sameSchedule = old.frequency == v.frequency && calc.key(old.startDate) == calc.key(v.startDate)
                        ruleE = ruleE.copy(exceptionsJson = RecurrenceExceptionCodec.encode(if (sameSchedule) old.exceptions.filter { it.value.skip } else emptyMap()))
                        val newSnap = ruleE.toSnapshot()
                        for (w in copyWork) {
                            val day = rescheduledDay(originalDay(w), old, v)
                            update(w, occurrence(v, day))
                            if (v.endDate != null && day.isAfter(calc.noon(v.endDate)) && !w.t.isDone) deletions += w
                            w.t = w.t.copy(id = RecurrenceCalculator.occurrenceId(ruleId, calc.key(day)).toString())
                        }
                        check(newSnap.id == ruleId)
                        ruleE = reconcile(ruleE)
                    }
                }
            }
            is Action.Delete -> when (action.scope) {
                Scope.OnlyThis -> {
                    exceptions = exceptions + (key to RecurrenceException(skip = true))
                    ruleE = ruleE.copy(exceptionsJson = RecurrenceExceptionCodec.encode(exceptions))
                    val id = RecurrenceCalculator.occurrenceId(ruleId, key).toString()
                    remove { it.t.id == id }
                }
                Scope.Following -> { ruleE = ruleE.copy(endDate = previousDay.toEpochMilli()); remove { !originalDay(it).isBefore(original) } }
                Scope.All -> { remove { true }; deleteRule = true }
            }
            Action.SkipMonth -> {
                for (o in calc.occurrences(base, monthStart, monthEnd)) exceptions = exceptions + (o.key to RecurrenceException(skip = true))
                ruleE = ruleE.copy(exceptionsJson = RecurrenceExceptionCodec.encode(exceptions))
                val ym = YearMonth.from(calc.day(original))
                remove { YearMonth.from(calc.day(Instant.ofEpochMilli(it.t.date))) == ym }
            }
            is Action.Terminate -> {
                ruleE = ruleE.copy(endDate = (if (action.afterThis) original else previousDay).toEpochMilli())
                remove { if (action.afterThis) originalDay(it).isAfter(original) else !originalDay(it).isBefore(original) }
            }
        }

        val deleted = deletions.toSet()
        val deleteIds = LinkedHashSet<String>()
        val upserts = ArrayList<TransactionEntity>()
        val byId = transactions.associateBy { it.id }
        for (w in work) {
            if (w in deleted) { w.origId?.let(deleteIds::add); continue }
            if (w.origId == null) upserts += w.t
            else if (w.t != byId[w.origId]) {
                if (w.t.id != w.origId) deleteIds += w.origId // prima si cancella, poi si inserisce (applicazione in questo ordine)
                upserts += w.t
            }
        }
        val rules = if (deleteRule) emptyList() else listOf(ruleE) + extraRules
        return Changes(upserts, deleteIds.toList(), rules, if (deleteRule) rule.id else null)
    }

    /** Materializzazione agli avvii: copie `isDone=false` mancanti per i mesi dovuti e watermark aggiornati. */
    fun materialize(rules: List<RecurringRuleEntity>, transactions: List<TransactionEntity>, accountIds: Set<String>, now: Instant, zone: ZoneId): Changes {
        val calc = RecurrenceCalculator(zone)
        val byTemplate = transactions.groupBy { it.templateId.lowercase() }
        val states = rules.map { r ->
            RecurringMaterializer.RuleState(
                r.toSnapshot(), r.materializedThrough?.let(Instant::ofEpochMilli),
                byTemplate[r.id.lowercase()].orEmpty().mapNotNull { runCatching { UUID.fromString(it.id) }.getOrNull() }.toSet(),
            )
        }
        val plan = RecurringMaterializer.plan(states, now, calc)
        if (plan.watermarks.isEmpty() && plan.toInsert.isEmpty()) return Changes()
        val inserts = plan.toInsert.map { o ->
            TransactionEntity(
                id = o.id.toString(), accountId = o.accountId?.toString()?.takeIf { it in accountIds }, name = o.name,
                amountCents = Amounts.toCents(o.amount), type = o.type, category = o.category, categoryIcon = o.categoryIcon,
                date = o.date.toEpochMilli(), isDone = false, isFixed = o.isFixed, notes = o.notes,
                templateId = o.ruleId.toString().uppercase(), createdAt = now.toEpochMilli(),
            )
        }
        val updated = rules.filter { it.id.lowercase() in plan.watermarks.keys.map { k -> k.toString().lowercase() } }
            .map { it.copy(materializedThrough = plan.watermarks.entries.first { e -> e.key.toString().equals(it.id, true) }.value.toEpochMilli()) }
        return Changes(upsertTransactions = inserts, upsertRules = updated)
    }

    /** Regola e occorrenza originale di una copia generata da serie (`RecurrenceSelection.resolve`). */
    data class Selection(val rule: RecurringRuleEntity, val occurrence: Occurrence)

    fun resolve(t: TransactionEntity, rules: List<RecurringRuleEntity>, zone: ZoneId): Selection? {
        if (t.templateId.isEmpty()) return null
        val rule = rules.firstOrNull { it.id.equals(t.templateId, ignoreCase = true) } ?: return null
        val calc = RecurrenceCalculator(zone)
        val snap = rule.toSnapshot()
        val bare = snap.copy(exceptions = emptyMap(), endDate = null)
        val end = calc.addMonths(maxOf(Instant.ofEpochMilli(t.date), snap.startDate, rule.materializedThrough?.let(Instant::ofEpochMilli) ?: snap.startDate), 1)
        val id = runCatching { UUID.fromString(t.id) }.getOrNull() ?: return null
        val original = calc.occurrences(bare, snap.startDate, end).firstOrNull { it.id == id } ?: return null
        val effective = calc.occurrences(snap, snap.startDate, end).firstOrNull { it.id == id } ?: original
        return Selection(rule, effective)
    }
}
