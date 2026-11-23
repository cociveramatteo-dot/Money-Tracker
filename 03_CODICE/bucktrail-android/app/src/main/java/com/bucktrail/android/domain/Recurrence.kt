package com.bucktrail.android.domain

import kotlinx.serialization.ExperimentalSerializationApi
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonArray
import kotlinx.serialization.json.JsonElement
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.JsonUnquotedLiteral
import kotlinx.serialization.json.booleanOrNull
import java.math.BigDecimal
import java.security.MessageDigest
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.time.temporal.ChronoUnit
import java.util.UUID

/** Eccezione di una singola occorrenza (formato JSON identico a iOS `RecurrenceException`). */
data class RecurrenceException(
    val skip: Boolean = false,
    val amount: String? = null,
    val date: Instant? = null,
    val name: String? = null,
    val notes: String? = null,
    val category: String? = null,
    val categoryIcon: String? = null,
    val type: String? = null,
    val isFixed: Boolean? = null,
    val accountId: UUID? = null,
    val overridesAccount: Boolean? = null,
)

/**
 * Codec di `exceptionsJSON`: chiavi ordinate, `skip` SEMPRE presente, `date` = secondi (Double) dal 2001-01-01Z,
 * `amount` stringa, `accountId` UUID MAIUSCOLO. Decodifica fallita (anche di una sola voce) = mappa vuota, come iOS.
 */
object RecurrenceExceptionCodec {
    private const val REFERENCE_EPOCH = 978_307_200L

    fun decode(json: String): Map<String, RecurrenceException> = try {
        val root = Json.parseToJsonElement(json) as? JsonObject ?: return emptyMap()
        root.mapValues { (_, v) -> decodeOne(v as? JsonObject ?: return emptyMap()) ?: return emptyMap() }
    } catch (_: Exception) {
        emptyMap()
    }

    private fun str(o: JsonObject, key: String): Result<String?> {
        val v = o[key] ?: return Result.success(null)
        if (v is JsonNull) return Result.success(null)
        val p = v as? JsonPrimitive ?: return Result.failure(IllegalArgumentException(key))
        return if (p.isString) Result.success(p.content) else Result.failure(IllegalArgumentException(key))
    }

    private fun bool(o: JsonObject, key: String): Result<Boolean?> {
        val v = o[key] ?: return Result.success(null)
        if (v is JsonNull) return Result.success(null)
        val p = v as? JsonPrimitive ?: return Result.failure(IllegalArgumentException(key))
        val b = if (p.isString) null else p.booleanOrNull
        return if (b != null) Result.success(b) else Result.failure(IllegalArgumentException(key))
    }

    private fun decodeOne(o: JsonObject): RecurrenceException? = try {
        val skip = bool(o, "skip").getOrThrow() ?: return null // `skip` obbligatorio (Codable iOS)
        val dateEl = o["date"]
        val date = if (dateEl == null || dateEl is JsonNull) null else {
            val p = dateEl as? JsonPrimitive ?: return null
            if (p.isString) return null
            val seconds = BigDecimal(p.content)
            val whole = seconds.setScale(0, java.math.RoundingMode.FLOOR)
            val nanos = seconds.subtract(whole).movePointRight(9).toLong()
            Instant.ofEpochSecond(REFERENCE_EPOCH + whole.toLong(), nanos)
        }
        RecurrenceException(
            skip = skip, amount = str(o, "amount").getOrThrow(), date = date, name = str(o, "name").getOrThrow(),
            notes = str(o, "notes").getOrThrow(), category = str(o, "category").getOrThrow(),
            categoryIcon = str(o, "categoryIcon").getOrThrow(), type = str(o, "type").getOrThrow(),
            isFixed = bool(o, "isFixed").getOrThrow(),
            accountId = str(o, "accountId").getOrThrow()?.let { UUID.fromString(it) },
            overridesAccount = bool(o, "overridesAccount").getOrThrow(),
        )
    } catch (_: Exception) {
        null
    }

