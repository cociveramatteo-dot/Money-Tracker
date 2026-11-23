package com.bucktrail.android.ui

import android.content.res.Resources
import com.bucktrail.android.R
import java.math.BigDecimal
import java.text.NumberFormat
import java.time.LocalDate
import java.time.YearMonth
import java.time.format.TextStyle
import java.util.Currency
import java.util.Locale

/** Formattazioni (§3.1): valuta scelta + locale di sistema, date localizzate. */
object Fmt {
    /** Oscuramento Home («•••• €» letterale) e altrove («• • •»), come iOS. */
    const val HIDDEN_HOME = "•••• €"
    const val HIDDEN = "• • •"

    val currencies: List<String> = listOf("EUR", "USD", "GBP", "CHF", "JPY", "CAD", "AUD", "SEK", "NOK", "DKK", "PLN", "RON", "HRK", "CZK", "HUF")

    fun currency(amount: BigDecimal, code: String = "EUR", locale: Locale = Locale.getDefault()): String =
        NumberFormat.getCurrencyInstance(locale).apply {
            currency = runCatching { Currency.getInstance(code) }.getOrDefault(Currency.getInstance("EUR"))
        }.format(amount)

    fun currencySymbol(code: String = "EUR", locale: Locale = Locale.getDefault()): String =
        runCatching { Currency.getInstance(code).getSymbol(locale) }.getOrDefault("€")

    /** `MMMM yyyy` con iniziale maiuscola («Novembre 2026»). */
    fun monthYear(month: YearMonth, locale: Locale = Locale.getDefault()): String =
        month.month.getDisplayName(TextStyle.FULL_STANDALONE, locale).replaceFirstChar { it.titlecase(locale) } +
            " " + month.year

    /** Prime 3 lettere del mese breve, capitalizzate («Nov»). */
    fun shortMonth(month: YearMonth, locale: Locale = Locale.getDefault()): String =
        month.month.getDisplayName(TextStyle.SHORT_STANDALONE, locale).take(3).replaceFirstChar { it.titlecase(locale) }

    /** «Oggi» / «Ieri» / `d MMM`. */
    fun dayMonth(date: LocalDate, today: LocalDate, res: Resources, locale: Locale = Locale.getDefault()): String = when (date) {
        today -> res.getString(R.string.oggi)
        today.minusDays(1) -> res.getString(R.string.ieri)
        else -> "${date.dayOfMonth} " + date.month.getDisplayName(TextStyle.SHORT, locale).trimEnd('.')
    }

    /** Intestazione Home: weekday e data per esteso. */
    fun headerDate(date: LocalDate, locale: Locale = Locale.getDefault()): String =
        "${date.dayOfWeek.getDisplayName(TextStyle.FULL, locale)} ${date.dayOfMonth} ${date.month.getDisplayName(TextStyle.FULL, locale)}"
}
