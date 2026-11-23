package com.bucktrail.android.domain

import org.junit.Assert.assertEquals
import org.junit.Assert.assertTrue
import org.junit.Test
import java.math.BigDecimal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/** Vettori da RecurrenceCalculatorTests.swift e StrictRecurrenceAmountTests.swift (Europe/Rome). */
class RecurrenceCalculatorTest {
    private val zone = ZoneId.of("Europe/Rome")
    private val calc = RecurrenceCalculator(zone)
    private fun date(y: Int, m: Int, d: Int, h: Int = 12): Instant = LocalDate.of(y, m, d).atTime(h, 0).atZone(zone).toInstant()
    private fun rule(frequency: String = "mensile", start: Instant, amount: String = "0.2") = RuleSnapshot(
        UUID.randomUUID(), "Affitto", BigDecimal(amount), "Uscita", "Casa", "house", frequency = frequency, startDate = start,
    )
    private fun keys(r: RuleSnapshot, from: Instant, to: Instant) = calc.occurrences(r, from, to).map { it.key }

    @Test fun monthlyClampingReturnsToTheAnchor() {
        for (year in listOf(2027, 2028)) {
            assertEquals(
                listOf("$year-01-31", "$year-02-${if (year == 2028) 29 else 28}", "$year-03-31", "$year-04-30"),
                keys(rule(start = date(year, 1, 31)), date(year, 1, 1), date(year, 5, 1)),
            )
        }
    }

    @Test fun leapDayReturnsInLeapYears() {
        assertEquals(listOf("2024-02-29", "2025-02-28", "2026-02-28", "2027-02-28", "2028-02-29"),
            keys(rule("annuale", date(2024, 2, 29)), date(2024, 1, 1), date(2029, 1, 1)))
    }

    @Test fun weeklyStaysAtNoonOverBothDstChanges() {
        for (month in listOf(3, 10)) {
            val r = calc.occurrences(rule("settimanale", date(2026, month, 1, 1)), date(2026, month, 1, 0), date(2026, month + 1, 1, 0))
            assertEquals(5, r.size)
            r.forEach { assertEquals(12, it.date.atZone(zone).hour) }
            r.zipWithNext().forEach { (a, b) ->
                assertEquals(7L, java.time.temporal.ChronoUnit.DAYS.between(a.date.atZone(zone).toLocalDate(), b.date.atZone(zone).toLocalDate()))
            }
        }
    }

    @Test fun midMonthStartInclusiveEndAndHalfOpenInterval() {
        var r = rule("settimanale", date(2026, 3, 15, 0)).copy(endDate = date(2026, 3, 29, 0))
        val from = date(2026, 3, 1, 0); val to = date(2026, 4, 1, 0)
        assertEquals(listOf("2026-03-15", "2026-03-22", "2026-03-29"), keys(r, from, to))
        assertEquals(1, calc.occurrences(r, date(2026, 3, 15), date(2026, 3, 22)).size)
        r = r.copy(endDate = date(2026, 3, 14))
        assertTrue(calc.occurrences(r, from, to).isEmpty())
    }

    @Test fun intervalEndingAtMidnightOfTheFirstExcludesTheEndMonth() {
        val from = date(2026, 3, 1, 0); val to = date(2026, 4, 1, 0)
        assertEquals(listOf("2026-03-01", "2026-03-08", "2026-03-15", "2026-03-22", "2026-03-29"), keys(rule("settimanale", date(2026, 3, 1, 0)), from, to))
        assertEquals(listOf("2026-03-01"), keys(rule(start = date(2026, 1, 1, 0)), from, to))
    }

    @Test fun normalEditorPreservesPositionAndClampedAnchors() {
        val monthly = rule(start = date(2026, 1, 31))
        assertEquals(date(2026, 1, 31), calc.anchorForSeriesEdit(monthly, date(2026, 2, 28), date(2026, 2, 28)))
        assertEquals(date(2026, 1, 27), calc.anchorForSeriesEdit(monthly, date(2026, 2, 28), date(2026, 2, 27)))
        assertEquals(date(2026, 2, 15), calc.anchorForSeriesEdit(monthly, date(2026, 2, 28), date(2026, 3, 15)))
        val weekly = rule("settimanale", date(2026, 3, 1))
        assertEquals(date(2026, 3, 4), calc.anchorForSeriesEdit(weekly, date(2026, 3, 15), date(2026, 3, 18)))
        val annual = rule("annuale", date(2024, 2, 29))
        assertEquals(date(2024, 2, 29), calc.anchorForSeriesEdit(annual, date(2025, 2, 28), date(2025, 2, 28)))
        assertEquals(date(2024, 2, 27), calc.anchorForSeriesEdit(annual, date(2025, 2, 28), date(2025, 2, 27)))
    }

