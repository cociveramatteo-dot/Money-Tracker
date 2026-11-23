package com.bucktrail.android.data

import android.content.Context
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.R
import kotlinx.coroutines.flow.first
import com.bucktrail.android.domain.QuickAdd
import com.bucktrail.android.ui.Fmt
import java.util.UUID

/**
 * Inserimento rapido e saldo senza aprire l'app (equivalente degli App Intent iOS): scrivono nel database REALE
 * tramite lo stesso DAO e marcano il movimento da sincronizzare (come `markTransactionDirty` su iOS).
 */
object QuickAddOps {
    sealed interface Outcome {
        data class Saved(val message: String) : Outcome
        data class Invalid(val problem: QuickAdd.Problem) : Outcome
        data object Failed : Outcome
    }

    suspend fun save(
        context: Context, kind: QuickAdd.Kind, name: String, amount: Double, accountName: String?, category: String?,
    ): Outcome {
        QuickAdd.validate(name, amount)?.let { return Outcome.Invalid(it) }
        val app = context.applicationContext as BucktrailApplication
        return runCatching {
            val dao = app.database.dao()
            val accounts = dao.accounts().sortedBy { it.createdAt }
            val categories = dao.categories()
            val suggested = ClassifierProvider.classify(app, name)
            val draft = QuickAdd.draft(
                kind, name, amount, accounts.map { it.toData() }, accountName, category, suggested,
                categories.sortedBy { it.sortOrder }.map { it.name }, iconOf = { n -> categories.firstOrNull { it.name == n }?.icon },
            )
            val tx = TransactionEntity(
                id = UUID.randomUUID().toString(), accountId = draft.accountId, name = draft.name, amountCents = com.bucktrail.android.domain.Amounts.toCents(draft.amount),
                type = draft.type, category = draft.category, categoryIcon = draft.icon, date = System.currentTimeMillis(), isDone = true,
            )
            dao.upsert(tx)
            app.markTransactionChanged(tx.id)
            val on = draft.accountName?.let { " ${app.getString(R.string.su_conto_suffisso, it)}" }.orEmpty()
            val text = if (kind == QuickAdd.Kind.Expense) app.getString(R.string.s_2f_per_salvato_9b5fb3, amount, draft.name + on)
            else app.getString(R.string.s_2f_salvato_424b7d, amount, draft.name + on)
            Outcome.Saved(text)
        }.getOrElse { Outcome.Failed }
    }

    /** Testo del «Controlla saldo» iOS; con importi oscurati se la privacy lo richiede. */
    suspend fun balanceText(context: Context, hidden: Boolean): String {
        val app = context.applicationContext as BucktrailApplication
        val dao = app.database.dao()
        val accounts = dao.accounts().sortedBy { it.createdAt }.map { it.toData() }
        val summary = QuickAdd.balanceSummary(accounts, dao.transactions().map { it.toData() })
            ?: return app.getString(R.string.nessun_conto_trovato_apri_l_app_per_aggi)
        val currency = app.prefs.state.first().currencyCode
        fun money(v: java.math.BigDecimal) = if (hidden) Fmt.HIDDEN_HOME else Fmt.currency(v, currency)
        return buildString {
            append(app.getString(R.string.saldo_totale, money(summary.total))).append('\n')
            summary.lines.forEach { append("${it.emoji} ${it.name}: ${money(it.balance)}\n") }
        }.trimEnd()
    }
}
