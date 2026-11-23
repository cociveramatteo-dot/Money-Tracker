package com.bucktrail.android.stress

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.JsonExport
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.data.toData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Balance
import com.bucktrail.android.domain.CsvExport
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.boolean
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.ZoneId
import kotlin.random.Random

/** Export CSV/JSON riletti da un parser indipendente: stessi movimenti, importi, nomi e saldi, anche con testi e importi estremi (seme fisso). */
class ExportRoundTripTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val nasty = listOf(
        "Pizza, \"bis\"", "riga1\nriga2", "=SOMMA(A1)", "-trattino", "+piu", "@at", "\tTAB", "😀👨‍👩‍👧‍👦🏳️‍🌈", "مرحبا بالعالم שלום עולם", "\u202eRTL", "A".repeat(5000),
        "<b>html</b> & ' \" ; DROP TABLE", "z̷̢̛a̶l̸g̵o̷", "日本語のとても長い名前", "", "  spazi  ", "\\backslash\\", "NUL\u0001ctl", "{\"json\":[1,2]}",
    )
    private val labels = CsvExport.Labels(listOf("d", "n", "a", "t", "c", "acc", "done", "rec"), "Uscita", "Entrata", "Sì", "No") { it }

    private fun parseCsv(text: String): List<List<String>> {
        val rows = ArrayList<List<String>>(); var row = ArrayList<String>(); val f = StringBuilder(); var q = false; var i = 0
        while (i < text.length) {
            val c = text[i]
            if (q) { if (c == '"') { if (i + 1 < text.length && text[i + 1] == '"') { f.append('"'); i++ } else q = false } else f.append(c) }
            else when (c) { '"' -> q = true; ',' -> { row.add(f.toString()); f.clear() }; '\n' -> { row.add(f.toString()); f.clear(); rows.add(row); row = ArrayList() }; else -> f.append(c) }
            i++
        }
        return rows
    }

    private fun world(seed: Int): Pair<List<AccountEntity>, List<TransactionEntity>> {
        val r = Random(seed)
        val accs = List(4) { AccountEntity(name = nasty[r.nextInt(nasty.size)].ifEmpty { "x" } + it, initialBalanceCents = listOf(0L, 1, -99_999_999_999L, 99_999_999_999L, r.nextLong(-10_000_000, 10_000_000))[r.nextInt(5)]) }
        val txs = List(1500) {
            TransactionEntity(
                accountId = if (r.nextInt(20) == 0) null else accs[r.nextInt(4)].id, name = nasty[r.nextInt(nasty.size)], notes = nasty[r.nextInt(nasty.size)],
                amountCents = listOf(0L, 1, 99_999_999_999L, r.nextLong(1, 1_000_000))[r.nextInt(4)], type = if (r.nextBoolean()) "Uscita" else "Entrata",
                date = Instant.parse("1970-01-01T00:00:00Z").toEpochMilli() + r.nextLong(0, 4_102_444_800_000L), isDone = r.nextBoolean(),
            )
        }
        return accs to txs
    }

    @Test fun csvRoundTripKeepsEveryRowAmountAndName() {
        for (seed in 1..5) {
            val (accs, txs) = world(seed)
            val csv = CsvExport.build(txs.map { it.toData() }, accs.associate { it.id to it.name }, zone, labels)
            val rows = parseCsv(csv)
            assertEquals("righe (+intestazione)", txs.size + 1, rows.size)
            assertEquals("tutte le righe hanno 8 colonne", setOf(8), rows.map { it.size }.toSet())
            val byAmountName = rows.drop(1).map { Triple(it[1].removePrefix("'"), it[2], it[3]) }.groupingBy { it }.eachCount()
            val expected = txs.map { Triple(it.name, Amounts.fixedFractionString(Amounts.fromCents(it.amountCents)), if (it.type == "Uscita") "Uscita" else "Entrata") }.groupingBy { it }.eachCount()
            // il prefisso `'` difende dalle formule solo sui nomi che iniziano con = + - @ TAB CR LF
            assertEquals("seed $seed", expected, byAmountName)
        }
    }

    @Test fun jsonRoundTripKeepsEverythingAndBalancesMatch() {
        for (seed in 1..5) {
            val (accs, txs) = world(seed)
            val json = Json.parseToJsonElement(JsonExport.build(accs, txs, emptyList(), emptyList(), Instant.parse("2026-11-23T10:00:00Z"))).jsonObject
            val jt = json["transactions"]!!.jsonArray; val ja = json["accounts"]!!.jsonArray
            assertEquals(txs.size, jt.size); assertEquals(accs.size, ja.size)
            val byId = txs.associateBy { it.id.uppercase() }
            var sumCents = BigDecimal.ZERO
            for (o in jt.map { it as JsonObject }) {
                val t = byId.getValue(o["id"]!!.jsonPrimitive.content)
                assertEquals(t.name, o["name"]!!.jsonPrimitive.content); assertEquals(t.notes, o["notes"]!!.jsonPrimitive.content)
                assertEquals(0, Amounts.fromCents(t.amountCents).compareTo(BigDecimal(o["amount"]!!.jsonPrimitive.content)))
                assertEquals(t.isDone, o["isDone"]!!.jsonPrimitive.boolean)
                sumCents += BigDecimal(o["amount"]!!.jsonPrimitive.content)
            }
            assertEquals(0, Amounts.fromCents(txs.sumOf { it.amountCents }).compareTo(sumCents))
            // il saldo ricostruito dal file esportato (iniziale + fatti con segno) = saldo calcolato dall'app, conto per conto
            val data = accs.map { it.toData() }; val tds = txs.map { it.toData() }
            for (a in ja.map { it as JsonObject }) {
                val acc = accs.first { it.id.uppercase() == a["id"]!!.jsonPrimitive.content }
                val rebuilt = jt.map { it as JsonObject }.filter { it["accountName"]?.jsonPrimitive?.content == acc.name && it["isDone"]!!.jsonPrimitive.boolean }
                    .fold(BigDecimal(a["initialBalance"]!!.jsonPrimitive.content)) { s, o -> s + Amounts.signed(BigDecimal(o["amount"]!!.jsonPrimitive.content), o["type"]!!.jsonPrimitive.content) }
                // i conti omonimi (stesso nome) non si distinguono nel file: il confronto vale solo per nomi univoci
                if (accs.count { it.name == acc.name } == 1) assertEquals(0, Balance.current(data.first { it.id == acc.id }, tds).compareTo(rebuilt))
            }
        }
    }
}
