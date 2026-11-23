package com.bucktrail.android.ui.screens

import androidx.compose.foundation.ExperimentalFoundationApi
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.combinedClickable
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
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.pluralStringResource
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.withStyle
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Budgeting
import com.bucktrail.android.ui.AppData
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.BudgetStatus
import com.bucktrail.android.ui.components.EmptyState
import com.bucktrail.android.ui.components.FitText
import com.bucktrail.android.ui.components.HeroCard
import com.bucktrail.android.ui.components.MonthBar
import com.bucktrail.android.ui.components.ProgressBar
import com.bucktrail.android.ui.components.SegmentedPill
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.PlainIconButton
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.components.budgetColor
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal
import java.time.Duration
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.Locale

class PlanActions(
    val onSettings: () -> Unit, val onAddBudget: () -> Unit, val onAddGoal: () -> Unit, val onEditGoal: (GoalEntity) -> Unit,
    val onDeleteBudget: (BudgetEntity) -> Unit, val onDeleteGoal: (GoalEntity) -> Unit,
)

private fun BudgetEntity.names(): List<String> = Budgeting.categorySet(category).sorted()

@Composable
private fun budgetName(b: BudgetEntity, accounts: List<AccountEntity>, separator: String = ", "): String {
    val names = b.names()
    return if (names.isEmpty()) (accounts.firstOrNull { it.id == b.accountId }?.name ?: stringResource(R.string.tutti))
    else { val res = LocalContext.current.resources; names.joinToString(separator) { categoryLabel(it, res) } }
}

