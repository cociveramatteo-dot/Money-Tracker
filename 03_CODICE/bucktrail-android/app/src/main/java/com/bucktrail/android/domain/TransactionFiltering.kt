package com.bucktrail.android.domain

import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/** Filtro lista Movimenti (§4.2, `filtered(for:)`): tutti i criteri in AND. */
object TransactionFiltering {
    enum class TypeFilter { All, Fixed, Transfer, Expense, Income }

    data class Criteria(
        val query: String = "",
        val type: TypeFilter = TypeFilter.All,
        val month: YearMonth,
        val category: String? = null,
        val minText: String = "",
        val maxText: String = "",
        val useDates: Boolean = false,
        val from: LocalDate? = null,
        val to: LocalDate? = null,
    )

    data class Row(
        val name: String, val type: String, val isFixed: Boolean, val isTransfer: Boolean,
        val category: String, val amount: BigDecimal, val date: Instant,
    )

    fun matches(row: Row, c: Criteria, zone: ZoneId): Boolean {
        val q = KeywordCategoryClassifier.fold(c.query.trim())
        val day = row.date.atZone(zone).toLocalDate()
        // periodo personalizzato sostituisce il mese; con testo di ricerca il mese è ignorato (cerca in tutto lo storico)
        if (c.useDates && c.from != null && c.to != null) {
            if (day < c.from || day > c.to) return false
        } else if (q.isEmpty() && YearMonth.from(day) != c.month) return false
        if (q.isNotEmpty() && !KeywordCategoryClassifier.fold(row.name).contains(q)) return false
        val typeOk = when (c.type) {
            TypeFilter.All -> true
            TypeFilter.Fixed -> row.isFixed
            TypeFilter.Transfer -> row.isTransfer
            TypeFilter.Expense -> row.type == Amounts.TYPE_EXPENSE && !row.isTransfer
            TypeFilter.Income -> row.type == Amounts.TYPE_INCOME && !row.isTransfer
        }
        if (!typeOk) return false
        if (c.category != null && row.category != c.category) return false
        parse(c.minText)?.let { if (row.amount < it) return false }
        parse(c.maxText)?.let { if (row.amount > it) return false }
        return true
    }

    fun <T> filter(items: List<T>, c: Criteria, zone: ZoneId, row: (T) -> Row): List<T> = items.filter { matches(row(it), c, zone) }

    private fun parse(text: String): BigDecimal? = if (text.isBlank()) null else Amounts.parse(text.trim())

    /** Conteggio del badge: (minimo non vuoto) + (massimo non vuoto) + (periodo attivo). */
    fun activeCount(minText: String, maxText: String, useDates: Boolean): Int =
        (if (minText.isNotEmpty()) 1 else 0) + (if (maxText.isNotEmpty()) 1 else 0) + (if (useDates) 1 else 0)

    enum class SummaryKind { AtLeast, AtMost, Range, Count }

    /** Etichetta del chip verde: solo min, solo max, min+max senza date, altrimenti «Filtri (N)». */
    fun summaryKind(minText: String, maxText: String, useDates: Boolean): SummaryKind {
        val hasMin = minText.isNotEmpty(); val hasMax = maxText.isNotEmpty()
        return when {
            hasMin && !hasMax && !useDates -> SummaryKind.AtLeast
            !hasMin && hasMax && !useDates -> SummaryKind.AtMost
            hasMin && hasMax && !useDates -> SummaryKind.Range
            else -> SummaryKind.Count
        }
    }
}
