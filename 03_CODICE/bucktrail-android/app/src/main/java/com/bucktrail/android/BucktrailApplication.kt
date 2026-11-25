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
import com.bucktrail.android.sync.AuthManager
import com.bucktrail.android.sync.HttpSupabaseApi
import com.bucktrail.android.sync.KeystoreSessionStore
import com.bucktrail.android.sync.RoomLocalStore
import com.bucktrail.android.sync.SharedPrefsSyncState
import com.bucktrail.android.sync.SyncEngine
import com.bucktrail.android.sync.SyncService
import com.bucktrail.android.sync.e2e.E2EController
import com.bucktrail.android.sync.e2e.E2EKeyStore
import kotlinx.coroutines.launch
import kotlinx.coroutines.flow.debounce
import kotlinx.coroutines.flow.distinctUntilChanged
import androidx.glance.appwidget.updateAll
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

    // --- Account e sync Supabase (B9). URL e chiave arrivano da BuildConfig: release da SupabaseConfig.swift, debug URL finto salvo -P espliciti. ---
    /** Falso se l'URL o la chiave non sono disponibili al build: l'app resta pienamente locale. */
    val syncConfigured: Boolean get() = BuildConfig.SUPABASE_URL.isNotBlank() && BuildConfig.SUPABASE_ANON_KEY.isNotBlank()
    private val supabaseApi by lazy { HttpSupabaseApi(BuildConfig.SUPABASE_URL, BuildConfig.SUPABASE_ANON_KEY) }
    val auth by lazy { AuthManager(supabaseApi, KeystoreSessionStore(applicationContext)).also { it.bootstrap() } }
    private val syncState by lazy { SharedPrefsSyncState(applicationContext) }
    private val localStore by lazy { RoomLocalStore { database.dao() } }
    private val e2e by lazy {
        if (BuildConfig.E2E_ENABLED) {
            E2EController(supabaseApi, supabaseApi, E2EKeyStore(applicationContext), enabled = true)
        } else {
            null
        }
    }
    val syncService by lazy {
        val engine = SyncEngine(supabaseApi, localStore, syncState, auth,
            onClear = { e2e?.clearLocalData(syncState.lastUserId) },
        )
        SyncService(
            appScope, auth, engine, syncState, localStore,
            syncEnabled = { !repository.isDemo }, e2e = e2e,
        )
    }
    private var syncStarted = false

    /** Avvia (una volta) account e sync: sessione, monitor di rete, ciclo di vita (background = push, foreground = sync). */
    @Synchronized
    fun startSync() {
        if (syncStarted || !syncConfigured) return
        syncStarted = true
        syncService.start()
        syncService.observe(repository.state)
        com.bucktrail.android.sync.NetworkMonitor.start(this) { syncService.onNetwork(it) }
        registerActivityLifecycleCallbacks(object : android.app.Application.ActivityLifecycleCallbacks {
            private var started = 0
            private var firstStart = true
            override fun onActivityStarted(activity: android.app.Activity) {
                if (started++ == 0) { if (firstStart) firstStart = false else appScope.launch { syncService.syncOnForeground() } }
            }
            override fun onActivityStopped(activity: android.app.Activity) {
                if (--started == 0 && !activity.isChangingConfigurations) appScope.launch { syncService.pushOnBackground() }
                else if (started < 0) started = 0
            }
            override fun onActivityCreated(activity: android.app.Activity, savedInstanceState: android.os.Bundle?) = Unit
            override fun onActivityResumed(activity: android.app.Activity) = Unit
            override fun onActivityPaused(activity: android.app.Activity) = Unit
            override fun onActivitySaveInstanceState(activity: android.app.Activity, outState: android.os.Bundle) = Unit
            override fun onActivityDestroyed(activity: android.app.Activity) = Unit
        })
    }

    /**
     * Un movimento scritto fuori dalle schermate (scorciatoia, widget): marcato da caricare (come `markTransactionDirty` iOS) e, se c'è un account,
     * caricato subito prima che il processo venga congelato dal sistema (massimo 5 s; se manca la rete resta in coda per il prossimo avvio).
     */
    suspend fun markTransactionChanged(id: String) {
        runCatching { com.bucktrail.android.shortcuts.BalanceWidget().updateAll(this) }
        if (!syncConfigured) return
        startSync()
        syncState.markDirty(listOf(id), System.currentTimeMillis())
        syncState.hasPendingChanges = true
        if (auth.isLoggedIn) kotlinx.coroutines.withTimeoutOrNull(5_000) { syncService.pushOnBackground() }
    }

    private var widgetsStarted = false

    /** Aggiorna il widget «Saldo» a ogni modifica dei dati reali o della privacy (con un respiro di 1 s). */
    @Synchronized
    @OptIn(kotlinx.coroutines.FlowPreview::class)
    fun startWidgetUpdates() {
        if (widgetsStarted) return
        widgetsStarted = true
        appScope.launch {
            kotlinx.coroutines.flow.combine(repository.state, prefs.state) { l, p ->
                if (l.demo) null else listOf(l.accounts, l.transactions, p.hideBalance, p.appLockEnabled, p.currencyCode)
            }.distinctUntilChanged().debounce(1_000).collect { runCatching { com.bucktrail.android.shortcuts.BalanceWidget().updateAll(this@BucktrailApplication) } }
        }
    }

    private var auditStarted = false

    override fun onCreate() {
        if (BuildConfig.DEBUG) enableStrictMode()
        super.onCreate()
        Notifier.ensureChannel(this)
    }

    /** Solo debug: segnala nel log (tag StrictMode) letture/scritture su disco e rete sul thread principale, e perdite di risorse. */
    private fun enableStrictMode() {
        android.os.StrictMode.setThreadPolicy(
            android.os.StrictMode.ThreadPolicy.Builder().detectAll().penaltyLog().build(),
        )
        android.os.StrictMode.setVmPolicy(
            android.os.StrictMode.VmPolicy.Builder().detectLeakedClosableObjects().detectLeakedSqlLiteObjects()
                .detectActivityLeaks().detectLeakedRegistrationObjects().penaltyLog().build(),
        )
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
