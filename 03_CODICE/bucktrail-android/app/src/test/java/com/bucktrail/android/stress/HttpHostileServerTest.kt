package com.bucktrail.android.stress

import com.bucktrail.android.sync.ApiException
import com.bucktrail.android.sync.AuthErrors
import com.bucktrail.android.sync.AuthMessage
import com.bucktrail.android.sync.ErrorKind
import com.bucktrail.android.sync.HttpSupabaseApi
import kotlinx.coroutines.runBlocking
import org.junit.After
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assert.fail
import org.junit.Before
import org.junit.Test
import java.net.InetAddress
import java.net.ServerSocket
import java.net.Socket
import kotlin.concurrent.thread

/** Stress del client HTTP contro un server ostile su localhost: risposte malformate, enormi, lente, paginazione che non finisce. Mai rete esterna. */
class HttpHostileServerTest {
    private lateinit var listener: ServerSocket
    private var status = 200
    private var body: () -> String = { "{}" }
    private var delayMs = 0L
    private var requests = java.util.concurrent.atomic.AtomicInteger()
    private fun api(readTimeout: Int = 2_000, page: Int = 2) = HttpSupabaseApi("http://127.0.0.1:${listener.localPort}", "k", 1_000, readTimeout, page)

    private fun serve(s: Socket) = s.use {
        val input = it.getInputStream().buffered()
        var length = 0
        while (true) {
            val sb = StringBuilder()
            while (true) { val c = input.read(); if (c < 0 || c == '\n'.code) break; sb.append(c.toChar()) }
            val l = sb.toString().trimEnd('\r')
            if (l.isEmpty()) break
            if (l.lowercase().startsWith("content-length:")) length = l.substringAfter(":").trim().toInt()
        }
        if (length > 0) input.readNBytes(length)
        requests.incrementAndGet()
        if (delayMs > 0) Thread.sleep(delayMs)
        val bytes = body().toByteArray()
        it.getOutputStream().apply { write("HTTP/1.1 $status X\r\nContent-Type: application/json\r\nContent-Length: ${bytes.size}\r\nConnection: close\r\n\r\n".toByteArray()); write(bytes); flush() }
    }

    @Before fun start() {
        listener = ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"))
        thread(isDaemon = true) { while (!listener.isClosed) { val s = runCatching { listener.accept() }.getOrNull() ?: break; thread(isDaemon = true) { runCatching { serve(s) } } } }
    }
    @After fun stop() { listener.close() }

    private fun expectApi(kind: ErrorKind, block: suspend () -> Unit) = runBlocking {
        try { block(); fail("attesa ApiException($kind)") } catch (e: ApiException) { assertEquals(kind, e.kind) }
    }

    @Test fun malformedSessionBodiesAreApiExceptionsNeverRawCrashes() {
        for (b in listOf("", "not json", "{", """{"access_token":"a"}""", """{"access_token":"a","refresh_token":"r","user":{}}""", "[]", "null", """{"user":"x"}""", "\u0000\u0001")) {
            body = { b }
            expectApi(ErrorKind.Server) { api().signIn("a@b.it", "x") }
            expectApi(ErrorKind.Server) { api().refresh("r") }
        }
    }

    @Test fun malformedTablePagesAreApiExceptions() {
        for (b in listOf("", "<html>502</html>", "{}", "[1,2]", "[{\"id\":", "\"x\"")) {
            body = { b }
            expectApi(ErrorKind.Server) { api().selectAll("mt_transactions", "U", "T") }
        }
    }

    @Test fun serverThatIgnoresRangeDoesNotLoopForever() {
        body = { """[{"id":"a"},{"id":"b"}]""" } // sempre la stessa pagina piena
        expectApi(ErrorKind.Server) { api(page = 2).selectAll("mt_transactions", "U", "T") }
        assertTrue("troppe richieste: ${requests.get()}", requests.get() <= 3)
    }

    @Test fun hugeResponseIsRefusedInsteadOfExhaustingMemory() {
        val big = "[" + "0,".repeat(26 * 1024 * 1024) + "0]" // ~52 MB
        body = { big }
        expectApi(ErrorKind.Server) { api(readTimeout = 20_000).selectAll("mt_transactions", "U", "T") }
    }

    @Test fun slowServerTimesOutAsNetworkError() {
        delayMs = 1_500
        expectApi(ErrorKind.Network) { api(readTimeout = 400).signIn("a@b.it", "x") }
        val e = runCatching { runBlocking { api(readTimeout = 400).signIn("a@b.it", "x") } }.exceptionOrNull() as ApiException
        assertEquals(AuthMessage.Offline, AuthErrors.login(e))
    }

    @Test fun serverErrorsAndUnauthorizedAreClassified() {
        status = 500; body = { "boom" }
        expectApi(ErrorKind.Server) { api().selectAll("t", "U", "T") }
        status = 401; body = { """{"message":"JWT expired"}""" }
        expectApi(ErrorKind.Unauthorized) { api().selectAll("t", "U", "T") }
        status = 403; body = { "" }
        expectApi(ErrorKind.Unauthorized) { api().selectAll("t", "U", "T") }
        status = 502; body = { "<html>bad gateway</html>" }
        expectApi(ErrorKind.Server) { api().upsert("t", listOf(kotlinx.serialization.json.JsonObject(emptyMap())), "T") }
    }

    @Test fun manyPagesOf1000RowsAreAssembledInOrder() {
        // 12.000 righe (10k+ movimenti) in 12 pagine, il server rispetta l'intervallo
        val rows = (0 until 12_000).map { """{"id":"${"%06d".format(it)}"}""" }
        listener.close()
        listener = ServerSocket(0, 50, InetAddress.getByName("127.0.0.1"))
        thread(isDaemon = true) {
            while (!listener.isClosed) {
                val s = runCatching { listener.accept() }.getOrNull() ?: break
                thread(isDaemon = true) { runCatching { s.use {
                    val input = it.getInputStream().buffered(); var range = "0-999"
                    while (true) { val sb = StringBuilder(); while (true) { val c = input.read(); if (c < 0 || c == '\n'.code) break; sb.append(c.toChar()) }
                        val l = sb.toString().trimEnd('\r'); if (l.isEmpty()) break; if (l.lowercase().startsWith("range:")) range = l.substringAfter(":").trim() }
                    val (a, b) = range.split("-").map { n -> n.toInt() }
                    val bytes = ("[" + rows.drop(a).take(b - a + 1).joinToString(",") + "]").toByteArray()
                    it.getOutputStream().apply { write("HTTP/1.1 206 X\r\nContent-Length: ${bytes.size}\r\nConnection: close\r\n\r\n".toByteArray()); write(bytes); flush() }
                } } }
            }
        }
        val got = runBlocking { api(page = 1000).selectAll("mt_transactions", "U", "T", "id") }
        assertEquals(12_000, got.size)
    }
}
