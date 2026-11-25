package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.Snapshot
import com.bucktrail.android.sync.SyncFormatException
import com.bucktrail.android.sync.SyncMapper
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral
import java.math.BigDecimal
import java.math.RoundingMode
import java.security.MessageDigest

internal object E2EVerifier {
    class Mismatch(val kind: VaultKind, reason: String) : Exception("${kind.wire}: $reason")
    data class Receipt(val byKind: Map<String, String>, val combined: String)

    fun rows(snapshot: Snapshot, owner: String): Map<VaultKind, List<JsonObject>> = with(snapshot) {
        mapOf(
            VaultKind.Account to accounts.map { SyncMapper.accountRow(it, owner) },
            VaultKind.Transaction to transactions.map { SyncMapper.transactionRow(it, owner) },
            VaultKind.Budget to budgets.map { SyncMapper.budgetRow(it, owner) },
            VaultKind.Goal to goals.map { SyncMapper.goalRow(it, owner) },
            VaultKind.Rule to rules.map { SyncMapper.ruleRow(it, owner) },
        )
    }

    fun ids(rows: List<JsonObject>, kind: VaultKind): Set<String> {
        val ids = rows.map { canonicalUuid(it.text("id"))?.toString() ?: throw Mismatch(kind, "id") }.toSet()
        if (ids.size != rows.size) throw Mismatch(kind, "duplicate id")
        return ids
    }

    fun verify(
        local: Map<VaultKind, List<JsonObject>>, remote: Map<VaultKind, List<JsonObject>>, owner: String,
        allowRemoteSubset: Boolean = false, log: (String) -> Unit = {},
    ): Receipt {
        val before = linkedMapOf<String, List<String>>()
        val after = linkedMapOf<String, List<String>>()
        for (kind in VaultKind.entries.sortedBy { it.wire }) {
            val expected = normalize(local.getValue(kind), kind, owner)
            val actual = normalize(remote.getValue(kind), kind, owner)
            val matched = if (allowRemoteSubset) expected.filterKeys { it in actual } else expected
            if (matched.size != actual.size) throw Mismatch(kind, "count")
            if (matched.keys != actual.keys) throw Mismatch(kind, "ids")
            val aligned = actual.mapValues { (id, fields) ->
                val reference = matched.getValue(id)
                val normalized = fields.mapValues { (key, field) ->
                    val want = reference[key]
                    if (key in dates && field is JsonPrimitive && field != JsonNull &&
                        want is JsonPrimitive && want != JsonNull &&
                        (field.content.toBigInteger() - want.content.toBigInteger()).abs() <= java.math.BigInteger.ONE
                    ) want else field
                }
                if (reference != normalized) throw Mismatch(kind, "fields")
                normalized
            }
            before[kind.wire] = lines(kind, matched)
            after[kind.wire] = lines(kind, aligned)
        }
        val expectedReceipt = receipt(before)
        val actualReceipt = receipt(after)
        for ((kind, hash) in expectedReceipt.byKind) log("E2E verification $kind: local $hash, remote ${actualReceipt.byKind[kind]}")
        log("E2E verification: local ${expectedReceipt.combined}, remote ${actualReceipt.combined}")
        check(expectedReceipt == actualReceipt)
        return expectedReceipt
    }

    private fun receipt(lines: Map<String, List<String>>) =
        Receipt(lines.mapValues { digest(it.value.joinToString("\n")) }, digest(lines.values.flatten().joinToString("\n")))

    // One compact UTF-8 line per row, in kind/UUID order, with no trailing newline.
    private fun lines(kind: VaultKind, rows: Map<String, Map<String, JsonElement>>) =
        rows.toSortedMap().map { (id, fields) -> "${kind.wire}|$id|${JsonObject(fields.toSortedMap())}" }

    fun digest(value: String): String =
        MessageDigest.getInstance("SHA-256").digest(value.encodeToByteArray()).joinToString("") { "%02x".format(it) }

    private val dates = setOf("created_at", "date", "deadline", "start_date", "end_date", "materialized_through")
    private val uuidFields = setOf("id", "user_id", "account_id", "transfer_group_id", "template_id")
    private val amounts = setOf("amount", "initial_balance", "monthly_limit", "target_amount", "current_amount")
    private val nullable = setOf("account_id", "deadline", "end_date", "materialized_through")

    @OptIn(ExperimentalSerializationApi::class)
    private fun normalize(rows: List<JsonObject>, kind: VaultKind, owner: String): Map<String, Map<String, JsonElement>> {
        ids(rows, kind)
        return rows.associate { row ->
            val id = checkNotNull(canonicalUuid(row.text("id"))).toString()
            if (canonicalUuid(row.text("user_id"))?.toString() != owner) throw Mismatch(kind, "owner")
            // Existing decoders reject invalid dates, required fields and amounts outside the app's range.
            // Read the actual field values below so mapper defaults or case conversion cannot hide a difference.
            val schema = when (kind) {
                VaultKind.Account -> SyncMapper.accountRow(SyncMapper.account(row), owner)
                VaultKind.Transaction -> SyncMapper.transactionRow(SyncMapper.transaction(row), owner)
                VaultKind.Budget -> SyncMapper.budgetRow(SyncMapper.budget(row), owner)
                VaultKind.Goal -> SyncMapper.goalRow(SyncMapper.goal(row), owner)
                VaultKind.Rule -> SyncMapper.ruleRow(SyncMapper.rule(row), owner)
            }
            id to schema.mapValues { (key, type) ->
                val value = row[key] ?: if (key in nullable) JsonNull else throw Mismatch(kind, "missing field")
                when {
                    value == JsonNull && key in nullable -> JsonNull
                    value !is JsonPrimitive || value == JsonNull -> throw Mismatch(kind, "field type")
                    key in dates -> JsonPrimitive(SyncMapper.parseDate(row.text(key) ?: throw Mismatch(kind, "date type")))
                    key in amounts && value.isString -> throw Mismatch(kind, "amount type")
                    key in amounts -> JsonUnquotedLiteral(
                        BigDecimal(value.content).setScale(2, RoundingMode.HALF_UP).stripTrailingZeros().toPlainString(),
                    )
                    key in uuidFields -> {
                        val text = row.text(key) ?: throw Mismatch(kind, "UUID type")
                        val uuid = canonicalUuid(text)
                        if (uuid == null && key in setOf("id", "user_id", "account_id")) throw Mismatch(kind, "UUID")
                        JsonPrimitive(uuid?.toString() ?: text)
                    }
                    type is JsonPrimitive && type.isString != value.isString -> throw Mismatch(kind, "field type")
                    else -> value
                }
            }
        }
    }

    fun backupJson(rows: Map<VaultKind, List<JsonObject>>) =
        JsonObject(rows.mapKeys { it.key.wire }.mapValues { JsonArray(it.value) })

    fun backupRows(json: JsonObject): Map<VaultKind, List<JsonObject>> = VaultKind.entries.associateWith { kind ->
        val list = json[kind.wire] as? JsonArray ?: throw SyncFormatException("Invalid E2E backup")
        list.map { it as? JsonObject ?: throw SyncFormatException("Invalid E2E backup row") }
    }
}
