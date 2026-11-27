package com.bucktrail.android.ui.screens

import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.widthIn
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.CornerRadius
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.clearAndSetSemantics
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Statistics
import com.bucktrail.android.ui.AppData
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.FitText
import com.bucktrail.android.ui.components.MonthBar
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.domain.CategoryTint
import com.bucktrail.android.ui.theme.colors
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

class StatisticsActions(
    val onSettings: () -> Unit,
    val onPdf: () -> Unit,
    val onEditTransaction: (TransactionEntity) -> Unit = {},
    val onDeleteTransaction: (TransactionEntity) -> Unit = {},
)

/** Statistiche (§4.5): tile del mese, Andamento 6M/12M, Per categoria, Abitudini. Grafici in Canvas. */
@Composable
fun StatisticsScreen(
    data: AppData, today: LocalDate, zone: ZoneId, monthOffset: Int, onMonthOffset: (Int) -> Unit, generatingPdf: Boolean, actions: StatisticsActions,
) {
    val c = Bt.colors
    val currency = data.prefs.currencyCode
    val locale = java.util.Locale.getDefault()
    val month = YearMonth.from(today).plusMonths(monthOffset.toLong())
    var range by rememberSaveable { mutableIntStateOf(6) }
    var showHabits by rememberSaveable { mutableStateOf(false) }
    if (showHabits) {
        HabitsPage(data, today, zone, actions.onEditTransaction, actions.onDeleteTransaction) { showHabits = false }
        return
    }
    val transactions = data.ledger.transactionData
    val byMonth = remember(transactions, zone) { Statistics.byMonth(transactions, zone) }
    val totals = Statistics.totalsOf(month, byMonth)
    val categories = remember(transactions, month, zone) { Statistics.categories(transactions, month, zone) }
    val trend = remember(byMonth, month, range) { Statistics.trend(byMonth, month, range) }
    fun money(v: BigDecimal) = Fmt.currency(v, currency)

    Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = (Dim.listBottomPadding + Dim.tabBarReserved).dp)) {
        PageHeader(stringResource(R.string.statistiche)) {
            Row(
                Modifier.heightIn(min = 44.dp).clip(RoundedCornerShape(12.dp)).background(c.surface).border(1.dp, c.fog, RoundedCornerShape(12.dp))
                    .clickable(enabled = !generatingPdf, role = Role.Button, onClick = actions.onPdf).padding(horizontal = 14.dp).testTag("statistics_pdf"),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp),
            ) {
                if (generatingPdf) CircularProgressIndicator(Modifier.size(16.dp), color = c.ink, strokeWidth = 2.dp)
                else Icon(SfIcons.forName("square.and.arrow.down"), null, tint = c.ink, modifier = Modifier.size(16.dp))
                Text(stringResource(R.string.pdf), style = Typo.secondary, color = c.ink)
            }
            Box(
                Modifier.size(48.dp).clickable(role = Role.Button, onClick = actions.onSettings).semantics { contentDescription = "" }.testTag("btn_openSettings"),
                contentAlignment = Alignment.Center,
            ) { Icon(SfIcons.forName("gearshape"), stringResource(R.string.impostazioni), tint = c.ink, modifier = Modifier.size(22.dp)) }
        }
        MonthBar(
            Fmt.monthYear(month, locale), { onMonthOffset(monthOffset - 1) }, { onMonthOffset(monthOffset + 1) },
            stringResource(R.string.mese_precedente), stringResource(R.string.mese_successivo), Modifier.padding(horizontal = 20.dp),
        )
        // Tre tile: Uscite, Entrate, Netto (hero)
        Row(Modifier.fillMaxWidth().padding(horizontal = 16.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            SummaryTile(stringResource(R.string.uscite), money(totals.expenses), c.ink, Modifier.weight(1f).testTag("statistics_expenses"))
            SummaryTile(stringResource(R.string.entrate), money(totals.income), c.accent, Modifier.weight(1f))
            SummaryTile(stringResource(R.string.netto), money(totals.income - totals.expenses), c.heroAccent, Modifier.weight(1f), hero = true)
        }
        // Andamento
        Column(
            Modifier.padding(horizontal = 16.dp).padding(top = 10.dp).fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(c.surface).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                Text(stringResource(R.string.andamento), style = Typo.rowName, color = c.ink, modifier = Modifier.weight(1f))
                Row(Modifier.clip(RoundedCornerShape(10.dp)).background(c.divider).padding(3.dp), horizontalArrangement = Arrangement.spacedBy(3.dp)) {
                    listOf(6, 12).forEach { n ->
                        val on = range == n
                        Box(
                            Modifier.widthIn(min = 44.dp).heightIn(min = 44.dp).clip(RoundedCornerShape(8.dp)).background(if (on) c.surface else c.divider)
                                .clickable(role = Role.Button) { range = n }.semantics { selected = on }.testTag("statistics_range_$n"),
                            contentAlignment = Alignment.Center,
                        ) { Text("${n}M", style = Typo.caption, color = if (on) c.ink else c.smoke) }
                    }
                }
            }
            Row(horizontalArrangement = Arrangement.spacedBy(14.dp)) {
                Legend(c.ink, stringResource(R.string.uscite)); Legend(c.heroAccent, stringResource(R.string.entrate))
            }
            if (trend.all { it.expenses.signum() == 0 && it.income.signum() == 0 }) {
                Text(stringResource(R.string.nessun_dato_disponibile), style = Typo.secondary, color = c.smoke)
            } else {
                val resources = LocalContext.current.resources
                val summary = trend.joinToString(". ") {
                    resources.getString(R.string.statistiche_riepilogo_mese, Fmt.shortMonth(it.month, locale), money(it.income), money(it.expenses))
                }
                TrendChart(trend, range == 12, summary)
            }
        }
        // Per categoria
        Column(
            Modifier.padding(horizontal = 16.dp).padding(top = 10.dp).fillMaxWidth().clip(RoundedCornerShape(22.dp)).background(c.surface).padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(6.dp),
        ) {
            Text(stringResource(R.string.per_categoria), style = Typo.rowName, color = c.ink, modifier = Modifier.padding(bottom = 4.dp).testTag("statistics_categories_title"))
            if (categories.isEmpty()) Text(stringResource(R.string.nessuna_uscita_questo_mese), style = Typo.secondary, color = c.smoke)
            val top = categories.firstOrNull()?.amount ?: BigDecimal.ZERO
            categories.forEach { cat ->
                androidx.compose.runtime.key(cat.name) {
                    Column(Modifier.padding(vertical = 5.dp), verticalArrangement = Arrangement.spacedBy(5.dp)) {
                        Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                            Text(categoryLabel(cat.name), style = Typo.secondary, color = c.ink, modifier = Modifier.weight(1f))
                            Text("${Statistics.percentOfTotal(cat.amount, totals.expenses)}%", style = Typo.caption, color = c.smoke)
                            Text(money(cat.amount), style = Typo.rowAmount, color = c.ink, maxLines = 1, softWrap = false)
                        }
                        val tint = CategoryTint.tint(cat.name).colors(c.isDark).foreground
                        val share = if (top.signum() > 0) (cat.amount.toDouble() / top.toDouble()).toFloat().coerceIn(0f, 1f) else 0f
                        Box(Modifier.fillMaxWidth().height(6.dp).clip(CircleShape).background(c.divider)) {
                            Box(Modifier.fillMaxWidth(share).height(6.dp).clip(CircleShape).background(tint))
                        }
                    }
                }
            }
        }
        Row(
            Modifier.padding(horizontal = 16.dp).padding(top = 12.dp).fillMaxWidth().heightIn(min = 44.dp)
                .clip(RoundedCornerShape(18.dp)).background(c.surface).border(1.dp, c.fog, RoundedCornerShape(18.dp))
                .clickable(role = Role.Button) { showHabits = true }.padding(horizontal = 16.dp, vertical = 14.dp).testTag("btn_openHabits"),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            Icon(SfIcons.forName("arrow.triangle.2.circlepath"), null, tint = c.ink, modifier = Modifier.size(18.dp))
            Text(stringResource(R.string.abitudini), style = Typo.rowName, color = c.ink, modifier = Modifier.weight(1f))
            Icon(SfIcons.forName("chevron.right"), null, tint = c.smoke, modifier = Modifier.size(14.dp))
        }
    }
}

