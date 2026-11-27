package com.bucktrail.android.sync

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity

/** Istantanea dei dati sincronizzati (locale o remota). Le categorie non si sincronizzano (come iOS). */
data class Snapshot(
    val accounts: List<AccountEntity> = emptyList(),
    val transactions: List<TransactionEntity> = emptyList(),
    val budgets: List<BudgetEntity> = emptyList(),
    val goals: List<GoalEntity> = emptyList(),
    val rules: List<RecurringRuleEntity> = emptyList(),
) {
    val isEmpty: Boolean get() = accounts.isEmpty() && transactions.isEmpty() && budgets.isEmpty() && goals.isEmpty() && rules.isEmpty()
    /** Numero totale di record sincronizzati (base della guardia «calo anomalo»). */
    val count: Int get() = accounts.size + transactions.size + budgets.size + goals.size + rules.size
}

/**
 * Id delle righe remote presenti ma illeggibili o con importo assurdo (ignorate dal pull senza bloccarlo).
 * Il merge non cancella mai la copia locale di una riga ignorata.
 */
data class IgnoredIds(
    val accounts: Set<String> = emptySet(), val transactions: Set<String> = emptySet(), val budgets: Set<String> = emptySet(),
    val goals: Set<String> = emptySet(), val rules: Set<String> = emptySet(),
) {
    val count: Int get() = accounts.size + transactions.size + budgets.size + goals.size + rules.size
}

/** Modifiche da applicare in locale con un'unica transazione Room (§5.3: «un'unica transazione Room»). */
data class SyncPlan(
    val accounts: List<AccountEntity> = emptyList(), val deleteAccountIds: List<String> = emptyList(),
    val transactions: List<TransactionEntity> = emptyList(), val deleteTransactionIds: List<String> = emptyList(),
    val budgets: List<BudgetEntity> = emptyList(), val deleteBudgetIds: List<String> = emptyList(),
    val goals: List<GoalEntity> = emptyList(), val deleteGoalIds: List<String> = emptyList(),
    val rules: List<RecurringRuleEntity> = emptyList(), val deleteRuleIds: List<String> = emptyList(),
) {
    val isEmpty: Boolean get() = accounts.isEmpty() && deleteAccountIds.isEmpty() && transactions.isEmpty() && deleteTransactionIds.isEmpty() &&
        budgets.isEmpty() && deleteBudgetIds.isEmpty() && goals.isEmpty() && deleteGoalIds.isEmpty() && rules.isEmpty() && deleteRuleIds.isEmpty()
}

/**
 * Unione del pull (`SyncService.pull` iOS): la riga remota vince campo per campo; si aggiorna solo ciò che differisce;
 * gli assenti sul remoto si cancellano (tranne le transazioni «sporche», non ancora caricate). Funzione pura.
 * Ritorna `null` se scatta una guardia (remoto senza conti e nessun conto locale già sincronizzato).
 */
