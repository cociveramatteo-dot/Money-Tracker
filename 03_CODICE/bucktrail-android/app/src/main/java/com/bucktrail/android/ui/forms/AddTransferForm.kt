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
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
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
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.material3.Icon
import com.bucktrail.android.ui.components.SfIcons
import androidx.compose.foundation.layout.size
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.TransactionOps
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.components.GhostButton
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

/** Aggiungi / modifica trasferimento (§4.4): due gambe collegate dal `transferGroupId` (§3.7). */
@Composable
fun AddTransferForm(
    editingOut: TransactionEntity?, editingIn: TransactionEntity?, accounts: List<AccountEntity>, currency: String,
    today: LocalDate, zone: ZoneId, onSave: suspend (List<TransactionEntity>) -> Boolean, onClose: () -> Unit,
) {
    val c = Bt.colors
    val context = LocalContext.current
    val scope = rememberCoroutineScope()
    val editing = editingOut != null && editingIn != null
    val selectable = accounts.filter { !it.isArchived || it.id == editingOut?.accountId || it.id == editingIn?.accountId }
    val active = accounts.filter { !it.isArchived }
    val originalDate = editingOut?.let { Instant.ofEpochMilli(it.date).atZone(zone).toLocalDate() }

    var amountText by rememberSaveable { mutableStateOf(editingOut?.let { Amounts.editableString(Amounts.fromCents(it.amountCents)) }.orEmpty()) }
    var fromId by rememberSaveable { mutableStateOf(editingOut?.accountId ?: active.getOrNull(0)?.id) }
    var toId by rememberSaveable { mutableStateOf(editingIn?.accountId ?: active.getOrNull(1)?.id) }
    var done by rememberSaveable { mutableStateOf(editingOut?.isDone ?: true) }
    var dateEpochDay by rememberSaveable { mutableStateOf((originalDate ?: today).toEpochDay()) }
    var notes by rememberSaveable { mutableStateOf(editingOut?.notes.orEmpty()) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val date = LocalDate.ofEpochDay(dateEpochDay)
    val amount = Amounts.parse(amountText)
    val from = selectable.firstOrNull { it.id == fromId }
    val to = selectable.firstOrNull { it.id == toId }
    val valid = Amounts.isValidInput(amount) && from != null && to != null && from.id != to.id

    FullScreenForm(onDismiss = { if (!saving) onClose() }, cancelTag = "btn_cancelTransfer") {
        Text(stringResource(if (editing) R.string.modifica_trasferimento else R.string.trasferimento), style = Typo.sheetTitle, color = c.ink)

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.importo))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(Fmt.currencySymbol(currency), style = Typo.formAmountSymbol, color = c.smoke, modifier = Modifier.heightIn(min = 56.dp))
                Box(Modifier.weight(1f)) {
                    if (amountText.isEmpty()) Text("0", style = Typo.formAmount, color = c.smoke.copy(alpha = 0.45f))
                    BasicTextField(amountText, { amountText = it.take(14) }, singleLine = true, textStyle = Typo.formAmount.copy(color = c.ink),
                        cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth().testTag("tf_amount"))
                }
            }
            FieldLine()
        }

        AccountChoice(stringResource(R.string.da), "from", selectable.filter { it.id != toId }, fromId) { fromId = it }
        AccountChoice(stringResource(R.string.a), "to", selectable.filter { it.id != fromId }, toId) { toId = it }

        if (from != null && to != null) Row(
            Modifier.fillMaxWidth().clip(RoundedCornerShape(10.dp)).background(c.fog).padding(12.dp),
            horizontalArrangement = Arrangement.Center, verticalAlignment = Alignment.CenterVertically,
        ) {
            val bold = Typo.formOption.copy(fontFamily = com.bucktrail.android.ui.theme.Fonts.formSemibold, fontSize = 13.sp)
            Text(from.name, style = bold, color = c.ink)
            Icon(SfIcons.forName("arrow.right"), null, tint = c.smoke, modifier = Modifier.padding(horizontal = 10.dp).size(14.dp))
            Text(to.name, style = bold, color = c.ink)
        }

        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            SectionLabel(stringResource(R.string.opzioni))
            OptionRow(stringResource(R.string.gia_effettuato), stringResource(R.string.togli_la_spunta_se_il_trasferimento_e_pi)) {
                FormSwitch(done, { done = it }, stringResource(R.string.gia_effettuato))
            }
            OptionRow(stringResource(R.string.data), titleColor = c.smoke, modifier = Modifier.clickable(role = Role.Button) {
                DatePickerDialog(context, { _, y, m, d ->
                    val picked = LocalDate.of(y, m + 1, d)
                    dateEpochDay = picked.toEpochDay(); done = picked <= today
                }, date.year, date.monthValue - 1, date.dayOfMonth).show()
            }) { DatePill(date.format(DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM))) }
        }

        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            Box {
                if (notes.isEmpty()) Text(stringResource(R.string.note_opzionale), style = Typo.formNote, color = c.smoke.copy(alpha = 0.45f))
                BasicTextField(notes, { notes = it.take(500) }, maxLines = 3, textStyle = Typo.formNote.copy(color = c.ink),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_notes"))
            }
            FieldLine()
        }

        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(
                stringResource(when { editing -> R.string.aggiorna; done -> R.string.trasferisci; else -> R.string.pianifica }),
                enabled = valid && !saving, modifier = Modifier.testTag("btn_saveTransfer"),
                onClick = {
                    saving = true; failed = false
                    scope.launch {
                        val dateMillis = if (originalDate != null && date == originalDate) editingOut!!.date else date.atTime(12, 0).atZone(zone).toInstant().toEpochMilli()
                        val input = TransactionOps.TransferInput(
                            checkNotNull(from).id, from.name, checkNotNull(to).id, to.name, Amounts.toCents(checkNotNull(amount)), dateMillis, done, notes.trim(),
                        )
                        val legs = if (editing) TransactionOps.updateTransfer(editingOut!!, editingIn!!, input) else TransactionOps.newTransfer(input)
                        val ok = onSave(legs)
                        saving = false
                        if (ok) onClose() else failed = true
                    }
                },
            )
        }
    }
}

@Composable
private fun AccountChoice(label: String, tag: String, accounts: List<AccountEntity>, selectedId: String?, onSelect: (String) -> Unit) {
    val c = Bt.colors
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        SectionLabel(label)
        if (accounts.isEmpty()) Text(stringResource(R.string.nessun_altro_conto), style = Typo.formOptionSub.copy(fontSize = androidx.compose.ui.unit.TextUnit(13f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke)
        else Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(20.dp)) {
            accounts.forEach { acc -> TextChip(acc.name, selectedId == acc.id, { onSelect(acc.id) }, Modifier.testTag("transfer_${tag}_${acc.name}")) }
        }
    }
}
