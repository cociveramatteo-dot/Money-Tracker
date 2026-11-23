package com.bucktrail.android.ui.screens

import android.content.Context
import android.content.ContextWrapper
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
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.rememberCoroutineScope
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
import androidx.compose.ui.unit.sp
import androidx.fragment.app.FragmentActivity
import com.bucktrail.android.data.AuditLog
import com.bucktrail.android.domain.AuditDiff
import com.bucktrail.android.export.ShareFiles
import com.bucktrail.android.notifications.rememberNotificationPermission
import com.bucktrail.android.security.Authenticator
import com.bucktrail.android.ui.components.EmptyState
import com.bucktrail.android.ui.theme.Dim
import kotlinx.coroutines.launch
import java.io.File
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
    val onSetNotifications: (Boolean) -> Unit, val onSetMonthlyReport: (Boolean) -> Unit, val onSetAppLock: (Boolean) -> Unit,
    val onSetDemo: (Boolean) -> Unit, val onExportCsv: suspend () -> File?, val onExportJson: suspend () -> File?,
    val onOpenAudit: () -> Unit, val onClose: () -> Unit,
)

/** Impostazioni (§4.9): Lingua, Valuta, Notifiche, Sicurezza, Home, Esportazione, Demo, Info, Account. */
@Composable
fun SettingsSheet(data: AppData, actions: SettingsActions, account: AccountSettings) {
    val c = Bt.colors
    val context = LocalContext.current
    var currencyMenu by remember { mutableStateOf(false) }
    var pendingCurrency by remember { mutableStateOf<String?>(null) }
    val version = remember { runCatching { context.packageManager.getPackageInfo(context.packageName, 0).versionName }.getOrNull().orEmpty() }
    val prefs = data.prefs
    val scope = rememberCoroutineScope()
    val activity = remember(context) { context.findFragmentActivity() }
    val lockAvailable = remember { Authenticator.isAvailable(context) }
    val appName = stringResource(R.string.app_name)
    val lockReason = stringResource(R.string.blocco_motivo)
    var permissionDenied by remember { mutableStateOf(false) }
    val askPermission = rememberNotificationPermission { granted -> if (granted) actions.onSetNotifications(true) else permissionDenied = true }
    var csv by remember { mutableStateOf<File?>(null) }
    var json by remember { mutableStateOf<File?>(null) }
    var csvBusy by remember { mutableStateOf(false) }
    var jsonBusy by remember { mutableStateOf(false) }
    var exportFailed by remember { mutableStateOf(false) }
    DisposableEffect(Unit) { onDispose { ShareFiles.clear(context) } }

    SheetPage(
        stringResource(R.string.impostazioni), actions.onClose,
        trailing = { BarAction(stringResource(R.string.chiudi), actions.onClose, Modifier.testTag("btn_closeSettings")) },
        largeTitle = true,
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
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(10.dp)) {
                        Icon(SfIcons.forName("gearshape"), null, tint = c.ink, modifier = Modifier.size(20.dp))
                        Text(stringResource(R.string.apri_impostazioni_lingua), style = Typo.formOption.copy(fontFamily = Fonts.formMedium, fontSize = 17.sp), color = c.ink)
                    }
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
                        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp),
                    ) {
                        Text(currencyLabel(prefs.currencyCode), style = Typo.formOption.copy(fontSize = 17.sp), color = c.ink)
                        Icon(SfIcons.forName("chevron.up.chevron.down"), null, tint = c.ink, modifier = Modifier.size(16.dp))
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
            // Notifiche
            SettingsSection {
                SectionLabel(stringResource(R.string.notifiche))
                OptionRow(stringResource(R.string.avvisi_automatici), stringResource(R.string.budget_quasi_esaurito_fissi_in_scadenza)) {
                    FormSwitch(
                        prefs.notificationsEnabled,
                        { on -> if (on) { permissionDenied = false; askPermission() } else actions.onSetNotifications(false) },
                        stringResource(R.string.avvisi_automatici), Modifier.testTag("toggle_notifications"),
                    )
                }
                if (permissionDenied) Text(stringResource(R.string.notifiche_permesso_negato), style = Typo.formOptionSub, color = c.danger)
                ThinDivider(color = c.fog)
                OptionRow(
                    stringResource(R.string.report_mensile_pdf), stringResource(R.string.promemoria_il_1_di_ogni_mese_per_generar),
                    Modifier.graphicsLayer { alpha = if (prefs.notificationsEnabled) 1f else 0.4f },
                ) {
                    FormSwitch(prefs.monthlyReportEnabled, actions.onSetMonthlyReport, stringResource(R.string.report_mensile_pdf), Modifier.testTag("toggle_monthlyReport"), enabled = prefs.notificationsEnabled)
                }
            }
            ThinDivider(color = c.fog)
            // Sicurezza
            SettingsSection {
                SectionLabel(stringResource(R.string.sicurezza))
                OptionRow(
                    stringResource(R.string.blocco_app),
                    stringResource(if (lockAvailable) R.string.blocco_app_disponibile else R.string.blocco_app_non_disponibile),
                ) {
                    FormSwitch(
                        prefs.appLockEnabled,
                        { on ->
                            if (on) actions.onSetAppLock(true)
                            else scope.launch {
                                // Spegnere una protezione richiede una nuova autenticazione (se disponibile).
                                val ok = !lockAvailable || activity == null || Authenticator.authenticate(activity, appName, lockReason)
                                if (ok) actions.onSetAppLock(false)
                            }
                        },
                        stringResource(R.string.blocco_app), Modifier.testTag("toggle_appLock"), enabled = lockAvailable,
                    )
                }
                ThinDivider(color = c.fog)
                Row(
                    Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button, onClick = actions.onOpenAudit).testTag("btn_auditLog"),
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
                ) {
                    Text(stringResource(R.string.cronologia_modifiche), style = Typo.formOption, color = c.ink)
                    Icon(SfIcons.forName("chevron.right"), null, tint = c.smoke, modifier = Modifier.size(14.dp))
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
            // Esportazione dati
            SettingsSection {
                SectionLabel(stringResource(R.string.esportazione_dati))
                Text(stringResource(R.string.esporta_tutte_le_transazioni_in_formato), style = Typo.formOption.copy(fontSize = 13.sp), color = c.smoke)
                ExportButton(
                    csv, csvBusy, stringResource(R.string.genera_csv), stringResource(R.string.condividi_csv), primary = true, "btn_generateCsv",
                    onGenerate = { scope.launch { csvBusy = true; csv = actions.onExportCsv(); csvBusy = false; if (csv == null) exportFailed = true } },
                    onShare = { csv?.let { ShareFiles.share(context, it, "text/csv") } },
                )
                ThinDivider(color = c.fog)
                Text(stringResource(R.string.esporta_json_descrizione), style = Typo.formOption.copy(fontSize = 13.sp), color = c.smoke)
                ExportButton(
                    json, jsonBusy, stringResource(R.string.esporta_json_genera), stringResource(R.string.esporta_json_condividi), primary = false, "btn_generateJson",
                    onGenerate = { scope.launch { jsonBusy = true; json = actions.onExportJson(); jsonBusy = false; if (json == null) exportFailed = true } },
                    onShare = { json?.let { ShareFiles.share(context, it, "application/json") } },
                )
                if (exportFailed) Text(stringResource(R.string.esporta_errore), style = Typo.formOptionSub, color = c.danger)
            }
            ThinDivider(color = c.fog)
            // Modalità demo
            SettingsSection {
                SectionLabel(stringResource(R.string.modalita_demo_68b79c))
                Text(stringResource(R.string.mostra_l_app_con_dati_di_esempio_senza_e), style = Typo.formOption.copy(fontSize = 13.sp), color = c.smoke)
                OptionRow(stringResource(R.string.attiva_modalita_demo), stringResource(R.string.i_tuoi_dati_reali_restano_intatti_e_priv)) {
                    FormSwitch(prefs.demoModeEnabled, actions.onSetDemo, stringResource(R.string.attiva_modalita_demo), Modifier.testTag("toggle_demoMode"), tint = c.planned)
                }
                if (prefs.demoModeEnabled) Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(c.fog.copy(alpha = 0.5f)).padding(12.dp),
                    verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(SfIcons.forName("info.circle.fill"), null, tint = c.planned, modifier = Modifier.size(14.dp).padding(top = 2.dp))
                    Text(stringResource(R.string.l_app_si_riavviera_con_dati_demo_per_tor), style = Typo.caption, color = c.smoke)
                }
            }
            ThinDivider(color = c.fog)
            // Scorciatoie (equivalente Android di «Siri & Shortcut»)
            SettingsSection {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    SectionLabel(stringResource(R.string.scorciatoie_sezione))
                    Text(stringResource(R.string.scorciatoie_extra_android), style = Typo.formOptionSub, color = c.smoke)
                }
                Text(stringResource(R.string.scorciatoie_testo), style = Typo.formOption.copy(fontSize = 13.sp), color = c.smoke)
                val pinWidget = remember { com.bucktrail.android.shortcuts.ShortcutSetup.canPinWidget(context) }
                if (pinWidget) ShortcutRow(stringResource(R.string.scorciatoie_aggiungi_widget), "btn_pinWidget") { com.bucktrail.android.shortcuts.ShortcutSetup.pinWidget(context) }
                if (Build.VERSION.SDK_INT >= 33) ShortcutRow(stringResource(R.string.scorciatoie_aggiungi_tile), "btn_addTile") { com.bucktrail.android.shortcuts.ShortcutSetup.requestTile(context) }
                Row(Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(c.fog.copy(alpha = 0.5f)).padding(12.dp), verticalAlignment = Alignment.Top, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    Icon(SfIcons.forName("lightbulb.fill"), null, tint = c.ink.copy(alpha = 0.5f), modifier = Modifier.size(14.dp).padding(top = 2.dp))
                    Text(stringResource(R.string.scorciatoie_suggerimento), style = Typo.caption, color = c.smoke)
                }
            }
            ThinDivider(color = c.fog)
            // Info
            SettingsSection {
                SectionLabel(stringResource(R.string.info))
                OptionRow(stringResource(R.string.versione)) { Text(version, style = Typo.formOption, color = c.smoke) }
                OptionRow(stringResource(R.string.transazioni_totali)) { Text("${data.ledger.transactions.size}", style = Typo.formOption, color = c.smoke, modifier = Modifier.testTag("settings_txCount")) }
            }
            ThinDivider(color = c.fog)
            // Account (in fondo, come iOS)
            AccountSection(account)
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
                    BarAction(stringResource(R.string.annulla), { pendingCurrency = null }, pill = false)
                    BarAction(stringResource(R.string.conferma), { actions.onSetCurrency(code); pendingCurrency = null }, Modifier.testTag("btn_confirmCurrency"), bold = true, pill = false)
                }
            }
        }
    }
}

