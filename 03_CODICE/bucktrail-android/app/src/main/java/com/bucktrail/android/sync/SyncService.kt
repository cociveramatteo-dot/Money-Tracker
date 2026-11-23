package com.bucktrail.android.sync

import com.bucktrail.android.data.LedgerState
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Job
import kotlinx.coroutines.delay
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableSharedFlow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharedFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asSharedFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.distinctUntilChanged
import kotlinx.coroutines.flow.map
import kotlinx.coroutines.launch
import kotlinx.coroutines.sync.Mutex
import kotlinx.coroutines.sync.withLock
import kotlin.math.min
import kotlin.math.pow

/** Stato pubblico del sync: solo un indicatore silenzioso, mai un errore bloccante (§5.3). */
sealed interface SyncStatus {
    data object Idle : SyncStatus
    data object Syncing : SyncStatus
    data class WaitingForRetry(val attempt: Int) : SyncStatus
    data object Offline : SyncStatus
}

object Backoff {
    const val MAX_SECONDS = 60.0
    /** 2, 4, 8, … fino a 60 secondi. */
    fun seconds(failures: Int): Double = min(2.0.pow(failures), MAX_SECONDS)
}

/**
 * `SyncService` iOS lato Android: coda unica di operazioni, push con debounce 1,5 s, retry con backoff, monitor di rete,
 * pull in foreground con cooldown di 5 minuti. Non fa nulla in modalità demo né senza account.
 */
