package com.bucktrail.android.ui

import com.bucktrail.android.data.TransactionEntity
import com.bucktrail.android.ui.screens.localDate
import java.time.ZoneId

/**
 * Ordine unico di visualizzazione dei movimenti:
 * 1) giorno di calendario dal più recente (`localDate(zone)` DESC),
 * 2) a parità di giorno, `createdAt` dal più recente (l'ultimo aggiunto in cima),
 * 3) tie-break deterministico su `id`.
 */
fun List<TransactionEntity>.sortedForDisplay(zone: ZoneId): List<TransactionEntity> =
    sortedWith(
        compareByDescending<TransactionEntity> { it.localDate(zone) }
            .thenByDescending { it.createdAt }
            .thenBy { it.id }
    )
