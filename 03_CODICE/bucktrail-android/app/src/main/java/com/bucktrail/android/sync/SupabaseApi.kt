package com.bucktrail.android.sync

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.withContext
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.contentOrNull
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import kotlinx.serialization.json.longOrNull
import java.io.IOException
import java.net.HttpURLConnection
import java.net.URI
import java.net.URLEncoder

/** Sessione GoTrue persistita (token + utente). */
data class Session(val accessToken: String, val refreshToken: String, val expiresAt: Long, val userId: String, val email: String?) {
    fun isExpiring(nowSeconds: Long, margin: Long = 60) = nowSeconds >= expiresAt - margin

    fun toJson(): String = buildJsonObject {
        put("a", JsonPrimitive(accessToken)); put("r", JsonPrimitive(refreshToken)); put("e", JsonPrimitive(expiresAt))
        put("u", JsonPrimitive(userId)); email?.let { put("m", JsonPrimitive(it)) }
    }.toString()

    companion object {
        fun fromJson(text: String): Session? = runCatching {
            val o = Json.parseToJsonElement(text).jsonObject
            Session(o["a"]!!.jsonPrimitive.content, o["r"]!!.jsonPrimitive.content, o["e"]!!.jsonPrimitive.longOrNull!!, o["u"]!!.jsonPrimitive.content, o["m"]?.jsonPrimitive?.contentOrNull)
        }.getOrNull()
    }
}

enum class ErrorKind { Network, Unauthorized, RateLimit, Client, Server }

/** Errore di rete o risposta non 2xx; `message` è il testo del server (usato per la mappatura sul messaggio, come iOS). */
class ApiException(val kind: ErrorKind, val status: Int, message: String) : Exception(message)

/** Superficie minima di Supabase (GoTrue + PostgREST) usata dall'app. Implementata da `HttpSupabaseApi` e dai finti nei test. */
interface SupabaseApi {
    suspend fun signIn(email: String, password: String): Session
    /** `null` = account creato ma serve la conferma via email (nessuna sessione). */
    suspend fun signUp(email: String, password: String): Session?
    suspend fun refresh(refreshToken: String): Session
    suspend fun signOut(accessToken: String)
    suspend fun recover(email: String)
    /** Tutte le righe dell'utente (paginate), ordinate per id. `columns` es. `id`. */
    suspend fun selectAll(table: String, userId: String, token: String, columns: String = "*"): List<JsonObject>
    suspend fun upsert(table: String, rows: List<JsonObject>, token: String)
    suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String)
    suspend fun rpc(function: String, token: String)
}

