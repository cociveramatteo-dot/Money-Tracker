package com.bucktrail.android.data

import org.junit.Assert.assertEquals
import org.junit.Test
import java.sql.Connection
import java.sql.DriverManager
import java.time.LocalDate
import java.time.ZoneId

/** Prova la migrazione v2 -> v3 con SQLite reale (JDBC) sullo schema `2.json`: nessun dato perso. */
class Migration2To3Test {
    private val zone = ZoneId.of("Europe/Rome")
    private val today = LocalDate.of(2026, 11, 23)

    private class Jdbc(val c: Connection) : MigrationSql {
        override fun exec(sql: String, args: List<Any?>) {
            c.prepareStatement(sql).use { st -> args.forEachIndexed { i, a -> st.setObject(i + 1, a) }; st.execute() }
        }
        override fun rows(sql: String): List<Map<String, Any?>> = c.createStatement().use { st ->
            st.executeQuery(sql).use { rs ->
                val md = rs.metaData
                buildList { while (rs.next()) add((1..md.columnCount).associate { md.getColumnName(it) to rs.getObject(it) }) }
            }
        }
    }

    @Test fun keepsAccountsAndMovementsAndMapsSignsDatesAndPlannedFlags() {
        DriverManager.getConnection("jdbc:sqlite::memory:").use { conn ->
            val sql = Jdbc(conn)
            sql.exec("CREATE TABLE `accounts` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `openingCents` INTEGER NOT NULL, PRIMARY KEY(`id`))")
            sql.exec("CREATE TABLE `movements` (`id` TEXT NOT NULL, `accountId` TEXT NOT NULL, `title` TEXT NOT NULL, `cents` INTEGER NOT NULL, `recordedAt` INTEGER NOT NULL, `entryDay` INTEGER, `planned` INTEGER NOT NULL DEFAULT 0, PRIMARY KEY(`id`), FOREIGN KEY(`accountId`) REFERENCES `accounts`(`id`) ON UPDATE NO ACTION ON DELETE RESTRICT )")
            sql.exec("INSERT INTO accounts VALUES ('acc1', 'Conto', 10000), ('acc2', 'Carta', 0)")
            val day = today.minusDays(3).toEpochDay()
            val future = today.plusDays(5).toEpochDay()
            sql.exec("INSERT INTO movements VALUES ('m1','acc1','Spesa',-2450,1000,NULL,0), ('m2','acc1','Stipendio',500000,2000,$day,0), " +
                "('m3','acc2','Bolletta',-8000,3000,$future,0), ('m4','acc2','Affitto',-70000,4000,$day,1)")

            Migration2To3.run(sql, zone, today, now = 99)

            val accounts = sql.rows("SELECT * FROM accounts ORDER BY id")
            assertEquals(listOf("Conto", "Carta").sorted(), accounts.map { it["name"] as String }.sorted())
            assertEquals(10000, (accounts[0]["initialBalanceCents"] as Number).toInt())
            assertEquals("Conto Bancario", accounts[0]["type"])
            val tx = sql.rows("SELECT * FROM transactions ORDER BY id").associateBy { it["id"] }
            assertEquals(4, tx.size)
            assertEquals(2450, (tx["m1"]!!["amountCents"] as Number).toInt()); assertEquals("Uscita", tx["m1"]!!["type"])
            assertEquals(1000L, (tx["m1"]!!["date"] as Number).toLong()) // senza entryDay resta recordedAt
            assertEquals("Entrata", tx["m2"]!!["type"])
            assertEquals(LocalDate.ofEpochDay(day).atTime(12, 0).atZone(zone).toInstant().toEpochMilli(), (tx["m2"]!!["date"] as Number).toLong())
            assertEquals(listOf(1, 1, 0, 0), listOf("m1", "m2", "m3", "m4").map { (tx[it]!!["isDone"] as Number).toInt() })
            assertEquals("Altro", tx["m1"]!!["category"]); assertEquals("tray.fill", tx["m1"]!!["categoryIcon"])
            assertEquals(4, (sql.rows("SELECT COUNT(*) AS n FROM transactions")[0]["n"] as Number).toInt())
        }
    }
}
