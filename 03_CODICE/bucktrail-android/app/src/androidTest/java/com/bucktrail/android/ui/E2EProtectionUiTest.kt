package com.bucktrail.android.ui

import android.graphics.Bitmap
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.compose.ui.test.assertIsNotEnabled
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.test.performTextReplacement
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.bucktrail.android.BuildConfig
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.MainActivity
import com.bucktrail.android.R
import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.sync.HttpSupabaseApi
import com.bucktrail.android.sync.e2e.E2EKeyStore
import com.bucktrail.android.sync.e2e.VaultKind
import com.bucktrail.android.sync.e2e.text
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

@RunWith(AndroidJUnit4::class)
class E2EProtectionUiTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()
    private val app get() = rule.activity.application as BucktrailApplication
    private val phrase = "correct horse battery staple"

    @Test
    fun activationAndSecondDeviceUnlockWithLocalFake() {
        fixture("ui")
        val initial = seedPlainMovement()
        tap("btn_openSettings", scroll = false)
        waitFor("e2e_settings")
        rule.onNodeWithTag("e2e_settings").performScrollTo()
        capture("00-settings")
        tap("e2e_settings")
        waitFor("e2e_activate")
        capture("01-off")
        tap("e2e_activate")
        waitFor("e2e_phrase")
        capture("02-phrase")
        tap("e2e_continue")
        assertText("e2e_phrase_error", R.string.e2e_frase_corta)
        type("e2e_phrase", phrase)
        type("e2e_repeat", "different phrase")
        tap("e2e_continue")
        assertText("e2e_phrase_error", R.string.e2e_frase_diverse)
        rule.onNodeWithTag("e2e_repeat").performScrollTo().performTextReplacement(phrase)
        tap("e2e_continue")
        waitFor("e2e_recovery_key")
        val key = text("e2e_recovery_key")
        assertEquals(listOf(4, 4), key.lines().map { it.split('-').size })
        rule.onNodeWithTag("e2e_key_saved").assertIsNotEnabled()
        capture("03-recovery-key")
        type("e2e_key_confirmation", key.substringAfterLast('-').lowercase())
        tap("e2e_key_saved")
        waitFor("e2e_progress")
        capture("04-progress")
        waitFor("e2e_active", 45_000)
        capture("05-active")

        val next = initial.copy(id = java.util.UUID.randomUUID().toString(), name = "After encryption")
        runBlocking {
            app.database.dao().upsertTransactions(listOf(next))
            app.syncService.manualRefresh()
        }
        assertVaultContains(setOf(initial.id, next.id))

        tap("e2e_disable")
        waitFor("e2e_confirm")
        capture("05-disable")
        rule.onNodeWithText(app.getString(R.string.annulla)).performClick()
        tap("e2e_change_phrase")
        waitFor("e2e_phrase")
        capture("08-change-phrase")
        tap("e2e_close", scroll = false)
        tap("btn_closeSettings", scroll = false)

        runBlocking {
            E2EKeyStore(app).clear(checkNotNull(app.auth.userId))
            app.syncService.manualRefresh()
        }
        waitFor("e2e_unlock_secret")
        capture("06-unlock")
        type("e2e_unlock_secret", "incorrect phrase")
        tap("e2e_unlock")
        waitFor("e2e_error")
        assertText("e2e_error", R.string.e2e_errata)
        capture("06-wrong-phrase")
        tap("e2e_unlock_method")
        waitFor("e2e_repeat")
        capture("06-recovery")
        tap("e2e_restart")
        waitFor("e2e_confirm")
        capture("07-restart")
        rule.onNodeWithText(app.getString(R.string.annulla)).performClick()
        tap("e2e_close", scroll = false)
        rule.onNodeWithTag("e2e_unlock_secret").assertDoesNotExist()
        tap("btn_openSettings", scroll = false)
        tap("e2e_settings")
        tap("e2e_unlock_open")
        type("e2e_unlock_secret", phrase)
        tap("e2e_unlock")
        waitFor("e2e_active", 45_000)
    }

    @Test
    fun capturesActivationProgressOnTheEmulator() {
        fixture("progress")
        seedPlainMovement()
        openProtection()
        enterValidActivation()
        waitFor("e2e_progress")
        capture("04-progress")
        waitFor("e2e_active", 45_000)
    }

    @Test
    fun activationPausesWhenFakeServerFailsAfterCreatingMigration() {
        fixture("interrupt")
        seedPlainMovement()
        openProtection()
        enterValidActivation()
        waitFor("e2e_error", 45_000)
        assertText("e2e_error", R.string.e2e_serve_rete)
        capture("04-interrupted")
    }

    @Test
    fun activationResumesAfterProcessRestart() {
        fixture("resume")
        openProtection()
        waitFor("e2e_active", 45_000)
        capture("04-resumed")
        val transaction = runBlocking { app.repository.snapshot().transactions.single { it.name == "Before encryption" } }
        val next = transaction.copy(id = java.util.UUID.randomUUID().toString(), name = "After restart")
        runBlocking {
            app.database.dao().upsertTransactions(listOf(next))
            app.syncService.manualRefresh()
        }
        assertVaultContains(setOf(transaction.id, next.id))
    }

    private fun enterValidActivation() {
        tap("e2e_activate")
        type("e2e_phrase", phrase)
        type("e2e_repeat", phrase)
        tap("e2e_continue")
        waitFor("e2e_recovery_key")
        type("e2e_key_confirmation", text("e2e_recovery_key").substringAfterLast('-'))
        tap("e2e_key_saved")
    }

    private fun fixture(scenario: String) {
        assumeTrue(BuildConfig.DEBUG && BuildConfig.E2E_ENABLED)
        assumeTrue(InstrumentationRegistry.getArguments().getString("e2eScenario") == scenario)
        assertTrue(BuildConfig.SUPABASE_URL.startsWith("http://10.0.2.2:"))
    }

    private fun seedPlainMovement(): TransactionEntity {
        val account = AccountEntity(name = "E2E fixture")
        val initial = TransactionEntity(
            name = "Before encryption", accountId = account.id, amountCents = 250,
            type = Amounts.TYPE_EXPENSE, date = System.currentTimeMillis(),
        )
        runBlocking {
            app.auth.signIn("demo@test.it", "password1")
            app.syncService.manualRefresh()
            app.database.dao().upsertAccounts(listOf(account))
            app.database.dao().upsertTransactions(listOf(initial))
            app.syncService.manualRefresh()
        }
        return initial
    }

    private fun openProtection() {
        tap("btn_openSettings", scroll = false)
        tap("e2e_settings")
    }

    private fun assertVaultContains(ids: Set<String>) = runBlocking {
        val session = checkNotNull(app.auth.session.value)
        val remote = HttpSupabaseApi(BuildConfig.SUPABASE_URL, BuildConfig.SUPABASE_ANON_KEY)
        for (kind in VaultKind.entries) {
            assertTrue(remote.selectAll(kind.table, session.userId, session.accessToken).isEmpty())
        }
        val vault = remote.selectVault(VaultKind.Transaction, session.userId, session.accessToken)
        assertEquals(ids, vault.map { it.text("id") }.toSet())
        assertTrue(vault.all { it.text("payload")?.startsWith("bt1.") == true })
    }

    private fun assertText(tag: String, string: Int) = assertEquals(app.getString(string), text(tag))

    private fun text(tag: String): String =
        rule.onNodeWithTag(tag).fetchSemanticsNode().config[SemanticsProperties.Text].joinToString("\n") { it.text }

    private fun waitFor(tag: String, timeout: Long = 15_000) =
        rule.waitUntil(timeoutMillis = timeout) { rule.onAllNodes(hasTestTag(tag)).fetchSemanticsNodes().isNotEmpty() }

    private fun tap(tag: String, scroll: Boolean = true) {
        waitFor(tag)
        val node = rule.onNodeWithTag(tag)
        if (scroll) node.performScrollTo()
        node.performClick()
    }

    private fun type(tag: String, value: String) {
        waitFor(tag)
        rule.onNodeWithTag(tag).performScrollTo().performTextInput(value)
    }

    private fun capture(name: String) {
        val label = InstrumentationRegistry.getArguments().getString("e2eCapture") ?: return
        val dir = File(app.cacheDir, "e2e-captures/$label").apply { mkdirs() }
        instrumentation.waitForIdleSync()
        // UiAutomation can still see the last composed buffer during the native IME transition.
        if (name == "04-progress") android.os.SystemClock.sleep(500)
        val bitmap = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
        File(dir, "$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
    }
}
