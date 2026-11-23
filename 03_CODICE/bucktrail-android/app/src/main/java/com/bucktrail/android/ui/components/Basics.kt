package com.bucktrail.android.ui.components

import androidx.compose.foundation.BorderStroke
import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.drawBehind
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.PathEffect
import androidx.compose.ui.graphics.Shape
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextDecoration
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bucktrail.android.domain.CategoryTint
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import com.bucktrail.android.ui.theme.colors

/** Bordo tratteggiato (chip secondari, icona pianificato, riga «Archiviati»). */
fun Modifier.dashedBorder(color: Color, radius: Dp, dash: Dp = 3.dp, gap: Dp = 3.dp, width: Dp = 1.dp): Modifier = drawBehind {
    val w = width.toPx()
    drawRoundRect(
        color = color, topLeft = androidx.compose.ui.geometry.Offset(w / 2, w / 2),
        size = Size(size.width - w, size.height - w), cornerRadius = CornerRadius(radius.toPx()),
        style = Stroke(w, pathEffect = PathEffect.dashPathEffect(floatArrayOf(dash.toPx(), gap.toPx()))),
    )
}

/** Card standard: `surface`, raggio 16, padding 16. */
@Composable
fun Card(
    modifier: Modifier = Modifier, radius: Dp = Dim.cardRadius.dp, padding: Dp = Dim.l.dp,
    border: Boolean = false, content: @Composable () -> Unit,
) {
    val c = Bt.colors
    Box(
        modifier.clip(RoundedCornerShape(radius)).background(c.surface)
            .then(if (border) Modifier.border(1.dp, c.fog, RoundedCornerShape(radius)) else Modifier).padding(padding),
    ) { content() }
}

/** Card scura (`hero`), scura anche nel tema chiaro. */
@Composable
fun HeroCard(modifier: Modifier = Modifier, radius: Dp = 24.dp, padding: Dp = 24.dp, content: @Composable () -> Unit) {
    Box(modifier.clip(RoundedCornerShape(radius)).background(Bt.colors.hero).padding(padding)) { content() }
}

@Composable
fun ThinDivider(modifier: Modifier = Modifier, color: Color = Bt.colors.fog) {
    Box(modifier.fillMaxWidth().height(0.5.dp).background(color))
}

@Composable
fun SectionLabel(text: String, modifier: Modifier = Modifier) {
    Text(text.uppercase(), style = Typo.sectionLabel, color = Bt.colors.smoke, modifier = modifier)
}

/** Barra di avanzamento h8 capsula; su hero track `heroDivider` e tacca bianca all'80%. */
@Composable
fun ProgressBar(progress: Float, color: Color, modifier: Modifier = Modifier, onHero: Boolean = false) {
    val c = Bt.colors
    val track = if (onHero) c.heroDivider else c.divider
    Box(modifier.fillMaxWidth().height(8.dp).clip(CircleShape).background(track).drawBehind {
        drawRoundRect(color, size = Size(size.width * progress.coerceIn(0f, 1f), size.height), cornerRadius = CornerRadius(size.height / 2))
        if (onHero) drawRect(Color.White, topLeft = androidx.compose.ui.geometry.Offset(size.width * 0.8f - 1.dp.toPx(), 0f), size = Size(2.dp.toPx(), size.height))
    })
}

/** Colore barra per stato budget: >= 100% danger, >= 80% planned, altrimenti accent. */
@Composable
fun budgetColor(progress: Double): Color {
    val c = Bt.colors
    return when { progress >= 1.0 -> c.danger; progress >= 0.8 -> c.planned; else -> c.accent }
}

/** Badge di stato budget: «Sforato» / «Soglia 80%» / «NN%». */
@Composable
fun BudgetStatus(progress: Double, over: String, threshold: String, modifier: Modifier = Modifier) {
    val c = Bt.colors
    val (bg, fg, text) = when {
        progress >= 1.0 -> Triple(c.dangerSoft, c.danger, over)
        progress >= 0.8 -> Triple(c.plannedSoft, c.plannedText, threshold)
        else -> Triple(c.accentSoft, c.accent, "${(progress * 100).toInt()}%")
    }
    Text(text, style = Typo.caption, color = fg, modifier = modifier.clip(CircleShape).background(bg).padding(horizontal = 8.dp, vertical = 4.dp))
}

