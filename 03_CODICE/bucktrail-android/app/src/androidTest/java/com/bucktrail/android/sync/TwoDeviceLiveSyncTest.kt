package com.bucktrail.android.sync

import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.bucktrail.android.BuildConfig
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import kotlinx.coroutines.runBlocking
import org.json.JSONObject
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeNotNull
import org.junit.Test
import org.junit.runner.RunWith
import java.net.URL

@RunWith(AndroidJUnit4::class)
class TwoDeviceLiveSyncTest {
    @Test
    fun exchange() = runBlocking {
        val args = InstrumentationRegistry.getArguments()
        val bridge = args.getString("mtBridge")
        assumeNotNull(bridge)
        val run = checkNotNull(args.getString("mtRun"))
        val phase = checkNotNull(args.getString("mtPhase"))
        val app = InstrumentationRegistry.getInstrumentation().targetContext.applicationContext as BucktrailApplication
        val dao = app.database.dao()
        val sync = app.syncService
        val prefix = "S51b $run"
        var step = "avvio Android"

        fun request(path: String): String = URL("$bridge/$path").openConnection().apply {
            connectTimeout = 5_000
            readTimeout = 10_000
            useCaches = false
        }.getInputStream().bufferedReader().use { it.readText() }

        try {
            check(BuildConfig.E2E_ENABLED && BuildConfig.SUPABASE_URL.startsWith("https://"))
            check(!app.repository.isDemo)
            app.startSync()
            if (!app.auth.isLoggedIn) {
                step = "accesso Android"
                val credentials = JSONObject(request("login"))
                app.auth.signIn(credentials.getString("email"), credentials.getString("password"))
            }
            if (phase == "protetta") {
                step = "sblocco Android"
                val phrase = JSONObject(request("android-phrase")).getString("phrase")
                sync.withE2EMigrator(expectedUser = app.auth.userId) { it.unlock(phrase) }
                request("android-unlocked")
            } else if (phase == "dopo") {
                step = "conferma disattivazione Android"
                sync.manualRefresh()
                sync.continueWithoutProtection()
            }

            step = "pull Android di A"
            sync.manualRefresh()
            if (sync.needsDecision.value) sync.resolveDecision(useCloud = true)
            val a = dao.transactions().single { it.name == "$prefix $phase A" }
            check(a.amountCents == 123L)
            request("android-received")

            step = "invio Android di B"
            val accountId = checkNotNull(a.accountId)
            check(dao.accounts().any { it.id == accountId })
            val b = TransactionEntity(accountId = accountId, name = "$prefix $phase B",
                amountCents = 456, type = Amounts.TYPE_EXPENSE, date = System.currentTimeMillis())
            dao.upsert(b)
            app.markTransactionChanged(b.id)
            sync.manualRefresh()
            check(dao.transactions().count { it.name == b.name && it.amountCents == 456L } == 1)
        } catch (error: Exception) {
            // No causes or payloads in instrumentation output.
            assertTrue("$step: ${error.javaClass.simpleName}", false)
        }
    }
}
