package com.bucktrail.android.sync

import com.bucktrail.android.domain.RecurrenceExceptionCodec
import kotlinx.serialization.json.Json
import kotlinx.serialization.json.JsonNull
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonObject
import kotlinx.serialization.json.jsonPrimitive
import org.junit.Assert.assertEquals
import org.junit.Assert.assertFalse
import org.junit.Assert.assertNull
import org.junit.Assert.assertTrue
import org.junit.Test

/** Payload nel formato esatto scritto/letto da iOS (supabase-swift + PostgREST). Nessuna rete. */
class SyncMapperTest {
    // Riga come la restituisce PostgREST per un movimento creato da iOS (uuid minuscoli, timestamptz con microsecondi e +00:00, numeric come numero).
    private val iosTransaction = """{"id":"3f2b8c10-aaaa-4bbb-8ccc-000000000001","user_id":"11111111-2222-3333-4444-555555555555","account_id":"aaaaaaaa-0000-4000-8000-000000000001",
        "name":"Spesa","amount":24.5,"type":"Uscita","category":"Cibo","category_icon":"fork.knife","date":"2026-11-20T10:30:00+00:00","is_done":true,"is_fixed":false,
        "is_transfer":false,"transfer_group_id":"","notes":"","recurring_frequency":"","template_id":"6BA7B810-9DAD-11D1-80B4-00C04FD430C8","created_at":"2026-11-20T09:00:00.123456+00:00"}"""

    private val iosExceptions = "{\"2026-01-01\":{\"accountId\":\"6BA7B810-9DAD-11D1-80B4-00C04FD430C8\",\"amount\":\"112.40\",\"date\":788961600,\"overridesAccount\":true,\"skip\":false},\"2026-02-01\":{\"skip\":true}}"

    @Test fun decodesAnIosTransactionRow() {
        val t = SyncMapper.transaction(Json.parseToJsonElement(iosTransaction).jsonObject)
        assertEquals("3f2b8c10-aaaa-4bbb-8ccc-000000000001", t.id)
        assertEquals(2450L, t.amountCents)
        assertEquals("Uscita", t.type)
        assertEquals(java.time.Instant.parse("2026-11-20T10:30:00Z").toEpochMilli(), t.date)
        assertEquals(java.time.Instant.parse("2026-11-20T09:00:00.123Z").toEpochMilli(), t.createdAt) // i microsecondi si troncano al millisecondo
        assertEquals("6BA7B810-9DAD-11D1-80B4-00C04FD430C8", t.templateId)
    }

    @Test fun encodesTransactionLikeIosCodable() {
        val t = SyncMapper.transaction(Json.parseToJsonElement(iosTransaction).jsonObject).copy(transferGroupId = "6ba7b810-9dad-11d1-80b4-00c04fd430c8", templateId = "")
        val row = SyncMapper.transactionRow(t, "11111111-2222-3333-4444-555555555555")
        // uuid MAIUSCOLI (come `uuidString`), anche user_id e account_id
        assertEquals("3F2B8C10-AAAA-4BBB-8CCC-000000000001", row["id"]!!.jsonPrimitive.content)
        assertEquals("11111111-2222-3333-4444-555555555555", row["user_id"]!!.jsonPrimitive.content)
        assertEquals("AAAAAAAA-0000-4000-8000-000000000001", row["account_id"]!!.jsonPrimitive.content)
        // transfer_group_id MAIUSCOLO
        assertEquals("6BA7B810-9DAD-11D1-80B4-00C04FD430C8", row["transfer_group_id"]!!.jsonPrimitive.content)
        // importo = numero JSON, non stringa; due decimali esatti
        assertFalse(row["amount"]!!.jsonPrimitive.isString)
        assertEquals("24.50", row["amount"]!!.jsonPrimitive.content)
        // date ISO-8601 UTC con millisecondi
        assertEquals("2026-11-20T10:30:00.000Z", row["date"]!!.jsonPrimitive.content)
        // tutte le 17 chiavi, sempre (i nil diventano NULL)
        assertEquals(17, row.size)
        assertEquals(
            setOf("id", "user_id", "account_id", "name", "amount", "type", "category", "category_icon", "date", "is_done", "is_fixed", "is_transfer", "transfer_group_id", "notes", "recurring_frequency", "template_id", "created_at"),
            row.keys,
        )
    }

    @Test fun nullAccountIsWrittenAsNull() {
        val row = SyncMapper.transactionRow(tx(T1, null), USER)
        assertEquals(JsonNull, row["account_id"])
        assertEquals(JsonNull, SyncMapper.goalRow(goal("g").copy(deadline = null), USER)["deadline"])
    }

    @Test fun exceptionsStringSurvivesTheRoundTripBitForBit() {
        val rowJson = """{"id":"cccccccc-0000-4000-8000-000000000001","user_id":"$USER","name":"Bolletta","type":"Uscita","category":"Casa","category_icon":"bolt.fill","notes":"",
            "amount":86,"is_fixed":true,"account_id":null,"frequency":"Mensile","start_date":"2026-05-23T10:00:00+00:00","end_date":null,"exceptions":${JsonPrimitive(iosExceptions)},
            "materialized_through":"2026-11-01T00:00:00+00:00","created_at":"2026-05-23T10:00:00+00:00"}"""
        val rule = SyncMapper.rule(Json.parseToJsonElement(rowJson).jsonObject)
        assertEquals(iosExceptions, rule.exceptionsJson)
        assertEquals(8600L, rule.amountCents)
        assertNull(rule.accountId); assertNull(rule.endDate)
        val back = SyncMapper.ruleRow(rule, USER)
        // `exceptions` viaggia come STRINGA JSON, identica
        assertTrue(back["exceptions"]!!.jsonPrimitive.isString)
        assertEquals(iosExceptions, back["exceptions"]!!.jsonPrimitive.content)
        assertEquals(JsonNull, back["end_date"]); assertEquals(JsonNull, back["account_id"])
        assertEquals(16, back.size)
        // e iOS (Codable) la decodificherebbe: `skip` presente, `date` numerica, accountId maiuscolo
        val decoded = RecurrenceExceptionCodec.decode(back["exceptions"]!!.jsonPrimitive.content)
        assertEquals(2, decoded.size)
        assertTrue(decoded["2026-02-01"]!!.skip)
        assertEquals("112.40", decoded["2026-01-01"]!!.amount)
    }

