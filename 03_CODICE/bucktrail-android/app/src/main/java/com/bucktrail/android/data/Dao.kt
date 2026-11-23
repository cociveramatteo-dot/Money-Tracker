package com.bucktrail.android.data

import androidx.room.Dao
import androidx.room.Delete
import androidx.room.Insert
import androidx.room.OnConflictStrategy
import androidx.room.Query
import androidx.room.Transaction
import androidx.room.Update
import com.bucktrail.android.domain.CategoryEditing
import kotlinx.coroutines.flow.Flow

@Dao
interface BucktrailDao {
    // Conti
    @Query("SELECT * FROM accounts ORDER BY name COLLATE NOCASE, id")
    fun observeAccounts(): Flow<List<AccountEntity>>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(account: AccountEntity)
    @Delete suspend fun delete(account: AccountEntity)

    @Query("SELECT * FROM accounts") suspend fun accounts(): List<AccountEntity>

    // Movimenti
    @Query("SELECT * FROM transactions") suspend fun transactions(): List<TransactionEntity>
    @Query("SELECT * FROM transactions ORDER BY date DESC, createdAt DESC, id")
    fun observeTransactions(): Flow<List<TransactionEntity>>
    @Query("SELECT * FROM transactions WHERE templateId = :templateId COLLATE NOCASE")
    suspend fun transactionsOfTemplate(templateId: String): List<TransactionEntity>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(transaction: TransactionEntity)
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsertTransactions(transactions: List<TransactionEntity>)
    @Delete suspend fun delete(transaction: TransactionEntity)
    @Query("DELETE FROM transactions WHERE id IN (:ids)") suspend fun deleteTransactions(ids: List<String>)
    @Query("UPDATE transactions SET category = :newName WHERE category = :oldName") suspend fun renameTransactionCategory(oldName: String, newName: String)

    /** Salva il conto e, se serve, la «Rettifica saldo» nella stessa transazione. */
    @Transaction
    suspend fun saveAccountWithAdjustment(account: AccountEntity, adjustment: TransactionEntity?) {
        upsert(account)
        adjustment?.let { upsert(it) }
    }

    // Budget, obiettivi
    @Query("SELECT * FROM budgets") suspend fun budgets(): List<BudgetEntity>
    @Query("SELECT * FROM goals") suspend fun goals(): List<GoalEntity>
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

    /** Rinomina (§4.8): riscrive `category` in transazioni e budget (nomi ordinati e ri-uniti), poi aggiorna la categoria. */
    @Transaction
    suspend fun renameCategory(cat: CategoryEntity, newName: String, newIcon: String) {
        if (newName != cat.name) {
            renameTransactionCategory(cat.name, newName)
            for (b in budgets()) {
                val renamed = CategoryEditing.renameInBudget(b.category, cat.name, newName)
                if (renamed != b.category) upsert(b.copy(category = renamed))
            }
        }
        update(cat.copy(name = newName, icon = newIcon))
    }

    // Ricorrenze
    @Query("SELECT * FROM recurring_rules ORDER BY createdAt, id") fun observeRules(): Flow<List<RecurringRuleEntity>>
    @Query("SELECT * FROM recurring_rules") suspend fun rules(): List<RecurringRuleEntity>
    @Insert(onConflict = OnConflictStrategy.REPLACE) suspend fun upsert(rule: RecurringRuleEntity)
    @Delete suspend fun delete(rule: RecurringRuleEntity)

    @Query("DELETE FROM recurring_rules WHERE id = :id") suspend fun deleteRuleById(id: String)

    /** Applica in un'unica transazione le modifiche di editor/materializzazione ricorrenze (o niente, se fallisce). */
    @Transaction
    suspend fun applyRecurring(c: RecurringOps.Changes) {
        c.deleteTransactionIds.chunked(500).forEach { deleteTransactions(it) }
        c.upsertRules.forEach { upsert(it) }
        if (c.upsertTransactions.isNotEmpty()) upsertTransactions(c.upsertTransactions)
        c.deleteRuleId?.let { deleteRuleById(it) }
    }

    /** Salvataggio di una copia di serie modificata + riallineamento di tutta la serie, in un'unica transazione. */
    @Transaction
    suspend fun saveSeriesEdit(copy: TransactionEntity, c: RecurringOps.Changes) {
        upsert(copy)
        applyRecurring(c)
    }

    /** Pulizia al logout (`clearLocalData`): tutto tranne le categorie. */
    @Transaction
    suspend fun clearLocalData() {
        deleteAllTransactions(); deleteAllRules(); deleteAllBudgets(); deleteAllGoals(); deleteAllAccounts()
    }

    /** Sostituisce i dati con quelli dimostrativi in un'unica transazione (le categorie restano). */
    @Transaction
    suspend fun replaceWithDemo(d: DemoData.Result) {
        clearLocalData()
        d.accounts.forEach { upsert(it) }
        d.rules.forEach { upsert(it) }
        upsertTransactions(d.transactions)
        d.budgets.forEach { upsert(it) }
        d.goals.forEach { upsert(it) }
    }

    @Query("DELETE FROM transactions") suspend fun deleteAllTransactions()
    @Query("DELETE FROM recurring_rules") suspend fun deleteAllRules()
    @Query("DELETE FROM budgets") suspend fun deleteAllBudgets()
    @Query("DELETE FROM goals") suspend fun deleteAllGoals()
    @Query("DELETE FROM accounts") suspend fun deleteAllAccounts()
}
