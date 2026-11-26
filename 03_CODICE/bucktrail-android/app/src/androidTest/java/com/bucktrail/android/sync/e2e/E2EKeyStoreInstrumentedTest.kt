package com.bucktrail.android.sync.e2e

import android.content.Context
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.bucktrail.android.sync.HttpSupabaseApi
import kotlinx.coroutines.runBlocking
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import org.junit.Assert.*
import org.junit.Test
import org.junit.runner.RunWith
import java.net.InetAddress
import java.net.ServerSocket
import android.security.keystore.KeyGenParameterSpec
import android.security.keystore.KeyProperties
import java.security.KeyStore
import javax.crypto.KeyGenerator
import java.util.UUID
import kotlin.concurrent.thread

@RunWith(AndroidJUnit4::class)
class E2EKeyStoreInstrumentedTest {
    @Test
    fun deviceKeyIsNonExportableAndEncryptedEntriesCannotMoveBetweenUsers() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val store = E2EKeyStore(context)
        val owner = UUID.randomUUID().toString()
        val other = UUID.randomUUID().toString()
        val key = ByteArray(32) { 91 }
        val otherKey = ByteArray(32) { 19 }
        try {
            store.save(owner.uppercase(), key)
            store.save(other, otherKey)
            assertArrayEquals(key, E2EKeyStore(context).load(owner)?.bytes)
            assertArrayEquals(otherKey, store.load(other)?.bytes)
            val deviceKey = KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.getKey("bucktrail_e2e_key", null)
            assertNotNull(deviceKey)
            assertNull(deviceKey.encoded)
            val prefs = context.getSharedPreferences("bucktrail_e2e", Context.MODE_PRIVATE)
            val encrypted = checkNotNull(prefs.getString("dek.$owner", null))
            assertFalse(encrypted.contains(VaultCrypto.encodeBase64URL(key)))
            assertTrue(prefs.edit().putString("dek.$other", encrypted).commit())
            assertNull(store.load(other))
            store.save(other, otherKey)
            store.clear(owner)
            assertNull(store.load(owner))
            assertArrayEquals(otherKey, store.load(other)?.bytes)
        } finally {
            store.remove(owner)
            store.remove(other)
        }
    }

    @Test
    fun corruptedDeviceKeyIsResetWithoutCrashing() {
        val context = InstrumentationRegistry.getInstrumentation().targetContext
        val store = E2EKeyStore(context)
        val owner = UUID.randomUUID().toString()
        val key = ByteArray(32) { 37 }
        try {
            store.save(owner, key)
            // Una chiave non AES sotto lo stesso alias: Cipher.init fallisce come con un Keystore corrotto.
            KeyStore.getInstance("AndroidKeyStore").apply { load(null) }.deleteEntry("bucktrail_e2e_key")
            KeyGenerator.getInstance(KeyProperties.KEY_ALGORITHM_HMAC_SHA256, "AndroidKeyStore").apply {
                init(KeyGenParameterSpec.Builder("bucktrail_e2e_key", KeyProperties.PURPOSE_SIGN).build())
            }.generateKey()
            assertNull(store.load(owner))
            assertNull(context.getSharedPreferences("bucktrail_e2e", Context.MODE_PRIVATE).getString("dek.$owner", null))
            store.save(owner, key)
            assertArrayEquals(key, store.load(owner)?.bytes)
        } finally {
            store.remove(owner)
        }
    }

    @Test
    fun androidHttpClientPatchesOnlyRequestedMetadataRow() = runBlocking {
        val received = java.util.concurrent.ArrayBlockingQueue<Pair<String, String>>(1)
        ServerSocket(0, 1, InetAddress.getByName("127.0.0.1")).use { listener ->
            val worker = thread(isDaemon = true) {
                listener.accept().use { socket ->
                    socket.soTimeout = 5_000
                    val input = socket.getInputStream().bufferedReader(Charsets.US_ASCII)
                    val request = input.readLine()
                    val headers = generateSequence { input.readLine()?.takeIf(String::isNotEmpty) }.toList()
                    val length = headers.first { it.startsWith("content-length:", ignoreCase = true) }.substringAfter(':').trim().toInt()
                    val body = buildString { repeat(length) { append(input.read().toChar()) } }
                    received.add(request to body)
                    socket.getOutputStream().write("HTTP/1.1 204 Stub\r\nConnection: close\r\n\r\n".encodeToByteArray())
                }
            }
            val api = HttpSupabaseApi("http://127.0.0.1:${listener.localPort}", "fake-key", readTimeoutMs = 5_000, connectTimeoutMs = 5_000)
            val owner = UUID.randomUUID().toString()
            val state = JsonObject(mapOf("state" to JsonPrimitive("active")))
            api.patchE2e(owner, state, "fake-token")
            assertEquals("PATCH /rest/v1/mt_e2e?user_id=eq.$owner HTTP/1.1" to state.toString(), received.poll())
            worker.join(5_000)
        }
    }
}
