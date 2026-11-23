package com.bucktrail.android.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.width
import androidx.compose.material3.Text
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.ui.Modifier
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.testTag
import androidx.compose.ui.semantics.SemanticsActions
import androidx.compose.ui.semantics.getOrNull
import androidx.compose.ui.test.assertIsDisplayed
import androidx.compose.ui.test.getUnclippedBoundsInRoot
import androidx.compose.ui.test.junit4.createComposeRule
import androidx.compose.ui.test.onNodeWithTag
import androidx.compose.ui.test.onNodeWithText
import androidx.compose.ui.text.TextLayoutResult
import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.unit.Density
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.compose.ui.graphics.Color
import androidx.test.ext.junit.runners.AndroidJUnit4
import com.bucktrail.android.ui.components.FitText
import com.bucktrail.android.ui.screens.PageHeader
import com.bucktrail.android.ui.theme.BucktrailTheme
import org.junit.Assert.assertTrue
import org.junit.Rule
import org.junit.Test
import org.junit.runner.RunWith

/**
 * Regressioni di layout già corrette (stress test 2026-11-23, difetti 2 e 3): provate sull'emulatore con font 2,0×
 * e larghezza 320 dp. `./gradlew connectedDebugAndroidTest` (serve un emulatore o un telefono collegato).
 */
@RunWith(AndroidJUnit4::class)
class LayoutRegressionTest {
    @get:Rule val rule = createComposeRule()

    /** Un importo enorme in uno spazio stretto non viene più tagliato in silenzio: si riduce e poi finisce con «…». */
    @Test fun fitTextEllipsizesInsteadOfSilentlyClipping() {
        rule.setContent {
            BucktrailTheme {
                Box(Modifier.width(60.dp)) {
                    FitText("498.000.000.000,00 €", TextStyle(fontSize = 28.sp), Color.Black, Modifier.testTag("amount"))
                }
            }
        }
        rule.waitForIdle()
        val results = mutableListOf<TextLayoutResult>()
        rule.onNodeWithTag("amount").fetchSemanticsNode().config.getOrNull(SemanticsActions.GetTextLayoutResult)?.action?.invoke(results)
        assertTrue("layout del testo disponibile", results.isNotEmpty())
        assertTrue("l'importo deve finire con «…» quando non entra", results.first().isLineEllipsized(0))
    }

    /** A 2,0× su 320 dp il titolo e le azioni stanno su due righe (titolo sopra, azioni sotto): mai sovrapposti. */
    @Test fun pageHeaderStacksTitleAndActionsAtLargeFont() {
        rule.setContent {
            BucktrailTheme {
                CompositionLocalProvider(LocalDensity provides Density(density = 2.75f, fontScale = 2.0f)) {
                    Box(Modifier.width(320.dp)) {
                        PageHeader("Statistiche") {
                            Box(Modifier.width(44.dp).fillMaxWidth().testTag("action")) { Text("A") }
                        }
                    }
                }
            }
        }
        rule.onNodeWithTag("action").assertIsDisplayed()
        val title = rule.onNodeWithText("Statistiche").getUnclippedBoundsInRoot()
        val action = rule.onNodeWithTag("action").getUnclippedBoundsInRoot()
        assertTrue("titolo sopra le azioni (nessuna sovrapposizione)", title.bottom <= action.top)
    }
}