    @OptIn(ExperimentalSerializationApi::class)
    fun encode(exceptions: Map<String, RecurrenceException>): String {
        val out = java.util.TreeMap<String, JsonElement>()
        for ((key, e) in exceptions) {
            val f = java.util.TreeMap<String, JsonElement>()
            f["skip"] = JsonPrimitive(e.skip)
            e.amount?.let { f["amount"] = JsonPrimitive(it) }
            e.date?.let {
                val secs = BigDecimal(it.epochSecond - REFERENCE_EPOCH).add(BigDecimal.valueOf(it.nano.toLong(), 9))
                f["date"] = JsonUnquotedLiteral(secs.stripTrailingZeros().toPlainString())
            }
            e.name?.let { f["name"] = JsonPrimitive(it) }
            e.notes?.let { f["notes"] = JsonPrimitive(it) }
            e.category?.let { f["category"] = JsonPrimitive(it) }
            e.categoryIcon?.let { f["categoryIcon"] = JsonPrimitive(it) }
            e.type?.let { f["type"] = JsonPrimitive(it) }
            e.isFixed?.let { f["isFixed"] = JsonPrimitive(it) }
            e.accountId?.let { f["accountId"] = JsonPrimitive(it.toString().uppercase()) }
            e.overridesAccount?.let { f["overridesAccount"] = JsonPrimitive(it) }
            out[key] = JsonObject(f)
        }
        return JsonObject(out).toString()
    }
}

data class RuleSnapshot(
    val id: UUID, val name: String, val amount: BigDecimal, val type: String, val category: String,
    val categoryIcon: String, val notes: String = "", val isFixed: Boolean = false, val accountId: UUID? = null,
    val frequency: String, val startDate: Instant, val endDate: Instant? = null,
    val exceptions: Map<String, RecurrenceException> = emptyMap(),
)

data class Occurrence(
    val ruleId: UUID, val key: String, val originalDate: Instant, val date: Instant, val amount: BigDecimal,
    val name: String, val category: String, val categoryIcon: String, val type: String, val accountId: UUID?,
    val isFixed: Boolean, val notes: String, val isOverridden: Boolean,
) {
    val id: UUID get() = RecurrenceCalculator.occurrenceId(ruleId, key)
}

/** Calcolo puro delle occorrenze (calendario Gregoriano nel fuso dato, tutte le date alle 12:00 locali). */
class RecurrenceCalculator(val zone: ZoneId) {
    private val amountPattern = Regex("^[+-]?(?:[0-9]+(?:\\.[0-9]*)?|\\.[0-9]+)$")

    fun day(date: Instant): LocalDate = date.atZone(zone).toLocalDate()
    private fun instant(date: LocalDate, hour: Int = 12): Instant = date.atTime(hour, 0).atZone(zone).toInstant()
    fun noon(date: Instant): Instant = instant(day(date))
    fun monthStart(date: Instant): Instant = instant(day(date).withDayOfMonth(1), 0)
    fun addMonths(date: Instant, months: Long): Instant {
        val z = date.atZone(zone)
        return z.plusMonths(months).toInstant()
    }
    fun addDays(date: Instant, days: Long): Instant = date.atZone(zone).plusDays(days).toInstant()
    fun key(date: Instant): String = day(date).toString() // yyyy-MM-dd

    fun anchorForSeriesEdit(rule: RuleSnapshot, originalDate: Instant, date: Instant): Instant {
        if (day(date) == day(originalDate)) return rule.startDate
        if (rule.frequency == "settimanale") {
            val days = ChronoUnit.DAYS.between(day(originalDate), day(date))
            return addDays(noon(rule.startDate), days)
        }
        val months = ChronoUnit.MONTHS.between(YearMonth.from(day(originalDate)), YearMonth.from(day(date)))
        val month = YearMonth.from(day(rule.startDate)).plusMonths(months)
        val dayOfMonth = minOf(day(date).dayOfMonth, month.lengthOfMonth())
        return instant(month.atDay(dayOfMonth))
    }

