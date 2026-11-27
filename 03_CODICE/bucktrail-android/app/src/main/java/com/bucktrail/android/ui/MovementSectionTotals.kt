package com.bucktrail.android.ui

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import com.bucktrail.android.ui.screens.FixedTotalTile
import com.bucktrail.android.ui.screens.amountValue
import com.bucktrail.android.ui.screens.money
import com.bucktrail.android.ui.theme.Bt
import java.math.BigDecimal

enum class MovementTotalsKind { All, Fixed, Expense, Income, Transfer, Recurring }

object MovementSectionTotals {
    data class Totals(
        val expenses: BigDecimal,
        val income: BigDecimal,
        val transferred: BigDecimal,
    )

    /**
     * Calcola i totali sulle stesse righe mostrate dalla lista (reali + virtuali),
     * escludendo i trasferimenti da spese/entrate e deduplicandoli per `transferGroupId`.
     */
    fun compute(real: List<TransactionEntity>, virtual: List<Occurrence>): Totals {
        var expenses = BigDecimal.ZERO
        var income = BigDecimal.ZERO
        var transferred = BigDecimal.ZERO
        val seenGroups = HashSet<String>()

        for (t in real) {
            val amount = t.amountValue()
            if (t.isTransfer) {
                val group = t.transferGroupId.trim().lowercase()
                if (group.isNotEmpty() && !seenGroups.add(group)) continue
                transferred += amount
            } else if (t.type == Amounts.TYPE_INCOME) {
                income += amount
            } else {
                expenses += amount
            }
        }

        for (occ in virtual) {
            if (occ.type == Amounts.TYPE_INCOME) {
                income += occ.amount
            } else {
                expenses += occ.amount
            }
        }

        return Totals(expenses = expenses, income = income, transferred = transferred)
    }
}

@Composable
fun MovementTotalsBlock(
    kind: MovementTotalsKind,
    totals: MovementSectionTotals.Totals,
    currency: String,
    hidden: Boolean,
    modifier: Modifier = Modifier,
) {
    val c = Bt.colors
    val stacked = LocalDensity.current.fontScale >= 1.6f
    val expColor = c.negative.takeUnless { hidden } ?: c.ink
    val incColor = c.positive.takeUnless { hidden } ?: c.ink
    val trColor = c.transfer.takeUnless { hidden } ?: c.ink

    @Composable
    fun PairTiles(leftLabel: String, leftAmount: BigDecimal, rightLabel: String, rightAmount: BigDecimal) {
        if (stacked) {
            Column(Modifier.fillMaxWidth(), verticalArrangement = Arrangement.spacedBy(12.dp)) {
                FixedTotalTile(leftLabel, money(leftAmount, currency, hidden), expColor, Modifier.fillMaxWidth())
                FixedTotalTile(rightLabel, money(rightAmount, currency, hidden), incColor, Modifier.fillMaxWidth())
            }
        } else {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                FixedTotalTile(leftLabel, money(leftAmount, currency, hidden), expColor, Modifier.weight(1f))
                FixedTotalTile(rightLabel, money(rightAmount, currency, hidden), incColor, Modifier.weight(1f))
            }
        }
    }

    Column(modifier.fillMaxWidth().padding(top = 4.dp).testTag("movements.sectionTotals")) {
        when (kind) {
            MovementTotalsKind.All -> PairTiles(
                stringResource(R.string.uscite), totals.expenses,
                stringResource(R.string.entrate), totals.income,
            )
            MovementTotalsKind.Fixed -> PairTiles(
                stringResource(R.string.spese_fisse), totals.expenses,
                stringResource(R.string.entrate_fisse), totals.income,
            )
            MovementTotalsKind.Expense -> FixedTotalTile(
                stringResource(R.string.uscite), money(totals.expenses, currency, hidden), expColor, Modifier.fillMaxWidth(),
            )
            MovementTotalsKind.Income -> FixedTotalTile(
                stringResource(R.string.entrate), money(totals.income, currency, hidden), incColor, Modifier.fillMaxWidth(),
            )
            MovementTotalsKind.Transfer -> FixedTotalTile(
                stringResource(R.string.trasferito), money(totals.transferred, currency, hidden), trColor, Modifier.fillMaxWidth(),
            )
            MovementTotalsKind.Recurring -> PairTiles(
                stringResource(R.string.uscite_programmate), totals.expenses,
                stringResource(R.string.entrate_programmate), totals.income,
            )
        }
    }
}
