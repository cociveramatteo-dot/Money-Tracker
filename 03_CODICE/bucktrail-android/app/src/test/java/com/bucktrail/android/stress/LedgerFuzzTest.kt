package com.bucktrail.android.stress

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.RecurringOps
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.TransactionOps
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.AccountEditing
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.RecurrenceCalculator
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID
import kotlin.random.Random

/**
 * Fuzz con seme fisso: operazioni casuali (movimenti, trasferimenti, rettifiche, archiviazioni, eliminazioni di conti a cascata,
 * ricorrenze al 31 / 29 febbraio, eccezioni, materializzazione) in vari fusi orari. Dopo OGNI passo: saldo = iniziale + somma dei fatti,
 * gambe dei trasferimenti coerenti, id univoci, materializzazione idempotente, nessuna eccezione imprevista.
 */
class LedgerFuzzTest {
    private class World(val zone: ZoneId, val rnd: Random) {
        var accounts = mutableListOf<AccountEntity>()
        var txs = listOf<TransactionEntity>()
        var rules = listOf<RecurringRuleEntity>()
        val calc = RecurrenceCalculator(zone)
        var now: Instant = LocalDate.of(2026, 11, 23).atTime(12, 0).atZone(zone).toInstant()
        val ids get() = accounts.map { it.id }.toSet()
    }

    private val extremeCents = longArrayOf(0, 1, 99, 100, 99_999_999_999L, 100_000_000_000L, 12_345_678)
    private fun cents(r: Random) = if (r.nextInt(4) == 0) extremeCents[r.nextInt(extremeCents.size)] else r.nextLong(1, 500_000)
    private fun randomDate(w: World): Long {
        val base = when (w.rnd.nextInt(8)) {
            0 -> LocalDate.of(1970, 1, 1); 1 -> LocalDate.of(2100, 12, 31); 2 -> LocalDate.of(2024, 2, 29)
            3 -> LocalDate.of(2026, 3, 29); 4 -> LocalDate.of(2026, 10, 25); 5 -> LocalDate.of(2026, 1, 31)
            else -> LocalDate.of(2026, 11, 23).plusDays(w.rnd.nextLong(-700, 700))
        }
        return base.atTime(w.rnd.nextInt(24), w.rnd.nextInt(60)).atZone(w.zone).toInstant().toEpochMilli()
    }

    private fun step(w: World) {
        val r = w.rnd
        when (r.nextInt(14)) {
            0, 1, 2 -> if (w.accounts.isNotEmpty()) w.txs += TransactionEntity(
                accountId = w.accounts.random(r).id, name = "t${r.nextInt()}", amountCents = cents(r),
                type = if (r.nextBoolean()) "Uscita" else "Entrata", date = randomDate(w), isDone = r.nextBoolean(),
            )
            3 -> if (w.txs.isNotEmpty()) {
                val t = w.txs.random(r)
                val gone = (listOf(t) + TransactionOps.twinsOf(t, w.txs)).map { it.id }.toSet()
                w.txs = w.txs.filter { it.id !in gone }
            }
            4 -> if (w.accounts.size >= 2) {
                val (a, b) = w.accounts.shuffled(r).take(2)
                w.txs += TransactionOps.newTransfer(TransactionOps.TransferInput(a.id, a.name, b.id, b.name, cents(r), randomDate(w), r.nextBoolean(), ""))
            }
            5 -> if (w.txs.isNotEmpty()) {
                val t = w.txs.random(r)
                val changed = TransactionOps.withDone(t, TransactionOps.twinsOf(t, w.txs), r.nextBoolean()).associateBy { it.id }
                w.txs = w.txs.map { changed[it.id] ?: it }
            }
            6 -> if (w.accounts.isNotEmpty()) {
                val i = r.nextInt(w.accounts.size); w.accounts[i] = w.accounts[i].copy(isArchived = !w.accounts[i].isArchived)
            }
            7 -> if (w.accounts.size > 1 && r.nextInt(3) == 0) {
                val gone = w.accounts.random(r)
                w.accounts.remove(gone)
                w.txs = w.txs.filter { it.accountId != gone.id } // ON DELETE CASCADE
            } else if (w.accounts.size < 6) w.accounts += AccountEntity(name = "c${r.nextInt()}", initialBalanceCents = r.nextLong(-500_000_000_000L, 500_000_000_000L))
            8 -> if (w.accounts.isNotEmpty()) { // modifica saldo (§4.7)
                val acc = w.accounts.random(r)
                val data = w.accounts.map { it.toData() }; val tds = w.txs.map { it.toData() }
                val current = Balance.current(data.first { it.id == acc.id }, tds)
                val target = Amounts.fromCents(r.nextLong(-1_000_000_000_000L / 100, 1_000_000_000_000L / 100))
                val has = w.txs.any { it.accountId == acc.id }
                when (val c = AccountEditing.balanceChange(has, current, target)) {
                    is AccountEditing.BalanceChange.SetInitial -> w.accounts[w.accounts.indexOf(acc)] = acc.copy(initialBalanceCents = Amounts.toCents(c.value))
                    is AccountEditing.BalanceChange.Adjust -> w.txs += TransactionOps.adjustment(acc.id, c, "Rettifica", "x", w.now.toEpochMilli())
                    AccountEditing.BalanceChange.None -> Unit
                }
                val after = Balance.current(w.accounts.map { it.toData() }.first { it.id == acc.id }, w.txs.map { it.toData() })
                assertEquals("saldo dopo modifica", target, after)
            }
            9 -> { // nuova serie
                val startDay = listOf(LocalDate.of(2026, 1, 31), LocalDate.of(2024, 2, 29), LocalDate.of(2026, 8, 1), LocalDate.of(2026, 10, 25), LocalDate.of(2026, 11, 15))[r.nextInt(5)]
                w.rules += RecurringRuleEntity(
                    name = "serie${r.nextInt()}", type = if (r.nextBoolean()) "Uscita" else "Entrata", category = "Altro", categoryIcon = "x",
                    amountCents = cents(r), isFixed = r.nextBoolean(), accountId = w.accounts.randomOrNull(r)?.id,
                    frequency = listOf("mensile", "settimanale", "annuale")[r.nextInt(3)], startDate = w.calc.noon(startDay.atStartOfDay(w.zone).toInstant()).toEpochMilli(),
                )
            }
            10, 11 -> { w.now = w.now.plusSeconds(r.nextLong(0, 90L * 86400)); materializeAndCheck(w) }
            else -> if (w.rules.isNotEmpty()) ruleAction(w)
        }
    }

