package com.bucktrail.android.data

import com.bucktrail.android.data.RecurringOps.Action
import com.bucktrail.android.data.RecurringOps.Scope
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.RecurrenceCalculator
import com.bucktrail.android.domain.RecurrenceExceptionCodec
import com.bucktrail.android.domain.RuleSnapshot
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertThrows
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Scenari portati da RecurringSeriesEditorTests.swift (stato in memoria al posto di SwiftData). */
class RecurringOpsTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val calc = RecurrenceCalculator(zone)
    private fun date(m: Int, d: Int = 1): Instant = LocalDate.of(2026, m, d).atTime(12, 0).atZone(zone).toInstant()
    private fun ms(m: Int, d: Int = 1) = date(m, d).toEpochMilli()

    private class World(var rules: List<RecurringRuleEntity>, var txs: List<TransactionEntity> = emptyList(), val accounts: Set<String> = emptySet()) {
        val rule get() = rules.first()
    }

    private fun setup(frequency: String = "mensile", start: Int = 1, accounts: Set<String> = emptySet()) =
        World(listOf(RecurringRuleEntity(name = "Base", type = "Uscita", category = "Altro", categoryIcon = "circle.dotted", amountCents = 20, frequency = frequency, startDate = ms(start))), accounts = accounts)

    private fun World.materialize(month: Int) {
        val c = RecurringOps.materialize(rules, txs, accounts, date(month), zone)
        val (r, t) = RecurringOps.applyTo(c, rules, txs); rules = r; txs = t
    }
    private fun World.apply(action: Action, rule: RecurringRuleEntity = this.rule, original: Instant, now: Instant = date(3)): RecurringRuleEntity? {
        val c = RecurringOps.apply(action, rule, original, txs, accounts, now, zone)
        val (r, t) = RecurringOps.applyTo(c, rules, txs); rules = r; txs = t
        return c.upsertRules.firstOrNull { it.id != rule.id } ?: rules.firstOrNull { it.id == rule.id }
    }
    private fun World.snap(r: RecurringRuleEntity = rule) = RecurringOps.snapshot(r)
    private fun World.series(r: RecurringRuleEntity = rule) = txs.filter { it.templateId.equals(r.id, true) }
    private fun World.dates() = txs.map { it.date }.sorted()

    @Test fun deleteMonthlyFixedSeriesAllScopes() {
        for (scope in Scope.entries) {
            val w = setup(); w.rules = listOf(w.rule.copy(isFixed = true))
            for (m in 1..4) w.materialize(m)
            val unrelated = TransactionEntity(name = "Unrelated", amountCents = 500, type = "Uscita", date = ms(3))
            w.txs = w.txs + unrelated
            val ruleId = w.rule.id
            w.apply(Action.Delete(scope), original = date(3))
            assertTrue(w.txs.any { it.id == unrelated.id })
            val dates = w.txs.filter { it.templateId.equals(ruleId, true) }.map { it.date }.toSet()
            when (scope) {
                Scope.OnlyThis -> assertEquals(setOf(ms(1), ms(2), ms(4)), dates)
                Scope.Following -> assertEquals(setOf(ms(1), ms(2)), dates)
                Scope.All -> assertTrue(dates.isEmpty())
            }
            assertEquals(if (scope == Scope.All) 0 else 1, w.rules.size)
            if (scope != Scope.All) {
                w.materialize(5)
                assertTrue(w.txs.none { it.templateId.equals(ruleId, true) && it.date == ms(3) })
                if (scope == Scope.Following) assertTrue(w.txs.none { it.templateId.equals(ruleId, true) && it.date >= ms(3) })
            }
        }
    }

    @Test fun deleteFollowingIncludesSelectedCopyBeforeNoon() {
        val w = setup(start = 3); w.rules = listOf(w.rule.copy(isFixed = true)); w.materialize(3)
        w.txs = w.txs.map { it.copy(date = LocalDate.of(2026, 3, 1).atTime(8, 0).atZone(zone).toInstant().toEpochMilli()) }
        w.apply(Action.Delete(Scope.Following), original = date(3))
        assertTrue(w.txs.isEmpty())
    }

    @Test fun everyFieldRespectsScope() {
        for (scope in Scope.entries) {
            val acc = "11111111-1111-1111-1111-111111111111"
            val w = setup(accounts = setOf(acc)); w.rules = listOf(w.rule.copy(accountId = acc))
            for (m in 1..4) w.materialize(m)
            w.txs = w.txs.map { if (it.date == ms(1) || it.date == ms(3)) it.copy(isDone = true) else it }
            val v = w.snap().copy(name = "Uniform", amount = BigDecimal(42), category = "Casa", categoryIcon = "house", type = "Entrata", notes = "New notes", isFixed = true, accountId = null,
                startDate = if (scope == Scope.OnlyThis) date(3, 15) else w.snap().startDate)
            val result = w.apply(Action.Edit(scope, v), original = date(3))!!
            assertEquals(4, w.txs.size)
            for (t in w.txs) {
                val month = java.time.Instant.ofEpochMilli(t.date).atZone(zone).monthValue
                val changed = scope == Scope.All || (if (scope == Scope.Following) month >= 3 else month == 3)
                assertEquals(if (changed) "Uniform" else "Base", t.name)
                assertEquals(if (changed) 4200L else 20L, t.amountCents)
                assertEquals(if (changed) "Casa" else "Altro", t.category)
                assertEquals(if (changed) "Entrata" else "Uscita", t.type)
                assertEquals(changed, t.isFixed)
                assertEquals(if (changed) null else acc, t.accountId)
                assertEquals(month == 1 || month == 3, t.isDone)
            }
            val future = calc.occurrences(result.toSnapshot(), date(5), date(6)).first()
            assertEquals(if (scope == Scope.OnlyThis) "Base" else "Uniform", future.name)
        }
    }

    @Test fun allReplacesPriorOverridesButPreservesSkipsAndCompletion() {
        val w = setup(); for (m in 1..4) w.materialize(m)
        w.apply(Action.Edit(Scope.OnlyThis, w.snap().copy(name = "Single", amount = BigDecimal(7), category = "Casa", startDate = date(3, 15))), original = date(3), now = date(4))
        w.apply(Action.Delete(Scope.OnlyThis), original = date(2), now = date(4))
        w.txs = w.txs.map { if (it.date == ms(1)) it.copy(isDone = true) else it }
        w.apply(Action.Edit(Scope.All, w.snap().copy(name = "All", amount = BigDecimal(9), category = "Salute", categoryIcon = "heart")), original = date(3), now = date(4))
        assertTrue(w.txs.all { it.name == "All" && it.amountCents == 900L && it.category == "Salute" })
        assertTrue(w.txs.first { it.date == ms(1) }.isDone)
        assertTrue(w.txs.any { it.date == ms(3) })
        assertTrue(w.txs.all { it.date != ms(3, 15) && it.date != ms(2) })
        val ex = RecurrenceExceptionCodec.decode(w.rule.exceptionsJson)
        assertEquals(1, ex.size); assertTrue(ex["2026-02-01"]!!.skip)
    }

    @Test fun deleteFollowingUsesOriginalDayOfMovedCopy() {
        val w = setup("settimanale", 3); w.materialize(3)
        w.apply(Action.Edit(Scope.OnlyThis, w.snap().copy(startDate = date(3, 2))), original = date(3, 15))
        w.apply(Action.Delete(Scope.Following), original = date(3, 15))
        assertEquals(listOf(ms(3), ms(3, 8)), w.dates())
    }

    @Test fun allDateChangeReschedulesHistoryAndClampsShortMonths() {
        val w = setup(); w.rules = listOf(w.rule.copy(startDate = ms(1, 31)))
        for (m in 1..3) w.materialize(m)
        val doneId = w.txs.first { it.date == ms(1, 31) }.id
        w.txs = w.txs.map { if (it.id == doneId) it.copy(isDone = true) else it }
        w.apply(Action.Edit(Scope.All, w.snap().copy(startDate = date(1, 30))), original = date(3, 31))
        assertEquals(listOf(ms(1, 30), ms(2, 28), ms(3, 30)), w.dates())
        val done = w.txs.first { it.date == ms(1, 30) }
        assertTrue(done.isDone)
        for (t in w.txs) assertEquals(RecurrenceCalculator.occurrenceId(java.util.UUID.fromString(w.rule.id), calc.key(Instant.ofEpochMilli(t.date))).toString(), t.id)
        w.materialize(4)
        assertEquals(listOf(ms(1, 30), ms(2, 28), ms(3, 30), ms(4, 30)), w.dates())
    }

    @Test fun onlyThisOverrideAndDelete() {
        val w = setup(); w.materialize(3)
        w.apply(Action.Edit(Scope.OnlyThis, w.snap().copy(amount = BigDecimal("0.1"), name = "Override", startDate = date(3, 15))), original = date(3))
        val copy = w.txs.first()
        assertEquals(10L, copy.amountCents); assertEquals(ms(3, 15), copy.date); assertEquals("Override", copy.name)
        assertEquals(20L, w.rule.amountCents)
        assertEquals("0.1", RecurrenceExceptionCodec.decode(w.rule.exceptionsJson)["2026-03-01"]?.amount)
        w.apply(Action.Delete(Scope.OnlyThis), original = date(3))
        assertTrue(w.txs.isEmpty())
        assertTrue(RecurrenceExceptionCodec.decode(w.rule.exceptionsJson)["2026-03-01"]!!.skip)
        w.materialize(3)
        assertTrue(w.txs.isEmpty())
    }

    @Test fun skipWeeklyMonthKeepsDone() {
        val w = setup("settimanale", 3); w.materialize(3)
        val done = w.txs.first().let { it.copy(isDone = true) }
        w.txs = w.txs.map { if (it.id == done.id) done else it }
        w.apply(Action.SkipMonth, original = date(3))
        assertEquals(listOf(done.id), w.txs.map { it.id })
        assertEquals(5, RecurrenceExceptionCodec.decode(w.rule.exceptionsJson).size)
    }

    @Test fun terminateAndDeleteFollowing() {
        for (after in listOf(false, true)) {
            val w = setup("settimanale", 3); w.materialize(3)
            w.txs = w.txs.map { if (it.date == ms(3, 22)) it.copy(isDone = true) else it }
            w.apply(Action.Terminate(after), original = date(3, 15))
            assertEquals(if (after) ms(3, 15) else ms(3, 14), w.rule.endDate)
            assertEquals(if (after) 4 else 3, w.txs.size)
            assertTrue(w.txs.first { it.date == ms(3, 22) }.isDone.let { true })
        }
        val w = setup(); w.materialize(3)
        w.apply(Action.Delete(Scope.Following), original = date(3))
        assertTrue(w.txs.isEmpty()); assertEquals(ms(2, 28), w.rule.endDate)
    }

    @Test fun deleteAllAfterTerminatingBeforeFirstOccurrence() {
        val w = setup(); w.materialize(3)
        w.apply(Action.Terminate(false), original = date(1))
        assertTrue(w.rule.endDate!! < w.rule.startDate)
        assertNull(w.apply(Action.Delete(Scope.All), original = date(1)))
        assertTrue(w.rules.isEmpty()); assertTrue(w.txs.isEmpty())
    }

    @Test fun editAllReconcilesAndUpdatesDone() {
        val w = setup("settimanale", 3); w.materialize(3)
        val doneId = w.txs.first { it.date == ms(3, 8) }.id
        w.txs = w.txs.map { if (it.id == doneId) it.copy(isDone = true) else it }
        w.apply(Action.Edit(Scope.All, w.snap().copy(amount = BigDecimal("0.1"), name = "New")), original = date(3))
        val done = w.txs.first { it.id == doneId }
        assertTrue(done.amountCents == 10L && done.name == "New" && done.isDone)
        assertTrue(w.txs.filter { !it.isDone }.all { it.name == "New" && it.amountCents == 10L })
        w.apply(Action.Edit(Scope.All, w.snap().copy(frequency = "mensile", startDate = date(3, 20))), original = date(3))
        assertEquals(5, w.txs.size)
        assertEquals(ms(4, 20), w.txs.first { it.isDone }.date)
        assertEquals("{}", w.rule.exceptionsJson)
        assertTrue(w.txs.any { !it.isDone && it.date == ms(3, 20) })
    }

    @Test fun splitDropsFutureExceptionsAndReconciles() {
        val w = setup("settimanale", 3)
        w.rules = listOf(w.rule.copy(exceptionsJson = RecurrenceExceptionCodec.encode(mapOf(
            "2026-03-01" to com.bucktrail.android.domain.RecurrenceException(name = "Earlier"),
            "2026-04-05" to com.bucktrail.android.domain.RecurrenceException(skip = true)))))
        w.materialize(3)
        val oldId = w.rule.id
        val fresh = w.apply(Action.Edit(Scope.Following, w.snap().copy(amount = BigDecimal(5))), original = date(3, 15))!!
        assertTrue(fresh.id != oldId)
        assertEquals(ms(3, 15), fresh.startDate)
        val old = w.rules.first { it.id == oldId }
        assertEquals(ms(3, 14), old.endDate)
        assertEquals("{}", fresh.exceptionsJson)
        assertEquals(1, RecurrenceExceptionCodec.decode(old.exceptionsJson).size)
        assertEquals(3, w.txs.count { it.templateId.equals(fresh.id, true) })
        assertEquals(2, w.txs.count { it.templateId.equals(oldId, true) })
    }

    @Test fun deleteAllAndOnlyThisNeverTouchDoneOrLegacy() {
        for (scope in listOf(Scope.OnlyThis, Scope.All)) {
            val w = setup(); w.materialize(3)
            w.txs = w.txs.map { it.copy(isDone = true) } + TransactionEntity(name = "Legacy", amountCents = 1000, type = "Uscita", date = ms(3), recurringFrequency = "mensile")
            w.apply(Action.Delete(scope), original = date(3))
            assertEquals(2, w.txs.size)
            assertEquals(if (scope == Scope.All) 0 else 1, w.rules.size)
        }
    }

    @Test fun futureNilWatermarkStaysDueAndDoesNotCreateHistory() {
        val w = setup(start = 8)
        w.apply(Action.Edit(Scope.All, w.snap().copy(amount = BigDecimal(4))), original = date(8), now = date(3))
        assertNull(w.rule.materializedThrough); assertTrue(w.txs.isEmpty())
        w.materialize(3); assertTrue(w.txs.isEmpty())
        w.materialize(8)
        assertEquals(1, w.txs.size); assertEquals(400L, w.txs.first().amountCents)
    }

    @Test fun virtualOverrideAndCrossMonthValidation() {
        val w = setup()
        w.apply(Action.Edit(Scope.OnlyThis, w.snap().copy(startDate = date(8, 10))), original = date(8))
        assertTrue(w.txs.isEmpty())
        val before = w.rule.exceptionsJson
        assertEquals(RecurringOps.Problem.CrossMonthOverride, assertThrows(RecurringOps.EditorException::class.java) {
            w.apply(Action.Edit(Scope.OnlyThis, w.snap().copy(startDate = date(9))), original = date(8))
        }.problem)
        assertEquals(before, w.rule.exceptionsJson)
        assertEquals(ms(8, 10), RecurrenceExceptionCodec.decode(w.rule.exceptionsJson)["2026-08-01"]?.date?.toEpochMilli())
        assertEquals(RecurringOps.Problem.InvalidValues, assertThrows(RecurringOps.EditorException::class.java) {
            w.apply(Action.Edit(Scope.All, w.snap().copy(frequency = "giornaliera")), original = date(8))
        }.problem)
        assertEquals(RecurringOps.Problem.InvalidOccurrence, assertThrows(RecurringOps.EditorException::class.java) {
            w.apply(Action.Delete(Scope.All), original = date(8, 5))
        }.problem)
    }

    @Test fun splitDoesNotDuplicateCompletedCurrentOccurrence() {
        val w = setup("settimanale", 3); w.materialize(3)
        w.txs = w.txs.map { if (it.date == ms(3, 22)) it.copy(isDone = true) else it }
        w.apply(Action.Edit(Scope.Following, w.snap().copy(amount = BigDecimal(8))), original = date(3, 15))
        assertEquals(5, w.txs.size)
        val done = w.txs.filter { it.date == ms(3, 22) }
        assertEquals(1, done.size); assertTrue(done.single().isDone); assertEquals(800L, done.single().amountCents)
        w.materialize(3)
        assertEquals(5, w.txs.size)
    }

    @Test fun resolveFindsOriginalOccurrenceOfMovedCopy() {
        val w = setup(); w.materialize(3)
        w.apply(Action.Edit(Scope.OnlyThis, w.snap().copy(startDate = date(3, 15))), original = date(3))
        val sel = RecurringOps.resolve(w.txs.first(), w.rules, zone)!!
        assertEquals(date(3), sel.occurrence.originalDate); assertEquals(date(3, 15), sel.occurrence.date)
        assertNull(RecurringOps.resolve(w.txs.first().copy(templateId = ""), w.rules, zone))
        assertFalse(Amounts.TYPE_INCOME == sel.occurrence.type)
    }
}
