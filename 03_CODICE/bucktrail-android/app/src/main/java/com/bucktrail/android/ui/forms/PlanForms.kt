package com.bucktrail.android.ui.forms

import android.app.DatePickerDialog
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Budgeting
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.GhostButton
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/** Nuovo budget (§4.6): categorie multiple (griglia 2 colonne), icona, conto, limite mensile. */
@Composable
fun AddBudgetForm(
    month: YearMonth, categories: List<CategoryEntity>, accounts: List<AccountEntity>, currency: String,
    onSave: suspend (BudgetEntity) -> Boolean, onClose: () -> Unit,
) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    val active = accounts.filter { !it.isArchived }
    var selected by rememberSaveable { mutableStateOf(listOf<String>()) }
    var limit by rememberSaveable { mutableStateOf("") }
    var accountId by rememberSaveable { mutableStateOf<String?>(null) }
    var chosenIcon by rememberSaveable { mutableStateOf<String?>(null) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val amount = Amounts.parse(limit)
    val canSave = Amounts.isValidInput(amount) && (selected.isNotEmpty() || accountId != null)

    FullScreenForm(onDismiss = { if (!saving) onClose() }) {
        Text(stringResource(R.string.nuovo_budget), style = Typo.sheetTitle, color = c.ink)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.categoria_opzionale))
            Text(stringResource(R.string.lascia_vuoto_per_un_budget_globale_sul_c), style = Typo.formOptionSub, color = c.smoke)
            categories.chunked(2).forEach { pair ->
                Row(horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    pair.forEach { cat ->
                        val sel = cat.name in selected
                        Row(
                            Modifier.weight(1f).heightIn(min = 44.dp).clip(RoundedCornerShape(8.dp)).background(if (sel) c.ink else c.fog)
                                .clickable(role = Role.Checkbox) {
                                    selected = if (sel) { if (chosenIcon == cat.icon) chosenIcon = null; selected - cat.name } else selected + cat.name
                                }.padding(horizontal = 8.dp).testTag("budgetCat_${cat.name}"),
                            verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp, Alignment.CenterHorizontally),
                        ) {
                            Icon(SfIcons.forName(cat.icon), null, tint = if (sel) c.paper else c.smoke, modifier = Modifier.size(14.dp))
                            Text(categoryLabel(cat.name), style = Typo.formOption.copy(fontWeight = FontWeight.Medium, fontSize = androidx.compose.ui.unit.TextUnit(13f, androidx.compose.ui.unit.TextUnitType.Sp)),
                                color = if (sel) c.paper else c.smoke, maxLines = 1)
                        }
                    }
                    if (pair.size == 1) Box(Modifier.weight(1f))
                }
            }
        }
        if (selected.size > 1) Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.icona_budget))
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                categories.filter { it.name in selected }.forEach { cat ->
                    val chosen = chosenIcon == cat.icon
                    Box(Modifier.size(44.dp).clip(CircleShape).background(if (chosen) c.ink else c.fog).clickable(role = Role.RadioButton) { chosenIcon = cat.icon }, contentAlignment = Alignment.Center) {
                        Icon(SfIcons.forName(cat.icon), null, tint = if (chosen) c.paper else c.smoke, modifier = Modifier.size(18.dp))
                    }
                }
            }
        }
        if (active.isNotEmpty()) Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.conto_opzionale))
            Text(stringResource(R.string.lascia_vuoto_per_applicarlo_a_tutti_i_co), style = Typo.formOptionSub, color = c.smoke)
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                TextChip(stringResource(R.string.tutti), accountId == null, { accountId = null })
                active.forEach { acc -> TextChip(acc.name, accountId == acc.id, { accountId = acc.id }, Modifier.testTag("budgetAccount_${acc.name}")) }
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.limite_mensile))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(Fmt.currencySymbol(currency), style = Typo.formAmountSymbol, color = c.smoke, modifier = Modifier.heightIn(min = 56.dp))
                Box(Modifier.weight(1f)) {
                    if (limit.isEmpty()) Text("0", style = Typo.formAmount, color = c.fog)
                    BasicTextField(limit, { limit = it.take(14) }, singleLine = true, textStyle = Typo.formAmount.copy(color = c.ink), cursorBrush = SolidColor(c.accent),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), modifier = Modifier.fillMaxWidth().testTag("tf_budgetLimit"))
                }
            }
            FieldLine()
        }
        if (!canSave && limit.isNotEmpty()) Text(stringResource(R.string.seleziona_almeno_una_categoria_o_un_cont), style = Typo.formOptionSub.copy(fontSize = androidx.compose.ui.unit.TextUnit(12f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke)
        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(stringResource(R.string.salva), enabled = canSave && !saving, modifier = Modifier.testTag("btn_saveBudget"), onClick = {
                saving = true; failed = false
                scope.launch {
                    val names = selected.sorted()
                    val icon = chosenIcon?.takeIf { it.isNotEmpty() } ?: names.firstOrNull()?.let { n -> categories.firstOrNull { it.name == n }?.icon ?: com.bucktrail.android.domain.Categories.iconFor(n) } ?: "building.columns.fill"
                    val ok = onSave(BudgetEntity(accountId = accountId, category = Budgeting.categoryString(names), categoryIcon = icon, monthlyLimitCents = Amounts.toCents(checkNotNull(amount)), month = month.monthValue, year = month.year))
                    saving = false
                    if (ok) onClose() else failed = true
                }
            })
            GhostButton(stringResource(R.string.annulla), onClose, Modifier.testTag("btn_cancelAddBudget"))
        }
    }
}

