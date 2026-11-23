package com.bucktrail.android.shortcuts

import com.bucktrail.android.ui.Fmt
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal

class WidgetContentTest {
    @Test fun amountsAreMaskedWhenPrivacyOrAppLockIsOn() {
        assertTrue(WidgetContent.hide(hideBalance = true, appLock = false))
        assertTrue(WidgetContent.hide(hideBalance = false, appLock = true))
        assertFalse(WidgetContent.hide(false, false))
    }

    @Test fun hiddenContentNeverContainsTheNumbers() {
        val c = WidgetContent.make(BigDecimal("1234.50"), BigDecimal("999.99"), "EUR", hidden = true)
        assertEquals(Fmt.HIDDEN_HOME, c.total); assertEquals(Fmt.HIDDEN_HOME, c.expected)
        assertFalse((c.total + c.expected).any { it.isDigit() })
    }

    @Test fun visibleContentIsFormattedInTheChosenCurrency() {
        val c = WidgetContent.make(BigDecimal("1234.50"), BigDecimal("999.99"), "EUR", hidden = false)
        assertTrue(c.total.contains("1.234,50") || c.total.contains("1,234.50") || c.total.contains("1234"))
        assertFalse(c.empty)
    }

    @Test fun noAccountsIsAnEmptyWidget() {
        assertTrue(WidgetContent.make(null, null, "EUR", false).empty)
    }
}
