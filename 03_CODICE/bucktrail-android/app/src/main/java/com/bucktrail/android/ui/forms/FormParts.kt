package com.bucktrail.android.ui.forms

import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.layout.wrapContentWidth
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.testTag
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
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.window.Dialog
import androidx.compose.ui.window.DialogProperties
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo

/** Contenitore a pagina intera (sfondo `paper`) per i form: sheet iOS «a pagina intera». */
@Composable
fun FullScreenForm(onDismiss: () -> Unit, cancelTag: String = "btn_cancel", content: @Composable () -> Unit) {
    Dialog(onDismissRequest = onDismiss, properties = DialogProperties(usePlatformDefaultWidth = false, decorFitsSystemWindows = false)) {
        com.bucktrail.android.ui.components.DialogStatusBarEffect()
        Box(Modifier.fillMaxSize().background(Bt.colors.paper).systemBarsPadding().imePadding().wrapContentWidth(androidx.compose.ui.Alignment.CenterHorizontally).widthIn(max = 640.dp).fillMaxSize()) {
            Column(Modifier.fillMaxSize().verticalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 16.dp), verticalArrangement = Arrangement.spacedBy(36.dp)) {
                CancelPill(onDismiss, Modifier.testTag(cancelTag))
                androidx.compose.runtime.CompositionLocalProvider(LocalOptionDivider provides true) { content() }
            }
        }
    }
}

/** «Annulla» in alto a sinistra come il pulsante di navigazione degli sheet iOS: capsula `surface` con bordo `fog`, testo 15 `smoke`. */
@Composable
fun CancelPill(onClick: () -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    val shape = androidx.compose.foundation.shape.RoundedCornerShape(50)
    Box(modifier.heightIn(min = 44.dp).clip(shape).background(c.surface).border(1.dp, c.fog, shape).clickable(role = Role.Button, onClick = onClick).padding(horizontal = 18.dp), contentAlignment = Alignment.Center) {
        Text(androidx.compose.ui.res.stringResource(com.bucktrail.android.R.string.annulla), style = Typo.ghostButton, color = c.smoke)
    }
}

/** Le righe opzione dei form iOS hanno la linea sottile sotto (`ThinDivider`); nelle Impostazioni no. */
val LocalOptionDivider = androidx.compose.runtime.compositionLocalOf { false }

/** Riga opzione: titolo + sottotitolo a sinistra, controllo a destra. */
@Composable
fun OptionRow(title: String, subtitle: String? = null, modifier: Modifier = Modifier, titleColor: androidx.compose.ui.graphics.Color = androidx.compose.ui.graphics.Color.Unspecified, trailing: @Composable () -> Unit) {
    Column(Modifier.fillMaxWidth()) {
        Row(modifier.fillMaxWidth().heightIn(min = 48.dp).padding(vertical = if (LocalOptionDivider.current) 6.dp else 0.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
            Column(Modifier.weight(1f).padding(end = 12.dp)) {
                Text(title, style = Typo.formOption, color = if (titleColor == androidx.compose.ui.graphics.Color.Unspecified) Bt.colors.ink else titleColor)
                subtitle?.let { Text(it, style = Typo.formOptionSub, color = Bt.colors.smoke) }
            }
            trailing()
        }
        if (LocalOptionDivider.current) com.bucktrail.android.ui.components.ThinDivider(color = Bt.colors.fog)
    }
}

@Composable
fun FormSwitch(
    checked: Boolean, onChange: (Boolean) -> Unit, description: String, modifier: Modifier = Modifier, enabled: Boolean = true,
    tint: androidx.compose.ui.graphics.Color = androidx.compose.ui.graphics.Color.Unspecified,
) {
    val c = Bt.colors
    // iOS: `.tint(DS.ink)` ovunque tranne la modalità demo (ambra); pollice bianco (in scuro `paper` per restare visibile sulla traccia chiara).
    val track = if (tint == androidx.compose.ui.graphics.Color.Unspecified) c.ink else tint
    val thumb = if (c.isDark && track == c.ink) c.paper else androidx.compose.ui.graphics.Color.White
    Switch(
        checked, onChange, modifier = modifier.androidx_semantics(description), enabled = enabled,
        colors = SwitchDefaults.colors(checkedThumbColor = thumb, checkedTrackColor = track, checkedBorderColor = track, uncheckedThumbColor = androidx.compose.ui.graphics.Color.White, uncheckedTrackColor = if (c.isDark) c.smoke.copy(alpha = 0.45f) else c.fog, uncheckedBorderColor = if (c.isDark) c.smoke.copy(alpha = 0.45f) else c.fog),
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
        Text(label, style = (if (selected) Typo.formOption.copy(fontFamily = com.bucktrail.android.ui.theme.Fonts.formSemibold) else Typo.formOption).copy(fontSize = 13.sp), color = if (selected) c.ink else c.smoke)
        Box(Modifier.height(1.dp).fillMaxWidth().background(if (selected) c.ink else androidx.compose.ui.graphics.Color.Transparent))
    }
}

private fun Modifier.androidx_semantics(description: String): Modifier = this.semantics { contentDescription = description }

/** Valore data a capsula (iOS `DatePicker` compatto): riempimento `fog` a metà, testo 17 ink. */
@Composable
fun DatePill(text: String) {
    val c = Bt.colors
    Box(Modifier.clip(androidx.compose.foundation.shape.RoundedCornerShape(50)).background(c.fog.copy(alpha = 0.55f)).padding(horizontal = 14.dp, vertical = 7.dp)) {
        Text(text, style = Typo.formOption.copy(fontSize = 17.sp), color = c.ink)
    }
}
