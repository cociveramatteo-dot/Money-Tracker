package com.bucktrail.android.domain

import java.math.BigDecimal

/** Modifica del saldo di un conto (§4.7): senza movimenti cambia il saldo iniziale, altrimenti si registra una «Rettifica saldo». */
object AccountEditing {
    sealed interface BalanceChange {
        data object None : BalanceChange
        data class SetInitial(val value: BigDecimal) : BalanceChange
        data class Adjust(val delta: BigDecimal) : BalanceChange {
            val type: String get() = if (delta.signum() > 0) Amounts.TYPE_INCOME else Amounts.TYPE_EXPENSE
            val amount: BigDecimal get() = delta.abs()
        }
    }

    fun balanceChange(hasTransactions: Boolean, currentBalance: BigDecimal, newBalance: BigDecimal): BalanceChange {
        if (!hasTransactions) return BalanceChange.SetInitial(newBalance)
        val delta = newBalance - currentBalance
        return if (delta.signum() == 0) BalanceChange.None else BalanceChange.Adjust(delta)
    }

    /** Soglia «saldo basso»: stringa vuota o ≤ 0 = disattivata. */
    fun threshold(raw: String?): BigDecimal? = raw?.let(Amounts::parse)?.takeIf { it.signum() > 0 }

    /** `true` se la soglia è attiva e il saldo attuale è inferiore. */
    fun isBelowThreshold(balance: BigDecimal, threshold: BigDecimal?): Boolean = threshold != null && balance < threshold

    /** Conti non esclusi prima, poi gli esclusi, mantenendo l'ordine relativo. */
    fun <T> includedFirst(items: List<T>, excluded: (T) -> Boolean): List<T> = items.sortedBy { excluded(it) }
}
