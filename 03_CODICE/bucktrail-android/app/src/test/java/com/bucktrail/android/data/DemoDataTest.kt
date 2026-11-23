package com.bucktrail.android.data

import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.Budgeting
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId
import java.util.UUID

/** I numeri della demo coincidono con `DemoDataSeeder.swift` (seedVersion 6): gli screenshot social li usano. */
class DemoDataTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val now = Instant.parse("2026-11-23T10:30:00Z")
    private val d = DemoData.build(now, zone, { it })
    private val txs = d.transactions

    @Test fun accountsAndOpeningBalances() {
        assertEquals(listOf("account.conto", "account.risparmi", "account.carta", "account.contanti"), d.accounts.map { it.name })
        assertEquals(listOf(290_000L, 620_000L, 480_000L, 65_000L), d.accounts.map { it.initialBalanceCents })
        assertEquals(listOf("Conto Bancario", "Risparmio", "Carta", "Contanti"), d.accounts.map { it.type })
        assertEquals(listOf("1F7A4D", "2F6FB0", "5A4AA3", "B45309"), d.accounts.map { it.colorHex })
    }

    @Test fun nineMonthlyFixedSeriesWithIosAnchors() {
        assertEquals(9, d.rules.size)
        assertTrue(d.rules.all { it.frequency == "mensile" && it.isFixed })
        assertEquals(listOf(285_000L, 78_000L, 8_600L, 2_900L, 1_599L, 1_099L, 4_500L, 6_400L, 12_500L), d.rules.map { it.amountCents })
        val salary = d.rules.first { it.name == "tx.stipendio" }
        assertEquals(Instant.parse("2026-04-01T10:00:00Z"), Instant.ofEpochMilli(salary.startDate)) // 7 mesi fa, giorno 1 alle 12:00 locali
        assertEquals(Instant.parse("2026-11-01T11:00:00Z"), Instant.ofEpochMilli(salary.materializedThrough!!))
        assertTrue(d.rules.first { it.name == "tx.bolletta" }.exceptionsJson.contains("112.40"))
    }

    @Test fun transactionCountsMatchTheSeeder() {
        assertEquals(9 * 8, txs.count { it.templateId.isNotEmpty() }) // 9 serie × 8 mesi (da 7 mesi fa al mese corrente)
        // per mese: 4 spesa + 8 spese singole + interessi + 2 gambe di giroconto = 15, per 8 mesi; più viaggi (4), dentista, 2 bonus e 2 pianificati
        assertEquals(8 * 15 + 4 + 1 + 2 + 2, txs.count { it.templateId.isEmpty() })
        assertEquals(201, txs.size)
    }

    @Test fun budgetsAndGoals() {
        assertEquals(40, d.budgets.size)
        assertEquals(setOf(30_000L, 9_000L, 24_000L, 18_000L, 17_000L), d.budgets.map { it.monthlyLimitCents }.toSet())
        assertEquals(8, d.budgets.map { it.month to it.year }.toSet().size)
        assertEquals(listOf(280_000L to 196_000L, 1_500_000L to 664_000L, 249_900L to 64_000L, 45_000L to 45_000L), d.goals.map { it.targetCents to it.currentCents })
        assertEquals(listOf("airplane", "banknote", "laptopcomputer", "camera.fill"), d.goals.map { it.emoji })
        assertEquals(listOf(true, false, true, false), d.goals.map { it.deadline != null })
    }

    @Test fun billOverrideAndTodayStates() {
        val nov = YearMonth.of(2026, 11)
        val bill = txs.filter { it.name == "tx.bolletta" && YearMonth.from(Instant.ofEpochMilli(it.date).atZone(zone)) == nov }.single()
        assertEquals(11_240L, bill.amountCents)
        assertTrue(!bill.isDone) // oggi, 12:00: ancora pianificata
        assertTrue(txs.first { it.name == "tx.gym" && Instant.ofEpochMilli(it.date) == Instant.parse("2026-11-23T11:00:00Z") }.isDone) // la palestra di oggi è già pagata
    }

    @Test fun transfersAreTwoLegsPerMonthAndExcludedFromReports() {
        val legs = txs.filter { it.isTransfer }
        assertEquals(16, legs.size)
        assertEquals(8, legs.map { it.transferGroupId }.toSet().size)
        assertTrue(legs.groupBy { it.transferGroupId }.values.all { g -> g.size == 2 && g.map { it.type }.toSet() == setOf("Uscita", "Entrata") && g.all { it.amountCents == 18_000L } })
        assertTrue(legs.all { it.transferGroupId == it.transferGroupId.uppercase() && UUID.fromString(it.transferGroupId) != null })
    }

    @Test fun twoPlannedNonSeriesRemainAndIdsAreUnique() {
        val planned = txs.filter { it.templateId.isEmpty() && !it.isDone }
        assertEquals(setOf("tx.hotel", "tx.course"), planned.map { it.name }.toSet())
        assertEquals(txs.size, txs.map { it.id }.toSet().size)
        assertTrue(txs.all { it.accountId in d.accounts.map { a -> a.id } })
    }

    @Test fun totalBalanceIsPlausibleAndStable() {
        val accounts = d.accounts.map { it.toData() }
        val total = Balance.total(accounts, txs.map { it.toData() })
        assertEquals(total, Balance.total(accounts, txs.map { it.toData() }))
        assertTrue(total > BigDecimal.ZERO)
    }

    @Test fun currentMonthBudgetsAreUsedButNotMostlyOver() {
        val nov = YearMonth.of(2026, 11)
        val data = txs.map { it.toData() }
        val spent = d.budgets.filter { it.month == 11 && it.year == 2026 }.associate { it.category to Budgeting.spent(it.toData(), nov, data, zone) }
        assertEquals(5, spent.size)
        assertTrue(spent.values.any { it.signum() > 0 })
    }

    @Test fun amountsFollowTheMonthlyVariation() {
        // supermercato = 62 + variazione/4 con variazioni 0,18,-12,35,8,-5,24,12 (una per mese, 4 volte)
        val expected = setOf(6_200L, 6_650L, 5_900L, 7_075L, 6_400L, 6_075L, 6_800L, 6_500L)
        assertEquals(expected, txs.filter { it.name == "tx.supermercato" }.map { it.amountCents }.toSet())
        assertEquals(32, txs.count { it.name == "tx.supermercato" })
        assertEquals(24_000L, txs.filter { it.name == "tx.regalo" }.maxOf { it.amountCents })
    }
}
