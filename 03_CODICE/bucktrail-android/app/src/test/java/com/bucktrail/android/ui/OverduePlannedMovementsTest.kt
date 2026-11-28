package com.bucktrail.android.ui

import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.AccountData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.HomeProjection
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.ZoneId

class OverduePlannedMovementsTest {
    private val zone = ZoneId.of("UTC")
    private fun millis(day: Int, month: Int) =
        LocalDate.of(2026, month, day).atTime(12, 0).atZone(zone).toInstant().toEpochMilli()

    @Test
    fun detectsOnlyPastMonthUnconfirmedNonTransfersAndConfirmingScalesBalance() {
        val nov28 = LocalDate.of(2026, 11, 28)
        val pastPlanned = TransactionEntity("t1", "a1", "Bolletta ottobre", amountCents = 80_00, type = Amounts.TYPE_EXPENSE, date = millis(20, 10), isDone = false, isFixed = false)
        val pastFixed = TransactionEntity("t2", "a1", "Assicurazione ott", amountCents = 120_00, type = Amounts.TYPE_EXPENSE, date = millis(15, 10), isDone = false, isFixed = true)
        val pastDone = TransactionEntity("t3", "a1", "Pagata ott", amountCents = 40_00, type = Amounts.TYPE_EXPENSE, date = millis(12, 10), isDone = true, isFixed = true)
        val pastTransfer = TransactionEntity("t4", "a1", "Giro ott", amountCents = 50_00, type = Amounts.TYPE_EXPENSE, date = millis(10, 10), isDone = false, isTransfer = true)
        val thisMonth = TransactionEntity("t5", "a1", "Cena nov", amountCents = 30_00, type = Amounts.TYPE_EXPENSE, date = millis(29, 11), isDone = false)
        val nextMonth = TransactionEntity("t6", "a1", "Fissa dic", amountCents = 200_00, type = Amounts.TYPE_EXPENSE, date = millis(12, 12), isDone = false, isFixed = true)

        val all = listOf(pastPlanned, pastFixed, pastDone, pastTransfer, thisMonth, nextMonth)
        val overdue = OverduePlannedMovements.list(all, nov28, zone)
        assertEquals(listOf("t1", "t2"), overdue.map { it.id })

        // Previsione di novembre esclude i pianificati singoli di ottobre e dicembre (solo -40 fatta, -50 trasferimento, -30 nov -> 880).
        val account = AccountData("a1", "Conto", "Conto Bancario", BigDecimal("1000.00"))
        val txData = all.map { it.toData() }
        assertEquals(0, BigDecimal("960.00").compareTo(Balance.current(account, txData)))
        assertEquals(0, BigDecimal("880.00").compareTo(HomeProjection.make(listOf(account), txData, nov28, zone).trail.expectedBalance))

        // Confermando pastPlanned: sparisce da Da confermare e scala Balance.current di 80.
        val afterConfirm = all.map { if (it.id == "t1") it.copy(isDone = true) else it }
        assertEquals(listOf("t2"), OverduePlannedMovements.list(afterConfirm, nov28, zone).map { it.id })
        assertEquals(0, BigDecimal("880.00").compareTo(Balance.current(account, afterConfirm.map { it.toData() })))

        // Filtri sezione Movimenti.
        assertEquals(listOf("t2"), OverduePlannedMovements.matchingSection(overdue, MovementSection.Fixed, emptySet()).map { it.id })
        assertEquals(emptyList<String>(), OverduePlannedMovements.matchingSection(overdue, MovementSection.Transfer, emptySet()).map { it.id })
    }
}
