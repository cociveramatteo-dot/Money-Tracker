package com.bucktrail.android.ui.forms

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
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
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.domain.AccountType
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.accountTypeRes
import com.bucktrail.android.ui.components.GhostButton
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch

/** Nuovo conto (§4.7): tipo, nome, saldo attuale, esclusione dal totale. */
@Composable
fun AddAccountForm(currency: String, onSave: suspend (AccountEntity) -> Boolean, onClose: () -> Unit) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    var type by rememberSaveable { mutableStateOf(AccountType.Checking.raw) }
    var name by rememberSaveable { mutableStateOf("") }
    var balance by rememberSaveable { mutableStateOf("") }
    var excluded by rememberSaveable { mutableStateOf(false) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val value = if (balance.isBlank()) java.math.BigDecimal.ZERO else Amounts.parse(balance)
    val valid = name.isNotBlank() && value != null

    FullScreenForm(onDismiss = { if (!saving) onClose() }) {
        Text(stringResource(R.string.nuovo_conto), style = Typo.sheetTitle, color = c.ink)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            SectionLabel(stringResource(R.string.tipo))
            AccountType.entries.forEach { t ->
                Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.RadioButton) { type = t.raw }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(stringResource(accountTypeRes(t)), style = Typo.formOption, color = c.ink)
                    if (type == t.raw) Icon(SfIcons.forName("checkmark"), null, tint = c.ink, modifier = Modifier.size(18.dp))
                }
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.nome))
            Box {
                if (name.isEmpty()) Text(stringResource(R.string.es_carta_unicredit_portafoglio), style = Typo.formDescription, color = c.fog)
                BasicTextField(name, { name = it.take(60) }, singleLine = true, textStyle = Typo.formDescription.copy(color = c.ink),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_accountName"))
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.saldo_attuale))
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(Fmt.currencySymbol(currency), style = Typo.formAmountSymbol, color = c.smoke)
                Box(Modifier.weight(1f)) {
                    if (balance.isEmpty()) Text("0", style = Typo.formAmount, color = c.fog)
                    BasicTextField(balance, { balance = it.take(14) }, singleLine = true, textStyle = Typo.formAmount.copy(color = c.ink),
                        cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth().testTag("tf_accountBalance"))
                }
            }
            FieldLine()
            Text(stringResource(R.string.inserisci_il_saldo_che_hai_adesso_su_que), style = Typo.formOptionSub, color = c.smoke)
        }
        Column {
            SectionLabel(stringResource(R.string.opzioni))
            OptionRow(stringResource(R.string.escludi_dal_totale), stringResource(R.string.non_viene_contato_nel_saldo_totale_dei_c)) {
                FormSwitch(excluded, { excluded = it }, stringResource(R.string.escludi_dal_totale))
            }
        }
        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(stringResource(R.string.aggiungi), enabled = valid && !saving, modifier = Modifier.testTag("btn_saveAccount"), onClick = {
                saving = true; failed = false
                scope.launch {
                    val ok = onSave(AccountEntity(name = name.trim(), type = type, initialBalanceCents = Amounts.toCents(checkNotNull(value)), isExcludedFromTotal = excluded))
                    saving = false
                    if (ok) onClose() else failed = true
                }
            })
            GhostButton(stringResource(R.string.annulla), onClose)
        }
    }
}
