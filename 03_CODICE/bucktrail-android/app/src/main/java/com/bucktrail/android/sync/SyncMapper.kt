package com.bucktrail.android.sync

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral
import kotlinx.serialization.json.booleanOrNull
import kotlinx.serialization.json.buildJsonObject
import kotlinx.serialization.json.intOrNull
import java.math.BigDecimal
import java.math.RoundingMode
import java.time.OffsetDateTime
import java.time.ZoneOffset
import java.time.format.DateTimeFormatter

/** Riga remota non decodificabile: il pull si interrompe per intero (mai applicazioni parziali). */
class SyncFormatException(message: String) : Exception(message)

/**
 * Conversione entità Room <-> righe JSON delle tabelle `mt_*` (§5.2), con le regole di compatibilità con iOS:
 * UUID in MAIUSCOLO in scrittura (ciò che invia `uuidString`), `template_id`/`transfer_group_id` MAIUSCOLI,
 * `exceptions` stringa JSON nel formato Codable di iOS, date ISO-8601 UTC, importi numerici senza perdita.
 * In scrittura tutte le chiavi sono sempre presenti (i nil diventano NULL), come l'upsert completo di iOS.
 */
object SyncMapper {
    private val isoOut: DateTimeFormatter = DateTimeFormatter.ofPattern("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'").withZone(ZoneOffset.UTC)

    fun iso(epochMillis: Long): String = isoOut.format(java.time.Instant.ofEpochMilli(epochMillis))

    /** Accetta `Z`, `+00:00`, con o senza frazioni (anche microsecondi di Postgres). */
    fun parseDate(text: String): Long = try {
        OffsetDateTime.parse(text).toInstant().toEpochMilli()
    } catch (e: Exception) {
        // Postgres può restituire "2026-11-23 10:30:00+00" (spazio e offset corto)
        try {
            val t = text.replace(' ', 'T').let { if (Regex("[+-]\\d\\d$").containsMatchIn(it)) "$it:00" else it }
            OffsetDateTime.parse(t).toInstant().toEpochMilli()
        } catch (e2: Exception) { throw SyncFormatException("data non valida: $text") }
    }

    @OptIn(ExperimentalSerializationApi::class)
    private fun num(cents: Long): JsonElement = JsonUnquotedLiteral(BigDecimal.valueOf(cents, 2).toPlainString())
    private fun uuid(id: String?): JsonElement = if (id == null) JsonNull else JsonPrimitive(id.uppercase())
    private fun dateOrNull(ms: Long?): JsonElement = if (ms == null) JsonNull else JsonPrimitive(iso(ms))

    fun accountRow(a: AccountEntity, userId: String): JsonObject = buildJsonObject {
        put("id", uuid(a.id)); put("user_id", uuid(userId)); put("name", JsonPrimitive(a.name)); put("type", JsonPrimitive(a.type))
        put("initial_balance", num(a.initialBalanceCents)); put("color_hex", JsonPrimitive(a.colorHex)); put("created_at", JsonPrimitive(iso(a.createdAt)))
        put("is_archived", JsonPrimitive(a.isArchived)); put("is_excluded_from_total", JsonPrimitive(a.isExcludedFromTotal))
    }

    fun transactionRow(t: TransactionEntity, userId: String): JsonObject = buildJsonObject {
        put("id", uuid(t.id)); put("user_id", uuid(userId)); put("account_id", uuid(t.accountId)); put("name", JsonPrimitive(t.name))
        put("amount", num(t.amountCents)); put("type", JsonPrimitive(t.type)); put("category", JsonPrimitive(t.category))
        put("category_icon", JsonPrimitive(t.categoryIcon)); put("date", JsonPrimitive(iso(t.date))); put("is_done", JsonPrimitive(t.isDone))
        put("is_fixed", JsonPrimitive(t.isFixed)); put("is_transfer", JsonPrimitive(t.isTransfer))
        put("transfer_group_id", JsonPrimitive(t.transferGroupId.uppercase())); put("notes", JsonPrimitive(t.notes))
        put("recurring_frequency", JsonPrimitive(t.recurringFrequency)); put("template_id", JsonPrimitive(t.templateId.uppercase()))
        put("created_at", JsonPrimitive(iso(t.createdAt)))
    }

    fun budgetRow(b: BudgetEntity, userId: String): JsonObject = buildJsonObject {
        put("id", uuid(b.id)); put("user_id", uuid(userId)); put("account_id", uuid(b.accountId)); put("category", JsonPrimitive(b.category))
        put("category_icon", JsonPrimitive(b.categoryIcon)); put("monthly_limit", num(b.monthlyLimitCents))
        put("month", JsonPrimitive(b.month)); put("year", JsonPrimitive(b.year)); put("created_at", JsonPrimitive(iso(b.createdAt)))
    }

    fun goalRow(g: GoalEntity, userId: String): JsonObject = buildJsonObject {
        put("id", uuid(g.id)); put("user_id", uuid(userId)); put("name", JsonPrimitive(g.name)); put("emoji", JsonPrimitive(g.emoji))
        put("target_amount", num(g.targetCents)); put("current_amount", num(g.currentCents)); put("deadline", dateOrNull(g.deadline))
        put("is_completed", JsonPrimitive(g.isCompleted)); put("created_at", JsonPrimitive(iso(g.createdAt)))
    }

