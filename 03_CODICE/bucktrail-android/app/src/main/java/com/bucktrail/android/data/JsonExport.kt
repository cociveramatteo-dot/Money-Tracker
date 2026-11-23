package com.bucktrail.android.data

import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.PrettyJson
import com.bucktrail.android.domain.PrettyJson.Num
import java.time.Instant
import java.time.temporal.ChronoUnit

/** Export completo del profilo (§5.6, GDPR art. 20): conti, movimenti, budget e obiettivi; non include regole né categorie. */
object JsonExport {
    const val FILE_NAME = "i-miei-dati-moneytracker.json"

    private fun iso(millis: Long) = Instant.ofEpochMilli(millis).truncatedTo(ChronoUnit.SECONDS).toString()
    private fun money(cents: Long) = Num(Amounts.fromCents(cents).stripTrailingZeros().toPlainString())
    private fun id(raw: String) = raw.uppercase()

    fun build(
        accounts: List<AccountEntity>, transactions: List<TransactionEntity>, budgets: List<BudgetEntity>, goals: List<GoalEntity>,
        exportedAt: Instant, userEmail: String? = null,
    ): String {
        val names = accounts.associate { it.id to it.name }
        fun Map<String, Any?>.dropNull() = filterValues { it != null }
        val root = mapOf(
            "exportedAt" to exportedAt.truncatedTo(ChronoUnit.SECONDS).toString(),
            "userEmail" to userEmail,
            "accounts" to accounts.map {
                mapOf("id" to id(it.id), "name" to it.name, "type" to it.type, "initialBalance" to money(it.initialBalanceCents),
                    "isArchived" to it.isArchived, "isExcludedFromTotal" to it.isExcludedFromTotal, "createdAt" to iso(it.createdAt))
            },
            "transactions" to transactions.map {
                mapOf("id" to id(it.id), "name" to it.name, "type" to it.type, "category" to it.category, "notes" to it.notes,
                    "amount" to money(it.amountCents), "date" to iso(it.date), "createdAt" to iso(it.createdAt), "isDone" to it.isDone,
                    "isFixed" to it.isFixed, "isTransfer" to it.isTransfer, "accountName" to it.accountId?.let { a -> names[a] }).dropNull()
            },
            "budgets" to budgets.map {
                mapOf("id" to id(it.id), "category" to it.category, "monthlyLimit" to money(it.monthlyLimitCents), "month" to Num("${it.month}"),
                    "year" to Num("${it.year}"), "accountName" to it.accountId?.let { a -> names[a] }).dropNull()
            },
            "goals" to goals.map {
                mapOf("id" to id(it.id), "name" to it.name, "targetAmount" to money(it.targetCents), "currentAmount" to money(it.currentCents),
                    "deadline" to it.deadline?.let(::iso), "isCompleted" to it.isCompleted).dropNull()
            },
        ).dropNull()
        return PrettyJson.write(root)
    }
}
