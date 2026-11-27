package com.bucktrail.android.ui

import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue

/**
 * Normalizza l'input dei campi chiave di recupero:
 * maiuscole automatiche, rimozione spazi/trattini in incolla,
 * trattino automatico ogni 4 caratteri (mai in coda),
 * cancellazione che supera il trattino, massimo 32 caratteri utili.
 */
object RecoveryKeyInputFormatter {
    const val MAX_USEFUL_CHARACTERS = 32

    fun format(newValue: String, previous: String = "", maxCharacters: Int = MAX_USEFUL_CHARACTERS): String {
        val useful = extractUseful(newValue).toMutableList()
        val deletedDash = singleDeletedDashIndex(newValue, previous)
        if (deletedDash != null) {
            val usefulBeforeDash = extractUseful(previous.substring(0, deletedDash)).size
            if (usefulBeforeDash > 0 && usefulBeforeDash <= useful.size) {
                useful.removeAt(usefulBeforeDash - 1)
            }
        }
        val clamped = if (useful.size > maxCharacters) useful.subList(0, maxCharacters) else useful
        return groupWithDashes(clamped)
    }

    fun formatSelection(
        newValue: TextFieldValue,
        previous: TextFieldValue,
        maxCharacters: Int = MAX_USEFUL_CHARACTERS,
    ): TextFieldValue {
        val formatted = format(newValue.text, previous.text, maxCharacters)
        val cursorEnd = newValue.selection.end.coerceIn(0, newValue.text.length)
        var usefulBeforeCursor = extractUseful(newValue.text.substring(0, cursorEnd)).size
        val deletedDash = singleDeletedDashIndex(newValue.text, previous.text)
        if (deletedDash != null && deletedDash <= cursorEnd) {
            usefulBeforeCursor = (usefulBeforeCursor - 1).coerceAtLeast(0)
        }
        val clampedUsefulCount = extractUseful(formatted).size
        val targetUseful = usefulBeforeCursor.coerceAtMost(clampedUsefulCount)
        val newCursor = cursorIndexForUsefulCount(formatted, targetUseful)
        return TextFieldValue(text = formatted, selection = TextRange(newCursor))
    }

    private fun extractUseful(text: String): List<Char> {
        val out = ArrayList<Char>(text.length)
        for (ch in text) {
            if (ch == '-' || ch.isWhitespace()) continue
            for (upper in ch.uppercaseChar().toString()) {
                out.add(upper)
            }
        }
        return out
    }

    private fun singleDeletedDashIndex(newValue: String, previous: String): Int? {
        if (previous.isEmpty() || newValue.length != previous.length - 1) return null
        var idx = 0
        while (idx < newValue.length && previous[idx] == newValue[idx]) idx++
        if (idx >= previous.length || previous[idx] != '-') return null
        val withoutDash = previous.removeRange(idx, idx + 1)
        return if (withoutDash == newValue) idx else null
    }

    private fun groupWithDashes(chars: List<Char>): String {
        if (chars.isEmpty()) return ""
        return buildString(chars.size + (chars.size - 1) / 4) {
            chars.forEachIndexed { idx, ch ->
                if (idx > 0 && idx % 4 == 0) append('-')
                append(ch)
            }
        }
    }

    private fun cursorIndexForUsefulCount(formatted: String, usefulCount: Int): Int {
        if (usefulCount <= 0) return 0
        var seen = 0
        for (i in formatted.indices) {
            if (formatted[i] != '-') {
                seen++
                if (seen == usefulCount) return i + 1
            }
        }
        return formatted.length
    }
}
