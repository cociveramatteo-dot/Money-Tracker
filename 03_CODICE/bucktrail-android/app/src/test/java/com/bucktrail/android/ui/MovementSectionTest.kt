package com.bucktrail.android.ui

import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.UUID

class MovementSectionTest {
    private val zone: ZoneId = ZoneId.of("Europe/Rome")

    private fun millis(year: Int, month: Int, day: Int): Long =
        LocalDate.of(year, month, day).atTime(12, 0).atZone(zone).toInstant().toEpochMilli()

    @Test
    fun recurringSectionKeepsOnlyExistingRulesInChosenMonthEvenWithQuery() {
        val activeRuleId = UUID.randomUUID().toString()
        val deletedRuleId = UUID.randomUUID().toString()

        val inMonthActive = TransactionEntity(
            id = "1", name = "Bolletta Enel", amountCents = 9000, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 11, 15), isDone = true, isFixed = true, templateId = activeRuleId.uppercase(),
        )
        val otherMonthActive = TransactionEntity(
            id = "2", name = "Bolletta Enel", amountCents = 8500, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 10, 15), isDone = true, isFixed = true, templateId = activeRuleId.uppercase(),
        )
        val deletedRuleTx = TransactionEntity(
            id = "3", name = "Bolletta vecchia", amountCents = 5000, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 11, 10), isDone = true, isFixed = true, templateId = deletedRuleId.uppercase(),
        )
        val manualTx = TransactionEntity(
            id = "4", name = "Bolletta Enel", amountCents = 4000, type = Amounts.TYPE_EXPENSE,
            category = "Casa", date = millis(2026, 11, 20), isDone = true, templateId = "",
        )

        val result = MovementSectionFilter.filterTransactions(
            transactions = listOf(inMonthActive, otherMonthActive, deletedRuleTx, manualTx),
            section = MovementSection.Recurring,
            ruleIds = setOf(activeRuleId.lowercase()),
            query = "Bolletta",
            month = YearMonth.of(2026, 11),
            category = null,
            minText = "",
            maxText = "",
            useDates = false,
            from = null,
            to = null,
            zone = zone,
        )

        assertEquals(listOf("1"), result.map { it.id })
    }

    @Test
    fun recurringSectionIncludesVirtualsAndAppliesCategoryAndAmountFilters() {
        val ruleId = UUID.randomUUID()
        val rule = RecurringRuleEntity(
            id = ruleId.toString(),
            name = "Affitto",
            amountCents = 75000,
            category = "Casa",
            categoryIcon = "house",
            type = Amounts.TYPE_EXPENSE,
            frequency = "mensile",
            startDate = millis(2026, 11, 1),
            isFixed = true,
        )
        val occCasa = Occurrence(
            ruleId = ruleId,
            key = "2026-12-03",
            originalDate = LocalDate.of(2026, 12, 3).atTime(12, 0).atZone(zone).toInstant(),
            date = LocalDate.of(2026, 12, 3).atTime(12, 0).atZone(zone).toInstant(),
            amount = BigDecimal("750.00"),
            name = "Affitto",
            category = "Casa",
            categoryIcon = "house",
            type = Amounts.TYPE_EXPENSE,
            accountId = null,
            isFixed = true,
            notes = "",
            isOverridden = false,
        )
        val occSmall = occCasa.copy(key = "2026-12-05", amount = BigDecimal("30.00"), name = "Streaming", category = "Abbonamenti")

        val matched = MovementSectionFilter.filterVirtual(
            occurrences = listOf(rule to occCasa, rule to occSmall),
            realIds = emptySet(),
            section = MovementSection.Recurring,
            query = "",
            category = "Casa",
            minText = "500",
            maxText = "900",
            useDates = false,
            from = null,
            to = null,
            zone = zone,
        )

        assertEquals(listOf("Affitto"), matched.map { it.second.name })
    }
}
