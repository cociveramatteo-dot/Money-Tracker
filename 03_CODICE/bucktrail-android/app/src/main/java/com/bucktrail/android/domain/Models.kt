package com.bucktrail.android.domain

import java.math.BigDecimal
import java.time.Instant

enum class AccountType(val raw: String) {
    Cash("Contanti"), Card("Carta"), Checking("Conto Bancario"), Savings("Risparmio"), Investment("Investimento");

    companion object {
        /** Tipo sconosciuto -> conto, come iOS. */
        fun from(raw: String): AccountType = entries.firstOrNull { it.raw == raw } ?: Checking
    }
}

/** Valori di sola lettura per le funzioni pure (nessuna dipendenza da Room). */
data class AccountData(
    val id: String, val name: String, val type: String, val initialBalance: BigDecimal,
    val isArchived: Boolean = false, val isExcludedFromTotal: Boolean = false,
)

data class TransactionData(
    val id: String, val accountId: String?, val name: String, val amount: BigDecimal, val type: String,
    val category: String = "Altro", val categoryIcon: String = "circle.dotted", val date: Instant,
    val isDone: Boolean = true, val isFixed: Boolean = false, val isTransfer: Boolean = false,
    val transferGroupId: String = "", val notes: String = "", val recurringFrequency: String = "",
    val templateId: String = "", val createdAt: Instant = date,
) {
    val signedAmount: BigDecimal get() = Amounts.signed(amount, type)
}
