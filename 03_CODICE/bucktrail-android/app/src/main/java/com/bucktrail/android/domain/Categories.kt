package com.bucktrail.android.domain

/** Categorie predefinite (nomi canonici italiani salvati nel DB) e fallback icona per nome. */
object Categories {
    data class Default(val name: String, val icon: String, val sortOrder: Int)

    val defaults = listOf(
        Default("Cibo", "fork.knife", 0), Default("Trasporti", "car.fill", 1), Default("Svago", "gamecontroller.fill", 2),
        Default("Shopping", "bag.fill", 3), Default("Salute", "heart.fill", 4), Default("Casa", "house.fill", 5),
        Default("Abbonamenti", "repeat.circle.fill", 6), Default("Lavoro", "briefcase.fill", 7),
        Default("Istruzione", "book.fill", 8), Default("Viaggi", "airplane", 9), Default("Regali", "gift.fill", 10),
        Default("Risparmio", "banknote", 11), Default("Giroconto", "arrow.left.arrow.right", 12),
        Default("Altro", "tray.fill", 13), Default("Rettifica saldo", "arrow.triangle.2.circlepath", 14),
    )

    /** Nomi mostrati localizzati (14, senza «Rettifica saldo»). */
    val localizedNames: Set<String> = defaults.map { it.name }.toSet() - "Rettifica saldo"

    const val OTHER = "Altro"
    const val ADJUSTMENT = "Rettifica saldo"
    const val TRANSFER = "Giroconto"
    const val UNKNOWN_ICON = "circle.dotted"
    const val TRANSFER_ICON = "arrow.left.arrow.right"

    private val byName = defaults.filter { it.name != ADJUSTMENT }.associate { it.name to it.icon }

    /** `DS.categoryIcon(for:)`: icona predefinita per nome, altrimenti `circle.dotted`. */
    fun iconFor(name: String): String = byName[name] ?: UNKNOWN_ICON
}
