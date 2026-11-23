package com.bucktrail.android.domain

/** Azioni di swipe sui movimenti (§4.2). */
object SwipeRules {
    /** Swipe a destra (Conferma / Pianificato) solo per voci fisse o non ancora fatte. */
    fun canToggleDone(isFixed: Boolean, isDone: Boolean): Boolean = isFixed || !isDone
}
