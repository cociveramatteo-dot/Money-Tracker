package com.bucktrail.android.sync

import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonArray
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread

/** Il client HTTP contro un server finto su localhost (JDK `HttpServer`): mai il Supabase reale. */
class HttpSupabaseApiTest {
    private class Recorded(val method: String, val path: String, val query: String?, val headers: Map<String, String>, val body: String)

    /** Risposta del finto server: stato + corpo. */
    private class Reply(val status: Int, val body: String)

    /** Server HTTP minimo su localhost (solo `ServerSocket`): niente moduli JDK extra, niente rete esterna. */
    private lateinit var listener: ServerSocket
    private val seen = java.util.Collections.synchronizedList(mutableListOf<Recorded>())
    private var handler: (Recorded) -> Reply = { Reply(200, "{}") }
    private val api get() = HttpSupabaseApi("http://127.0.0.1:${listener.localPort}", "anon-key", connectTimeoutMs = 2_000, readTimeoutMs = 2_000, pageSize = 2)
    private fun reply(status: Int, body: String) = Reply(status, body)

    private fun serve(socket: Socket) = socket.use { s ->
        val input = s.getInputStream().buffered()
        fun line(): String? {
            val sb = StringBuilder()
            while (true) { val c = input.read(); if (c < 0) return if (sb.isEmpty()) null else sb.toString(); if (c == '\n'.code) return sb.toString().trimEnd('\r'); sb.append(c.toChar()) }
        }
        val request = line() ?: return@use
        val (method, target) = request.split(" ").let { it[0] to it[1] }
        val headers = mutableMapOf<String, String>()
        while (true) { val l = line() ?: break; if (l.isEmpty()) break; headers[l.substringBefore(":").lowercase()] = l.substringAfter(":").trim() }
        val length = headers["content-length"]?.toInt() ?: 0
        val body = if (length > 0) String(input.readNBytes(length), Charsets.UTF_8) else ""
        val rec = Recorded(method, target.substringBefore("?"), target.substringAfter("?", "").ifEmpty { null }, headers, body)
        seen += rec
        val r = handler(rec)
        val bytes = r.body.toByteArray()
        s.getOutputStream().apply {
            write("HTTP/1.1 ${r.status} X\r\nContent-Type: application/json\r\nContent-Length: ${bytes.size}\r\nConnection: close\r\n\r\n".toByteArray()); write(bytes); flush()
        }
    }

    @Before fun start() {
        listener = ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"))
        thread(isDaemon = true) { while (!listener.isClosed) { val s = runCatching { listener.accept() }.getOrNull() ?: break; thread(isDaemon = true) { runCatching { serve(s) } } } }
    }
    @After fun stop() { listener.close() }

    private val sessionBody = """{"access_token":"AT","token_type":"bearer","expires_in":3600,"refresh_token":"RT","user":{"id":"AAAAAAAA-0000-4000-8000-0000000000AA","email":"a@b.it"}}"""

    @Test fun signInSendsCredentialsAndAnonKeyAndParsesTheSession() = runBlocking {
        handler = { reply(200, sessionBody) }
        val s = api.signIn("a@b.it", "secret1")
        assertEquals("AT", s.accessToken); assertEquals("RT", s.refreshToken); assertEquals("a@b.it", s.email)
        assertEquals("aaaaaaaa-0000-4000-8000-0000000000aa", s.userId)
        assertTrue(s.expiresAt > System.currentTimeMillis() / 1000 + 3000)
        val r = seen.single()
        assertEquals("POST", r.method); assertEquals("/auth/v1/token", r.path); assertEquals("grant_type=password", r.query)
        assertEquals("anon-key", r.headers["apikey"]); assertEquals("Bearer anon-key", r.headers["authorization"])
        val body = Json.parseToJsonElement(r.body).jsonObject
        assertEquals("a@b.it", body["email"]!!.jsonPrimitive.content); assertEquals("secret1", body["password"]!!.jsonPrimitive.content)
    }

    @Test fun wrongPasswordMapsToTheItalianMessage() = runBlocking {
        handler = { reply(400, """{"code":400,"error_code":"invalid_credentials","msg":"Invalid login credentials"}""") }
        try { api.signIn("a@b.it", "x"); fail() } catch (e: ApiException) {
            assertEquals(ErrorKind.Client, e.kind); assertEquals(400, e.status)
            assertEquals(AuthMessage.InvalidCredentials, AuthErrors.login(e))
        }
    }

    @Test fun legacyErrorShapeIsAlsoRead() = runBlocking {
        handler = { reply(400, """{"error":"invalid_grant","error_description":"Email not confirmed"}""") }
        try { api.signIn("a@b.it", "x"); fail() } catch (e: ApiException) { assertEquals(AuthMessage.EmailNotConfirmed, AuthErrors.login(e)) }
    }

    @Test fun rateLimitIs429() = runBlocking {
        handler = { reply(429, """{"code":429,"error_code":"over_request_rate_limit","msg":"Request rate limit reached"}""") }
        try { api.signIn("a@b.it", "x"); fail() } catch (e: ApiException) { assertEquals(ErrorKind.RateLimit, e.kind); assertEquals(AuthMessage.RateLimit, AuthErrors.login(e)) }
    }

    @Test fun signUpWithEmailConfirmationReturnsNoSession() = runBlocking {
        handler = { reply(200, """{"id":"AAAAAAAA-0000-4000-8000-0000000000AA","email":"a@b.it","confirmation_sent_at":"2026-11-23T10:00:00Z"}""") }
        assertNull(api.signUp("a@b.it", "secret1"))
        assertEquals("/auth/v1/signup", seen.single().path)
    }