@Composable
private fun SummaryTile(label: String, value: String, color: androidx.compose.ui.graphics.Color, modifier: Modifier, hero: Boolean = false) {
    val c = Bt.colors
    Column(
        modifier.clip(RoundedCornerShape(16.dp)).background(if (hero) c.hero else c.surface).padding(12.dp),
        verticalArrangement = Arrangement.spacedBy(4.dp),
    ) {
        Text(label, style = Typo.caption, color = if (hero) c.heroSecondary else c.smoke, maxLines = 1)
        FitText(value, Typo.rowAmount, color, minScale = 0.65f)
    }
}

@Composable
private fun Legend(color: androidx.compose.ui.graphics.Color, label: String) {
    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(Dim.xs.dp)) {
        Box(Modifier.size(12.dp, 8.dp).clip(RoundedCornerShape(2.dp)).background(color))
        Text(label, style = Typo.caption, color = Bt.colors.smoke)
    }
}

/** Barre affiancate per mese (uscite `ink`, entrate `heroAccent`), altezza 130, asse Y nascosto, mese selezionato in grassetto. */
@Composable
private fun TrendChart(trend: List<Statistics.MonthStat>, short: Boolean, summary: String) {
    val c = Bt.colors
    val locale = java.util.Locale.getDefault()
    val max = trend.maxOf { maxOf(it.expenses, it.income) }.toDouble().coerceAtLeast(1.0) * 1.08
    Column(Modifier.fillMaxWidth().semantics(mergeDescendants = false) { }.clearAndSetSemantics { contentDescription = summary }) {
        Canvas(Modifier.fillMaxWidth().height(108.dp)) {
            val slot = size.width / trend.size
            val barW = slot * 0.65f / 2
            val radius = CornerRadius(4.dp.toPx())
            trend.forEachIndexed { i, s ->
                val left = i * slot + (slot - barW * 2) / 2
                listOf(s.expenses to c.ink, s.income to c.heroAccent).forEachIndexed { k, (v, color) ->
                    val h = (v.toDouble() / max * size.height).toFloat()
                    if (h > 0f) drawRoundRect(color, Offset(left + k * barW, size.height - h), Size(barW, h), radius)
                }
            }
        }
        Row(Modifier.fillMaxWidth().padding(top = 6.dp)) {
            trend.forEachIndexed { i, s ->
                val label = Fmt.shortMonth(s.month, locale).let { if (short) it.take(1) else it }
                Text(
                    label, style = if (i == trend.lastIndex) Typo.tabLabel.copy(fontWeight = FontWeight.Bold) else Typo.tabLabel, color = c.smoke,
                    maxLines = 1, softWrap = false, textAlign = androidx.compose.ui.text.style.TextAlign.Center, modifier = Modifier.weight(1f),
                )
            }
        }
    }
}
