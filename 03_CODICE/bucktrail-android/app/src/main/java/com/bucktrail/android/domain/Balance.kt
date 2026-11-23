package com.bucktrail.android.domain

import java.math.BigDecimal

/** Saldo per conto (`AccountBalanceCache` iOS): attuale = iniziale + fatti; futuro = iniziale + tutti. */
object Balance {
    fun current(account: AccountData, transactions: List<TransactionData>): BigDecimal =
        transactions.filter { it.accountId == account.id && it.isDone }
            .fold(account.initialBalance) { acc, t -> acc + t.signedAmount }

    fun future(account: AccountData, transactions: List<TransactionData>): BigDecimal =
        transactions.filter { it.accountId == account.id }
            .fold(account.initialBalance) { acc, t -> acc + t.signedAmount }

    fun plannedDelta(account: AccountData, transactions: List<TransactionData>): BigDecimal =
        future(account, transactions) - current(account, transactions)

    /** Conti che contano nei totali: non archiviati e non esclusi. */
    fun included(accounts: List<AccountData>): List<AccountData> =
        accounts.filter { !it.isArchived && !it.isExcludedFromTotal }

    fun total(accounts: List<AccountData>, transactions: List<TransactionData>): BigDecimal =
        included(accounts).fold(BigDecimal.ZERO) { acc, a -> acc + current(a, transactions) }

    fun totalFuture(accounts: List<AccountData>, transactions: List<TransactionData>): BigDecimal =
        included(accounts).fold(BigDecimal.ZERO) { acc, a -> acc + future(a, transactions) }
}
