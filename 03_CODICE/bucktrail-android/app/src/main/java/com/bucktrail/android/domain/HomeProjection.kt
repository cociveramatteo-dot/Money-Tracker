package com.bucktrail.android.domain

import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/**
 * Saldo, serie del mese e pianificati per conto della Home (funzione pura; la usano anche il widget e lo Scorciatoie).
 * Competenza mensile (S-41): una spesa fissa singola futura non fatta di un altro mese non entra nel saldo atteso di questo.
 */
data class HomeProjection(val total: BigDecimal, val trail: BalanceTrail, val plannedByAccount: Map<String?, BigDecimal>) {
    companion object {
        fun countsInMonth(t: TransactionData, month: YearMonth, zone: ZoneId): Boolean {
            val isOneOffFixedExpense = t.isFixed && t.type == Amounts.TYPE_EXPENSE &&
                !t.isTransfer && t.templateId.isEmpty() && t.recurringFrequency.isEmpty()
            if (t.isDone || !isOneOffFixedExpense) return true
            return YearMonth.from(t.date.atZone(zone)) == month
        }

        fun make(accounts: List<AccountData>, txs: List<TransactionData>, today: LocalDate, zone: ZoneId): HomeProjection {
            val month = YearMonth.from(today)
            val ids = Balance.included(accounts).map { it.id }.toSet()
            val entries = txs.filter { it.accountId in ids && countsInMonth(it, month, zone) }
            val total = Balance.total(accounts, txs)
            val trail = BalanceTrail.make(total, entries.map { BalanceTrail.Entry(it.date, it.signedAmount, it.isDone) }, today.atTime(12, 0).atZone(zone).toInstant(), zone)
            val planned = entries.filter { !it.isDone }.groupBy { it.accountId }
                .mapValues { (_, v) -> v.fold(BigDecimal.ZERO) { a, t -> a + t.signedAmount } }
            return HomeProjection(total, trail, planned)
        }
    }
}
