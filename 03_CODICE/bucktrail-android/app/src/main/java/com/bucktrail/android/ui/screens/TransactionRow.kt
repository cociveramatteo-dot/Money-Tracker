package com.bucktrail.android.ui.screens

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.size
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.Icon
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.CustomAccessibilityAction
import androidx.compose.ui.semantics.customActions
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.SwipeRules
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.categoryLabel
import com.bucktrail.android.ui.components.MovementRow
import com.bucktrail.android.ui.components.SfIcons
import com.bucktrail.android.ui.components.SwipeAction
import com.bucktrail.android.ui.components.SwipeableRow
import com.bucktrail.android.ui.theme.Bt
import java.time.LocalDate
import java.time.ZoneId

/**
 * Riga movimento condivisa da Home e Movimenti (§4.2): tap = modifica (o trasferimento), swipe sinistra = elimina,
 * swipe destra = Conferma/Pianificato (solo voci fisse o non fatte, se `onToggleDone` è dato), pressione lunga = menu.
 */
@Composable
fun TransactionRow(
    t: TransactionEntity, accounts: List<AccountEntity>, currency: String, hidden: Boolean,
    today: LocalDate, zone: ZoneId, res: android.content.res.Resources, recurring: Boolean = false, compact: Boolean = false,
    onEdit: (TransactionEntity) -> Unit, onDelete: (TransactionEntity) -> Unit, onToggleDone: ((TransactionEntity) -> Unit)? = null,
    onRecurrence: ((TransactionEntity) -> Unit)? = null, deleteOpensEditor: Boolean = false, homeMeta: Boolean = false,
) {
    val c = Bt.colors
    var menu by remember { mutableStateOf(false) }
    val date = t.localDate(zone)
    val planned = !t.isDone
    val account = accountName(accounts, t.accountId)
    val category = categoryLabel(t.category, res)
    // iOS: la Home mostra sempre «categoria · conto · data»; Movimenti «categoria · conto» (fatti) o «Fissa/categoria · data» (pianificati).
    val meta = if (homeMeta) listOf(category, account, Fmt.dayMonth(date, today, res)).filter { it.isNotEmpty() }.joinToString(" · ")
    else if (planned) "${if (t.isFixed) res.getString(R.string.fissa) else category} · ${Fmt.dayMonth(date, today, res)}"
    else listOf(category, account).filter { it.isNotEmpty() }.joinToString(" · ")
    val canToggle = onToggleDone != null && SwipeRules.canToggleDone(t.isFixed, t.isDone)
    val needsConfirm = (t.isTransfer && t.transferGroupId.isNotEmpty()) || deleteOpensEditor
    SwipeableRow(
        deleteAction = SwipeAction(stringResource(R.string.elimina), SfIcons.forName("trash"), c.danger, c.onAccent),
        onDelete = { onDelete(t); !needsConfirm },
        toggleAction = if (canToggle) {
            if (planned) SwipeAction(stringResource(R.string.conferma), SfIcons.forName("checkmark.circle.fill"), c.accent, c.onAccent)
            else SwipeAction(stringResource(R.string.pianificato), SfIcons.forName("clock"), c.smoke, c.surface)
        } else null,
        onToggle = { onToggleDone?.invoke(t) },
        modifier = Modifier.testTag("txRow_${t.id}"),
    ) {
        Box {
            MovementRow(
                title = t.name, meta = meta, amount = money(t.amountValue(), currency, hidden), kind = t.kind(), categoryName = t.category,
                categoryIcon = t.categoryIcon, planned = planned, recurring = recurring, compact = compact,
                onClick = { onEdit(t) }, onLongClick = { menu = true },
                modifier = Modifier.semantics {
                    contentDescription = "${t.name}, " + (if (planned) res.getString(R.string.pianificato) else res.getString(R.string.fatto))
                    // Il menu a pressione lunga è come iOS (solo Ricorrenza/Elimina): le azioni dello swipe restano per TalkBack
                    customActions = buildList {
                        if (canToggle) add(CustomAccessibilityAction(res.getString(if (planned) R.string.conferma else R.string.pianificato)) { onToggleDone?.invoke(t); true })
                        add(CustomAccessibilityAction(res.getString(R.string.elimina)) { onDelete(t); true })
                    }
                },
            )
            DropdownMenu(menu, { menu = false }) {
                // iOS: nella Home il menu ha «Modifica» e «Elimina»; in Movimenti solo «Ricorrenza»/«Elimina»
                if (homeMeta) DropdownMenuItem(
                    text = { Text(stringResource(R.string.modifica)) },
                    leadingIcon = { Icon(SfIcons.forName("pencil"), null, modifier = Modifier.size(18.dp)) },
                    onClick = { menu = false; onEdit(t) },
                )
                if (recurring && onRecurrence != null) DropdownMenuItem(
                    text = { Text(stringResource(R.string.ricorrenza)) },
                    leadingIcon = { Icon(SfIcons.forName("repeat"), null, modifier = Modifier.size(18.dp)) },
                    onClick = { menu = false; onRecurrence(t) },
                )
                DropdownMenuItem(
                    text = { Text(stringResource(R.string.elimina), color = c.danger) },
                    leadingIcon = { Icon(SfIcons.forName("trash"), null, tint = c.danger, modifier = Modifier.size(18.dp)) },
                    onClick = { menu = false; onDelete(t) },
                )
            }
        }
    }
}
