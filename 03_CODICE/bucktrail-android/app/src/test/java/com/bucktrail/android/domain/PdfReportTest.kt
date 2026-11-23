package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.LocalDate
import java.time.YearMonth

class PdfReportTest {
    private val labels = PdfReport.Labels("Bucktrail", "Uscite", "Entrate", "Netto", "rispetto al mese precedente", "Uscite per categoria", "Movimenti") { it }
    private val month = YearMonth.of(2026, 11)
    private fun tx(day: Int, amount: String, income: Boolean = false, category: String = "Cibo", done: Boolean = true, transfer: Boolean = false, name: String = "Voce") =
        PdfReport.Tx(name, BigDecimal(amount), LocalDate.of(2026, 11, day), income, done, transfer, category)
    private fun run(txs: List<PdfReport.Tx>, prev: String = "0") =
        PdfReport.layout(month, "Novembre 2026", txs, BigDecimal(prev), labels, { "€" + it.toPlainString() }, { "${it.dayOfMonth} nov" })
    private fun List<List<PdfReport.Op>>.texts() = flatten().filterIsInstance<PdfReport.Text>()

    @Test fun headerAndSummaryExcludeTransfersAndPlanned() {
        val pages = run(listOf(tx(1, "100"), tx(2, "40", category = "Svago"), tx(3, "500", income = true, category = "Lavoro"), tx(4, "180", transfer = true, category = "Giroconto"), tx(5, "9", done = false)), prev = "100")
        val t = pages.texts().map { it.text }
        assertEquals(1, pages.size)
        assertEquals("BUCKTRAIL", t[0]); assertEquals("Novembre 2026", t[1]); assertEquals("NOVEMBRE 2026", t[2])
        assertTrue(t.containsAll(listOf("USCITE", "ENTRATE", "NETTO", "€140", "€500", "€360", "+40% rispetto al mese precedente")))
        assertEquals(PdfReport.Weight.Black, pages.texts()[2].weight)
        assertEquals(28f, pages.texts()[2].size, 0f)
    }

    @Test fun categoriesCappedAtEightWithShareInsideBar() {
        val txs = (1..10).map { tx(it, "${100 - it}", category = "C$it") }
        val rows = run(txs).texts().filter { it.size == 13f }
        assertEquals(8, rows.size)
        assertEquals("C1", rows.first().text)
        val bars = run(txs).flatten().filterIsInstance<PdfReport.Bar>()
        assertEquals(16, bars.size)
        assertEquals(PdfReport.PAGE_W - 2 * PdfReport.MARGIN, bars[0].w, 0.01f)
    }

    @Test fun movementsIncludeTransfersAndSignsAndPaginate() {
        val txs = (1..120).map { tx(1 + it % 28, "10", income = it % 5 == 0, transfer = it == 7, name = "Mov $it") }
        val pages = run(txs)
        assertTrue(pages.size >= 3)
        val amounts = pages.texts().filter { it.size == 11f && it.alignRight && (it.text.startsWith("+") || it.text.startsWith("−")) }
        assertEquals(120, amounts.size)
        assertTrue(amounts.all { it.y + 22 <= PdfReport.PAGE_H - PdfReport.MARGIN + 22 })
        assertEquals(PdfReport.MARGIN, pages[1].filterIsInstance<PdfReport.Text>().first().y, 0f)
    }

    @Test fun noPreviousMonthMeansNoComparisonLine() {
        assertTrue(run(listOf(tx(1, "10"))).texts().none { it.text.contains("rispetto al mese") })
    }

    @Test fun fileNameFollowsMonth() = assertEquals("report_2026-11.pdf", PdfReport.fileName(month))
}
