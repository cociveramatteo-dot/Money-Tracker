package com.bucktrail.android.sync

import com.bucktrail.android.data.LedgerState
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

class SyncServiceTest {
    @Test fun backoffDoublesUpToSixtySeconds() {
        assertEquals(listOf(2.0, 4.0, 8.0, 16.0, 32.0, 60.0, 60.0), (1..7).map { Backoff.seconds(it) })
    }

    private fun ledger(txs: List<com.bucktrail.android.data.TransactionEntity> = emptyList(), demo: Boolean = false, generation: Int = 0, accounts: List<com.bucktrail.android.data.AccountEntity> = listOf(account(A1))) =
        LedgerState(accounts = accounts, transactions = txs, demo = demo, generation = generation)

    @Test fun firstSnapshotIsTheBaselineNotAChange() {
        assertNull(ChangeWatcher().onState(ledger(listOf(tx(T1, A1)))))
    }

    @Test fun newAndEditedTransactionsAreReportedByIdAndRemovalOnlyFlagsPending() {
        val w = ChangeWatcher(); w.onState(ledger(listOf(tx(T1, A1))))
        assertEquals(setOf(T2), w.onState(ledger(listOf(tx(T1, A1), tx(T2, A1)))))
        assertEquals(setOf(T1), w.onState(ledger(listOf(tx(T1, A1, 99_00), tx(T2, A1)))))
        assertEquals(emptySet<String>(), w.onState(ledger(listOf(tx(T1, A1, 99_00))))) // cancellazione: nessun id sporco, ma serve un push
        assertNull(w.onState(ledger(listOf(tx(T1, A1, 99_00)))))                       // nessun cambiamento
    }

    @Test fun nonTransactionChangesAreDetectedToo() {
        val w = ChangeWatcher(); w.onState(ledger())
        assertEquals(emptySet<String>(), w.onState(ledger(accounts = listOf(account(A1, "Rinominato")))))
    }

    @Test fun demoAndSilentModeNeverReportChanges() {
        val w = ChangeWatcher(); w.onState(ledger(listOf(tx(T1, A1))))
        assertNull(w.onState(ledger(listOf(tx(T1, A1), tx(T2, A1)), demo = true)))
        w.onState(ledger(listOf(tx(T1, A1))))
        w.silent = true
        assertNull(w.onState(ledger(listOf(tx(T1, A1), tx(T2, A1)))))   // scritto dal sync stesso
        w.silent = false
        assertNull(w.onState(ledger(listOf(tx(T1, A1), tx(T2, A1)))))   // ormai è la base
    }

    @Test fun rebaseAfterAPullMakesItsRowsInvisibleToTheWatcher() {
        val w = ChangeWatcher(); w.onState(ledger(listOf(tx(T1, A1))))
        w.rebase(Snapshot(listOf(account(A1)), listOf(tx(T1, A1), tx(T3, A1))))
        assertNull(w.onState(ledger(listOf(tx(T1, A1), tx(T3, A1)))))
        assertTrue(w.onState(ledger(listOf(tx(T1, A1), tx(T3, A1), tx(T2, A1))))!!.contains(T2))
    }

    @Test fun aNewDatabaseGenerationResetsTheBaseline() {
        val w = ChangeWatcher(); w.onState(ledger(listOf(tx(T1, A1)), generation = 0))
        assertNull(w.onState(ledger(emptyList(), generation = 1)))
    }
}
