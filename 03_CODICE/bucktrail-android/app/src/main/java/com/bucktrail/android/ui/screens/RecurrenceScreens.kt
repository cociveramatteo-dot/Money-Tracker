package com.bucktrail.android.ui.screens

import android.app.DatePickerDialog
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.foundation.verticalScroll
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.data.RecurringOps
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.toSnapshot
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Occurrence
import com.bucktrail.android.domain.RecurrenceCalculator
import com.bucktrail.android.domain.RecurringSeries
import com.bucktrail.android.ui.AppViewModel
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.sortedForDisplay
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.BtAlert
import com.bucktrail.android.ui.components.CategoryIconBox
import com.bucktrail.android.ui.components.EmptyState
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SegmentedPill
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.components.UnderlineSegment
import com.bucktrail.android.ui.components.dashedBorder
import com.bucktrail.android.ui.forms.CategoryPickerSheet
import com.bucktrail.android.ui.forms.FieldLine
import com.bucktrail.android.ui.forms.FormSwitch
import com.bucktrail.android.ui.forms.DatePill
import com.bucktrail.android.ui.forms.OptionRow
import com.bucktrail.android.ui.forms.TextChip
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.domain.CategoryTint
import com.bucktrail.android.ui.theme.colors
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.Locale
import java.util.UUID

@Composable
private fun frequencyLabel(frequency: String): String = stringResource(
    when (frequency) { "mensile" -> R.string.mensile; "annuale" -> R.string.annuale; "settimanale" -> R.string.settimanale; else -> R.string.irregolare },
)

/** Avvio di una serie programmata: occorrenza di partenza per la scheda (prossima, o la prima se la serie è finita). */
private fun nextSelection(rule: RecurringRuleEntity, today: LocalDate, zone: ZoneId): RecurringOps.Selection? {
    val calc = RecurrenceCalculator(zone)
    val snap = rule.toSnapshot()
    val start = today.atStartOfDay(zone).toInstant()
    val end = calc.addMonths(maxOf(start, snap.startDate), 24)
    calc.occurrences(snap, start, end).firstOrNull()?.let { return RecurringOps.Selection(rule, it) }
    val base = snap.copy(exceptions = emptyMap(), endDate = null)
    return calc.occurrences(base, snap.startDate, snap.startDate.plusSeconds(86_400)).firstOrNull()?.let { RecurringOps.Selection(rule, it) }
}

