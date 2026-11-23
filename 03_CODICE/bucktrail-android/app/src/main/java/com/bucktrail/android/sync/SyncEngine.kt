package com.bucktrail.android.sync

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity

/** Stato di sync persistito (UserDefaults iOS: `syncService.*`). */
interface SyncStateStore {
    /** Ultimo utente i cui dati stanno sul dispositivo (isolamento multi-utente). */
    var lastUserId: String?
    /**
     * Utente per cui è già avvenuto un primo scambio riuscito (pull completo, o primo push con cloud vuoto).
     * **Finché non coincide con l'utente di sessione nessun push è permesso** (mai push con DB vuoto/parziale prima di un pull riuscito).
     */
    var syncedUserId: String?
    var lastPull: Long
    var hasPendingChanges: Boolean
    /** Movimenti creati/modificati non ancora caricati: id -> istante della marcatura. */
    fun dirty(): Map<String, Long>
    fun markDirty(ids: Collection<String>, stamp: Long)
    /** Toglie solo gli id la cui marcatura è ancora quella vista all'inizio del push (una modifica successiva resta in coda). */
    fun clearDirty(uploaded: Map<String, Long>)
    fun reset()
}

/** Accesso al database locale reale (mai la demo). */
interface LocalStore {
    suspend fun snapshot(): Snapshot
    /** Applica tutto in un'unica transazione: o tutto o niente. */
    suspend fun apply(plan: SyncPlan)
    /** `clearLocalData`: movimenti, regole, budget, obiettivi, conti (le categorie restano). */
    suspend fun clear()
}

enum class PullOutcome { Done, Skipped, Failed }

sealed interface LoginSyncResult {
    data object Pushed : LoginSyncResult
    data object Pulled : LoginSyncResult
    /** Il dispositivo ha già dati creati senza account e il cloud ne ha altri: serve la scelta dell'utente. */
    data object NeedsDecision : LoginSyncResult
    data object Failed : LoginSyncResult
}

/**
 * Cuore del sync (`SyncService` iOS §5.3): push, pull, primo scambio al login. Puro rispetto ad Android
 * (testato con un `SupabaseApi` finto). Regole di sicurezza: nessun push prima di un pull riuscito; il pull
 * non cancella nulla se il remoto è vuoto ma il locale no; tutto il locale si applica in una sola transazione.
 */
