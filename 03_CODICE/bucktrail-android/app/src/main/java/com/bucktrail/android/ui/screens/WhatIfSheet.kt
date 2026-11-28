package com.bucktrail.android.ui.screens

import androidx.compose.foundation.ExperimentalFoundationApi
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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.BasicTextField
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateListOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.focus.FocusRequester
import androidx.compose.ui.focus.focusRequester
import androidx.compose.ui.graphics.SolidColor
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.WhatIfBaseline
import com.bucktrail.android.ui.WhatIfHypothesis
import com.bucktrail.android.ui.WhatIfResult
import com.bucktrail.android.ui.WhatIfScenario
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.components.Card
import com.bucktrail.android.ui.components.FitText
import com.bucktrail.android.ui.components.SectionLabel
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SheetPage
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.forms.FormSwitch
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Dim
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal
import java.util.UUID

/** Simulazione rapida «E se…?» dalla Home: solo in memoria, nulla viene salvato. */
@OptIn(ExperimentalFoundationApi::class)
@Composable
fun WhatIfSheet(
    baselines: List<WhatIfBaseline>,
    currency: String,
    hidden: Boolean,
    onClose: () -> Unit,
) {
    val c = Bt.colors
    val accessibilityLayout = LocalDensity.current.fontScale >= 1.5f
    var selectedId by remember { mutableStateOf("all") }
    var accountMenuOpen by remember { mutableStateOf(false) }
    val items = remember { mutableStateListOf<WhatIfHypothesis>() }
    var pendingFocusId by remember { mutableStateOf<String?>(null) }

    val activeBaseline = baselines.firstOrNull { it.id == selectedId }
        ?: baselines.firstOrNull()
        ?: WhatIfBaseline("all", null, BigDecimal.ZERO, BigDecimal.ZERO)
    val included = baselines.filter { it.name != null && !it.isExcludedFromTotal }
    val excluded = baselines.filter { it.name != null && it.isExcludedFromTotal }
    val result = WhatIfScenario.result(activeBaseline, items)

    fun moneyText(v: BigDecimal): String = if (hidden) Fmt.HIDDEN_HOME else Fmt.currency(v, currency)
    fun deltaText(v: BigDecimal): String = when {
        v.signum() > 0 -> "+" + Fmt.currency(v, currency)
        else -> Fmt.currency(v, currency)
    }

    SheetPage(
        title = stringResource(R.string.e_se),
        onDismiss = onClose,
        trailing = { BarAction(stringResource(R.string.fine), onClose, Modifier.testTag("whatIf.done")) },
        scroll = false,
    ) {
        Column(Modifier.weight(1f)) {
            Column(
                Modifier
                    .weight(1f)
                    .verticalScroll(rememberScrollState())
                    .padding(horizontal = Dim.screenMargin.dp, vertical = Dim.m.dp),
                verticalArrangement = Arrangement.spacedBy(Dim.l.dp),
            ) {
                Box {
                    Row(
                        Modifier
                            .heightIn(min = 44.dp)
                            .clip(RoundedCornerShape(50))
                            .background(c.surface)
                            .border(1.dp, c.fog, RoundedCornerShape(50))
                            .clickable(role = Role.Button) { accountMenuOpen = true }
                            .padding(horizontal = Dim.l.dp, vertical = 10.dp)
                            .testTag("whatIf.accountMenu"),
                        verticalAlignment = Alignment.CenterVertically,
                        horizontalArrangement = Arrangement.spacedBy(8.dp),
                    ) {
                        Text(
                            activeBaseline.name ?: stringResource(R.string.tutti),
                            style = Typo.rowName.copy(fontWeight = FontWeight.Medium),
                            color = c.ink,
                            maxLines = 1,
                            overflow = TextOverflow.Ellipsis,
                        )
                        Icon(SfIcons.forName("chevron.down"), null, tint = c.ink, modifier = Modifier.size(14.dp))
                    }
                    DropdownMenu(accountMenuOpen, { accountMenuOpen = false }) {
                        baselines.firstOrNull { it.name == null }?.let { all ->
                            DropdownMenuItem(
                                text = { Text(stringResource(R.string.tutti) + if (activeBaseline.id == all.id) "  ✓" else "") },
                                onClick = { selectedId = all.id; accountMenuOpen = false },
                            )
                        }
                        included.forEach { b ->
                            DropdownMenuItem(
                                text = { Text((b.name.orEmpty()) + if (activeBaseline.id == b.id) "  ✓" else "") },
                                onClick = { selectedId = b.id; accountMenuOpen = false },
                            )
                        }
                        if (excluded.isNotEmpty()) {
                            ThinDivider()
                            Text(
                                stringResource(R.string.esclusi_dal_totale),
                                style = Typo.caption,
                                color = c.smoke,
                                modifier = Modifier.padding(horizontal = 12.dp, vertical = 6.dp),
                            )
                            excluded.forEach { b ->
                                DropdownMenuItem(
                                    text = { Text((b.name.orEmpty()) + if (activeBaseline.id == b.id) "  ✓" else "") },
                                    onClick = { selectedId = b.id; accountMenuOpen = false },
                                )
                            }
                        }
                    }
                }

                Card {
                    if (items.isEmpty()) {
                        Text(
                            stringResource(R.string.nessuna_ipotesi_aggiungine_una),
                            style = Typo.secondary,
                            color = c.smoke,
                            modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp),
                        )
                    } else {
                        Column {
                            items.forEachIndexed { index, item ->
                                if (index > 0) ThinDivider(Modifier.padding(vertical = Dim.m.dp), c.divider)
                                HypothesisRow(
                                    index = index,
                                    item = item,
                                    accessibilityLayout = accessibilityLayout,
                                    requestFocus = pendingFocusId == item.id,
                                    onFocused = { if (pendingFocusId == item.id) pendingFocusId = null },
                                    onChange = { updated -> items[index] = updated },
                                    onDelete = { items.removeAt(index) },
                                )
                            }
                        }
                    }
                }

                val limitReached = items.size >= WhatIfScenario.MAX_HYPOTHESES
                Row(
                    Modifier
                        .fillMaxWidth()
                        .heightIn(min = 48.dp)
                        .clip(RoundedCornerShape(Dim.cardRadius.dp))
                        .background(c.surface)
                        .clickable(enabled = !limitReached, role = Role.Button) {
                            val newId = UUID.randomUUID().toString()
                            items.add(WhatIfHypothesis(id = newId))
                            pendingFocusId = newId
                        }
                        .padding(horizontal = Dim.l.dp)
                        .testTag("whatIf.addHypothesis"),
                    verticalAlignment = Alignment.CenterVertically,
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                ) {
                    Icon(SfIcons.forName("plus"), null, tint = if (limitReached) c.smoke else c.accent, modifier = Modifier.size(18.dp))
                    Text(
                        stringResource(R.string.aggiungi_ipotesi),
                        style = Typo.rowName.copy(fontWeight = FontWeight.SemiBold),
                        color = if (limitReached) c.smoke else c.accent,
                    )
                }

                if (accessibilityLayout) {
                    WhatIfResultsCard(result, ::moneyText, ::deltaText, accessibilityLayout = true)
                    Text(
                        stringResource(R.string.le_ipotesi_non_vengono_salvate),
                        style = Typo.caption,
                        color = c.smoke,
                    )
                }
            }

            if (!accessibilityLayout) {
                Column(
                    Modifier
                        .fillMaxWidth()
                        .background(c.paper)
                        .padding(horizontal = Dim.screenMargin.dp, vertical = Dim.m.dp),
                    verticalArrangement = Arrangement.spacedBy(Dim.s.dp),
                ) {
                    WhatIfResultsCard(result, ::moneyText, ::deltaText, accessibilityLayout = false)
                    Text(
                        stringResource(R.string.le_ipotesi_non_vengono_salvate),
                        style = Typo.caption,
                        color = c.smoke,
                    )
                }
            }
        }
    }
}

