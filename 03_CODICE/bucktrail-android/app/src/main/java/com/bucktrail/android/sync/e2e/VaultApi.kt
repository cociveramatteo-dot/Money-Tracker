package com.bucktrail.android.sync.e2e

import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.time.OffsetDateTime
import java.util.UUID

/** Superficie PostgREST delle tabelle E2E. I record del vault contengono solo id, utente, kind e involucro cifrato. */
interface VaultApi {
    suspend fun selectVault(kind: VaultKind, userId: String, token: String, columns: String = "*"): List<JsonObject>
    suspend fun upsertVault(rows: List<JsonObject>, token: String)
    suspend fun deleteVault(kind: VaultKind, ids: List<String>, userId: String, token: String)
    suspend fun getE2e(userId: String, token: String): E2ERowLookup
    suspend fun insertE2e(row: JsonObject, token: String)
    suspend fun patchE2e(userId: String, changes: JsonObject, token: String)
    suspend fun deleteE2e(userId: String, token: String)

    suspend fun patchE2eIfCurrent(row: JsonObject, changes: JsonObject, token: String): Boolean {
        val owner = checkNotNull(row.text("user_id"))
        if (!(getE2e(owner, token) as? E2ERowLookup.Present)?.row.sameGeneration(row)) return false
        patchE2e(owner, changes, token)
        return true
    }

    suspend fun deleteE2eIfCurrent(row: JsonObject, token: String): Boolean {
        val owner = checkNotNull(row.text("user_id"))
        if (!(getE2e(owner, token) as? E2ERowLookup.Present)?.row.sameGeneration(row)) return false
        deleteE2e(owner, token)
        return true
    }
}

internal fun JsonObject.generation(): String? = text("updated_at")?.let {
    OffsetDateTime.parse(it).toInstant().toString()
}

internal fun JsonObject?.sameGeneration(expected: JsonObject): Boolean = this != null &&
    text("user_id").equals(expected.text("user_id"), ignoreCase = true) &&
    text("key_id") == expected.text("key_id") && text("state") == expected.text("state") &&
    text("updated_at") == expected.text("updated_at")

enum class VaultKind(val table: String, val wire: String) {
    Account("mt_accounts", "account"),
    Transaction("mt_transactions", "transaction"),
    Budget("mt_budgets", "budget"),
    Goal("mt_goals", "goal"),
    Rule("mt_recurring_rules", "rule");

    companion object {
        private val byTable = entries.associateBy { it.table }

        fun forTable(table: String): VaultKind = requireNotNull(byTable[table]) { "Unsupported vault table" }
    }
}

sealed interface E2ERowLookup {
    data object Unavailable : E2ERowLookup
    data object Absent : E2ERowLookup
    data object Malformed : E2ERowLookup
    data class Present(val row: JsonObject) : E2ERowLookup
}

internal fun JsonObject.text(key: String): String? =
    (this[key] as? JsonPrimitive)?.takeIf { it.isString }?.content

internal fun canonicalUuid(value: String?): UUID? {
    if (value == null || value.length != 36) return null
    return runCatching { UUID.fromString(value) }.getOrNull()?.takeIf { it.toString().equals(value, ignoreCase = true) }
}
