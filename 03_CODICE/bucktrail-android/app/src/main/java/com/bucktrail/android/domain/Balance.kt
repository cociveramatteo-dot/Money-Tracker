package com.bucktrail.android.domain

import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

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

    /** Saldo atteso a fine mese secondo la regola Home (`HomeProjection.countsInMonth`). */
    fun expectedInMonth(
        account: AccountData,
        transactions: List<TransactionData>,
        today: LocalDate,
        zone: ZoneId,
    ): BigDecimal {
        val month = YearMonth.from(today)
        return transactions
            .filter { it.accountId == account.id && HomeProjection.countsInMonth(it, month, zone) }
            .fold(account.initialBalance) { acc, t -> acc + t.signedAmount }
    }

    /** Conti che contano nei totali: non archiviati e non esclusi. */
    fun included(accounts: List<AccountData>): List<AccountData> =
        accounts.filter { !it.isArchived && !it.isExcludedFromTotal }

    fun total(accounts: List<AccountData>, transactions: List<TransactionData>): BigDecimal =
        included(accounts).fold(BigDecimal.ZERO) { acc, a -> acc + current(a, transactions) }

    fun totalFuture(accounts: List<AccountData>, transactions: List<TransactionData>): BigDecimal =
        included(accounts).fold(BigDecimal.ZERO) { acc, a -> acc + future(a, transactions) }

    fun totalExpectedInMonth(
        accounts: List<AccountData>,
        transactions: List<TransactionData>,
        today: LocalDate,
        zone: ZoneId,
    ): BigDecimal = included(accounts).fold(BigDecimal.ZERO) { acc, a ->
        acc + expectedInMonth(a, transactions, today, zone)
    }
}