    /** Intervallo semiaperto [start, end); `endDate` della regola inclusivo (giorno civile). */
    fun occurrences(rule: RuleSnapshot, intervalStart: Instant, intervalEnd: Instant): List<Occurrence> {
        if (!intervalEnd.isAfter(intervalStart)) return emptyList()
        val start = noon(rule.startDate)
        val end = rule.endDate?.let(::noon)
        val startDay = day(start)
        val firstMonthDay = day(intervalStart).withDayOfMonth(1)
        val firstMonth = instant(firstMonthDay, 0)
        val lastMonth = instant(YearMonth.from(day(intervalEnd.minusSeconds(1))).plusMonths(1).atDay(1), 0)
        val dates = ArrayList<Instant>()
        when (rule.frequency) {
            "settimanale" -> {
                val days = ChronoUnit.DAYS.between(startDay, firstMonthDay)
                var k = maxOf(0L, days / 7)
                while (true) {
                    val d = instant(startDay.plusDays(k * 7))
                    if (!d.isBefore(lastMonth)) break
                    if (!d.isBefore(firstMonth)) dates.add(d)
                    k++
                }
            }
            "mensile", "annuale" -> {
                val anchorMonth = YearMonth.from(startDay)
                val diff = ChronoUnit.MONTHS.between(anchorMonth, YearMonth.from(firstMonthDay))
                val step = if (rule.frequency == "mensile") 1L else 12L
                var n = maxOf(0L, diff / step)
                while (true) {
                    val month = anchorMonth.plusMonths(n * step)
                    if (!instant(month.atDay(1), 0).isBefore(lastMonth)) break
                    val d = instant(month.atDay(minOf(startDay.dayOfMonth, month.lengthOfMonth())))
                    if (!d.isBefore(firstMonth)) dates.add(d)
                    n++
                }
            }
            else -> return emptyList()
        }
        return dates.mapNotNull { original ->
            if (original.isBefore(start) || (end != null && original.isAfter(end))) return@mapNotNull null
            val key = key(original)
            val ex = rule.exceptions[key]
            if (ex?.skip == true) return@mapNotNull null
            val override = ex?.date?.let(::noon)
            val date = override?.takeIf { YearMonth.from(day(it)) == YearMonth.from(day(original)) } ?: original
            if (date.isBefore(intervalStart) || !date.isBefore(intervalEnd)) return@mapNotNull null
            val amount = ex?.amount?.takeIf { amountPattern.matches(it) }?.let { BigDecimal(it) } ?: rule.amount
            Occurrence(
                ruleId = rule.id, key = key, originalDate = original, date = date, amount = amount,
                name = ex?.name ?: rule.name, category = ex?.category ?: rule.category,
                categoryIcon = ex?.categoryIcon ?: rule.categoryIcon, type = ex?.type ?: rule.type,
                accountId = if (ex?.overridesAccount == true) ex.accountId else rule.accountId,
                isFixed = ex?.isFixed ?: rule.isFixed, notes = ex?.notes ?: rule.notes, isOverridden = ex != null,
            )
        }.sortedWith(compareBy<Occurrence> { it.date }.thenBy { it.key })
    }

    companion object {
        /** UUIDv5 (RFC 9562): SHA-1(16 byte della regola || UTF-8 della chiave "yyyy-MM-dd"). Deve coincidere con iOS. */
        fun occurrenceId(ruleId: UUID, key: String): UUID {
            val ns = java.nio.ByteBuffer.allocate(16).putLong(ruleId.mostSignificantBits).putLong(ruleId.leastSignificantBits).array()
            val digest = MessageDigest.getInstance("SHA-1").digest(ns + key.toByteArray(Charsets.UTF_8)).copyOf(16)
            digest[6] = ((digest[6].toInt() and 0x0f) or 0x50).toByte()
            digest[8] = ((digest[8].toInt() and 0x3f) or 0x80).toByte()
            val bb = java.nio.ByteBuffer.wrap(digest)
            return UUID(bb.long, bb.long)
        }
    }
}
