package com.bucktrail.android.ui.screens

import com.bucktrail.android.domain.HomeProjection
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.horizontalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.AccountType
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.BalanceTrail
import com.bucktrail.android.ui.AppData
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.Card
import com.bucktrail.android.ui.components.EmptyState
import com.bucktrail.android.ui.components.FitText
import com.bucktrail.android.ui.components.HeroCard
import com.bucktrail.android.ui.components.MovementRow
import com.bucktrail.android.ui.components.RoundIconButton
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.components.TrailView
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.Locale

private val EPS = BigDecimal("0.001")

/** Home (§4.1): hero con sentiero, carosello conti, fissi del mese, ultimi movimenti. */
@Composable
fun HomeScreen(
    data: AppData, today: LocalDate, zone: ZoneId,
    onToggleHide: () -> Unit, onEdit: (TransactionEntity) -> Unit, onDelete: (TransactionEntity) -> Unit,
    onSeeAllMovements: () -> Unit, onManageAccounts: () -> Unit, onOpenSettings: () -> Unit, onOpenAccountOrder: () -> Unit,
) {
    val c = Bt.colors
    val ledger = data.ledger
    val hidden = data.prefs.hideBalance
    val currency = data.prefs.currencyCode
    val res = LocalContext.current.resources
    val locale = Locale.getDefault()
    val month = YearMonth.from(today)

    val projection = remember(ledger.accounts, ledger.transactions, today, zone) {
        HomeProjection.make(ledger.accountData, ledger.transactionData, today, zone)
    }
    val (total, trail, plannedByAccount) = projection.let { Triple(it.total, it.trail, it.plannedByAccount) }

    val balances = remember(ledger.accounts, ledger.transactions) {
        val txs = ledger.transactionData
        Balance.included(ledger.accountData).associate { it.id to Balance.current(it, txs) }
    }
    val topAccounts = remember(ledger.accounts, balances, data.prefs.homeAccountOrderedShown) {
        val included = ledger.accounts.filter { it.id in balances }
        val saved = data.prefs.homeAccountIds
        if (saved.isEmpty()) included.sortedByDescending { balances[it.id] }.take(3)
        else saved.mapNotNull { id -> included.firstOrNull { it.id == id } }
    }
    val fixed = remember(ledger.transactions, today) {
        fun sum(type: String) = ledger.transactions.filter {
            it.isFixed && !it.isTransfer && it.type == type && YearMonth.from(it.localDate(zone)) == month
        }.fold(BigDecimal.ZERO) { a, t -> a + t.amountValue() }
        sum(Amounts.TYPE_EXPENSE) to sum(Amounts.TYPE_INCOME)
    }
    val latest = remember(ledger.transactions) {
        ledger.transactions.filter { !it.isFixed && !it.isTransfer && it.recurringFrequency.isEmpty() }.take(4)
    }
    var collapsed by rememberSaveable { mutableStateOf(false) }
    val accountOrderDescription = stringResource(R.string.conti_in_home)
    val hiddenText = Fmt.HIDDEN_HOME

    Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = (Dim.listBottomPadding + Dim.tabBarReserved).dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
        // Intestazione: data + wordmark, occhio
        Row(
            Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = Dim.screenMargin.dp).padding(top = 8.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
        ) {
            Column(Modifier.weight(1f)) {
                Text(Fmt.headerDate(today, locale), style = Typo.secondary, color = c.smoke, maxLines = 1)
                Text(stringResource(R.string.app_name), style = Typo.wordmark, color = c.ink)
            }
            Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                RoundIconButton(
                    SfIcons.forName(if (hidden) "eye.slash" else "eye"),
                    stringResource(if (hidden) R.string.mostra_importi else R.string.oscura_importi), onToggleHide,
                )
                RoundIconButton(SfIcons.forName("gearshape"), stringResource(R.string.impostazioni), onOpenSettings, Modifier.testTag("btn_openSettings"))
            }
        }

        // Hero
        HeroCard(Modifier.padding(horizontal = Dim.cardMargin.dp), radius = 26.dp, padding = 20.dp) {
            Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(stringResource(R.string.saldo_attuale), style = Typo.secondary, color = c.heroSecondary)
                FitText(money(total, currency, hidden, hiddenText), Typo.heroAmount, c.heroText)
                Spacer(Modifier.height(10.dp))
                TrailView(
                    trail,
                    firstLabel = "1 ${Fmt.shortMonth(month, locale).lowercase(locale)}",
                    todayLabel = stringResource(R.string.oggi),
                    lastLabel = "${trail.daysInMonth} ${Fmt.shortMonth(month, locale).lowercase(locale)}",
                )
                if (trail.plannedDelta.abs() > EPS) {
                    Spacer(Modifier.height(10.dp))
                    Box(Modifier.fillMaxWidth().height(1.dp).background(c.heroDivider))
                    Spacer(Modifier.height(10.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.Top) {
                        Column(Modifier.weight(1f)) {
                            Text(stringResource(R.string.saldo_atteso_a_fine_mese), style = Typo.caption, color = c.heroSecondary)
                            FitText(money(trail.expectedBalance, currency, hidden, hiddenText), Typo.sectionTitle, c.heroPlanned, minScale = 0.6f)
                        }
                        val count = trail.plannedCount
                        val delta = (if (trail.plannedDelta.signum() > 0 && !hidden) "+" else "") + money(trail.plannedDelta, currency, hidden, hiddenText)
                        Text(
                            (if (count == 1) stringResource(R.string.s_1_movimento_pianificato) else stringResource(R.string.lld_movimenti_pianificati, count)) + "\n" + delta,
                            style = Typo.caption, color = c.heroSecondary, textAlign = TextAlign.End, modifier = Modifier.weight(1f),
                        )
                    }
                }
            }
        }

        // Conti
        if (topAccounts.isNotEmpty()) Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth().padding(horizontal = Dim.screenMargin.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                Text(stringResource(R.string.conti), style = Typo.sectionTitle, color = c.ink)
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    Box(Modifier.size(44.dp).clickable(role = Role.Button, onClick = onOpenAccountOrder).testTag("btn_homeAccountOrder").semantics { contentDescription = accountOrderDescription }, contentAlignment = Alignment.Center) {
                        Icon(SfIcons.forName("slider.horizontal.3"), null, tint = c.smoke, modifier = Modifier.size(20.dp))
                    }
                    Box(Modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onManageAccounts), contentAlignment = Alignment.Center) {
                        Text(stringResource(R.string.gestisci), style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.accent)
                    }
                }
            }
            Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = Dim.cardMargin.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                topAccounts.forEach { account ->
                    val type = AccountType.from(account.type)
                    val delta = plannedByAccount[account.id] ?: BigDecimal.ZERO
                    val balance = balances.getValue(account.id)
                    Column(
                        Modifier.width(148.dp).clip(RoundedCornerShape(18.dp)).background(c.surface).padding(horizontal = 14.dp, vertical = 12.dp),
                        verticalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                            Box(Modifier.size(10.dp).clip(RoundedCornerShape(3.dp)).background(accountDotColor(type)))
                            Text(account.name, style = Typo.secondary, color = c.smoke, maxLines = 1)
                        }
                        FitText(money(balance, currency, hidden, hiddenText), Typo.rowAmount, c.ink, minScale = 0.7f)
                        if (delta.abs() > EPS) Text("→ " + money(balance + delta, currency, hidden, hiddenText), style = Typo.caption, color = c.plannedText, maxLines = 1)
                        else Text(stringResource(R.string.nessun_movimento_0ef874), style = Typo.caption, color = c.smoke, maxLines = 1)
                    }
                }
            }
        }

        // Fissi del mese
        if (data.prefs.showFixedExpensesTotal || data.prefs.showFixedIncomeTotal) Column(Modifier.padding(horizontal = Dim.screenMargin.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Text(stringResource(R.string.fissi_del_mese), style = Typo.sectionTitle, color = c.ink)
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                if (data.prefs.showFixedExpensesTotal) FixedTotalTile(stringResource(R.string.spese_fisse), money(fixed.first, currency, hidden), c.negative.takeUnless { hidden } ?: c.ink, Modifier.weight(1f))
                if (data.prefs.showFixedIncomeTotal) FixedTotalTile(stringResource(R.string.entrate_fisse), money(fixed.second, currency, hidden), c.positive.takeUnless { hidden } ?: c.ink, Modifier.weight(1f))
            }
        }

        // Ultimi movimenti
        Column(Modifier.padding(horizontal = Dim.cardMargin.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.ultimi_movimenti), style = Typo.sectionTitle, color = c.ink)
                Box(Modifier.size(44.dp).clickable(role = Role.Button) { collapsed = !collapsed }, contentAlignment = Alignment.Center) {
                    Icon(SfIcons.forName(if (collapsed) "chevron.down" else "chevron.up"), null, tint = c.smoke, modifier = Modifier.size(16.dp))
                }
                Spacer(Modifier.weight(1f))
                Box(Modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onSeeAllMovements), contentAlignment = Alignment.Center) {
                    Text(stringResource(R.string.vedi_tutti), style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.accent)
                }
            }
            if (!collapsed) {
                if (latest.isEmpty()) EmptyState(SfIcons.forName("tray"), stringResource(R.string.nessun_movimento), stringResource(R.string.premi_per_aggiungere_la_tua_prima_spesa))
                else Column(Modifier.clip(RoundedCornerShape(20.dp)).background(c.surface)) {
                    latest.forEachIndexed { i, t ->
                        androidx.compose.runtime.key(t.id) {
                            if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                            TransactionRow(t, ledger.accounts, currency, hidden, today, zone, res, recurring = ledger.rules.any { it.id.equals(t.templateId, true) },
                                onEdit = onEdit, onDelete = onDelete)
                        }
                    }
                }
            }
        }
        Spacer(Modifier.height(54.dp))
    }
}

@Composable
private fun accountDotColor(type: AccountType): Color {
    val c = Bt.colors
    return when (type) {
        AccountType.Checking -> c.accent; AccountType.Savings -> c.transfer; AccountType.Card -> c.planned
        AccountType.Cash -> c.smoke; AccountType.Investment -> c.ink
    }
}

@Composable
fun FixedTotalTile(label: String, amount: String, color: Color, modifier: Modifier = Modifier) {
    val c = Bt.colors
    Column(modifier.clip(RoundedCornerShape(12.dp)).background(c.fog.copy(alpha = 0.5f)).padding(12.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(label, style = Typo.caption, color = c.smoke, maxLines = 1)
        FitText(amount, Typo.rowAmount.copy(fontSize = androidx.compose.ui.unit.TextUnit(20f, androidx.compose.ui.unit.TextUnitType.Sp)), color, minScale = 0.7f)
    }
}
