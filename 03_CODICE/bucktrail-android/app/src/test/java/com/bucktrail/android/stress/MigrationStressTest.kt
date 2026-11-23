package com.bucktrail.android.stress

import com.bucktrail.android.data.Migration2To3
import com.bucktrail.android.data.MigrationSql
import org.junit.Assert.assertEquals
import org.junit.Test
import java.sql.Connection
import java.sql.DriverManager
import java.time.LocalDate
import java.time.ZoneId
import kotlin.random.Random

/** Migrazione v2 -> v3 con 20.000 movimenti reali in SQLite (JDBC), importi estremi e dati corrotti: nessuna perdita, nessun crash. */
class MigrationStressTest {
    private class Jdbc(val c: Connection) : MigrationSql {
        override fun exec(sql: String, args: List<Any?>) { c.prepareStatement(sql).use { st -> args.forEachIndexed { i, a -> st.setObject(i + 1, a) }; st.execute() } }
        override fun rows(sql: String): List<Map<String, Any?>> = c.createStatement().use { st -> st.executeQuery(sql).use { rs ->
            val md = rs.metaData; buildList { while (rs.next()) add((1..md.columnCount).associate { md.getColumnName(it) to rs.getObject(it) }) } } }
    }

    @Test fun twentyThousandMovementsKeepCountSumsAndSigns() {
        val r = Random(11); val today = LocalDate.of(2026, 11, 23); val zone = ZoneId.of("Europe/Rome")
        DriverManager.getConnection("jdbc:sqlite::memory:").use { conn ->
            val sql = Jdbc(conn)
            sql.exec("CREATE TABLE accounts (id TEXT NOT NULL, name TEXT NOT NULL, openingCents INTEGER NOT NULL, PRIMARY KEY(id))")
            sql.exec("CREATE TABLE movements (id TEXT NOT NULL, accountId TEXT NOT NULL, title TEXT NOT NULL, cents INTEGER NOT NULL, recordedAt INTEGER NOT NULL, entryDay INTEGER, planned INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(id))")
            repeat(5) { sql.exec("INSERT INTO accounts VALUES (?,?,?)", listOf("a$it", "Conto \uD83D\uDE00 $it", r.nextLong(-99_999_999_999L, 99_999_999_999L))) }
            var signed = 0L; var abs = 0L
            conn.autoCommit = false
            repeat(20_000) {
                val cents = listOf(0L, 1L, -1L, 99_999_999_999L, -99_999_999_999L, r.nextLong(-1_000_000, 1_000_000))[r.nextInt(6)]
                signed += cents; abs += kotlin.math.abs(cents)
                val entryDay: Long? = when (r.nextInt(6)) { 0 -> null; 1 -> 0L; 2 -> 2_932_896L; 3 -> Long.MAX_VALUE; else -> today.toEpochDay() + r.nextLong(-900, 900) } // 2_932_896 = 9999-12-31
                sql.exec("INSERT INTO movements VALUES (?,?,?,?,?,?,?)", listOf("m$it", "a${it % 5}", "Mov $it \u00e8", cents, r.nextLong(0, 4_102_444_800_000L), entryDay, r.nextInt(2).toLong()))
            }
            conn.commit(); conn.autoCommit = true
            Migration2To3.run(sql, zone, today, now = 1)
            val row = sql.rows("SELECT COUNT(*) AS n, SUM(CASE WHEN type='Entrata' THEN amountCents ELSE -amountCents END) AS s, SUM(amountCents) AS a FROM transactions")[0]
            assertEquals(20_000, (row["n"] as Number).toInt()); assertEquals(signed, (row["s"] as Number).toLong()); assertEquals(abs, (row["a"] as Number).toLong())
            assertEquals(5, (sql.rows("SELECT COUNT(*) AS n FROM accounts")[0]["n"] as Number).toInt())
        }
    }
}
