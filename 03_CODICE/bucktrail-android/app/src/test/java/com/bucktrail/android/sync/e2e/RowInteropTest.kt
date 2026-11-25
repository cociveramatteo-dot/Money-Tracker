package com.bucktrail.android.sync.e2e

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.sync.SyncMapper
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertArrayEquals
import org.junit.Assert.assertEquals
import org.junit.Test
import java.io.File
import java.math.BigDecimal
import java.util.UUID

class RowInteropTest {
    private val owner = "abcdefab-cdef-4abc-8def-abcdefabcdef"
    private val key = ByteArray(32) { (0xA0 + it).toByte() }

    @Test
    fun nativeMapperRowsMatchSharedVectors() {
        val cases = fixture()["cases"]!!.jsonArray.associate { it.jsonObject.text("kind") to it.jsonObject }
        for ((index, sample) in nativeRows().withIndex()) {
            val (kind, row) = sample
            val plaintext = row.toString()
            val nonce = ByteArray(12).apply { this[11] = (index + 6).toByte() }
            val aad = VaultCrypto.rowAAD(kind.wire, UUID.fromString(row.text("id")), UUID.fromString(owner))
            val sealed = VaultCrypto.sealForTest(plaintext.encodeToByteArray(), key, aad, nonce)
            val expected = cases.getValue(kind.wire)["android"]!!.jsonObject
            assertEquals(kind.wire, expected.text("plaintext"), plaintext)
            assertEquals(kind.wire, expected.text("nonce_hex"), nonce.joinToString("") { "%02x".format(it) })
            assertEquals(kind.wire, expected.text("sealed"), sealed)
        }
    }

    @Test
    fun bothClientsDecodeAllVaultRows() = runBlocking {
        val fixture = fixture()
        assertEquals(owner, fixture.text("user_id"))
        assertEquals(key.joinToString("") { "%02x".format(it) }, fixture.text("key_hex"))
        val cases = fixture["cases"]!!.jsonArray.map { it.jsonObject }
        assertEquals(VaultKind.entries.map { it.wire }.sorted(), cases.map { it.text("kind")!! }.sorted())
        val backend = FakeVaultSupabase()
        val vault = VaultSupabaseApi(backend, backend, key, owner)
        val nonces = mutableSetOf<String>()
        for (sample in cases) {
            val kind = VaultKind.entries.single { it.wire == sample.text("kind") }
            val id = checkNotNull(sample.text("id"))
            val expected = sample["expected"]!!.jsonObject
            for (client in listOf("ios", "android")) {
                val label = "${kind.wire}/$client"
                val wire = sample[client]!!.jsonObject
                val sealed = checkNotNull(wire.text("sealed"))
                val nonce = checkNotNull(wire.text("nonce_hex"))
                nonces += nonce
                val aad = VaultCrypto.rowAAD(kind.wire, UUID.fromString(id), UUID.fromString(owner))
                assertArrayEquals(label, nonce.hexBytes(), VaultCrypto.decodeBase64URL(sealed.removePrefix("bt1.")).copyOf(12))
                assertEquals(label, wire.text("plaintext"), VaultCrypto.open(sealed, key, aad).decodeToString())
                backend.records[id] = JsonObject(mapOf("id" to JsonPrimitive(id), "user_id" to JsonPrimitive(owner),
                    "kind" to JsonPrimitive(kind.wire), "payload" to JsonPrimitive(sealed)))
                val row = vault.selectAll(kind.table, owner, "fake-token").single()
                val decoded = reencodeDecoded(kind, row)
                assertEquals(label, expected, normalize(decoded))
                if (kind == VaultKind.Rule) {
                    val exceptions = com.bucktrail.android.domain.RecurrenceExceptionCodec.decode(SyncMapper.rule(row).exceptionsJson)
                    assertEquals(label, true, exceptions["2023-11-16"]?.skip)
                }
            }
        }
        assertEquals(10, nonces.size)
    }

    private fun reencodeDecoded(kind: VaultKind, row: JsonObject): JsonObject = when (kind) {
        VaultKind.Account -> SyncMapper.accountRow(SyncMapper.account(row), owner)
        VaultKind.Transaction -> SyncMapper.transactionRow(SyncMapper.transaction(row), owner)
        VaultKind.Budget -> SyncMapper.budgetRow(SyncMapper.budget(row), owner)
        VaultKind.Goal -> SyncMapper.goalRow(SyncMapper.goal(row), owner)
        VaultKind.Rule -> SyncMapper.ruleRow(SyncMapper.rule(row), owner)
    }

    private fun normalize(row: JsonObject) = JsonObject(row.mapValues { (field, value) ->
        if (value == JsonNull) return@mapValues value
        val primitive = value as JsonPrimitive
        when (field) {
            "id", "user_id", "account_id" -> JsonPrimitive(primitive.content.lowercase())
            "initial_balance", "amount", "monthly_limit", "target_amount", "current_amount" ->
                JsonPrimitive(BigDecimal(primitive.content).stripTrailingZeros().toPlainString())
            "created_at", "date", "deadline", "start_date", "end_date", "materialized_through" ->
                JsonPrimitive(SyncMapper.parseDate(primitive.content))
            else -> primitive
        }
    })

    private fun fixture(): JsonObject {
        val path = checkNotNull(System.getProperty("e2eVectors"))
        return Json.parseToJsonElement(File(path).readText()).jsonObject["rows"]!!.jsonObject
    }

    private fun String.hexBytes() = chunked(2).map { it.toInt(16).toByte() }.toByteArray()

    private fun nativeRows(): List<Pair<VaultKind, JsonObject>> {
        fun id(index: Int) = "76543210-abcd-4ef0-8123-abcdef00000$index"
        val created = 1_700_000_000_125L
        return listOf(
            VaultKind.Account to SyncMapper.accountRow(AccountEntity(id(1), "Conto 東京 🏦", "Conto Bancario",
                initialBalanceCents = -4_567, colorHex = "2468AC", createdAt = created, isArchived = true,
                isExcludedFromTotal = true), owner),
            VaultKind.Transaction to SyncMapper.transactionRow(TransactionEntity(id = id(2), name = "Caffè 京都 ☕",
                amountCents = -1_234, type = "Uscita", category = "旅", categoryIcon = "airplane",
                date = 1_700_123_456_789, isDone = false, notes = "Rimborso 日本 🧾", createdAt = created), owner),
            VaultKind.Budget to SyncMapper.budgetRow(BudgetEntity(id(3), id(1), "食費 🍜", "fork.knife",
                monthlyLimitCents = 9_214, month = 11, year = 2026, createdAt = created), owner),
            VaultKind.Goal to SyncMapper.goalRow(GoalEntity(id(4), "旅行 🚄", "🌸", targetCents = 38_276,
                currentCents = 1_245, createdAt = created), owner),
            VaultKind.Rule to SyncMapper.ruleRow(RecurringRuleEntity(id(5), "家賃 🏡", "Uscita", "Casa", "house",
                notes = "例外あり", amountCents = 27_865, isFixed = true, frequency = "Mensile",
                startDate = 1_700_086_400_250, exceptionsJson = """{"2023-11-16":{"skip":true}}""",
                materializedThrough = 1_700_345_600_750, createdAt = created), owner),
        )
    }
}