@Composable
private fun ShortcutRow(label: String, tag: String, onClick: () -> Unit) {
    val c = Bt.colors
    Row(
        Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button, onClick = onClick).testTag(tag),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(label, style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.ink)
        Icon(SfIcons.forName("arrow.up"), null, tint = c.smoke, modifier = Modifier.size(16.dp).graphicsLayer { rotationZ = 45f })
    }
}

/** Genera → condividi: a riposo il pulsante crea il file, poi diventa «Condividi…» (come ShareLink iOS). */
@Composable
private fun ExportButton(file: File?, busy: Boolean, generate: String, share: String, primary: Boolean, tag: String, onGenerate: () -> Unit, onShare: () -> Unit) {
    val c = Bt.colors
    val bg = if (primary) c.ink else c.fog
    val fg = if (primary) c.surface else c.ink
    Row(
        Modifier.fillMaxWidth().height(52.dp).clip(RoundedCornerShape(14.dp)).background(if (busy) bg.copy(alpha = 0.6f) else bg)
            .clickable(enabled = !busy, role = Role.Button) { if (file != null) onShare() else onGenerate() }.testTag(tag),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center,
    ) {
        when {
            busy -> {
                CircularProgressIndicator(Modifier.size(18.dp), color = fg, strokeWidth = 2.dp)
                Spacer(Modifier.width(8.dp))
                Text(stringResource(R.string.generazione_in_corso), style = Typo.primaryButton.copy(fontSize = if (primary) 17.sp else 15.sp), color = fg)
            }
            file != null -> {
                Icon(SfIcons.forName("square.and.arrow.up"), null, tint = fg, modifier = Modifier.size(16.dp))
                Spacer(Modifier.width(8.dp))
                Text(share, style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = fg)
            }
            else -> Text(generate, style = if (primary) Typo.primaryButton else Typo.formOption.copy(fontFamily = Fonts.formMedium), color = fg)
        }
    }
}

