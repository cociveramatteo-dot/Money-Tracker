package com.bucktrail.android.shortcuts

import android.os.Bundle
import android.widget.Toast
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.imePadding
import androidx.compose.foundation.layout.navigationBarsPadding
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.systemBarsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.horizontalScroll
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.Text
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.produceState
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.res.stringResource
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.R
import com.bucktrail.android.data.QuickAddOps
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.QuickAdd
import com.bucktrail.android.ui.components.BarAction
import com.bucktrail.android.ui.forms.TextChip
import com.bucktrail.android.ui.screens.AuthField
import com.bucktrail.android.ui.theme.Bt
import com.bucktrail.android.ui.theme.BucktrailTheme
import com.bucktrail.android.ui.theme.Typo
import kotlinx.coroutines.launch

/**
 * «Aggiungi spesa/entrata» senza aprire l'app (scorciatoia sull'icona, riquadro Impostazioni rapide, widget, link `bucktrail://add`).
 * Stessa logica degli App Intent iOS (`QuickAdd`), stesso DAO dell'app; nessun saldo mostrato, quindi nessun blocco app.
 */
class QuickAddActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val link = QuickAdd.parseLink(intent?.dataString) as? QuickAdd.Link.Add
        val kind = link?.kind ?: if (intent?.getStringExtra("kind") == "income") QuickAdd.Kind.Income else QuickAdd.Kind.Expense
        setContent { BucktrailTheme { QuickAddCard(kind, link) { finish() } } }
    }
}

@androidx.compose.runtime.Composable
private fun QuickAddCard(kind: QuickAdd.Kind, link: QuickAdd.Link.Add?, onClose: () -> Unit) {
    val c = Bt.colors
    val context = androidx.compose.ui.platform.LocalContext.current
    val app = context.applicationContext as BucktrailApplication
    val scope = rememberCoroutineScope()
    var name by remember { mutableStateOf(link?.name.orEmpty()) }
    var amount by remember { mutableStateOf(link?.amount.orEmpty()) }
    var account by remember { mutableStateOf(link?.account) }
    var category by remember { mutableStateOf(link?.category) }
    var error by remember { mutableStateOf<Int?>(null) }
    var busy by remember { mutableStateOf(false) }
    val accounts by produceState<List<String>?>(null) { value = app.database.dao().accounts().filter { !it.isArchived }.sortedBy { it.createdAt }.map { it.name } }
    val categories by produceState(emptyList<String>()) { value = app.database.dao().categories().sortedBy { it.sortOrder }.map { it.name } }
    val expense = kind == QuickAdd.Kind.Expense

    Box(Modifier.fillMaxSize().background(Color.Black.copy(alpha = 0.45f)).clickable(onClick = onClose).systemBarsPadding().imePadding(), contentAlignment = Alignment.BottomCenter) {
        Column(
            Modifier.fillMaxWidth().padding(12.dp).clip(RoundedCornerShape(24.dp)).background(c.paper).clickable(enabled = false) {}.navigationBarsPadding()
                .padding(20.dp).verticalScroll(rememberScrollState()).testTag("quickAdd"),
            verticalArrangement = Arrangement.spacedBy(14.dp),
        ) {
            Text(stringResource(if (expense) R.string.aggiungi_spesa else R.string.aggiungi_entrata), style = Typo.sectionTitle, color = c.ink)
            if (accounts?.isEmpty() == true) {
                Text(stringResource(R.string.nessun_conto_trovato_apri_l_app_per_aggi), style = Typo.formOption, color = c.smoke)
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End) { BarAction(stringResource(R.string.chiudi), onClose) }
            } else {
                AuthField(stringResource(R.string.nome), "", name, { name = it }, KeyboardType.Text, tag = "field_quickName")
                AuthField(stringResource(R.string.importo), "0,00", amount, { amount = it }, KeyboardType.Decimal, tag = "field_quickAmount")
                accounts?.takeIf { it.size > 1 }?.let { names ->
                    Text(stringResource(R.string.conto_opzionale), style = Typo.formOptionSub, color = c.smoke)
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        names.forEach { n -> TextChip(n, selected = (account ?: names.first()) == n, onClick = { account = n }) }
                    }
                }
                if (categories.isNotEmpty()) {
                    Text(stringResource(R.string.categoria_opzionale), style = Typo.formOptionSub, color = c.smoke)
                    Row(Modifier.horizontalScroll(rememberScrollState()), horizontalArrangement = Arrangement.spacedBy(16.dp)) {
                        categories.forEach { n -> TextChip(com.bucktrail.android.ui.categoryLabel(n), selected = category == n, onClick = { category = if (category == n) null else n }) }
                    }
                }
                error?.let { Text(stringResource(it), style = Typo.formOption, color = c.danger, modifier = Modifier.testTag("quick_error")) }
                Row(Modifier.fillMaxWidth(), horizontalArrangement = Arrangement.End, verticalAlignment = Alignment.CenterVertically) {
                    BarAction(stringResource(R.string.annulla), onClose)
                    BarAction(stringResource(R.string.salva), {
                        if (busy) return@BarAction
                        val parsed = Amounts.parse(amount)?.toDouble() ?: Double.NaN
                        busy = true
                        scope.launch {
                            when (val r = QuickAddOps.save(context, kind, name, parsed, account, category)) {
                                is QuickAddOps.Outcome.Saved -> { Toast.makeText(context, r.message, Toast.LENGTH_LONG).show(); onClose() }
                                is QuickAddOps.Outcome.Invalid -> error = when (r.problem) {
                                    QuickAdd.Problem.InvalidAmount -> R.string.l_importo_deve_essere_un_numero_positivo
                                    QuickAdd.Problem.EmptyName -> if (expense) R.string.inserisci_una_descrizione_per_la_spesa else R.string.inserisci_una_descrizione_per_l_entrata
                                }
                                QuickAddOps.Outcome.Failed -> error = R.string.il_database_non_e_disponibile_apri_l_app
                            }
                            busy = false
                        }
                    }, Modifier.testTag("btn_quickSave"), bold = true)
                }
            }
        }
    }
}
