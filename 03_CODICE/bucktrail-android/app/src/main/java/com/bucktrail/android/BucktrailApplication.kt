package com.bucktrail.android

import android.app.Application
import androidx.room.Room
import com.bucktrail.android.data.AppPrefs
import com.bucktrail.android.data.AuditLog
import com.bucktrail.android.data.AuditTracker
import com.bucktrail.android.data.DemoSeeder
import com.bucktrail.android.data.Migration2To3
import com.bucktrail.android.data.Repository
import com.bucktrail.android.data.migration1To2
import com.bucktrail.android.notifications.NotificationScheduler
import com.bucktrail.android.notifications.Notifier
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.SupervisorJob
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.io.File

class BucktrailApplication : Application() {
    /** Ambito dell'app: avvisi in ritardo, registro modifiche, semina demo. */
    val appScope = CoroutineScope(SupervisorJob() + Dispatchers.Default)

    val database by lazy {
        Room.databaseBuilder(applicationContext, BucktrailDatabase::class.java, BucktrailDatabase.NAME)
            .addMigrations(migration1To2, Migration2To3.migration).build()
    }
    /** Database separato della modalità demo (§4.12): i dati reali non si toccano mai. */
    val demoDatabase by lazy { Room.databaseBuilder(applicationContext, BucktrailDatabase::class.java, "bucktrail-demo.db").build() }
    val prefs by lazy { AppPrefs(applicationContext) }
    val repository by lazy {
        val demo = runBlocking { prefs.state.first().demoModeEnabled }
        Repository((if (demo) demoDatabase else database).dao(), demo)
    }
    val auditLog by lazy { AuditLog(File(filesDir, "audit-log.jsonl")) }
    val notifications by lazy { NotificationScheduler(applicationContext, appScope) }

    private var auditStarted = false

    override fun onCreate() {
        super.onCreate()
        Notifier.ensureChannel(this)
    }

    /** Avvia (una volta) la cronologia modifiche sui dati reali. */
    @Synchronized
    fun startAudit() {
        if (auditStarted) return
        auditStarted = true
        AuditTracker(auditLog).start(appScope, repository.state)
    }

    /** Testo localizzato di un dato demo (`demo.tx.gym` → risorsa `demo_tx_gym`). */
    fun demoName(key: String): String {
        val id = resources.getIdentifier("demo_" + key.replace('.', '_'), "string", packageName)
        return if (id != 0) getString(id) else key
    }

    /** Dati di partenza: categorie, e in demo l'intero set dimostrativo. */
    suspend fun prepareData() {
        if (repository.isDemo) DemoSeeder.seedIfNeeded(repository.dao, prefs, ::demoName) else repository.seed()
    }

    /** Entra o esce dalla modalità demo senza riavviare: cambia il database attivo. */
    suspend fun setDemoMode(enabled: Boolean) {
        if (enabled) {
            DemoSeeder.seedIfNeeded(demoDatabase.dao(), prefs, ::demoName)
            repository.switchTo(demoDatabase.dao(), true)
        } else {
            database.dao().let { repository.switchTo(it, false) }
        }
        prefs.setDemoMode(enabled)
    }
}
