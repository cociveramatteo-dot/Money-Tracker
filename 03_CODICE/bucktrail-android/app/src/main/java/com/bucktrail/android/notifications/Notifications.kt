package com.bucktrail.android.notifications

import android.Manifest
import android.app.AlarmManager
import android.app.NotificationChannel
import android.app.NotificationManager
import android.app.PendingIntent
import android.content.BroadcastReceiver
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Build
import androidx.core.app.NotificationCompat
import androidx.core.app.NotificationManagerCompat
import androidx.core.content.ContextCompat
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.MainActivity
import com.bucktrail.android.R
import com.bucktrail.android.data.LedgerState
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.NotificationRules
import com.bucktrail.android.ui.categoryLabel
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.YearMonth
import java.time.ZoneId

/** Testo localizzato di ogni avviso (§5.5); costruito alla consegna, quindi segue la lingua del momento. */
object NotificationTexts {
    enum class Kind { BudgetNear, BudgetOver, Fixed, Goal, Balance, Report }
    class Content(val title: String, val body: String)

    /** `name` = nome budget/obiettivo/conto, `number` = percentuale (budget) o quantità (fisse). */
    fun build(context: Context, kind: Kind, name: String = "", number: Int = 0): Content = when (kind) {
        Kind.BudgetNear -> Content(context.getString(R.string.notif_budget_near_title), context.getString(R.string.notif_budget_near_body, name, number))
        Kind.BudgetOver -> Content(context.getString(R.string.notif_budget_over_title), context.getString(R.string.notif_budget_over_body, name))
        Kind.Fixed -> Content(
            context.getString(R.string.notif_fixed_title),
            if (number == 1) context.getString(R.string.notif_fixed_one) else context.getString(R.string.notif_fixed_many, number),
        )
        Kind.Goal -> Content(context.getString(R.string.notif_goal_title), context.getString(R.string.notif_goal_body, name))
        Kind.Balance -> Content(context.getString(R.string.notif_balance_title), context.getString(R.string.notif_balance_body, name))
        Kind.Report -> Content(context.getString(R.string.notif_report_title), context.getString(R.string.notif_report_body))
    }
}

object Notifier {
    const val CHANNEL = "alerts"

    /** Canale «Avvisi» (importanza predefinita). */
    fun ensureChannel(context: Context) {
        if (Build.VERSION.SDK_INT < 26) return
        val manager = context.getSystemService(NotificationManager::class.java)
        manager.createNotificationChannel(NotificationChannel(CHANNEL, context.getString(R.string.notif_channel_name), NotificationManager.IMPORTANCE_DEFAULT))
    }

    /** Permesso `POST_NOTIFICATIONS` (solo Android 13+) concesso e notifiche non bloccate. */
    fun canPost(context: Context): Boolean =
        (Build.VERSION.SDK_INT < 33 || ContextCompat.checkSelfPermission(context, Manifest.permission.POST_NOTIFICATIONS) == PackageManager.PERMISSION_GRANTED) &&
            NotificationManagerCompat.from(context).areNotificationsEnabled()

    /** Pubblica (o sostituisce, a parità di `id`) la notifica; senza permesso non fa nulla. */
    @android.annotation.SuppressLint("MissingPermission")
    fun post(context: Context, id: String, content: NotificationTexts.Content) {
        if (!canPost(context)) return
        ensureChannel(context)
        val open = PendingIntent.getActivity(
            context, 0, Intent(context, MainActivity::class.java).addFlags(Intent.FLAG_ACTIVITY_SINGLE_TOP or Intent.FLAG_ACTIVITY_CLEAR_TOP),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )
        val n = NotificationCompat.Builder(context, CHANNEL)
            .setSmallIcon(R.drawable.ic_stat_bucktrail).setContentTitle(content.title).setContentText(content.body)
            .setStyle(NotificationCompat.BigTextStyle().bigText(content.body))
            .setAutoCancel(true).setContentIntent(open).setPriority(NotificationCompat.PRIORITY_DEFAULT).build()
        NotificationManagerCompat.from(context).notify(id, 0, n)
    }
}

