package com.bucktrail.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.AccountData
import com.bucktrail.android.domain.AccountType
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.ui.AppData
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.accountTypeCategoryProxy
import com.bucktrail.android.ui.accountTypeIcon
import com.bucktrail.android.ui.accountTypeRes
import com.bucktrail.android.ui.components.CategoryIconBox
import com.bucktrail.android.ui.components.EmptyState
import com.bucktrail.android.ui.components.FitText
import com.bucktrail.android.ui.components.HeroCard
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal

/** Conti (§4.7): hero «Patrimonio totale / A conti fatti», gruppi Liquidità e Risparmio e investimenti. */
@Composable
fun AccountsScreen(data: AppData, onAdd: () -> Unit) {
    val c = Bt.colors
    val ledger = data.ledger
    val hidden = data.prefs.hideBalance
    val currency = data.prefs.currencyCode
    val calc = remember(ledger.accounts, ledger.transactions) {
        val txs = ledger.transactionData
        val accounts = ledger.accountData
        object {
            val total = Balance.total(accounts, txs)
            val future = Balance.totalFuture(accounts, txs)
            val current = accounts.associate { it.id to Balance.current(it, txs) }
            val futureBy = accounts.associate { it.id to Balance.future(it, txs) }
        }
    }
    val active = ledger.accounts.filter { !it.isArchived }

    Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = Dim.listBottomPadding.dp)) {
        PageHeader(stringResource(R.string.conti))
        Column(Modifier.padding(horizontal = Dim.cardMargin.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            HeroCard(Modifier.fillMaxWidth()) {
                Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(stringResource(R.string.patrimonio_totale), style = Typo.secondary, color = c.heroSecondary)
                    FitText(money(calc.total, currency, hidden), Typo.heroAmountSm, c.heroText, Modifier.testTag("accounts_total"))
                    Spacer(Modifier.height(6.dp))
                    Box(Modifier.fillMaxWidth().height(1.dp).background(c.heroDivider))
                    Spacer(Modifier.height(6.dp))
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                        Text(stringResource(R.string.a_conti_fatti), style = Typo.secondary, color = c.heroSecondary)
                        Text(money(calc.future, currency, hidden), style = Typo.rowAmount, color = c.heroPlanned)
                    }
                }
            }
            if (active.isEmpty()) {
                EmptyState(SfIcons.forName("creditcard"), stringResource(R.string.nessun_conto), stringResource(R.string.aggiungi_un_conto_per_iniziare_a_traccia),
                    stringResource(R.string.aggiungi_conto_73e3ed), onAdd)
            } else {
                AccountGroup(stringResource(R.string.liquidita), active.filter { AccountType.from(it.type) in setOf(AccountType.Cash, AccountType.Card, AccountType.Checking) },
                    calc.current, calc.futureBy, currency, hidden)
                AccountGroup(stringResource(R.string.risparmio_e_investimenti), active.filter { AccountType.from(it.type) in setOf(AccountType.Savings, AccountType.Investment) },
                    calc.current, calc.futureBy, currency, hidden)
            }
        }
    }
}

@Composable
private fun AccountGroup(title: String, accounts: List<AccountEntity>, current: Map<String, BigDecimal>, future: Map<String, BigDecimal>, currency: String, hidden: Boolean) {
    if (accounts.isEmpty()) return
    val c = Bt.colors
    val ordered = accounts.sortedBy { it.isExcludedFromTotal }
    val total = accounts.filter { !it.isExcludedFromTotal }.fold(BigDecimal.ZERO) { a, acc -> a + (current[acc.id] ?: BigDecimal.ZERO) }
    Column {
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title, style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.smoke)
            Text(money(total, currency, hidden), style = Typo.rowAmount, color = c.ink)
        }
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(c.surface)) {
            ordered.forEachIndexed { i, acc ->
                if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                AccountRow(acc, current[acc.id] ?: BigDecimal.ZERO, future[acc.id] ?: BigDecimal.ZERO, currency, hidden)
            }
        }
    }
}

@Composable
private fun AccountRow(account: AccountEntity, current: BigDecimal, future: BigDecimal, currency: String, hidden: Boolean) {
    val c = Bt.colors
    val type = AccountType.from(account.type)
    val excluded = account.isExcludedFromTotal
    val subtitle = if (excluded) stringResource(R.string.escluso_dal_totale) else stringResource(accountTypeRes(type))
    Row(
        Modifier.fillMaxWidth().testTag("accountRow_${account.name}").padding(horizontal = 14.dp, vertical = Dim.rowVPad.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CategoryIconBox(accountTypeIcon(type), accountTypeCategoryProxy(type), radius = 13.dp)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(account.name, style = Typo.rowName, color = if (account.isArchived) c.smoke else c.ink, maxLines = 1)
            Text(subtitle, style = Typo.caption, color = c.smoke, maxLines = 1)
        }
        Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Text(money(current, currency, hidden), style = Typo.rowAmount, color = if (excluded) c.smoke else c.ink, maxLines = 1)
            if ((future - current).abs() > BigDecimal("0.001") && !hidden) Text("→ " + Fmt.currency(future, currency), style = Typo.caption, color = c.plannedText, maxLines = 1)
        }
    }
}

/** Pagina senza ancora contenuti (Statistiche e Pianifica arrivano nei blocchi B7 e B6). */
@Composable
fun PlaceholderScreen(title: String, icon: String, emptyTitle: String, emptySubtitle: String?) {
    Column(Modifier.fillMaxWidth()) {
        PageHeader(title)
        EmptyState(SfIcons.forName(icon), emptyTitle, emptySubtitle)
    }
}
