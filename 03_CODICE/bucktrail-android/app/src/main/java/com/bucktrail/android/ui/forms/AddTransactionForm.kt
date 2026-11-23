package com.bucktrail.android.ui.forms

import android.app.DatePickerDialog
import androidx.compose.foundation.clickable
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.saveable.rememberSaveable
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Categories
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.GhostButton
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.UnderlineSegment
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.delay
import kotlinx.coroutines.launch
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/** Aggiungi / modifica movimento (§4.3), stile form: Inter al posto di SF Pro. */
@Composable
fun AddTransactionForm(
    existing: TransactionEntity?, accounts: List<AccountEntity>, categories: List<CategoryEntity>, currency: String,
    today: LocalDate, zone: ZoneId, classify: suspend (String) -> String,
    onSave: suspend (TransactionEntity) -> Boolean, onClose: () -> Unit,
) {
    val c = Bt.colors
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val active = accounts.filter { !it.isArchived }
    val originalDate = existing?.let { java.time.Instant.ofEpochMilli(it.date).atZone(zone).toLocalDate() }

    var income by rememberSaveable { mutableStateOf(existing?.type == Amounts.TYPE_INCOME) }
    var amountText by rememberSaveable { mutableStateOf(existing?.let { Amounts.editableString(Amounts.fromCents(it.amountCents)) }.orEmpty()) }
    var name by rememberSaveable { mutableStateOf(existing?.name.orEmpty()) }
    var notes by rememberSaveable { mutableStateOf(existing?.notes.orEmpty()) }
    var accountId by rememberSaveable { mutableStateOf(existing?.accountId ?: active.firstOrNull()?.id) }
    var dateEpochDay by rememberSaveable { mutableStateOf((originalDate ?: today).toEpochDay()) }
    var planned by rememberSaveable { mutableStateOf(existing?.isDone == false) }
    var chosenCategory by rememberSaveable { mutableStateOf(existing?.category) }
    var suggested by rememberSaveable { mutableStateOf<String?>(null) }
    var categoryMenu by remember { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val date = LocalDate.ofEpochDay(dateEpochDay)

    // suggerimento categoria (debounce 280 ms), solo se l'utente non l'ha scelta a mano
    LaunchedEffect(name) {
        if (chosenCategory != null || name.isBlank()) { suggested = null; return@LaunchedEffect }
        delay(280)
        val result = classify(name.trim())
        suggested = result.takeIf { it != Categories.OTHER && categories.any { c -> c.name == it } }
    }

    val amount = Amounts.parse(amountText)
    val valid = name.isNotBlank() && Amounts.isValidInput(amount)
    val shownCategory = chosenCategory ?: suggested

    FullScreenForm(onDismiss = { if (!saving) onClose() }) {
        Text(stringResource(if (existing == null) R.string.nuovo_movimento else R.string.modifica), style = Typo.sheetTitle, color = c.ink)
        UnderlineSegment(listOf(stringResource(R.string.uscita), stringResource(R.string.entrata)), if (income) 1 else 0, { income = it == 1 })

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.importo))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text((if (income) "+" else "\u2212") + Fmt.currencySymbol(currency), style = Typo.formAmountSymbol, color = c.smoke, modifier = Modifier.heightIn(min = 56.dp))
                Box(Modifier.weight(1f)) {
                    if (amountText.isEmpty()) Text("0", style = Typo.formAmount, color = c.fog)
                    BasicTextField(
                        amountText, { amountText = it.take(14) }, singleLine = true, textStyle = Typo.formAmount.copy(color = c.ink),
                        cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth().testTag("tf_amount"),
                    )
                }
            }
            FieldLine()
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.descrizione))
            Box {
                if (name.isEmpty()) Text(stringResource(R.string.es_affitto_netflix_pizza), style = Typo.formDescription, color = c.fog)
                BasicTextField(name, { name = it.take(80) }, singleLine = true, textStyle = Typo.formDescription.copy(color = c.ink),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_name"))
            }
            FieldLine()
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.categoria))
            Box {
                Row(
                    Modifier.fillMaxWidth().heightIn(min = 44.dp).testTag("btn_categoryPicker").clickable(role = Role.Button) { categoryMenu = true },
                    verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    shownCategory?.let { cat ->
                        Icon(SfIcons.forName(categories.firstOrNull { it.name == cat }?.icon ?: Categories.iconFor(cat)), null, tint = c.smoke, modifier = Modifier.size(14.dp))
                    }
                    Text(shownCategory?.let { categoryLabel(it) } ?: stringResource(R.string.scegli), style = Typo.formOption, color = if (shownCategory == null) c.smoke else c.ink)
                    if (chosenCategory == null && suggested != null) Text(stringResource(R.string.suggerita), style = Typo.formOptionSub, color = c.smoke)
                    Box(Modifier.weight(1f))
                    Icon(SfIcons.forName("chevron.down"), null, tint = c.smoke, modifier = Modifier.size(14.dp))
                }
                DropdownMenu(categoryMenu, { categoryMenu = false }) {
                    categories.forEach { cat ->
                        DropdownMenuItem(
                            text = { Text(categoryLabel(cat.name)) },
                            leadingIcon = { Icon(SfIcons.forName(cat.icon), null, modifier = Modifier.size(16.dp)) },
                            onClick = { chosenCategory = cat.name; categoryMenu = false },
                        )
                    }
                }
            }
            FieldLine()
        }

        if (active.isNotEmpty()) Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.conto))
            Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
                active.forEach { acc ->
                    TextChip(acc.name, accountId == acc.id, { accountId = if (accountId == acc.id) null else acc.id }, Modifier.testTag("accountChip_${acc.name}"))
                }
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            SectionLabel(stringResource(R.string.opzioni))
            OptionRow(stringResource(R.string.data), modifier = Modifier.clickable(role = Role.Button) {
                DatePickerDialog(context, { _, y, m, d ->
                    val picked = LocalDate.of(y, m + 1, d)
                    dateEpochDay = picked.toEpochDay(); planned = picked > today
                }, date.year, date.monthValue - 1, date.dayOfMonth).show()
            }) { Text(date.format(java.time.format.DateTimeFormatter.ofLocalizedDate(java.time.format.FormatStyle.MEDIUM)), style = Typo.formOption, color = c.ink) }
            OptionRow(stringResource(R.string.pianificato)) {
                FormSwitch(planned, { planned = it }, stringResource(R.string.pianificato))
            }
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.note_opzionale))
            Box {
                if (notes.isEmpty()) Text(stringResource(R.string.aggiungi_una_nota), style = Typo.formNote, color = c.fog)
                BasicTextField(notes, { notes = it.take(500) }, maxLines = 3, textStyle = Typo.formNote.copy(color = c.ink),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_notes"))
            }
            FieldLine()
        }

        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(
                stringResource(if (existing == null) R.string.salva else R.string.aggiorna),
                enabled = valid && !saving, modifier = Modifier.testTag("btn_saveTransaction"),
                onClick = {
                    saving = true; failed = false
                    scope.launch {
                        val category = shownCategory ?: Categories.OTHER
                        val icon = categories.firstOrNull { it.name == category }?.icon ?: if (shownCategory == null) Categories.UNKNOWN_ICON else Categories.iconFor(category)
                        val dateMillis = if (date == originalDate) existing!!.date
                        else date.atTime(12, 0).atZone(zone).toInstant().toEpochMilli()
                        val entity = (existing ?: TransactionEntity(id = UUID.randomUUID().toString(), name = "", amountCents = 0, type = "", date = 0)).copy(
                            accountId = accountId, name = name.trim(), amountCents = Amounts.toCents(checkNotNull(amount)),
                            type = if (income) Amounts.TYPE_INCOME else Amounts.TYPE_EXPENSE, category = category, categoryIcon = icon,
                            date = dateMillis, isDone = !planned, notes = notes.trim(),
                        )
                        val ok = onSave(entity)
                        saving = false
                        if (ok) onClose() else failed = true
                    }
                },
            )
            GhostButton(stringResource(R.string.annulla), onClose, Modifier.testTag("btn_cancelAddTransaction"))
        }
    }
}
