package com.bucktrail.android.ui.forms

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Switch
import androidx.compose.material3.SwitchDefaults
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.unit.dp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo

/** Contenitore a pagina intera (sfondo `paper`) per i form: sheet iOS «a pagina intera». */
@Composable
fun FullScreenForm(onDismiss: () -> Unit, content: @Composable () -> Unit) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        com.bucktrail.android.ui.components.DialogStatusBarEffect()
        Box(Modifier.fillMaxSize().background(Bt.colors.paper).systemBarsPadding().imePadding()) {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(36.dp)) {
                content()
            }
        }
    }
}

/** Riga opzione: titolo + sottotitolo a sinistra, controllo a destra. */
@Composable
fun OptionRow(title: String, subtitle: String? = null, modifier: Modifier = Modifier, trailing: @Composable () -> Unit) {
    Row(modifier.fillMaxWidth().heightIn(min = 48.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
        Column(Modifier.weight(1f).padding(end = 12.dp)) {
            Text(title, style = Typo.formOption, color = Bt.colors.ink)
            subtitle?.let { Text(it, style = Typo.formOptionSub, color = Bt.colors.smoke) }
        }
        trailing()
    }
}

@Composable
fun FormSwitch(checked: Boolean, onChange: (Boolean) -> Unit, description: String) {
    val c = Bt.colors
    Switch(
        checked, onChange,
        colors = SwitchDefaults.colors(checkedThumbColor = c.onAccent, checkedTrackColor = c.accent, uncheckedThumbColor = c.surface, uncheckedTrackColor = c.fog, uncheckedBorderColor = c.fog),
    )
}

/** Linea sottile sotto un campo. */
@Composable
fun FieldLine() {
    Box(Modifier.fillMaxWidth().height(1.dp).background(Bt.colors.fog))
}

/** Chip testuale del conto: selezionato semibold + riga 1pt ink. */
@Composable
fun TextChip(label: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    Column(modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onClick), verticalArrangement = Arrangement.Center) {
        Text(label, style = if (selected) Typo.formOption.copy(fontFamily = com.bucktrail.android.ui.theme.Fonts.formSemibold) else Typo.formOption, color = if (selected) c.ink else c.smoke)
        Box(Modifier.height(1.dp).fillMaxWidth().background(if (selected) c.ink else androidx.compose.ui.graphics.Color.Transparent))
    }
}