class SyncService(
    private val scope: CoroutineScope, private val auth: AuthManager, private val engine: SyncEngine, private val state: SyncStateStore,
    private val store: LocalStore, private val syncEnabled: () -> Boolean,
    private val nowMillis: () -> Long = System::currentTimeMillis,
    private val sleep: suspend (Long) -> Unit = { delay(it) },
) {
    private val _status = MutableStateFlow<SyncStatus>(SyncStatus.Idle)
    val status: StateFlow<SyncStatus> = _status.asStateFlow()
    private val _needsDecision = MutableStateFlow(false)
    /** Vero quando serve la scelta «usa i dati del cloud» (dati creati senza account + cloud con altri dati). */
    val needsDecision: StateFlow<Boolean> = _needsDecision.asStateFlow()
    private val _deleteConfirmation = MutableStateFlow<PushResult.NeedsConfirmation?>(null)
    /** Non nulla quando il push cancellerebbe il cloud con DB locale vuoto o in calo anomalo: serve la conferma esplicita dell'utente. */
    val deleteConfirmation: StateFlow<PushResult.NeedsConfirmation?> = _deleteConfirmation.asStateFlow()
    private val _ignoredRows = MutableStateFlow(0)
    /** Righe del cloud ignorate dall'ultimo pull (illeggibili o con importo assurdo): il sync prosegue senza di loro. */
    val ignoredRows: StateFlow<Int> = _ignoredRows.asStateFlow()
    private val _pulled = MutableSharedFlow<Unit>(extraBufferCapacity = 4)
    /** Emette a ogni pull riuscito (poi si materializzano le ricorrenze). */
    val pulled: SharedFlow<Unit> = _pulled.asSharedFlow()

    private val ops = Mutex()
    private var failures = 0
    private var retryJob: Job? = null
    private var debounceJob: Job? = null
    private var sessionJob: Job? = null
    @Volatile private var online = true
    private val watcher = ChangeWatcher()

    private val active: Boolean get() = auth.isLoggedIn && syncEnabled()

    /** Avvia l'ascolto della sessione: accesso o sessione ripristinata -> primo scambio; uscita -> tutto fermo. */
    fun start() {
        if (sessionJob != null) return
        sessionJob = scope.launch {
            auth.session.map { it?.userId }.distinctUntilChanged().collect { userId ->
                if (userId == null) { retryJob?.cancel(); debounceJob?.cancel(); failures = 0; _status.value = SyncStatus.Idle; _needsDecision.value = false; _deleteConfirmation.value = null }
                else if (syncEnabled()) ops.withLock { initialSync() }
            }
        }
    }

    /** Segue i dati locali per accorgersi di cosa è cambiato (equivale a `ModelContext.didSave` + `recordChanges`). */
    fun observe(states: Flow<LedgerState>) = scope.launch {
        states.collect { s ->
            val changed = watcher.onState(s) ?: return@collect
            if (!auth.isLoggedIn || !syncEnabled()) return@collect
            if (changed.isNotEmpty()) state.markDirty(changed, nowMillis())
            schedulePush()
        }
    }

    // ---- operazioni (sempre dentro la coda `ops`) -------------------------------------------------------------

    private suspend fun initialSync(): Boolean {
        if (!active) return false
        _status.value = SyncStatus.Syncing
        watcher.silent = true
        // `afterPull` (nuova base del watcher) resta dentro la finestra «silenziosa»: nessuna modifica del sync diventa un push
        val result = try { engine.syncOnLogin().also { if (it == LoginSyncResult.Pulled) afterPull() } } finally { watcher.silent = false }
        return when (result) {
            LoginSyncResult.Pulled -> { success(); true }
            LoginSyncResult.Pushed -> { success(); true }
            is LoginSyncResult.NeedsDeleteConfirmation -> { askDeleteConfirmation(PushResult.NeedsConfirmation(result.deletions, result.baseline)); false }
            LoginSyncResult.NeedsDecision -> { _needsDecision.value = true; _status.value = SyncStatus.Idle; false }
            LoginSyncResult.Failed -> { failed(); false }
        }
    }

    /** Nessun errore né retry: la scelta spetta all'utente (le modifiche restano in attesa). */
    private fun askDeleteConfirmation(r: PushResult.NeedsConfirmation) {
        retryJob?.cancel()
        state.hasPendingChanges = true
        _deleteConfirmation.value = r
        _status.value = SyncStatus.Idle
    }

    private suspend fun afterPull() {
        _ignoredRows.value = engine.lastIgnoredRows
        watcher.rebase(store.snapshot())
        _pulled.tryEmit(Unit)
    }

    private fun success() { failures = 0; state.hasPendingChanges = false; _status.value = if (online) SyncStatus.Idle else SyncStatus.Offline }

    private fun failed() {
        failures += 1
        state.hasPendingChanges = true
        scheduleRetry()
    }

    private suspend fun pushResilient(): Boolean {
        if (!active) return false
        // primo scambio non ancora avvenuto: non si fa push alla cieca
        if (!engine.canPush(auth.userId!!)) return initialSync()
        _status.value = SyncStatus.Syncing
        return when (val r = engine.pushDetailed()) {
            PushResult.Done -> { _deleteConfirmation.value = null; success(); true }
            PushResult.Failed -> { failed(); false }
            is PushResult.NeedsConfirmation -> { askDeleteConfirmation(r); false }
        }
    }

    /**
     * La scelta dopo `deleteConfirmation`: `delete = true` cancella davvero dal cloud ciò che il dispositivo non ha più;
     * `false` (anche «Annulla») ripristina i dati dal cloud e non cancella nulla.
     */
    suspend fun resolveDeleteConfirmation(delete: Boolean) {
        _deleteConfirmation.value = null
        ops.withLock {
            if (!active) return@withLock
            _status.value = SyncStatus.Syncing
            if (delete) {
                when (engine.pushDetailed(allowDestructive = true)) {
                    PushResult.Done -> success()
                    else -> failed()
                }
            } else if (!pull()) failed()
        }
    }

    private suspend fun pull(): Boolean {
        if (!active) return false
        _status.value = SyncStatus.Syncing
        watcher.silent = true
        return try {
            when (engine.pull()) {
                PullOutcome.Done -> { afterPull(); success(); true }
                PullOutcome.Skipped -> { _status.value = SyncStatus.Idle; false }
                PullOutcome.Failed -> { _status.value = SyncStatus.Idle; false }
            }
        } finally { watcher.silent = false }
    }

    private fun scheduleRetry() {
        retryJob?.cancel()
        _status.value = SyncStatus.WaitingForRetry(failures)
        val wait = (Backoff.seconds(failures) * 1000).toLong()
        retryJob = scope.launch { sleep(wait); ops.withLock { pushResilient() } }
    }

    val shouldPull: Boolean get() = nowMillis() - state.lastPull > PULL_COOLDOWN_MS

    // ---- ingressi pubblici ------------------------------------------------------------------------------------

    /** Ritorno in primo piano: push, poi pull solo se il push è riuscito e il cooldown è scaduto. */
    suspend fun syncOnForeground() = ops.withLock {
        if (!active) return@withLock
        if (pushResilient() && shouldPull) pull()
    }

    /** L'app va in background: carica quanto prima (resiliente). */
    suspend fun pushOnBackground() = ops.withLock { if (active) pushResilient() }

    /** Pull-to-refresh: push e, se riuscito, pull senza cooldown. */
    suspend fun manualRefresh() = ops.withLock {
        if (!active) return@withLock
        if (pushResilient()) pull()
    }

    /** Push con debounce 1,5 s a ogni salvataggio. */
    fun schedulePush() {
        if (!active) return
        state.hasPendingChanges = true
        debounceJob?.cancel()
        debounceJob = scope.launch {
            delay(DEBOUNCE_MS)
            // una modifica appena fatta è un buon motivo per riprovare subito
            failures = 0; retryJob?.cancel()
            ops.withLock { pushResilient() }
        }
    }

    /** La scelta dell'utente dopo `needsDecision`. Annullare = uscire dall'account senza toccare i dati del dispositivo. */
    suspend fun resolveDecision(useCloud: Boolean) {
        _needsDecision.value = false
        if (!useCloud) { auth.signOut(); return }
        ops.withLock {
            _status.value = SyncStatus.Syncing
            watcher.silent = true
            val result = try { engine.syncOnLogin(useCloud = true).also { if (it == LoginSyncResult.Pulled) afterPull() } } finally { watcher.silent = false }
            when (result) {
                LoginSyncResult.Pulled -> success()
                LoginSyncResult.Pushed -> success()
                else -> failed()
            }
        }
    }

    /** Rete assente/ritrovata (callback di `ConnectivityManager`). */
    fun onNetwork(available: Boolean) {
        online = available
        if (!auth.isLoggedIn) return
        if (!available) { _status.value = SyncStatus.Offline; return }
        if (_status.value == SyncStatus.Offline) _status.value = SyncStatus.Idle
        if (state.hasPendingChanges && syncEnabled()) { retryJob?.cancel(); scope.launch { ops.withLock { pushResilient() } } }
    }

    /** Esci: carica le modifiche (resiliente), chiude la sessione, svuota i dati locali (isolamento tra utenti). */
    suspend fun signOutAndClear() {
        ops.withLock { if (active) pushResilient() }
        retryJob?.cancel(); debounceJob?.cancel()
        auth.signOut()
        ops.withLock { engine.clearLocalData(); watcher.rebase(store.snapshot()) }
        failures = 0; _status.value = SyncStatus.Idle
    }

    /** Elimina l'account sul cloud, poi i dati locali, poi esce. Se la RPC fallisce non si tocca nulla. */
    suspend fun deleteAccountAndClear() {
        ops.withLock {
            auth.deleteAccount()
            retryJob?.cancel(); debounceJob?.cancel()
            engine.clearLocalData()
            watcher.rebase(store.snapshot())
        }
        auth.signOut()
        failures = 0; _status.value = SyncStatus.Idle
    }

    companion object {
        const val DEBOUNCE_MS = 1500L
        const val PULL_COOLDOWN_MS = 300_000L
    }
}

