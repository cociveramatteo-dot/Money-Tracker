package com.bucktrail.android.data

import com.bucktrail.android.domain.AccountData
import com.bucktrail.android.domain.TransactionData
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.combine

/** Istantanea reattiva dei dati per le schermate (query Room osservate, nessuna cache manuale). */
data class LedgerState(
    val accounts: List<AccountEntity> = emptyList(),
    val transactions: List<TransactionEntity> = emptyList(),
    val categories: List<CategoryEntity> = emptyList(),
    val budgets: List<BudgetEntity> = emptyList(),
    val goals: List<GoalEntity> = emptyList(),
    val rules: List<RecurringRuleEntity> = emptyList(),
) {
    val accountData: List<AccountData> by lazy { accounts.map { it.toData() } }
    val transactionData: List<TransactionData> by lazy { transactions.map { it.toData() } }
}

class Repository(val dao: BucktrailDao) {
    val state: Flow<LedgerState> = combine(
        dao.observeAccounts(), dao.observeTransactions(), dao.observeCategories(),
        dao.observeBudgets(), dao.observeGoals(), dao.observeRules(),
    ) { values ->
        @Suppress("UNCHECKED_CAST")
        LedgerState(
            values[0] as List<AccountEntity>, values[1] as List<TransactionEntity>, values[2] as List<CategoryEntity>,
            values[3] as List<BudgetEntity>, values[4] as List<GoalEntity>, values[5] as List<RecurringRuleEntity>,
        )
    }

    suspend fun seed() = dao.seedDefaultCategories()
}
