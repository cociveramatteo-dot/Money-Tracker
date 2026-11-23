package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal

class AccountEditingTest {
    private fun d(s: String) = BigDecimal(s)

    @Test fun withoutTransactionsSetsInitialBalance() =
        assertEquals(AccountEditing.BalanceChange.SetInitial(d("120.00")), AccountEditing.balanceChange(false, d("0"), d("120.00")))

    @Test fun unchangedBalanceDoesNothing() =
        assertEquals(AccountEditing.BalanceChange.None, AccountEditing.balanceChange(true, d("50.00"), d("50")))

    @Test fun positiveDeltaIsIncomeAdjustment() {
        val change = AccountEditing.balanceChange(true, d("50.00"), d("80.50")) as AccountEditing.BalanceChange.Adjust
        assertEquals(d("30.50"), change.amount); assertEquals(Amounts.TYPE_INCOME, change.type)
    }

    @Test fun negativeDeltaIsExpenseAdjustment() {
        val change = AccountEditing.balanceChange(true, d("50.00"), d("20")) as AccountEditing.BalanceChange.Adjust
        assertEquals(d("30.00"), change.amount); assertEquals(Amounts.TYPE_EXPENSE, change.type)
    }

    @Test fun thresholdOffWhenEmptyOrZero() {
        assertNull(AccountEditing.threshold(null)); assertNull(AccountEditing.threshold("")); assertNull(AccountEditing.threshold("0.00"))
        assertEquals(d("100.00"), AccountEditing.threshold("100,00"))
        assertTrue(AccountEditing.isBelowThreshold(d("99.99"), d("100")))
        assertFalse(AccountEditing.isBelowThreshold(d("100"), d("100")))
        assertFalse(AccountEditing.isBelowThreshold(d("1"), null))
    }

    @Test fun excludedAccountsGoLastKeepingOrder() =
        assertEquals(listOf("b", "d", "a", "c"), AccountEditing.includedFirst(listOf("a", "b", "c", "d")) { it == "a" || it == "c" })
}

class CategoryEditingTest {
    @Test fun duplicateIsCaseInsensitiveAndIgnoresSelf() {
        val all = listOf("1" to "Musica", "2" to "Sport")
        assertTrue(CategoryEditing.isDuplicate(" musica ", all, null))
        assertFalse(CategoryEditing.isDuplicate("MUSICA", all, "1"))
        assertFalse(CategoryEditing.isDuplicate("Yoga", all, null))
        assertFalse(CategoryEditing.isDuplicate("  ", all, null))
    }

    @Test fun renameRewritesBudgetCategoriesSorted() {
        assertEquals("Cibo,Zumba", CategoryEditing.renameInBudget("Cibo,Yoga", "Yoga", "Zumba"))
        assertEquals("Aerobica,Cibo", CategoryEditing.renameInBudget("Cibo,Yoga", "Yoga", "Aerobica"))
        assertEquals("Tutti", CategoryEditing.renameInBudget("Tutti", "Yoga", "Zumba"))
        assertEquals("Cibo", CategoryEditing.renameInBudget("Cibo", "Yoga", "Zumba"))
    }

    @Test fun deleteMessageByUsage() {
        assertEquals(CategoryEditing.DeleteMessage.None, CategoryEditing.deleteMessage(0))
        assertEquals(CategoryEditing.DeleteMessage.One, CategoryEditing.deleteMessage(1))
        assertEquals(CategoryEditing.DeleteMessage.Many, CategoryEditing.deleteMessage(7))
    }

    @Test fun availableIconsAre48AndUnique() {
        assertEquals(48, Categories.availableIcons.size)
        assertEquals(48, Categories.availableIcons.toSet().size)
    }
}

class SwipeRulesTest {
    @Test fun leadingSwipeOnlyForFixedOrNotDone() {
        assertTrue(SwipeRules.canToggleDone(isFixed = true, isDone = true))
        assertTrue(SwipeRules.canToggleDone(isFixed = false, isDone = false))
        assertFalse(SwipeRules.canToggleDone(isFixed = false, isDone = true))
    }
}
