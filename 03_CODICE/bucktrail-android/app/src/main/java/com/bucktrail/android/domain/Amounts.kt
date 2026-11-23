package com.bucktrail.android.domain

import java.math.BigDecimal
import java.math.RoundingMode

/** Importi: `BigDecimal` nel dominio, centesimi (`Long`) solo nelle colonne Room. Stessa semantica di `Decimal.parseAmount` iOS. */
object Amounts {
    const val TYPE_EXPENSE = "Uscita"
    const val TYPE_INCOME = "Entrata"
    val MAX: BigDecimal = BigDecimal("1000000000")
    private val strict = Regex("^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$")

    /** `,` -> `.`, regex rigida sull'intera stringa, arrotondamento `.plain` (HALF_UP) a 2 decimali; altrimenti `null`. */
    fun parse(raw: String): BigDecimal? {
        val text = raw.replace(',', '.')
        if (!strict.matches(text)) return null
        return BigDecimal(text).setScale(2, RoundingMode.HALF_UP)
    }

    /** Importo valido per l'input utente: `0 < v <= 1_000_000_000`. */
    fun isValidInput(value: BigDecimal?): Boolean = value != null && value.signum() > 0 && value <= MAX

    /** Intero senza decimali ("50") altrimenti max 2 decimali, punto, senza raggruppamento. */
    fun editableString(value: BigDecimal): String {
        val v = value.setScale(2, RoundingMode.HALF_UP).stripTrailingZeros()
        return (if (v.scale() < 0) v.setScale(0) else v).toPlainString()
    }

    /** Sempre 2 decimali, punto, senza raggruppamento (CSV, soglie, audit). */
    fun fixedFractionString(value: BigDecimal): String = value.setScale(2, RoundingMode.HALF_UP).toPlainString()

    fun toCents(value: BigDecimal): Long = value.setScale(2, RoundingMode.HALF_UP).movePointRight(2).longValueExact()
    fun fromCents(cents: Long): BigDecimal = BigDecimal.valueOf(cents, 2)

    /** `Decimal(roundedFromDouble:)` degli Intent: da `String.format("%.2f")` POSIX. */
    fun roundedFromDouble(value: Double): BigDecimal = BigDecimal(String.format(java.util.Locale.ROOT, "%.2f", value))

    fun signed(amount: BigDecimal, type: String): BigDecimal = if (type == TYPE_INCOME) amount else amount.negate()
}
