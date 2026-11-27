package com.bucktrail.android.ui.screens

import android.app.Activity
import android.content.ClipData
import android.content.ClipDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.ContextWrapper
import android.content.Intent
import android.os.Build
import android.os.Handler
import android.os.Looper
import android.os.PersistableBundle
import android.view.WindowManager
import androidx.annotation.StringRes
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.selection.SelectionContainer
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.key
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.LocalFocusManager
import androidx.compose.ui.platform.LocalView
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.LiveRegionMode
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.liveRegion
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.DialogWindowProvider
import com.bucktrail.android.R
import com.bucktrail.android.security.Authenticator
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.e2e.E2EController
import com.bucktrail.android.sync.e2e.E2EController.Protection
import com.bucktrail.android.sync.e2e.E2EController.Reason
import com.bucktrail.android.sync.e2e.E2EGate
import com.bucktrail.android.sync.e2e.E2EMigrator
import com.bucktrail.android.sync.e2e.MigrationDirection
import com.bucktrail.android.sync.e2e.RecoveryKey
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.CancellationException
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch

@Composable
internal fun AdvancedProtectionRow(status: E2EController.Status, open: () -> Unit) {
    val c = Bt.colors
    Row(
        Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button, onClick = open)
            .padding(vertical = Dim.s.dp).testTag("e2e_settings"),
        horizontalArrangement = Arrangement.spacedBy(Dim.s.dp),
        verticalAlignment = Alignment.CenterVertically,
    ) {
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(Dim.xs.dp)) {
            Text(stringResource(R.string.e2e_titolo), style = Typo.formOption, color = c.ink)
            val locked = status.lockReason != null
            val subtitle = when {
                status.lockReason == E2EGate.LockReason.ProtectionRemoved -> R.string.e2e_rimossa_titolo
                locked -> R.string.e2e_pausa
                else -> R.string.e2e_sottotitolo
            }
            Text(stringResource(subtitle),
                style = Typo.formOptionSub, color = if (locked) c.plannedText else c.smoke)
        }
        if (status.protection == Protection.On || status.protection == Protection.Off) {
            val on = status.protection == Protection.On
            Text(stringResource(if (on) R.string.e2e_stato_attiva else R.string.e2e_stato_disattivata),
                style = Typo.formOptionSub, color = if (on) c.accent else c.smoke)
        }
        Icon(SfIcons.forName("chevron.right"), null, tint = c.smoke, modifier = Modifier.size(14.dp))
    }
}

private enum class ProtectionPage { Overview, SetPhrase, SaveKey, Unlock, ChangePhrase, RotatedKey, Updated }
private enum class ProtectionDialog { TurnOff, Rotate, Restart }