    @Test fun exceptionsWrittenByAndroidKeepTheSkipKeyAndSecondsSince2001() {
        val ex = mapOf("2026-02-01" to com.bucktrail.android.domain.RecurrenceException(skip = false, date = java.time.Instant.parse("2026-02-05T12:00:00Z"), amount = "9.90"))
        val json = RecurrenceExceptionCodec.encode(ex)
        val o = Json.parseToJsonElement(json).jsonObject["2026-02-01"]!!.jsonObject
        assertEquals("false", o["skip"]!!.jsonPrimitive.content)
        assertFalse(o["date"]!!.jsonPrimitive.isString)
        assertEquals(java.time.Instant.parse("2026-02-05T12:00:00Z").epochSecond - 978_307_200L, o["date"]!!.jsonPrimitive.content.toLong())
        val rule = rule(R1, A1, exceptions = json)
        assertEquals(json, SyncMapper.rule(SyncMapper.ruleRow(rule, USER)).exceptionsJson)
    }

    @Test fun jsonbExceptionsObjectIsTolerated() {
        val o = Json.parseToJsonElement("""{"id":"$R1","user_id":"$USER","name":"x","type":"Uscita","category":"c","category_icon":"i","notes":"","amount":1,"is_fixed":false,
            "frequency":"Mensile","start_date":"2026-05-23T10:00:00Z","exceptions":{"2026-02-01":{"skip":true}},"created_at":"2026-05-23T10:00:00Z"}""").jsonObject
        assertEquals("{\"2026-02-01\":{\"skip\":true}}", SyncMapper.rule(o).exceptionsJson)
    }

    @Test fun everyEntityRoundTripsThroughItsRow() {
        val a = account(A1).copy(isArchived = true, isExcludedFromTotal = true, colorHex = "1F7A4D")
        assertEquals(a, SyncMapper.account(SyncMapper.accountRow(a, USER)))
        val t = tx(T1, A1, 1_234_56, date = 1_763_000_123_000).copy(isDone = false, isFixed = true, templateId = "6BA7B810-9DAD-11D1-80B4-00C04FD430C8", recurringFrequency = "")
        assertEquals(t, SyncMapper.transaction(SyncMapper.transactionRow(t, USER)))
        val b = budget("dddddddd-0000-4000-8000-000000000001", A1)
        assertEquals(b, SyncMapper.budget(SyncMapper.budgetRow(b, USER)))
        val g = goal("eeeeeeee-0000-4000-8000-000000000001")
        assertEquals(g, SyncMapper.goal(SyncMapper.goalRow(g, USER)))
        val r = rule(R1, A1, through = 1_762_000_000_000)
        assertEquals(r, SyncMapper.rule(SyncMapper.ruleRow(r, USER)))
    }

    @Test fun postgresDateFormatsAreAccepted() {
        val expected = java.time.Instant.parse("2026-11-23T10:30:00Z").toEpochMilli()
        assertEquals(expected, SyncMapper.parseDate("2026-11-23T10:30:00Z"))
        assertEquals(expected, SyncMapper.parseDate("2026-11-23T10:30:00.000Z"))
        assertEquals(expected, SyncMapper.parseDate("2026-11-23T10:30:00+00:00"))
        assertEquals(expected, SyncMapper.parseDate("2026-11-23T12:30:00+02:00"))
        assertEquals(expected, SyncMapper.parseDate("2026-11-23 10:30:00+00"))
        assertEquals(expected + 123, SyncMapper.parseDate("2026-11-23T10:30:00.123456+00:00"))
    }

    @Test fun amountsKeepExactCentsAndOddDecimalsRound() {
        fun cents(text: String) = SyncMapper.transaction(Json.parseToJsonElement(iosTransaction.replace("24.5", text)).jsonObject).amountCents
        assertEquals(1L, cents("0.01")); assertEquals(11240L, cents("112.4")); assertEquals(1_000_000_000_00L, cents("1000000000"))
        assertEquals(1001L, cents("10.005")) // HALF_UP, come `Decimal.parseAmount`
        assertEquals(-250L, cents("-2.5"))
    }

    @Test(expected = SyncFormatException::class) fun malformedRowFailsLoudly() {
        SyncMapper.transaction(Json.parseToJsonElement(iosTransaction.replace("\"amount\":24.5,", "\"amount\":\"abc\",")).jsonObject)
    }

    @Test fun lowercaseTemplateIdFromAnOlderWriterIsNormalisedToUppercase() {
        val t = SyncMapper.transaction(Json.parseToJsonElement(iosTransaction.replace("6BA7B810-9DAD-11D1-80B4-00C04FD430C8", "6ba7b810-9dad-11d1-80b4-00c04fd430c8")).jsonObject)
        assertEquals("6BA7B810-9DAD-11D1-80B4-00C04FD430C8", t.templateId)
    }

}