/**
 * Pianificazione degli avvisi (§5.5). Immediati (budget dopo 2 s, saldo dopo 1 s) con un ritardo in-process;
 * programmati (fisse 1° del mese 09:00, report 1° alle 10:00, obiettivo 7 giorni prima) con `AlarmManager`
 * (`setAndAllowWhileIdle`: nessun permesso di sveglie esatte) e ripianificati all'avvio e dopo il riavvio del telefono.
 */
class NotificationScheduler(private val app: Context, private val scope: CoroutineScope) {
    private val alarms get() = app.getSystemService(AlarmManager::class.java)
    private val pending = HashMap<String, Job>()

    private fun pendingIntent(id: String, kind: String, name: String = "", number: Int = 0): PendingIntent =
        PendingIntent.getBroadcast(
            app, 0,
            Intent(app, ReminderReceiver::class.java).setData(Uri.parse("bucktrail://alarm/$id")).putExtra(ReminderReceiver.EXTRA_ID, id)
                .putExtra(ReminderReceiver.EXTRA_KIND, kind).putExtra(ReminderReceiver.EXTRA_NAME, name).putExtra(ReminderReceiver.EXTRA_NUMBER, number),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_UPDATE_CURRENT,
        )

    private fun cancelAlarm(id: String) {
        val pi = PendingIntent.getBroadcast(
            app, 0, Intent(app, ReminderReceiver::class.java).setData(Uri.parse("bucktrail://alarm/$id")),
            PendingIntent.FLAG_IMMUTABLE or PendingIntent.FLAG_NO_CREATE,
        ) ?: return
        alarms.cancel(pi); pi.cancel()
    }

    private fun setAlarm(id: String, at: Instant, kind: String, name: String = "", number: Int = 0) {
        alarms.setAndAllowWhileIdle(AlarmManager.RTC_WAKEUP, at.toEpochMilli(), pendingIntent(id, kind, name, number))
    }

    /** Tutti gli avvisi pendenti (ordine di iOS `cancelAll`): immediati, fisse, report e obiettivi con scadenza. */
    fun cancelAll(goalIds: Collection<String>) {
        pending.values.forEach { it.cancel() }; pending.clear()
        cancelAlarm(NotificationRules.ID_FIXED); cancelAlarm(NotificationRules.ID_MONTHLY_REPORT)
        goalIds.forEach { cancelAlarm(NotificationRules.goalId(it)) }
    }

    private fun postLater(id: String, delayMs: Long, build: () -> NotificationTexts.Content) {
        pending.remove(id)?.cancel()
        pending[id] = scope.launch { delay(delayMs); Notifier.post(app, id, build()); pending.remove(id) }
    }

    /** Dopo una Uscita fatta: avvisa per ogni budget del mese all'80% o oltre. */
    suspend fun checkBudgets(ledger: LedgerState, month: YearMonth, zone: ZoneId) {
        val alerts = NotificationRules.budgetAlerts(ledger.budgets.map { it.toData() }, ledger.transactionData, month, zone)
        for (a in alerts) {
            val name = if (a.categoryRaw == "Tutti") ledger.accounts.firstOrNull { it.id == a.accountId }?.name ?: app.getString(R.string.budget)
            else a.categoryRaw.split(",").joinToString(" + ") { categoryLabel(it, app.resources) }
            val id = NotificationRules.budgetId(a.budgetId)
            postLater(id, NotificationRules.BUDGET_DELAY_MS) {
                if (a.exceeded) NotificationTexts.build(app, NotificationTexts.Kind.BudgetOver, name)
                else NotificationTexts.build(app, NotificationTexts.Kind.BudgetNear, name, a.percent)
            }
        }
    }

    /** Saldo sotto la soglia del conto: avviso dopo 1 s; sopra la soglia cancella l'eventuale avviso in attesa. */
    fun checkBalance(accountId: String, accountName: String, below: Boolean) {
        val id = NotificationRules.balanceId(accountId)
        pending.remove(id)?.cancel()
        if (below) postLater(id, NotificationRules.BALANCE_DELAY_MS) { NotificationTexts.build(app, NotificationTexts.Kind.Balance, accountName) }
    }