@Composable
internal fun AdvancedProtectionSheet(
    sync: SyncService, userId: String, status: E2EController.Status?, unlockInitially: Boolean,
    onSignOut: () -> Unit,
    onClose: () -> Unit,
) {
    val c = Bt.colors
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val activity = remember(context) { context.findFragmentActivity() }
    val authTitle = stringResource(R.string.e2e_titolo)
    val authReason = stringResource(R.string.e2e_motivo_biometria)
    val authenticate: suspend () -> Boolean = {
        if (activity == null || !Authenticator.isAvailable(activity)) {
            throw E2EMigrator.Failure(E2EMigrator.Problem.Unavailable)
        }
        Authenticator.authenticate(activity, authTitle, authReason)
    }
    var page by remember { mutableStateOf(if (unlockInitially) ProtectionPage.Unlock else ProtectionPage.Overview) }
    var dialog by remember { mutableStateOf<ProtectionDialog?>(null) }
    var phrase by remember { mutableStateOf("") }
    var repeated by remember { mutableStateOf("") }
    var secret by remember { mutableStateOf("") }
    var recoveryKey by remember { mutableStateOf("") }
    var confirmation by remember { mutableStateOf("") }
    var useRecovery by remember { mutableStateOf(false) }
    var attemptedActivation by remember { mutableStateOf(false) }
    var validation by remember { mutableStateOf<Int?>(null) }
    var issue by remember { mutableStateOf<Reason?>(null) }
    var busy by remember { mutableStateOf(false) }
    var direction by remember { mutableStateOf<MigrationDirection?>(null) }
    var retry by remember { mutableStateOf<(() -> Unit)?>(null) }

    fun clearSecrets() {
        phrase = ""; repeated = ""; secret = ""; recoveryKey = ""; confirmation = ""
        useRecovery = false; attemptedActivation = false; validation = null
    }

    fun move(next: ProtectionPage) {
        clearSecrets()
        issue = null
        retry = null
        page = next
    }

    fun validatePhrase(): Boolean {
        validation = when {
            phrase.codePointCount(0, phrase.length) < 10 -> R.string.e2e_frase_corta
            phrase != repeated -> R.string.e2e_frase_diverse
            else -> null
        }
        return validation == null
    }

    fun <T> run(
        migration: MigrationDirection? = null,
        refresh: Boolean = true,
        action: suspend (E2EMigrator) -> T,
        complete: (T) -> Unit,
    ) {
        if (busy || sync.protection?.value?.busy == true) return
        busy = true
        direction = migration
        issue = null
        scope.launch {
            try {
                complete(sync.withE2EMigrator(expectedUser = userId, refreshOnSuccess = refresh, action = action))
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                val reason = E2EController.issueFor(error)
                issue = when {
                    reason == Reason.Authentication -> null
                    reason == Reason.StateChanged && migration == MigrationDirection.Enable &&
                        sync.protection?.value?.remoteEnabling == true -> Reason.ConcurrentActivation
                    else -> reason
                }
            } finally {
                busy = false
                direction = null
            }
        }
    }

    fun enable() {
        retry = ::enable
        val credentials = Triple(phrase, recoveryKey, confirmation)
        run(MigrationDirection.Enable, action = { migrator ->
            if (!migrator.resumeForUi(MigrationDirection.Enable, allowCommitted = attemptedActivation)) {
                attemptedActivation = true
                migrator.enable(credentials.first, credentials.second, credentials.third)
            }
        }, complete = { move(ProtectionPage.Overview) })
    }

    fun disable() {
        retry = ::disable
        run(MigrationDirection.Disable, action = { migrator ->
            if (!migrator.resumeForUi(MigrationDirection.Disable)) migrator.disable(authenticate)
        }, complete = { move(ProtectionPage.Overview) })
    }

    fun cancelActivation() {
        retry = ::cancelActivation
        run(action = { it.cancelEnable() }, complete = { move(ProtectionPage.Overview) })
    }

    fun resume(migration: MigrationDirection) {
        run(migration, action = { it.resumeForUi(migration) }, complete = { move(ProtectionPage.Overview) })
    }

    fun continueWithoutProtection() {
        if (busy || sync.protection?.value?.busy == true) return
        busy = true
        issue = null
        scope.launch {
            try {
                sync.continueWithoutProtection()
                if (unlockInitially) { clearSecrets(); onClose() } else move(ProtectionPage.Overview)
            } catch (cancelled: CancellationException) {
                throw cancelled
            } catch (error: Exception) {
                issue = E2EController.issueFor(error)
            } finally {
                busy = false
            }
        }
    }

    val protection = status?.protection
    val removed = status?.lockReason == E2EGate.LockReason.ProtectionRemoved
    val waiting = busy || status?.busy == true
    val progress = when {
        !waiting -> null
        protection is Protection.Activating -> Triple(MigrationDirection.Enable, protection.completed, protection.total)
        protection is Protection.Disabling -> Triple(MigrationDirection.Disable, protection.completed, protection.total)
        direction == MigrationDirection.Enable -> Triple(MigrationDirection.Enable, 0, 9)
        direction == MigrationDirection.Disable -> Triple(MigrationDirection.Disable, 0, 8)
        else -> null
    }
    val title = when {
        progress != null -> R.string.e2e_titolo
        removed && page in listOf(ProtectionPage.Overview, ProtectionPage.Unlock) -> R.string.e2e_rimossa_titolo
        page == ProtectionPage.SetPhrase -> R.string.e2e_frase_titolo
        page in listOf(ProtectionPage.SaveKey, ProtectionPage.RotatedKey) -> R.string.e2e_chiave_titolo
        page == ProtectionPage.Unlock -> R.string.e2e_sblocca_titolo
        page == ProtectionPage.ChangePhrase -> R.string.e2e_cambia_frase
        else -> R.string.e2e_titolo
    }
    val canClose = !waiting && page != ProtectionPage.RotatedKey
    val dismiss = { if (canClose) { clearSecrets(); onClose() } }
    val issueToShow = issue ?: if (page == ProtectionPage.Overview && status?.resume != null) status.issue else null

    SheetPage(stringResource(title), dismiss, scroll = false, largeTitle = true,
        trailing = { if (canClose) BarAction(stringResource(R.string.chiudi), dismiss, Modifier.testTag("e2e_close")) },
    ) {
        val focus = LocalFocusManager.current
        val scroll = key(page, progress != null) { rememberScrollState() }
        Column(Modifier.fillMaxWidth().verticalScroll(scroll).padding(horizontal = Dim.screenMargin.dp, vertical = Dim.m.dp),
            verticalArrangement = Arrangement.spacedBy(Dim.l.dp)) {
            if (progress != null) {
                val (operation, completed, total) = progress
                Message(if (operation == MigrationDirection.Enable) R.string.e2e_in_corso else R.string.e2e_disattivazione_in_corso)
                LinearProgressIndicator(progress = { completed.toFloat() / total }, Modifier.fillMaxWidth(), color = c.accent, trackColor = c.fog)
                Text("$completed / $total", style = Typo.formOption, color = c.smoke,
                    modifier = Modifier.testTag("e2e_progress").clearAndSetSemantics {})
            } else when (page) {
                ProtectionPage.Overview -> when (protection) {
                    Protection.Off -> {
                        Message(R.string.e2e_intro)
                        Message(R.string.e2e_metadati)
                        Message(R.string.e2e_avviso_perdita,
                            Modifier.fillMaxWidth().background(c.dangerSoft, RoundedCornerShape(Dim.cardRadius.dp)).padding(Dim.l.dp),
                            color = c.danger)
                        Message(R.string.e2e_avviso_aggiorna)
                        PrimaryButton(stringResource(R.string.e2e_attiva), { move(ProtectionPage.SetPhrase) },
                            Modifier.testTag("e2e_activate"), enabled = !waiting)
                    }
                    Protection.On -> {
                        Message(R.string.e2e_fatto, Modifier.testTag("e2e_active"), color = c.accent)
                        ProtectionAction(R.string.e2e_cambia_frase, enabled = !waiting, tag = "e2e_change_phrase") { move(ProtectionPage.ChangePhrase) }
                        ThinDivider()
                        ProtectionAction(R.string.e2e_nuova_chiave, R.string.e2e_nuova_chiave_nota, enabled = !waiting) { dialog = ProtectionDialog.Rotate }
                        ThinDivider()
                        ProtectionAction(R.string.e2e_disattiva, destructive = true, enabled = !waiting, tag = "e2e_disable") { dialog = ProtectionDialog.TurnOff }
                    }
                    is Protection.Locked -> if (removed) {
                        ProtectionRemovedNotice(!waiting, ::continueWithoutProtection) { clearSecrets(); onClose(); onSignOut() }
                    } else {
                        Message(if (protection.reason == E2EGate.LockReason.Transition) R.string.e2e_altro_dispositivo else R.string.e2e_pausa, color = c.plannedText)
                        PrimaryButton(stringResource(R.string.e2e_sblocca), { move(ProtectionPage.Unlock) }, Modifier.testTag("e2e_unlock_open"), !waiting)
                    }
                    is Protection.Activating, is Protection.Disabling -> {
                        if (issueToShow == null) Message(R.string.e2e_errore, color = c.danger)
                        if (retry == null) status?.resume?.let { current ->
                            PrimaryButton(stringResource(R.string.e2e_riprova), { resume(current) }, enabled = !waiting)
                        }
                    }
                    else -> if (issueToShow == null) Message(R.string.e2e_errore, color = c.danger)
                }
                ProtectionPage.SetPhrase, ProtectionPage.ChangePhrase -> {
                    PhraseFields(phrase, repeated, { phrase = it }, { repeated = it }, validation)
                    PrimaryButton(stringResource(R.string.auth_continua), {
                        if (validatePhrase()) {
                            if (page == ProtectionPage.SetPhrase) {
                                try {
                                    focus.clearFocus()
                                    recoveryKey = RecoveryKey.format(RecoveryKey.generate())
                                    page = ProtectionPage.SaveKey
                                } catch (_: Exception) {
                                    issue = Reason.Verification
                                }
                            } else {
                                focus.clearFocus()
                                val newPhrase = phrase
                                run(refresh = false, action = { it.changePhrase(newPhrase, authenticate) },
                                    complete = { move(ProtectionPage.Updated) })
                            }
                        }
                    }, Modifier.testTag("e2e_continue"), !waiting)
                }
                ProtectionPage.SaveKey -> if (issue == null) {
                    RecoveryCard(recoveryKey, confirmation, { confirmation = it }, ::enable, !waiting)
                }
                ProtectionPage.RotatedKey -> RecoveryCard(recoveryKey, null, {}, { move(ProtectionPage.Overview) }, !waiting)
                ProtectionPage.Updated -> Message(R.string.e2e_frase_cambiata, Modifier.testTag("e2e_phrase_updated"), color = c.accent)
                ProtectionPage.Unlock -> {
                    val reason = status?.lockReason
                    if (reason == E2EGate.LockReason.ProtectionRemoved) {
                        ProtectionRemovedNotice(!waiting, ::continueWithoutProtection) { clearSecrets(); onClose(); onSignOut() }
                    } else if (reason == null || reason == E2EGate.LockReason.Unsupported) {
                        if (issue == null) Message(R.string.e2e_errore, color = c.danger)
                    } else {
                        Message(if (reason == E2EGate.LockReason.Transition) R.string.e2e_altro_dispositivo else R.string.e2e_sblocca_testo)
                        androidx.compose.runtime.key(useRecovery) {
                            SecretField(
                                if (useRecovery) R.string.e2e_chiave_campo else R.string.e2e_frase_campo,
                                secret,
                                { secret = it },
                                "e2e_unlock_secret",
                                keyboard = if (useRecovery) KeyboardType.Ascii else KeyboardType.Password,
                                recoveryKeyFormatting = useRecovery,
                            )
                        }
                        if (useRecovery) {
                            SectionLabel(stringResource(R.string.e2e_frase_titolo))
                            PhraseFields(phrase, repeated, { phrase = it }, { repeated = it }, validation)
                        }
                        PrimaryButton(stringResource(R.string.e2e_sblocca), {
                            if (!useRecovery || validatePhrase()) {
                                focus.clearFocus()
                                val credential = secret
                                val newPhrase = phrase.takeIf { useRecovery }
                                run(action = { if (newPhrase != null) it.recover(credential, newPhrase) else it.unlock(credential) },
                                    complete = { if (unlockInitially) { clearSecrets(); onClose() } else move(ProtectionPage.Overview) })
                            }
                        }, Modifier.testTag("e2e_unlock"), secret.isNotEmpty() && !waiting)
                        ProtectionAction(if (useRecovery) R.string.e2e_usa_frase else R.string.e2e_usa_chiave,
                            enabled = !waiting, tag = "e2e_unlock_method") {
                            val useKey = !useRecovery
                            focus.clearFocus()
                            clearSecrets(); issue = null; useRecovery = useKey
                        }
                        if (reason == E2EGate.LockReason.NeedsSecret) {
                            ProtectionAction(R.string.e2e_perse_entrambe, destructive = true, enabled = !waiting, tag = "e2e_restart") {
                                focus.clearFocus()
                                dialog = ProtectionDialog.Restart
                            }
                        }
                    }
                }
            }
            if (progress == null) {
                issueToShow?.let { problem ->
                    val message = if (problem == Reason.Secret && page != ProtectionPage.Unlock) R.string.e2e_errore else problem.message
                    Message(message, Modifier.testTag("e2e_error"),
                        color = if (problem == Reason.ConcurrentActivation) c.plannedText else c.danger)
                    val retryAction = retry
                    if (retryAction != null && problem != Reason.ConcurrentActivation) {
                        PrimaryButton(stringResource(R.string.e2e_riprova), retryAction, Modifier.testTag("e2e_retry"), !waiting)
                    }
                }
                if (status?.canCancelActivation == true && (page == ProtectionPage.SaveKey || page == ProtectionPage.Overview)) {
                    ProtectionAction(R.string.e2e_annulla_attivazione, destructive = true, enabled = !waiting, tag = "e2e_cancel", click = ::cancelActivation)
                }
                if (waiting) CircularProgressIndicator(Modifier.size(22.dp), color = c.accent, strokeWidth = 2.dp)
            }
        }
    }
    dialog?.let { requested ->
        val (heading, message, confirm) = when (requested) {
            ProtectionDialog.TurnOff -> Triple(R.string.e2e_disattiva_titolo, R.string.e2e_disattiva_testo, R.string.e2e_disattiva)
            ProtectionDialog.Rotate -> Triple(R.string.e2e_nuova_chiave_titolo, R.string.e2e_nuova_chiave_nota, R.string.e2e_nuova_chiave)
            ProtectionDialog.Restart -> Triple(R.string.e2e_ricomincia_titolo, R.string.e2e_ricomincia_testo, R.string.e2e_ricomincia)
        }
        BtAlert(stringResource(heading), stringResource(message), stringResource(confirm),
            onConfirm = {
                dialog = null
                when (requested) {
                    ProtectionDialog.TurnOff -> disable()
                    ProtectionDialog.Rotate -> run(refresh = false, action = { it.rotateRecovery(authenticate) },
                        complete = { key -> move(ProtectionPage.RotatedKey); recoveryKey = key })
                    ProtectionDialog.Restart -> run(MigrationDirection.Disable, action = { it.restartFromDevice(authenticate) },
                        complete = { if (unlockInitially) { clearSecrets(); onClose() } else move(ProtectionPage.Overview) })
                }
            }, onDismiss = { dialog = null }, dismissLabel = stringResource(R.string.annulla),
            modifier = Modifier.testTag("e2e_confirm"), confirmWrap = true)
    }
}

