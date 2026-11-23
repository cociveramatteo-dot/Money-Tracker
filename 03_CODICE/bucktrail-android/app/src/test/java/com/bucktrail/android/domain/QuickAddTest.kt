package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant

/** Equivalenza con gli App Intent iOS (`AddExpenseIntent`, `AddIncomeIntent`, `CheckBalanceIntent`). */
class QuickAddTest {
    private fun acc(id: String, name: String, archived: Boolean = false, excluded: Boolean = false, type: String = "Conto Bancario", initial: String = "0") =
        AccountData(id, name, type, BigDecimal(initial), archived, excluded)

    private fun tx(accountId: String, cents: Long, type: String = Amounts.TYPE_EXPENSE, done: Boolean = true) =
        TransactionData("t$cents$accountId", accountId, "x", Amounts.fromCents(cents), type, date = Instant.parse("2026-11-01T10:00:00Z"), isDone = done)

    @Test fun amountMustBePositiveFiniteAndAtMostOneBillion() {
        assertEquals(QuickAdd.Problem.InvalidAmount, QuickAdd.validate("Caffè", 0.0))
        assertEquals(QuickAdd.Problem.InvalidAmount, QuickAdd.validate("Caffè", -3.0))
        assertEquals(QuickAdd.Problem.InvalidAmount, QuickAdd.validate("Caffè", Double.NaN))
        assertEquals(QuickAdd.Problem.InvalidAmount, QuickAdd.validate("Caffè", Double.POSITIVE_INFINITY))
        assertEquals(QuickAdd.Problem.InvalidAmount, QuickAdd.validate("Caffè", 1_000_000_000.01))
        assertNull(QuickAdd.validate("Caffè", 1_000_000_000.0))
        assertNull(QuickAdd.validate("Caffè", 0.01))
    }

    @Test fun nameMustNotBeBlank() {
        assertEquals(QuickAdd.Problem.EmptyName, QuickAdd.validate("   ", 5.0))
        assertEquals("amount wins when both are wrong", QuickAdd.Problem.InvalidAmount, QuickAdd.validate("", 0.0))
    }

    @Test fun accountByExactNameElseFirst() {
        val a = listOf(acc("1", "Conto"), acc("2", "Contanti"))
        assertEquals("2", QuickAdd.pickAccount(a, "Contanti")!!.id)
        assertEquals("1", QuickAdd.pickAccount(a, "contanti")!!.id) // nome esatto, maiuscole comprese
        assertEquals("1", QuickAdd.pickAccount(a, null)!!.id)
        assertNull(QuickAdd.pickAccount(emptyList(), null))
    }

    @Test fun archivedAccountIsNotPickedByDefaultOnAndroid() {
        val a = listOf(acc("1", "Vecchio", archived = true), acc("2", "Attivo"))
        assertEquals("2", QuickAdd.pickAccount(a, null)!!.id)
        assertEquals("1", QuickAdd.pickAccount(listOf(acc("1", "Vecchio", archived = true)), null)!!.id)
    }

    @Test fun expenseCategoryRules() {
        assertEquals("Cibo", QuickAdd.category(QuickAdd.Kind.Expense, "Cibo", "Svago", emptyList()))     // classificatore vince
        assertEquals("Svago", QuickAdd.category(QuickAdd.Kind.Expense, "Altro", "Svago", emptyList()))   // poi la fornita
        assertEquals("Altro", QuickAdd.category(QuickAdd.Kind.Expense, "Altro", null, emptyList()))
        assertEquals("Altro", QuickAdd.category(QuickAdd.Kind.Expense, "", "  ", emptyList()))
    }

    @Test fun incomeCategoryRules() {
        assertEquals("Risparmio", QuickAdd.category(QuickAdd.Kind.Income, "Risparmio", null, listOf("Lavoro")))
        assertEquals("Lavoro", QuickAdd.category(QuickAdd.Kind.Income, "Altro", null, listOf("Cibo", "Lavoro")))
        assertEquals("Cibo", QuickAdd.category(QuickAdd.Kind.Income, "Altro", null, listOf("Cibo", "Casa")))
        assertEquals("Lavoro", QuickAdd.category(QuickAdd.Kind.Income, "Altro", null, emptyList()))
    }

