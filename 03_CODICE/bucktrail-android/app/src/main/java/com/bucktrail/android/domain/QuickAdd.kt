package com.bucktrail.android.domain

import java.math.BigDecimal

/**
 * Logica 1:1 degli App Intent iOS (`AddExpenseIntent`, `AddIncomeIntent`, `CheckBalanceIntent`) per le scorciatoie Android:
 * stesse validazioni, stessa scelta di conto e categoria, stesso testo del saldo. Funzioni pure.
 */
object QuickAdd {
    enum class Kind { Expense, Income }
    enum class Problem { InvalidAmount, EmptyName }

    data class Draft(val name: String, val amount: BigDecimal, val type: String, val accountId: String?, val accountName: String?, val category: String, val icon: String)

    /** Importo > 0, finito, ≤ 1 miliardo; nome non vuoto (dopo il trim). */
    fun validate(name: String, amount: Double): Problem? = when {
        !amount.isFinite() || amount <= 0.0 || amount > 1e9 -> Problem.InvalidAmount
        name.trim().isEmpty() -> Problem.EmptyName
        else -> null
    }

    /** Conto per nome esatto, altrimenti il primo (Android: i non archiviati prima, in ordine di creazione). */
    fun pickAccount(accounts: List<AccountData>, requested: String?): AccountData? =
        accounts.firstOrNull { it.name == requested } ?: accounts.firstOrNull { !it.isArchived } ?: accounts.firstOrNull()

    /**
     * Spesa: classificatore se ≠ «Altro», altrimenti la categoria fornita, altrimenti «Altro».
     * Entrata: classificatore se ≠ «Altro», altrimenti «Lavoro» (o la prima categoria, o «Lavoro»).
     */
    fun category(kind: Kind, suggested: String, requested: String?, knownCategories: List<String>): String {
        if (suggested != Categories.OTHER && suggested.isNotEmpty()) return suggested
        return when (kind) {
            Kind.Expense -> requested?.takeIf { it.isNotBlank() } ?: Categories.OTHER
            Kind.Income -> knownCategories.firstOrNull { it == "Lavoro" } ?: knownCategories.firstOrNull() ?: "Lavoro"
        }
    }

    fun draft(
        kind: Kind, name: String, amount: Double, accounts: List<AccountData>, requestedAccount: String?, requestedCategory: String?,
        suggested: String, knownCategories: List<String>, iconOf: (String) -> String?,
    ): Draft {
        val trimmed = name.trim()
        val account = pickAccount(accounts, requestedAccount)
        val category = category(kind, suggested, requestedCategory, knownCategories)
        return Draft(
            trimmed, Amounts.roundedFromDouble(amount), if (kind == Kind.Expense) Amounts.TYPE_EXPENSE else Amounts.TYPE_INCOME,
            account?.id, account?.name, category, iconOf(category) ?: Categories.iconFor(category),
        )
    }

    /** Emoji del tipo di conto (`Account.emoji` iOS). */
    fun emoji(type: String): String = when (AccountType.from(type)) {
        AccountType.Cash -> "💵"; AccountType.Card -> "💳"; AccountType.Checking -> "🏦"; AccountType.Savings -> "🐷"; AccountType.Investment -> "📈"
    }

    data class BalanceLine(val emoji: String, val name: String, val balance: BigDecimal)
    data class BalanceSummary(val total: BigDecimal, val lines: List<BalanceLine>)

    /** Conti non archiviati; totale = somma dei saldi dei non esclusi. `null` = nessun conto. */
    fun balanceSummary(accounts: List<AccountData>, txs: List<TransactionData>): BalanceSummary? {
        val live = accounts.filter { !it.isArchived }
        if (live.isEmpty()) return null
        val total = live.filter { !it.isExcludedFromTotal }.fold(BigDecimal.ZERO) { a, acc -> a + Balance.current(acc, txs) }
        return BalanceSummary(total, live.map { BalanceLine(emoji(it.type), it.name, Balance.current(it, txs)) })
    }

    /** Link profondi `bucktrail://add?kind=expense|income&name=&amount=&account=&category=` e `bucktrail://balance`. */
    sealed interface Link {
        data class Add(val kind: Kind, val name: String, val amount: String, val account: String?, val category: String?) : Link
        data object Balance : Link
        data object Home : Link
    }

    fun parseLink(raw: String?): Link? {
        val uri = raw ?: return null
        if (!uri.startsWith("bucktrail://")) return null
        val rest = uri.removePrefix("bucktrail://")
        val host = rest.substringBefore("?").trimEnd('/')
        val query = rest.substringAfter("?", "").split("&").filter { it.contains("=") }.associate {
            it.substringBefore("=") to java.net.URLDecoder.decode(it.substringAfter("="), "UTF-8")
        }
        return when (host) {
            "add" -> Link.Add(if (query["kind"] == "income") Kind.Income else Kind.Expense, query["name"].orEmpty(), query["amount"].orEmpty(), query["account"], query["category"])
            "balance" -> Link.Balance
            "home", "" -> Link.Home
            else -> null
        }
    }
}