/** Selettore a due o più «pillole» (track `fog`, segmento attivo `surface` con ombra leggera). */
@Composable
fun SegmentedPill(options: List<String>, selected: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier, tags: List<String> = emptyList()) {
    val c = Bt.colors
    Row(modifier.fillMaxWidth().clip(CircleShape).background(c.fog).padding(4.dp)) {
        options.forEachIndexed { i, label ->
            val active = i == selected
            Box(
                Modifier.weight(1f).heightIn(min = 44.dp)
                    .then(if (active) Modifier.shadow(3.dp, CircleShape, ambientColor = c.ink.copy(alpha = 0.08f), spotColor = c.ink.copy(alpha = 0.08f)) else Modifier)
                    .clip(CircleShape).background(if (active) c.surface else Color.Transparent)
                    .clickable(role = Role.Tab) { onSelect(i) }
                    .semantics { this.selected = active; if (tags.size > i) contentDescription = label },
                contentAlignment = Alignment.Center,
            ) {
                Text(label, style = Typo.rowName.copy(fontWeight = if (active) FontWeight.SemiBold else FontWeight.Medium),
                    color = if (active) c.ink else c.smoke, maxLines = 1, overflow = TextOverflow.Ellipsis)
            }
        }
    }
}

/** Chip capsula (pagina Ricorrenti, ecc.): attivo `ink`, inattivo `surface` + bordo; `secondary` = bordo tratteggiato. */
@Composable
fun FilterChip(label: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier, secondary: Boolean = false) {
    val c = Bt.colors
    val base = modifier.heightIn(min = 44.dp).clip(CircleShape)
    val styled = when {
        selected -> base.background(c.ink)
        secondary -> base.background(c.surface).dashedBorder(c.filterBorder, 22.dp)
        else -> base.background(c.surface).border(1.dp, c.fog, CircleShape)
    }
    Box(styled.clickable(role = Role.Button, onClick = onClick).padding(horizontal = 16.dp), contentAlignment = Alignment.Center) {
        Text(label, style = Typo.rowName.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium),
            color = if (selected) c.surface else c.ink, maxLines = 1)
    }
}

/** Chip tipo di Movimenti: raggio 12, h 34, attivo `ink`/testo `surface` SemiBold. */
@Composable
fun TypeChip(label: String, selected: Boolean, onClick: () -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    val shape = RoundedCornerShape(12.dp)
    Box(
        modifier.heightIn(min = 34.dp).clip(shape)
            .then(if (selected) Modifier.background(c.ink) else Modifier.background(c.surface).border(1.dp, c.fog, shape))
            .clickable(role = Role.Button, onClick = onClick).padding(horizontal = 14.dp),
        contentAlignment = Alignment.Center,
    ) {
        Text(label, style = Typo.secondary.copy(fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium),
            color = if (selected) c.surface else c.ink, maxLines = 1)
    }
}

/** Chip secondario (mese, categoria): raggio 10, h 32, bordo tratteggiato; categoria attiva = `accentSoft`. */
@Composable
fun SecondaryChip(label: String, onClick: () -> Unit, modifier: Modifier = Modifier, active: Boolean = false, trailing: ImageVector? = null) {
    val c = Bt.colors
    val shape = RoundedCornerShape(10.dp)
    Row(
        modifier.heightIn(min = 32.dp).clip(shape)
            .then(if (active) Modifier.background(c.accentSoft) else Modifier.dashedBorder(c.filterBorder, 10.dp))
            .clickable(role = Role.Button, onClick = onClick).padding(horizontal = 12.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(label, style = Typo.secondary.copy(fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal),
            color = if (active) c.accent else c.ink, maxLines = 1)
        trailing?.let { Icon(it, null, tint = if (active) c.accent else c.smoke, modifier = Modifier.size(14.dp)) }
    }
}

/** Pulsante icona 44x44, raggio 14, bordo `fog`, sfondo `surface`; badge numerico opzionale. */
@Composable
fun RoundIconButton(icon: ImageVector, description: String, onClick: () -> Unit, modifier: Modifier = Modifier, badge: Int = 0) {
    val c = Bt.colors
    val shape = RoundedCornerShape(14.dp)
    Box(modifier.size(Dim.touchTarget.dp)) {
        Box(
            Modifier.matchParentSizeCompat().clip(shape).background(c.surface).border(1.dp, c.fog, shape)
                .clickable(role = Role.Button, onClick = onClick).semantics { contentDescription = description },
            contentAlignment = Alignment.Center,
        ) { Icon(icon, null, tint = c.ink, modifier = Modifier.size(20.dp)) }
        if (badge > 0) Text(
            "$badge", style = Typo.caption.copy(fontWeight = FontWeight.SemiBold, fontSize = 11.sp), color = c.onAccent, textAlign = TextAlign.Center,
            modifier = Modifier.align(Alignment.TopEnd).padding(top = 0.dp).defaultMinSize18().clip(CircleShape).background(c.accent),
        )
    }
}

private fun Modifier.matchParentSizeCompat(): Modifier = this.size(Dim.touchTarget.dp)
private fun Modifier.defaultMinSize18(): Modifier = this.widthIn(min = 18.dp).heightIn(min = 18.dp)

/** Pulsante primario: h52, raggio 14, `ink` (30% se disabilitato). */
@Composable
fun PrimaryButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier, enabled: Boolean = true) {
    val c = Bt.colors
    Box(
        modifier.fillMaxWidth().height(Dim.buttonHeight.dp).clip(RoundedCornerShape(Dim.buttonRadius.dp))
            .background(if (enabled) c.ink else c.ink.copy(alpha = 0.3f))
            .clickable(enabled = enabled, role = Role.Button, onClick = onClick),
        contentAlignment = Alignment.Center,
    ) { Text(text, style = Typo.primaryButton, color = c.surface) }
}

