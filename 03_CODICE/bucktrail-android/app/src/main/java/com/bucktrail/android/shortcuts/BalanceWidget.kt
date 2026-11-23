package com.bucktrail.android.shortcuts

import android.content.Context
import android.content.Intent
import android.net.Uri
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.glance.GlanceId
import androidx.glance.GlanceModifier
import androidx.glance.action.clickable
import androidx.glance.appwidget.GlanceAppWidget
import androidx.glance.appwidget.GlanceAppWidgetReceiver
import androidx.glance.appwidget.SizeMode
import androidx.glance.appwidget.action.actionStartActivity
import androidx.glance.appwidget.cornerRadius
import androidx.glance.appwidget.provideContent
import androidx.glance.background
import androidx.glance.layout.Alignment
import androidx.glance.layout.Column
import androidx.glance.layout.Row
import androidx.glance.layout.Spacer
import androidx.glance.layout.fillMaxSize
import androidx.glance.layout.padding
import androidx.glance.layout.width
import androidx.glance.text.FontWeight
import androidx.glance.text.Text
import androidx.glance.text.TextStyle
import androidx.compose.ui.graphics.Color
import androidx.glance.color.ColorProvider as DayNight
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.MainActivity
import com.bucktrail.android.R
import com.bucktrail.android.domain.HomeProjection
import com.bucktrail.android.data.toData
import com.bucktrail.android.ui.Fmt
import kotlinx.coroutines.flow.first
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId

/** Cosa mostra il widget: importi in chiaro o oscurati (privacy). Funzione pura. */
data class WidgetContent(val total: String, val expected: String, val hidden: Boolean, val empty: Boolean) {
    companion object {
        /** Gli importi si oscurano se l'utente ha «oscura importi» **oppure** il blocco app: il widget è visibile a telefono bloccato. */
        fun hide(hideBalance: Boolean, appLock: Boolean) = hideBalance || appLock

        fun make(total: BigDecimal?, expected: BigDecimal?, currency: String, hidden: Boolean): WidgetContent = when {
            total == null || expected == null -> WidgetContent("", "", hidden, empty = true)
            hidden -> WidgetContent(Fmt.HIDDEN_HOME, Fmt.HIDDEN_HOME, true, false)
            else -> WidgetContent(Fmt.currency(total, currency), Fmt.currency(expected, currency), false, false)
        }
    }
}

/** Widget «Saldo» (extra Android): saldo attuale e atteso a fine mese; tocca = apre l'app; «+» = Aggiungi spesa. */
class BalanceWidget : GlanceAppWidget() {
    override val sizeMode = SizeMode.Exact

    override suspend fun provideGlance(context: Context, id: GlanceId) {
        val app = context.applicationContext as BucktrailApplication
        val prefs = app.prefs.state.first()
        val content = runCatching {
            val dao = app.database.dao()
            val accounts = dao.accounts().map { it.toData() }
            val txs = dao.transactions().map { it.toData() }
            val included = com.bucktrail.android.domain.Balance.included(accounts)
            if (accounts.none { !it.isArchived } || included.isEmpty()) WidgetContent.make(null, null, prefs.currencyCode, false)
            else {
                val p = HomeProjection.make(accounts, txs, LocalDate.now(), ZoneId.systemDefault())
                WidgetContent.make(p.total, p.trail.expectedBalance, prefs.currencyCode, WidgetContent.hide(prefs.hideBalance, prefs.appLockEnabled))
            }
        }.getOrElse { WidgetContent.make(null, null, prefs.currencyCode, false) }
        val label = context.getString(R.string.saldo_conti)
        val expectedLabel = context.getString(R.string.saldo_atteso_a_fine_mese)
        val add = context.getString(R.string.aggiungi_spesa)
        val openApp = actionStartActivity(Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        val addAction = actionStartActivity(Intent(Intent.ACTION_VIEW, Uri.parse("bucktrail://add?kind=expense"), context, QuickAddActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_NEW_TASK))
        provideContent {
            val ink = DayNight(day = Color(0xFF121614), night = Color(0xFFF1F3EF))
            val smoke = DayNight(day = Color(0xFF5E665F), night = Color(0xFFA3ABA4))
            val bg = DayNight(day = Color(0xFFFFFFFF), night = Color(0xFF171C19))
            val accent = DayNight(day = Color(0xFF1F7A4D), night = Color(0xFF5FD19B))
            Row(GlanceModifier.fillMaxSize().background(bg).cornerRadius(20.dp).padding(14.dp).clickable(openApp), verticalAlignment = Alignment.CenterVertically) {
                Column(GlanceModifier.defaultWeight()) {
                    Text(label, style = TextStyle(color = smoke, fontSize = 12.sp, fontWeight = FontWeight.Medium))
                    if (content.empty) Text(context.getString(R.string.nessun_conto), style = TextStyle(color = ink, fontSize = 18.sp, fontWeight = FontWeight.Bold))
                    else {
                        Text(content.total, style = TextStyle(color = ink, fontSize = 26.sp, fontWeight = FontWeight.Bold), maxLines = 1)
                        Text(expectedLabel + "  " + content.expected, style = TextStyle(color = smoke, fontSize = 12.sp), maxLines = 1)
                    }
                }
                Spacer(GlanceModifier.width(8.dp))
                Text("+", modifier = GlanceModifier.background(accent).cornerRadius(16.dp).padding(horizontal = 14.dp, vertical = 6.dp).clickable(addAction),
                    style = TextStyle(color = DayNight(day = Color.White, night = Color(0xFF0E1210)), fontSize = 22.sp, fontWeight = FontWeight.Bold))
            }
        }
    }
}

class BalanceWidgetReceiver : GlanceAppWidgetReceiver() {
    override val glanceAppWidget: GlanceAppWidget = BalanceWidget()
}
