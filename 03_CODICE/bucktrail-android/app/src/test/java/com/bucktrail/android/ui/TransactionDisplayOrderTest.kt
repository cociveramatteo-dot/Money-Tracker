package com.bucktrail.android.ui

import com.bucktrail.android.data.TransactionEntity
import org.junit.Assert.assertEquals
import org.junit.Test
import java.sql.DriverManager
import java.time.LocalDate
import java.time.ZoneId

class TransactionDisplayOrderTest {
    private val zone = ZoneId.of("Europe/Rome")

    private fun epoch(day: Int, hour: Int, minute: Int = 0, z: ZoneId = zone): Long =
        LocalDate.of(2026, 11, day).atTime(hour, minute).atZone(z).toInstant().toEpochMilli()

    @Test
    fun sameDayPlacesLaterCreatedOnTopEvenWithEarlierHour() {
        val laterHourCreatedFirst = TransactionEntity(
            id = "a",
            name = "Cena",
            amountCents = 3000,
            type = "Uscita",
            date = epoch(27, 22),
            createdAt = epoch(27, 10),
        )
        val earlierHourCreatedLast = TransactionEntity(
            id = "b",
            name = "Colazione",
            amountCents = 500,
            type = "Uscita",
            date = epoch(27, 8),
            createdAt = epoch(27, 11),
        )

        val ordered = listOf(laterHourCreatedFirst, earlierHourCreatedLast).sortedForDisplay(zone)
        assertEquals(listOf("Colazione", "Cena"), ordered.map { it.name })
    }

    @Test
    fun differentDaysOrderByCalendarDayDescending() {
        val yesterdayCreatedLater = TransactionEntity(
            id = "a",
            name = "Ieri",
            amountCents = 1200,
            type = "Uscita",
            date = epoch(26, 23, 59),
            createdAt = epoch(27, 18),
        )
        val todayCreatedEarlier = TransactionEntity(
            id = "b",
            name = "Oggi",
            amountCents = 800,
            type = "Uscita",
            date = epoch(27, 1, 0),
            createdAt = epoch(27, 9),
        )

        val ordered = listOf(yesterdayCreatedLater, todayCreatedEarlier).sortedForDisplay(zone)
        assertEquals(listOf("Oggi", "Ieri"), ordered.map { it.name })
    }

    @Test
    fun daoSqlQueryOrdersSameLocalDayByCreatedAtDescending() {
        val sysZone = ZoneId.systemDefault()
        DriverManager.getConnection("jdbc:sqlite::memory:").use { conn ->
            conn.createStatement().use { st ->
                st.execute("CREATE TABLE transactions (id TEXT PRIMARY KEY, name TEXT NOT NULL, date INTEGER NOT NULL, createdAt INTEGER NOT NULL)")
            }
            val insert = conn.prepareStatement("INSERT INTO transactions (id, name, date, createdAt) VALUES (?, ?, ?, ?)")
            insert.setString(1, "1"); insert.setString(2, "Cena")
            insert.setLong(3, epoch(27, 22, z = sysZone)); insert.setLong(4, epoch(27, 10, z = sysZone))
            insert.executeUpdate()

            insert.setString(1, "2"); insert.setString(2, "Colazione")
            insert.setLong(3, epoch(27, 8, z = sysZone)); insert.setLong(4, epoch(27, 11, z = sysZone))
            insert.executeUpdate()
            insert.close()

            val names = buildList {
                conn.createStatement().use { st ->
                    st.executeQuery("SELECT name FROM transactions ORDER BY date(date / 1000, 'unixepoch', 'localtime') DESC, createdAt DESC, id").use { rs ->
                        while (rs.next()) add(rs.getString(1))
                    }
                }
            }
            assertEquals(listOf("Colazione", "Cena"), names)
        }
    }
}