@Composable
fun GhostButton(text: String, onClick: () -> Unit, modifier: Modifier = Modifier) {
    Box(modifier.fillMaxWidth().heightIn(min = Dim.touchTarget.dp).clickable(role = Role.Button, onClick = onClick), contentAlignment = Alignment.Center) {
        Text(text, style = Typo.ghostButton, color = Bt.colors.smoke)
    }
}

/** Segmento Uscita/Entrata dei form: testo 15 semibold ink / regular smoke + riga 1.5 sotto. */
@Composable
fun UnderlineSegment(options: List<String>, selected: Int, onSelect: (Int) -> Unit, modifier: Modifier = Modifier) {
    val c = Bt.colors
    Row(modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(24.dp)) {
        options.forEachIndexed { i, label ->
            val active = i == selected
            Column(Modifier.width(androidx.compose.foundation.layout.IntrinsicSize.Max).heightIn(min = 44.dp).clickable(role = Role.Tab) { onSelect(i) }.semantics { this.selected = active }, verticalArrangement = Arrangement.Center) {
                Text(label, style = Typo.formOption.copy(fontSize = 15.sp, fontWeight = if (active) FontWeight.SemiBold else FontWeight.Normal), color = if (active) c.ink else c.smoke)
                Spacer(Modifier.height(6.dp))
                Box(Modifier.fillMaxWidth().height(1.5.dp).background(if (active) c.ink else Color.Transparent))
            }
        }
    }
}

/** Stato vuoto: icona 40 ultraLight `fog`, titolo, sottotitolo, CTA sottolineata. */
@Composable
fun EmptyState(icon: ImageVector, title: String, subtitle: String? = null, cta: String? = null, onCta: (() -> Unit)? = null, modifier: Modifier = Modifier) {
    val c = Bt.colors
    Column(modifier.fillMaxWidth().padding(horizontal = 40.dp, vertical = 36.dp), horizontalAlignment = Alignment.CenterHorizontally, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Icon(icon, null, tint = c.fog, modifier = Modifier.size(40.dp))
        Text(title, style = Typo.emptyTitle, color = c.ink, textAlign = TextAlign.Center)
        subtitle?.let { Text(it, style = Typo.emptySub, color = c.smoke, textAlign = TextAlign.Center) }
        if (cta != null && onCta != null) Text(cta, style = Typo.emptyCta.copy(textDecoration = TextDecoration.Underline), color = c.ink,
            modifier = Modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onCta).padding(top = 8.dp))
    }
}

