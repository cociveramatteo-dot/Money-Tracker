package com.bucktrail.android.data

import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.domain.Categories
import java.util.UUID

/** Costruzione dei movimenti compositi (trasferimenti, rettifiche): funzioni pure, testabili senza Room. */
object TransactionOps {
    const val TRANSFER_OUT_PREFIX = "Trasferimento → "
    const val TRANSFER_IN_PREFIX = "Trasferimento ← "

    data class TransferInput(
        val fromId: String, val fromName: String, val toId: String, val toName: String,
        val amountCents: Long, val date: Long, val done: Boolean, val notes: String,
    )

    /** Due gambe con lo stesso `transferGroupId` (UUID maiuscolo): Uscita sul conto Da, Entrata sul conto A (§3.7). */
    fun newTransfer(i: TransferInput, now: Long = System.currentTimeMillis(), groupId: String = UUID.randomUUID().toString().uppercase()): List<TransactionEntity> =
        listOf(
            leg(TransactionEntity(name = "", amountCents = 0, type = "", date = 0, createdAt = now), i, groupId, out = true),
            leg(TransactionEntity(name = "", amountCents = 0, type = "", date = 0, createdAt = now), i, groupId, out = false),
        )

    /** Modifica: aggiorna entrambe le gambe (nome, importo, data, note, isDone, conto) mantenendo id e gruppo. */
    fun updateTransfer(outLeg: TransactionEntity, inLeg: TransactionEntity, i: TransferInput): List<TransactionEntity> =
        listOf(leg(outLeg, i, outLeg.transferGroupId, out = true), leg(inLeg, i, outLeg.transferGroupId, out = false))

    private fun leg(base: TransactionEntity, i: TransferInput, groupId: String, out: Boolean) = base.copy(
        accountId = if (out) i.fromId else i.toId,
        name = if (out) TRANSFER_OUT_PREFIX + i.toName else TRANSFER_IN_PREFIX + i.fromName,
        amountCents = i.amountCents,
        type = if (out) Amounts.TYPE_EXPENSE else Amounts.TYPE_INCOME,
        category = Categories.TRANSFER, categoryIcon = Categories.TRANSFER_ICON,
        date = i.date, isDone = i.done, isFixed = false, isTransfer = true, transferGroupId = groupId, notes = i.notes,
    )

    /** Gambe gemelle: stesso gruppo (senza distinzione di maiuscole) e id diverso. */
    fun twinsOf(t: TransactionEntity, all: List<TransactionEntity>): List<TransactionEntity> =
        if (!t.isTransfer || t.transferGroupId.isEmpty()) emptyList()
        else all.filter { it.id != t.id && it.transferGroupId.equals(t.transferGroupId, ignoreCase = true) }

    fun withDone(t: TransactionEntity, twins: List<TransactionEntity>, done: Boolean): List<TransactionEntity> =
        (listOf(t) + twins).map { it.copy(isDone = done) }

    /** Rettifica saldo (§4.7): categoria «Rettifica saldo», data oggi, fatta. */
    fun adjustment(accountId: String, change: AccountEditing.BalanceChange.Adjust, adjustmentName: String, icon: String, now: Long): TransactionEntity =
        TransactionEntity(
            accountId = accountId, name = adjustmentName, amountCents = Amounts.toCents(change.amount), type = change.type,
            category = Categories.ADJUSTMENT, categoryIcon = icon, date = now, isDone = true, createdAt = now,
        )
}
