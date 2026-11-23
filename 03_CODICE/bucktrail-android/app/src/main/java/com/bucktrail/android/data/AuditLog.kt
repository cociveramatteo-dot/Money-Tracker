package com.bucktrail.android.data

import com.bucktrail.android.domain.AuditDiff
import kotlinx.coroutines.CoroutineScope
import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.launch
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import java.io.File
import java.util.UUID

/** Registro append-only (§4.11, `audit-log.jsonl`): una riga JSON per evento, mai riscritta; si cancella con i dati locali. */
class AuditLog(private val file: File) {
    data class Entry(val id: String, val timestamp: Long, val entityType: String, val action: String, val summary: String)

    @Synchronized
    fun append(events: List<AuditDiff.Event>, now: Long = System.currentTimeMillis()) {
        if (events.isEmpty()) return
        file.parentFile?.mkdirs()
        file.appendText(events.joinToString("") { e ->
            JsonObject(mapOf(
                "id" to JsonPrimitive(UUID.randomUUID().toString()), "timestamp" to JsonPrimitive(now),
                "entityType" to JsonPrimitive(e.type), "action" to JsonPrimitive(e.action), "summary" to JsonPrimitive(e.summary),
            )).toString() + "\n"
        })
    }

    /** Tutte le voci, dalla più recente; le righe illeggibili si saltano. */
    @Synchronized
    fun readAll(): List<Entry> {
        if (!file.exists()) return emptyList()
        return file.readLines().mapNotNull { line ->
            runCatching {
                val o = Json.parseToJsonElement(line) as JsonObject
                Entry(o["id"]!!.jsonPrimitive.content, o["timestamp"]!!.jsonPrimitive.longOrNull!!, o["entityType"]!!.jsonPrimitive.content,
                    o["action"]!!.jsonPrimitive.content, o["summary"]!!.jsonPrimitive.contentOrNull.orEmpty())
            }.getOrNull()
        }.reversed()
    }

    /** Logout, eliminazione account, cambio utente. */
    @Synchronized
    fun clearAll() { file.delete() }
}

/** Osserva i dati reali (mai la demo) e registra ogni creazione, modifica ed eliminazione, come iOS con la notifica di salvataggio. */
class AuditTracker(private val log: AuditLog) {
    fun start(scope: CoroutineScope, states: Flow<LedgerState>) = scope.launch(Dispatchers.Default) {
        var previous: List<AuditDiff.Item>? = null
        var generation = -1
        states.collect { s ->
            if (s.demo) { previous = null; return@collect }
            val items = s.auditItems()
            val before = previous
            if (before == null || s.generation != generation) { generation = s.generation; previous = items; return@collect }
            previous = items
            log.append(AuditDiff.diff(before, items))
        }
    }
}
