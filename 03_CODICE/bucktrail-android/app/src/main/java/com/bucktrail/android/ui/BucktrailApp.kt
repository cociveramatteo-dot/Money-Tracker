package com.bucktrail.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import com.bucktrail.android.data.toData
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.unit.dp
import androidx.lifecycle.Lifecycle
import androidx.lifecycle.compose.LocalLifecycleOwner
import androidx.lifecycle.compose.collectAsStateWithLifecycle
import androidx.lifecycle.repeatOnLifecycle
import androidx.lifecycle.viewmodel.compose.viewModel
import com.bucktrail.android.R
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.ui.components.FabButton
import com.bucktrail.android.ui.components.FloatingTabBar
import com.bucktrail.android.ui.components.Tab
import com.bucktrail.android.ui.forms.AddAccountForm
import com.bucktrail.android.ui.forms.AddTransferForm
import com.bucktrail.android.ui.forms.CategoryManagementSheet
import com.bucktrail.android.ui.forms.AddTransactionForm
import com.bucktrail.android.ui.screens.AccountActions
import com.bucktrail.android.ui.screens.AccountsScreen
import com.bucktrail.android.ui.screens.HomeAccountOrderSheet
import com.bucktrail.android.ui.screens.MovementActions
import com.bucktrail.android.ui.screens.SettingsActions
import com.bucktrail.android.ui.screens.SettingsSheet
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.UndoBar
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.data.TransactionOps
import com.bucktrail.android.ui.screens.HomeScreen
import com.bucktrail.android.ui.screens.MovementsScreen
import com.bucktrail.android.ui.screens.PlaceholderScreen
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import kotlinx.coroutines.delay
import java.time.LocalDate
import java.time.ZoneId

