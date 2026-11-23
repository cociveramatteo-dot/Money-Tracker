package com.bucktrail.android.domain

import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId

/**
 * Report PDF mensile (§4.5): impaginazione pura (A4 595,2×841,8 pt, margine 44) con le stesse misure di `PDFReportGenerator`.
 * Restituisce le pagine come elenco di operazioni di disegno; `PdfRenderer` le stampa su `PdfDocument`.
 */
object PdfReport {
    const val PAGE_W = 595.2f
    const val PAGE_H = 841.8f
    const val MARGIN = 44f
    private const val CONTENT_W = PAGE_W - 2 * MARGIN

    enum class Tone { Ink, Smoke, Fog }
    enum class Weight { Regular, Medium, Semibold, Black }

    sealed interface Op
    /** `y` = bordo alto del testo; `maxWidth` tronca con «…»; `alignRight` allinea il bordo destro a `x`. */
    data class Text(val text: String, val x: Float, val y: Float, val size: Float, val weight: Weight, val tone: Tone, val kern: Float = 0f, val alignRight: Boolean = false, val maxWidth: Float? = null) : Op
    data class Line(val y: Float) : Op
    data class Bar(val x: Float, val y: Float, val w: Float, val h: Float, val tone: Tone) : Op

    class Tx(val name: String, val amount: BigDecimal, val date: LocalDate, val isIncome: Boolean, val isDone: Boolean, val isTransfer: Boolean, val category: String)

    class Labels(
        val brand: String, val expenses: String, val income: String, val net: String, val vsPrevious: String,
        val categoriesTitle: String, val movementsTitle: String, val category: (String) -> String,
    )

    fun fileName(month: YearMonth) = "report_$month.pdf"

    fun layout(month: YearMonth, monthTitle: String, transactions: List<Tx>, prevSpent: BigDecimal, labels: Labels, money: (BigDecimal) -> String, dayMonth: (LocalDate) -> String): List<List<Op>> {
        val pages = ArrayList<MutableList<Op>>()
        var ops = ArrayList<Op>().also { pages.add(it) }
        fun newPage() { ops = ArrayList<Op>().also { pages.add(it) } }

        // I trasferimenti restano nell'elenco ma non contano nei totali né per categoria.
        val done = transactions.filter { it.isDone && !it.isTransfer }
        val uscite = done.filter { !it.isIncome }.fold(BigDecimal.ZERO) { a, t -> a + t.amount }
        val entrate = done.filter { it.isIncome }.fold(BigDecimal.ZERO) { a, t -> a + t.amount }
        val cats = done.filter { !it.isIncome }.groupBy { it.category }.mapValues { (_, l) -> l.fold(BigDecimal.ZERO) { a, t -> a + t.amount } }
            .entries.sortedWith(compareByDescending<Map.Entry<String, BigDecimal>> { it.value }.thenBy { it.key })

        var y = MARGIN
        ops += Text(labels.brand.uppercase(), MARGIN, y, 10f, Weight.Semibold, Tone.Smoke, kern = 1.5f)
        ops += Text(monthTitle, PAGE_W - MARGIN, y, 10f, Weight.Semibold, Tone.Smoke, alignRight = true)
        val bigY = y + 20
        ops += Text(monthTitle.uppercase(), MARGIN, bigY, 28f, Weight.Black, Tone.Ink)
        y = bigY + 36
        y += 24; ops += Line(y); y += 20

        // Riepilogo a 3 colonne
        val colW = CONTENT_W / 3
        listOf(labels.expenses to 0, labels.income to 1, labels.net to 2).forEach { (l, i) ->
            ops += Text(l.uppercase(), MARGIN + colW * i, y, 9f, Weight.Semibold, Tone.Smoke, kern = 1.2f)
        }
        y += 16
        listOf(uscite, entrate, entrate - uscite).forEachIndexed { i, v -> ops += Text(money(v), MARGIN + colW * i, y, 22f, Weight.Black, Tone.Ink) }
        y += 30
        if (prevSpent.signum() > 0) {
            val delta = uscite - prevSpent
            val pct = Statistics.deltaPercent(uscite, prevSpent)
            ops += Text("${if (delta.signum() >= 0) "+" else "−"}$pct% ${labels.vsPrevious}", MARGIN, y, 11f, Weight.Regular, Tone.Smoke)
            y += 16
        }
        y += 24; ops += Line(y); y += 20

        // Uscite per categoria (max 8)
        ops += Text(labels.categoriesTitle.uppercase(), MARGIN, y, 9f, Weight.Semibold, Tone.Smoke, kern = 1.2f)
        y += 16
        for (cat in cats.take(8)) {
            val pct = if (uscite.signum() > 0) minOf(cat.value.toDouble() / uscite.toDouble(), 1.0) else 0.0
            if (y + 28 > PAGE_H - MARGIN) { newPage(); y = MARGIN }
            ops += Text(labels.category(cat.key), MARGIN, y, 13f, Weight.Regular, Tone.Ink)
            ops += Text(money(cat.value) + "  ${Math.round(pct * 100)}%", PAGE_W - MARGIN, y + 2, 11f, Weight.Medium, Tone.Smoke, alignRight = true)
            y += 16
            ops += Bar(MARGIN, y, CONTENT_W, 2f, Tone.Fog)
            if (pct > 0) ops += Bar(MARGIN, y, (CONTENT_W * pct).toFloat(), 2f, Tone.Ink)
            y += 2 + 8
        }
        y += 20; ops += Line(y); y += 20

        // Movimenti (solo quelli fatti, trasferimenti inclusi)
        ops += Text(labels.movementsTitle.uppercase(), MARGIN, y, 9f, Weight.Semibold, Tone.Smoke, kern = 1.2f)
        y += 16
        for (t in transactions.sortedByDescending { it.date }) {
            if (y + 22 > PAGE_H - MARGIN) { newPage(); y = MARGIN }
            ops += Text(dayMonth(t.date), MARGIN, y, 11f, Weight.Regular, Tone.Smoke)
            ops += Text(t.name, MARGIN + 52, y, 11f, Weight.Regular, Tone.Ink, maxWidth = CONTENT_W - 110)
            ops += Text((if (t.isIncome) "+" else "−") + money(t.amount), PAGE_W - MARGIN, y, 11f, Weight.Medium, if (t.isDone) Tone.Ink else Tone.Smoke, alignRight = true)
            y += 22
            ops += Line(y - 1)
        }
        return pages
    }

    /** Transazioni fatte del mese (come i `PDFTxSnapshot` iOS), pronte per `layout`. */
    fun transactionsOf(all: List<TransactionData>, month: YearMonth, zone: ZoneId): List<Tx> =
        all.filter { it.isDone && YearMonth.from(it.date.atZone(zone)) == month }
            .map { Tx(it.name, it.amount, it.date.atZone(zone).toLocalDate(), it.type == Amounts.TYPE_INCOME, it.isDone, it.isTransfer, it.category) }
}
