package com.bucktrail.android.domain

/** Azioni di swipe sui movimenti (§4.2). */
object SwipeRules {
    /** Swipe a destra (Conferma / Pianificato) per voci fisse, non ancora fatte, o fatte con data futura. */
    fun canToggleDone(isFixed: Boolean, isDone: Boolean, isFutureDate: Boolean = false): Boolean =
        isFixed || !isDone || isFutureDate
}
