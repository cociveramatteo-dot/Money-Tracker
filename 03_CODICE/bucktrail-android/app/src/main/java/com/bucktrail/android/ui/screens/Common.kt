package com.bucktrail.android.ui.screens

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.statusBarsPadding
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.Fmt
import com.bucktrail.android.ui.components.MovementKind
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.Typo
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

/** Intestazione di pagina (titolo grande + azioni a destra), margine 20. */
@Composable
fun PageHeader(title: String, modifier: Modifier = Modifier, actions: @Composable () -> Unit = {}) {
    Row(
        modifier.fillMaxWidth().statusBarsPadding().padding(horizontal = 20.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically, horizontalArrangement = Arrangement.SpaceBetween,
    ) {
        Text(title, style = Typo.screenTitle, color = Bt.colors.ink, modifier = Modifier.weight(1f))
        Row(horizontalArrangement = Arrangement.spacedBy(8.dp), verticalAlignment = Alignment.CenterVertically) { actions() }
    }
}

fun TransactionEntity.kind(): MovementKind = when {
    isTransfer -> MovementKind.Transfer
    type == Amounts.TYPE_INCOME -> MovementKind.Income
    else -> MovementKind.Expense
}

fun TransactionEntity.localDate(zone: ZoneId): LocalDate = Instant.ofEpochMilli(date).atZone(zone).toLocalDate()

fun TransactionEntity.amountValue(): BigDecimal = Amounts.fromCents(amountCents)

/** Importo mostrato (senza segno: lo applica `MovementRow`) o oscurato. */
fun money(value: BigDecimal, currency: String, hidden: Boolean, hiddenText: String = Fmt.HIDDEN): String =
    if (hidden) hiddenText else Fmt.currency(value, currency)

fun accountName(accounts: List<AccountEntity>, id: String?): String = accounts.firstOrNull { it.id == id }?.name.orEmpty()