    fun ruleRow(r: RecurringRuleEntity, userId: String): JsonObject = buildJsonObject {
        put("id", uuid(r.id)); put("user_id", uuid(userId)); put("name", JsonPrimitive(r.name)); put("type", JsonPrimitive(r.type))
        put("category", JsonPrimitive(r.category)); put("category_icon", JsonPrimitive(r.categoryIcon)); put("notes", JsonPrimitive(r.notes))
        put("amount", num(r.amountCents)); put("is_fixed", JsonPrimitive(r.isFixed)); put("account_id", uuid(r.accountId))
        put("frequency", JsonPrimitive(r.frequency)); put("start_date", JsonPrimitive(iso(r.startDate))); put("end_date", dateOrNull(r.endDate))
        put("exceptions", JsonPrimitive(r.exceptionsJson)); put("materialized_through", dateOrNull(r.materializedThrough))
        put("created_at", JsonPrimitive(iso(r.createdAt)))
    }

    // ---- lettura -------------------------------------------------------------------------------------------

    private fun JsonObject.el(key: String): JsonElement? = this[key]?.takeUnless { it is JsonNull }
    private fun JsonObject.str(key: String): String = (el(key) as? JsonPrimitive)?.takeIf { it.isString }?.content ?: throw SyncFormatException("campo $key")
    private fun JsonObject.strOr(key: String, default: String): String = (el(key) as? JsonPrimitive)?.content ?: default
    private fun JsonObject.bool(key: String): Boolean = (el(key) as? JsonPrimitive)?.booleanOrNull ?: throw SyncFormatException("campo $key")
    private fun JsonObject.int(key: String): Int = (el(key) as? JsonPrimitive)?.intOrNull ?: throw SyncFormatException("campo $key")
    private fun JsonObject.cents(key: String): Long = (el(key) as? JsonPrimitive)?.let {
        runCatching { BigDecimal(it.content).setScale(2, RoundingMode.HALF_UP).movePointRight(2).longValueExact() }.getOrNull()
    } ?: throw SyncFormatException("campo $key")
    private fun JsonObject.date(key: String): Long = parseDate(str(key))
    private fun JsonObject.dateOrNull(key: String): Long? = el(key)?.let { parseDate((it as? JsonPrimitive)?.content ?: throw SyncFormatException("campo $key")) }
    private fun JsonObject.idOrNull(key: String): String? = el(key)?.let { (it as? JsonPrimitive)?.content?.lowercase() }
    private fun JsonObject.id(): String = str("id").lowercase()

    fun account(o: JsonObject) = AccountEntity(
        id = o.id(), name = o.str("name"), type = o.str("type"), initialBalanceCents = o.cents("initial_balance"), colorHex = o.str("color_hex"),
        createdAt = o.date("created_at"), isArchived = o.bool("is_archived"), isExcludedFromTotal = o.bool("is_excluded_from_total"),
    )

    fun transaction(o: JsonObject) = TransactionEntity(
        id = o.id(), accountId = o.idOrNull("account_id"), name = o.str("name"), amountCents = o.cents("amount"), type = o.str("type"),
        category = o.str("category"), categoryIcon = o.str("category_icon"), date = o.date("date"), isDone = o.bool("is_done"),
        isFixed = o.bool("is_fixed"), isTransfer = o.bool("is_transfer"), transferGroupId = o.strOr("transfer_group_id", "").uppercase(),
        notes = o.strOr("notes", ""), recurringFrequency = o.strOr("recurring_frequency", ""), templateId = o.strOr("template_id", "").uppercase(),
        createdAt = o.date("created_at"),
    )

    fun budget(o: JsonObject) = BudgetEntity(
        id = o.id(), accountId = o.idOrNull("account_id"), category = o.str("category"), categoryIcon = o.str("category_icon"),
        monthlyLimitCents = o.cents("monthly_limit"), month = o.int("month"), year = o.int("year"), createdAt = o.date("created_at"),
    )

    fun goal(o: JsonObject) = GoalEntity(
        id = o.id(), name = o.str("name"), emoji = o.str("emoji"), targetCents = o.cents("target_amount"), currentCents = o.cents("current_amount"),
        deadline = o.dateOrNull("deadline"), isCompleted = o.bool("is_completed"), createdAt = o.date("created_at"),
    )

    fun rule(o: JsonObject): RecurringRuleEntity {
        // `exceptions` è una stringa JSON; se la colonna fosse jsonb arriverebbe come oggetto
        val exceptions = when (val e = o.el("exceptions")) {
            null -> "{}"
            is JsonPrimitive -> e.content
            else -> e.toString()
        }
        return RecurringRuleEntity(
            id = o.id(), name = o.str("name"), type = o.str("type"), category = o.str("category"), categoryIcon = o.str("category_icon"),
            notes = o.strOr("notes", ""), amountCents = o.cents("amount"), isFixed = o.bool("is_fixed"), accountId = o.idOrNull("account_id"),
            frequency = o.str("frequency"), startDate = o.date("start_date"), endDate = o.dateOrNull("end_date"), exceptionsJson = exceptions,
            materializedThrough = o.dateOrNull("materialized_through"), createdAt = o.date("created_at"),
        )
    }
}
