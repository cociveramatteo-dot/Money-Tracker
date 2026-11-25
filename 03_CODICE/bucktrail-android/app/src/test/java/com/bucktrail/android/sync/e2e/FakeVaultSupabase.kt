package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.FakeSupabase
import com.bucktrail.android.sync.Session
import com.bucktrail.android.sync.SessionStore
import com.bucktrail.android.sync.SupabaseApi
import kotlinx.serialization.json.JsonObject

/** Nuovo fake per la sync protetta. Riproduce il trigger su scritture e cancellazioni in chiaro. */
internal class FakeVaultSupabase(
    val plain: FakeSupabase = FakeSupabase(),
) : SupabaseApi by plain, VaultApi {
    val readsAndWrites = mutableListOf<String>()
    val keys = mutableMapOf<String, JsonObject>()
    val records = mutableMapOf<String, JsonObject>()
    var available = true
    var metadataError: ApiException? = null
    var transitionOnNextPlainWrite: JsonObject? = null

    override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) {
        transitionOnNextPlainWrite?.let { row ->
            keys[checkNotNull(row.text("user_id")).lowercase()] = row
            transitionOnNextPlainWrite = null
        }
        if (rows.any { row -> keys[row.text("user_id")?.lowercase()]?.text("state") in listOf("migrating", "active") }) {
            readsAndWrites += "reject:$table"
            throw ApiException(ErrorKind.Client, 400, "bt_e2e_active", "P0001")
        }
        plain.upsert(table, rows, token)
    }

    override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) {
        if (keys[userId.lowercase()]?.text("state") == "migrating") {
            readsAndWrites += "reject:$table"
            throw ApiException(ErrorKind.Client, 400, "bt_e2e_migrating", "P0001")
        }
        plain.deleteIn(table, ids, userId, token)
    }

    override suspend fun selectVault(kind: VaultKind, userId: String, token: String, columns: String): List<JsonObject> {
        readsAndWrites += "vaultSelect:$userId:${kind.wire}:$columns"
        return records.values.filter { scoped(it, kind, userId) }.map {
            if (columns == "id") JsonObject(it.filterKeys { key -> key == "id" }) else it
        }
    }

    override suspend fun upsertVault(rows: List<JsonObject>, token: String) {
        readsAndWrites += "vaultUpsert:${rows.size}"
        rows.forEach { records[checkNotNull(it.text("id")).lowercase()] = it }
    }

    override suspend fun deleteVault(kind: VaultKind, ids: List<String>, userId: String, token: String) {
        readsAndWrites += "vaultDelete:$userId:${kind.wire}:${ids.size}"
        for (id in ids) {
            val key = id.lowercase()
            if (records[key]?.let { scoped(it, kind, userId) } == true) records.remove(key)
        }
    }

    override suspend fun getE2e(userId: String, token: String): E2ERowLookup {
        readsAndWrites += "e2eGet:$userId"
        metadataError?.let { throw it }
        if (!available) return E2ERowLookup.Unavailable
        return keys[userId.lowercase()]?.let(E2ERowLookup::Present) ?: E2ERowLookup.Absent
    }

    override suspend fun insertE2e(row: JsonObject, token: String) {
        val owner = checkNotNull(row.text("user_id")).lowercase()
        readsAndWrites += "e2eInsert:$owner"
        if (owner in keys) throw ApiException(ErrorKind.Client, 409, "duplicate state")
        keys[owner] = row
    }

    override suspend fun patchE2e(userId: String, changes: JsonObject, token: String) {
        readsAndWrites += "e2ePatch:$userId"
        val owner = userId.lowercase()
        keys[owner]?.let { keys[owner] = JsonObject(it + changes) }
    }

    override suspend fun deleteE2e(userId: String, token: String) {
        readsAndWrites += "e2eDelete:$userId"
        keys.remove(userId.lowercase())
    }

    private fun scoped(row: JsonObject, kind: VaultKind, user: String): Boolean =
        row.text("kind") == kind.wire && row.text("user_id").equals(user, ignoreCase = true)
}

internal class MemoryE2ESecrets : E2ESecrets {
    private val items = mutableMapOf<String, LocalDek>()
    private var migration: E2EMigrationMarker? = null

    override fun load(userId: String) = items[userId.lowercase()]

    override fun save(userId: String, dek: ByteArray) {
        items[userId.lowercase()] = LocalDek(dek.copyOf(), VaultCrypto.keyId(dek))
    }

    override fun remove(userId: String) {
        items.remove(userId.lowercase())
    }

    override fun marker() = migration

    override fun saveMarker(marker: E2EMigrationMarker) {
        migration = marker
    }

    override fun clear(userId: String) {
        remove(userId)
        if (migration?.userId.equals(userId, ignoreCase = true)) migration = null
    }
}

internal class E2ETestSession(var stored: Session?) : SessionStore {
    override fun load(): Session? = stored
    override fun save(session: Session?) {
        stored = session
    }
}

internal fun e2eTestSession(userId: String) = Session("token", "refresh", Long.MAX_VALUE, userId, null)
