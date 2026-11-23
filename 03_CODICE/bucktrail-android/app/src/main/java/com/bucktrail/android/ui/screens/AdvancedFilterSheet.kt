package com.bucktrail.android.ui.screens

import android.app.DatePickerDialog
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
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
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.GhostButton
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.forms.FormSwitch
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Fonts
import com.bucktrail.android.ui.theme.Typo
import java.time.LocalDate
import java.time.format.DateTimeFormatter
import java.time.format.FormatStyle

/** Filtri avanzati (§4.2): importo minimo/massimo e periodo personalizzato (sostituisce il filtro mese). */
@Composable
fun AdvancedFilterSheet(
    minText: String, maxText: String, useDates: Boolean, from: LocalDate, to: LocalDate, currency: String, activeCount: Int,
    onChange: (String, String, Boolean) -> Unit, onFromChange: (LocalDate) -> Unit, onToChange: (LocalDate) -> Unit, onClose: () -> Unit,
) {
    val c = Bt.colors
    val context = LocalContext.current
    var min by remember { mutableStateOf(minText) }
    var max by remember { mutableStateOf(maxText) }
    var dates by remember { mutableStateOf(useDates) }
    fun pick(current: LocalDate, onPicked: (LocalDate) -> Unit) {
        DatePickerDialog(context, { _, y, m, d -> onPicked(LocalDate.of(y, m + 1, d)) }, current.year, current.monthValue - 1, current.dayOfMonth).show()
    }
    val dateFormat = DateTimeFormatter.ofLocalizedDate(FormatStyle.MEDIUM)

    SheetPage(
        stringResource(R.string.filtri), onClose,
        trailing = { BarAction(stringResource(R.string.fine), onClose, Modifier.testTag("btn_doneFilters"), bold = true) },
    ) {
        Column(Modifier.padding(horizontal = 20.dp, vertical = 8.dp), verticalArrangement = Arrangement.spacedBy(24.dp)) {
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionLabel(stringResource(R.string.importo))
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                    AmountField(stringResource(R.string.minimo), "0", min, currency, Modifier.weight(1f).testTag("tf_filterMin")) { min = it; onChange(min, max, dates) }
                    AmountField(stringResource(R.string.massimo), "∞", max, currency, Modifier.weight(1f).testTag("tf_filterMax")) { max = it; onChange(min, max, dates) }
                }
            }
            ThinDivider(color = c.fog)
            Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
                SectionLabel(stringResource(R.string.periodo))
                Row(Modifier.fillMaxWidth().heightIn(min = 48.dp), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                    Column(Modifier.weight(1f).padding(end = 12.dp)) {
                        Text(stringResource(R.string.periodo_personalizzato), style = Typo.formOption, color = c.ink)
                        Text(stringResource(R.string.sostituisce_il_filtro_mese), style = Typo.formOptionSub, color = c.smoke)
                    }
                    FormSwitch(dates, { dates = it; onChange(min, max, dates) }, stringResource(R.string.periodo_personalizzato))
                }
                if (dates) {
                    DateRow(stringResource(R.string.da), from.format(dateFormat), Modifier.testTag("btn_filterFrom")) { pick(from, onFromChange) }
                    DateRow(stringResource(R.string.a), to.format(dateFormat), Modifier.testTag("btn_filterTo")) { pick(to, onToChange) }
                }
            }
            if (activeCount > 0 || min.isNotEmpty() || max.isNotEmpty() || dates) {
                ThinDivider(color = c.fog)
                GhostButton(stringResource(R.string.rimuovi_tutti_i_filtri), { min = ""; max = ""; dates = false; onChange("", "", false) }, Modifier.testTag("btn_clearFilters"))
            }
        }
    }
}

@Composable
private fun AmountField(label: String, placeholder: String, value: String, currency: String, modifier: Modifier, onChange: (String) -> Unit) {
    val c = Bt.colors
    Column(modifier, verticalArrangement = Arrangement.spacedBy(8.dp)) {
        Text(label, style = Typo.caption, color = c.smoke)
        Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(4.dp)) {
            Text(Fmt.currencySymbol(currency), style = Typo.formDescription.copy(fontSize = androidx.compose.ui.unit.TextUnit(16f, androidx.compose.ui.unit.TextUnitType.Sp)), color = c.smoke)
            Box(Modifier.weight(1f)) {
                if (value.isEmpty()) Text(placeholder, style = Typo.formOption.copy(fontSize = androidx.compose.ui.unit.TextUnit(20f, androidx.compose.ui.unit.TextUnitType.Sp), fontFamily = Fonts.formMedium), color = c.fog)
                BasicTextField(
                    value, { onChange(it.take(14)) }, singleLine = true,
                    textStyle = Typo.formOption.copy(fontSize = androidx.compose.ui.unit.TextUnit(20f, androidx.compose.ui.unit.TextUnitType.Sp), fontFamily = Fonts.formMedium, color = c.ink),
                    cursorBrush = SolidColor(c.accent), keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal), modifier = Modifier.fillMaxWidth(),
                )
            }
        }
        ThinDivider(color = c.fog)
    }
}

@Composable
private fun DateRow(label: String, value: String, modifier: Modifier, onClick: () -> Unit) {
    val c = Bt.colors
    Row(modifier.fillMaxWidth().heightIn(min = 48.dp).clickable(role = Role.Button, onClick = onClick), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
        Text(label, style = Typo.formOption, color = c.ink)
        Text(value, style = Typo.formOption.copy(fontFamily = Fonts.formMedium), color = c.ink)
    }
}