/** Serie programmata (`ProgrammedRuleCard`): icona, nome, importo, cadenza, stato, «Prossima occorrenza» o «Modifica». */
@Composable
fun ProgrammedRuleCard(rule: RecurringRuleEntity, currency: String, today: LocalDate, zone: ZoneId, res: android.content.res.Resources, onSelect: (RecurringOps.Selection) -> Unit) {
    val c = Bt.colors
    val tint = CategoryTint.tint(rule.category).colors(c.isDark)
    val next = remember(rule, today, zone) { nextSelection(rule, today, zone) }
    val actual = remember(rule, today, zone) {
        val snap = rule.toSnapshot(); val calc = RecurrenceCalculator(zone)
        val start = today.atStartOfDay(zone).toInstant()
        calc.occurrences(snap, start, calc.addMonths(maxOf(start, snap.startDate), 24)).firstOrNull()
    }
    val ended = rule.endDate?.let { Instant.ofEpochMilli(it).atZone(zone).toLocalDate().isBefore(today) } == true
    Column(
        Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(c.surface).border(1.dp, c.fog, RoundedCornerShape(18.dp)).padding(16.dp).testTag("ruleCard_${rule.name}"),
        verticalArrangement = Arrangement.spacedBy(12.dp),
    ) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
            Box(Modifier.size(38.dp).clip(RoundedCornerShape(12.dp)).background(tint.background), contentAlignment = Alignment.Center) {
                Icon(SfIcons.forName(rule.categoryIcon.ifEmpty { "circle.dotted" }), null, tint = tint.foreground, modifier = Modifier.size(19.dp))
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(4.dp)) {
                Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.Top) {
                    Text(rule.name, style = Typo.rowName, color = c.ink, modifier = Modifier.weight(1f))
                    Text(Fmt.currency(Amounts.fromCents(rule.amountCents), currency), style = Typo.rowAmount, color = c.plannedText, maxLines = 1, softWrap = false)
                }
                Text(frequencyLabel(rule.frequency), style = Typo.caption, color = c.smoke)
                val end = rule.endDate?.let { Instant.ofEpochMilli(it).atZone(zone).toLocalDate() }
                if (end != null) {
                    Text(stringResource(if (ended) R.string.terminata else R.string.termina_il), style = Typo.caption, color = c.smoke)
                    Text(Fmt.dayMonth(end, LocalDate.MAX, res), style = Typo.caption, color = c.smoke)
                } else Text(stringResource(R.string.attiva), style = Typo.caption, color = c.smoke)
            }
        }
        Box(Modifier.fillMaxWidth().height(1.dp).background(c.divider))
        if (actual != null && next != null) {
            Row(
                Modifier.fillMaxWidth().heightIn(min = 44.dp).clickable(role = Role.Button) { onSelect(next) }.testTag("editRecurrence_${rule.name}"),
                verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
            ) {
                Text(
                    stringResource(R.string.prossima_occorrenza) + " · " + Fmt.dayMonth(actual.date.atZone(zone).toLocalDate(), LocalDate.MAX, res),
                    style = Typo.secondary, color = c.plannedText, modifier = Modifier.weight(1f),
                )
                Icon(SfIcons.forName("chevron.right"), null, tint = c.plannedText, modifier = Modifier.size(14.dp))
            }
        } else if (next != null) {
            Box(Modifier.fillMaxWidth().heightIn(min = 44.dp).clickable(role = Role.Button) { onSelect(next) }, contentAlignment = Alignment.CenterStart) {
                Text(stringResource(R.string.modifica), style = Typo.secondary, color = c.accent)
            }
        }
    }
}

