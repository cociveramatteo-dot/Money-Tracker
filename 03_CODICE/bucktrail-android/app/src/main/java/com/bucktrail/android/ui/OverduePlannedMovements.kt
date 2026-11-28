package com.bucktrail.android.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.ExperimentalLayoutApi
import androidx.compose.foundation.layout.FlowRow
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.key
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Categories
import com.bucktrail.android.domain.TransactionData
import com.bucktrail.android.ui.components.MovementKind
import com.bucktrail.android.ui.components.MovementRow
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SwipeAction
import com.bucktrail.android.ui.components.SwipeableRow
import com.bucktrail.android.ui.components.ThinDivider
import com.bucktrail.android.ui.screens.amountValue
import com.bucktrail.android.ui.screens.localDate
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/** Movimenti pianificati scaduti (di mesi passati e non ancora confermati) — S-73f/S-73g. */
object OverduePlannedMovements {
    fun isOverdue(
        t: TransactionData,
        today: LocalDate,
        zone: ZoneId,
        archivedAccountIds: Set<String> = emptySet(),
    ): Boolean {
        if (t.isDone || t.isTransfer) return false
        if (t.accountId != null && t.accountId in archivedAccountIds) return false
        return YearMonth.from(t.date.atZone(zone)).isBefore(YearMonth.from(today))
    }

    fun list(
        transactions: List<TransactionEntity>,
        today: LocalDate,
        zone: ZoneId,
        archivedAccountIds: Set<String> = emptySet(),
    ): List<TransactionEntity> =
        transactions.filter { isOverdue(it.toData(), today, zone, archivedAccountIds) }.sortedForDisplay(zone)

    fun matchingSection(
        items: List<TransactionEntity>,
        section: MovementSection,
        ruleIds: Set<String>,
    ): List<TransactionEntity> = when (section) {
        MovementSection.All -> items
        MovementSection.Fixed -> items.filter { it.isFixed }
        MovementSection.Recurring -> items.filter { it.templateId.lowercase() in ruleIds }
        MovementSection.Transfer -> emptyList()
        MovementSection.Expense -> items.filter { it.type == Amounts.TYPE_EXPENSE }
        MovementSection.Income -> items.filter { it.type == Amounts.TYPE_INCOME }
    }

    fun resolvedCategoryIcon(t: TransactionEntity): String =
        t.categoryIcon.takeIf { it.isNotEmpty() && it != Categories.UNKNOWN_ICON }
            ?: Categories.iconFor(t.category)
}

@Composable
fun OverduePlannedHeader(
    count: Int,
    compactHeader: Boolean = false,
    onSeeAll: (() -> Unit)? = null,
) {
    val c = Bt.colors
    Row(
        Modifier.fillMaxWidth().semantics(mergeDescendants = true) {}.testTag("overdue_header"),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(6.dp),
    ) {
        Icon(
            SfIcons.forName("clock"),
            null,
            tint = c.plannedText,
            modifier = Modifier.size(if (compactHeader) 14.dp else 16.dp),
        )
        Text(
            stringResource(R.string.da_confermare),
            style = if (compactHeader) Typo.secondary.copy(fontWeight = FontWeight.SemiBold) else Typo.sectionTitle,
            color = c.plannedText,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
        )
        Text(
            count.toString(),
            style = Typo.caption.copy(fontWeight = FontWeight.SemiBold),
            color = c.plannedText,
            modifier = Modifier
                .clip(CircleShape)
                .background(c.plannedSoft)
                .padding(horizontal = 8.dp, vertical = 2.dp),
        )
        Spacer(Modifier.weight(1f))
        if (onSeeAll != null) {
            Box(Modifier.heightIn(min = 44.dp).clickable(role = Role.Button, onClick = onSeeAll), contentAlignment = Alignment.Center) {
                Text(stringResource(R.string.vedi_tutti), style = Typo.secondary.copy(fontWeight = FontWeight.SemiBold), color = c.accent)
            }
        }
    }
}