    @Test fun skipOverridesExactDecimalAndDefensiveCodec() {
        val ex = mapOf("2026-01-15" to RecurrenceException(skip = true),
            "2026-02-15" to RecurrenceException(amount = "0.1", date = date(2026, 2, 20), name = "Altro", notes = "Nota"))
        val r = rule(start = date(2026, 1, 15)).copy(exceptions = ex)
        val json = RecurrenceExceptionCodec.encode(ex)
        assertEquals(ex, RecurrenceExceptionCodec.decode(json))
        assertTrue(RecurrenceExceptionCodec.decode("broken").isEmpty())
        assertTrue(RecurrenceExceptionCodec.decode("[]").isEmpty())
        assertTrue(RecurrenceExceptionCodec.decode("{\"x\":{\"skip\":true,\"amount\":3}}").isEmpty())
        val result = calc.occurrences(r, date(2026, 1, 1), date(2026, 4, 1))
        assertEquals(2, result.size)
        assertEquals(date(2026, 2, 20), result[0].date); assertEquals(date(2026, 2, 15), result[0].originalDate)
        assertEquals("2026-02-15", result[0].key)
        assertTrue(result[0].name == "Altro" && result[0].notes == "Nota" && result[0].isOverridden)
        assertEquals(0, BigDecimal("0.3").compareTo(result.fold(BigDecimal.ZERO) { a, o -> a + o.amount }))
        assertTrue(!result[1].isOverridden)
        assertEquals(1, calc.occurrences(r, date(2026, 2, 19), date(2026, 2, 21)).size)
    }

    @Test fun codecFormatMatchesSwiftCodable() {
        // `skip` sempre presente, chiavi ordinate, `date` numerico in secondi dal 2001-01-01Z, accountId MAIUSCOLO.
        val id = UUID.fromString("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
        val json = RecurrenceExceptionCodec.encode(mapOf(
            "2026-01-01" to RecurrenceException(amount = "112.40", date = Instant.parse("2026-01-01T12:00:00Z"), accountId = id, overridesAccount = true),
            "2026-02-01" to RecurrenceException(skip = true)))
        assertEquals(
            "{\"2026-01-01\":{\"accountId\":\"6BA7B810-9DAD-11D1-80B4-00C04FD430C8\",\"amount\":\"112.40\",\"date\":788961600,\"overridesAccount\":true,\"skip\":false}," +
                "\"2026-02-01\":{\"skip\":true}}", json)
        assertEquals(Instant.parse("2026-01-01T12:00:00Z"), RecurrenceExceptionCodec.decode(json)["2026-01-01"]!!.date)
        assertTrue(RecurrenceExceptionCodec.decode("{\"2026-01-01\":{\"amount\":\"1\"}}").isEmpty()) // senza `skip` iOS non decodifica
    }

    @Test fun skippingAllFiveWeeksOfAMonth() {
        var r = rule("settimanale", date(2026, 3, 1))
        val from = date(2026, 3, 1); val to = date(2026, 4, 1)
        r = r.copy(exceptions = calc.occurrences(r, from, to).associate { it.key to RecurrenceException(skip = true) })
        assertEquals(5, r.exceptions.size)
        assertTrue(calc.occurrences(r, from, to).isEmpty())
        assertEquals(4, calc.occurrences(r, date(2026, 4, 1), date(2026, 5, 1)).size)
    }

    @Test fun noTwelveMonthHorizon() {
        for (f in listOf("mensile", "settimanale", "annuale")) {
            val r = rule(f, date(2026, 1, 15))
            val k = keys(r, date(2027, 1, 1), date(2027, 3, 1))
            assertTrue(f, k.isNotEmpty())
            if (f == "mensile") assertEquals(listOf("2027-01-15", "2027-02-15"), k)
        }
    }

    @Test fun uuidV5MatchesTheRfcVectorAndIsDeterministic() {
        val ns = UUID.fromString("6ba7b810-9dad-11d1-80b4-00c04fd430c8")
        assertEquals("21f7f8de-8051-5b89-8680-0195ef798b6a", RecurrenceCalculator.occurrenceId(ns, "www.widgets.com").toString())
        val first = RecurrenceCalculator.occurrenceId(ns, "2026-01-01")
        assertEquals(first, RecurrenceCalculator.occurrenceId(ns, "2026-01-01"))
        assertTrue(first != RecurrenceCalculator.occurrenceId(ns, "2026-01-02"))
        assertTrue(first != RecurrenceCalculator.occurrenceId(UUID.randomUUID(), "2026-01-01"))
        assertEquals(5, first.version()); assertEquals(2, first.variant())
    }

    @Test fun invalidFrequencyAndMalformedOverridesAreHarmless() {
        var r = rule(start = date(2026, 1, 15)).copy(exceptions = mapOf("2026-01-15" to RecurrenceException(amount = "invalid", date = date(2026, 2, 1))))
        val from = date(2026, 1, 1); val to = date(2026, 2, 1)
        val result = calc.occurrences(r, from, to)
        assertEquals(date(2026, 1, 15), result.first().date)
        assertEquals(r.amount, result.first().amount)
        r = r.copy(frequency = "invalid")
        assertTrue(calc.occurrences(r, from, to).isEmpty())
    }

    @Test fun overrideAmountsAreValidatedWholeAndKeepExactPrecision() {
        val utc = RecurrenceCalculator(java.time.ZoneOffset.UTC)
        val d = Instant.parse("2026-01-01T12:00:00Z")
        for (text in listOf("12abc", "1.234,56", "", "12\n", "0.1234567890123456789", "-5.5")) {
            val r = RuleSnapshot(UUID.randomUUID(), "Test", BigDecimal(7), "Uscita", "Casa", "house", frequency = "mensile", startDate = d,
                exceptions = mapOf("2026-01-01" to RecurrenceException(amount = text)))
            val o = utc.occurrences(r, Instant.parse("2026-01-01T00:00:00Z"), Instant.parse("2026-02-01T00:00:00Z")).first()
            val expected = if (text in listOf("0.1234567890123456789", "-5.5")) BigDecimal(text) else r.amount
            assertEquals(text, 0, expected.compareTo(o.amount))
        }
    }
}
