package com.bucktrail.android.sync.e2e

import com.bucktrail.android.sync.HttpSupabaseApi
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Test
import java.net.InetAddress
import java.net.ServerSocket
import java.util.concurrent.CopyOnWriteArrayList
import kotlin.concurrent.thread

class ObsoleteVaultFilterTest {
    @Test
    fun cleanupSelectsOnlyObsoleteVaultKeys() = runBlocking {
        val requests = CopyOnWriteArrayList<String>()
        ServerSocket(0, 1, InetAddress.getByName("127.0.0.1")).use { listener ->
            listener.soTimeout = 5_000
            val worker = thread(isDaemon = true) {
                repeat(VaultKind.entries.size) {
                    listener.accept().use { socket ->
                        socket.soTimeout = 5_000
                        val input = socket.getInputStream().bufferedReader()
                        requests += checkNotNull(input.readLine())
                        while (!input.readLine().isNullOrEmpty()) {
                            // Consume request headers before sending the response.
                        }
                        socket.getOutputStream().write(
                            "HTTP/1.1 200 OK\r\nContent-Type: application/json\r\nContent-Length: 2\r\nConnection: close\r\n\r\n[]"
                                .encodeToByteArray(),
                        )
                    }
                }
            }
            val api = HttpSupabaseApi(
                "http://127.0.0.1:${listener.localPort}", "fake-anon-key", connectTimeoutMs = 5_000, readTimeoutMs = 5_000,
            )
            api.clearDeadVaultKeys("owner", "live-key", { it("token") }, {}, {})
            worker.join(5_000)
            assertEquals(VaultKind.entries.map { kind ->
                "GET /rest/v1/mt_vault?select=id%2Ckey_id&user_id=eq.owner&kind=eq.${kind.wire}&key_id=neq.live-key&order=id.asc HTTP/1.1"
            }, requests)
        }
    }
}