private const val COPIED_LABEL_MS = 2_000L
private const val CLIPBOARD_TTL_MS = 120_000L

/** Niente screenshot né anteprima nelle app recenti finché la chiave di recupero è sullo schermo. */
@Composable
private fun SecureWindowEffect() {
    val view = LocalView.current
    val context = LocalContext.current
    DisposableEffect(view, context) {
        val windows = listOfNotNull((view.parent as? DialogWindowProvider)?.window, context.findActivity()?.window).distinct()
        windows.forEach { it.addFlags(WindowManager.LayoutParams.FLAG_SECURE) }
        onDispose { windows.forEach { it.clearFlags(WindowManager.LayoutParams.FLAG_SECURE) } }
    }
}

private tailrec fun Context.findActivity(): Activity? = when (this) {
    is Activity -> this
    is ContextWrapper -> baseContext.findActivity()
    else -> null
}

/** Dopo 2 minuti toglie la chiave dagli appunti, solo se ci sono ancora quelli copiati da qui (API 28+). */
private fun clearClipboardLater(context: Context, key: String) {
    if (Build.VERSION.SDK_INT < Build.VERSION_CODES.P) return
    Handler(Looper.getMainLooper()).postDelayed({
        val clipboard = context.getSystemService(ClipboardManager::class.java) ?: return@postDelayed
        val current = runCatching { clipboard.primaryClip?.takeIf { it.itemCount > 0 }?.getItemAt(0)?.text?.toString() }.getOrNull()
        // In background `primaryClip` è null (API 29+): si svuota comunque, non si può verificare il contenuto.
        if (current == null || current == key) runCatching { clipboard.clearPrimaryClip() }
    }, CLIPBOARD_TTL_MS)
}

