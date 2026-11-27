package com.bucktrail.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.data.TransactionOps
import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.data.RecurringOps
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.toSnapshot
import com.bucktrail.android.domain.RecurrenceCalculator
import com.bucktrail.android.R
import com.bucktrail.android.data.JsonExport
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.CsvExport
import com.bucktrail.android.domain.NotificationRules
import com.bucktrail.android.domain.PdfReport
import com.bucktrail.android.domain.Statistics
import com.bucktrail.android.export.PdfRenderer
import com.bucktrail.android.export.ShareFiles
import java.time.YearMonth
import java.time.Instant
import java.time.ZoneId
import java.util.UUID
import com.bucktrail.android.domain.HomeAccountOrder
import kotlinx.coroutines.flow.MutableStateFlow
import com.bucktrail.android.data.AppPrefs
import com.bucktrail.android.data.LedgerState
import com.bucktrail.android.data.PrefsState
import com.bucktrail.android.data.Repository
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Categories
import com.bucktrail.android.domain.KeywordCategoryClassifier
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive

data class AppData(val ledger: LedgerState = LedgerState(), val prefs: PrefsState = PrefsState(), val loaded: Boolean = false)

class AppViewModel(app: Application) : AndroidViewModel(app) {
    private val application = app as BucktrailApplication
    private val repository: Repository = application.repository
    val prefs: AppPrefs = application.prefs

