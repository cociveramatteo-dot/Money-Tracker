package com.bucktrail.android.ui

import android.graphics.Bitmap
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.hasText
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.compose.ui.test.performTextInput
import androidx.compose.ui.semantics.SemanticsProperties
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.bucktrail.android.BuildConfig
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.MainActivity
import com.bucktrail.android.R
import com.bucktrail.android.sync.HttpSupabaseApi
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Assume.assumeTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File

/**
 * Captures the «Protezione avanzata disattivata» notice: protection is active on this
 * device, then the `mt_e2e` row disappears from the local fake server.
 * Runs only with `-e e2eScenario removed` on a debug build with E2E on and the fake server.
 */
@RunWith(AndroidJUnit4::class)
class E2EProtectionRemovedUiTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()
    private val app get() = rule.activity.application as BucktrailApplication
    private val phrase = "correct horse battery staple"

    @Test
    fun showsProtectionRemovedNoticeWhenServerRowDisappears() {
        assumeTrue(BuildConfig.DEBUG && BuildConfig.E2E_ENABLED)
        assumeTrue(InstrumentationRegistry.getArguments().getString("e2eScenario") == "removed")
        assertTrue(BuildConfig.SUPABASE_URL.startsWith("http://10.0.2.2:"))

        runBlocking {
            app.auth.signIn("demo@test.it", "password1")
            app.syncService.manualRefresh()
        }
        tap("btn_openSettings", scroll = false)
        tap("e2e_settings")
        tap("e2e_activate")
        type("e2e_phrase", phrase)
        type("e2e_repeat", phrase)
        tap("e2e_continue")
        waitFor("e2e_recovery_key")
        type("e2e_key_confirmation", text("e2e_recovery_key").substringAfterLast('-'))
        tap("e2e_key_saved")
        waitFor("e2e_active", 45_000)
        tap("e2e_close", scroll = false)
        tap("btn_closeSettings", scroll = false)

        runBlocking {
            val session = checkNotNull(app.auth.session.value)
            HttpSupabaseApi(BuildConfig.SUPABASE_URL, BuildConfig.SUPABASE_ANON_KEY)
                .deleteE2e(session.userId, session.accessToken)
            app.syncService.manualRefresh()
        }
        waitFor("e2e_removed")
        waitFor("e2e_removed_sign_out")
        capture("protezione-rimossa")

        tap("e2e_removed_sign_out")
        val title = app.getString(R.string.auth_esci_titolo)
        rule.waitUntil(10_000) { rule.onAllNodes(hasText(title)).fetchSemanticsNodes().isNotEmpty() }
        capture("protezione-rimossa-esci")
        rule.onNodeWithText(app.getString(R.string.annulla)).performClick()
        rule.waitUntil(10_000) { rule.onAllNodes(hasText(title)).fetchSemanticsNodes().isEmpty() }
        waitFor("e2e_removed")
    }

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
        android.os.SystemClock.sleep(500)
        val bitmap = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
        File(dir, "$name.png").outputStream().use { bitmap.compress(Bitmap.CompressFormat.PNG, 100, it) }
        bitmap.recycle()
    }
}
