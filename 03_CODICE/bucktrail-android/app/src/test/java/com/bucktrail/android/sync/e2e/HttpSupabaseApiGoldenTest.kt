package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.HttpSupabaseApi
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.jsonObject
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.io.InputStream
import java.net.InetAddress
import java.net.ServerSocket
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.concurrent.thread

class HttpSupabaseApiGoldenTest {
    @Test
    fun plainSelectKeepsExactUrlAndRangeAcrossPages() = runBlocking {
        LoopbackServer(listOf(200 to """[{"id":"1"},{"id":"2"}]""", 200 to """[{"id":"3"}]""")).use { server ->
            val api = server.api(pageSize = 2)
            assertEquals(3, api.selectAll("mt_transactions", "a+b c", "fake-token", "id,name").size)
            val url = "/rest/v1/mt_transactions?select=id%2Cname&user_id=eq.a%2Bb+c&order=id.asc"
            val requests = server.requests.map {
                listOf(it.line, it.headers["range-unit"], it.headers["range"], it.headers["authorization"])
            }
            assertEquals(listOf("0-1", "2-3").map { listOf("GET $url HTTP/1.1", "items", it, "Bearer fake-token") }, requests)
        }
    }

    @Test
    fun vaultReadAndDeleteSharePaginationWithKindAndUserFilters() = runBlocking {
        LoopbackServer(listOf(200 to """[{"id":"1"},{"id":"2"}]""", 200 to """[{"id":"3"}]""", 204 to "")).use { server ->
            val api = server.api(pageSize = 2)
            assertEquals(3, api.selectVault(VaultKind.Transaction, "owner", "fake-token", "id").size)
            api.deleteVault(VaultKind.Transaction, listOf("1", "2"), "owner", "fake-token")
            val url = "/rest/v1/mt_vault?select=id&user_id=eq.owner&kind=eq.transaction&order=id.asc"
            assertEquals(listOf("GET $url HTTP/1.1", "GET $url HTTP/1.1",
                "DELETE /rest/v1/mt_vault?id=in.(1,2)&user_id=eq.owner&kind=eq.transaction HTTP/1.1"), server.requests.map { it.line })
            assertEquals(listOf("0-1", "2-3", null), server.requests.map { it.headers["range"] })
        }
    }

    @Test
    fun metadataDistinguishesMissingSchemaFromFailuresAndMalformedRows() = runBlocking {
        val responses = listOf(
            404 to """{"code":"unknown"}""", 400 to """{"code":"PGRST205"}""",
            400 to """{"code":"42P01"}""", 200 to "[]", 200 to "[{},{}]", 200 to "[1]",
            503 to """{"code":"PGRST205","message":"try again"}""",
        )
        LoopbackServer(responses).use { server ->
            val api = server.api()
            repeat(3) { assertEquals(E2ERowLookup.Unavailable, api.getE2e("owner", "fake-token")) }
            assertEquals(E2ERowLookup.Absent, api.getE2e("owner", "fake-token"))
            repeat(2) { assertEquals(E2ERowLookup.Malformed, api.getE2e("owner", "fake-token")) }
            val error = runCatching { api.getE2e("owner", "fake-token") }.exceptionOrNull() as ApiException
            assertEquals(ErrorKind.Server, error.kind)
            assertEquals(503, error.status)
            assertEquals(7, server.requests.size)
            assertTrue(server.requests.all { it.line == "GET /rest/v1/mt_e2e?user_id=eq.owner&select=* HTTP/1.1" })
        }
    }

    @Test
    fun metadataInsertIsPureAndDeleteIsUserScoped() = runBlocking {
        val json = """{"user_id":"owner","state":"migrating"}"""
        LoopbackServer(listOf(200 to "[$json]", 201 to "", 204 to "")).use { server ->
            val api = server.api()
            val row = Json.parseToJsonElement(json).jsonObject
            assertEquals(E2ERowLookup.Present(row), api.getE2e("owner", "fake-token"))
            api.insertE2e(row, "fake-token")
            api.deleteE2e("owner", "fake-token")
            assertEquals("POST /rest/v1/mt_e2e HTTP/1.1", server.requests[1].line)
            assertEquals(json, server.requests[1].body)
            assertFalse(server.requests[1].headers.getValue("prefer").contains("merge-duplicates"))
            assertEquals("DELETE /rest/v1/mt_e2e?user_id=eq.owner HTTP/1.1", server.requests[2].line)
        }
    }
}

private class LoopbackServer(replies: List<Pair<Int, String>>) : AutoCloseable {
    data class Request(val line: String, val headers: Map<String, String>, val body: String)
    private val listener = ServerSocket(0, 2, InetAddress.getByName("127.0.0.1"))
    val requests = CopyOnWriteArrayList<Request>()
    private val worker = thread(isDaemon = true) {
        try {
            for ((status, body) in replies) {
                listener.accept().use { socket ->
                    socket.soTimeout = 5_000
                    val input = socket.getInputStream().buffered()
                    val line = input.line()
                    val headers = generateSequence { input.line().takeIf { it.isNotEmpty() } }.associate {
                        it.substringBefore(':').lowercase() to it.substringAfter(':').trim()
                    }
                    val requestBody = input.readNBytes(headers["content-length"]?.toInt() ?: 0).decodeToString()
                    requests.add(Request(line, headers, requestBody))
                    val bytes = body.encodeToByteArray()
                    socket.getOutputStream().apply {
                        write("HTTP/1.1 $status Stub\r\nContent-Type: application/json\r\nContent-Length: ${bytes.size}\r\nConnection: close\r\n\r\n".encodeToByteArray())
                        write(bytes)
                    }
                }
            }
        } catch (e: java.net.SocketException) {
            if (!listener.isClosed) throw e
        }
    }

    fun api(pageSize: Int = 1000) = HttpSupabaseApi(
        "http://127.0.0.1:${listener.localPort}", "fake-key", connectTimeoutMs = 5_000, readTimeoutMs = 5_000,
        pageSize = pageSize,
    )

    override fun close() {
        listener.close()
        worker.join(5_000)
    }

    private fun InputStream.line(): String = buildString {
        while (true) {
            val byte = read()
            if (byte == -1 || byte == '\n'.code) break
            if (byte != '\r'.code) append(byte.toChar())
        }
    }
}
