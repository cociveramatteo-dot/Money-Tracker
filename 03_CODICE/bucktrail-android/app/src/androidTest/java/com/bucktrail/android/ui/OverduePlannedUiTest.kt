package com.bucktrail.android.ui

import android.graphics.Bitmap
import androidx.compose.ui.test.assertContentDescriptionEquals
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

/**
 * S-73f/S-73g: movimento pianificato scaduto (mese passato non confermato) compare in «Da confermare»
 * su Home e Movimenti con pulsante compatto solo icona, data visibile su una riga e icona categoria;
 * la conferma rapida lo rimuove e cattura gli screenshot.
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
        val txName = "Hotel Roma 2 notti"
        val txId = "overdue-ui-s73g"

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
                        category = "Viaggi",
                        categoryIcon = "airplane",
                        date = overdueDate,
                        isDone = false,
                        isFixed = true,
                    ),
                ),
            )
        }

        val confirmTag = "btn_confirmOverdue_$txName"
        val confirmDesc = rule.activity.getString(R.string.conferma)
        rule.waitUntil(timeoutMillis = 10_000) {
            rule.onAllNodes(hasTestTag(confirmTag)).fetchSemanticsNodes().isNotEmpty()
        }
        rule.onNodeWithTag(confirmTag).assertContentDescriptionEquals(confirmDesc)
        rule.onNodeWithTag(confirmTag).performScrollTo()
        rule.onNodeWithText(app.getString(R.string.demo_tx_supermercato)).performScrollTo()
        capture("home")

        rule.onNodeWithTag("tab_movimenti").performClick()
        rule.waitUntil(timeoutMillis = 10_000) {
            rule.onAllNodes(hasTestTag(confirmTag)).fetchSemanticsNodes().isNotEmpty()
        }
        rule.onNodeWithTag(confirmTag).assertContentDescriptionEquals(confirmDesc)
        capture("movimenti")

        rule.onNodeWithTag(confirmTag).performClick()
        rule.waitUntil(timeoutMillis = 10_000) {
            rule.onAllNodes(hasTestTag(confirmTag)).fetchSemanticsNodes().isEmpty()
        }
        val stored = runBlocking { app.demoDatabase.dao().transactions().firstOrNull { it.id == txId } }
        assertTrue("La transazione confermata deve avere isDone == true", stored?.isDone == true)
    }

    private fun capture(screen: String) {
        val label = InstrumentationRegistry.getArguments().getString("s73gMode") ?: return
        val dir = File(app.cacheDir, "s73g").apply { mkdirs() }
        instrumentation.waitForIdleSync()
        rule.waitForIdle()
        val bitmap = checkNotNull(instrumentation.uiAutomation.takeScreenshot())
        File(dir, "android-$screen-$label.png").outputStream().use {
            bitmap.compress(Bitmap.CompressFormat.PNG, 100, it)
        }
        bitmap.recycle()
    }
}
