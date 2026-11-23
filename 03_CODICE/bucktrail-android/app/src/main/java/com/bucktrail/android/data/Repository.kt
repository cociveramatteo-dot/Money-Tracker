package com.bucktrail.android.data

import com.bucktrail.android.domain.AccountData
import com.bucktrail.android.domain.TransactionData
import kotlinx.coroutines.ExperimentalCoroutinesApi
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.flatMapLatest
import kotlinx.coroutines.flow.update
import kotlinx.coroutines.flow.combine

/** Istantanea reattiva dei dati per le schermate (query Room osservate, nessuna cache manuale). */
data class LedgerState(
    val accounts: List<AccountEntity> = emptyList(),
    val transactions: List<TransactionEntity> = emptyList(),
    val categories: List<CategoryEntity> = emptyList(),
    val budgets: List<BudgetEntity> = emptyList(),
    val goals: List<GoalEntity> = emptyList(),
    val rules: List<RecurringRuleEntity> = emptyList(),
    /** Vero se i dati vengono dal database demo; `generation` cambia a ogni cambio di database. */
    val demo: Boolean = false,
    val generation: Int = 0,
) {
    val accountData: List<AccountData> by lazy { accounts.map { it.toData() } }
    val transactionData: List<TransactionData> by lazy { transactions.map { it.toData() } }
}

class Repository(initial: BucktrailDao, demo: Boolean = false) {
    private data class Source(val dao: BucktrailDao, val demo: Boolean, val generation: Int)
    private val source = MutableStateFlow(Source(initial, demo, 0))

    /** Database attivo: quello reale o, in modalità demo, quello separato (§4.12). */
    val dao: BucktrailDao get() = source.value.dao
    val isDemo: Boolean get() = source.value.demo

    @OptIn(ExperimentalCoroutinesApi::class)
    val state: Flow<LedgerState> = source.flatMapLatest { s ->
        combine(
            s.dao.observeAccounts(), s.dao.observeTransactions(), s.dao.observeCategories(),
            s.dao.observeBudgets(), s.dao.observeGoals(), s.dao.observeRules(),
        ) { values ->
            @Suppress("UNCHECKED_CAST")
            LedgerState(
                values[0] as List<AccountEntity>, values[1] as List<TransactionEntity>, values[2] as List<CategoryEntity>,
                values[3] as List<BudgetEntity>, values[4] as List<GoalEntity>, values[5] as List<RecurringRuleEntity>,
                s.demo, s.generation,
            )
        }
    }

    fun switchTo(dao: BucktrailDao, demo: Boolean) { source.update { Source(dao, demo, it.generation + 1) } }

    suspend fun seed() = dao.seedDefaultCategories()

    /** Lettura puntuale dopo un salvataggio (per le notifiche, prima che i flussi si aggiornino). */
    suspend fun snapshot(): LedgerState = dao.let {
        LedgerState(it.accounts(), it.transactions(), it.categories(), it.budgets(), it.goals(), it.rules(), isDemo)
    }
}
