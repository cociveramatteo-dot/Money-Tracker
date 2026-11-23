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
import com.bucktrail.android.ui.forms.AddTransactionForm
import com.bucktrail.android.ui.screens.AccountsScreen
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
    val owner = LocalLifecycleOwner.current
    val clock by produceState(LocalDate.now() to ZoneId.systemDefault(), owner) {
        owner.lifecycle.repeatOnLifecycle(Lifecycle.State.STARTED) {
            while (true) { value = LocalDate.now() to ZoneId.systemDefault(); delay(30_000) }
        }
    }
    val (today, zone) = clock
    var tab by rememberSaveable { mutableStateOf(Tab.Home) }
    // "tx:new" | "tx:<id>" | "account" | null
    var editor by rememberSaveable { mutableStateOf<String?>(null) }
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
    val edit: (TransactionEntity) -> Unit = { editor = "tx:${it.id}" }

    Box(Modifier.fillMaxSize().background(c.paper)) {
        when (tab) {
            Tab.Home -> HomeScreen(data, today, zone, { vm.setHideBalance(!data.prefs.hideBalance) }, edit, vm::deleteTransaction,
                onSeeAllMovements = { tab = Tab.Movements }, onManageAccounts = { tab = Tab.Accounts })
            Tab.Movements -> MovementsScreen(data, today, zone, edit, vm::deleteTransaction) { searching = it }
            Tab.Statistics -> PlaceholderScreen(stringResource(R.string.statistiche), "chart.bar", stringResource(R.string.nessun_dato_disponibile), null)
            Tab.Plan -> PlaceholderScreen(stringResource(R.string.pianifica), "scope", stringResource(R.string.nessun_budget), stringResource(R.string.imposta_un_limite_mensile_per_categoria))
            Tab.Accounts -> AccountsScreen(data) { editor = "account" }
        }
        FloatingTabBar(tab, labels, { tab = it; searching = false }, Modifier.align(Alignment.BottomCenter))
        Box(Modifier.align(Alignment.BottomEnd).navigationBarsPadding().padding(end = Dim.fabEnd.dp, bottom = Dim.fabBottom.dp)) {
            FabButton(fabDescription, fabVisible, onClick = {
                when (tab) {
                    Tab.Home, Tab.Movements -> if (ledger.accounts.none { !it.isArchived }) editor = "account" else fabMenu = true
                    Tab.Accounts -> editor = "account"
                    else -> Unit // Pianifica: nuovo budget/obiettivo arrivano nel blocco B6
                }
            })
            DropdownMenu(fabMenu, { fabMenu = false }) {
                DropdownMenuItem(text = { Text(stringResource(R.string.spesa_entrata)) }, onClick = { fabMenu = false; editor = "tx:new" },
                    leadingIcon = { Icon(com.bucktrail.android.ui.components.SfIcons.forName("plus.circle"), null) })
                DropdownMenuItem(text = { Text(stringResource(R.string.trasferimento_tra_conti)) }, onClick = { fabMenu = false /* trasferimento: blocco B3 */ },
                    leadingIcon = { Icon(com.bucktrail.android.ui.components.SfIcons.forName("arrow.left.arrow.right"), null) })
            }
        }
    }

    when (val e = editor) {
        null -> Unit
        "account" -> AddAccountForm(data.prefs.currencyCode, onSave = { vm.saveAccountChecked(it) }, onClose = { editor = null })
        else -> {
            val existing = if (e == "tx:new") null else ledger.transactions.firstOrNull { it.id == e.removePrefix("tx:") }
            if (e == "tx:new" || existing != null) AddTransactionForm(
                existing, ledger.accounts, ledger.categories, data.prefs.currencyCode, today, zone, vm::classify,
                onSave = { vm.saveTransaction(it) }, onClose = { editor = null },
            ) else LaunchedEffect(Unit) { editor = null }
        }
    }
}