private val Reason.message: Int
    get() = when (this) {
        Reason.Secret -> R.string.e2e_errata
        Reason.ConcurrentActivation -> R.string.e2e_gia_in_corso
        Reason.Network -> R.string.e2e_serve_rete
        else -> R.string.e2e_errore
    }

/**
 * La protezione avanzata è sparita dal server: continuare in chiaro o uscire dall'account.
 * L'uscita chiede sempre la stessa conferma dell'uscita dalle Impostazioni (`AccountSection`).
 */
@Composable
private fun ProtectionRemovedNotice(enabled: Boolean, onContinue: () -> Unit, onSignOut: () -> Unit) {
    var confirmSignOut by remember { mutableStateOf(false) }
    Message(R.string.e2e_rimossa_testo, Modifier.testTag("e2e_removed"), color = Bt.colors.plannedText)
    PrimaryButton(stringResource(R.string.e2e_rimossa_continua), onContinue, Modifier.testTag("e2e_removed_continue"), enabled)
    ProtectionAction(R.string.e2e_rimossa_esci, destructive = true, enabled = enabled, tag = "e2e_removed_sign_out") {
        confirmSignOut = true
    }
    if (confirmSignOut) BtAlert(
        stringResource(R.string.auth_esci_titolo), stringResource(R.string.auth_esci_messaggio), stringResource(R.string.auth_esci_conferma),
        onConfirm = { confirmSignOut = false; onSignOut() }, onDismiss = { confirmSignOut = false },
        dismissLabel = stringResource(R.string.annulla),
    )
}

