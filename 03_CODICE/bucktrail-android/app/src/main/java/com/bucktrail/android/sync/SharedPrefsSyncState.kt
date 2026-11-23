package com.bucktrail.android.sync

import android.content.Context
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull

/** `syncService.*` di iOS in SharedPreferences (sopravvive al riavvio; non contiene segreti). */
class SharedPrefsSyncState(context: Context) : SyncStateStore {
    private val prefs = context.applicationContext.getSharedPreferences("bucktrail_sync", Context.MODE_PRIVATE)
    private val lock = Any()

    override var lastUserId: String?
        get() = prefs.getString("lastUserId", null)
        set(v) { prefs.edit().putString("lastUserId", v).apply() }
    override var syncedUserId: String?
        get() = prefs.getString("syncedUserId", null)
        set(v) { prefs.edit().putString("syncedUserId", v).apply() }
    override var lastPull: Long
        get() = prefs.getLong("lastPull", 0)
        set(v) { prefs.edit().putLong("lastPull", v).apply() }
    override var lastSyncedCount: Int
        get() = prefs.getInt("lastSyncedCount", -1)
        set(v) { prefs.edit().putInt("lastSyncedCount", v).apply() }
    override var hasPendingChanges: Boolean
        get() = prefs.getBoolean("pending", false)
        set(v) { prefs.edit().putBoolean("pending", v).apply() }

    override fun dirty(): Map<String, Long> = synchronized(lock) {
        val text = prefs.getString("dirty", null) ?: return emptyMap()
        runCatching { Json.parseToJsonElement(text).jsonObject.mapValues { it.value.jsonPrimitive.longOrNull ?: 0L } }.getOrDefault(emptyMap())
    }

    private fun write(map: Map<String, Long>) {
        val json: JsonObject = buildJsonObject { map.forEach { (k, v) -> put(k, JsonPrimitive(v)) } }
        prefs.edit().putString("dirty", json.toString()).apply()
    }

    override fun markDirty(ids: Collection<String>, stamp: Long) = synchronized(lock) { write(dirty() + ids.associateWith { stamp }) }

    override fun clearDirty(uploaded: Map<String, Long>) = synchronized(lock) {
        val current = dirty()
        write(current.filter { (id, stamp) -> uploaded[id] != stamp })
    }

    override fun reset() { prefs.edit().clear().apply() }
}