    private fun materializeAndCheck(w: World) {
        val c = RecurringOps.materialize(w.rules, w.txs, w.ids, w.now, w.zone)
        val (nr, nt) = RecurringOps.applyTo(c, w.rules, w.txs); w.rules = nr; w.txs = nt
        val again = RecurringOps.materialize(w.rules, w.txs, w.ids, w.now, w.zone)
        assertTrue("materializzazione non idempotente: ${again.upsertTransactions.size} nuovi", again.upsertTransactions.isEmpty())
    }

    private fun ruleAction(w: World) {
        val rule = w.rules.random(w.rnd)
        val month = w.calc.monthStart(w.now.plusSeconds(w.rnd.nextLong(-40L, 40L) * 86400))
        val occ = w.calc.occurrences(rule.toSnapshotForTest(), month, w.calc.addMonths(month, 1))
        if (occ.isEmpty()) return
        val o = occ.random(w.rnd)
        val action: RecurringOps.Action = when (w.rnd.nextInt(5)) {
            0 -> RecurringOps.Action.Delete(RecurringOps.Scope.entries.random(w.rnd))
            1 -> RecurringOps.Action.SkipMonth
            2 -> RecurringOps.Action.Terminate(w.rnd.nextBoolean())
            else -> RecurringOps.Action.Edit(RecurringOps.Scope.entries.random(w.rnd), rule.toSnapshotForTest().copy(name = "mod", amount = Amounts.fromCents(cents(w.rnd)), startDate = if (w.rnd.nextBoolean()) rule.toSnapshotForTest().startDate else o.date))
        }
        val changes = try { RecurringOps.apply(action, rule, o.originalDate, w.txs, w.ids, w.now, w.zone) }
        catch (e: RecurringOps.EditorException) { return } // rifiuti previsti (mese diverso, valori non validi)
        val (nr, nt) = RecurringOps.applyTo(changes, w.rules, w.txs); w.rules = nr; w.txs = nt
    }

    private fun RecurringRuleEntity.toSnapshotForTest() = RecurringOps.snapshot(this)

    private fun check(w: World, label: String) {
        val data = w.accounts.map { it.toData() }; val tds = w.txs.map { it.toData() }
        for (a in w.accounts) {
            val done = w.txs.filter { it.accountId == a.id && it.isDone }.sumOf { if (it.type == "Entrata") it.amountCents else -it.amountCents }
            val all = w.txs.filter { it.accountId == a.id }.sumOf { if (it.type == "Entrata") it.amountCents else -it.amountCents }
            val d = data.first { it.id == a.id }
            assertEquals("$label saldo attuale ${a.name}", Amounts.fromCents(a.initialBalanceCents + done), Balance.current(d, tds))
            assertEquals("$label saldo futuro ${a.name}", Amounts.fromCents(a.initialBalanceCents + all), Balance.future(d, tds))
        }
        val total = w.accounts.filter { !it.isArchived && !it.isExcludedFromTotal }.sumOf { a -> Balance.current(data.first { it.id == a.id }, tds) }
        assertEquals("$label totale", total, Balance.total(data, tds))
        assertEquals("$label id univoci", w.txs.size, w.txs.map { it.id }.toSet().size)
        for ((g, legs) in w.txs.filter { it.isTransfer }.groupBy { it.transferGroupId.lowercase() }) {
            if (legs.size != 2) continue
            assertEquals("$label gambe $g importo", legs[0].amountCents, legs[1].amountCents)
            assertEquals("$label gambe $g stato", legs[0].isDone, legs[1].isDone)
            assertTrue("$label gambe $g tipo", legs.map { it.type }.toSet() == setOf("Uscita", "Entrata"))
        }
        // nessun movimento orfano
        assertTrue("$label orfani", w.txs.all { it.accountId == null || it.accountId in w.ids })
        // serie: mai due copie dello stesso giorno originale
        for (rl in w.rules) {
            val copies = w.txs.filter { it.templateId.equals(rl.id, true) }
            assertEquals("$label copie duplicate di ${rl.name}", copies.size, copies.map { it.id }.toSet().size)
        }
    }

    private fun run(zone: String, seed: Int, steps: Int) {
        val w = World(ZoneId.of(zone), Random(seed))
        repeat(3) { w.accounts += AccountEntity(name = "base$it", initialBalanceCents = 100_00L * it) }
        repeat(steps) { i -> step(w); check(w, "[$zone seed=$seed passo=$i]") }
    }

    @Test fun fuzzRome() { for (s in 1..6) run("Europe/Rome", s, 500) }
    @Test fun fuzzLosAngeles() { for (s in 1..4) run("America/Los_Angeles", 100 + s, 500) }
    @Test fun fuzzAuckland() { for (s in 1..4) run("Pacific/Auckland", 200 + s, 500) }
    @Test fun fuzzKolkataAndUtc() { for (s in 1..3) { run("Asia/Kolkata", 300 + s, 500); run("UTC", 400 + s, 500) } }
}