@Composable
private fun Message(@StringRes text: Int, modifier: Modifier = Modifier, color: Color = Bt.colors.ink) {
    Text(stringResource(text), modifier, color = color, style = Typo.formOption)
}

@Composable
private fun PhraseFields(
    phrase: String, repeated: String, onPhrase: (String) -> Unit, onRepeat: (String) -> Unit, validation: Int?,
) {
    Message(R.string.e2e_frase_aiuto, color = Bt.colors.smoke)
    SecretField(R.string.e2e_frase_campo, phrase, onPhrase, "e2e_phrase")
    SecretField(R.string.e2e_frase_ripeti, repeated, onRepeat, "e2e_repeat")
    validation?.let { Message(it, Modifier.testTag("e2e_phrase_error"), color = Bt.colors.danger) }
}

@Composable
private fun SecretField(
    @StringRes label: Int,
    value: String,
    change: (String) -> Unit,
    tag: String,
    keyboard: KeyboardType = KeyboardType.Password,
    recoveryKeyFormatting: Boolean = false,
) {
    val text = stringResource(label)
    AuthField(text, "", value, change, keyboard, secure = true, tag = tag, recoveryKeyFormatting = recoveryKeyFormatting)
}

@Composable
private fun ProtectionAction(
    @StringRes label: Int, @StringRes note: Int? = null, destructive: Boolean = false,
    enabled: Boolean = true, tag: String = "", click: () -> Unit,
) {
    val c = Bt.colors
    Column(Modifier.fillMaxWidth().heightIn(min = Dim.touchTarget.dp)
        .clickable(enabled = enabled, role = Role.Button, onClick = click).testTag(tag).padding(vertical = Dim.s.dp),
        verticalArrangement = Arrangement.spacedBy(Dim.xs.dp)) {
        Message(label, color = if (destructive) c.danger else c.accent)
        note?.let { Message(it, color = c.smoke) }
    }
}

