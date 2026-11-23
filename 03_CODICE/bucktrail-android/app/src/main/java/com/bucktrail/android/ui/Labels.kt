package com.bucktrail.android.ui

import androidx.annotation.StringRes
import androidx.compose.runtime.Composable
import androidx.compose.ui.res.stringResource
import com.bucktrail.android.R
import com.bucktrail.android.domain.AccountType

/** Nomi canonici italiani (salvati nel DB) -> etichetta localizzata; i nomi personalizzati restano grezzi. */
private val categoryRes: Map<String, Int> = mapOf(
    "Cibo" to R.string.cibo, "Trasporti" to R.string.trasporti, "Svago" to R.string.svago, "Shopping" to R.string.shopping,
    "Salute" to R.string.salute, "Casa" to R.string.casa, "Abbonamenti" to R.string.abbonamenti, "Lavoro" to R.string.lavoro,
    "Istruzione" to R.string.istruzione, "Viaggi" to R.string.viaggi, "Regali" to R.string.regali,
    "Risparmio" to R.string.risparmio, "Giroconto" to R.string.giroconto, "Altro" to R.string.altro,
)

@Composable
fun categoryLabel(name: String): String = categoryRes[name]?.let { stringResource(it) } ?: name

fun categoryLabel(name: String, resources: android.content.res.Resources): String =
    categoryRes[name]?.let { resources.getString(it) } ?: name

@StringRes
fun accountTypeRes(type: AccountType): Int = when (type) {
    AccountType.Cash -> R.string.contanti
    AccountType.Card -> R.string.carta
    AccountType.Checking -> R.string.conto_bancario
    AccountType.Savings -> R.string.risparmio
    AccountType.Investment -> R.string.investimento
}

fun accountTypeIcon(type: AccountType): String = when (type) {
    AccountType.Cash -> "banknote"
    AccountType.Card -> "creditcard"
    AccountType.Checking -> "building.columns"
    AccountType.Savings -> "tray.full"
    AccountType.Investment -> "chart.line.uptrend.xyaxis"
}

/** Tinta riga conto per tipo (§1.1). */
fun accountTypeCategoryProxy(type: AccountType): String = when (type) {
    AccountType.Cash, AccountType.Investment -> "Istruzione" // violet
    AccountType.Card -> "Cibo" // amber
    AccountType.Checking -> "Salute" // green
    AccountType.Savings -> "Trasporti" // blue
}
