package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.SupabaseApi
import com.bucktrail.android.sync.SyncFormatException
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject

/** Espone al motore gli stessi JSON della sync in chiaro, ma li conserva cifrati in mt_vault. */
class VaultSupabaseApi(
    plain: SupabaseApi, private val vault: VaultApi, dek: ByteArray, userId: String,
) : SupabaseApi by plain {
    private val owner = requireNotNull(canonicalUuid(userId))
    private val key = dek.copyOf()

    override suspend fun selectAll(table: String, userId: String, token: String, columns: String): List<JsonObject> {
        checkOwner(userId)
        require(columns == "*" || columns == "id")
        val kind = VaultKind.forTable(table)
        return vault.selectVault(kind, owner.toString(), token, columns).map { record ->
            val id = canonicalUuid(record.text("id")) ?: throw SyncFormatException("Invalid vault row ID")
            val fallback = JsonObject(mapOf("id" to JsonPrimitive(id.toString())))
            if (columns == "id") return@map fallback
            if (canonicalUuid(record.text("user_id")) != owner || record.text("kind") != kind.wire) return@map fallback
            val payload = record.text("payload") ?: return@map fallback
            runCatching {
                val bytes = VaultCrypto.open(payload, key, VaultCrypto.rowAAD(kind.wire, id, owner))
                val row = Json.parseToJsonElement(bytes.decodeToString(throwOnInvalidSequence = true)) as? JsonObject
                if (row != null && canonicalUuid(row.text("id")) == id && canonicalUuid(row.text("user_id")) == owner) {
                    row
                } else fallback
            }.getOrDefault(fallback)
        }
    }

    override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) {
        val kind = VaultKind.forTable(table)
        rows.chunked(BATCH_SIZE).forEach { batch ->
            val records = batch.map { row ->
                val id = canonicalUuid(row.text("id")) ?: throw SyncFormatException("Invalid vault row ID")
                checkOwner(row.text("user_id"))
                val payload = VaultCrypto.seal(row.toString().encodeToByteArray(), key, VaultCrypto.rowAAD(kind.wire, id, owner))
                buildJsonObject {
                    put("id", JsonPrimitive(id.toString()))
                    put("user_id", JsonPrimitive(owner.toString()))
                    put("kind", JsonPrimitive(kind.wire))
                    put("payload", JsonPrimitive(payload))
                }
            }
            vault.upsertVault(records, token)
        }
    }

    override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) {
        checkOwner(userId)
        val normalized = ids.map { canonicalUuid(it)?.toString() ?: throw SyncFormatException("Invalid vault row ID") }
        vault.deleteVault(VaultKind.forTable(table), normalized, owner.toString(), token)
    }

    private fun checkOwner(userId: String?) {
        if (canonicalUuid(userId) != owner) throw SyncFormatException("Invalid vault owner")
    }

    private companion object {
        const val BATCH_SIZE = 200
    }
}