/** Pianifica (§4.6): segmented Budget/Obiettivi, hero scura e card. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun PlanScreen(
    data: AppData, today: LocalDate, zone: ZoneId, segment: Int, onSegment: (Int) -> Unit, monthOffset: Int, onMonthOffset: (Int) -> Unit,
    actions: PlanActions, onHistory: () -> Unit,
) {
    val c = Bt.colors
    val ledger = data.ledger
    val currency = data.prefs.currencyCode
    val locale = Locale.getDefault()
    val month = YearMonth.from(today).plusMonths(monthOffset.toLong())

    Column(Modifier.verticalScroll(rememberScrollState()).padding(bottom = (Dim.listBottomPadding + Dim.tabBarReserved).dp)) {
        Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 20.dp).padding(top = 8.dp), verticalAlignment = Alignment.CenterVertically) {
            Text(stringResource(R.string.pianifica), style = Typo.screenTitle, color = c.ink, modifier = Modifier.weight(1f))
            if (segment == 0) PlainIconButton("clock.arrow.circlepath", stringResource(R.string.storico_budget), onHistory, Modifier.testTag("btn_budgetHistory"))
            PlainIconButton("gearshape", stringResource(R.string.impostazioni), actions.onSettings, Modifier.testTag("btn_openSettings"))
        }
        SegmentedPill(
            listOf(stringResource(R.string.budget), stringResource(R.string.obiettivi)), segment, onSegment,
            Modifier.padding(horizontal = 16.dp).padding(top = 8.dp), tags = listOf("planning_budget", "planning_goals"),
        )
        if (segment == 0) BudgetContent(data, month, today, zone, currency, locale, onMonthOffset, monthOffset, actions)
        else GoalsContent(ledger.goals, currency, today, actions)
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun BudgetContent(
    data: AppData, month: YearMonth, today: LocalDate, zone: ZoneId, currency: String, locale: Locale,
    onMonthOffset: (Int) -> Unit, monthOffset: Int, actions: PlanActions,
) {
    val c = Bt.colors
    val ledger = data.ledger
    val budgets = remember(ledger.budgets, month) { ledger.budgets.filter { it.month == month.monthValue && it.year == month.year } }
    val spentMap = remember(budgets, ledger.transactions, month, zone) {
        val txs = ledger.transactionData
        budgets.associate { it.id to Budgeting.spent(it.toData(), month, txs, zone) }
    }
    val total = budgets.fold(BigDecimal.ZERO) { a, b -> a + Amounts.fromCents(b.monthlyLimitCents) }
    val used = spentMap.values.fold(BigDecimal.ZERO) { a, v -> a + v }
    val pct = if (total.signum() > 0) minOf(used.divide(total, java.math.MathContext.DECIMAL64).toDouble(), 1.0) else 0.0
    val end = month.plusMonths(1).atDay(1).atStartOfDay(zone).toInstant()
    val days = Duration.between(Instant.now(), end).toDays().coerceAtLeast(0).toInt()

    MonthBar(
        Fmt.monthYear(month, locale), { onMonthOffset(monthOffset - 1) }, { onMonthOffset(monthOffset + 1) },
        stringResource(R.string.mese_precedente), stringResource(R.string.mese_successivo), Modifier.padding(horizontal = 20.dp).padding(top = 8.dp),
    )
    HeroCard(Modifier.padding(horizontal = 16.dp).padding(top = 4.dp), radius = 24.dp, padding = 18.dp) {
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                Text(stringResource(R.string.budget_usato), style = Typo.secondary, color = c.heroSecondary)
                Text("${Math.round(pct * 100)}%", style = Typo.screenTitle, color = c.heroPlanned)
            }
            FitText(Fmt.currency(used, currency) + " / " + Fmt.currency(total, currency), Typo.rowAmount, c.heroText)
            ProgressBar(pct.toFloat(), budgetColor(pct), onHero = true)
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                Text(pluralStringResource(R.plurals.plurale_mancano_lld_giorni, days, days), style = Typo.caption, color = c.heroSecondary, modifier = Modifier.weight(1f))
                Text(stringResource(R.string.avviso_all80), style = Typo.caption, color = c.heroSecondary)
            }
        }
    }
    if (budgets.isEmpty()) EmptyState(
        SfIcons.forName("chart.bar"), stringResource(R.string.nessun_budget), stringResource(R.string.imposta_un_limite_mensile_per_categoria),
        stringResource(R.string.aggiungi_budget_c8fecf), actions.onAddBudget, Modifier.padding(top = 24.dp),
    ) else Column(Modifier.padding(horizontal = 16.dp).padding(top = 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        budgets.forEach { b -> androidx.compose.runtime.key(b.id) { BudgetCard(b, spentMap[b.id] ?: BigDecimal.ZERO, ledger.accounts, currency, actions.onDeleteBudget) } }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun BudgetCard(b: BudgetEntity, spent: BigDecimal, accounts: List<AccountEntity>, currency: String, onDelete: (BudgetEntity) -> Unit) {
    val c = Bt.colors
    val limit = Amounts.fromCents(b.monthlyLimitCents)
    val progress = Budgeting.progress(spent, limit)
    val remaining = limit - spent
    val over = spent > limit
    val names = b.names()
    val name = budgetName(b, accounts)
    val kind = stringResource(if (names.isEmpty()) R.string.conto else if (names.size > 1) R.string.multi_categoria else R.string.categoria)
    val accountName = accounts.firstOrNull { it.id == b.accountId }?.name
    var menu by remember { mutableStateOf(false) }
    Box {
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(c.surface)
                .combinedClickable(onClick = {}, onLongClick = { menu = true }, onLongClickLabel = stringResource(R.string.elimina))
                .padding(horizontal = 16.dp, vertical = 14.dp).testTag("budgetRow_${b.id}"),
            verticalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.Top) {
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(name, style = Typo.rowAmount, color = c.ink)
                    Text("$kind · ${stringResource(R.string.mensile)}", style = Typo.caption, color = c.smoke)
                    if (names.isNotEmpty() && accountName != null) Text(accountName, style = Typo.caption, color = c.smoke)
                }
                BudgetStatus(progress, stringResource(R.string.sforato), stringResource(R.string.soglia_80))
            }
            ProgressBar(progress.toFloat(), budgetColor(progress))
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(
                    androidx.compose.ui.text.buildAnnotatedString {
                        withStyle(androidx.compose.ui.text.SpanStyle(color = c.ink)) { append(Fmt.currency(spent, currency)) }
                        withStyle(androidx.compose.ui.text.SpanStyle(color = c.smoke)) { append(" / " + Fmt.currency(limit, currency)) }
                    },
                    style = Typo.secondary.copy(fontFeatureSettings = "tnum"), maxLines = 1, softWrap = false,
                )
                Spacer(Modifier.size(8.dp))
                Text(
                    if (over) stringResource(R.string.sforato_di) + " " + Fmt.currency(remaining.abs(), currency) else Fmt.currency(remaining, currency) + " " + stringResource(R.string.rimasti),
                    style = Typo.caption, color = if (over) c.danger else c.smoke, maxLines = 2,
                )
            }
        }
        DropdownMenu(menu, { menu = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.elimina), color = c.danger) }, modifier = Modifier.testTag("btn_deleteBudget"),
                leadingIcon = { Icon(SfIcons.forName("trash"), null, tint = c.danger, modifier = Modifier.size(18.dp)) }, onClick = { menu = false; onDelete(b) },
            )
        }
    }
}

@Composable
private fun GoalsContent(goals: List<GoalEntity>, currency: String, today: LocalDate, actions: PlanActions) {
    val c = Bt.colors
    val data = goals.map { it.toData() }
    val overall = Budgeting.overallGoalProgress(data)
    val current = goals.fold(BigDecimal.ZERO) { a, g -> a + Amounts.fromCents(g.currentCents) }
    val target = goals.fold(BigDecimal.ZERO) { a, g -> a + Amounts.fromCents(g.targetCents) }
    HeroCard(Modifier.padding(horizontal = 16.dp).padding(top = 12.dp), radius = 24.dp, padding = 18.dp) {
        Row(horizontalArrangement = Arrangement.spacedBy(18.dp), verticalAlignment = Alignment.CenterVertically, modifier = Modifier.fillMaxWidth()) {
            ProgressRing(overall)
            Column(verticalArrangement = Arrangement.spacedBy(4.dp), modifier = Modifier.weight(1f)) {
                Text(stringResource(R.string.progresso_complessivo), style = Typo.secondary, color = c.heroSecondary)
                Text("${Math.round(overall * 100)}%", style = Typo.screenTitle, color = c.heroAccent)
                FitText(Fmt.currency(current, currency) + " / " + Fmt.currency(target, currency), Typo.secondary.copy(fontFeatureSettings = "tnum"), c.heroText)
            }
        }
    }
    if (goals.isEmpty()) EmptyState(
        SfIcons.forName("target"), stringResource(R.string.nessun_obiettivo), stringResource(R.string.imposta_un_obiettivo_di_risparmio_e_tien),
        stringResource(R.string.aggiungi_obiettivo_f27d65), actions.onAddGoal, Modifier.padding(top = 24.dp),
    ) else Column(Modifier.padding(horizontal = 16.dp).padding(top = 10.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        goals.forEach { g -> androidx.compose.runtime.key(g.id) { GoalCard(g, currency, today, actions) } }
    }
}

@Composable
private fun ProgressRing(progress: Double) {
    val c = Bt.colors
    Canvas(Modifier.padding(5.dp).size(74.dp)) {
        val w = 10.dp.toPx()
        val inset = w / 2
        val s = Size(size.width - w, size.height - w)
        drawArc(c.heroDivider, 0f, 360f, false, Offset(inset, inset), s, style = Stroke(w))
        drawArc(c.heroAccent, -90f, (360 * progress).toFloat(), false, Offset(inset, inset), s, style = Stroke(w, cap = StrokeCap.Round))
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
fun GoalCard(g: GoalEntity, currency: String, today: LocalDate, actions: PlanActions) {
    val c = Bt.colors
    val res = LocalContext.current.resources
    val zone = ZoneId.systemDefault()
    val progress = Budgeting.goalProgress(g.toData())
    var menu by remember { mutableStateOf(false) }
    val deadline = g.deadline?.let { Instant.ofEpochMilli(it).atZone(zone).toLocalDate() }
    val plusDescription = stringResource(R.string.aggiungi_progresso)
    Box {
        Column(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(c.surface)
                .combinedClickable(onClick = { actions.onEditGoal(g) }, onLongClick = { menu = true })
                .padding(horizontal = 16.dp, vertical = 14.dp).testTag("goalRow_${g.id}"),
            verticalArrangement = Arrangement.spacedBy(10.dp),
        ) {
            Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
                Box(Modifier.size(42.dp).clip(RoundedCornerShape(14.dp)).background(c.accentSoft), contentAlignment = Alignment.Center) {
                    if (g.emoji.isNotEmpty() && g.emoji.any { it.code >= 128 }) Text(g.emoji, style = Typo.rowName)
                    else Icon(SfIcons.forName(g.emoji.ifEmpty { "target" }), null, tint = c.accent, modifier = Modifier.size(20.dp))
                }
                Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(g.name, style = Typo.rowAmount, color = c.ink)
                    Text(
                        if (deadline != null) stringResource(R.string.entro) + " " + Fmt.dayMonth(deadline, LocalDate.MAX, res) else stringResource(R.string.nessuna_scadenza),
                        style = Typo.caption, color = c.smoke,
                    )
                }
                Box(
                    Modifier.size(44.dp).clip(RoundedCornerShape(14.dp)).background(c.surface).border(1.dp, c.fog, RoundedCornerShape(14.dp))
                        .clickable(role = Role.Button) { actions.onEditGoal(g) }.semantics { contentDescription = plusDescription }.testTag("goal_add_${g.id}"),
                    contentAlignment = Alignment.Center,
                ) { Icon(SfIcons.forName("plus"), null, tint = c.ink, modifier = Modifier.size(20.dp)) }
            }
            Box(Modifier.fillMaxWidth().height(8.dp).clip(CircleShape).background(c.divider)) {
                Box(Modifier.fillMaxWidth(progress.toFloat().coerceIn(0f, 1f)).height(8.dp).clip(CircleShape).background(c.accent))
            }
            Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween, verticalAlignment = Alignment.CenterVertically) {
                Text(
                    androidx.compose.ui.text.buildAnnotatedString {
                        withStyle(androidx.compose.ui.text.SpanStyle(color = c.ink)) { append(Fmt.currency(Amounts.fromCents(g.currentCents), currency)) }
                        withStyle(androidx.compose.ui.text.SpanStyle(color = c.smoke)) { append(" / " + Fmt.currency(Amounts.fromCents(g.targetCents), currency)) }
                    },
                    style = Typo.secondary.copy(fontFeatureSettings = "tnum"), maxLines = 1, softWrap = false,
                )
                Text("${Math.round(progress * 100)}%", style = Typo.rowAmount, color = c.accent)
            }
            if (g.isCompleted) Text(stringResource(R.string.obiettivo_raggiunto), style = Typo.caption, color = c.accent)
        }
        DropdownMenu(menu, { menu = false }) {
            DropdownMenuItem(text = { Text(stringResource(R.string.modifica)) }, modifier = Modifier.testTag("btn_editGoal"),
                leadingIcon = { Icon(SfIcons.forName("pencil"), null, modifier = Modifier.size(18.dp)) }, onClick = { menu = false; actions.onEditGoal(g) })
            DropdownMenuItem(text = { Text(stringResource(R.string.elimina), color = c.danger) }, modifier = Modifier.testTag("btn_deleteGoal"),
                leadingIcon = { Icon(SfIcons.forName("trash"), null, tint = c.danger, modifier = Modifier.size(18.dp)) }, onClick = { menu = false; actions.onDeleteGoal(g) })
        }
    }
}

/** Storico budget (ultimi 6 mesi, dal più vecchio): spesa/limite e percentuale per ogni budget. */
@Composable
fun BudgetHistorySheet(data: AppData, today: LocalDate, zone: ZoneId, onClose: () -> Unit) {
    val c = Bt.colors
    val ledger = data.ledger
    val currency = data.prefs.currencyCode
    val locale = Locale.getDefault()
    val months = remember(today) { (5 downTo 0).map { YearMonth.from(today).minusMonths(it.toLong()) } }
    val txs = remember(ledger.transactions) { ledger.transactionData }
    SheetPage(stringResource(R.string.storico_budget), onClose, trailing = { BarAction(stringResource(R.string.chiudi), onClose, Modifier.testTag("btn_closeHistory")) }) {
        months.forEach { m ->
            val list = ledger.budgets.filter { it.month == m.monthValue && it.year == m.year }
            Text(Fmt.monthYear(m, locale), style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.ink, modifier = Modifier.padding(start = 20.dp, end = 20.dp, top = 24.dp, bottom = 12.dp))
            if (list.isEmpty()) Text(stringResource(R.string.nessun_budget), style = Typo.secondary, color = c.smoke, modifier = Modifier.padding(horizontal = 20.dp).padding(bottom = 12.dp))
            list.forEach { b ->
                val spent = Budgeting.spent(b.toData(), m, txs, zone)
                val limit = Amounts.fromCents(b.monthlyLimitCents)
                val p = Budgeting.progress(spent, limit)
                val over = spent > limit
                Column(Modifier.padding(horizontal = 20.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
                    Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) {
                        Icon(SfIcons.forName(b.categoryIcon.ifEmpty { "circle.dotted" }), null, tint = c.smoke, modifier = Modifier.size(16.dp))
                        Text(budgetName(b, ledger.accounts, " + "), style = Typo.rowName.copy(fontWeight = FontWeight.Normal), color = c.ink, modifier = Modifier.weight(1f))
                        Text(Fmt.currency(spent, currency) + " / " + Fmt.currency(limit, currency), style = Typo.caption, color = c.smoke)
                        Text("${Math.round(p * 100)}%", style = Typo.caption.copy(fontWeight = FontWeight.SemiBold), color = if (over) c.danger else c.smoke, modifier = Modifier.width(36.dp), textAlign = androidx.compose.ui.text.style.TextAlign.End)
                    }
                    Box(Modifier.fillMaxWidth().height(2.dp).background(c.fog)) { Box(Modifier.fillMaxWidth(p.toFloat().coerceIn(0f, 1f)).height(2.dp).background(if (over) c.danger else c.smoke)) }
                }
                ThinDivider(Modifier.padding(start = 44.dp), c.fog)
            }
            ThinDivider(color = c.fog)
        }
        Spacer(Modifier.height(60.dp))
    }
}
