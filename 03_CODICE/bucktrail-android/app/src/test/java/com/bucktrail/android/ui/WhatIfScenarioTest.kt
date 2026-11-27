package com.bucktrail.android.ui

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.HomeProjection
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId

class WhatIfScenarioTest {
    @Test
    fun emptyAndValidSumsAndDisabled() {
        assertEquals(BigDecimal.ZERO, WhatIfScenario.delta(emptyList()))
        val items = listOf(
            WhatIfHypothesis("1", "150", isIncome = false, name = "cena", isOn = true),
            WhatIfHypothesis("2", "350", isIncome = true, name = "lavoretto", isOn = true),
            WhatIfHypothesis("3", "999", isIncome = false, name = "spenta", isOn = false),
        )
        assertEquals(0, BigDecimal("200").compareTo(WhatIfScenario.delta(items)))
    }

    @Test
    fun validatesBoundsSignAndDecimalRounding() {
        assertNull(WhatIfScenario.amount(""))
        assertNull(WhatIfScenario.amount("0"))
        assertNull(WhatIfScenario.amount("abc"))
        assertNull(WhatIfScenario.amount("-10"))
        assertNull(WhatIfScenario.amount("+10"))
        assertNull(WhatIfScenario.amount("1000000001"))
        assertEquals(0, BigDecimal("1000000000").compareTo(WhatIfScenario.amount("1000000000")))
        assertEquals(0, BigDecimal("12.35").compareTo(WhatIfScenario.amount("12,345")))

        assertFalse(WhatIfScenario.isInvalidInput(""))
        assertFalse(WhatIfScenario.isInvalidInput("   "))
        assertTrue(WhatIfScenario.isInvalidInput("abc"))
        assertTrue(WhatIfScenario.isInvalidInput("-15"))
        assertFalse(WhatIfScenario.isInvalidInput("15,50"))

        val exact = WhatIfScenario.delta(
            listOf(
                WhatIfHypothesis("1", "0.1", isIncome = true, isOn = true),
                WhatIfHypothesis("2", "0,2", isIncome = true, isOn = true),
            ),
        )
        assertEquals(0, BigDecimal("0.3").compareTo(exact))
    }

    @Test
    fun resultAndBaselinesIncludeExcludedAccountsAndSkipArchived() {
        val baseline = WhatIfBaseline("acc", "Carta", BigDecimal("-50"), BigDecimal("-120"))
        val res = WhatIfScenario.result(
            baseline,
            listOf(
                WhatIfHypothesis("1", "150", isIncome = false, isOn = true),
                WhatIfHypothesis("2", "abc", isIncome = true, isOn = true),
            ),
        )
        assertEquals(0, BigDecimal("-150").compareTo(res.delta))
        assertEquals(0, BigDecimal("-200").compareTo(res.todayWith))
        assertEquals(0, BigDecimal("-270").compareTo(res.endWith))

        val inc = AccountEntity("a1", "Conto", initialBalanceCents = 100_00)
        val exc = AccountEntity("a2", "Fondo", initialBalanceCents = 500_00, isExcludedFromTotal = true)
        val arc = AccountEntity("a3", "Vecchio", initialBalanceCents = 999_00, isArchived = true)
        val today = LocalDate.of(2026, 11, 27)
        val zone = ZoneId.of("Europe/Rome")
        val txs = listOf(
            TransactionEntity(
                id = "t1",
                accountId = "a2",
                name = "Bonus",
                amountCents = 50_00,
                type = Amounts.TYPE_INCOME,
                date = today.atTime(12, 0).atZone(zone).toInstant().toEpochMilli(),
                isDone = false,
            ),
        )
        val accounts = listOf(inc, exc, arc)
        val projection = HomeProjection.make(accounts.map { AccountEntity(it.id, it.name, it.type, it.initialBalanceCents, it.colorHex, it.createdAt, it.isArchived, it.isExcludedFromTotal) }.let {
            listOf(
                com.bucktrail.android.domain.AccountData("a1", "Conto", "Conto Bancario", BigDecimal("100.00")),
                com.bucktrail.android.domain.AccountData("a2", "Fondo", "Conto Bancario", BigDecimal("500.00"), isExcludedFromTotal = true),
                com.bucktrail.android.domain.AccountData("a3", "Vecchio", "Conto Bancario", BigDecimal("999.00"), isArchived = true),
            )
        }, emptyList(), today, zone)
        val baselines = WhatIfScenario.baselines(accounts, txs, projection, mapOf("a1" to BigDecimal("100.00")))
        assertEquals(listOf("all", "a1", "a2"), baselines.map { it.id })
        assertTrue(baselines.last().isExcludedFromTotal)
        assertEquals(0, BigDecimal("550.00").compareTo(baselines.last().endOfMonth))
    }
}
