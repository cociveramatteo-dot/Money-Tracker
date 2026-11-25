package com.bucktrail.android.sync

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.sync.e2e.VaultKind

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
    /** Record sincronizzati all'ultimo scambio riuscito (push o pull): base della guardia «calo anomalo». -1 = sconosciuto. */
    var lastSyncedCount: Int
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

/**
 * Esito del push. `NeedsConfirmation`: il push cancellerebbe `deletions` record dal cloud (su `baseline` noti) con il database
 * locale vuoto o in calo anomalo: non si cancella nulla finché l'utente non conferma.
 */
sealed interface PushResult {
    data object Done : PushResult
    data object Failed : PushResult
    data class NeedsConfirmation(val deletions: Int, val baseline: Int) : PushResult
}

/** Guardia «mai cancellare il cloud per errore»: pura, testata a parte. */
object DeletionGuard {
    /** Sotto questa base un calo non è «anomalo» (con pochi record ogni eliminazione pesa molto). */
    const val MIN_BASELINE = 10

    /**
     * `true` se servono conferme: ci sarebbero cancellazioni sul cloud e il locale è vuoto, oppure è sceso sotto metà
     * dei record dell'ultimo stato sincronizzato (`baseline`).
     */
    fun requiresConfirmation(deletions: Int, localCount: Int, baseline: Int): Boolean {
        if (deletions <= 0) return false
        if (localCount == 0) return true
        return baseline >= MIN_BASELINE && localCount * 2 < baseline
    }
}