/** Serie rilevata (`RecurringSeriesCard`): conteggio, totale, proiezioni. */
@Composable
fun RecurringSeriesCard(series: RecurringSeries, currency: String, zone: ZoneId, res: android.content.res.Resources, modifier: Modifier = Modifier) {
    val c = Bt.colors
    val tint = CategoryTint.tint(series.category).colors(c.isDark)
    val expense = series.type == Amounts.TYPE_EXPENSE
    fun m(v: BigDecimal) = Fmt.currency(v, currency)
    val total = stringResource(if (expense) R.string.speso_finora else R.string.ricevuto_finora) + ": " + m(series.totalAmount)
    val avg = series.average
    val detail = when {
        series.isVariableAmount -> stringResource(R.string.media) + ": " + m(avg) + " · " + stringResource(R.string.ultimo) + ": " + m(series.lastAmount)
        series.frequency == "settimanale" -> stringResource(R.string.settimana) + " " + m(avg) + " · " + stringResource(R.string.mese) + " ≈" + m(avg.multiply(BigDecimal("4.33"))) + " · " + stringResource(R.string.anno) + " " + m(avg.multiply(BigDecimal(52)))
        series.frequency == "mensile" -> stringResource(R.string.mese) + " " + m(avg) + " · " + stringResource(R.string.anno) + " " + m(avg.multiply(BigDecimal(12)))
        series.frequency == "annuale" -> stringResource(R.string.anno) + " " + m(avg)
        else -> ""
    }
    val first = series.occurrences.first().date.atZone(zone).toLocalDate()
    Column(modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(c.surface).border(1.dp, c.fog, RoundedCornerShape(18.dp)).padding(16.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Row(horizontalArrangement = Arrangement.spacedBy(12.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(38.dp).clip(RoundedCornerShape(12.dp)).background(tint.background), contentAlignment = Alignment.Center) {
                Icon(SfIcons.forName(series.categoryIcon.ifEmpty { "circle.dotted" }), null, tint = tint.foreground, modifier = Modifier.size(19.dp))
            }
            Column(Modifier.weight(1f), verticalArrangement = Arrangement.spacedBy(2.dp)) {
                Text(series.name, style = Typo.rowName, color = c.ink, maxLines = 2, overflow = TextOverflow.Ellipsis)
                Text("${series.count} ${stringResource(R.string.volte)} · ${stringResource(R.string.dal)} ${Fmt.dayMonth(first, LocalDate.MAX, res)}", style = Typo.caption, color = c.smoke)
            }
            Text(frequencyLabel(series.frequency), style = Typo.caption, color = c.smoke)
        }
        Text(total, style = Typo.rowAmount, color = if (expense) c.ink else c.positive)
        if (detail.isNotEmpty()) Text(detail, style = Typo.caption.copy(fontFeatureSettings = "tnum"), color = c.smoke)
    }
}

/** Storico di una serie rilevata: scheda riassuntiva + occorrenze (tap = modifica, swipe = elimina). */
@Composable
fun RecurringSeriesDetailSheet(
    series: RecurringSeries?, data: com.bucktrail.android.ui.AppData, today: LocalDate, zone: ZoneId, onEdit: (com.bucktrail.android.data.TransactionEntity) -> Unit,
    onDelete: (com.bucktrail.android.data.TransactionEntity) -> Unit, onClose: () -> Unit,
) {
    val c = Bt.colors
    val res = LocalContext.current.resources
    val ledger = data.ledger
    SheetPage(series?.name.orEmpty(), onClose, trailing = { BarAction(stringResource(R.string.fine), onClose, Modifier.testTag("btn_closeSeries")) }) {
        if (series == null) {
            EmptyState(SfIcons.forName("arrow.triangle.2.circlepath"), stringResource(R.string.serie_eliminata), stringResource(R.string.tutte_le_occorrenze_di_questo_pagamento))
        } else {
            RecurringSeriesCard(series, data.prefs.currencyCode, zone, res, Modifier.padding(horizontal = 16.dp, vertical = 12.dp))
            SectionLabel(stringResource(R.string.storico), Modifier.padding(horizontal = 20.dp, vertical = 4.dp))
            val rows = series.occurrences.mapNotNull { o -> ledger.transactions.firstOrNull { it.id == o.id } }.sortedForDisplay(zone)
            Column(Modifier.fillMaxWidth().background(c.surface)) {
                rows.forEachIndexed { i, t ->
                    androidx.compose.runtime.key(t.id) {
                        if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                        TransactionRow(t, ledger.accounts, data.prefs.currencyCode, false, today, zone, res, onEdit = onEdit, onDelete = onDelete, homeMeta = true)
                    }
                }
            }
        }
    }
}

/** Pagina «Ricorrenti» (§4.2): ricerca, categorie, serie programmate e serie rilevate. */
@Composable
fun RecurringPage(
    data: com.bucktrail.android.ui.AppData, today: LocalDate, zone: ZoneId, onSelectRule: (RecurringOps.Selection) -> Unit,
    onEditTransaction: (com.bucktrail.android.data.TransactionEntity) -> Unit, onDeleteTransaction: (com.bucktrail.android.data.TransactionEntity) -> Unit, onBack: () -> Unit,
) {
    val c = Bt.colors
    val res = LocalContext.current.resources
    val ledger = data.ledger
    val currency = data.prefs.currencyCode
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("") }
    var selectedSeries by remember { mutableStateOf<String?>(null) }
    val detected = remember(ledger.transactions, zone) { com.bucktrail.android.domain.RecurringSeriesDetector.detect(ledger.transactionData, zone) }
    val series = detected.filter { (query.isEmpty() || it.name.contains(query, ignoreCase = true)) && (category.isEmpty() || it.category == category) }
    val rules = ledger.rules.filter { (category.isEmpty() || it.category == category) && (query.isEmpty() || it.name.contains(query, ignoreCase = true)) }

    androidx.activity.compose.BackHandler(onBack = onBack)
    Column(Modifier.fillMaxWidth().background(c.paper)) {
        Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 16.dp).heightIn(min = 52.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(48.dp).clickable(role = Role.Button, onClick = onBack).testTag("btn_backRecurring"), contentAlignment = Alignment.Center) {
                Box(Modifier.size(44.dp).clip(androidx.compose.foundation.shape.CircleShape).background(c.surface).border(1.dp, c.fog, androidx.compose.foundation.shape.CircleShape), contentAlignment = Alignment.Center) {
                    Icon(SfIcons.forName("chevron.left"), stringResource(R.string.movimenti), tint = c.ink, modifier = Modifier.size(24.dp))
                }
            }
            Text(stringResource(R.string.ricorrenti), style = Typo.rowName.copy(fontWeight = FontWeight.SemiBold), color = c.ink, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            Box(Modifier.size(44.dp))
        }
        Row(
            Modifier.padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 4.dp).fillMaxWidth().heightIn(min = 46.dp).clip(RoundedCornerShape(16.dp)).background(c.surface)
                .border(1.dp, c.fog, RoundedCornerShape(16.dp)).padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(SfIcons.forName("magnifyingglass"), null, tint = c.smoke, modifier = Modifier.size(18.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) Text(stringResource(R.string.cerca_per_nome), style = Typo.secondary.copy(fontSize = androidx.compose.ui.unit.TextUnit(15f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke)
                BasicTextField(query, { query = it }, singleLine = true, textStyle = Typo.rowName.copy(color = c.ink, fontWeight = FontWeight.Normal),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_sectionSearch"))
            }
        }
        if (ledger.categories.isNotEmpty()) Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            com.bucktrail.android.ui.components.FilterChip(stringResource(R.string.tutte_le_categorie), category.isEmpty(), { category = "" }, secondary = true)
            ledger.categories.forEach { cat ->
                com.bucktrail.android.ui.components.FilterChip(categoryLabel(cat.name), category == cat.name, { category = if (category == cat.name) "" else cat.name }, secondary = true)
            }
        }
        if (detected.isEmpty() && ledger.rules.isEmpty()) {
            EmptyState(SfIcons.forName("arrow.triangle.2.circlepath"), stringResource(R.string.nessuna_serie_ricorrente), stringResource(R.string.i_pagamenti_che_si_ripetono_per_almeno_2))
        } else Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 12.dp, bottom = 120.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            Box(Modifier.fillMaxWidth(), contentAlignment = Alignment.Center) { SectionLabel(stringResource(R.string.serie_programmate)) }
            rules.forEach { r -> androidx.compose.runtime.key(r.id) { ProgrammedRuleCard(r, currency, today, zone, res, onSelectRule) } }
            series.forEach { s -> androidx.compose.runtime.key(s.id) { RecurringSeriesCard(s, currency, zone, res, Modifier.clickable { selectedSeries = s.id }.testTag("seriesCard_${s.name}")) } }
        }
    }
    selectedSeries?.let { id ->
        RecurringSeriesDetailSheet(detected.firstOrNull { it.id == id }, data, today, zone, onEditTransaction, onDeleteTransaction) { selectedSeries = null }
    }
}

