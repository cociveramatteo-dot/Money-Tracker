package com.bucktrail.android.domain

import com.bucktrail.android.domain.RecurringMaterializer.RuleState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/** Scenari da RecurringMaterializerTests.swift (la parte pura: cosa inserire e quale watermark). */
class RecurringMaterializerTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val calc = RecurrenceCalculator(zone)
    private fun date(y: Int = 2026, m: Int, d: Int = 1): Instant = LocalDate.of(y, m, d).atTime(12, 0).atZone(zone).toInstant()
    private fun rule(start: Instant, frequency: String = "mensile") =
        RuleSnapshot(UUID.randomUUID(), "Affitto", BigDecimal("0.2"), "Uscita", "Casa", "house", isFixed = true, frequency = frequency, startDate = start)

    @Test fun currentMonthIsPlannedIncludingFutureDaysAndSecondRunIsNoOp() {
        val r = rule(date(2026, 1, 31))
        val plan = RecurringMaterializer.plan(listOf(RuleState(r, null, emptySet())), date(2026, 3, 1), calc)
        assertEquals(listOf(date(2026, 3, 31)), plan.toInsert.map { it.date })
        assertEquals(RecurrenceCalculator.occurrenceId(r.id, "2026-03-31"), plan.toInsert.single().id)
        assertEquals(date(2026, 3), plan.watermarks[r.id])
        val again = RecurringMaterializer.plan(listOf(RuleState(r, plan.watermarks[r.id], plan.toInsert.map { it.id }.toSet())), date(2026, 3, 31), calc)
        assertTrue(again.toInsert.isEmpty())
    }

    @Test fun threeMissedMonthsRecoverInOneRun() {
        val r = rule(date(2026, 1, 31))
        val plan = RecurringMaterializer.plan(listOf(RuleState(r, date(2026, 1), emptySet())), date(2026, 4, 1), calc)
        assertEquals(listOf(date(2026, 2, 28), date(2026, 3, 31), date(2026, 4, 30)), plan.toInsert.map { it.date })
        assertEquals(date(2026, 4), plan.watermarks[r.id])
    }

    @Test fun backfillIsCappedAtThirtySixMonths() {
        val r = rule(date(2000, 1, 15))
        val plan = RecurringMaterializer.plan(listOf(RuleState(r, date(2000, 1), emptySet())), date(2026, 11, 1), calc)
        assertEquals(36, plan.toInsert.size)
        assertEquals(date(2023, 12, 15), plan.toInsert.first().date)
        assertEquals(date(2026, 11, 15), plan.toInsert.last().date)
        assertEquals(date(2026, 11), plan.watermarks[r.id])
    }

    @Test fun newRuleNeverGeneratesPastMonthsAndFutureRulesWait() {
        val past = rule(date(2000, 1, 15)); val future = rule(date(2026, 6, 15))
        val plan = RecurringMaterializer.plan(listOf(RuleState(past, null, emptySet()), RuleState(future, null, emptySet())), date(2026, 3, 1), calc)
        assertEquals(listOf(date(2026, 3, 15)), plan.toInsert.map { it.date })
        assertEquals(date(2026, 3), plan.watermarks[past.id])
        assertEquals(date(2026, 5), plan.watermarks[future.id])
        val later = RecurringMaterializer.plan(listOf(RuleState(future, date(2026, 5), emptySet())), date(2026, 6, 1), calc)
        assertEquals(listOf(date(2026, 6, 15)), later.toInsert.map { it.date })
    }

    @Test fun terminatedRulesSkipsAndExistingCopiesCreateNothing() {
        val ended = rule(date(2026, 1, 15)).copy(endDate = date(2026, 2, 15))
        val skipped = rule(date(2026, 3, 1), "settimanale").copy(exceptions = mapOf("2026-03-01" to RecurrenceException(skip = true)))
        val plan = RecurringMaterializer.plan(listOf(RuleState(ended, date(2026, 2), emptySet()), RuleState(skipped, null, emptySet())), date(2026, 3, 1), calc)
        assertEquals(4, plan.toInsert.size)
        assertTrue(plan.toInsert.none { it.ruleId == ended.id })
        val existing = RecurrenceCalculator.occurrenceId(skipped.id, "2026-03-08")
        val replan = RecurringMaterializer.plan(listOf(RuleState(skipped, date(2026, 2), setOf(existing))), date(2026, 3, 1), calc)
        assertEquals(3, replan.toInsert.size)
    }

    @Test fun invalidFrequencyIsIgnored() {
        val plan = RecurringMaterializer.plan(listOf(RuleState(rule(date(2026, 1, 1), "xx"), null, emptySet())), date(2026, 3, 1), calc)
        assertTrue(plan.toInsert.isEmpty() && plan.watermarks.isEmpty())
    }
}