/** Client HTTP puro (`HttpURLConnection`): nessuna libreria, nessun segreto nel codice (URL e chiave pubblica arrivano da `BuildConfig`). */
class HttpSupabaseApi(
    baseUrl: String, private val anonKey: String,
    private val connectTimeoutMs: Int = 15_000, private val readTimeoutMs: Int = 30_000,
    private val pageSize: Int = 1000,
) : SupabaseApi {
    private val base = baseUrl.trimEnd('/')

    private companion object {
        const val MAX_BODY_BYTES = 48 * 1024 * 1024
        const val MAX_ROWS = 2_000_000
    }

    private class Response(val status: Int, val body: String)

    private suspend fun call(method: String, path: String, body: String? = null, token: String? = null, extra: Map<String, String> = emptyMap()): Response =
        withContext(Dispatchers.IO) {
            var conn: HttpURLConnection? = null
            try {
                conn = (URI.create(base + path).toURL().openConnection() as HttpURLConnection).apply {
                    requestMethod = method
                    connectTimeout = connectTimeoutMs; readTimeout = readTimeoutMs
                    setRequestProperty("apikey", anonKey)
                    setRequestProperty("Authorization", "Bearer ${token ?: anonKey}")
                    setRequestProperty("Accept", "application/json")
                    extra.forEach { (k, v) -> setRequestProperty(k, v) }
                    if (body != null) {
                        doOutput = true
                        setRequestProperty("Content-Type", "application/json")
                        outputStream.use { it.write(body.toByteArray(Charsets.UTF_8)) }
                    }
                }
                val status = conn.responseCode
                val stream = if (status in 200..399) conn.inputStream else conn.errorStream
                val text = stream?.let { readBounded(it) }.orEmpty()
                if (status !in 200..299) throw ApiException(kindOf(status), status, errorMessage(text, status))
                Response(status, text)
            } catch (e: ApiException) {
                throw e
            } catch (e: IOException) {
                throw ApiException(ErrorKind.Network, 0, e.message ?: "network error")
            } finally {
                conn?.disconnect()
            }
        }

    /** Legge al massimo `MAX_BODY_BYTES`: una risposta enorme (server difettoso o ostile) non deve esaurire la memoria. */
    private fun readBounded(stream: java.io.InputStream): String = stream.use { input ->
        val out = java.io.ByteArrayOutputStream()
        val buffer = ByteArray(16 * 1024)
        while (true) {
            val n = input.read(buffer)
            if (n < 0) break
            if (out.size() + n > MAX_BODY_BYTES) throw ApiException(ErrorKind.Server, 0, "response too large")
            out.write(buffer, 0, n)
        }
        out.toString(Charsets.UTF_8.name())
    }

    private fun kindOf(status: Int) = when {
        status == 401 || status == 403 -> ErrorKind.Unauthorized
        status == 429 -> ErrorKind.RateLimit
        status >= 500 -> ErrorKind.Server
        else -> ErrorKind.Client
    }

    private fun errorMessage(text: String, status: Int): String = runCatching {
        val o = Json.parseToJsonElement(text).jsonObject
        listOf("msg", "error_description", "message", "error").firstNotNullOfOrNull { (o[it] as? JsonPrimitive)?.contentOrNull } ?: text
    }.getOrDefault(text.ifBlank { "HTTP $status" })

    /** `null` per qualunque risposta malformata (JSON non valido, campi mancanti): mai un'eccezione grezza fino alla schermata. */
    private fun parseSession(text: String, nowSeconds: Long = System.currentTimeMillis() / 1000): Session? = runCatching { parseSessionStrict(text, nowSeconds) }.getOrNull()

    private fun parseSessionStrict(text: String, nowSeconds: Long): Session? {
        val o = Json.parseToJsonElement(text).jsonObject
        val access = (o["access_token"] as? JsonPrimitive)?.contentOrNull ?: return null
        val refresh = (o["refresh_token"] as? JsonPrimitive)?.contentOrNull ?: return null
        val user = o["user"]?.jsonObject ?: return null
        val expires = (o["expires_at"] as? JsonPrimitive)?.longOrNull ?: (nowSeconds + ((o["expires_in"] as? JsonPrimitive)?.longOrNull ?: 3600))
        return Session(access, refresh, expires, user["id"]!!.jsonPrimitive.content.lowercase(), (user["email"] as? JsonPrimitive)?.contentOrNull)
    }

    private fun credentials(email: String, password: String) = buildJsonObject { put("email", JsonPrimitive(email)); put("password", JsonPrimitive(password)) }.toString()

    override suspend fun signIn(email: String, password: String): Session {
        val r = call("POST", "/auth/v1/token?grant_type=password", credentials(email, password))
        return parseSession(r.body) ?: throw ApiException(ErrorKind.Server, r.status, "risposta di accesso non valida")
    }

    override suspend fun signUp(email: String, password: String): Session? =
        parseSession(call("POST", "/auth/v1/signup", credentials(email, password)).body)

    override suspend fun refresh(refreshToken: String): Session {
        val r = call("POST", "/auth/v1/token?grant_type=refresh_token", buildJsonObject { put("refresh_token", JsonPrimitive(refreshToken)) }.toString())
        return parseSession(r.body) ?: throw ApiException(ErrorKind.Server, r.status, "risposta di rinnovo non valida")
    }

    override suspend fun signOut(accessToken: String) { call("POST", "/auth/v1/logout", token = accessToken) }

    override suspend fun recover(email: String) {
        call("POST", "/auth/v1/recover", buildJsonObject { put("email", JsonPrimitive(email)) }.toString())
    }

    private fun enc(s: String) = URLEncoder.encode(s, "UTF-8")

    override suspend fun selectAll(table: String, userId: String, token: String, columns: String): List<JsonObject> {
        val out = ArrayList<JsonObject>()
        var from = 0
        var previous: List<JsonObject>? = null
        while (true) {
            val r = call(
                "GET", "/rest/v1/$table?select=${enc(columns)}&user_id=eq.${enc(userId)}&order=id.asc", token = token,
                extra = mapOf("Range-Unit" to "items", "Range" to "$from-${from + pageSize - 1}"),
            )
            val page = runCatching { Json.parseToJsonElement(r.body) as? JsonArray }.getOrNull() ?: throw ApiException(ErrorKind.Server, r.status, "risposta non valida")
            val rows = page.map { it as? JsonObject ?: throw ApiException(ErrorKind.Server, r.status, "riga non valida") }
            // server che ignora l'intervallo e rimanda sempre la stessa pagina: senza questo controllo il ciclo non finirebbe mai
            if (rows.isNotEmpty() && rows == previous) throw ApiException(ErrorKind.Server, r.status, "paginazione non valida")
            previous = rows
            out += rows
            if (out.size > MAX_ROWS) throw ApiException(ErrorKind.Server, r.status, "too many rows") // mai un risultato parziale: il pull ne cancellerebbe il resto
            if (page.size < pageSize) return out
            from += pageSize
        }
    }

    override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) {
        if (rows.isEmpty()) return
        call("POST", "/rest/v1/$table", JsonArray(rows).toString(), token, mapOf("Prefer" to "resolution=merge-duplicates,return=minimal"))
    }

    override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) {
        ids.chunked(100).forEach { chunk ->
            call("DELETE", "/rest/v1/$table?id=in.(${chunk.joinToString(",") { enc(it) }})&user_id=eq.${enc(userId)}", token = token, extra = mapOf("Prefer" to "return=minimal"))
        }
    }

    override suspend fun rpc(function: String, token: String) { call("POST", "/rest/v1/rpc/$function", "{}", token) }
}