object SyncMerge {
    fun plan(local: Snapshot, remote: Snapshot, dirtyTransactionIds: Set<String>, ignored: IgnoredIds = IgnoredIds(),
             knownRuleIds: Set<String> = emptySet(), knownAccountIds: Set<String> = emptySet(),
             clearedLinks: Set<String> = emptySet(), encrypted: Boolean = false,
             preserveDirtyChanges: Boolean = false): SyncPlan? {
        val localAccounts = local.accounts.associateBy { it.id }
        val noRemoteAccounts = remote.accounts.isEmpty() && ignored.accounts.isEmpty()
        if (noRemoteAccounts && localAccounts.isNotEmpty() && localAccounts.keys.none { it in knownAccountIds }) return null

        val remoteAccountIds = remote.accounts.map { it.id }.toSet()
        val pendingAccounts = if (noRemoteAccounts) localAccounts.keys - knownAccountIds else emptySet()
        // I conti ignorati già presenti in locale restano referenziabili.
        val stillReferenced = remote.transactions.mapNotNull { it.accountId }.toSet() intersect localAccounts.keys
        val retainedAccounts = remoteAccountIds + (ignored.accounts intersect localAccounts.keys) + pendingAccounts + stillReferenced
        val accounts = remote.accounts.mapNotNull { r ->
            val existing = localAccounts[r.id]
            val merged = existing?.copy(
                name = r.name, type = r.type, initialBalanceCents = r.initialBalanceCents, colorHex = r.colorHex,
                isArchived = r.isArchived, isExcludedFromTotal = r.isExcludedFromTotal,
            ) ?: r
            merged.takeIf { it != existing }
        }
        val deleteAccounts = localAccounts.keys.filter { it !in retainedAccounts }

        // Il cascade locale non deve far sparire i movimenti ancora presenti sul server.
        val cascaded = deleteAccounts.toSet()
        val localTx = local.transactions.associateBy { it.id }
        val warned = remote.transactions.count { it.accountId != null && it.accountId !in retainedAccounts }
        if (warned > 0) java.util.logging.Logger.getLogger(SyncMerge::class.java.name)
            .warning("$warned downloaded transactions reference a missing account")
        val transactions = remote.transactions.mapNotNull { r ->
            val existing = localTx[r.id]
            if (existing != null && preserveDirtyChanges && r.id in dirtyTransactionIds) {
                return@mapNotNull existing.takeIf { it.accountId in cascaded }?.copy(accountId = null)
            }
            val accountId = r.accountId?.takeIf { it in retainedAccounts }
            val merged = existing?.copy(
                name = r.name, amountCents = r.amountCents, type = r.type, category = r.category, categoryIcon = r.categoryIcon, date = r.date,
                isDone = r.isDone, isFixed = r.isFixed, isTransfer = r.isTransfer, transferGroupId = r.transferGroupId, notes = r.notes,
                recurringFrequency = r.recurringFrequency, templateId = r.templateId,
                accountId = when {
                    accountId != null || r.id in clearedLinks || encrypted -> accountId
                    else -> existing.accountId?.takeIf { it in retainedAccounts }
                },
            ) ?: r.copy(accountId = accountId)
            merged.takeIf { it != existing || existing.accountId in cascaded }
        }
        val remoteTxIds = remote.transactions.map { it.id }.toSet()
        val deleteTx = local.transactions.filter { it.id !in remoteTxIds && it.id !in ignored.transactions && it.id !in dirtyTransactionIds && it.accountId !in cascaded && it.accountId !in pendingAccounts }.map { it.id }

        val localBudgets = local.budgets.associateBy { it.id }
        val budgets = remote.budgets.mapNotNull { r ->
            val existing = localBudgets[r.id]
            val accountId = r.accountId?.takeIf { it in retainedAccounts }
            val merged = existing?.copy(
                category = r.category, categoryIcon = r.categoryIcon, monthlyLimitCents = r.monthlyLimitCents, month = r.month, year = r.year,
                accountId = if (r.accountId != null) accountId else existing.accountId,
            ) ?: r.copy(accountId = accountId)
            merged.takeIf { it != existing }
        }
        val remoteBudgetIds = remote.budgets.map { it.id }.toSet()
        val deleteBudgets = local.budgets.filter { it.id !in remoteBudgetIds && it.id !in ignored.budgets && it.accountId !in cascaded && it.accountId !in pendingAccounts }.map { it.id }

        val localGoals = local.goals.associateBy { it.id }
        val goals = remote.goals.mapNotNull { r ->
            val existing = localGoals[r.id]
            val merged = existing?.copy(
                name = r.name, emoji = r.emoji, targetCents = r.targetCents, currentCents = r.currentCents, deadline = r.deadline, isCompleted = r.isCompleted,
            ) ?: r
            merged.takeIf { it != existing }
        }
        val remoteGoalIds = remote.goals.map { it.id }.toSet()
        val deleteGoals = local.goals.map { it.id }.filter { it !in remoteGoalIds && it !in ignored.goals }

        // Con un remoto vuoto restano le regole in attesa del primo push. Il cursore non torna mai indietro.
        val keepAllRules = remote.rules.isEmpty() && local.rules.isNotEmpty()
        val localRules = local.rules.associateBy { it.id }
        val rules = if (keepAllRules) emptyList() else remote.rules.mapNotNull { r ->
            val existing = localRules[r.id]
            val merged = existing?.copy(
                name = r.name, type = r.type, category = r.category, categoryIcon = r.categoryIcon, notes = r.notes, amountCents = r.amountCents,
                isFixed = r.isFixed, accountId = r.accountId, frequency = r.frequency, startDate = r.startDate, endDate = r.endDate,
                exceptionsJson = r.exceptionsJson, createdAt = r.createdAt,
                materializedThrough = listOfNotNull(existing.materializedThrough, r.materializedThrough).maxOrNull(),
            ) ?: r
            merged.takeIf { it != existing }
        }
        val remoteRuleIds = remote.rules.map { it.id }.toSet()
        val deleteRules = local.rules.map { it.id }.filter {
            it !in remoteRuleIds && it !in ignored.rules && (!keepAllRules || it in knownRuleIds)
        }

        val dirtyOrIgnoredChildren = local.transactions.filter {
            it.id !in remoteTxIds && it.accountId in cascaded &&
                (it.id in dirtyTransactionIds || it.id in ignored.transactions)
        }.map { it.copy(accountId = null) }
        return SyncPlan(accounts, deleteAccounts, transactions + dirtyOrIgnoredChildren, deleteTx,
            budgets, deleteBudgets, goals, deleteGoals, rules, deleteRules)
    }
}