    @Test fun signUpAutoConfirmedReturnsASession() = runBlocking {
        handler = { reply(200, sessionBody) }
        assertEquals("AT", api.signUp("a@b.it", "secret1")!!.accessToken)
    }

    @Test fun signUpErrorsMapToTheItalianMessages() = runBlocking {
        handler = { reply(422, """{"code":422,"error_code":"user_already_exists","msg":"User already registered"}""") }
        try { api.signUp("a@b.it", "secret1"); fail() } catch (e: ApiException) { assertEquals(AuthMessage.AlreadyExists, AuthErrors.signUp(e)) }
        handler = { reply(422, """{"code":422,"error_code":"weak_password","msg":"Password should be at least 6 characters."}""") }
        try { api.signUp("a@b.it", "123"); fail() } catch (e: ApiException) { assertEquals(AuthMessage.PasswordTooShort, AuthErrors.signUp(e)) }
        handler = { reply(400, """{"code":400,"error_code":"email_address_invalid","msg":"Unable to validate email address: invalid email"}""") }
        try { api.signUp("zzz", "secret1"); fail() } catch (e: ApiException) { assertEquals(AuthMessage.InvalidEmail, AuthErrors.signUp(e)) }
    }

    @Test fun refreshUsesTheRefreshGrant() = runBlocking {
        handler = { reply(200, sessionBody) }
        api.refresh("OLD")
        assertEquals("grant_type=refresh_token", seen.single().query)
        assertEquals("OLD", Json.parseToJsonElement(seen.single().body).jsonObject["refresh_token"]!!.jsonPrimitive.content)
    }

    @Test fun recoverAndLogoutAndRpc() = runBlocking {
        handler = { reply(200, "{}") }
        api.recover("a@b.it"); api.signOut("AT"); api.rpc("delete_own_account", "AT")
        assertEquals(listOf("/auth/v1/recover", "/auth/v1/logout", "/rest/v1/rpc/delete_own_account"), seen.map { it.path })
        assertEquals("Bearer AT", seen[1].headers["authorization"]); assertEquals("Bearer AT", seen[2].headers["authorization"])
    }

    @Test fun selectAllPagesThroughRangeUntilAShortPage() = runBlocking {
        val all = (1..5).map { buildJsonObject { put("id", JsonPrimitive("id$it")) } }
        handler = { r ->
            val range = r.headers["range"]!!.split("-").map { it.toInt() }
            reply(206, JsonArray(all.drop(range[0]).take(range[1] - range[0] + 1)).toString())
        }
        val rows = api.selectAll("mt_transactions", "U-1", "TOKEN", "id")
        assertEquals((1..5).map { "id$it" }, rows.map { it["id"]!!.jsonPrimitive.content })
        assertEquals(listOf("0-1", "2-3", "4-5"), seen.map { it.headers["range"] })
        assertEquals("select=id&user_id=eq.U-1&order=id.asc", seen.first().query)
        assertEquals("items", seen.first().headers["range-unit"]); assertEquals("Bearer TOKEN", seen.first().headers["authorization"])
    }

    @Test fun upsertSendsAJsonArrayWithMergeDuplicates() = runBlocking {
        handler = { reply(201, "") }
        api.upsert("mt_accounts", listOf(SyncMapper.accountRow(account(A1), USER)), "TOKEN")
        val r = seen.single()
        assertEquals("POST", r.method); assertEquals("/rest/v1/mt_accounts", r.path)
        assertTrue(r.headers["prefer"]!!.contains("resolution=merge-duplicates"))
        val row = Json.parseToJsonElement(r.body).jsonArray.single().jsonObject
        assertEquals("AAAAAAAA-0000-4000-8000-000000000001", row["id"]!!.jsonPrimitive.content)
        assertEquals("100.00", row["initial_balance"]!!.jsonPrimitive.content)
    }

    @Test fun upsertOfNothingSendsNothing() = runBlocking {
        api.upsert("mt_accounts", emptyList(), "T"); assertTrue(seen.isEmpty())
    }

    @Test fun deleteInIsChunkedAndScopedToTheUser() = runBlocking {
        handler = { reply(204, "") }
        api.deleteIn("mt_transactions", (1..150).map { "ID$it" }, "U-1", "TOKEN")
        assertEquals(2, seen.size)
        assertTrue(seen[0].query!!.startsWith("id=in.(ID1,ID2,"))
        assertTrue(seen.all { it.method == "DELETE" && it.query!!.endsWith("&user_id=eq.U-1") })
    }

    @Test fun serverDownIsANetworkLikeErrorForTheUiButServerKindForRetry() = runBlocking {
        handler = { reply(503, "upstream down") }
        try { api.upsert("mt_accounts", listOf(SyncMapper.accountRow(account(A1), USER)), "T"); fail() } catch (e: ApiException) { assertEquals(ErrorKind.Server, e.kind) }
    }

    @Test fun unauthorizedIsReported() = runBlocking {
        handler = { reply(401, """{"message":"JWT expired"}""") }
        try { api.selectAll("mt_accounts", "U", "T"); fail() } catch (e: ApiException) { assertEquals(ErrorKind.Unauthorized, e.kind); assertEquals("JWT expired", e.message) }
    }

    @Test fun connectionRefusedIsANetworkErrorMappedToTheOfflineMessage() = runBlocking {
        val dead = HttpSupabaseApi("http://127.0.0.1:1", "k", connectTimeoutMs = 500, readTimeoutMs = 500)
        try { dead.signIn("a@b.it", "x"); fail() } catch (e: ApiException) {
            assertEquals(ErrorKind.Network, e.kind)
            assertEquals(AuthMessage.Offline, AuthErrors.login(e)); assertEquals(AuthMessage.Offline, AuthErrors.signUp(e))
        }
    }
}