@OptIn(ExperimentalFoundationApi::class)
@Composable
private fun HypothesisRow(
    index: Int,
    item: WhatIfHypothesis,
    accessibilityLayout: Boolean,
    requestFocus: Boolean,
    onFocused: () -> Unit,
    onChange: (WhatIfHypothesis) -> Unit,
    onDelete: () -> Unit,
) {
    val c = Bt.colors
    val focusRequester = remember { FocusRequester() }
    var deleteMenu by remember { mutableStateOf(false) }
    val invalid = WhatIfScenario.isInvalidInput(item.amountText)
    val signLabel = stringResource(if (item.isIncome) R.string.entrata else R.string.spesa)
    val toggleLabel = stringResource(R.string.includi_nel_calcolo)
    val unnamed = stringResource(R.string.ipotesi_senza_nome)
    val toggleValue = item.name.trim().ifEmpty { unnamed }

    LaunchedEffect(requestFocus) {
        if (requestFocus) {
            focusRequester.requestFocus()
            onFocused()
        }
    }

    val signButton: @Composable () -> Unit = {
        Box(
            Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(if (item.isIncome) c.accentSoft else c.dangerSoft)
                .clickable(role = Role.Button) { onChange(item.copy(isIncome = !item.isIncome)) }
                .semantics { contentDescription = signLabel }
                .testTag("whatIf.row.$index.sign"),
            contentAlignment = Alignment.Center,
        ) {
            Icon(
                SfIcons.forName(if (item.isIncome) "plus" else "minus"),
                null,
                tint = if (item.isIncome) c.accent else c.danger,
                modifier = Modifier.size(18.dp),
            )
        }
    }

    val amountField: @Composable (Modifier) -> Unit = { mod ->
        Box(
            mod
                .heightIn(min = 44.dp)
                .clip(RoundedCornerShape(10.dp))
                .background(c.paper)
                .border(if (invalid) 1.5.dp else 1.dp, if (invalid) c.danger else c.fog, RoundedCornerShape(10))
                .padding(horizontal = 10.dp, vertical = 10.dp),
            contentAlignment = Alignment.CenterEnd,
        ) {
            if (item.amountText.isEmpty()) {
                Text("0", style = Typo.rowAmount, color = c.smoke.copy(alpha = 0.55f), textAlign = TextAlign.End)
            }
            BasicTextField(
                value = item.amountText,
                onValueChange = { onChange(item.copy(amountText = it.take(14))) },
                singleLine = true,
                textStyle = Typo.rowAmount.copy(color = if (item.isOn) c.ink else c.smoke, textAlign = TextAlign.End),
                cursorBrush = SolidColor(c.accent),
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier
                    .fillMaxWidth()
                    .focusRequester(focusRequester)
                    .testTag("whatIf.row.$index.amount"),
            )
        }
    }

    val nameField: @Composable (Modifier) -> Unit = { mod ->
        Box(mod.heightIn(min = 44.dp), contentAlignment = Alignment.CenterStart) {
            if (item.name.isEmpty()) {
                Text(
                    stringResource(R.string.nome_es_cena),
                    style = Typo.rowName,
                    color = c.smoke.copy(alpha = 0.55f),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                )
            }
            BasicTextField(
                value = item.name,
                onValueChange = { onChange(item.copy(name = it.take(60))) },
                singleLine = true,
                textStyle = Typo.rowName.copy(color = if (item.isOn) c.ink else c.smoke),
                cursorBrush = SolidColor(c.accent),
                modifier = Modifier.fillMaxWidth().testTag("whatIf.row.$index.name"),
            )
        }
    }

    val toggle: @Composable () -> Unit = {
        FormSwitch(
            checked = item.isOn,
            onChange = { onChange(item.copy(isOn = it)) },
            description = "$toggleLabel: $toggleValue",
            modifier = Modifier.testTag("whatIf.row.$index.toggle"),
        )
    }

    Box(
        Modifier
            .fillMaxWidth()
            .combinedClickable(onClick = {}, onLongClick = { deleteMenu = true }),
    ) {
        if (accessibilityLayout) {
            Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                    signButton()
                    amountField(Modifier.weight(1f))
                    toggle()
                }
                nameField(Modifier.fillMaxWidth())
            }
        } else {
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                signButton()
                amountField(Modifier.weight(0.36f))
                nameField(Modifier.weight(0.64f))
                toggle()
            }
        }
        DropdownMenu(deleteMenu, { deleteMenu = false }) {
            DropdownMenuItem(
                text = { Text(stringResource(R.string.elimina), color = c.danger) },
                onClick = { deleteMenu = false; onDelete() },
            )
        }
    }
}