    fun scheduleFixed(pendingCount: Int, now: java.time.ZonedDateTime = java.time.ZonedDateTime.now()) {
        cancelAlarm(NotificationRules.ID_FIXED)
        if (pendingCount <= 0) return
        setAlarm(NotificationRules.ID_FIXED, NotificationRules.nextMonthly(now, NotificationRules.FIXED_HOUR).toInstant(), "fixed", number = pendingCount)
    }

    fun scheduleMonthlyReport(enabled: Boolean, now: java.time.ZonedDateTime = java.time.ZonedDateTime.now()) {
        cancelAlarm(NotificationRules.ID_MONTHLY_REPORT)
        if (!enabled) return
        setAlarm(NotificationRules.ID_MONTHLY_REPORT, NotificationRules.nextMonthly(now, NotificationRules.REPORT_HOUR).toInstant(), "report")
    }

    fun scheduleGoal(goalId: String, name: String, deadlineMillis: Long, zone: ZoneId = ZoneId.systemDefault()) {
        val id = NotificationRules.goalId(goalId)
        cancelAlarm(id)
        val at = NotificationRules.goalReminderAt(Instant.ofEpochMilli(deadlineMillis), Instant.now(), zone) ?: return
        setAlarm(id, at, "goal", name)
    }

    fun cancelGoal(goalId: String) = cancelAlarm(NotificationRules.goalId(goalId))

    /** Riallinea le sveglie programmate ai dati attuali (avvio app, riavvio telefono). */
    fun rescheduleAll(ledger: LedgerState, monthlyReport: Boolean, zone: ZoneId = ZoneId.systemDefault()) {
        scheduleFixed(NotificationRules.fixedPending(ledger.transactionData, YearMonth.now(zone), zone))
        scheduleMonthlyReport(monthlyReport)
        ledger.goals.forEach { g -> if (g.deadline != null) scheduleGoal(g.id, g.name, g.deadline) else cancelGoal(g.id) }
    }
}

/** Consegna dell'avviso all'ora programmata; per i ricorrenti ripianifica il prossimo 1° del mese. */
class ReminderReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val id = intent.getStringExtra(EXTRA_ID) ?: return
        val name = intent.getStringExtra(EXTRA_NAME).orEmpty()
        val number = intent.getIntExtra(EXTRA_NUMBER, 0)
        val app = context.applicationContext as BucktrailApplication
        when (intent.getStringExtra(EXTRA_KIND)) {
            "fixed" -> { Notifier.post(context, id, NotificationTexts.build(context, NotificationTexts.Kind.Fixed, number = number)); app.notifications.scheduleFixed(number) }
            "report" -> { Notifier.post(context, id, NotificationTexts.build(context, NotificationTexts.Kind.Report)); app.notifications.scheduleMonthlyReport(true) }
            "goal" -> Notifier.post(context, id, NotificationTexts.build(context, NotificationTexts.Kind.Goal, name))
        }
    }

    companion object {
        const val EXTRA_ID = "id"; const val EXTRA_KIND = "kind"; const val EXTRA_NAME = "name"; const val EXTRA_NUMBER = "number"
    }
}

/** Dopo il riavvio le sveglie sono perse: le ricrea dai dati e dalle preferenze. */
class BootReceiver : BroadcastReceiver() {
    override fun onReceive(context: Context, intent: Intent) {
        val app = context.applicationContext as BucktrailApplication
        val result = goAsync()
        app.appScope.launch {
            try {
                val prefs = app.prefs.state.first()
                // In demo non si programma nulla: gli avvisi riguardano solo i dati reali.
                if (prefs.notificationsEnabled && !app.repository.isDemo) app.notifications.rescheduleAll(app.repository.snapshot(), prefs.monthlyReportEnabled)
            } finally { result.finish() }
        }
    }
}
