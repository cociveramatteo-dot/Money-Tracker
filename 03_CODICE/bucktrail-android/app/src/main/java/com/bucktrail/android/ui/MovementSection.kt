package com.bucktrail.android.ui

import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.KeywordCategoryClassifier
import com.bucktrail.android.domain.Occurrence
import com.bucktrail.android.domain.TransactionFiltering
import com.bucktrail.android.ui.screens.amountValue
import com.bucktrail.android.ui.screens.localDate
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

enum class MovementSection(val tag: String) {
    All("Tutti"),
    Fixed("Fisse"),
    Transfer("Trasf."),
    Expense("Uscite"),
    Income("Entrate"),
    Recurring("Ricorrenti"),
    ;

    fun toTypeFilter(): TransactionFiltering.TypeFilter? = when (this) {
        All -> TransactionFiltering.TypeFilter.All
        Fixed -> TransactionFiltering.TypeFilter.Fixed
        Transfer -> TransactionFiltering.TypeFilter.Transfer
        Expense -> TransactionFiltering.TypeFilter.Expense
        Income -> TransactionFiltering.TypeFilter.Income
        Recurring -> null
    }
}

object MovementSectionFilter {
    fun filterTransactions(
        transactions: List<TransactionEntity>,
        section: MovementSection,
        ruleIds: Set<String>,
        query: String,
        month: YearMonth,
        category: String?,
        minText: String,
        maxText: String,
        useDates: Boolean,
        from: LocalDate?,
        to: LocalDate?,
        zone: ZoneId,
    ): List<TransactionEntity> {
        val typeFilter = section.toTypeFilter()
        if (typeFilter != null) {
            val criteria = TransactionFiltering.Criteria(
                query = query,
                type = typeFilter,
                month = month,
                category = category,
                minText = minText,
                maxText = maxText,
                useDates = useDates,
                from = from,
                to = to,
            )
            return TransactionFiltering.filter(transactions, criteria, zone) {
                TransactionFiltering.Row(
                    it.name,
                    it.type,
                    it.isFixed,
                    it.isTransfer,
                    it.category,
                    it.amountValue(),
                    Instant.ofEpochMilli(it.date),
                )
            }
        }

        val q = KeywordCategoryClassifier.fold(query.trim())
        val minAmt = parseAmount(minText)
        val maxAmt = parseAmount(maxText)
        return transactions.filter { t ->
            if (t.templateId.isEmpty() || t.templateId.lowercase() !in ruleIds) return@filter false
            val day = t.localDate(zone)
            // In Ricorrenti il mese scelto vale sempre (anche con ricerca attiva): niente storico dei mesi precedenti.
            if (YearMonth.from(day) != month) return@filter false
            if (useDates && from != null && to != null && (day < from || day > to)) return@filter false
            if (q.isNotEmpty() && !KeywordCategoryClassifier.fold(t.name).contains(q)) return@filter false
            if (category != null && t.category != category) return@filter false
            val amt = t.amountValue()
            if (minAmt != null && amt < minAmt) return@filter false
            if (maxAmt != null && amt > maxAmt) return@filter false
            true
        }
    }

    fun filterVirtual(
        occurrences: List<Pair<RecurringRuleEntity, Occurrence>>,
        realIds: Set<String>,
        section: MovementSection,
        query: String,
        category: String?,
        minText: String,
        maxText: String,
        useDates: Boolean,
        from: LocalDate?,
        to: LocalDate?,
        zone: ZoneId,
    ): List<Pair<RecurringRuleEntity, Occurrence>> {
        val q = KeywordCategoryClassifier.fold(query.trim())
        val minAmt = parseAmount(minText)
        val maxAmt = parseAmount(maxText)
        return occurrences.filter { (_, o) ->
            if (o.id.toString() in realIds) return@filter false
            val sectionOk = when (section) {
                MovementSection.All, MovementSection.Recurring -> true
                MovementSection.Fixed -> o.isFixed
                MovementSection.Expense -> o.type == Amounts.TYPE_EXPENSE
                MovementSection.Income -> o.type == Amounts.TYPE_INCOME
                MovementSection.Transfer -> false
            }
            if (!sectionOk) return@filter false
            if (category != null && o.category != category) return@filter false
            if (q.isNotEmpty() && !KeywordCategoryClassifier.fold(o.name).contains(q)) return@filter false
            if (minAmt != null && o.amount < minAmt) return@filter false
            if (maxAmt != null && o.amount > maxAmt) return@filter false
            if (useDates && from != null && to != null) {
                val day = o.date.atZone(zone).toLocalDate()
                if (day < from || day > to) return@filter false
            }
            true
        }.sortedBy { it.second.date }
    }

    private fun parseAmount(text: String): BigDecimal? =
        if (text.isBlank()) null else Amounts.parse(text.trim())
}
