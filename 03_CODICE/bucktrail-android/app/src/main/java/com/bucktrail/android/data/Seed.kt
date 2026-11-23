package com.bucktrail.android.data

import com.bucktrail.android.domain.Categories

/** Seed delle categorie predefinite: se la tabella è vuota le crea tutte; altrimenti aggiunge le mancanti e riallinea le icone. */
suspend fun BucktrailDao.seedDefaultCategories() {
    val existing = categories().associateBy { it.name }
    for (d in Categories.defaults) {
        val current = existing[d.name]
        when {
            current == null -> upsert(CategoryEntity(name = d.name, icon = d.icon, isDefault = true, sortOrder = d.sortOrder))
            current.isDefault && (current.icon != d.icon || current.sortOrder != d.sortOrder) ->
                update(current.copy(icon = d.icon, sortOrder = d.sortOrder))
        }
    }
}
