package com.bucktrail.android.ui.screens

import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.Settings
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.gestures.detectDragGestures
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.semantics.stateDescription
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.domain.AccountType
import com.bucktrail.android.domain.HomeAccountOrder
import com.bucktrail.android.ui.AppData
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.accountTypeRes
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.forms.FormSwitch
import com.bucktrail.android.ui.forms.OptionRow
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Fonts
import com.bucktrail.android.ui.theme.Typo
import java.util.Currency

class SettingsActions(
    val onSetCurrency: (String) -> Unit, val onSetFixedExpenses: (Boolean) -> Unit, val onSetFixedIncome: (Boolean) -> Unit,
    val onClose: () -> Unit,
)

/** Impostazioni (§4.9): Lingua, Valuta, Home, Info. Sicurezza, notifiche, export, demo e account arrivano nei blocchi B7–B9. */
@Composable
fun SettingsSheet(data: AppData, actions: SettingsActions) {
    val c = Bt.colors
    val context = LocalContext.current
    var currencyMenu by remember { mutableStateOf(false) }
    var pendingCurrency by remember { mutableStateOf<String?>(null) }
    val version = remember { runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull().orEmpty() }
    val prefs = data.prefs

    SheetPage(
        stringResource(R.string.impostazioni), actions.onClose,
        trailing = { BarAction(stringResource(R.string.chiudi), actions.onClose, Modifier.testTag("btn_closeSettings")) },
    ) {
        Column(Modifier.padding(horizontal = 20.dp, vertical = 8.dp)) {
            // Lingua
            SettingsSection {
                SectionLabel(stringResource(R.string.lingua))
                Text(stringResource(R.string.la_lingua_dell_app_segue_le_preferenze_d), style = Typo.formOption, color = c.smoke)
                Row(
                    Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button) {
                        val intent = if (Build.VERSION.SDK_INT >= 33) Intent(Settings.ACTION_APP_LOCALE_SETTINGS, Uri.fromParts("package", context.packageName, null))
                        else Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS, Uri.fromParts("package", context.packageName, null))
                        runCatching { context.startActivity(intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)) }
                    },
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(stringResource(R.string.apri_impostazioni_lingua), style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.ink)
                    Icon(SfIcons.forName("arrow.up"), null, tint = c.smoke, modifier = Modifier.size(16.dp).graphicsLayer { rotationZ = 45f })
                }
            }
            ThinDivider(color = c.fog)
            // Valuta
            SettingsSection {
                SectionLabel(stringResource(R.string.valuta))
                Box {
                    Row(
                        Modifier.fillMaxWidth().heightIn(min = 48.dp).testTag("picker_currency").clickable(role = Role.Button) { currencyMenu = true },
                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
                    ) {
                        Text(currencyLabel(prefs.currencyCode), style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.ink)
                        Icon(SfIcons.forName("chevron.down"), null, tint = c.smoke, modifier = Modifier.size(16.dp))
                    }
                    DropdownMenu(currencyMenu, { currencyMenu = false }) {
                        Fmt.currencies.forEach { code ->
                            DropdownMenuItem(
                                text = { Text(currencyLabel(code) + if (code == prefs.currencyCode) "  ✓" else "") },
                                onClick = { currencyMenu = false; if (code != prefs.currencyCode) pendingCurrency = code },
                            )
                        }
                    }
                }
            }
            ThinDivider(color = c.fog)
            // Home
            SettingsSection {
                SectionLabel(stringResource(R.string.home))
                OptionRow(stringResource(R.string.spese_fisse_mensili), stringResource(R.string.mostra_il_totale_delle_spese_fisse_del_m)) {
                    FormSwitch(prefs.showFixedExpensesTotal, actions.onSetFixedExpenses, stringResource(R.string.spese_fisse_mensili))
                }
                OptionRow(stringResource(R.string.entrate_fisse_mensili), stringResource(R.string.mostra_il_totale_delle_entrate_fisse_del)) {
                    FormSwitch(prefs.showFixedIncomeTotal, actions.onSetFixedIncome, stringResource(R.string.entrate_fisse_mensili))
                }
            }
            ThinDivider(color = c.fog)
            // Info
            SettingsSection {
                SectionLabel(stringResource(R.string.info))
                OptionRow(stringResource(R.string.versione)) { Text(version, style = Typo.formOption, color = c.smoke) }
                OptionRow(stringResource(R.string.transazioni_totali)) { Text("${data.ledger.transactions.size}", style = Typo.formOption, color = c.smoke, modifier = Modifier.testTag("settings_txCount")) }
            }
        }
    }

    pendingCurrency?.let { code ->
        Dialog(onDismissRequest = {}, properties = DialogProperties(dismissOnBackPress = false, dismissOnClickOutside = false)) {
            Column(
                Modifier.fillMaxWidth().clip(RoundedCornerShape(24.dp)).background(c.surface).padding(24.dp),
                horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(12.dp),
            ) {
                Text(Fmt.currencySymbol(code), style = Typo.formAmount.copy(fontFamily = Fonts.formUltraLight), color = c.ink)
                Text(currencyName(code), style = Typo.rowName, color = c.ink)
                Text(stringResource(R.string.il_simbolo_verra_aggiornato_ovunque_nell), style = Typo.formOption, color = c.smoke, textAlign = TextAlign.Center)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceEvenly) {
                    BarAction(stringResource(R.string.annulla), { pendingCurrency = null })
                    BarAction(stringResource(R.string.conferma), { actions.onSetCurrency(code); pendingCurrency = null }, Modifier.testTag("btn_confirmCurrency"), bold = true)
                }
            }
        }
    }
}

