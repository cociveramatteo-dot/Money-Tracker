package com.bucktrail.android.ui

import androidx.compose.ui.text.TextRange
import androidx.compose.ui.text.input.TextFieldValue
import org.junit.Assert.assertEquals
import org.junit.Test

class RecoveryKeyInputFormatterTest {

    @Test
    fun groupsByFourAndUppercasesWithoutTrailingDash() {
        assertEquals("ABCD", RecoveryKeyInputFormatter.format("abcd"))
        assertEquals("ABCD-E", RecoveryKeyInputFormatter.format("abcde"))
        assertEquals("ABCD-1234-EFGH", RecoveryKeyInputFormatter.format("abcd1234efgh"))
    }

    @Test
    fun normalizesPastedKeyWithDashesAndWhitespace() {
        val raw = "  ab12 cd34-ef56\ngh78 jk90-mn23 pq45-rs67  "
        assertEquals(
            "AB12-CD34-EF56-GH78-JK90-MN23-PQ45-RS67",
            RecoveryKeyInputFormatter.format(raw),
        )
    }

    @Test
    fun backspaceCrossesDashWithoutGettingStuck() {
        assertEquals("ABCD", RecoveryKeyInputFormatter.format("ABCD-", previous = "ABCD-E"))
        assertEquals("ABCE-FGH", RecoveryKeyInputFormatter.format("ABCDEFGH", previous = "ABCD-EFGH"))
        assertEquals("ABC", RecoveryKeyInputFormatter.format("ABCD", previous = "ABCD-"))
    }

    @Test
    fun capsAt32UsefulCharacters() {
        val over = "abcd1234efgh5678jkmn9012pqrs3456tvwx"
        val formatted = RecoveryKeyInputFormatter.format(over)
        assertEquals("ABCD-1234-EFGH-5678-JKMN-9012-PQRS-3456", formatted)
        assertEquals(32, formatted.count { it != '-' })
    }

    @Test
    fun formatSelectionPlacesCursorAfterInsertedGroupDashAndBeforeDeletedDash() {
        val typedFifth = RecoveryKeyInputFormatter.formatSelection(
            newValue = TextFieldValue("abcde", TextRange(5)),
            previous = TextFieldValue("ABCD", TextRange(4)),
        )
        assertEquals("ABCD-E", typedFifth.text)
        assertEquals(TextRange(6), typedFifth.selection)

        val deletedDash = RecoveryKeyInputFormatter.formatSelection(
            newValue = TextFieldValue("ABCDEFGH", TextRange(4)),
            previous = TextFieldValue("ABCD-EFGH", TextRange(5)),
        )
        assertEquals("ABCE-FGH", deletedDash.text)
        assertEquals(TextRange(3), deletedDash.selection)
    }
}
