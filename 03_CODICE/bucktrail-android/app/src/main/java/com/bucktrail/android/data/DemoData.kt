package com.bucktrail.android.data

import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.AuditDiff
import com.bucktrail.android.domain.Categories
import com.bucktrail.android.domain.RecurrenceCalculator
import com.bucktrail.android.domain.RecurrenceException
import com.bucktrail.android.domain.RecurrenceExceptionCodec
import com.bucktrail.android.domain.RuleSnapshot
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.UUID

/**
 * Dati dimostrativi (§4.12, `DemoDataSeeder.swift`, seedVersion 6): numeri e giorni identici a iOS.
 * Funzione pura: nessun accesso al database, i nomi arrivano da `name("tx.gym")`-> testo localizzato.
 */
object DemoData {
    const val SEED_VERSION = 6

    class Result(
        val accounts: List<AccountEntity>, val rules: List<RecurringRuleEntity>, val transactions: List<TransactionEntity>,
        val budgets: List<BudgetEntity>, val goals: List<GoalEntity>,
    )

    fun build(now: Instant, zone: ZoneId, name: (String) -> String, newId: () -> UUID = UUID::randomUUID): Result {
        val calc = RecurrenceCalculator(zone)
        val today = calc.noon(now)
        val todayDay = calc.day(now)
        val monthStart = todayDay.withDayOfMonth(1)
        val nowMs = now.toEpochMilli()

        // Aritmetica di calendario: i giorni civili restano tali anche attraverso DST e cambio anno.
        fun dayOf(offset: Int, day: Int): LocalDate {
            val start = monthStart.plusMonths(offset.toLong())
            return start.plusDays(minOf(day, start.lengthOfMonth()) - 1L)
        }
        fun date(offset: Int, day: Int): Instant = dayOf(offset, day).atTime(12, 0).atZone(zone).toInstant()
        fun icon(category: String) = Categories.defaults.firstOrNull { it.name == category }?.icon ?: "tray.fill"
        fun cents(v: BigDecimal) = Amounts.toCents(v)

        fun account(key: String, type: String, balance: Long, color: String) =
            AccountEntity(id = newId().toString(), name = name("account.$key"), type = type, initialBalanceCents = balance * 100, colorHex = color, createdAt = nowMs)
        val conto = account("conto", "Conto Bancario", 2_900, "1F7A4D")
        val risparmi = account("risparmi", "Risparmio", 6_200, "2F6FB0")
        val carta = account("carta", "Carta", 4_800, "5A4AA3")
        val contanti = account("contanti", "Contanti", 650, "B45309")

        val txs = ArrayList<TransactionEntity>()
        fun movement(key: String, amount: BigDecimal, category: String, whenAt: Instant, account: AccountEntity, type: String = Amounts.TYPE_EXPENSE): TransactionEntity {
            val tx = TransactionEntity(
                id = newId().toString(), accountId = account.id, name = name(key), amountCents = cents(amount), type = type,
                category = category, categoryIcon = icon(category), date = whenAt.toEpochMilli(), isDone = whenAt.isBefore(today), createdAt = nowMs,
            )
            txs += tx
            return tx
        }
        fun replace(tx: TransactionEntity, f: (TransactionEntity) -> TransactionEntity) { txs[txs.indexOfFirst { it.id == tx.id }] = f(tx) }
        fun dec(v: Any) = BigDecimal(v.toString())

        val rules = ArrayList<RecurringRuleEntity>()
        fun series(key: String, amount: BigDecimal, category: String, day: Int, account: AccountEntity, type: String = Amounts.TYPE_EXPENSE, override: Boolean = false) {
            // Ancora il giorno 29/30/31 anche se il primo mese storico è più corto.
            val start = if (dayOf(-7, day).dayOfMonth == day) date(-7, day) else date(-8, day)
            val ruleId = newId()
            val exceptions = if (override) mapOf(calc.key(date(0, day)) to RecurrenceException(amount = "112.40")) else emptyMap()
            rules += RecurringRuleEntity(
                id = ruleId.toString(), name = name(key), type = type, category = category, categoryIcon = icon(category),
                amountCents = cents(amount), isFixed = true, accountId = account.id, frequency = "mensile", startDate = start.toEpochMilli(),
                exceptionsJson = if (override) RecurrenceExceptionCodec.encode(exceptions) else "{}",
                materializedThrough = date(0, 1).toEpochMilli(), createdAt = nowMs,
            )
            val snapshot = RuleSnapshot(
                id = ruleId, name = name(key), amount = amount, type = type, category = category, categoryIcon = icon(category), isFixed = true,
                accountId = UUID.fromString(account.id), frequency = "mensile", startDate = start, exceptions = exceptions,
            )
            for (o in calc.occurrences(snapshot, date(-7, 1), date(1, 1))) {
                val tx = movement(key, o.amount, category, o.date, account, type)
                replace(tx) {
                    it.copy(id = o.id.toString(), templateId = ruleId.toString().uppercase(), isFixed = true,
                        isDone = o.date.isBefore(today) || (key == "tx.gym" && calc.day(o.date) == todayDay))
                }
            }
        }
        series("tx.stipendio", dec(2850), "Lavoro", 1, conto, Amounts.TYPE_INCOME)
        series("tx.affitto", dec(780), "Casa", 3, conto)
        series("tx.bolletta", dec(86), "Casa", todayDay.dayOfMonth, conto, override = true)
        series("tx.internet", dec(29), "Casa", 9, conto)
        series("tx.streaming", dec("15.99"), "Abbonamenti", 12, carta)
        series("tx.music", dec("10.99"), "Abbonamenti", 6, carta)
        series("tx.gym", dec(45), "Salute", todayDay.dayOfMonth, conto)
        series("tx.insurance", dec(64), "Trasporti", 23, conto)
        series("tx.installment", dec(125), "Shopping", 10, conto)

        // Otto profili mensili distinti; nel mese corrente gli acquisti sono distribuiti sui giorni trascorsi.
        val variation = listOf(0, 18, -12, 35, 8, -5, 24, 12)
        for (offset in -7..0) {
            val v = BigDecimal(variation[offset + 7])
            val elapsed = if (offset == 0) todayDay.dayOfMonth else 28
            fun spent(key: String, amount: BigDecimal, category: String, day: Int, account: AccountEntity) {
                val purchaseDay = if (offset == 0) maxOf(1, day * elapsed / 28) else day
                val tx = movement(key, amount, category, date(offset, purchaseDay), account)
                replace(tx) { it.copy(isDone = true) }
            }
            for (day in listOf(2, 8, 15, 28)) spent("tx.supermercato", dec(62) + v.divide(BigDecimal(4)), "Cibo", day, conto)
            spent("tx.carburante", dec(58) + v, "Trasporti", 6, conto)
            spent("tx.ristorante", dec(68) + v, "Svago", 11, carta)
            spent("tx.cinema", dec(32), "Svago", 19, contanti)
            spent("tx.farmacia", dec(22) + v.divide(BigDecimal(2)), "Salute", 14, carta)
            spent("tx.shopping", dec(75) + v, "Shopping", 18, carta)
            spent("tx.course", dec(35), "Istruzione", 10, carta)
            spent("tx.regalo", if (offset == -1) dec(240) else dec(40) + v, "Regali", 24, carta)
            spent("tx.other", dec(12), "Altro", 7, contanti)
            if (offset == -3 || offset == -6) {
                spent("tx.volo", dec(if (offset == -3) 320 else 145), "Viaggi", 13, carta)
                spent("tx.hotel", dec(if (offset == -3) 640 else 210), "Viaggi", 17, carta)
            }
            if (offset == -2) spent("tx.dentista", dec(280), "Salute", 16, conto)
            if (offset == -4 || offset == -1) {
                val bonus = movement("tx.bonus", dec(if (offset == -4) 450 else 180), "Lavoro", date(offset, 18), conto, Amounts.TYPE_INCOME)
                replace(bonus) { it.copy(isDone = true) }
            }
            val interest = movement("tx.interest", dec("2.75"), "Risparmio", date(offset, minOf(2, elapsed)), risparmi, Amounts.TYPE_INCOME)
            replace(interest) { it.copy(isDone = true) }
            // Giroconto a due gambe: visibile nei conti, escluso dai report.
            val group = newId().toString().uppercase()
            for ((acc, type) in listOf(conto to Amounts.TYPE_EXPENSE, risparmi to Amounts.TYPE_INCOME)) {
                val tx = movement("tx.risparmio", dec(180), "Giroconto", date(offset, minOf(5, elapsed)), acc, type)
                replace(tx) { it.copy(isDone = true, isTransfer = true, transferGroupId = group) }
            }
        }
        // Pianificati non seriali: restano visibili anche l'ultimo giorno del mese.
        movement("tx.hotel", dec(195), "Viaggi", date(0, 31), carta)
        movement("tx.course", dec(90), "Istruzione", calc.addDays(today, 3), conto)

        val budgets = ArrayList<BudgetEntity>()
        for (offset in -7..0) {
            val anchor = dayOf(offset, 1)
            for ((category, limit) in listOf("Cibo" to 300L, "Svago" to 90L, "Trasporti" to 240L, "Salute" to 180L, "Shopping" to 170L)) {
                budgets += BudgetEntity(
                    id = newId().toString(), category = category, categoryIcon = Categories.defaults.firstOrNull { it.name == category }?.icon ?: "circle.dotted",
                    monthlyLimitCents = limit * 100, month = anchor.monthValue, year = anchor.year, createdAt = nowMs,
                )
            }
        }

        fun goal(key: String, target: Long, current: Long, emoji: String, months: Long?) = GoalEntity(
            id = newId().toString(), name = name("goal.$key"), emoji = emoji, targetCents = target, currentCents = current,
            deadline = months?.let { now.atZone(zone).plusMonths(it).toInstant().toEpochMilli() }, isCompleted = current >= target, createdAt = nowMs,
        )
        val goals = listOf(
            goal("vacanza", 280_000, 196_000, "airplane", 2), goal("emergenza", 1_500_000, 664_000, "banknote", null),
            goal("computer", 249_900, 64_000, "laptopcomputer", 8), goal("fotografia", 45_000, 45_000, "camera.fill", null),
        )
        return Result(listOf(conto, risparmi, carta, contanti), rules, txs, budgets, goals)
    }
}

/** Elementi della cronologia modifiche per l'istantanea attuale (§4.11): testi italiani fissi, come iOS. */
fun LedgerState.auditItems(): List<AuditDiff.Item> {
    val out = ArrayList<AuditDiff.Item>(transactions.size + accounts.size + budgets.size + goals.size)
    for (t in transactions) out += AuditDiff.Item(AuditDiff.TRANSACTION, t.id, "${t.name} — ${Amounts.fixedFractionString(Amounts.fromCents(t.amountCents))} (${t.type})", t)
    for (a in accounts) out += AuditDiff.Item(AuditDiff.ACCOUNT, a.id, "${a.name} — saldo iniziale ${Amounts.fixedFractionString(Amounts.fromCents(a.initialBalanceCents))}", a)
    for (b in budgets) out += AuditDiff.Item(AuditDiff.BUDGET, b.id, "${b.category} — ${Amounts.fixedFractionString(Amounts.fromCents(b.monthlyLimitCents))}/mese", b)
    for (g in goals) out += AuditDiff.Item(AuditDiff.GOAL, g.id, "${g.name} — obiettivo ${Amounts.fixedFractionString(Amounts.fromCents(g.targetCents))}", g)
    return out
}