/** ‹ mese anno › (chevron 14 smoke, mese `rowName`). */
@Composable
fun MonthBar(label: String, onPrevious: () -> Unit, onNext: () -> Unit, previousDescription: String, nextDescription: String, modifier: Modifier = Modifier) {
    val c = Bt.colors
    Row(modifier.fillMaxWidth().heightIn(min = 44.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.Center) {
        Box(Modifier.size(44.dp).clickable(role = Role.Button, onClick = onPrevious).semantics { contentDescription = previousDescription }, contentAlignment = Alignment.Center) {
            Icon(SfIcons.forName("chevron.left"), null, tint = c.smoke, modifier = Modifier.size(14.dp))
        }
        Text(label, style = Typo.rowName, color = c.ink, modifier = Modifier.padding(horizontal = 12.dp))
        Box(Modifier.size(44.dp).clickable(role = Role.Button, onClick = onNext).semantics { contentDescription = nextDescription }, contentAlignment = Alignment.Center) {
            Icon(SfIcons.forName("chevron.right"), null, tint = c.smoke, modifier = Modifier.size(14.dp))
        }
    }
}

/** Quadrato icona categoria 38x38 raggio 12 (pianificato: nessun fill, bordo tratteggiato ambra). */
@Composable
fun CategoryIconBox(sfName: String, category: String, modifier: Modifier = Modifier, planned: Boolean = false, transfer: Boolean = false, size: Dp = 38.dp, radius: Dp = 12.dp) {
    val c = Bt.colors
    val tint = CategoryTint.tint(category).colors(c.isDark)
    val fg = when { planned -> c.plannedText; transfer -> c.transfer; else -> tint.foreground }
    val bg = when { planned -> Color.Transparent; transfer -> if (c.isDark) Color(0xFF1B2A3B) else Color(0xFFE4ECF6); else -> tint.background }
    Box(
        modifier.size(size).clip(RoundedCornerShape(radius)).background(bg)
            .then(if (planned) Modifier.dashedBorder(c.planned, radius) else Modifier),
        contentAlignment = Alignment.Center,
    ) { Icon(SfIcons.forName(if (transfer) "arrow.left.arrow.right" else sfName), null, tint = fg, modifier = Modifier.size(size * 0.5f)) }
}

enum class MovementKind { Expense, Income, Transfer }

/**
 * Riga movimento (§1.4): icona 38, titolo `rowName` (+ `repeat` se serie), metadati caption, importo a destra.
 * Colore importo: pianificato = plannedText; uscita = ink; entrata = accent; trasferimento = transfer.
 */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun MovementRow(
    title: String, meta: String, amount: String, kind: MovementKind, categoryName: String, categoryIcon: String,
    modifier: Modifier = Modifier, planned: Boolean = false, recurring: Boolean = false, compact: Boolean = false,
    onClick: (() -> Unit)? = null, onLongClick: (() -> Unit)? = null,
) {
    val c = Bt.colors
    val color = when { planned -> c.plannedText; kind == MovementKind.Income -> c.accent; kind == MovementKind.Transfer -> c.transfer; else -> c.ink }
    val sign = when (kind) { MovementKind.Expense -> "\u2212"; MovementKind.Income -> "+"; MovementKind.Transfer -> "" }
    Row(
        modifier.fillMaxWidth()
            .then(if (onClick != null || onLongClick != null) Modifier.combinedClickable(onClick = { onClick?.invoke() }, onLongClick = onLongClick) else Modifier)
            .padding(horizontal = 14.dp, vertical = if (compact) 10.dp else Dim.rowVPad.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        CategoryIconBox(categoryIcon, categoryName, planned = planned, transfer = kind == MovementKind.Transfer)
        Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(title, style = Typo.rowName, color = c.ink, maxLines = 1, overflow = TextOverflow.Ellipsis, modifier = Modifier.weight(1f, fill = false))
                if (recurring) Icon(SfIcons.forName("repeat"), null, tint = c.smoke, modifier = Modifier.size(12.dp))
            }
            Text(meta, style = Typo.caption, color = c.smoke, maxLines = 1, overflow = TextOverflow.Ellipsis)
        }
        Text(sign + amount, style = Typo.rowAmount, color = color, maxLines = 1, softWrap = false)
    }
}

/** Ombra colorata (API 28+ rispetta i colori; sotto resta quella di default). */
fun Modifier.tintedShadow(elevation: Dp, shape: Shape, color: Color): Modifier =
    shadow(elevation, shape, clip = false, ambientColor = color, spotColor = color)

@Composable
fun HorizontalScrollRow(modifier: Modifier = Modifier, spacing: Dp = 8.dp, content: @Composable () -> Unit) {
    Row(modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(spacing), verticalAlignment = Alignment.CenterVertically) { content() }
}

/** Testo a una riga che riduce il corpo (fino a `minScale`) se non entra, come `minimumScaleFactor` iOS. */
@Composable
fun FitText(text: String, style: TextStyle, color: Color, modifier: Modifier = Modifier, minScale: Float = 0.6f, textAlign: TextAlign? = null) {
    var scale = androidx.compose.runtime.remember(text) { androidx.compose.runtime.mutableFloatStateOf(1f) }
    Text(
        text, color = color, maxLines = 1, softWrap = false, textAlign = textAlign, modifier = modifier,
        style = style.copy(fontSize = style.fontSize * scale.floatValue, letterSpacing = style.letterSpacing),
        onTextLayout = { if (it.didOverflowWidth && scale.floatValue > minScale) scale.floatValue = (scale.floatValue * 0.92f).coerceAtLeast(minScale) },
    )
}
