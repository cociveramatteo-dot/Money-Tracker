package com.bucktrail.android.ui

import android.app.Application
import androidx.lifecycle.AndroidViewModel
import androidx.lifecycle.viewModelScope
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.data.AccountEntity
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

    fun saveAccount(account: AccountEntity) = viewModelScope.launch { repository.dao.upsert(account) }

    /** Esegue il salvataggio e riporta l'esito (false = errore: il form resta aperto). */
    suspend fun saveTransaction(transaction: TransactionEntity): Boolean = runCatching { repository.dao.upsert(transaction) }.isSuccess

    suspend fun saveAccountChecked(account: AccountEntity): Boolean = runCatching { repository.dao.upsert(account) }.isSuccess

    fun deleteTransaction(transaction: TransactionEntity) = viewModelScope.launch { repository.dao.delete(transaction) }

    fun setHideBalance(value: Boolean) = viewModelScope.launch { prefs.setHideBalance(value) }

    fun iconForCategory(name: String, categories: List<com.bucktrail.android.data.CategoryEntity>): String =
        categories.firstOrNull { it.name == name }?.icon ?: Categories.iconFor(name)
}