@Composable
private fun WhatIfResultsCard(
    res: WhatIfResult,
    moneyText: (BigDecimal) -> String,
    deltaText: (BigDecimal) -> String,
    accessibilityLayout: Boolean,
) {
    val c = Bt.colors
    val deltaColor = when {
        res.delta.signum() > 0 -> c.accent
        res.delta.signum() < 0 -> c.danger
        else -> c.smoke
    }
    Card {
        Column(verticalArrangement = Arrangement.spacedBy(Dim.m.dp)) {
            ResultBlock(
                title = stringResource(R.string.saldo_di_oggi),
                nowText = moneyText(res.todayNow),
                withText = moneyText(res.todayWith),
                nowTag = "whatIf.result.today.now",
                withTag = "whatIf.result.today.with",
                accessibilityLayout = accessibilityLayout,
            )
            ResultBlock(
                title = stringResource(R.string.saldo_atteso_a_fine_mese),
                nowText = moneyText(res.endNow),
                withText = moneyText(res.endWith),
                nowTag = "whatIf.result.end.now",
                withTag = "whatIf.result.end.with",
                accessibilityLayout = accessibilityLayout,
            )
            ThinDivider(color = c.divider)
            Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween) {
                Text(stringResource(R.string.differenza_totale), style = Typo.secondary, color = c.smoke)
                Spacer(Modifier.size(8.dp))
                FitText(
                    deltaText(res.delta),
                    Typo.sectionTitle,
                    deltaColor,
                    Modifier.testTag("whatIf.result.delta"),
                    minScale = 0.7f,
                    textAlign = TextAlign.End,
                )
            }
        }
    }
}

