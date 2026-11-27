package com.bucktrail.android.ui

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.HomeProjection
import java.math.BigDecimal

data class WhatIfBaseline(
    val id: String,
    val name: String?,
    val today: BigDecimal,
    val endOfMonth: BigDecimal,
    val isExcludedFromTotal: Boolean = false,
)

data class WhatIfHypothesis(
    val id: String,
    val amountText: String = "",
    val isIncome: Boolean = false,
    val name: String = "",
    val isOn: Boolean = true,
)

data class WhatIfResult(
    val todayNow: BigDecimal,
    val todayWith: BigDecimal,
    val endNow: BigDecimal,
    val endWith: BigDecimal,
    val delta: BigDecimal,
)

object WhatIfScenario {
    const val MAX_HYPOTHESES = 20

    /** Parses positive amounts <= 1e9; sign is controlled only by the -/+ button. */
    fun amount(text: String): BigDecimal? {
        val trimmed = text.trim()
        if (trimmed.isEmpty() || trimmed.contains('-') || trimmed.contains('+')) return null
        val parsed = Amounts.parse(trimmed) ?: return null
        return parsed.takeIf { Amounts.isValidInput(it) }
    }

    fun isInvalidInput(text: String): Boolean {
        val trimmed = text.trim()
        return trimmed.isNotEmpty() && amount(trimmed) == null
    }

    fun delta(items: List<WhatIfHypothesis>): BigDecimal =
        items.fold(BigDecimal.ZERO) { acc, item ->
            if (!item.isOn) return@fold acc
            val value = amount(item.amountText) ?: return@fold acc
            acc + if (item.isIncome) value else value.negate()
        }

    fun result(baseline: WhatIfBaseline, items: List<WhatIfHypothesis>): WhatIfResult {
        val d = delta(items)
        return WhatIfResult(
            todayNow = baseline.today,
            todayWith = baseline.today + d,
            endNow = baseline.endOfMonth,
            endWith = baseline.endOfMonth + d,
            delta = d,
        )
    }

    fun baselines(
        accounts: List<AccountEntity>,
        transactions: List<TransactionEntity>,
        projection: HomeProjection,
        balances: Map<String, BigDecimal>,
    ): List<WhatIfBaseline> {
        val all = WhatIfBaseline(
            id = "all",
            name = null,
            today = projection.total,
            endOfMonth = projection.trail.expectedBalance,
        )
        val active = accounts.filter { !it.isArchived }
        val included = active.filter { !it.isExcludedFromTotal }
            .sortedByDescending { balances[it.id] ?: BigDecimal.ZERO }
            .map { acc ->
                val today = balances[acc.id] ?: BigDecimal.ZERO
                WhatIfBaseline(
                    id = acc.id,
                    name = acc.name,
                    today = today,
                    endOfMonth = today + (projection.plannedByAccount[acc.id] ?: BigDecimal.ZERO),
                )
            }
        val txData = transactions.map { it.toData() }
        val excluded = active.filter { it.isExcludedFromTotal }
            .map { acc ->
                val data = acc.toData()
                val today = Balance.current(data, txData)
                WhatIfBaseline(
                    id = acc.id,
                    name = acc.name,
                    today = today,
                    endOfMonth = Balance.future(data, txData),
                    isExcludedFromTotal = true,
                )
            }
            .sortedByDescending { it.today }
        return listOf(all) + included + excluded
    }
}