@OptIn(ExperimentalLayoutApi::class)
@Composable
fun OverduePlannedSection(
    items: List<TransactionEntity>,
    currency: String,
    hidden: Boolean,
    today: LocalDate,
    zone: ZoneId,
    res: android.content.res.Resources,
    ruleIds: Set<String> = emptySet(),
    compactHeader: Boolean = false,
    onSeeAll: (() -> Unit)? = null,
    onEdit: (TransactionEntity) -> Unit,
    onConfirm: (TransactionEntity) -> Unit,
    onDelete: (TransactionEntity) -> Unit,
) {
    if (items.isEmpty()) return
    val c = Bt.colors
    val radius = if (compactHeader) 18.dp else 20.dp
    val largeFont = LocalDensity.current.fontScale >= 1.6f
    val confirmLabel = stringResource(R.string.conferma)

    Column(verticalArrangement = Arrangement.spacedBy(if (compactHeader) 6.dp else 8.dp)) {
        OverduePlannedHeader(count = items.size, compactHeader = compactHeader, onSeeAll = onSeeAll)
        Column(
            Modifier
                .fillMaxWidth()
                .clip(RoundedCornerShape(radius))
                .background(c.surface)
                .border(1.dp, c.planned.copy(alpha = 0.35f), RoundedCornerShape(radius)),
        ) {
            items.forEachIndexed { index, t ->
                key("overdue_${t.id}") {
                    if (index > 0) ThinDivider(Modifier.padding(start = if (compactHeader) 14.dp else 64.dp), c.divider)
                    val category = categoryLabel(t.category, res)
                    val date = t.localDate(zone)
                    val meta = if (t.isFixed) res.getString(R.string.fissa) else category
                    val metaTail = " · ${Fmt.dayMonth(date, today, res)}"
                    val amountText = if (hidden) Fmt.HIDDEN else Fmt.currency(t.amountValue(), currency)
                    val kind = if (t.type == Amounts.TYPE_INCOME) MovementKind.Income else MovementKind.Expense
                    val recurring = t.templateId.lowercase() in ruleIds
                    val categoryIcon = OverduePlannedMovements.resolvedCategoryIcon(t)

                    val confirmButton: @Composable () -> Unit = {
                        Box(
                            Modifier
                                .size(48.dp)
                                .clip(CircleShape)
                                .clickable(role = Role.Button, onClickLabel = confirmLabel) { onConfirm(t) }
                                .testTag("btn_confirmOverdue_${t.name}"),
                            contentAlignment = Alignment.Center,
                        ) {
                            Box(
                                Modifier
                                    .size(32.dp)
                                    .clip(CircleShape)
                                    .background(c.plannedSoft),
                                contentAlignment = Alignment.Center,
                            ) {
                                Icon(
                                    SfIcons.forName("checkmark"),
                                    contentDescription = confirmLabel,
                                    tint = c.plannedText,
                                    modifier = Modifier.size(16.dp),
                                )
                            }
                        }
                    }

                    SwipeableRow(
                        deleteAction = SwipeAction(stringResource(R.string.elimina), SfIcons.forName("trash"), c.danger, c.onAccent),
                        onDelete = { onDelete(t); true },
                        toggleAction = SwipeAction(confirmLabel, SfIcons.forName("checkmark.circle.fill"), c.accent, c.onAccent),
                        onToggle = { onConfirm(t) },
                    ) {
                        if (largeFont) {
                            Column(Modifier.fillMaxWidth().padding(end = 14.dp)) {
                                MovementRow(
                                    title = t.name, meta = meta, metaTail = metaTail, amount = amountText, kind = kind,
                                    categoryName = t.category, categoryIcon = categoryIcon,
                                    planned = true, recurring = recurring, compact = compactHeader,
                                    onClick = { onEdit(t) },
                                )
                                FlowRow(Modifier.padding(start = 6.dp, bottom = 6.dp)) { confirmButton() }
                            }
                        } else {
                            Row(
                                Modifier.fillMaxWidth().padding(start = 14.dp, end = 6.dp),
                                verticalAlignment = Alignment.CenterVertically,
                                horizontalArrangement = Arrangement.spacedBy(2.dp),
                            ) {
                                Box(Modifier.weight(1f)) {
                                    MovementRow(
                                        title = t.name, meta = meta, metaTail = metaTail, amount = amountText, kind = kind,
                                        categoryName = t.category, categoryIcon = categoryIcon,
                                        planned = true, recurring = recurring, compact = compactHeader,
                                        horizontalPadding = 0.dp,
                                        onClick = { onEdit(t) },
                                    )
                                }
                                confirmButton()
                            }
                        }
                    }
                }
            }
        }
    }
}
