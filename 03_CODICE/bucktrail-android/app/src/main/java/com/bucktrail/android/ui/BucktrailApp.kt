package com.bucktrail.android.ui

import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.statusBarsPadding
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
import androidx.compose.runtime.rememberCoroutineScope
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
import com.bucktrail.android.export.ShareFiles
import com.bucktrail.android.notifications.rememberNotificationPermission
import com.bucktrail.android.ui.components.DemoBanner
import com.bucktrail.android.ui.components.SyncBanner
import com.bucktrail.android.ui.screens.AccountSettings
import com.bucktrail.android.ui.screens.AuthActions
import com.bucktrail.android.ui.screens.AuthFlow
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.pulltorefresh.PullToRefreshBox
import com.bucktrail.android.ui.screens.AuditLogSheet
import com.bucktrail.android.ui.screens.StatisticsActions
import com.bucktrail.android.ui.screens.StatisticsScreen
import kotlinx.coroutines.launch
import java.time.YearMonth
import com.bucktrail.android.ui.components.FabButton
import com.bucktrail.android.ui.components.FloatingTabBar
import com.bucktrail.android.ui.components.Tab
import com.bucktrail.android.ui.forms.AddAccountForm
import com.bucktrail.android.ui.forms.AddTransferForm
import com.bucktrail.android.ui.forms.CategoryManagementSheet
import com.bucktrail.android.ui.forms.AddTransactionForm
import com.bucktrail.android.ui.screens.AccountActions
import com.bucktrail.android.ui.screens.AccountsScreen
import com.bucktrail.android.ui.screens.BudgetHistorySheet
import com.bucktrail.android.ui.screens.PlanActions
import com.bucktrail.android.ui.screens.PlanScreen
import com.bucktrail.android.ui.forms.AddBudgetForm
import com.bucktrail.android.ui.forms.AddGoalForm
import com.bucktrail.android.ui.screens.RecurrenceEditorSheet
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
    var planSegment by rememberSaveable { mutableStateOf(0) }
    var planMonth by rememberSaveable { mutableStateOf(0) }
    var historyOpen by rememberSaveable { mutableStateOf(false) }
    var auditOpen by rememberSaveable { mutableStateOf(false) }
    var authOpen by rememberSaveable { mutableStateOf(false) }
    var refreshing by remember { mutableStateOf(false) }
    val session by vm.session.collectAsStateWithLifecycle()
    val syncStatus by vm.syncStatus.collectAsStateWithLifecycle()
    val needsSyncDecision by vm.needsSyncDecision.collectAsStateWithLifecycle()
    LaunchedEffect(session) { if (session != null) authOpen = false }
    var statsMonth by rememberSaveable { mutableStateOf(0) }
    var generatingPdf by remember { mutableStateOf(false) }
    val scope = rememberCoroutineScope()
    val context = LocalContext.current
    var recurrence by remember { mutableStateOf<com.bucktrail.android.data.RecurringOps.Selection?>(null) }
    var searching by remember { mutableStateOf(false) }
    val labels = mapOf(
        Tab.Home to stringResource(R.string.home), Tab.Movements to stringResource(R.string.movimenti),
        Tab.Statistics to stringResource(R.string.statistiche), Tab.Plan to stringResource(R.string.pianifica), Tab.Accounts to stringResource(R.string.conti),
    )
    val fabDescription = when (tab) {
        Tab.Home, Tab.Movements -> stringResource(R.string.nuovo_movimento)
        Tab.Plan -> stringResource(if (planSegment == 0) R.string.nuovo_budget else R.string.nuovo_obiettivo)
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
    val openRecurrence: (TransactionEntity) -> Unit = { t -> com.bucktrail.android.data.RecurringOps.resolve(t, ledger.rules, zone)?.let { recurrence = it } ?: requestDelete(t) }
    // copie mancanti delle serie: all'avvio, a ogni cambio giorno e quando cambiano le regole
    LaunchedEffect(data.loaded, today, ledger.rules.size) { vm.materializeDue() }

    // Permesso notifiche al primo avvio (la preferenza non esiste ancora) e ripianificazione degli avvisi programmati.
    val askNotifications = rememberNotificationPermission { vm.setNotifications(it) }
    LaunchedEffect(data.loaded, data.prefs.notificationsDecided) { if (data.loaded && !data.prefs.notificationsDecided) askNotifications() }
    LaunchedEffect(data.loaded, today, data.prefs.notificationsEnabled, data.prefs.monthlyReportEnabled, ledger.demo) { vm.refreshNotifications() }

    Column(Modifier.fillMaxSize().background(c.paper).wrapContentWidth(androidx.compose.ui.Alignment.CenterHorizontally).widthIn(max = 640.dp).fillMaxSize().then(if (ledger.demo) Modifier.statusBarsPadding() else Modifier)) {
    if (ledger.demo) DemoBanner()
    Box(Modifier.fillMaxWidth().weight(1f)) {
        Refreshable(enabled = session != null && !ledger.demo, refreshing = refreshing, onRefresh = { scope.launch { refreshing = true; vm.refresh(); refreshing = false } }) {
        when (tab) {
            Tab.Home -> HomeScreen(data, today, zone, { vm.setHideBalance(!data.prefs.hideBalance) }, edit, requestDelete,
                onSeeAllMovements = { tab = Tab.Movements }, onManageAccounts = { tab = Tab.Accounts },
                onOpenSettings = { settingsOpen = true }, onOpenAccountOrder = { homeOrderOpen = true })
            Tab.Movements -> MovementsScreen(
                data, today, zone, MovementActions(edit, requestDelete, toggleDone, vm::setTxFilters, { settingsOpen = true }, openRecurrence, { recurrence = it }), { searching = it },
            )
            Tab.Statistics -> StatisticsScreen(
                data, today, zone, statsMonth, { statsMonth = it }, generatingPdf,
                StatisticsActions(onSettings = { settingsOpen = true }, onPdf = {
                    scope.launch {
                        generatingPdf = true
                        val file = vm.exportPdf(YearMonth.from(today).plusMonths(statsMonth.toLong()))
                        generatingPdf = false
                        if (file != null) ShareFiles.share(context, file, "application/pdf")
                    }
                }),
            )
            Tab.Plan -> PlanScreen(
                data, today, zone, planSegment, { planSegment = it }, planMonth, { planMonth = it },
                PlanActions({ settingsOpen = true }, { editor = "budget:new" }, { editor = "goal:new" }, { editor = "goal:${it.id}" }, { vm.deleteBudget(it) }, { vm.deleteGoal(it) }),
                onHistory = { historyOpen = true },
            )
            Tab.Accounts -> AccountsScreen(
                data, AccountActions(
                    onAdd = { editor = "account:new" }, onEdit = { editor = "account:${it.id}" }, onDelete = { vm.deleteAccount(it) },
                    onArchive = { a, v -> vm.setAccountArchived(a, v) }, onExclude = { a, v -> vm.setAccountExcluded(a, v) },
                    onSettings = { settingsOpen = true },
                ),
            )
        }
        }
        if (session != null && !ledger.demo) SyncBanner(syncStatus, Modifier.align(Alignment.TopCenter).statusBarsPadding().padding(top = 8.dp))
        FloatingTabBar(tab, labels, { tab = it; searching = false }, Modifier.align(Alignment.BottomCenter))
        undo?.let { u ->
            UndoBar(
                stringResource(if (u.series) R.string.serie_eliminata else if (u.transactions.size > 1) R.string.movimenti_eliminati else R.string.movimento_eliminato), stringResource(R.string.annulla), u.key,
                onAction = vm::undoDelete, onTimeout = { vm.dismissUndo(u.key) },
                modifier = Modifier.align(Alignment.BottomStart).navigationBarsPadding().padding(start = Dim.cardMargin.dp, end = 96.dp, bottom = (Dim.fabBottom + 66).dp),
            )
        }
        Box(Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(end = Dim.fabEnd.dp, bottom = Dim.fabBottom.dp)) {
            FabButton(fabDescription, fabVisible, onClick = {
                when (tab) {
                    Tab.Home, Tab.Movements -> if (ledger.accounts.none { !it.isArchived }) editor = "account:new" else fabMenu = true
                    Tab.Accounts -> editor = "account:new"
                    Tab.Plan -> editor = if (planSegment == 0) "budget:new" else "goal:new"
                    else -> Unit
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
    }

    val noopClose = { editor = null }
    when (val e = editor) {
        null -> Unit
        "account:new" -> AddAccountForm(null, java.math.BigDecimal.ZERO, false, null, ledger.categories, data.prefs.currencyCode,
            onSave = { vm.saveAccount(it.account, it.adjustment, it.threshold, it.addToHome) }, onClose = noopClose)
        "budget:new" -> AddBudgetForm(
            java.time.YearMonth.from(today).plusMonths(planMonth.toLong()), ledger.categories, ledger.accounts, data.prefs.currencyCode,
            onSave = { vm.saveBudget(it) }, onClose = noopClose,
        )
        "goal:new" -> AddGoalForm(null, data.prefs.currencyCode, today, zone, onSave = { vm.saveGoal(it) }, onClose = noopClose)
        "tx:new" -> TransactionEditor(null, data, vm, today, zone, { categoriesOpen = true }, noopClose)
        "transfer:new" -> AddTransferForm(null, null, ledger.accounts, data.prefs.currencyCode, today, zone, onSave = { vm.saveTransactions(it) }, onClose = noopClose)
        else -> when {
            e.startsWith("goal:") -> {
                val goal = ledger.goals.firstOrNull { it.id == e.removePrefix("goal:") }
                if (goal == null) LaunchedEffect(Unit) { editor = null }
                else AddGoalForm(goal, data.prefs.currencyCode, today, zone, onSave = { vm.saveGoal(it) }, onClose = noopClose)
            }
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

    recurrence?.let { sel ->
        RecurrenceEditorSheet(sel, ledger.accounts, ledger.categories, zone, apply = { vm.applyRecurrence(it, sel.rule, sel.occurrence.originalDate) }, onClose = { recurrence = null })
    }
    if (historyOpen) BudgetHistorySheet(data, today, zone) { historyOpen = false }
    if (settingsOpen) SettingsSheet(
        data, SettingsActions(
            vm::setCurrency, vm::setShowFixedExpenses, vm::setShowFixedIncome, vm::setNotifications, vm::setMonthlyReport, vm::setAppLock,
            vm::setDemoMode, { runCatching { vm.exportCsv() }.getOrNull() }, { runCatching { vm.exportJson() }.getOrNull() },
            onOpenAudit = { auditOpen = true }, onClose = { settingsOpen = false },
        ),
        AccountSettings(session?.email, vm.syncConfigured, onSignIn = { authOpen = true }, onSignOut = { vm.signOut().join() }, onDelete = { vm.deleteAccount() }),
    )
    if (authOpen && session == null) AuthFlow(AuthActions(vm::signIn, vm::signUp, vm::resetPassword, onClose = { authOpen = false }))
    if (needsSyncDecision) BtAlert(
        stringResource(R.string.sync_decisione_titolo), stringResource(R.string.sync_decisione_messaggio), stringResource(R.string.sync_usa_cloud),
        onConfirm = { vm.resolveSyncDecision(true) }, onDismiss = { vm.resolveSyncDecision(false) }, dismissLabel = stringResource(R.string.annulla), destructive = false,
        modifier = Modifier.testTag("alert_syncDecision"),
    )
    if (auditOpen) AuditLogSheet({ (context.applicationContext as com.bucktrail.android.BucktrailApplication).auditLog.readAll() }) { auditOpen = false }
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
        onSave = { t, frequency -> vm.saveTransaction(t, frequency, isNew = existing == null) }, onClose = onClose,
    )
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun Refreshable(enabled: Boolean, refreshing: Boolean, onRefresh: () -> Unit, content: @Composable () -> Unit) {
    if (enabled) PullToRefreshBox(refreshing, onRefresh, Modifier.fillMaxSize()) { content() } else content()
}
