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
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.style.TextOverflow
import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.RoundIconButton
import com.bucktrail.android.ui.components.SwipeAction
import com.bucktrail.android.ui.components.SwipeableRow
import com.bucktrail.android.ui.components.dashedBorder

/** Azioni sui conti, raccolte per non allungare le firme. */
class AccountActions(
    val onAdd: () -> Unit, val onEdit: (AccountEntity) -> Unit, val onDelete: (AccountEntity) -> Unit,
    val onArchive: (AccountEntity, Boolean) -> Unit, val onExclude: (AccountEntity, Boolean) -> Unit,
    val onSettings: () -> Unit,
)

/** Conti (§4.7): hero «Patrimonio totale / A conti fatti», gruppi Liquidità e Risparmio e investimenti, archiviati. */
@Composable
fun AccountsScreen(data: AppData, actions: AccountActions) {
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
            val txCount = ledger.transactions.groupingBy { it.accountId }.eachCount()
        }
    }
    val active = ledger.accounts.filter { !it.isArchived }
    val archived = ledger.accounts.filter { it.isArchived }
    var showArchived by rememberSaveable { mutableStateOf(false) }
    var toDelete by remember { mutableStateOf<AccountEntity?>(null) }
    val ctx = AccountRowContext(calc.current, calc.futureBy, currency, hidden, data.prefs.balanceThresholds, actions) { toDelete = it }

    Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = (Dim.listBottomPadding + Dim.tabBarReserved).dp)) {
        PageHeader(stringResource(R.string.conti)) {
            RoundIconButton(SfIcons.forName("gearshape"), stringResource(R.string.impostazioni), actions.onSettings, Modifier.testTag("btn_openSettings"))
        }
        Column(Modifier.padding(horizontal = Dim.cardMargin.dp), verticalArrangement = Arrangement.spacedBy(18.dp)) {
            HeroCard(Modifier.fillMaxWidth(), padding = 24.dp) {
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
            if (active.isEmpty() && archived.isEmpty()) {
                EmptyState(SfIcons.forName("creditcard"), stringResource(R.string.nessun_conto), stringResource(R.string.aggiungi_un_conto_per_iniziare_a_traccia),
                    stringResource(R.string.aggiungi_conto_73e3ed), actions.onAdd)
            } else {
                AccountGroup(stringResource(R.string.liquidita), active.filter { AccountType.from(it.type) in setOf(AccountType.Cash, AccountType.Card, AccountType.Checking) }, ctx)
                AccountGroup(stringResource(R.string.risparmio_e_investimenti), active.filter { AccountType.from(it.type) in setOf(AccountType.Savings, AccountType.Investment) }, ctx)
                if (archived.isNotEmpty()) {
                    ArchivedToggle(archived.size, showArchived, { showArchived = !showArchived })
                    if (showArchived) {
                        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(c.surface)) {
                            archived.forEachIndexed { i, acc ->
                                key(acc.id) {
                                    if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                                    AccountRow(acc, ctx, archivedRow = true)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    toDelete?.let { acc ->
        val count = calc.txCount[acc.id] ?: 0
        BtAlert(
            title = stringResource(R.string.eliminare, acc.name), message = null,
            confirm = when { count == 0 -> stringResource(R.string.elimina); count == 1 -> stringResource(R.string.elimina_con_1_movimento); else -> stringResource(R.string.elimina_con_n_movimenti, count) },
            onConfirm = { toDelete = null; actions.onDelete(acc) }, onDismiss = { toDelete = null }, dismissLabel = stringResource(R.string.annulla),
            modifier = Modifier.testTag("alert_deleteAccount"),
        )
    }
}

private class AccountRowContext(
    val current: Map<String, BigDecimal>, val future: Map<String, BigDecimal>, val currency: String, val hidden: Boolean,
    val thresholds: Map<String, String>, val actions: AccountActions, val requestDelete: (AccountEntity) -> Unit,
)

@Composable
private fun ArchivedToggle(count: Int, expanded: Boolean, onClick: () -> Unit) {
    val c = Bt.colors
    Row(
        Modifier.fillMaxWidth().heightIn(min = 48.dp).testTag("accounts_archived").dashedBorder(c.filterBorder, 16.dp, 5.dp, 4.dp)
            .clip(RoundedCornerShape(16.dp)).clickable(role = Role.Button, onClick = onClick).padding(horizontal = 16.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(stringResource(R.string.archiviati), style = Typo.rowName, color = c.smoke, modifier = Modifier.weight(1f))
        Text("$count", style = Typo.rowAmount, color = c.smoke)
        Icon(SfIcons.forName(if (expanded) "chevron.up" else "chevron.down"), null, tint = c.smoke, modifier = Modifier.size(16.dp))
    }
}

@Composable
private fun AccountGroup(title: String, accounts: List<AccountEntity>, ctx: AccountRowContext) {
    if (accounts.isEmpty()) return
    val c = Bt.colors
    val ordered = AccountEditing.includedFirst(accounts) { it.isExcludedFromTotal }
    val total = accounts.filter { !it.isExcludedFromTotal }.fold(BigDecimal.ZERO) { a, acc -> a + (ctx.current[acc.id] ?: BigDecimal.ZERO) }
    Column {
        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
            Text(title, style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.smoke)
            Text(money(total, ctx.currency, ctx.hidden), style = Typo.rowAmount, color = c.ink)
        }
        Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(20.dp)).background(c.surface)) {
            ordered.forEachIndexed { i, acc ->
                key(acc.id) {
                    if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                    AccountRow(acc, ctx, archivedRow = false)
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun AccountRow(account: AccountEntity, ctx: AccountRowContext, archivedRow: Boolean) {
    val c = Bt.colors
    val current = ctx.current[account.id] ?: BigDecimal.ZERO
    val future = ctx.future[account.id] ?: BigDecimal.ZERO
    val hidden = ctx.hidden
    val type = AccountType.from(account.type)
    val excluded = account.isExcludedFromTotal
    val threshold = AccountEditing.threshold(ctx.thresholds[account.id])
    val below = !hidden && AccountEditing.isBelowThreshold(current, threshold)
    var menu by remember { mutableStateOf(false) }
    val smoke = archivedRow
    SwipeableRow(
        deleteAction = if (archivedRow) null else SwipeAction(stringResource(R.string.elimina), SfIcons.forName("trash"), c.danger, c.onAccent),
        onDelete = { ctx.requestDelete(account); false },
        toggleAction = null, onToggle = {},
        modifier = Modifier.testTag("accountRow_${account.name}"),
    ) {
        Box {
            Row(
                Modifier.fillMaxWidth().combinedClickable(onClick = { ctx.actions.onEdit(account) }, onLongClick = { menu = true })
                    .padding(horizontal = 14.dp, vertical = Dim.rowVPad.dp),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                CategoryIconBox(accountTypeIcon(type), accountTypeCategoryProxy(type), radius = 13.dp)
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(account.name, style = Typo.rowName, color = if (smoke) c.smoke else c.ink, maxLines = 1, overflow = TextOverflow.Ellipsis)
                    when {
                        excluded -> Text(stringResource(R.string.escluso_dal_totale), style = Typo.caption, color = c.smoke, maxLines = 1)
                        below -> Text(stringResource(R.string.sotto_la_soglia_di, Fmt.currency(checkNotNull(threshold), ctx.currency)),
                            style = Typo.caption.copy(fontWeight = FontWeight.SemiBold), color = c.plannedText, maxLines = 2)
                        else -> Text(stringResource(accountTypeRes(type)), style = Typo.caption, color = c.smoke, maxLines = 1)
                    }
                }
                Column(horizontalAlignment = Alignment.End, verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(money(current, ctx.currency, hidden), style = Typo.rowAmount, color = if (excluded || smoke) c.smoke else c.ink, maxLines = 1, softWrap = false)
                    if ((future - current).abs() > BigDecimal("0.001") && !hidden) Text("→ " + Fmt.currency(future, ctx.currency), style = Typo.caption, color = c.plannedText, maxLines = 1, softWrap = false)
                }
            }
            DropdownMenu(menu, { menu = false }) {
                if (archivedRow) {
                    DropdownMenuItem(text = { Text(stringResource(R.string.ripristina)) }, modifier = Modifier.testTag("account_restore"), onClick = { menu = false; ctx.actions.onArchive(account, false) })
                    DropdownMenuItem(text = { Text(stringResource(R.string.elimina_definitivamente), color = c.danger) }, onClick = { menu = false; ctx.actions.onDelete(account) })
                } else {
                    DropdownMenuItem(text = { Text(stringResource(R.string.modifica)) }, modifier = Modifier.testTag("account_edit"), onClick = { menu = false; ctx.actions.onEdit(account) })
                    DropdownMenuItem(
                        text = { Text(stringResource(if (excluded) R.string.includi_nel_totale else R.string.escludi_dal_totale)) }, modifier = Modifier.testTag("account_exclude"),
                        onClick = { menu = false; ctx.actions.onExclude(account, !excluded) },
                    )
                    DropdownMenuItem(text = { Text(stringResource(R.string.archivia)) }, modifier = Modifier.testTag("account_archive"), onClick = { menu = false; ctx.actions.onArchive(account, true) })
                    DropdownMenuItem(text = { Text(stringResource(R.string.elimina), color = c.danger) }, onClick = { menu = false; ctx.requestDelete(account) })
                }
            }
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
