package com.bucktrail.android.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.darkColorScheme
import androidx.compose.material3.lightColorScheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.CompositionLocalProvider
import androidx.compose.runtime.Immutable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.runtime.staticCompositionLocalOf
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.bucktrail.android.domain.CategoryTint

/** Token «Sentiero» (`DS` iOS, §1.1). Il tema segue sempre il sistema: mai colori fissi né scelta manuale. */
@Immutable
class BucktrailColors(
    val ink: Color, val paper: Color, val surface: Color, val fog: Color, val filterBorder: Color, val smoke: Color,
    val divider: Color, val accent: Color, val onAccent: Color, val accentSoft: Color, val planned: Color,
    val plannedText: Color, val plannedSoft: Color, val danger: Color, val dangerSoft: Color, val transfer: Color,
    val hero: Color, val heroText: Color, val heroSecondary: Color, val heroDivider: Color, val heroAccent: Color,
    val heroPlanned: Color, val isDark: Boolean,
) {
    val positive: Color get() = accent
    val negative: Color get() = danger

    /** `signColor(x)`: > 0 positivo, < 0 negativo, 0 inchiostro. */
    fun sign(value: Int): Color = when { value > 0 -> positive; value < 0 -> negative; else -> ink }
}

private fun c(hex: Long) = Color(0xFF000000 or hex)

val LightColors = BucktrailColors(
    ink = c(0x121614), paper = c(0xF3F4EF), surface = c(0xFFFFFF), fog = c(0xDCDFD8), filterBorder = c(0xB9BFB6),
    smoke = c(0x5B635E), divider = c(0xECEEE9), accent = c(0x1F7A4D), onAccent = c(0xFFFFFF), accentSoft = c(0xDDEEE3),
    planned = c(0xB45309), plannedText = c(0x8A4A0C), plannedSoft = c(0xFBEBDD), danger = c(0xB42318),
    dangerSoft = c(0xFBE4E1), transfer = c(0x2F6FB0), hero = c(0x121614), heroText = c(0xFFFFFF),
    heroSecondary = c(0xA9B2AC), heroDivider = c(0x2A322D), heroAccent = c(0x5FD19B), heroPlanned = c(0xF2A65A),
    isDark = false,
)

val DarkColors = BucktrailColors(
    ink = c(0xF1F3EF), paper = c(0x0E1210), surface = c(0x171C19), fog = c(0x2A332E), filterBorder = c(0x2A332E),
    smoke = c(0x9AA39D), divider = c(0x232A26), accent = c(0x5FD19B), onAccent = c(0x0E1210), accentSoft = c(0x1C2E25),
    planned = c(0xF2A65A), plannedText = c(0xF2A65A), plannedSoft = c(0x3A2A16), danger = c(0xF26B5E),
    dangerSoft = c(0x3A1D1A), transfer = c(0x6FA8E0), hero = c(0x1F2622), heroText = c(0xF1F3EF),
    heroSecondary = c(0xA9B2AC), heroDivider = c(0x323B35), heroAccent = c(0x5FD19B), heroPlanned = c(0xF2A65A),
    isDark = true,
)

val LocalBucktrail = staticCompositionLocalOf { LightColors }

object Bt {
    val colors: BucktrailColors @Composable @ReadOnlyComposable get() = LocalBucktrail.current
}

/** Sfondo e colore icona della tinta categoria (§1.1). */
data class TintColors(val background: Color, val foreground: Color)

fun CategoryTint.colors(dark: Boolean): TintColors = when (this) {
    CategoryTint.Green -> if (dark) TintColors(c(0x1C2E25), c(0x5FD19B)) else TintColors(c(0xE3EFE7), c(0x1F7A4D))
    CategoryTint.Amber -> if (dark) TintColors(c(0x3A2A16), c(0xF2A65A)) else TintColors(c(0xFBEBDD), c(0x8A4A0C))
    CategoryTint.Blue -> if (dark) TintColors(c(0x1B2A3B), c(0x6FA8E0)) else TintColors(c(0xE4ECF6), c(0x2F6FB0))
    CategoryTint.Violet -> if (dark) TintColors(c(0x2A2540), c(0xA99BE0)) else TintColors(c(0xECE8F6), c(0x5A4AA3))
}

@Composable
fun BucktrailTheme(content: @Composable () -> Unit) {
    val colors = if (isSystemInDarkTheme()) DarkColors else LightColors
    val scheme = if (colors.isDark) darkColorScheme(
        primary = colors.accent, onPrimary = colors.onAccent, background = colors.paper, onBackground = colors.ink,
        surface = colors.surface, onSurface = colors.ink, onSurfaceVariant = colors.smoke, outline = colors.fog,
        primaryContainer = colors.accentSoft, error = colors.danger, surfaceVariant = colors.fog,
        surfaceContainer = colors.surface, surfaceContainerHigh = colors.surface, surfaceContainerHighest = colors.surface, surfaceTint = colors.surface,
    ) else lightColorScheme(
        primary = colors.accent, onPrimary = colors.onAccent, background = colors.paper, onBackground = colors.ink,
        surface = colors.surface, onSurface = colors.ink, onSurfaceVariant = colors.smoke, outline = colors.fog,
        primaryContainer = colors.accentSoft, error = colors.danger, surfaceVariant = colors.fog,
        surfaceContainer = colors.surface, surfaceContainerHigh = colors.surface, surfaceContainerHighest = colors.surface, surfaceTint = colors.surface,
    )
    CompositionLocalProvider(LocalBucktrail provides colors) {
        MaterialTheme(
            colorScheme = scheme, typography = MaterialTheme.typography.copy(labelLarge = Typo.rowName, bodyLarge = Typo.rowName),
            shapes = MaterialTheme.shapes.copy(extraSmall = androidx.compose.foundation.shape.RoundedCornerShape(14.dp)), content = content,
        )
    }
}
