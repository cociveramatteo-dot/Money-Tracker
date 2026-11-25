package com.bucktrail.android.sync.e2e

import androidx.test.ext.junit.runners.AndroidJUnit4
import com.bucktrail.android.sync.HttpSupabaseApi
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.net.InetAddress
import java.net.ServerSocket
import java.net.URLDecoder
import java.util.concurrent.FutureTask
import kotlin.concurrent.thread

@RunWith(AndroidJUnit4::class)
class E2EMigrationTransportInstrumentedTest {
    @Test
    fun metadataMutationUsesExpectedGenerationAndRejectsZeroRows() = runBlocking {
        val user = "11111111-2222-3333-4444-555555555555"
        val key = "0123456789abcdef"
        val timestamp = "2026-11-25T15:20:30.123456+00:00"
        val current = JsonObject(mapOf(
            "user_id" to JsonPrimitive(user), "key_id" to JsonPrimitive(key),
            "state" to JsonPrimitive("migrating"), "updated_at" to JsonPrimitive(timestamp),
        ))
        ServerSocket(0, 1, InetAddress.getByName("127.0.0.1")).use { server ->
            server.soTimeout = 5_000
            val received = FutureTask {
                listOf("[{\"user_id\":\"$user\"}]", "[]").map { response ->
                    server.accept().use { socket ->
                        socket.soTimeout = 5_000
                        val input = socket.getInputStream().bufferedReader()
                        val first = checkNotNull(input.readLine())
                        val headers = generateSequence { input.readLine() }.takeWhile { it.isNotEmpty() }.toList()
                        val length = headers.firstOrNull { it.startsWith("Content-Length:", true) }
                            ?.substringAfter(':')?.trim()?.toInt() ?: 0
                        val body = buildString { repeat(length) { append(input.read().toChar()) } }
                        socket.getOutputStream().apply {
                            write(("HTTP/1.1 200 OK\r\nContent-Type: application/json\r\n" +
                                "Content-Length: ${response.length}\r\nConnection: close\r\n\r\n$response").encodeToByteArray())
                            flush()
                        }
                        Triple(first, headers, body)
                    }
                }
            }
            thread(isDaemon = true) { received.run() }
            val api = HttpSupabaseApi("http://127.0.0.1:${server.localPort}", "test", readTimeoutMs = 5_000)
            assertTrue(api.patchE2eIfCurrent(current, JsonObject(mapOf("state" to JsonPrimitive("active"))), "token"))
            assertFalse(api.deleteE2eIfCurrent(current, "token"))

            val requests = received.get()
            assertTrue(requests[0].first.startsWith("PATCH /rest/v1/mt_e2e?"))
            assertTrue(requests[1].first.startsWith("DELETE /rest/v1/mt_e2e?"))
            assertEquals("{\"state\":\"active\"}", requests[0].third)
            requests.forEach { (line, headers) ->
                val query = line.substringAfter('?').substringBefore(' ').split('&').associate {
                    it.substringBefore('=') to URLDecoder.decode(it.substringAfter('='), "UTF-8")
                }
                assertEquals(mapOf(
                    "user_id" to "eq.$user", "key_id" to "eq.$key",
                    "state" to "eq.migrating", "updated_at" to "eq.$timestamp", "select" to "user_id",
                ), query)
                assertTrue(headers.any { it.equals("Prefer: return=representation", true) })
            }
        }
    }
}