private fun currencyName(code: String): String = runCatching { Currency.getInstance(code).displayName }.getOrDefault(code)
private fun currencyLabel(code: String): String = "${Fmt.currencySymbol(code)}  ·  $code  ·  ${currencyName(code)}"

@Composable
private fun SettingsSection(content: @Composable () -> Unit) {
    Column(Modifier.padding(vertical = 18.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) { content() }
}

/** «Conti in home» (`HomeAccountOrderSheet`): scelta e ordine (trascina la maniglia) dei conti nel carosello della Home. */
@Composable
fun HomeAccountOrderSheet(accounts: List<AccountEntity>, saved: List<String>, onSave: (List<String>) -> Unit, onClose: () -> Unit) {
    val c = Bt.colors
    val ids = remember(accounts) { accounts.map { it.id } }
    var state by remember { mutableStateOf(HomeAccountOrder.load(saved, ids)) }
    var dragId by remember { mutableStateOf<String?>(null) }
    var dragOffset by remember { mutableFloatStateOf(0f) }
    val byId = remember(accounts) { accounts.associateBy { it.id } }
    val rowPx = with(androidx.compose.ui.platform.LocalDensity.current) { 64.dp.toPx() }
    val shownDesc = stringResource(R.string.conti_in_home_selezionato)
    val hiddenDesc = stringResource(R.string.conti_in_home_nascosto)
    val upLabel = stringResource(R.string.sposta_su)
    val downLabel = stringResource(R.string.sposta_giu)

    SheetPage(
        stringResource(R.string.conti_in_home), onClose,
        leading = { BarAction(stringResource(R.string.annulla), onClose) },
        trailing = { BarAction(stringResource(R.string.fine), { onSave(HomeAccountOrder.save(state)); onClose() }, Modifier.testTag("btn_doneHomeAccounts"), bold = true) },
    ) {
        state.items.forEachIndexed { index, id ->
            val acc = byId[id] ?: return@forEachIndexed
            key(id) {
                val checked = id in state.shown
                val dragging = dragId == id
                Column(Modifier.graphicsLayer { translationY = if (dragging) dragOffset else 0f; shadowElevation = if (dragging) 12f else 0f }.background(c.paper)) {
                    Row(
                        Modifier.fillMaxWidth().heightIn(min = 64.dp).padding(horizontal = 20.dp).testTag("homeAccountRow_${acc.name}")
                            .semantics {
                                customActions = listOf(
                                    CustomAccessibilityAction(upLabel) { state = state.copy(items = HomeAccountOrder.move(state.items, index, index - 1)); true },
                                    CustomAccessibilityAction(downLabel) { state = state.copy(items = HomeAccountOrder.move(state.items, index, index + 1)); true },
                                )
                            },
                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
                    ) {
                        Box(
                            Modifier.size(44.dp).clickable(role = Role.Checkbox) { state = HomeAccountOrder.toggle(state, id) }
                                .semantics { stateDescription = if (checked) shownDesc else hiddenDesc },
                            contentAlignment = Alignment.Center,
                        ) {
                            Icon(SfIcons.forName(if (checked) "checkmark.circle.fill" else "circle"), null, tint = if (checked) c.ink else c.smoke, modifier = Modifier.size(22.dp))
                        }
                        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                            Text(acc.name, style = Typo.rowName, color = c.ink, maxLines = 1)
                            Text(stringResource(accountTypeRes(AccountType.from(acc.type))), style = Typo.caption, color = c.smoke)
                        }
                        Box(
                            Modifier.size(44.dp).pointerInput(id) {
                                detectDragGestures(
                                    onDragStart = { dragId = id; dragOffset = 0f },
                                    onDragEnd = { dragId = null; dragOffset = 0f }, onDragCancel = { dragId = null; dragOffset = 0f },
                                ) { change, amount ->
                                    change.consume()
                                    dragOffset += amount.y
                                    val from = state.items.indexOf(id)
                                    val target = when {
                                        dragOffset > rowPx / 2 -> from + 1
                                        dragOffset < -rowPx / 2 -> from - 1
                                        else -> from
                                    }
                                    if (target != from && target in state.items.indices) {
                                        state = state.copy(items = HomeAccountOrder.move(state.items, from, target))
                                        dragOffset -= (target - from) * rowPx
                                    }
                                }
                            },
                            contentAlignment = Alignment.Center,
                        ) { Icon(SfIcons.forName("line.3.horizontal"), null, tint = c.smoke, modifier = Modifier.size(22.dp)) }
                    }
                    ThinDivider(Modifier.padding(horizontal = 20.dp), c.fog)
                }
            }
        }
    }
}