@Composable
private fun ResultBlock(
    title: String,
    nowText: String,
    withText: String,
    nowTag: String,
    withTag: String,
    accessibilityLayout: Boolean,
) {
    val c = Bt.colors
    val nowLabel = stringResource(R.string.ora)
    val withLabel = stringResource(R.string.con_le_ipotesi)
    Column(verticalArrangement = Arrangement.spacedBy(4.dp)) {
        Text(title, style = Typo.secondary, color = c.smoke)
        if (accessibilityLayout) {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(nowLabel, style = Typo.caption, color = c.smoke)
                    FitText(nowText, Typo.rowAmount, c.smoke, Modifier.testTag(nowTag), minScale = 0.7f)
                }
                Column(verticalArrangement = Arrangement.spacedBy(2.dp)) {
                    Text(withLabel, style = Typo.caption, color = c.smoke)
                    FitText(withText, Typo.sectionTitle, c.ink, Modifier.testTag(withTag), minScale = 0.7f)
                }
            }
        } else {
            Row(verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.spacedBy(8.dp)) {
                FitText(nowText, Typo.rowAmount, c.smoke, Modifier.testTag(nowTag), minScale = 0.7f)
                Text("→", style = Typo.secondary, color = c.smoke)
                FitText(withText, Typo.sectionTitle, c.ink, Modifier.testTag(withTag), minScale = 0.7f)
            }
        }
    }
}
