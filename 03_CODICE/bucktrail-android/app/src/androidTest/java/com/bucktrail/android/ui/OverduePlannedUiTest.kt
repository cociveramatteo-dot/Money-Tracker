package com.bucktrail.android.ui

import android.graphics.Bitmap
import androidx.compose.ui.test.hasTestTag
import androidx.compose.ui.test.junit4.createAndroidComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.test.performClick
import androidx.compose.ui.test.performScrollTo
import androidx.test.ext.junit.runners.AndroidJUnit4
import androidx.test.platform.app.InstrumentationRegistry
import com.bucktrail.android.BucktrailApplication
import com.bucktrail.android.MainActivity
import com.bucktrail.android.R
import com.bucktrail.android.data.DemoSeeder
import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.domain.Amounts
import kotlinx.coroutines.runBlocking
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith
import java.io.File
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/**
 * S-73f: movimento pianificato scaduto (mese passato non confermato) compare in «Da confermare»
 * su Home e Movimenti; la conferma rapida lo rimuove e cattura gli screenshot.
 */
@RunWith(AndroidJUnit4::class)
class OverduePlannedUiTest {
    @get:Rule val rule = createAndroidComposeRule<MainActivity>()
    private val instrumentation get() = InstrumentationRegistry.getInstrumentation()
    private val app get() = rule.activity.application as BucktrailApplication

    @Test
    fun overduePlannedWarningAndQuickConfirm() {
        val zone = ZoneId.systemDefault()
        val overdueDate = LocalDate.now(zone).minusMonths(1).withDayOfMonth(15)
            .atStartOfDay(zone).toInstant().toEpochMilli()
        val txName = "Visita medica"
        val txId = "overdue-ui-s73f"

        runBlocking {
            app.prefs.setNotifications(false)
            app.setDemoMode(true)
            DemoSeeder.forceReset(app.demoDatabase.dao(), app.prefs, app::demoName)
            val accounts = app.demoDatabase.dao().accounts()
            val accountId = checkNotNull(accounts.firstOrNull { !it.isArchived }?.id)
            app.demoDatabase.dao().upsertTransactions(
                listOf(
                    TransactionEntity(
                        id = txId,
                        accountId = accountId,
                        name = txName,
                        amountCents = 4500L,
                        type = Amounts.TYPE_EXPENSE,
                        category = "Salute",
                        categoryIcon = "heart.fill",
                        date = overdueDate,
                        isDone = false,
                        isFixed = true,
                    ),
                ),
            )
        }

        val confirmTag = "btn_confirmOverdue_$txName"
        rule.waitUntil(timeoutMillis = 10_000) {
            rule.onAllNodes(hasTestTag(confirmTag)).fetchSemanticsNodes().isNotEmpty()
        }
        rule.onNodeWithTag(confirmTag).performScrollTo()
        rule.onNodeWithText(app.getString(R.string.demo_tx_supermercato)).performScrollTo()
        capture("home")

        rule.onNodeWithTag("tab_movimenti").performClick()
        rule.waitUntil(timeoutMillis = 10_000) {
            rule.onAllNodes(hasTestTag(confirmTag)).fetchSemanticsNodes().isNotEmpty()
        }
        capture("movimenti")

        rule.onNodeWithTag(confirmTag).performClick()
        rule.waitUntil(timeoutMillis = 10_000) {
            rule.onAllNodes(hasTestTag(confirmTag)).fetchSemanticsNodes().isEmpty()
        }
        val stored = runBlocking { app.demoDatabase.dao().transactions().firstOrNull { it.id == txId } }
        assertTrue("La transazione confermata deve avere isDone == true", stored?.isDone == true)
    }

    private fun capture(screen: String) {
        val label = InstrumentationRegistry.getArguments().getString("s73fMode") ?: return
        val dir = File(app.cacheDir, "s73f").apply { mkdirs() }
        instrumentation.waitForIdleSync()
        rule.waitForIdle()
        val bitmap = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
        File(dir, "android-$screen-$label.png").outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        bitmap.recycle()
    }
}
