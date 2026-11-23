package com.bucktrail.android.stress

import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.ui.Fmt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.util.Locale

/** Regressione: saldo di un conto enorme faceva scattare `ArithmeticException` in `toCents` (crash al salvataggio). */
class AmountsLimitsTest {
    @Test fun balanceLimitKeepsEverythingInsideLongCents() {
        assertTrue(Amounts.isValidBalance(BigDecimal("1000000000000")))
        assertTrue(Amounts.isValidBalance(BigDecimal("-1000000000000")))
        assertTrue(Amounts.isValidBalance(BigDecimal.ZERO))
        assertFalse(Amounts.isValidBalance(BigDecimal("1000000000000.01")))
        assertFalse(Amounts.isValidBalance(BigDecimal("99999999999999999999999")))
        assertFalse(Amounts.isValidBalance(null))
        assertEquals(100_000_000_000_000L, Amounts.toCents(Amounts.MAX_BALANCE))
        assertEquals(-100_000_000_000_000L, Amounts.toCents(Amounts.MAX_BALANCE.negate()))
    }

    @Test fun extremeInputsParseOrAreRejectedWithoutThrowing() {
        for (s in listOf("0", "0,01", "0.001", "999999999,99", "1000000000", "1000000000,01", "-5", "1,2,3", "1e5", "٣", "", " ", ".", "9".repeat(60), "0." + "9".repeat(40))) {
            val v = Amounts.parse(s)
            if (v != null && Amounts.isValidInput(v)) Amounts.toCents(v) // mai eccezioni per un importo accettato
        }
        assertEquals(BigDecimal("0.01"), Amounts.parse("0,005")) // HALF_UP
        assertEquals(BigDecimal("1.00"), Amounts.parse("0.999999"))
        assertNull(Amounts.parse("1e5"))
        assertFalse(Amounts.isValidInput(Amounts.parse("1000000000,01")))
        assertTrue(Amounts.isValidInput(Amounts.parse("1000000000")))
    }

    @Test fun currencyFormatsExtremesInEveryLocaleWithoutThrowing() {
        for (loc in listOf("it", "en", "de", "es", "fr", "ja", "zh-Hans", "ar", "he").map { Locale.forLanguageTag(it) })
            for (v in listOf("0", "0.01", "-0.01", "999999999.99", "-999999999999.99", "1000000000000"))
                for (code in listOf("EUR", "JPY", "HRK", "XXX-non-valida")) Fmt.currency(BigDecimal(v), code, loc)
        assertEquals("7662,00\u00a0€", Fmt.currency(BigDecimal("7662"), "EUR", Locale.ITALY))
    }
}
