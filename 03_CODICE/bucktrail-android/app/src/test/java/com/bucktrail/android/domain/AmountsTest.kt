package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertNull
import org.junit.Test
import java.math.BigDecimal

/** Vettori da StrictAmountParsingTests, CurrencyFormattingTests, StrictRecurrenceAmountTests (iOS). */
class AmountsTest {
    private fun p(s: String) = Amounts.parse(s)?.toPlainString()

    @Test fun rejectsPartialNumbersAndMalformedGrouping() {
        listOf("12abc", "1.234,56", "1,234.56", "12.3.4", "12-3", "12\n", "12€", "abc").forEach { assertNull(it, Amounts.parse(it)) }
    }

    @Test fun rejectsEmptyInputAndBareSigns() {
        listOf("", "-", "+", ".", ",").forEach { assertNull(it, Amounts.parse(it)) }
    }

    @Test fun preservesSupportedFormsAndRoundsHalfUpToTwoDecimals() {
        val cases = listOf("-5,5" to "-5.50", "10,50" to "10.50", "10.50" to "10.50", "500" to "500.00", "+5.5" to "5.50",
            ".5" to "0.50", "5." to "5.00", "10.999" to "11.00", "10.994" to "10.99", "10.995" to "11.00", "-10.995" to "-11.00")
        cases.forEach { (input, expected) -> assertEquals(input, expected, p(input)) }
    }

    @Test fun inputLimitsAndEditableStrings() {
        assertEquals(true, Amounts.isValidInput(Amounts.parse("0,01")))
        assertEquals(false, Amounts.isValidInput(Amounts.parse("0")))
        assertEquals(false, Amounts.isValidInput(Amounts.parse("-3")))
        assertEquals(true, Amounts.isValidInput(Amounts.parse("1000000000")))
        assertEquals(false, Amounts.isValidInput(Amounts.parse("1000000000,01")))
        assertEquals("50", Amounts.editableString(BigDecimal("50.00")))
        assertEquals("50.5", Amounts.editableString(BigDecimal("50.50")))
        assertEquals("1200", Amounts.editableString(BigDecimal("1200")))
        assertEquals("0.00", Amounts.fixedFractionString(BigDecimal.ZERO))
        assertEquals("1234.50", Amounts.fixedFractionString(BigDecimal("1234.5")))
    }

    @Test fun centsRoundTripAndPositionalSigns() {
        assertEquals(2450L, Amounts.toCents(BigDecimal("24.50")))
        assertEquals("0.01", Amounts.fromCents(1).toPlainString())
        assertEquals(BigDecimal("-12.40"), Amounts.signed(BigDecimal("12.40"), "Uscita"))
        assertEquals("12.35", Amounts.roundedFromDouble(12.345).toPlainString())
    }
}
