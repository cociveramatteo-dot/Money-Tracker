package com.bucktrail.android.ui.screens

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.border
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardActions
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.ImeAction
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.AppData
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.EmptyState
import com.bucktrail.android.ui.components.SecondaryChip
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.components.TypeChip
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.Locale

private enum class TypeFilter(val tag: String) { All("Tutti"), Fixed("Fisse"), Transfer("Trasf."), Expense("Uscite"), Income("Entrate") }

private fun foldText(s: String) = com.bucktrail.android.domain.KeywordCategoryClassifier.fold(s)

/** Movimenti (§4.2): ricerca, chip tipo, mese/categoria, «In arrivo» in cima, gruppi per giorno. */
@Composable
fun MovementsScreen(
    data: AppData, today: LocalDate, zone: ZoneId,
    onEdit: (TransactionEntity) -> Unit, onDelete: (TransactionEntity) -> Unit, onSearchActiveChange: (Boolean) -> Unit = {},
) {
    val c = Bt.colors
    val res = LocalContext.current.resources
    val ledger = data.ledger
    val hidden = data.prefs.hideBalance
    val currency = data.prefs.currencyCode
    var query by rememberSaveable { mutableStateOf("") }
    var type by rememberSaveable { mutableStateOf(TypeFilter.All) }
    var monthOffset by rememberSaveable { mutableIntStateOf(0) }
    var category by rememberSaveable { mutableStateOf<String?>(null) }
    var monthMenu by remember { mutableStateOf(false) }
    var categoryMenu by remember { mutableStateOf(false) }
    val locale = Locale.getDefault()
    val month = YearMonth.from(today).plusMonths(monthOffset.toLong())

    val filtered = remember(ledger.transactions, query, type, month, category) {
        val q = foldText(query.trim())
        ledger.transactions.filter { t ->
            (q.isNotEmpty() || YearMonth.from(t.localDate(zone)) == month) &&
                (q.isEmpty() || foldText(t.name).contains(q)) &&
                when (type) {
                    TypeFilter.All -> true
                    TypeFilter.Fixed -> t.isFixed
                    TypeFilter.Transfer -> t.isTransfer
                    TypeFilter.Expense -> t.type == Amounts.TYPE_EXPENSE && !t.isTransfer
                    TypeFilter.Income -> t.type == Amounts.TYPE_INCOME && !t.isTransfer
                } && (category == null || t.category == category)
        }
    }
    val planned = remember(filtered) { filtered.filter { !it.isDone } }
    val groups = remember(filtered, zone) { filtered.filter { it.isDone }.groupBy { it.localDate(zone) }.toSortedMap(compareByDescending { it }) }
    fun sum(list: List<TransactionEntity>) = list.filter { !it.isTransfer }.fold(BigDecimal.ZERO) { a, t -> a + Amounts.signed(t.amountValue(), t.type) }

    Column(Modifier.fillMaxSize()) {
        PageHeader(stringResource(R.string.movimenti))
        // Ricerca
        Row(
            Modifier.padding(horizontal = Dim.cardMargin.dp).fillMaxWidth().heightIn(min = 46.dp).clip(RoundedCornerShape(16.dp)).background(c.surface)
                .border(1.dp, c.fog, RoundedCornerShape(16.dp)).padding(horizontal = 16.dp),
            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
        ) {
            Icon(SfIcons.forName("magnifyingglass"), null, tint = c.smoke, modifier = Modifier.size(18.dp))
            Box(Modifier.weight(1f)) {
                if (query.isEmpty()) Text(stringResource(R.string.cerca_per_nome), style = Typo.secondary.copy(fontSize = androidx.compose.ui.unit.TextUnit(15f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke)
                BasicTextField(
                    query, { query = it; onSearchActiveChange(it.isNotEmpty()) }, singleLine = true,
                    textStyle = Typo.rowName.copy(color = c.ink, fontWeight = FontWeight.Normal), cursorBrush = SolidColor(c.accent),
                    keyboardOptions = KeyboardOptions(imeAction = ImeAction.Done), keyboardActions = KeyboardActions(),
                    modifier = Modifier.fillMaxWidth().testTag("tf_searchTransactions"),
                )
            }
            if (query.isNotEmpty()) Box(Modifier.size(28.dp).androidxClick { query = ""; onSearchActiveChange(false) }, contentAlignment = Alignment.Center) {
                Icon(SfIcons.forName("xmark"), stringResource(R.string.annulla), tint = c.smoke, modifier = Modifier.size(14.dp))
            }
        }
        // Chip tipo
        Row(Modifier.padding(top = 12.dp).horizontalScroll(rememberScrollState()).padding(horizontal = Dim.cardMargin.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            TypeFilter.entries.forEach { f ->
                val label = when (f) {
                    TypeFilter.All -> stringResource(R.string.tutti); TypeFilter.Fixed -> stringResource(R.string.fisse)
                    TypeFilter.Transfer -> stringResource(R.string.trasf); TypeFilter.Expense -> stringResource(R.string.uscite)
                    TypeFilter.Income -> stringResource(R.string.entrate)
                }
                TypeChip(label, type == f, { type = f }, Modifier.testTag("txFilterBlock_${f.tag}"))
            }
        }
        // Chip secondari
        Row(Modifier.padding(vertical = 10.dp).horizontalScroll(rememberScrollState()).padding(horizontal = Dim.cardMargin.dp), horizontalArrangement = Arrangement.spacedBy(8.dp)) {
            Box {
                SecondaryChip(Fmt.monthYear(month, locale), { monthMenu = true }, Modifier.testTag("btn_monthPicker"), trailing = SfIcons.forName("chevron.down"))
                DropdownMenu(monthMenu, { monthMenu = false }) {
                    DropdownMenuItem(text = { Text(stringResource(R.string.questo_mese)) }, onClick = { monthOffset = 0; monthMenu = false })
                    DropdownMenuItem(text = { Text(stringResource(R.string.mese_precedente)) }, onClick = { monthOffset -= 1; monthMenu = false })
                    DropdownMenuItem(text = { Text(stringResource(R.string.mese_successivo)) }, onClick = { monthOffset += 1; monthMenu = false })
                    ThinDivider()
                    for (o in -6..6) DropdownMenuItem(
                        text = { Text(Fmt.monthYear(YearMonth.from(today).plusMonths(o.toLong()), locale) + if (o == monthOffset) "  ✓" else "") },
                        onClick = { monthOffset = o; monthMenu = false },
                    )
                }
            }
            Box {
                SecondaryChip(category?.let { categoryLabel(it) } ?: stringResource(R.string.categoria), { categoryMenu = true }, Modifier.testTag("btn_categoryFilter"),
                    active = category != null, trailing = SfIcons.forName("chevron.down"))
                DropdownMenu(categoryMenu, { categoryMenu = false }) {
                    DropdownMenuItem(text = { Text(stringResource(R.string.tutte_le_categorie)) }, onClick = { category = null; categoryMenu = false })
                    ledger.categories.forEach { cat ->
                        DropdownMenuItem(
                            text = { Text(categoryLabel(cat.name) + if (cat.name == category) "  ✓" else "") },
                            onClick = { category = if (category == cat.name) null else cat.name; categoryMenu = false },
                        )
                    }
                }
            }
        }
        LazyColumn(
            Modifier.weight(1f), contentPadding = PaddingValues(start = Dim.cardMargin.dp, end = Dim.cardMargin.dp, bottom = Dim.listBottomPadding.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp),
        ) {
            if (planned.isNotEmpty()) item("planned") {
                Column {
                    Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                        Text(stringResource(R.string.in_arrivo_pianificati), style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.plannedText)
                        Text(money(sum(planned), currency, hidden), style = Typo.rowAmount, color = c.plannedText)
                    }
                    GroupCard {
                        planned.sortedByDescending { it.date }.forEachIndexed { i, t ->
                            if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                            TransactionRow(t, ledger.accounts, currency, hidden, today, zone, res, compact = true,
                                recurring = ledger.rules.any { it.id.equals(t.templateId, true) }, onEdit = onEdit, onDelete = onDelete)
                        }
                    }
                }
            }
            groups.forEach { (day, rows) ->
                item(day.toString()) {
                    Column {
                        Row(Modifier.fillMaxWidth().padding(horizontal = 4.dp, vertical = 6.dp), horizontalArrangement = Arrangement.SpaceBetween) {
                            Text(Fmt.dayMonth(day, today, res, locale), style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.smoke)
                            val total = sum(rows)
                            Text((if (total.signum() > 0 && !hidden) "+" else "") + money(total, currency, hidden), style = Typo.rowAmount, color = c.ink)
                        }
                        GroupCard {
                            rows.forEachIndexed { i, t ->
                                if (i > 0) ThinDivider(Modifier.padding(start = 14.dp), c.divider)
                                TransactionRow(t, ledger.accounts, currency, hidden, today, zone, res, compact = true,
                                    recurring = ledger.rules.any { it.id.equals(t.templateId, true) }, onEdit = onEdit, onDelete = onDelete)
                            }
                        }
                    }
                }
            }
            if (planned.isEmpty() && groups.isEmpty()) item("empty") {
                if (query.isNotBlank()) EmptyState(SfIcons.forName("magnifyingglass"), stringResource(R.string.nessun_risultato), stringResource(R.string.nessun_movimento_corrisponde_alla_ricerc))
                else EmptyState(SfIcons.forName("tray"), stringResource(R.string.nessun_movimento), stringResource(R.string.i_movimenti_di_questo_periodo_apparirann))
            }
        }
    }
}

@Composable
private fun GroupCard(content: @Composable () -> Unit) {
    Column(Modifier.fillMaxWidth().clip(RoundedCornerShape(18.dp)).background(Bt.colors.surface)) { content() }
}

private fun Modifier.androidxClick(onClick: () -> Unit): Modifier =
    this.then(Modifier.clickable(role = Role.Button, onClick = onClick))