class SyncEngine(
    private val api: SupabaseApi, private val store: LocalStore, private val state: SyncStateStore,
    private val auth: AuthGateway, private val nowMillis: () -> Long = System::currentTimeMillis,
    private val chunk: Int = 500,
) {
    /** Ponte verso `AuthManager` (nei test: finto con un token fisso). */
    interface AuthGateway {
        val userId: String?
        suspend fun <T> authed(block: suspend (token: String) -> T): T
    }

    /** Il push è consentito solo dopo il primo scambio riuscito per questo utente. */
    fun canPush(userId: String): Boolean = state.syncedUserId == userId

    /** `true` solo se il push è arrivato in fondo senza errori. */
    suspend fun push(): Boolean {
        val userId = auth.userId ?: return false
        if (!canPush(userId)) return false
        return try { pushInternal(userId); true } catch (e: Exception) { false }
    }

    private suspend fun pushInternal(userId: String) {
        // prima le marcature, poi la lettura: una modifica arrivata dopo resta in coda (la sua marcatura cambia)
        val dirtyAtStart = state.dirty()
        val snap = store.snapshot()
        auth.authed { token ->
            upload("mt_accounts", snap.accounts.map { SyncMapper.accountRow(it, userId) }, token)
            deleteOrphans("mt_accounts", userId, snap.accounts.map { it.id }.toSet(), token, remoteIds = null)

            // movimenti: i «sporchi» + quelli che il cloud non ha (una marcatura persa non deve mai far cancellare un movimento al pull)
            val remoteTx = fetchIds("mt_transactions", userId, token)
            val toUpload = snap.transactions.filter { it.id in dirtyAtStart || it.id !in remoteTx }
            upload("mt_transactions", toUpload.map { SyncMapper.transactionRow(it, userId) }, token)
            state.clearDirty(dirtyAtStart.filterKeys { id -> toUpload.any { it.id == id } })
            deleteOrphans("mt_transactions", userId, snap.transactions.map { it.id }.toSet(), token, remoteIds = remoteTx)

            upload("mt_budgets", snap.budgets.map { SyncMapper.budgetRow(it, userId) }, token)
            deleteOrphans("mt_budgets", userId, snap.budgets.map { it.id }.toSet(), token, remoteIds = null)
            upload("mt_goals", snap.goals.map { SyncMapper.goalRow(it, userId) }, token)
            deleteOrphans("mt_goals", userId, snap.goals.map { it.id }.toSet(), token, remoteIds = null)
            upload("mt_recurring_rules", snap.rules.map { SyncMapper.ruleRow(it, userId) }, token)
            deleteOrphans("mt_recurring_rules", userId, snap.rules.map { it.id }.toSet(), token, remoteIds = null)
        }
    }

    private suspend fun upload(table: String, rows: List<kotlinx.serialization.json.JsonObject>, token: String) {
        rows.chunked(chunk).forEach { api.upsert(table, it, token) }
    }

    private suspend fun fetchIds(table: String, userId: String, token: String): Set<String> =
        api.selectAll(table, userId, token, "id").map { o ->
            (o["id"] as? kotlinx.serialization.json.JsonPrimitive)?.content?.lowercase() ?: throw SyncFormatException("id mancante")
        }.toSet()

    /** Una sola richiesta di cancellazione per i record remoti assenti in locale. */
    private suspend fun deleteOrphans(table: String, userId: String, localIds: Set<String>, token: String, remoteIds: Set<String>?) {
        val remote = remoteIds ?: fetchIds(table, userId, token)
        val orphans = remote - localIds
        if (orphans.isNotEmpty()) api.deleteIn(table, orphans.map { it.uppercase() }, userId, token)
    }

    /** Scarica tutto, calcola le modifiche e le applica in un'unica transazione. */
    suspend fun pull(): PullOutcome {
        val userId = auth.userId ?: return PullOutcome.Failed
        return try {
            val remote = auth.authed { token ->
                val accounts = api.selectAll("mt_accounts", userId, token).map(SyncMapper::account)
                // remoto senza conti: le altre tabelle non contano (la guardia del merge impedisce di cancellare il locale)
                if (accounts.isEmpty()) return@authed Snapshot()
                Snapshot(
                    accounts, api.selectAll("mt_transactions", userId, token).map(SyncMapper::transaction),
                    api.selectAll("mt_budgets", userId, token).map(SyncMapper::budget), api.selectAll("mt_goals", userId, token).map(SyncMapper::goal),
                    api.selectAll("mt_recurring_rules", userId, token).map(SyncMapper::rule),
                )
            }
            // il locale si legge DOPO le richieste: nessuna finestra in cui una modifica nuova sembri «assente sul remoto»
            val local = store.snapshot()
            val plan = SyncMerge.plan(local, remote, state.dirty().keys) ?: return PullOutcome.Skipped
            if (!plan.isEmpty) store.apply(plan)
            state.lastPull = nowMillis()
            PullOutcome.Done
        } catch (e: Exception) {
            PullOutcome.Failed
        }
    }

    /**
     * Primo scambio dopo l'accesso. `useCloud` = scelta dell'utente quando il dispositivo ha dati creati senza account
     * e il cloud ne ha altri: i dati del dispositivo vengono sostituiti da quelli del cloud.
     */
    suspend fun syncOnLogin(useCloud: Boolean = false): LoginSyncResult {
        val userId = auth.userId ?: return LoginSyncResult.Failed
        val previousUser = state.lastUserId
        // isolamento multi-utente: dati di un altro utente non restano mai
        if (previousUser != null && previousUser != userId) {
            runCatching { store.clear() }.onFailure { return LoginSyncResult.Failed }
            state.syncedUserId = null
            state.clearDirty(state.dirty())
            state.hasPendingChanges = false
        }
        // sessione ripresa dopo un primo scambio già riuscito: prima si caricano le modifiche locali, poi si scarica
        if (canPush(userId)) {
            state.lastUserId = userId
            if (!push()) return LoginSyncResult.Failed
            return if (pull() == PullOutcome.Done) LoginSyncResult.Pulled else LoginSyncResult.Pushed
        }
        val remoteIds = try {
            auth.authed { fetchIds("mt_accounts", userId, it) }
        } catch (e: Exception) {
            // iOS ripiega sul push; qui mai: senza sapere cosa c'è sul cloud non si scrive (il primo scambio non è ancora avvenuto)
            return LoginSyncResult.Failed
        }
        val local = store.snapshot()
        if (remoteIds.isEmpty()) {
            // nuovo utente o primo dispositivo: i dati locali vanno sul cloud
            state.lastUserId = userId
            state.syncedUserId = userId
            return if (push()) LoginSyncResult.Pushed else { state.syncedUserId = null; LoginSyncResult.Failed }
        }
        val anonymousLocal = previousUser == null && !local.isEmpty
        if (anonymousLocal && !useCloud) return LoginSyncResult.NeedsDecision
        if (anonymousLocal) runCatching { store.clear() }.onFailure { return LoginSyncResult.Failed }
        state.lastUserId = userId
        return when (pull()) {
            PullOutcome.Done -> { state.syncedUserId = userId; LoginSyncResult.Pulled }
            else -> LoginSyncResult.Failed
        }
    }

    /** Logout: svuota i dati dell'utente e lo stato di sync (come `clearLocalData` iOS). */
    suspend fun clearLocalData() {
        store.clear()
        state.lastPull = 0
        state.syncedUserId = null
        state.lastUserId = null
        state.clearDirty(state.dirty())
        state.hasPendingChanges = false
    }
}
