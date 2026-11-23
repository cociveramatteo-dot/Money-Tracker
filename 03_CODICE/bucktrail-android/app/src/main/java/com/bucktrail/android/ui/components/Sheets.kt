package com.bucktrail.android.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ColumnScope
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.SwipeToDismissBox
import androidx.compose.material3.SwipeToDismissBoxValue
import androidx.compose.material3.Text
import androidx.compose.material3.rememberSwipeToDismissBoxState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.rememberUpdatedState
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.delay

/** Le finestre di dialogo hanno una status bar propria: icone scure su sfondo chiaro e viceversa. */
@Composable
fun DialogStatusBarEffect() {
    val view = androidx.compose.ui.platform.LocalView.current
    val dark = Bt.colors.isDark
    androidx.compose.runtime.SideEffect {
        val window = (view.parent as? androidx.compose.ui.window.DialogWindowProvider)?.window ?: return@SideEffect
        androidx.core.view.WindowCompat.getInsetsController(window, view).apply { isAppearanceLightStatusBars = !dark; isAppearanceLightNavigationBars = !dark }
    }
}

/** Azione testuale nella barra del foglio (Annulla / Fine / Chiudi). */
@Composable
fun BarAction(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, bold: Boolean = false, enabled: Boolean = true) {
    Box(modifier.heightIn(min = 44.dp).widthIn(min = 44.dp).clickable(enabled = enabled, role = Role.Button, onClick = onClick), contentAlignment = Alignment.Center) {
        Text(text, style = Typo.rowName.copy(fontWeight = if (bold) FontWeight.SemiBold else FontWeight.Medium), color = if (enabled) Bt.colors.ink else Bt.colors.smoke, maxLines = 1, softWrap = false)
    }
}

/**
 * Foglio a pagina intera con barra (azione a sinistra, titolo, azione a destra): equivale alle sheet iOS con
 * `NavigationStack` (sfondo `paper`). Il contenuto scorre.
 */
@Composable
fun SheetPage(
    title: String, onDismiss: () -> Unit, modifier: Modifier = Modifier,
    leading: (@Composable () -> Unit)? = null, trailing: (@Composable () -> Unit)? = null,
    scroll: Boolean = true, content: @Composable ColumnScope.() -> Unit,
) {
    val c = Bt.colors
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        DialogStatusBarEffect()
        Column(Modifier.fillMaxSize().background(c.paper).systemBarsPadding().imePadding()) {
            Row(Modifier.fillMaxWidth().heightIn(min = 56.dp).padding(horizontal = 12.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.widthIn(min = 72.dp), contentAlignment = Alignment.CenterStart) { leading?.invoke() }
                Text(title, style = Typo.rowName.copy(fontWeight = FontWeight.SemiBold), color = c.ink, textAlign = TextAlign.Center, maxLines = 2, modifier = Modifier.weight(1f).padding(horizontal = 4.dp))
                Box(Modifier.widthIn(min = 72.dp), contentAlignment = Alignment.CenterEnd) { trailing?.invoke() }
            }
            Column(
                modifier.fillMaxWidth().weight(1f).then(if (scroll) Modifier.verticalScroll(rememberScrollState()) else Modifier),
                content = content,
            )
        }
    }
}

/** Avviso Sentiero: superficie `surface`, azione distruttiva in `danger`. */
@Composable
fun BtAlert(
    title: String, message: String?, confirm: String, onConfirm: () -> Unit, onDismiss: () -> Unit,
    dismissLabel: String, destructive: Boolean = true, confirmEnabled: Boolean = true,
    modifier: Modifier = Modifier, extra: (@Composable () -> Unit)? = null,
) {
    val c = Bt.colors
    AlertDialog(
        onDismissRequest = onDismiss, modifier = modifier, containerColor = c.surface, shape = RoundedCornerShape(20.dp),
        title = { Text(title, style = Typo.sectionTitle, color = c.ink) },
        text = if (message != null || extra != null) ({
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                message?.let { Text(it, style = Typo.secondary.copy(fontSize = androidx.compose.ui.unit.TextUnit(14f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke) }
                extra?.invoke()
            }
        }) else null,
        confirmButton = {
            BarAction(confirm, onConfirm, enabled = confirmEnabled, modifier = Modifier.testTag("alertConfirm"), bold = true)
        },
        dismissButton = { BarAction(dismissLabel, onDismiss) },
    )
}

/** Azione di swipe: sfondo colorato con icona e testo. */
data class SwipeAction(val label: String, val icon: ImageVector, val background: Color, val foreground: Color)

/**
 * Riga con swipe (§4.2): sinistra = elimina (full swipe), destra = conferma/pianificato.
 * `onDelete` ritorna `true` se la riga può uscire subito (altrimenti torna in posizione, es. dialog di conferma).
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SwipeableRow(
    deleteAction: SwipeAction?, onDelete: () -> Boolean,
    toggleAction: SwipeAction?, onToggle: () -> Unit,
    modifier: Modifier = Modifier, content: @Composable () -> Unit,
) {
    val haptic = LocalHapticFeedback.current
    val currentDelete by rememberUpdatedState(onDelete)
    val currentToggle by rememberUpdatedState(onToggle)
    val state = rememberSwipeToDismissBoxState(confirmValueChange = { value ->
        when (value) {
            SwipeToDismissBoxValue.EndToStart -> { haptic.performHapticFeedback(HapticFeedbackType.LongPress); currentDelete() }
            SwipeToDismissBoxValue.StartToEnd -> { haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove); currentToggle(); false }
            SwipeToDismissBoxValue.Settled -> false
        }
    })
    SwipeToDismissBox(
        state = state, modifier = modifier,
        enableDismissFromStartToEnd = toggleAction != null, enableDismissFromEndToStart = deleteAction != null,
        backgroundContent = {
            val action = when (state.dismissDirection) {
                SwipeToDismissBoxValue.EndToStart -> deleteAction
                SwipeToDismissBoxValue.StartToEnd -> toggleAction
                else -> null
            }
            if (action != null) Row(
                Modifier.fillMaxSize().background(action.background).padding(horizontal = 20.dp),
                verticalAlignment = Alignment.CenterVertically,
                horizontalArrangement = if (state.dismissDirection == SwipeToDismissBoxValue.StartToEnd) Arrangement.Start else Arrangement.End,
            ) {
                Icon(action.icon, null, tint = action.foreground, modifier = Modifier.size(20.dp))
                Text(action.label, style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = action.foreground, modifier = Modifier.padding(start = 8.dp))
            }
        },
        content = { Box(Modifier.background(Bt.colors.surface)) { content() } },
    )
}

/** Barra temporanea «Movimento eliminato · Annulla» (capsula `ink`, come il banner sync). */
@Composable
fun UndoBar(message: String, actionLabel: String, key: Long, onAction: () -> Unit, onTimeout: () -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    LaunchedEffect(key) { delay(5_000); onTimeout() }
    Row(
        modifier.clip(RoundedCornerShape(16.dp)).background(c.ink).padding(start = 18.dp, end = 6.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
    ) {
        Text(message, style = Typo.secondary.copy(fontWeight = FontWeight.Medium), color = c.paper, modifier = Modifier.weight(1f, fill = false))
        Box(Modifier.heightIn(min = 44.dp).widthIn(min = 44.dp).clickable(role = Role.Button, onClick = onAction).padding(horizontal = 12.dp), contentAlignment = Alignment.Center) {
            Text(actionLabel, style = Typo.secondary.copy(fontWeight = FontWeight.Bold), color = c.heroAccent)
        }
    }
}