/** Foglio «Cronologia modifiche» (§4.11): voci più recenti prima, o stato vuoto. */
@Composable
fun AuditLogSheet(load: () -> List<AuditLog.Entry>, onClose: () -> Unit) {
    val c = Bt.colors
    val entries = remember { load() }
    val locale = java.util.Locale.getDefault()
    val zone = java.time.ZoneId.systemDefault()
    val format = remember { java.time.format.DateTimeFormatter.ofLocalizedDateTime(java.time.format.FormatStyle.MEDIUM, java.time.format.FormatStyle.SHORT).withLocale(locale) }
    SheetPage(
        stringResource(R.string.cronologia_modifiche), onClose,
        trailing = { BarAction(stringResource(R.string.chiudi), onClose, Modifier.testTag("btn_closeAudit")) },
    ) {
        if (entries.isEmpty()) EmptyState(SfIcons.forName("clock.arrow.circlepath"), stringResource(R.string.cronologia_vuota_titolo), stringResource(R.string.cronologia_vuota_sottotitolo), modifier = Modifier.padding(top = 60.dp))
        entries.forEach { e ->
            Column {
                Row(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 12.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Dim.m.dp)) {
                    Icon(SfIcons.forName(when (e.action) { "created" -> "plus.circle"; "deleted" -> "trash"; else -> "pencil.circle" }), null, tint = c.smoke, modifier = Modifier.size(20.dp))
                    Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                        Text(if (e.summary == AuditDiff.DELETED_SUMMARY) entityLabel(e.entityType) else e.summary, style = Typo.formOption.copy(fontSize = 14.sp), color = c.ink)
                        val action = stringResource(when (e.action) { "created" -> R.string.cronologia_creato; "deleted" -> R.string.cronologia_eliminato; else -> R.string.cronologia_modificato })
                        Text("$action · ${format.format(java.time.Instant.ofEpochMilli(e.timestamp).atZone(zone))}", style = Typo.formOptionSub, color = c.smoke)
                    }
                }
                ThinDivider(color = c.fog)
            }
        }
    }
}

@Composable
private fun entityLabel(type: String): String = when (type) {
    AuditDiff.TRANSACTION -> stringResource(R.string.cronologia_movimento)
    AuditDiff.ACCOUNT -> stringResource(R.string.conto)
    AuditDiff.BUDGET -> stringResource(R.string.budget)
    AuditDiff.GOAL -> stringResource(R.string.obiettivo)
    else -> type
}

private fun Context.findFragmentActivity(): FragmentActivity? {
    var ctx = this
    while (ctx is ContextWrapper) { if (ctx is FragmentActivity) return ctx; ctx = ctx.baseContext }
    return null
}

private fun currencyName(code: String): String = runCatching { Currency.getInstance(code).displayName }.getOrDefault(code)
private fun currencyLabel(code: String): String = "${Fmt.currencySymbol(code)}  ${currencyName(code)}"

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
                            Modifier.size(48.dp).clickable(role = Role.Checkbox) { state = HomeAccountOrder.toggle(state, id) }
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