/** Radice dell'app: 5 tab con tab bar flottante, FAB contestuale e form a pagina intera. */
@Composable
fun BucktrailApp(vm: AppViewModel = viewModel()) {
    val c = Bt.colors
    val data by vm.data.collectAsStateWithLifecycle()
    val undo by vm.undo.collectAsStateWithLifecycle()
    val owner = LocalLifecycleOwner.current
    val clock by produceState(LocalDate.now() to ZoneId.systemDefault(), owner) {
        owner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) { value = LocalDate.now() to ZoneId.systemDefault(); delay(30_000) }
        }
    }
    val (today, zone) = clock
    var tab by rememberSaveable { mutableStateOf(Tab.Home) }
    // "tx:new" | "tx:<id>" | "transfer:new" | "transfer:<id>" | "account:new" | "account:<id>" | null
    var editor by rememberSaveable { mutableStateOf<String?>(null) }
    var settingsOpen by rememberSaveable { mutableStateOf(false) }
    var homeOrderOpen by rememberSaveable { mutableStateOf(false) }
    var categoriesOpen by rememberSaveable { mutableStateOf(false) }
    var pendingTransferDelete by remember { mutableStateOf<TransactionEntity?>(null) }
    var fabMenu by remember { mutableStateOf(false) }
    var searching by remember { mutableStateOf(false) }
    val labels = mapOf(
        Tab.Home to stringResource(R.string.home), Tab.Movements to stringResource(R.string.movimenti),
        Tab.Statistics to stringResource(R.string.statistiche), Tab.Plan to stringResource(R.string.pianifica), Tab.Accounts to stringResource(R.string.conti),
    )
    val fabDescription = when (tab) {
        Tab.Home, Tab.Movements -> stringResource(R.string.nuovo_movimento)
        Tab.Plan -> stringResource(R.string.nuovo_budget)
        Tab.Accounts -> stringResource(R.string.nuovo_conto)
        Tab.Statistics -> ""
    }
    val fabVisible = tab != Tab.Statistics && !(tab == Tab.Movements && searching)
    val ledger = data.ledger
    val edit: (TransactionEntity) -> Unit = { editor = if (it.isTransfer && it.transferGroupId.isNotEmpty()) "transfer:${it.id}" else "tx:${it.id}" }
    // Elimina: i trasferimenti collegati chiedono conferma, il resto esce subito con «Annulla».
    val requestDelete: (TransactionEntity) -> Unit = { t ->
        if (t.isTransfer && t.transferGroupId.isNotEmpty()) pendingTransferDelete = t else vm.deleteTransactions(listOf(t))
    }
    val toggleDone: (TransactionEntity) -> Unit = { vm.toggleDone(it, ledger.transactions) }

    Box(Modifier.fillMaxSize().background(c.paper)) {
        when (tab) {
            Tab.Home -> HomeScreen(data, today, zone, { vm.setHideBalance(!data.prefs.hideBalance) }, edit, requestDelete,
                onSeeAllMovements = { tab = Tab.Movements }, onManageAccounts = { tab = Tab.Accounts },
                onOpenSettings = { settingsOpen = true }, onOpenAccountOrder = { homeOrderOpen = true })
            Tab.Movements -> MovementsScreen(
                data, today, zone, MovementActions(edit, requestDelete, toggleDone, vm::setTxFilters) { settingsOpen = true }, { searching = it },
            )
            Tab.Statistics -> PlaceholderScreen(stringResource(R.string.statistiche), "chart.bar", stringResource(R.string.nessun_dato_disponibile), null)
            Tab.Plan -> PlaceholderScreen(stringResource(R.string.pianifica), "scope", stringResource(R.string.nessun_budget), stringResource(R.string.imposta_un_limite_mensile_per_categoria))
            Tab.Accounts -> AccountsScreen(
                data, AccountActions(
                    onAdd = { editor = "account:new" }, onEdit = { editor = "account:${it.id}" }, onDelete = { vm.deleteAccount(it) },
                    onArchive = { a, v -> vm.setAccountArchived(a, v) }, onExclude = { a, v -> vm.setAccountExcluded(a, v) },
                    onSettings = { settingsOpen = true },
                ),
            )
        }
        FloatingTabBar(tab, labels, { tab = it; searching = false }, Modifier.align(Alignment.BottomCenter))
        undo?.let { u ->
            UndoBar(
                stringResource(if (u.transactions.size > 1) R.string.movimenti_eliminati else R.string.movimento_eliminato), stringResource(R.string.annulla), u.key,
                onAction = vm::undoDelete, onTimeout = { vm.dismissUndo(u.key) },
                modifier = Modifier.align(Alignment.BottomStart).navigationBarsPadding().padding(start = Dim.cardMargin.dp, end = 96.dp, bottom = (Dim.fabBottom + 66).dp),
            )
        }
        Box(Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(end = Dim.fabEnd.dp, bottom = Dim.fabBottom.dp)) {
            FabButton(fabDescription, fabVisible, onClick = {
                when (tab) {
                    Tab.Home, Tab.Movements -> if (ledger.accounts.none { !it.isArchived }) editor = "account:new" else fabMenu = true
                    Tab.Accounts -> editor = "account:new"
                    else -> Unit // Pianifica: nuovo budget/obiettivo arrivano nel blocco B6
                }
            })
            DropdownMenu(fabMenu, { fabMenu = false }) {
                DropdownMenuItem(text = { Text(stringResource(R.string.spesa_entrata)) }, onClick = { fabMenu = false; editor = "tx:new" },
                    leadingIcon = { Icon(com.bucktrail.android.ui.components.SfIcons.forName("plus.circle"), null) })
                DropdownMenuItem(text = { Text(stringResource(R.string.trasferimento_tra_conti)) }, onClick = { fabMenu = false; editor = "transfer:new" },
                    leadingIcon = { Icon(com.bucktrail.android.ui.components.SfIcons.forName("arrow.left.arrow.right"), null) })
            }
        }
    }

    val noopClose = { editor = null }
    when (val e = editor) {
        null -> Unit
        "account:new" -> AddAccountForm(null, java.math.BigDecimal.ZERO, false, null, ledger.categories, data.prefs.currencyCode,
            onSave = { vm.saveAccount(it.account, it.adjustment, it.threshold, it.addToHome) }, onClose = noopClose)
        "tx:new" -> TransactionEditor(null, data, vm, today, zone, { categoriesOpen = true }, noopClose)
        "transfer:new" -> AddTransferForm(null, null, ledger.accounts, data.prefs.currencyCode, today, zone, onSave = { vm.saveTransactions(it) }, onClose = noopClose)
        else -> when {
            e.startsWith("account:") -> {
                val account = ledger.accounts.firstOrNull { it.id == e.removePrefix("account:") }
                if (account == null) LaunchedEffect(Unit) { editor = null } else {
                    val txs = ledger.transactionData
                    AddAccountForm(
                        account, Balance.current(account.toData(), txs), ledger.transactions.any { it.accountId == account.id },
                        data.prefs.balanceThresholds[account.id], ledger.categories, data.prefs.currencyCode,
                        onSave = { vm.saveAccount(it.account, it.adjustment, it.threshold, false) }, onClose = noopClose,
                    )
                }
            }
            e.startsWith("transfer:") -> {
                val leg = ledger.transactions.firstOrNull { it.id == e.removePrefix("transfer:") }
                val twin = leg?.let { TransactionOps.twinsOf(it, ledger.transactions).firstOrNull() }
                if (leg == null || twin == null) LaunchedEffect(Unit) { editor = null } else {
                    val (outLeg, inLeg) = if (leg.type == com.bucktrail.android.domain.Amounts.TYPE_EXPENSE) leg to twin else twin to leg
                    AddTransferForm(outLeg, inLeg, ledger.accounts, data.prefs.currencyCode, today, zone, onSave = { vm.saveTransactions(it) }, onClose = noopClose)
                }
            }
            else -> {
                val existing = ledger.transactions.firstOrNull { it.id == e.removePrefix("tx:") }
                if (existing != null) TransactionEditor(existing, data, vm, today, zone, { categoriesOpen = true }, noopClose)
                else LaunchedEffect(Unit) { editor = null }
            }
        }
    }

    if (settingsOpen) SettingsSheet(
        data, SettingsActions(vm::setCurrency, vm::setShowFixedExpenses, vm::setShowFixedIncome) { settingsOpen = false },
    )
    if (homeOrderOpen) {
        val balances = remember(ledger.accounts, ledger.transactions) {
            val txs = ledger.transactionData
            Balance.included(ledger.accountData).associate { it.id to Balance.current(it, txs) }
        }
        HomeAccountOrderSheet(
            ledger.accounts.filter { it.id in balances }.sortedByDescending { balances[it.id] }, data.prefs.homeAccountIds,
            onSave = vm::setHomeAccounts, onClose = { homeOrderOpen = false },
        )
    }
    if (categoriesOpen) CategoryManagementSheet(
        ledger.categories, usageCount = { name -> ledger.transactions.count { it.category == name } },
        onSave = { cat, name, icon -> vm.saveCategory(cat, name, icon) }, onDelete = { vm.deleteCategory(it) }, onClose = { categoriesOpen = false },
    )
    pendingTransferDelete?.let { t ->
        BtAlert(
            stringResource(R.string.elimina_trasferimento), stringResource(R.string.questo_trasferimento_e_composto_da_due_m),
            stringResource(R.string.elimina_entrambi_i_movimenti),
            onConfirm = { pendingTransferDelete = null; vm.deleteTransactions(listOf(t) + TransactionOps.twinsOf(t, ledger.transactions)) },
            onDismiss = { pendingTransferDelete = null }, dismissLabel = stringResource(R.string.annulla),
            modifier = Modifier.testTag("alert_deleteTransfer"),
        )
    }
}

@Composable
private fun TransactionEditor(
    existing: TransactionEntity?, data: AppData, vm: AppViewModel, today: LocalDate, zone: ZoneId, onManageCategories: () -> Unit, onClose: () -> Unit,
) {
    val ledger = data.ledger
    AddTransactionForm(
        existing, ledger.accounts, ledger.categories, ledger.transactions, data.prefs.currencyCode, today, zone, vm::classify, onManageCategories,
        onSave = { vm.saveTransaction(it) }, onClose = onClose,
    )
}