    val data: StateFlow<AppData> = combine(repository.state, prefs.state) { l, p -> AppData(l, p, true) }
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5_000), AppData())

    private val scheduler get() = application.notifications

    init {
        application.startAudit()
        viewModelScope.launch { application.prepareData() }
        application.startSync()
        application.startWidgetUpdates()
        // dopo un pull le serie del mese si materializzano (coda unica iOS: login -> foreground -> cambio data)
        if (application.syncConfigured) viewModelScope.launch {
            application.syncService.pulled.collect { kotlinx.coroutines.delay(500); materializeDue() }
        }
    }

    // ---- Account e sync (B9) ----
    val syncConfigured: Boolean get() = application.syncConfigured
    private val auth get() = application.auth
    private val sync get() = application.syncService
    internal val protectionSync get() = if (com.bucktrail.android.BuildConfig.E2E_ENABLED) sync else null
    val session: StateFlow<com.bucktrail.android.sync.Session?> get() = auth.session
    val syncStatus: StateFlow<com.bucktrail.android.sync.SyncStatus> get() = sync.status
    val needsSyncDecision: StateFlow<Boolean> get() = sync.needsDecision
    val syncDeleteConfirmation: StateFlow<com.bucktrail.android.sync.PushResult.NeedsConfirmation?> get() = sync.deleteConfirmation

    /** `null` = accesso riuscito (la sessione apre il primo sync da sola); altrimenti il messaggio da mostrare. */
    suspend fun signIn(email: String, password: String): com.bucktrail.android.sync.AuthMessage? =
        try { auth.signIn(email, password); null } catch (e: Exception) { com.bucktrail.android.sync.AuthErrors.login(e) }

    suspend fun signUp(email: String, password: String): Pair<com.bucktrail.android.sync.SignUpResult?, com.bucktrail.android.sync.AuthMessage?> =
        try { auth.signUp(email, password) to null } catch (e: Exception) { null to com.bucktrail.android.sync.AuthErrors.signUp(e) }

    /** L'esito non mostra mai errori (come iOS: `try?`). */
    suspend fun resetPassword(email: String) { runCatching { auth.resetPassword(email) } }

    fun signOut() = viewModelScope.launch {
        // Un errore durante la pulizia locale non deve far crashare l'app al logout.
        try { sync.signOutAndClear() }
        catch (cancelled: kotlinx.coroutines.CancellationException) { throw cancelled }
        catch (e: Exception) { android.util.Log.w("Bucktrail", "Pulizia al logout incompleta", e) }
        finally { runCatching { application.auditLog.clearAll() } }
    }
    suspend fun deleteAccount(): String? = try { sync.deleteAccountAndClear(); application.auditLog.clearAll(); null } catch (e: Exception) { e.message ?: e.toString() }
    fun resolveSyncDeleteConfirmation(delete: Boolean) = viewModelScope.launch { sync.resolveDeleteConfirmation(delete) }
    fun resolveSyncDecision(useCloud: Boolean) = viewModelScope.launch { sync.resolveDecision(useCloud) }
    suspend fun refresh() = sync.manualRefresh()

    /** Categoria suggerita per il nome (classificatore on-device); `Altro` se nulla combacia. */
    suspend fun classify(name: String): String = com.bucktrail.android.data.ClassifierProvider.classify(application, name)

    /** Ultima eliminazione, in attesa di «Annulla» (barra temporanea): movimenti oppure una serie (con la sua `restore`). */
    data class UndoState(
        val transactions: List<TransactionEntity>, val key: Long = System.nanoTime(),
        val series: Boolean = false, val restore: (suspend () -> Unit)? = null,
    )
    val undo = MutableStateFlow<UndoState?>(null)

    private val zone get() = ZoneId.systemDefault()
    private fun accountIds() = data.value.ledger.accounts.map { it.id }.toSet()

    /**
     * Salva il movimento (false = errore: il form resta aperto). Nuovo + `frequency`: crea la serie (regola + prima copia + copie del mese).
     * Modifica di una copia di serie: riallinea l'intera serie (`edit(all)`), il «fatto» resta locale alla copia (§3.4).
     */
    suspend fun saveTransaction(transaction: TransactionEntity, frequency: String = "", isNew: Boolean = true): Boolean = runCatching {
        val ledger = data.value.ledger
        val dao = repository.dao
        val now = Instant.now()
        if (isNew && frequency.isNotEmpty()) {
            val calc = RecurrenceCalculator(zone)
            val date = Instant.ofEpochMilli(transaction.date)
            val rule = RecurringRuleEntity(
                name = transaction.name, type = transaction.type, category = transaction.category, categoryIcon = transaction.categoryIcon,
                notes = transaction.notes, amountCents = transaction.amountCents, isFixed = transaction.isFixed, accountId = transaction.accountId,
                frequency = frequency, startDate = date.toEpochMilli(),
            )
            val first = transaction.copy(id = RecurrenceCalculator.occurrenceId(UUID.fromString(rule.id), calc.key(date)).toString(), templateId = rule.id.uppercase())
            val c = RecurringOps.materialize(ledger.rules + rule, ledger.transactions + first, accountIds(), now, zone)
            val rules = (listOf(rule) + c.upsertRules).associateBy { it.id }.values.toList()
            dao.applyRecurring(RecurringOps.Changes(c.upsertTransactions + first, emptyList(), rules))
        } else {
            val rule = if (isNew) null else RecurringOps.resolve(transaction, ledger.rules, zone)?.let { it.rule to it.occurrence }
            if (rule == null) dao.upsert(transaction) else {
                val (r, occ) = rule
                val calc = RecurrenceCalculator(zone)
                val values = r.toSnapshot().copy(
                    name = transaction.name, amount = Amounts.fromCents(transaction.amountCents), type = transaction.type, category = transaction.category,
                    categoryIcon = transaction.categoryIcon, accountId = transaction.accountId?.let { runCatching { UUID.fromString(it) }.getOrNull() },
                    isFixed = transaction.isFixed, notes = transaction.notes,
                )
                val anchored = values.copy(startDate = calc.anchorForSeriesEdit(values, occ.originalDate, Instant.ofEpochMilli(transaction.date)))
                val stored = ledger.transactions.map { if (it.id == transaction.id) it.copy(isDone = transaction.isDone) else it }
                val c = RecurringOps.apply(RecurringOps.Action.Edit(RecurringOps.Scope.All, anchored), r, Instant.ofEpochMilli(r.startDate), stored, accountIds(), now, zone)
                dao.saveSeriesEdit(stored.first { it.id == transaction.id }, c)
            }
        }
    }.isSuccess.also { if (it) afterTransactionSaved(transaction) }

    /** Dopo il salvataggio (§5.5): Uscita fatta → avvisi budget del mese; movimento fatto con conto → soglia saldo. */
    private fun afterTransactionSaved(t: TransactionEntity) {
        if (!data.value.prefs.notificationsEnabled || !t.isDone) return
        viewModelScope.launch {
            runCatching {
                val ledger = repository.snapshot()
                if (t.type == Amounts.TYPE_EXPENSE) scheduler.checkBudgets(ledger, YearMonth.from(Instant.ofEpochMilli(t.date).atZone(zone)), zone)
                val account = ledger.accounts.firstOrNull { it.id == t.accountId } ?: return@runCatching
                val threshold = data.value.prefs.balanceThresholds[account.id]?.let { Amounts.parse(it) }
                if (threshold == null || threshold.signum() <= 0) return@runCatching
                val balance = Balance.current(account.toData(), ledger.transactionData)
                scheduler.checkBalance(account.id, account.name, NotificationRules.balanceBelow(balance, threshold))
            }
        }
    }

    sealed interface RecurrenceResult {
        data object Ok : RecurrenceResult
        data class Error(val problem: RecurringOps.Problem?) : RecurrenceResult
    }

    /** Editor serie: applica l'azione in un'unica transazione; l'eliminazione mostra «Annulla». */
    suspend fun applyRecurrence(action: RecurringOps.Action, rule: RecurringRuleEntity, originalDate: Instant): RecurrenceResult {
        val ledger = data.value.ledger
        return try {
            val c = RecurringOps.apply(action, rule, originalDate, ledger.transactions, accountIds(), Instant.now(), zone)
            val dao = repository.dao
            dao.applyRecurring(c)
            if (action is RecurringOps.Action.Delete) {
                val gone = ledger.transactions.filter { it.id in c.deleteTransactionIds }
                val oldRules = ledger.rules.filter { it.id == rule.id }
                undo.value = UndoState(gone, series = true, restore = {
                    dao.applyRecurring(RecurringOps.Changes(upsertTransactions = gone, upsertRules = oldRules))
                })
            }
            RecurrenceResult.Ok
        } catch (e: RecurringOps.EditorException) {
            RecurrenceResult.Error(e.problem)
        } catch (e: Exception) {
            RecurrenceResult.Error(null)
        }
    }

    /** Copie mancanti delle serie (avvio, ritorno in foreground, cambio giorno). */
    fun materializeDue() {
        val state = data.value
        if (!state.loaded || state.ledger.rules.isEmpty()) return
        viewModelScope.launch {
            runCatching {
                val l = data.value.ledger
                val c = RecurringOps.materialize(l.rules, l.transactions, accountIds(), Instant.now(), zone)
                if (!c.isEmpty) repository.dao.applyRecurring(c)
            }
        }
    }

    suspend fun saveTransactions(list: List<TransactionEntity>): Boolean = runCatching { repository.dao.upsertTransactions(list) }.isSuccess

    fun deleteTransactions(list: List<TransactionEntity>) {
        if (list.isEmpty()) return
        viewModelScope.launch {
            repository.dao.deleteTransactions(list.map { it.id })
            undo.value = UndoState(list)
        }
    }

    fun undoDelete() {
        val state = undo.value ?: return
        undo.value = null
        viewModelScope.launch { state.restore?.invoke() ?: repository.dao.upsertTransactions(state.transactions) }
    }

    fun dismissUndo(key: Long) { if (undo.value?.key == key) undo.value = null }

    /** Swipe Conferma/Pianificato: inverte `isDone`, anche sulla gamba gemella del trasferimento. */
    fun toggleDone(t: TransactionEntity, all: List<TransactionEntity>) = viewModelScope.launch {
        repository.dao.upsertTransactions(TransactionOps.withDone(t, TransactionOps.twinsOf(t, all), !t.isDone))
    }

    // Conti
    /** Salva il conto con l'eventuale rettifica; soglia in prefs (`null` = invariata, "" = disattivata). */
    suspend fun saveAccount(account: AccountEntity, adjustment: TransactionEntity?, threshold: String?, addToHome: Boolean): Boolean {
        val ok = runCatching { repository.dao.saveAccountWithAdjustment(account, adjustment) }.isSuccess
        if (!ok) return false
        if (threshold != null) {
            val value = AccountEditing.threshold(threshold)
            if (value == null) prefs.removeBalanceThreshold(account.id) else prefs.setBalanceThreshold(account.id, Amounts.fixedFractionString(value))
        }
        if (addToHome) {
            val saved = data.value.prefs.homeAccountIds
            prefs.setHomeAccounts(HomeAccountOrder.withNewAccount(saved, account.id))
        }
        return true
    }

    fun setAccountArchived(account: AccountEntity, archived: Boolean) = viewModelScope.launch { repository.dao.upsert(account.copy(isArchived = archived)) }
    fun setAccountExcluded(account: AccountEntity, excluded: Boolean) = viewModelScope.launch { repository.dao.upsert(account.copy(isExcludedFromTotal = excluded)) }

    /** Elimina conto + movimenti + budget del conto (cascata Room) e le preferenze legate. */
    fun deleteAccount(account: AccountEntity) = viewModelScope.launch {
        sync.deleteLedgerAccount(account.id) { repository.dao.delete(account) }
        prefs.removeBalanceThreshold(account.id)
        val saved = data.value.prefs.homeAccountIds
        if (account.id in saved) prefs.setHomeAccounts(saved - account.id)
    }

    // Categorie
    suspend fun saveCategory(existing: CategoryEntity?, name: String, icon: String): Boolean = runCatching {
        if (existing == null) {
            val next = (data.value.ledger.categories.maxOfOrNull { it.sortOrder } ?: -1) + 1
            repository.dao.upsert(CategoryEntity(name = name.trim(), icon = icon, isDefault = false, sortOrder = next))
        } else repository.dao.renameCategory(existing, name.trim(), icon)
    }.isSuccess

    fun deleteCategory(category: CategoryEntity) = viewModelScope.launch { repository.dao.delete(category) }

    // Budget e obiettivi
    suspend fun saveBudget(b: com.bucktrail.android.data.BudgetEntity): Boolean = runCatching { repository.dao.upsert(b) }.isSuccess
    fun deleteBudget(b: com.bucktrail.android.data.BudgetEntity) = viewModelScope.launch { repository.dao.delete(b) }
    suspend fun saveGoal(g: com.bucktrail.android.data.GoalEntity): Boolean = runCatching { repository.dao.upsert(g) }.isSuccess.also { ok ->
        if (ok && data.value.prefs.notificationsEnabled && !repository.isDemo) {
            if (g.deadline != null) scheduler.scheduleGoal(g.id, g.name, g.deadline) else scheduler.cancelGoal(g.id)
        }
    }
    fun deleteGoal(g: com.bucktrail.android.data.GoalEntity) = viewModelScope.launch { repository.dao.delete(g); scheduler.cancelGoal(g.id) }

    // Preferenze
    fun setHomeAccounts(ids: List<String>) = viewModelScope.launch { prefs.setHomeAccounts(ids) }
    fun setCurrency(code: String) = viewModelScope.launch { prefs.setCurrency(code) }
    fun setShowFixedExpenses(v: Boolean) = viewModelScope.launch { prefs.setShowFixedExpenses(v) }
    fun setShowFixedIncome(v: Boolean) = viewModelScope.launch { prefs.setShowFixedIncome(v) }
    fun setTxFilters(min: String, max: String, useDates: Boolean) = viewModelScope.launch { prefs.setTxFilters(min, max, useDates) }

    // Notifiche, sicurezza, demo (§4.9)
    /** Avvisi automatici: spegnerli cancella tutto il programmato e spegne anche il report mensile. */
    fun setNotifications(enabled: Boolean) = viewModelScope.launch {
        prefs.setNotifications(enabled)
        if (enabled) refreshNotifications(force = true) else {
            scheduler.cancelAll(data.value.ledger.goals.map { it.id })
            prefs.setMonthlyReport(false)
        }
    }

    fun setMonthlyReport(enabled: Boolean) = viewModelScope.launch {
        prefs.setMonthlyReport(enabled)
        scheduler.scheduleMonthlyReport(enabled && data.value.prefs.notificationsEnabled)
    }

    /** Ripianifica fisse, report e scadenze obiettivi sui dati reali (avvio app, ritorno in primo piano). */
    fun refreshNotifications(force: Boolean = false) {
        val state = data.value
        if (!state.loaded || state.ledger.demo || !(state.prefs.notificationsEnabled || force)) return
        scheduler.rescheduleAll(state.ledger, state.prefs.monthlyReportEnabled)
    }

    fun setAppLock(enabled: Boolean) = viewModelScope.launch { prefs.setAppLock(enabled) }

    fun setDemoMode(enabled: Boolean) = viewModelScope.launch { application.setDemoMode(enabled) }

    // Esportazioni: file temporanei in cache, condivisi col foglio di sistema
    private val res get() = application.resources

    suspend fun exportCsv(): java.io.File = withContext(Dispatchers.Default) {
        val ledger = repository.snapshot()
        val labels = CsvExport.Labels(
            listOf(R.string.data, R.string.descrizione, R.string.importo, R.string.tipo, R.string.categoria, R.string.conto, R.string.fatto, R.string.ricorrenza).map(res::getString),
            res.getString(R.string.uscita), res.getString(R.string.entrata), res.getString(R.string.si), res.getString(R.string.no),
        ) { categoryLabel(it, res) }
        val text = CsvExport.build(ledger.transactionData, ledger.accounts.associate { it.id to it.name }, zone, labels)
        ShareFiles.write(application, CsvExport.FILE_NAME, text.toByteArray(Charsets.UTF_8))
    }

    suspend fun exportJson(): java.io.File = withContext(Dispatchers.Default) {
        val l = repository.snapshot()
        val json = JsonExport.build(l.accounts, l.transactions, l.budgets, l.goals, Instant.now())
        ShareFiles.write(application, JsonExport.FILE_NAME, json.toByteArray(Charsets.UTF_8))
    }

    /** Report del mese (§4.5): valuta scelta nelle Impostazioni (diverge dall'anomalia iOS #4, che usa quella di sistema). */
    suspend fun exportPdf(month: YearMonth): java.io.File? = withContext(Dispatchers.Default) {
        runCatching {
            val ledger = repository.snapshot()
            val currency = data.value.prefs.currencyCode
            val all = ledger.transactionData
            val byMonth = Statistics.byMonth(all, zone)
            val dayMonth = java.time.format.DateTimeFormatter.ofPattern("d MMM", java.util.Locale.getDefault())
            val labels = PdfReport.Labels(
                res.getString(R.string.app_name), res.getString(R.string.uscite), res.getString(R.string.entrate), res.getString(R.string.netto),
                res.getString(R.string.rispetto_al_mese_precedente), res.getString(R.string.uscite_per_categoria), res.getString(R.string.movimenti),
            ) { categoryLabel(it, res) }
            val pages = PdfReport.layout(
                month, Fmt.monthYear(month), PdfReport.transactionsOf(all, month, zone), Statistics.prevMonthSpent(byMonth, month), labels,
                { Fmt.currency(it, currency) }, { dayMonth.format(it) },
            )
            val file = ShareFiles.target(application, PdfReport.fileName(month))
            PdfRenderer.write(pages, file)
            file
        }.getOrNull()
    }

    fun setHideBalance(value: Boolean) = viewModelScope.launch { prefs.setHideBalance(value) }

    fun iconForCategory(name: String, categories: List<com.bucktrail.android.data.CategoryEntity>): String =
        categories.firstOrNull { it.name == name }?.icon ?: Categories.iconFor(name)
}