    @Test fun draftBuildsLikeTheIosIntent() {
        val d = QuickAdd.draft(
            QuickAdd.Kind.Expense, "  Pizza  ", 12.345, listOf(acc("1", "Conto")), "Altro conto", null, "Cibo", listOf("Cibo"),
            iconOf = { if (it == "Cibo") "fork.knife" else null },
        )
        assertEquals("Pizza", d.name); assertEquals(Amounts.TYPE_EXPENSE, d.type); assertEquals("1", d.accountId)
        assertEquals(BigDecimal("12.35"), d.amount) // String.format("%.2f") come `Decimal(roundedFromDouble:)`
        assertEquals("Cibo", d.category); assertEquals("fork.knife", d.icon)
        val i = QuickAdd.draft(QuickAdd.Kind.Income, "Stipendio", 1500.0, listOf(acc("1", "Conto")), null, null, "Altro", emptyList(), iconOf = { null })
        assertEquals(Amounts.TYPE_INCOME, i.type); assertEquals("Lavoro", i.category); assertEquals("briefcase.fill", i.icon)
    }

    @Test fun balanceTextMatchesTheIosLayout() {
        val accounts = listOf(
            acc("1", "Principale", initial = "1000"), acc("2", "Risparmi", type = "Risparmio", excluded = true, initial = "500"),
            acc("3", "Chiuso", archived = true, initial = "9"), acc("4", "Cash", type = "Contanti", initial = "50"),
        )
        val s = QuickAdd.balanceSummary(accounts, listOf(tx("1", 25_00), tx("4", 10_00, Amounts.TYPE_INCOME), tx("1", 99_00, done = false)))!!
        assertEquals(BigDecimal("1035.00").setScale(2), s.total.setScale(2)) // 975 + 60, escluso «Risparmi», archiviato fuori
        assertEquals(listOf("🏦 Principale", "🐷 Risparmi", "💵 Cash"), s.lines.map { "${it.emoji} ${it.name}" })
        assertEquals(BigDecimal("500.00"), s.lines[1].balance.setScale(2)) // l'escluso compare nelle righe ma non nel totale
    }

    @Test fun noAccountsMeansNoSummary() {
        assertNull(QuickAdd.balanceSummary(emptyList(), emptyList()))
        assertNull(QuickAdd.balanceSummary(listOf(acc("1", "x", archived = true)), emptyList()))
    }

    @Test fun accountTypeEmojisAreTheIosOnes() {
        assertEquals(listOf("💵", "💳", "🏦", "🐷", "📈", "🏦"), listOf("Contanti", "Carta", "Conto Bancario", "Risparmio", "Investimento", "boh").map(QuickAdd::emoji))
    }

    @Test fun deepLinks() {
        assertEquals(QuickAdd.Link.Add(QuickAdd.Kind.Expense, "", "", null, null), QuickAdd.parseLink("bucktrail://add"))
        assertEquals(QuickAdd.Link.Add(QuickAdd.Kind.Income, "Caff%", "3,5", "Cash", "Cibo"), QuickAdd.parseLink("bucktrail://add?kind=income&name=Caff%25&amount=3,5&account=Cash&category=Cibo"))
        assertEquals(QuickAdd.Link.Add(QuickAdd.Kind.Expense, "Pane e latte", "2", null, null), QuickAdd.parseLink("bucktrail://add?name=Pane+e+latte&amount=2"))
        assertEquals(QuickAdd.Link.Balance, QuickAdd.parseLink("bucktrail://balance"))
        assertEquals(QuickAdd.Link.Home, QuickAdd.parseLink("bucktrail://home"))
        assertNull(QuickAdd.parseLink("https://evil.example/add")); assertNull(QuickAdd.parseLink("bucktrail://nope")); assertNull(QuickAdd.parseLink(null))
    }

    @Test fun homeProjectionMatchesBalanceAndKeepsCompetenzaMensile() {
        val zone = java.time.ZoneId.of("Europe/Rome"); val today = java.time.LocalDate.of(2026, 11, 23)
        val accounts = listOf(acc("1", "Conto", initial = "1000"))
        val fixedNextMonth = tx("1", 80_00, done = false).copy(isFixed = true, date = Instant.parse("2026-12-05T10:00:00Z"), id = "fx")
        val plannedThisMonth = tx("1", 20_00, done = false).copy(date = Instant.parse("2026-11-28T10:00:00Z"), id = "pl")
        val p = HomeProjection.make(accounts, listOf(tx("1", 100_00), fixedNextMonth, plannedThisMonth), today, zone)
        assertEquals(0, BigDecimal("900.00").compareTo(p.total))
        assertEquals("la fissa del mese dopo non entra nell'atteso", 0, BigDecimal("880.00").compareTo(p.trail.expectedBalance))
    }
}
