package com.bucktrail.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.CategoryEntity
import com.bucktrail.android.data.TransactionOps
import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.domain.Amounts
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

    @Volatile private var classifier: KeywordCategoryClassifier? = null

    init {
        viewModelScope.launch { repository.seed() }
    }

    /** Categoria suggerita per il nome (classificatore on-device); `Altro` se nulla combacia. */
    suspend fun classify(name: String): String {
        val c = classifier ?: withContext(Dispatchers.IO) {
            val text = application.assets.open("CategoryKeywords.json").bufferedReader().use { it.readText() }
            val map = (Json.parseToJsonElement(text) as JsonObject).mapValues { (_, v) -> (v as JsonArray).map { it.jsonPrimitive.content } }
            KeywordCategoryClassifier(map).also { classifier = it }
        }
        return withContext(Dispatchers.Default) { c.classify(name) }
    }

    /** Ultimo movimento eliminato, in attesa di «Annulla» (barra temporanea). */
    data class UndoState(val transactions: List<TransactionEntity>, val key: Long = System.nanoTime())
    val undo = MutableStateFlow<UndoState?>(null)

    /** Esegue il salvataggio e riporta l'esito (false = errore: il form resta aperto). */
    suspend fun saveTransaction(transaction: TransactionEntity): Boolean = runCatching { repository.dao.upsert(transaction) }.isSuccess

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
        viewModelScope.launch { repository.dao.upsertTransactions(state.transactions) }
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
        repository.dao.delete(account)
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

    // Preferenze
    fun setHomeAccounts(ids: List<String>) = viewModelScope.launch { prefs.setHomeAccounts(ids) }
    fun setCurrency(code: String) = viewModelScope.launch { prefs.setCurrency(code) }
    fun setShowFixedExpenses(v: Boolean) = viewModelScope.launch { prefs.setShowFixedExpenses(v) }
    fun setShowFixedIncome(v: Boolean) = viewModelScope.launch { prefs.setShowFixedIncome(v) }
    fun setTxFilters(min: String, max: String, useDates: Boolean) = viewModelScope.launch { prefs.setTxFilters(min, max, useDates) }

    fun setHideBalance(value: Boolean) = viewModelScope.launch { prefs.setHideBalance(value) }

    fun iconForCategory(name: String, categories: List<com.bucktrail.android.data.CategoryEntity>): String =
        categories.firstOrNull { it.name == name }?.icon ?: Categories.iconFor(name)
}
