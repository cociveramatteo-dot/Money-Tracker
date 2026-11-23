package com.bucktrail.android.ui.theme

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.Font
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontVariation
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.em
import androidx.compose.ui.unit.sp
import com.bucktrail.android.R

/** Scala tipografica `DS.Typo` (§1.2): Space Grotesk per titoli/importi hero, Inter per righe e testi. */
object Fonts {
    val grotesk = FontFamily(
        Font(R.font.space_grotesk_medium, FontWeight.Medium),
        Font(R.font.space_grotesk_semibold, FontWeight.SemiBold),
        Font(R.font.space_grotesk_bold, FontWeight.Bold),
    )
    val inter = FontFamily(
        Font(R.font.inter_regular, FontWeight.Normal),
        Font(R.font.inter_medium, FontWeight.Medium),
        Font(R.font.inter_semibold, FontWeight.SemiBold),
    )

    /** Inter variabile: sostituisce SF Pro nelle schermate form (pesi da 200 a 900). */
    @OptIn(androidx.compose.ui.text.ExperimentalTextApi::class)
    private fun variable(weight: Int) = FontFamily(
        Font(R.font.inter_variable, FontWeight(weight), variationSettings = FontVariation.Settings(FontVariation.weight(weight))),
    )
    val formUltraLight = variable(200)
    val formLight = variable(300)
    val formRegular = variable(400)
    val formMedium = variable(500)
    val formSemibold = variable(600)
    val formBlack = variable(900)
}

private const val TNUM = "tnum"

object Typo {
    val screenTitle = TextStyle(fontFamily = Fonts.grotesk, fontWeight = FontWeight.Bold, fontSize = 30.sp, letterSpacing = (-0.02).em)
    val wordmark = TextStyle(fontFamily = Fonts.grotesk, fontWeight = FontWeight.Bold, fontSize = 26.sp, letterSpacing = (-0.02).em)
    val heroAmount = TextStyle(fontFamily = Fonts.grotesk, fontWeight = FontWeight.SemiBold, fontSize = 44.sp, letterSpacing = (-0.03).em, fontFeatureSettings = TNUM)
    val heroAmountSm = TextStyle(fontFamily = Fonts.grotesk, fontWeight = FontWeight.SemiBold, fontSize = 38.sp, letterSpacing = (-0.03).em, fontFeatureSettings = TNUM)
    val sectionTitle = TextStyle(fontFamily = Fonts.grotesk, fontWeight = FontWeight.SemiBold, fontSize = 18.sp)
    val rowName = TextStyle(fontFamily = Fonts.inter, fontWeight = FontWeight.Medium, fontSize = 15.sp)
    val rowAmount = TextStyle(fontFamily = Fonts.inter, fontWeight = FontWeight.SemiBold, fontSize = 15.sp, fontFeatureSettings = TNUM)
    val secondary = TextStyle(fontFamily = Fonts.inter, fontWeight = FontWeight.Normal, fontSize = 13.sp)
    val caption = TextStyle(fontFamily = Fonts.inter, fontWeight = FontWeight.Normal, fontSize = 12.sp)
    val tabLabel = TextStyle(fontFamily = Fonts.inter, fontWeight = FontWeight.Medium, fontSize = 11.sp)
    val tabLabelActive = TextStyle(fontFamily = Fonts.inter, fontWeight = FontWeight.SemiBold, fontSize = 11.sp)

    // Stili form (SF Pro su iOS -> Inter variabile qui)
    val sheetTitle = TextStyle(fontFamily = Fonts.formSemibold, fontSize = 28.sp)
    val formAmount = TextStyle(fontFamily = Fonts.formBlack, fontSize = 56.sp, fontFeatureSettings = TNUM)
    val formAmountSymbol = TextStyle(fontFamily = Fonts.formUltraLight, fontSize = 28.sp)
    val formDescription = TextStyle(fontFamily = Fonts.formLight, fontSize = 22.sp)
    val formNote = TextStyle(fontFamily = Fonts.formLight, fontSize = 15.sp)
    val sectionLabel = TextStyle(fontFamily = Fonts.formSemibold, fontSize = 11.sp, letterSpacing = 0.1.em)
    val formOption = TextStyle(fontFamily = Fonts.formRegular, fontSize = 15.sp)
    val formOptionSub = TextStyle(fontFamily = Fonts.formRegular, fontSize = 11.sp)
    val primaryButton = TextStyle(fontFamily = Fonts.formSemibold, fontSize = 17.sp)
    val ghostButton = TextStyle(fontFamily = Fonts.formRegular, fontSize = 15.sp)
    val emptyTitle = TextStyle(fontFamily = Fonts.formMedium, fontSize = 17.sp)
    val emptySub = TextStyle(fontFamily = Fonts.formRegular, fontSize = 13.sp)
    val emptyCta = TextStyle(fontFamily = Fonts.formMedium, fontSize = 15.sp)
}

/** Spaziature e misure (`DS.Space`, `DS.Layout`, §1.3), in dp. */
object Dim {
    const val xs = 4; const val s = 8; const val m = 12; const val l = 16; const val xl = 24; const val xxl = 36
    const val screenMargin = 20; const val cardMargin = 16
    const val rowVPad = 14; const val buttonHeight = 52; const val buttonRadius = 14; const val cardRadius = 16
    const val tabBarHeight = 66; const val tabBarSideMargin = 14; const val tabBarBottom = 20
    /** Spazio riservato sotto i contenuti: tab bar (66) + offset (20) + respiro (8) = 94. */
    const val tabBarReserved = 94
    const val listBottomPadding = 100
    const val fabSize = 58; const val fabRadius = 20; const val fabEnd = 22; const val fabBottom = 100
    const val touchTarget = 44
}