sealed interface LoginSyncResult {
    data object Pushed : LoginSyncResult
    data object Pulled : LoginSyncResult
    /** Il dispositivo ha già dati creati senza account e il cloud ne ha altri: serve la scelta dell'utente. */
    data object NeedsDecision : LoginSyncResult
    data object Failed : LoginSyncResult
    /** Sessione ripresa, ma il push cancellerebbe il cloud con DB locale vuoto o in calo anomalo: serve la conferma dell'utente. */
    data class NeedsDeleteConfirmation(val deletions: Int, val baseline: Int) : LoginSyncResult
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
    private val onClear: (String?) -> Unit = {},
    private val completeSnapshot: Boolean = false,
) {
    /** Ponte verso `AuthManager` (nei test: finto con un token fisso). */
    interface AuthGateway {
        val userId: String?
        suspend fun <T> authed(block: suspend (token: String) -> T): T
    }

    /** Un trasporto per tutta l'operazione, legato alla sessione che ha risolto il gate. */
    internal fun using(
        api: SupabaseApi, owner: String, completeSnapshot: Boolean = false, batchSize: Int = chunk,
    ): SyncEngine {
        val scopedAuth = object : AuthGateway {
            override val userId: String? get() = auth.userId?.takeIf { it == owner }
            override suspend fun <T> authed(block: suspend (String) -> T): T = auth.authed { token ->
                if (userId == null) throw NotSignedInException()
                block(token).also { if (userId == null) throw NotSignedInException() }
            }
        }
        return SyncEngine(api, store, state, scopedAuth, nowMillis, batchSize, onClear, completeSnapshot)
    }

    /** Il push è consentito solo dopo il primo scambio riuscito per questo utente. */
    fun canPush(userId: String): Boolean = state.syncedUserId == userId

    /** Righe remote ignorate dall'ultimo pull perché illeggibili o con importo assurdo (0 = tutte buone). */
    @Volatile var lastIgnoredRows: Int = 0
        private set

    /** `true` solo se il push è arrivato in fondo senza errori (una richiesta di conferma NON è un successo). */
    suspend fun push(allowDestructive: Boolean = false): Boolean = pushDetailed(allowDestructive) is PushResult.Done

    suspend fun pushDetailed(allowDestructive: Boolean = false): PushResult {
        val userId = auth.userId ?: return PushResult.Failed
        if (!canPush(userId)) return PushResult.Failed
        return try { pushInternal(userId, allowDestructive) } catch (e: Exception) { PushResult.Failed }
    }

    /** Usa una copia immutabile e conserva le marcature che serviranno dopo il cambio di modalità. */
    internal suspend fun pushMigration(
        snapshot: Snapshot, allTransactions: Boolean, pruneOrphans: Boolean, allowDestructive: Boolean,
    ): PushResult = pushInternal(
        auth.userId ?: throw NotSignedInException(), allowDestructive, snapshot, allTransactions, pruneOrphans,
    )

    private suspend fun pushInternal(
        userId: String, allowDestructive: Boolean, frozen: Snapshot? = null, allTransactions: Boolean = false,
        pruneOrphans: Boolean = true,
    ): PushResult {
        // prima le marcature, poi la lettura: una modifica arrivata dopo resta in coda (la sua marcatura cambia)
        val dirtyAtStart = state.dirty()
        val snap = frozen ?: store.snapshot()
        val tables = listOf(
            "mt_accounts" to snap.accounts.map { it.id }.toSet(), "mt_transactions" to snap.transactions.map { it.id }.toSet(),
            "mt_budgets" to snap.budgets.map { it.id }.toSet(), "mt_goals" to snap.goals.map { it.id }.toSet(),
            "mt_recurring_rules" to snap.rules.map { it.id }.toSet(),
        )
        return auth.authed<PushResult> { token ->
            // guardia: prima di scrivere o cancellare qualsiasi cosa si sa quanto verrebbe cancellato dal cloud
            val remoteIdsByTable = tables.associate { (t, _) -> t to fetchIds(t, userId, token) }
            val deletions = if (pruneOrphans) tables.sumOf { (t, local) -> (remoteIdsByTable.getValue(t) - local).size } else 0
            val baseline = state.lastSyncedCount.takeIf { it >= 0 } ?: remoteIdsByTable.values.sumOf { it.size }
            if (!allowDestructive && DeletionGuard.requiresConfirmation(deletions, snap.count, baseline)) {
                return@authed PushResult.NeedsConfirmation(deletions, baseline)
            }
            upload("mt_accounts", snap.accounts.map { SyncMapper.accountRow(it, userId) }, token)
            if (pruneOrphans) deleteOrphans("mt_accounts", userId, snap.accounts.map { it.id }.toSet(), token, remoteIdsByTable.getValue("mt_accounts"))

            // movimenti: i «sporchi» + quelli che il cloud non ha (una marcatura persa non deve mai far cancellare un movimento al pull)
            val remoteTx = remoteIdsByTable.getValue("mt_transactions")
            val toUpload = snap.transactions.filter { allTransactions || it.id in dirtyAtStart || it.id !in remoteTx }
            upload("mt_transactions", toUpload.map { SyncMapper.transactionRow(it, userId) }, token)
            if (frozen == null) state.clearDirty(dirtyAtStart.filterKeys { id -> toUpload.any { it.id == id } })
            if (pruneOrphans) deleteOrphans("mt_transactions", userId, snap.transactions.map { it.id }.toSet(), token, remoteTx)

            upload("mt_budgets", snap.budgets.map { SyncMapper.budgetRow(it, userId) }, token)
            if (pruneOrphans) deleteOrphans("mt_budgets", userId, snap.budgets.map { it.id }.toSet(), token, remoteIdsByTable.getValue("mt_budgets"))
            upload("mt_goals", snap.goals.map { SyncMapper.goalRow(it, userId) }, token)
            if (pruneOrphans) deleteOrphans("mt_goals", userId, snap.goals.map { it.id }.toSet(), token, remoteIdsByTable.getValue("mt_goals"))
            upload("mt_recurring_rules", snap.rules.map { SyncMapper.ruleRow(it, userId) }, token)
            if (pruneOrphans) deleteOrphans("mt_recurring_rules", userId, snap.rules.map { it.id }.toSet(), token, remoteIdsByTable.getValue("mt_recurring_rules"))
            if (frozen == null) state.lastSyncedCount = snap.count
            PushResult.Done
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
    private suspend fun deleteOrphans(table: String, userId: String, localIds: Set<String>, token: String, remoteIds: Set<String>) {
        val orphans = remoteIds - localIds
        if (orphans.isNotEmpty()) api.deleteIn(table, orphans.map { it.uppercase() }, userId, token)
    }

    /** Scarica tutto, calcola le modifiche e le applica in un'unica transazione. */
    suspend fun pull(): PullOutcome {
        val userId = auth.userId ?: return PullOutcome.Failed
        return try {
            val (remote, ignored) = auth.authed { token ->
                val accounts = decode(api.selectAll("mt_accounts", userId, token), SyncMapper::account)
                // remoto senza conti: le altre tabelle non contano (la guardia del merge impedisce di cancellare il locale)
                if (!completeSnapshot && accounts.items.isEmpty() && accounts.ignored.isEmpty()) return@authed Snapshot() to IgnoredIds()
                val tx = decode(api.selectAll("mt_transactions", userId, token), SyncMapper::transaction)
                val budgets = decode(api.selectAll("mt_budgets", userId, token), SyncMapper::budget)
                val goals = decode(api.selectAll("mt_goals", userId, token), SyncMapper::goal)
                val rules = decode(api.selectAll("mt_recurring_rules", userId, token), SyncMapper::rule)
                Snapshot(accounts.items, tx.items, budgets.items, goals.items, rules.items) to
                    IgnoredIds(accounts.ignored, tx.ignored, budgets.ignored, goals.ignored, rules.ignored)
            }
            // il locale si legge DOPO le richieste: nessuna finestra in cui una modifica nuova sembri «assente sul remoto»
            val local = store.snapshot()
            val plan = SyncMerge.plan(local, remote, state.dirty().keys, ignored) ?: return PullOutcome.Skipped
            if (!plan.isEmpty) store.apply(plan)
            lastIgnoredRows = ignored.count
            state.lastSyncedCount = if (plan.isEmpty) local.count else store.snapshot().count
            state.lastPull = nowMillis()
            PullOutcome.Done
        } catch (e: Exception) {
            PullOutcome.Failed
        }
    }

    private class Decoded<T>(val items: List<T>, val ignored: Set<String>)

    /**
     * Decodifica riga per riga: una riga illeggibile o con importo assurdo viene ignorata (e il suo id ricordato perché
     * il merge non cancelli la copia locale), il resto del pull prosegue.
     */
    private fun <T> decode(rows: List<kotlinx.serialization.json.JsonObject>, f: (kotlinx.serialization.json.JsonObject) -> T): Decoded<T> {
        val ok = ArrayList<T>(rows.size)
        val bad = HashSet<String>()
        for (row in rows) {
            try { ok += f(row) } catch (e: Exception) {
                val id = (row["id"] as? kotlinx.serialization.json.JsonPrimitive)?.takeIf { it.isString }?.content?.lowercase()
                bad += id ?: "?${bad.size}" // senza id non si può proteggere nulla, ma la riga conta come ignorata
            }
        }
        return Decoded(ok, bad)
    }

    /**
     * Primo scambio dopo l'accesso. `useCloud` = scelta dell'utente quando il dispositivo ha dati creati senza account
     * e il cloud ne ha altri: i dati del dispositivo vengono sostituiti da quelli del cloud.
     */
    suspend fun syncOnLogin(useCloud: Boolean = false): LoginSyncResult = syncOnLogin(useCloud, fresh = false)

    internal suspend fun syncOnLogin(useCloud: Boolean, fresh: Boolean): LoginSyncResult {
        val userId = auth.userId ?: return LoginSyncResult.Failed
        val previousUser = state.lastUserId
        // isolamento multi-utente: dati di un altro utente non restano mai
        if (previousUser != null && previousUser != userId) {
            runCatching { store.clear() }.onFailure { return LoginSyncResult.Failed }
            state.syncedUserId = null
            state.lastSyncedCount = -1
            state.clearDirty(state.dirty())
            state.hasPendingChanges = false
        }
        // sessione ripresa dopo un primo scambio già riuscito: prima si caricano le modifiche locali, poi si scarica
        if (!fresh && canPush(userId)) {
            state.lastUserId = userId
            when (val r = pushDetailed()) {
                is PushResult.NeedsConfirmation -> return LoginSyncResult.NeedsDeleteConfirmation(r.deletions, r.baseline)
                PushResult.Failed -> return LoginSyncResult.Failed
                PushResult.Done -> Unit
            }
            return if (pull() == PullOutcome.Done) LoginSyncResult.Pulled else LoginSyncResult.Pushed
        }
        val remoteEmpty = try {
            auth.authed { token ->
                if (!completeSnapshot) fetchIds("mt_accounts", userId, token).isEmpty()
                else VaultKind.entries.none { fetchIds(it.table, userId, token).isNotEmpty() }
            }
        } catch (e: Exception) {
            // iOS ripiega sul push; qui mai: senza sapere cosa c'è sul cloud non si scrive (il primo scambio non è ancora avvenuto)
            return LoginSyncResult.Failed
        }
        val local = store.snapshot()
        if (remoteEmpty) {
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
    suspend fun clearLocalData(retiredUser: String? = null) {
        val owner = state.lastUserId ?: retiredUser
        try {
            store.clear()
        } finally {
            onClear(owner)
            if (retiredUser != null && retiredUser != owner) onClear(retiredUser)
        }
        state.lastPull = 0
        state.syncedUserId = null
        state.lastUserId = null
        state.lastSyncedCount = -1
        state.clearDirty(state.dirty())
        state.hasPendingChanges = false
    }
}