/** Pagina «Abitudini» (da Statistiche): serie rilevate con almeno 3 occorrenze in 3 mesi diversi. */
@Composable
fun HabitsPage(
    data: com.bucktrail.android.ui.AppData,
    today: LocalDate,
    zone: ZoneId,
    onEditTransaction: (com.bucktrail.android.data.TransactionEntity) -> Unit,
    onDeleteTransaction: (com.bucktrail.android.data.TransactionEntity) -> Unit,
    onBack: () -> Unit,
) {
    val c = Bt.colors
    val res = LocalContext.current.resources
    val ledger = data.ledger
    val currency = data.prefs.currencyCode
    var query by remember { mutableStateOf("") }
    var category by remember { mutableStateOf("") }
    var selectedSeries by remember { mutableStateOf<String?>(null) }
    val detected = remember(ledger.transactions, zone) {
        com.bucktrail.android.domain.RecurringSeriesDetector.detect(ledger.transactionData, zone)
    }
    val trimmed = query.trim()
    val series = detected.filter {
        (trimmed.isEmpty() || it.name.contains(trimmed, ignoreCase = true)) &&
            (category.isEmpty() || it.category == category)
    }

    androidx.activity.compose.BackHandler(onBack = onBack)
    Column(Modifier.fillMaxWidth().background(c.paper)) {
        Row(Modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 16.dp).heightIn(min = 52.dp), verticalAlignment = Alignment.CenterVertically) {
            Box(Modifier.size(48.dp).clickable(role = Role.Button, onClick = onBack).testTag("btn_backHabits"), contentAlignment = Alignment.Center) {
                Box(Modifier.size(44.dp).clip(androidx.compose.foundation.shape.CircleShape).background(c.surface).border(1.dp, c.fog, androidx.compose.foundation.shape.CircleShape), contentAlignment = Alignment.Center) {
                    Icon(SfIcons.forName("chevron.left"), stringResource(R.string.statistiche), tint = c.ink, modifier = Modifier.size(24.dp))
                }
            }
            Text(stringResource(R.string.abitudini), style = Typo.rowName.copy(fontWeight = FontWeight.SemiBold), color = c.ink, modifier = Modifier.weight(1f), textAlign = androidx.compose.ui.text.style.TextAlign.Center)
            Box(Modifier.size(44.dp))
        }
        Row(
            Modifier.padding(horizontal = 20.dp).padding(top = 8.dp, bottom = 4.dp).fillMaxWidth().heightIn(min = 46.dp).clip(RoundedCornerShape(16.dp)).background(c.surface)
                .border(1.dp, c.fog, RoundedCornerShape(16.dp)).padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(SfIcons.forName("magnifyingglass"), null, tint = c.smoke, modifier = Modifier.size(18.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) Text(stringResource(R.string.cerca_per_nome), style = Typo.secondary.copy(fontSize = androidx.compose.ui.unit.TextUnit(15f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke)
                BasicTextField(
                    query, { query = it }, singleLine = true,
                    textStyle = Typo.rowName.copy(color = c.ink, fontWeight = FontWeight.Normal),
                    cursorBrush = SolidColor(c.accent),
                    modifier = Modifier.fillMaxWidth().testTag("tf_habitsSearch"),
                )
            }
        }
        if (ledger.categories.isNotEmpty()) Row(Modifier.horizontalScroll(rememberScrollState()).padding(horizontal = 20.dp, vertical = 8.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            com.bucktrail.android.ui.components.FilterChip(stringResource(R.string.tutte_le_categorie), category.isEmpty(), { category = "" }, secondary = true)
            ledger.categories.forEach { cat ->
                com.bucktrail.android.ui.components.FilterChip(categoryLabel(cat.name), category == cat.name, { category = if (category == cat.name) "" else cat.name }, secondary = true)
            }
        }
        if (detected.isEmpty()) {
            EmptyState(SfIcons.forName("arrow.triangle.2.circlepath"), stringResource(R.string.nessuna_abitudine), stringResource(R.string.abitudini_vuoto))
        } else if (series.isEmpty()) {
            EmptyState(SfIcons.forName("magnifyingglass"), stringResource(R.string.nessun_risultato), stringResource(R.string.nessun_movimento_corrisponde_alla_ricerc))
        } else Column(Modifier.weight(1f, fill = false).verticalScroll(rememberScrollState()).padding(horizontal = 20.dp).padding(top = 12.dp, bottom = 120.dp), verticalArrangement = Arrangement.spacedBy(12.dp)) {
            series.forEach { s ->
                androidx.compose.runtime.key(s.id) {
                    RecurringSeriesCard(s, currency, zone, res, Modifier.clickable { selectedSeries = s.id }.testTag("habitCard_${s.name}"))
                }
            }
        }
    }
    selectedSeries?.let { id ->
        RecurringSeriesDetailSheet(detected.firstOrNull { it.id == id }, data, today, zone, onEditTransaction, onDeleteTransaction) { selectedSeries = null }
    }
}

/** Editor di una serie (`RecurrenceEditorView`): ambito, campi, «Salta mese», «Termina…», «Elimina». */
@Composable
fun RecurrenceEditorSheet(
    selection: RecurringOps.Selection, accounts: List<AccountEntity>, categories: List<CategoryEntity>, zone: ZoneId,
    apply: suspend (RecurringOps.Action) -> AppViewModel.RecurrenceResult, onClose: () -> Unit,
) {
    val c = Bt.colors
    val ctx = LocalContext.current
    val scope = rememberCoroutineScope()
    val rule = selection.rule
    val occ = selection.occurrence
    val calc = remember(zone) { RecurrenceCalculator(zone) }
    fun day(i: Instant) = i.atZone(zone).toLocalDate()
    val ruleSnap = remember(rule) { rule.toSnapshot() }

    var scopeIndex by remember { mutableStateOf(0) }
    var name by remember { mutableStateOf(occ.name) }
    var amount by remember { mutableStateOf(Amounts.editableString(occ.amount)) }
    var notes by remember { mutableStateOf(occ.notes) }
    var date by remember { mutableStateOf(day(occ.date)) }
    var frequency by remember { mutableStateOf(rule.frequency) }
    var income by remember { mutableStateOf(occ.type == Amounts.TYPE_INCOME) }
    var category by remember { mutableStateOf(occ.category) }
    var accountId by remember { mutableStateOf(occ.accountId?.toString()) }
    var fixed by remember { mutableStateOf(occ.isFixed) }
    var confirmDelete by remember { mutableStateOf(false) }
    var error by remember { mutableStateOf<String?>(null) }
    var busy by remember { mutableStateOf(false) }
    var categoryPicker by remember { mutableStateOf(false) }
    var scopeMenu by remember { mutableStateOf(false) }
    var freqMenu by remember { mutableStateOf(false) }

    fun load(i: Int) {
        scopeIndex = i
        name = if (i == 0) occ.name else rule.name
        amount = Amounts.editableString(if (i == 0) occ.amount else Amounts.fromCents(rule.amountCents))
        notes = if (i == 0) occ.notes else rule.notes
        date = day(if (i == 0) occ.date else if (i == 1) occ.originalDate else ruleSnap.startDate)
        frequency = rule.frequency
        income = (if (i == 0) occ.type else rule.type) == Amounts.TYPE_INCOME
        category = if (i == 0) occ.category else rule.category
        accountId = (if (i == 0) occ.accountId else ruleSnap.accountId)?.toString()
        fixed = if (i == 0) occ.isFixed else rule.isFixed
    }
    val editorScope = when (scopeIndex) { 0 -> RecurringOps.Scope.OnlyThis; 1 -> RecurringOps.Scope.Following; else -> RecurringOps.Scope.All }
    val parsed = Amounts.parse(amount)
    val valid = name.trim().isNotEmpty() && Amounts.isValidInput(parsed)
    val scopeLabels = listOf(stringResource(R.string.solo_questa), stringResource(R.string.questa_e_le_successive), stringResource(R.string.tutte))

    fun errorText(p: AppViewModel.RecurrenceResult.Error): String = ctx.getString(
        when (p.problem) {
            RecurringOps.Problem.InvalidValues -> R.string.i_valori_della_ricorrenza_non_sono_valid
            RecurringOps.Problem.CrossMonthOverride -> R.string.la_data_deve_restare_nello_stesso_mese
            RecurringOps.Problem.InvalidOccurrence -> R.string.loccorrenza_non_appartiene_alla_serie
            null -> R.string.impossibile_aggiornare_le_ricorrenze_rip
        },
    )
    fun run(action: RecurringOps.Action) {
        if (busy) return
        busy = true
        scope.launch {
            val r = apply(action)
            busy = false
            when (r) { AppViewModel.RecurrenceResult.Ok -> onClose(); is AppViewModel.RecurrenceResult.Error -> error = errorText(r) }
        }
    }
    fun save() {
        val value = parsed ?: return
        val values = ruleSnap.copy(
            name = name.trim(), amount = value, notes = notes.trim(), startDate = date.atTime(12, 0).atZone(zone).toInstant(), frequency = frequency,
            type = if (income) Amounts.TYPE_INCOME else Amounts.TYPE_EXPENSE, category = category,
            categoryIcon = categories.firstOrNull { it.name == category }?.icon ?: ruleSnap.categoryIcon,
            accountId = accountId?.let { runCatching { UUID.fromString(it) }.getOrNull() }, isFixed = fixed,
        )
        run(RecurringOps.Action.Edit(editorScope, values))
    }

    SheetPage(
        stringResource(R.string.ricorrenza), onClose,
        leading = { BarAction(stringResource(R.string.annulla), onClose, Modifier.testTag("btn_cancelRecurrence")) },
        trailing = { BarAction(stringResource(R.string.salva), { save() }, Modifier.testTag("btn_saveRecurrence"), bold = true, enabled = valid && !busy) },
    ) {
        Column(Modifier.padding(horizontal = 20.dp, vertical = 12.dp), verticalArrangement = Arrangement.spacedBy(20.dp)) {
            Box {
                OptionRow(stringResource(R.string.ambito), modifier = Modifier.clickable(role = Role.Button) { scopeMenu = true }.testTag("recurrence_scope")) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(scopeLabels[scopeIndex], style = Typo.formOption, color = c.ink)
                        Icon(SfIcons.forName("chevron.down"), null, tint = c.smoke, modifier = Modifier.size(12.dp))
                    }
                }
                DropdownMenu(scopeMenu, { scopeMenu = false }) {
                    scopeLabels.forEachIndexed { i, l -> DropdownMenuItem(text = { Text(l + if (i == scopeIndex) "  ✓" else "") }, onClick = { scopeMenu = false; load(i) }) }
                }
            }
            LabeledField(stringResource(R.string.descrizione), name, { name = it.take(80) }, Modifier.testTag("recurrence_name"))
            LabeledField(stringResource(R.string.importo), amount, { amount = it.take(14) }, Modifier.testTag("recurrence_amount"), KeyboardType.Decimal)
            LabeledField(stringResource(R.string.note), notes, { notes = it.take(500) }, Modifier.testTag("recurrence_notes"))
            Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
                OptionRow(stringResource(R.string.data), titleColor = c.smoke, modifier = Modifier.clickable(enabled = scopeIndex != 1, role = Role.Button) {
                    val dialog = DatePickerDialog(ctx, { _, y, m, d -> date = LocalDate.of(y, m + 1, d) }, date.year, date.monthValue - 1, date.dayOfMonth)
                    if (scopeIndex == 0) {
                        val ym = YearMonth.from(day(occ.originalDate))
                        dialog.datePicker.minDate = ym.atDay(1).atStartOfDay(zone).toInstant().toEpochMilli()
                        dialog.datePicker.maxDate = ym.atEndOfMonth().atTime(23, 59).atZone(zone).toInstant().toEpochMilli()
                    }
                    dialog.show()
                }) { Text(date.format(java.time.format.DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM)), style = Typo.formOption, color = if (scopeIndex == 1) c.smoke else c.ink) }
                if (scopeIndex == 0) Text(stringResource(R.string.la_data_deve_restare_nello_stesso_mese), style = Typo.formOptionSub, color = c.smoke)
            }
            if (scopeIndex != 0) Box {
                OptionRow(stringResource(R.string.ricorrenza), modifier = Modifier.clickable(role = Role.Button) { freqMenu = true }) {
                    Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                        Text(frequencyLabel(frequency), style = Typo.formOption, color = c.ink)
                        Icon(SfIcons.forName("chevron.down"), null, tint = c.smoke, modifier = Modifier.size(12.dp))
                    }
                }
                DropdownMenu(freqMenu, { freqMenu = false }) {
                    listOf("settimanale", "mensile", "annuale").forEach { f -> DropdownMenuItem(text = { Text(frequencyLabel(f) + if (f == frequency) "  ✓" else "") }, onClick = { freqMenu = false; frequency = f }) }
                }
            }
            UnderlineSegment(listOf(stringResource(R.string.uscita), stringResource(R.string.entrata)), if (income) 1 else 0, { income = it == 1 }, Modifier.testTag("recurrence_type"))
            OptionRow(stringResource(R.string.categoria), modifier = Modifier.clickable(role = Role.Button) { categoryPicker = true }.testTag("recurrence_category")) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                    Text(categoryLabel(category), style = Typo.formOption, color = c.ink)
                    Icon(SfIcons.forName("chevron.down"), null, tint = c.smoke, modifier = Modifier.size(12.dp))
                }
            }
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                SectionLabel(stringResource(R.string.conto))
                Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                    TextChip(stringResource(R.string.nessuno), accountId == null, { accountId = null })
                    accounts.filter { !it.isArchived || it.id == accountId }.forEach { a -> TextChip(a.name, accountId == a.id, { accountId = a.id }, Modifier.testTag("recurrence_account_${a.name}")) }
                }
            }
            OptionRow(stringResource(R.string.fissa), modifier = Modifier.testTag("recurrence_fixed")) { FormSwitch(fixed, { fixed = it }, stringResource(R.string.fissa)) }

            Column {
                ThinDivider(color = c.divider)
                ActionRow(stringResource(R.string.salta_mese), c.ink, Modifier.testTag("btn_skipMonth")) { run(RecurringOps.Action.SkipMonth) }
                ThinDivider(color = c.divider)
                ActionRow(stringResource(R.string.termina_da_qui), c.danger, Modifier.testTag("btn_terminateFrom")) { run(RecurringOps.Action.Terminate(false)) }
                ThinDivider(color = c.divider)
                ActionRow(stringResource(R.string.termina_dopo_questa), c.danger, Modifier.testTag("btn_terminateAfter")) { run(RecurringOps.Action.Terminate(true)) }
                ThinDivider(color = c.divider)
                ActionRow(stringResource(R.string.elimina), c.danger, Modifier.testTag("btn_deleteRecurrence")) { confirmDelete = true }
            }
        }
    }
    if (categoryPicker) CategoryPickerSheet(categories, category, onSelect = { category = it; categoryPicker = false }, onManage = {}, onClose = { categoryPicker = false })
    if (confirmDelete) BtAlert(
        stringResource(R.string.eliminare_le_occorrenze_selezionate), stringResource(R.string.le_occorrenze_gia_effettuate_restano_inv),
        stringResource(R.string.elimina), { confirmDelete = false; run(RecurringOps.Action.Delete(editorScope)) }, { confirmDelete = false }, stringResource(R.string.annulla),
        modifier = Modifier.testTag("alert_deleteRecurrence"),
    )
    error?.let { msg ->
        BtAlert(stringResource(R.string.ricorrenze), msg, stringResource(R.string.ok), { error = null }, { error = null }, stringResource(R.string.annulla), destructive = false)
    }
}

@Composable
private fun ActionRow(text: String, color: androidx.compose.ui.graphics.Color, modifier: Modifier, onClick: () -> Unit) {
    Box(modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button, onClick = onClick), contentAlignment = Alignment.CenterStart) {
        Text(text, style = Typo.formOption, color = color)
    }
}

@Composable
private fun LabeledField(label: String, value: String, onChange: (String) -> Unit, modifier: Modifier = Modifier, keyboard: KeyboardType = KeyboardType.Text) {
    val c = Bt.colors
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SectionLabel(label)
        BasicTextField(value, onChange, singleLine = true, textStyle = Typo.formOption.copy(color = c.ink, fontSize = androidx.compose.ui.unit.TextUnit(17f, androidx.compose.ui.unit.TextUnitType.Sp)),
            cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = keyboard), modifier = modifier.fillMaxWidth().heightIn(min = 32.dp))
        FieldLine()
    }
}
