package com.bucktrail.android.ui

import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

class MovementListLayoutTest {
    private val zone: ZoneId = ZoneId.of("Europe/Rome")

    private fun instant(year: Int, month: Int, day: Int): Instant =
        LocalDate.of(year, month, day).atTime(12, 0).atZone(zone).toInstant()

    private fun millis(year: Int, month: Int, day: Int): Long = instant(year, month, day).toEpochMilli()

    private fun rule(name: String, amountCents: Long, type: String): RecurringRuleEntity =
        RecurringRuleEntity(
            id = UUID.randomUUID().toString(),
            name = name,
            amountCents = amountCents,
            category = "Casa",
            categoryIcon = "house",
            type = type,
            frequency = "mensile",
            startDate = millis(2026, 11, 1),
            isFixed = true,
        )

    private fun occurrence(rule: RecurringRuleEntity, day: LocalDate, amount: BigDecimal, type: String): Occurrence =
        Occurrence(
            ruleId = UUID.fromString(rule.id),
            key = day.toString(),
            originalDate = day.atTime(12, 0).atZone(zone).toInstant(),
            date = day.atTime(12, 0).atZone(zone).toInstant(),
            amount = amount,
            name = rule.name,
            category = rule.category,
            categoryIcon = rule.categoryIcon,
            type = type,
            accountId = null,
            isFixed = true,
            notes = "",
            isOverridden = false,
        )

    @Test
    fun futureMonthCombinesPlannedAndVirtualsAscendingAndExcludesTransfersFromTotal() {
        val realPlannedLater = TransactionEntity(
            id = "p2", name = "Bolletta", amountCents = 8000, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 12, 20), isDone = false, createdAt = 100L,
        )
        val realPlannedEarlier = TransactionEntity(
            id = "p1", name = "Regalo", amountCents = 5000, type = Amounts.TYPE_EXPENSE,
            category = "Regali", date = millis(2026, 12, 5), isDone = false, createdAt = 200L,
        )
        val realTransfer = TransactionEntity(
            id = "t1", name = "Giroconto", amountCents = 50000, type = Amounts.TYPE_EXPENSE,
            category = "Altro", date = millis(2026, 12, 10), isDone = false, isTransfer = true, createdAt = 300L,
        )
        val realDone = TransactionEntity(
            id = "d1", name = "Anticipo", amountCents = 10000, type = Amounts.TYPE_INCOME,
            category = "Lavoro", date = millis(2026, 12, 1), isDone = true, createdAt = 400L,
        )
        val r1 = rule("Stipendio", 200000, Amounts.TYPE_INCOME)
        val r2 = rule("Abbonamento", 1200, Amounts.TYPE_EXPENSE)
        val o1 = occurrence(r1, LocalDate.of(2026, 12, 15), BigDecimal("2000.00"), Amounts.TYPE_INCOME)
        val o2 = occurrence(r2, LocalDate.of(2026, 12, 2), BigDecimal("12.00"), Amounts.TYPE_EXPENSE)

        val result = MovementListLayout.make(
            real = listOf(realPlannedLater, realPlannedEarlier, realTransfer, realDone),
            virtual = listOf(r1 to o1, r2 to o2),
            isFutureMonth = true,
            zone = zone,
        )

        val names = result.planned.map {
            when (it) {
                is MovementItem.Real -> it.tx.name
                is MovementItem.Virtual -> it.occurrence.name
            }
        }
        assertEquals(listOf("Abbonamento", "Regalo", "Giroconto", "Stipendio", "Bolletta"), names)

        val total = result.planned.fold(BigDecimal.ZERO) { acc, item -> acc + item.signedAmount }
        assertEquals(0, BigDecimal("1858.00").compareTo(total))
        assertEquals(1, result.days.size)
        assertEquals(1, result.days[0].items.size)
        assertEquals(6, result.planned.size + result.days.sumOf { it.items.size })
    }

    @Test
    fun currentMonthKeepsPlannedInsideDayGroupsInDisplayOrder() {
        val older = TransactionEntity(
            id = "old", name = "Vecchia", amountCents = 2000, type = Amounts.TYPE_EXPENSE,
            category = "Cibo", date = millis(2026, 11, 10), isDone = true, createdAt = 100L,
        )
        val sameDayEarlier = TransactionEntity(
            id = "e1", name = "Prima", amountCents = 1000, type = Amounts.TYPE_EXPENSE,
            category = "Cibo", date = millis(2026, 11, 20), isDone = true, createdAt = 200L,
        )
        val sameDayPlannedNewer = TransactionEntity(
            id = "p1", name = "Pianificata", amountCents = 4500, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 11, 20), isDone = false, createdAt = 300L,
        )

        val result = MovementListLayout.make(
            real = listOf(older, sameDayEarlier, sameDayPlannedNewer),
            virtual = emptyList(),
            isFutureMonth = false,
            zone = zone,
        )

        assertTrue(result.planned.isEmpty())
        assertEquals(2, result.days.size)
        assertEquals(LocalDate.of(2026, 11, 20), result.days[0].day)
        assertEquals(listOf("p1", "e1"), result.days[0].items.map { it.id })
        assertEquals(LocalDate.of(2026, 11, 10), result.days[1].day)
        assertEquals(3, result.days.sumOf { it.items.size })
    }

    @Test
    fun pastMonthWithUnconfirmedTransactionShowsItInDayGroupWithoutTopSection() {
        val pastPlanned = TransactionEntity(
            id = "pp", name = "Pianificata passata", amountCents = 3000, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 10, 12), isDone = false, createdAt = 100L,
        )
        val pastDone = TransactionEntity(
            id = "pd", name = "Fatta passata", amountCents = 1500, type = Amounts.TYPE_INCOME,
            category = "Altro", date = millis(2026, 10, 12), isDone = true, createdAt = 200L,
        )

        val result = MovementListLayout.make(
            real = listOf(pastPlanned, pastDone),
            virtual = emptyList(),
            isFutureMonth = false,
            zone = zone,
        )

        assertTrue(result.planned.isEmpty())
        assertEquals(1, result.days.size)
        assertEquals(listOf("pd", "pp"), result.days[0].items.map { it.id })
    }

    @Test
    fun preservesExactItemCountAcrossEmptyAndMixedInputs() {
        val real = listOf(
            TransactionEntity(id = "1", name = "A", amountCents = 1000, type = Amounts.TYPE_EXPENSE, category = "Cibo", date = millis(2026, 12, 1), isDone = true),
            TransactionEntity(id = "2", name = "B", amountCents = 2000, type = Amounts.TYPE_EXPENSE, category = "Cibo", date = millis(2026, 12, 1), isDone = false),
        )
        val r = rule("V", 3000, Amounts.TYPE_EXPENSE)
        val virtual = listOf(r to occurrence(r, LocalDate.of(2026, 12, 2), BigDecimal("30.00"), Amounts.TYPE_EXPENSE))

        val future = MovementListLayout.make(real, virtual, isFutureMonth = true, zone = zone)
        val current = MovementListLayout.make(real, virtual, isFutureMonth = false, zone = zone)
        val empty = MovementListLayout.make(emptyList(), emptyList(), isFutureMonth = true, zone = zone)

        assertEquals(real.size + virtual.size, future.planned.size + future.days.sumOf { it.items.size })
        assertEquals(real.size + virtual.size, current.planned.size + current.days.sumOf { it.items.size })
        assertTrue(empty.planned.isEmpty() && empty.days.isEmpty())
    }
}