/**
 * Confronta le istantanee reattive: ritorna gli id dei movimenti nuovi/modificati (insieme vuoto = cambiò altro, es. un budget),
 * `null` = nessuna modifica (prima istantanea, demo, o modifiche fatte dal sync stesso).
 */
class ChangeWatcher {
    @Volatile var silent = false
    private var tx: Map<String, com.bucktrail.android.data.TransactionEntity>? = null
    private var other: Int = 0
    private var generation = -1

    private fun others(a: List<com.bucktrail.android.data.AccountEntity>, b: List<com.bucktrail.android.data.BudgetEntity>, g: List<com.bucktrail.android.data.GoalEntity>, r: List<com.bucktrail.android.data.RecurringRuleEntity>) =
        listOf(a.toSet(), b.toSet(), g.toSet(), r.toSet()).hashCode()

    @Synchronized
    fun onState(s: LedgerState): Set<String>? {
        if (s.demo) { tx = null; return null }
        val map = s.transactions.associateBy { it.id }
        val o = others(s.accounts, s.budgets, s.goals, s.rules)
        val before = tx
        if (before == null || s.generation != generation || silent) { tx = map; other = o; generation = s.generation; return null }
        val changed = map.filter { (id, t) -> before[id] != t }.keys
        val removed = before.keys.any { it !in map }
        val otherChanged = o != other
        tx = map; other = o
        return if (changed.isNotEmpty() || removed || otherChanged) changed else null
    }

    /** Dopo un pull/pulizia: i dati attuali sono la nuova base (nessuna modifica «utente» da inseguire). */
    @Synchronized
    fun rebase(snapshot: Snapshot) {
        tx = snapshot.transactions.associateBy { it.id }
        other = others(snapshot.accounts, snapshot.budgets, snapshot.goals, snapshot.rules)
    }
}