@Composable
private fun RecoveryCard(key: String, confirmation: String?, change: (String) -> Unit, saved: () -> Unit, enabled: Boolean) {
    val c = Bt.colors
    val context = LocalContext.current
    val focus = LocalFocusManager.current
    val label = stringResource(R.string.e2e_chiave_campo)
    val share = stringResource(R.string.e2e_condividi)
    val shape = RoundedCornerShape(Dim.cardRadius.dp)
    var copied by remember { mutableStateOf(false) }
    SecureWindowEffect()
    if (copied) LaunchedEffect(Unit) { delay(COPIED_LABEL_MS); copied = false }
    SelectionContainer(Modifier.fillMaxWidth().background(c.surface, shape).border(1.dp, c.filterBorder, shape)) {
        Text(key.split('-').chunked(4).joinToString("\n") { it.joinToString("-") },
            Modifier.horizontalScroll(rememberScrollState()).padding(Dim.l.dp).testTag("e2e_recovery_key")
                .semantics { contentDescription = key.toCharArray().joinToString(" ") },
            style = Typo.formOption.copy(fontFamily = FontFamily.Monospace), color = c.ink)
    }
    Row(horizontalArrangement = Arrangement.spacedBy(Dim.m.dp)) {
        BarAction(stringResource(if (copied) R.string.e2e_copiata else R.string.e2e_copia), {
            val clip = ClipData.newPlainText(label, key)
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.TIRAMISU) {
                clip.description.extras = PersistableBundle().apply { putBoolean(ClipDescription.EXTRA_IS_SENSITIVE, true) }
            }
            context.getSystemService(ClipboardManager::class.java)?.let { clipboard ->
                clipboard.setPrimaryClip(clip)
                clearClipboardLater(context.applicationContext, key)
            }
            copied = true
        }, if (copied) Modifier.semantics { liveRegion = LiveRegionMode.Polite } else Modifier, pill = false, color = c.smoke, wrap = true)
        BarAction(share, {
            val intent = Intent(Intent.ACTION_SEND).apply { type = "text/plain"; putExtra(Intent.EXTRA_TEXT, key) }
            context.startActivity(Intent.createChooser(intent, share))
        }, pill = false, color = c.accent, wrap = true)
    }
    Message(R.string.e2e_chiave_testo, color = c.smoke)
    if (confirmation != null) {
        AuthField(stringResource(R.string.e2e_chiave_conferma), "", confirmation, change, KeyboardType.Ascii,
            tag = "e2e_key_confirmation", recoveryKeyFormatting = true)
    }
    PrimaryButton(stringResource(R.string.e2e_chiave_salvata), { focus.clearFocus(); saved() }, Modifier.testTag("e2e_key_saved"),
        enabled && (confirmation == null || key.substringAfterLast('-').equals(confirmation, ignoreCase = true)))
}
