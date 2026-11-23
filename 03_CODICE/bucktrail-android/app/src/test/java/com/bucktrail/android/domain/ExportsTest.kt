package com.bucktrail.android.domain

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.JsonExport
import com.bucktrail.android.data.TransactionEntity
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.ZoneId

class ExportsTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val labels = CsvExport.Labels(
        listOf("Data", "Descrizione", "Importo", "Tipo", "Categoria", "Conto", "Fatto", "Ricorrenza"), "Uscita", "Entrata", "Sì", "No",
    ) { if (it == "Cibo") "Food" else it }

    @Test fun csvEscapeQuotesAndNeutralizesFormulas() {
        assertEquals("\"a\"\"b\"", CsvExport.escape("a\"b"))
        assertEquals("\"'=SOMMA(A1)\"", CsvExport.escape("=SOMMA(A1)"))
        for (c in listOf("+1", "-2", "@x", "\tx", "\rx", "\nx")) assertEquals("\"'$c\"", CsvExport.escape(c))
        assertEquals("\"\"", CsvExport.escape(""))
        assertEquals("\"12.50\"", CsvExport.escape("12.50"))
    }

    @Test fun csvRowsAreNewestFirstWithAllTransactions() {
        val txs = listOf(
            TransactionData("1", "a", "Pizza, \"bis\"", BigDecimal("12.5"), "Uscita", "Cibo", date = Instant.parse("2026-11-02T11:00:00Z"), isDone = true, recurringFrequency = "mensile"),
            TransactionData("2", null, "Stipendio", BigDecimal("1500"), "Entrata", "Lavoro", date = Instant.parse("2026-11-20T11:00:00Z"), isDone = false),
        )
        val lines = CsvExport.build(txs, mapOf("a" to "Conto"), zone, labels).split("\n")
        assertEquals("\"Data\",\"Descrizione\",\"Importo\",\"Tipo\",\"Categoria\",\"Conto\",\"Fatto\",\"Ricorrenza\"", lines[0])
        assertEquals("\"20/11/2026\",\"Stipendio\",\"1500.00\",\"Entrata\",\"Lavoro\",\"\",\"No\",\"\"", lines[1])
        assertEquals("\"02/11/2026\",\"Pizza, \"\"bis\"\"\",\"12.50\",\"Uscita\",\"Food\",\"Conto\",\"Sì\",\"mensile\"", lines[2])
        assertEquals("", lines[3])
    }

    @Test fun prettyJsonUsesSwiftLayout() {
        val text = PrettyJson.write(mapOf("b" to listOf(PrettyJson.Num("1.5"), "x/y"), "a" to true))
        assertEquals("{\n  \"a\" : true,\n  \"b\" : [\n    1.5,\n    \"x\\/y\"\n  ]\n}", text)
    }

    @Test fun fullExportContainsEverythingExceptNullFields() {
        val acc = AccountEntity("acc-1", "Conto", "Conto Bancario", 100_000, createdAt = 1_700_000_000_000)
        val tx = TransactionEntity("tx-1", "acc-1", "Spesa", 1_250, "Uscita", "Cibo", date = 1_700_000_100_000, createdAt = 1_700_000_100_000)
        val budget = BudgetEntity("b-1", null, "Cibo", monthlyLimitCents = 30_000, month = 11, year = 2026)
        val goal = GoalEntity("g-1", "Vacanza", targetCents = 280_000, currentCents = 196_000, deadline = null)
        val json = JsonExport.build(listOf(acc), listOf(tx), listOf(budget), listOf(goal), Instant.parse("2026-11-23T10:00:00.789Z"), null)
        val root = Json.parseToJsonElement(json) as JsonObject
        assertEquals(setOf("exportedAt", "accounts", "transactions", "budgets", "goals"), root.keys)
        assertEquals("2026-11-23T10:00:00Z", root["exportedAt"]!!.jsonPrimitive.content)
        val t = (root["transactions"] as JsonArray)[0] as JsonObject
        assertEquals("TX-1", t["id"]!!.jsonPrimitive.content)
        assertEquals("Conto", t["accountName"]!!.jsonPrimitive.content)
        assertEquals("12.5", t["amount"]!!.jsonPrimitive.content)
        assertEquals("1000", ((root["accounts"] as JsonArray)[0] as JsonObject)["initialBalance"]!!.jsonPrimitive.content)
        val g = (root["goals"] as JsonArray)[0] as JsonObject
        assertFalse("deadline" in g)
        assertFalse("accountName" in ((root["budgets"] as JsonArray)[0] as JsonObject))
        assertTrue(json.startsWith("{\n  \"accounts\" : ["))
    }
}
