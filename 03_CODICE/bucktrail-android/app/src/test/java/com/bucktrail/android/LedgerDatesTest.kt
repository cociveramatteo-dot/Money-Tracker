package com.bucktrail.android

import org.junit.Assert.assertEquals
import org.junit.Test
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

class LedgerDatesTest {
    private val today = LocalDate.of(2026, 11, 21)
    private val zone = ZoneId.of("Europe/Rome")
    private val account = Account("main", "Conto", 10_000)

    @Test fun includesOnlyCurrentMonthPlansInProjection() {
        val current = Movement("current", "main", "Bolletta", -2_000, entryDay = today.plusDays(2).toEpochDay())
        val next = Movement("next", "main", "Tasse", -3_000, entryDay = today.plusMonths(1).toEpochDay(), planned = true)
        val overdue = Movement("overdue", "main", "Precedente", -1_000, entryDay = today.minusMonths(1).toEpochDay(), planned = true)
        val snapshot = summarize(listOf(AccountWithMovements(account, listOf(next, current, overdue))), today, zone)
        assertEquals(10_000L, snapshot.accounts.single().cents)
        assertEquals(8_000L, snapshot.expectedBalance)
        assertEquals(listOf("overdue", "current", "next"), snapshot.planned.map { it.entry.id })
    }

    @Test fun keepsLegacyMovementsAndOnlyBooksDueEntriesWhenConfirmed() {
        val old = Movement("old", "main", "Vecchia spesa", -500, Instant.parse("2026-11-20T23:00:00Z").toEpochMilli())
        val pending = Movement("pending", "main", "Spesa", -2_000, entryDay = today.toEpochDay(), planned = true)
        val before = summarize(listOf(AccountWithMovements(account, listOf(old, pending))), today, zone)
        assertEquals(9_500L, before.accounts.single().cents)
        assertEquals(today, before.booked.single().date)
        val after = summarize(listOf(AccountWithMovements(account, listOf(old, pending.copy(planned = false)))), today, zone)
        assertEquals(7_500L, after.accounts.single().cents)
        assertEquals(0, after.planned.size)
    }
}
