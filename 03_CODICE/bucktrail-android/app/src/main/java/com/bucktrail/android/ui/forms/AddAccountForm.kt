package com.bucktrail.android.ui.forms

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.ui.text.style.TextAlign
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
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.TransactionOps
import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.domain.AccountType
import com.bucktrail.android.domain.Categories
import java.math.BigDecimal
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.accountTypeRes
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.components.PrimaryButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch

/** Esito del modulo conto: conto, rettifica opzionale, soglia (`null` = invariata) e se aggiungerlo alla lista Home. */
class AccountSaveRequest(val account: AccountEntity, val adjustment: TransactionEntity?, val threshold: String?, val addToHome: Boolean)

/** Nuovo / modifica conto (§4.7): tipo, nome, saldo attuale, esclusione dal totale, avviso saldo basso. */
@Composable
fun AddAccountForm(
    existing: AccountEntity?, currentBalance: BigDecimal, hasTransactions: Boolean, thresholdRaw: String?, categories: List<CategoryEntity>,
    currency: String, onSave: suspend (AccountSaveRequest) -> Boolean, onClose: () -> Unit,
) {
    val c = Bt.colors
    val scope = rememberCoroutineScope()
    val adjustmentName = stringResource(R.string.rettifica_saldo)
    val initialThreshold = AccountEditing.threshold(thresholdRaw)?.let { Amounts.editableString(it) }.orEmpty()
    var type by rememberSaveable { mutableStateOf(existing?.type ?: AccountType.Checking.raw) }
    var name by rememberSaveable { mutableStateOf(existing?.name.orEmpty()) }
    var balance by rememberSaveable { mutableStateOf(if (existing != null && currentBalance.signum() != 0) Amounts.editableString(currentBalance) else "") }
    var excluded by rememberSaveable { mutableStateOf(existing?.isExcludedFromTotal ?: false) }
    var threshold by rememberSaveable { mutableStateOf(initialThreshold) }
    var saving by remember { mutableStateOf(false) }
    var failed by remember { mutableStateOf(false) }
    val value = if (balance.isBlank()) BigDecimal.ZERO else Amounts.parse(balance)
    val valid = name.isNotBlank() && Amounts.isValidBalance(value)

    FullScreenForm(onDismiss = { if (!saving) onClose() }, cancelTag = "btn_cancelAddAccount") {
        Text(stringResource(if (existing == null) R.string.nuovo_conto else R.string.modifica_conto), style = Typo.sheetTitle, color = c.ink)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            SectionLabel(stringResource(R.string.tipo))
            AccountType.entries.forEachIndexed { i, t ->
                if (i > 0) ThinDivider(color = c.fog)
                Row(Modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.RadioButton) { type = t.raw }, verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    Text(stringResource(accountTypeRes(t)), style = if (type == t.raw) Typo.formOption.copy(fontFamily = com.bucktrail.android.ui.theme.Fonts.formSemibold) else Typo.formOption, color = c.ink)
                    if (type == t.raw) Icon(SfIcons.forName("checkmark"), null, tint = c.ink, modifier = Modifier.size(18.dp))
                }
            }
        }
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.nome))
            Box {
                if (name.isEmpty()) Text(stringResource(R.string.es_carta_unicredit_portafoglio), style = Typo.formDescription, color = c.smoke.copy(alpha = 0.45f))
                BasicTextField(name, { name = it.take(60) }, singleLine = true, textStyle = Typo.formDescription.copy(color = c.ink),
                    cursorBrush = SolidColor(c.accent), modifier = Modifier.fillMaxWidth().testTag("tf_accountName"))
            }
            FieldLine()
        }
        Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
            SectionLabel(stringResource(R.string.saldo_attuale))
            Text(stringResource(R.string.inserisci_il_saldo_che_hai_adesso_su_que), style = Typo.formOptionSub, color = c.smoke)
            Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(Fmt.currencySymbol(currency), style = Typo.formAmountSymbol, color = c.smoke)
                Box(Modifier.weight(1f)) {
                    if (balance.isEmpty()) Text("0", style = Typo.formAmount, color = c.smoke.copy(alpha = 0.45f))
                    BasicTextField(balance, { balance = it.take(14) }, singleLine = true, textStyle = Typo.formAmount.copy(color = c.ink),
                        cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.fillMaxWidth().testTag("tf_accountBalance"))
                }
            }
            FieldLine()
        }
        Column {
            SectionLabel(stringResource(R.string.opzioni))
            OptionRow(stringResource(R.string.escludi_dal_totale), stringResource(R.string.non_viene_contato_nel_saldo_totale_dei_c)) {
                FormSwitch(excluded, { excluded = it }, stringResource(R.string.escludi_dal_totale))
            }
            OptionRow(stringResource(R.string.avviso_saldo_basso), stringResource(R.string.ricevi_una_notifica_quando_il_saldo_scen)) {
                Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(Fmt.currencySymbol(currency), style = Typo.formOption, color = c.smoke)
                    Box(Modifier.width(80.dp)) {
                        if (threshold.isEmpty()) Text("0", style = Typo.formOption.copy(textAlign = TextAlign.End), color = c.fog, modifier = Modifier.fillMaxWidth())
                        BasicTextField(threshold, { threshold = it.take(12) }, singleLine = true,
                            textStyle = Typo.formOption.copy(color = c.ink, textAlign = TextAlign.End, fontFamily = com.bucktrail.android.ui.theme.Fonts.formMedium),
                            cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                            modifier = Modifier.fillMaxWidth().testTag("tf_accountThreshold"))
                    }
                }
            }
        }
        if (failed) Text(stringResource(R.string.save_failed), style = Typo.formOption, color = c.danger)
        Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
            PrimaryButton(stringResource(if (existing == null) R.string.aggiungi else R.string.salva), enabled = valid && !saving, modifier = Modifier.testTag("btn_saveAccount"), onClick = {
                saving = true; failed = false
                scope.launch {
                    val newValue = checkNotNull(value)
                    var adjustment: TransactionEntity? = null
                    val account = if (existing == null) {
                        AccountEntity(name = name.trim(), type = type, initialBalanceCents = Amounts.toCents(newValue), isExcludedFromTotal = excluded)
                    } else {
                        var initial = existing.initialBalanceCents
                        when (val change = AccountEditing.balanceChange(hasTransactions, currentBalance, newValue)) {
                            is AccountEditing.BalanceChange.SetInitial -> initial = Amounts.toCents(change.value)
                            is AccountEditing.BalanceChange.Adjust -> adjustment = TransactionOps.adjustment(
                                existing.id, change, adjustmentName, categories.firstOrNull { it.name == Categories.ADJUSTMENT }?.icon ?: "arrow.triangle.2.circlepath", System.currentTimeMillis(),
                            )
                            AccountEditing.BalanceChange.None -> Unit
                        }
                        existing.copy(name = name.trim(), type = type, initialBalanceCents = initial, isExcludedFromTotal = excluded)
                    }
                    val ok = onSave(AccountSaveRequest(account, adjustment, threshold.trim(), addToHome = existing == null && !excluded))
                    saving = false
                    if (ok) onClose() else failed = true
                }
            })
        }
    }
}
