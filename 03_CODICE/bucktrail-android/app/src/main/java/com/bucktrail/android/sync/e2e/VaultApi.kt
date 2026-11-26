package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import java.time.OffsetDateTime
import java.util.UUID

/** Superficie PostgREST delle tabelle E2E. I record del vault contengono solo id, utente, kind, key_id e involucro cifrato. */
interface VaultApi {
    suspend fun selectVault(kind: VaultKind, userId: String, token: String, columns: String = "*", keyId: String? = null): List<JsonObject>
    suspend fun upsertVault(rows: List<JsonObject>, token: String)
    suspend fun deleteVault(kind: VaultKind, ids: List<String>, userId: String, token: String, keyId: String)
    suspend fun activateE2e(row: JsonObject, generation: String, counts: Map<String, Int>, token: String)
    suspend fun rollbackActivation(row: JsonObject, token: String)
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

internal fun ApiException.e2eStateChanged(): Boolean = code == "P0001" && message in setOf(
    "bt_e2e_state_changed", "bt_e2e_counts", "bt_e2e_key_mismatch", "bt_e2e_vault_locked", "bt_e2e_use_activate",
    "bt_e2e_use_rollback",
)

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


internal suspend fun VaultApi.clearDeadVaultKeys(
    userId: String,
    liveKey: String,
    request: suspend (suspend (String) -> Unit) -> Unit,
    requireCurrent: suspend (String) -> Unit,
    onDeferred: suspend () -> Unit,
) {
    for (kind in VaultKind.entries) {
        request(requireCurrent)
        try {
            request { token ->
                val rows = selectVault(kind, userId, token, "id,key_id")
                for ((key, records) in rows.groupBy { it.text("key_id") }) {
                    if (key == null || key == liveKey) continue
                    val ids = records.mapNotNull { canonicalUuid(it.text("id"))?.toString() }.distinct()
                    for (batch in ids.sorted().chunked(100)) {
                        requireCurrent(token)
                        // A delayed DELETE cannot remove a row already rewritten under a new key.
                        deleteVault(kind, batch, userId, token, key)
                    }
                }
            }
        } catch (_: ApiException) {
            onDeferred()
        }
    }
}
