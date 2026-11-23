package com.bucktrail.android.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import kotlinx.coroutines.flow.Flow

@Dao
interface BucktrailDao {
    // Conti
    @Query("SELECT * FROM accounts ORDER BY name COLLATE NOCASE, id")
    fun observeAccounts(): Flow<List<AccountEntity>>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(account: AccountEntity)
    @Delete suspend fun delete(account: AccountEntity)

    // Movimenti
    @Query("SELECT * FROM transactions ORDER BY date DESC, createdAt DESC, id")
    fun observeTransactions(): Flow<List<TransactionEntity>>
    @Query("SELECT * FROM transactions WHERE templateId = :templateId COLLATE NOCASE")
    suspend fun transactionsOfTemplate(templateId: String): List<TransactionEntity>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(transaction: TransactionEntity)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsertTransactions(transactions: List<TransactionEntity>)
    @Delete suspend fun delete(transaction: TransactionEntity)
    @Query("DELETE FROM transactions WHERE id IN (:ids)") suspend fun deleteTransactions(ids: List<String>)

    // Budget, obiettivi
    @Query("SELECT * FROM budgets ORDER BY createdAt, id") fun observeBudgets(): Flow<List<BudgetEntity>>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(budget: BudgetEntity)
    @Delete suspend fun delete(budget: BudgetEntity)
    @Query("SELECT * FROM goals ORDER BY createdAt, id") fun observeGoals(): Flow<List<GoalEntity>>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(goal: GoalEntity)
    @Delete suspend fun delete(goal: GoalEntity)

    // Categorie
    @Query("SELECT * FROM categories ORDER BY sortOrder, name COLLATE NOCASE") fun observeCategories(): Flow<List<CategoryEntity>>
    @Query("SELECT * FROM categories") suspend fun categories(): List<CategoryEntity>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(category: CategoryEntity)
    @Update suspend fun update(category: CategoryEntity)
    @Delete suspend fun delete(category: CategoryEntity)

    // Ricorrenze
    @Query("SELECT * FROM recurring_rules ORDER BY createdAt, id") fun observeRules(): Flow<List<RecurringRuleEntity>>
    @Query("SELECT * FROM recurring_rules") suspend fun rules(): List<RecurringRuleEntity>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(rule: RecurringRuleEntity)
    @Delete suspend fun delete(rule: RecurringRuleEntity)

    /** Pulizia al logout (`clearLocalData`): tutto tranne le categorie. */
    @Transaction
    suspend fun clearLocalData() {
        deleteAllTransactions(); deleteAllRules(); deleteAllBudgets(); deleteAllGoals(); deleteAllAccounts()
    }
    @Query("DELETE FROM transactions") suspend fun deleteAllTransactions()
    @Query("DELETE FROM recurring_rules") suspend fun deleteAllRules()
    @Query("DELETE FROM budgets") suspend fun deleteAllBudgets()
    @Query("DELETE FROM goals") suspend fun deleteAllGoals()
    @Query("DELETE FROM accounts") suspend fun deleteAllAccounts()
}