private val goalIcons = listOf(
    "target", "trophy.fill", "star.fill", "flag.fill", "crown.fill", "rosette", "house.fill", "car.fill", "airplane", "tram.fill", "bicycle", "figure.walk",
    "eurosign.circle.fill", "creditcard.fill", "banknote", "chart.line.uptrend.xyaxis", "building.columns.fill", "cart.fill", "graduationcap.fill", "book.fill",
    "laptopcomputer", "iphone", "headphones", "paintbrush.fill", "heart.fill", "figure.run", "dumbbell.fill", "leaf.fill",
    "fork.knife", "bed.double.fill", "gift.fill", "pawprint.fill", "sparkles", "camera.fill", "music.note", "map.fill",
)

/** Nuovo / modifica obiettivo: icona (36), nome, importo, «Già risparmiato» o «Aggiungi risparmio», scadenza. */
@Composable
fun AddGoalForm(existing: GoalEntity?, currency: String, today: LocalDate, zone: ZoneId, onSave: suspend (GoalEntity) -> Boolean, onClose: () -> Unit) {
    val c = Bt.colors
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    var name by rememberSaveable { mutableStateOf(existing?.name.orEmpty()) }
    var target by rememberSaveable { mutableStateOf(existing?.let { Amounts.editableString(Amounts.fromCents(it.targetCents)) }.orEmpty()) }
    var extra by rememberSaveable { mutableStateOf("") }
    var hasDeadline by rememberSaveable { mutableStateOf(existing?.deadline != null) }
    var deadlineDay by rememberSaveable { mutableStateOf(existing?.deadline?.let { Instant.ofEpochMilli(it).atZone(zone).toLocalDate().toEpochDay() } ?: today.plusDays(90).toEpochDay()) }
    var icon by rememberSaveable { mutableStateOf(existing?.emoji?.takeIf { it.isNotEmpty() && it.all { ch -> ch.code < 128 } } ?: "target") }
    var picker by rememberSaveable { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val deadline = LocalDate.ofEpochDay(deadlineDay)
    val targetAmount = Amounts.parse(target)
    val extraAmount = Amounts.parse(extra)
    val valid = name.isNotEmpty() && target.isNotEmpty()

    FullScreenForm(onDismiss = { if (!saving) onClose() }) {
        Text(stringResource(if (existing == null) R.string.nuovo_obiettivo else R.string.modifica), style = Typo.sheetTitle, color = c.ink)
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.icona))
            Row(Modifier.fillMaxWidth().heightIn(min = 52.dp).clickable(role = Role.Button) { picker = !picker }.testTag("btn_goalIcon"), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                Box(Modifier.size(52.dp).clip(CircleShape).background(c.fog), contentAlignment = Alignment.Center) { Icon(SfIcons.forName(icon), null, tint = c.ink, modifier = Modifier.size(22.dp)) }
                Text(stringResource(R.string.cambia_icona), style = Typo.formOption, color = c.smoke, modifier = Modifier.weight(1f))
                Icon(SfIcons.forName(if (picker) "chevron.up" else "chevron.down"), null, tint = c.smoke, modifier = Modifier.size(12.dp))
            }
            if (picker) Column(verticalArrangement = Arrangement.spacedBy(12.dp), modifier = Modifier.padding(top = 8.dp)) {
                goalIcons.chunked(6).forEach { rowIcons ->
                    Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.SpaceBetween) {
                        rowIcons.forEach { i ->
                            Box(Modifier.size(44.dp).clip(CircleShape).background(if (icon == i) c.ink else c.fog).clickable(role = Role.RadioButton) { icon = i; picker = false }, contentAlignment = Alignment.Center) {
                                Icon(SfIcons.forName(i), null, tint = if (icon == i) c.paper else c.smoke, modifier = Modifier.size(18.dp))
                            }
                        }
                    }
                }
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.nome))
            Box {
                if (name.isEmpty()) Text(stringResource(R.string.es_vacanza_auto_nuova), style = Typo.formDescription, color = c.fog)
                BasicTextField(name, { name = it.take(80) }, singleLine = true, textStyle = Typo.formDescription.copy(color = c.ink), cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_goalName"))
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(R.string.obiettivo))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text(Fmt.currencySymbol(currency), style = Typo.formAmountSymbol, color = c.smoke, modifier = Modifier.heightIn(min = 56.dp))
                Box(Modifier.weight(1f)) {
                    if (target.isEmpty()) Text("0", style = Typo.formAmount, color = c.fog)
                    BasicTextField(target, { target = it.take(14) }, singleLine = true, textStyle = Typo.formAmount.copy(color = c.ink), cursorBrush = SolidColor(c.accent),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), modifier = Modifier.fillMaxWidth().testTag("tf_goalTarget"))
                }
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
            SectionLabel(stringResource(if (existing == null) R.string.gia_risparmiato else R.string.aggiungi_risparmio))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                Text("+" + Fmt.currencySymbol(currency), style = Typo.formAmountSymbol.copy(fontSize = androidx.compose.ui.unit.TextUnit(22f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke, modifier = Modifier.heightIn(min = 44.dp))
                Box(Modifier.weight(1f)) {
                    if (extra.isEmpty()) Text("0", style = Typo.formDescription.copy(fontSize = androidx.compose.ui.unit.TextUnit(40f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.fog)
                    BasicTextField(extra, { extra = it.take(14) }, singleLine = true, textStyle = Typo.formDescription.copy(color = c.ink, fontSize = androidx.compose.ui.unit.TextUnit(40f, androidx.compose.ui.unit.TextUnitType.Sp)),
                        cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), modifier = Modifier.fillMaxWidth().testTag("tf_goalSavings"))
                }
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            SectionLabel(stringResource(R.string.scadenza))
            OptionRow(stringResource(R.string.imposta_scadenza), modifier = Modifier.testTag("toggle_goalDeadline")) { FormSwitch(hasDeadline, { hasDeadline = it }, stringResource(R.string.imposta_scadenza)) }
            if (hasDeadline) OptionRow(stringResource(R.string.data), modifier = Modifier.clickable(role = Role.Button) {
                DatePickerDialog(context, { _, y, m, d -> deadlineDay = LocalDate.of(y, m + 1, d).toEpochDay() }, deadline.year, deadline.monthValue - 1, deadline.dayOfMonth).show()
            }.testTag("goalDeadlineDate")) { Text(deadline.format(java.time.format.DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM)), style = Typo.formOption, color = c.ink) }
        }
        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(stringResource(if (existing == null) R.string.salva else R.string.aggiorna), enabled = valid && !saving, modifier = Modifier.testTag("btn_saveGoal"), onClick = {
                val t = targetAmount
                if (t == null || !Amounts.isValidInput(t)) { failed = true; return@PrimaryButton }
                saving = true; failed = false
                scope.launch {
                    val added = extraAmount?.takeIf { it.signum() > 0 } ?: java.math.BigDecimal.ZERO
                    val currentBefore = existing?.let { Amounts.fromCents(it.currentCents) } ?: java.math.BigDecimal.ZERO
                    val current = currentBefore + added
                    val dl = if (hasDeadline) deadline.atTime(12, 0).atZone(zone).toInstant().toEpochMilli() else null
                    val goal = (existing ?: GoalEntity(name = "", targetCents = 0)).copy(
                        name = name, targetCents = Amounts.toCents(t), emoji = icon, currentCents = Amounts.toCents(current), deadline = dl, isCompleted = current >= t,
                    )
                    val ok = onSave(goal)
                    saving = false
                    if (ok) onClose() else failed = true
                }
            })
            GhostButton(stringResource(R.string.annulla), onClose, Modifier.testTag("btn_cancelAddGoal"))
        }
    }
}
