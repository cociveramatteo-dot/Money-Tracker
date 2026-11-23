package com.bucktrail.android.data

import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import java.time.LocalDate
import java.time.ZoneId

/** Accesso SQL minimo, così la migrazione si prova anche in un test JVM (SQLite JDBC) senza emulatore. */
interface MigrationSql {
    fun exec(sql: String, args: List<Any?> = emptyList())
    fun rows(sql: String): List<Map<String, Any?>>
}

private class SupportSql(private val db: SupportSQLiteDatabase) : MigrationSql {
    override fun exec(sql: String, args: List<Any?>) = db.execSQL(sql, args.toTypedArray())
    override fun rows(sql: String): List<Map<String, Any?>> = db.query(sql).use { c ->
        buildList {
            while (c.moveToNext()) add((0 until c.columnCount).associate { i ->
                c.getColumnName(i) to when (c.getType(i)) {
                    android.database.Cursor.FIELD_TYPE_NULL -> null
                    android.database.Cursor.FIELD_TYPE_INTEGER -> c.getLong(i)
                    android.database.Cursor.FIELD_TYPE_FLOAT -> c.getDouble(i)
                    else -> c.getString(i)
                }
            })
        }
    }
}

/** Migrazione v2 -> v3: nessun dato perso (§2.2). Le parti SQL stesse di `schemas/3.json`. */
object Migration2To3 {
    val createStatements = listOf(
        "CREATE TABLE IF NOT EXISTS `accounts` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `initialBalanceCents` INTEGER NOT NULL, `colorHex` TEXT NOT NULL, `createdAt` INTEGER NOT NULL, `isArchived` INTEGER NOT NULL, `isExcludedFromTotal` INTEGER NOT NULL, PRIMARY KEY(`id`))",
        "CREATE TABLE IF NOT EXISTS `transactions` (`id` TEXT NOT NULL, `accountId` TEXT, `name` TEXT NOT NULL, `amountCents` INTEGER NOT NULL, `type` TEXT NOT NULL, `category` TEXT NOT NULL, `categoryIcon` TEXT NOT NULL, `date` INTEGER NOT NULL, `isDone` INTEGER NOT NULL DEFAULT 1, `isFixed` INTEGER NOT NULL DEFAULT 0, `isTransfer` INTEGER NOT NULL DEFAULT 0, `transferGroupId` TEXT NOT NULL DEFAULT '', `notes` TEXT NOT NULL DEFAULT '', `recurringFrequency` TEXT NOT NULL DEFAULT '', `templateId` TEXT NOT NULL DEFAULT '', `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`accountId`) REFERENCES `accounts`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )",
        "CREATE INDEX IF NOT EXISTS `index_transactions_accountId` ON `transactions` (`accountId`)",
        "CREATE INDEX IF NOT EXISTS `index_transactions_date` ON `transactions` (`date`)",
        "CREATE INDEX IF NOT EXISTS `index_transactions_templateId` ON `transactions` (`templateId`)",
        "CREATE INDEX IF NOT EXISTS `index_transactions_transferGroupId` ON `transactions` (`transferGroupId`)",
        "CREATE TABLE IF NOT EXISTS `budgets` (`id` TEXT NOT NULL, `accountId` TEXT, `category` TEXT NOT NULL, `categoryIcon` TEXT NOT NULL, `monthlyLimitCents` INTEGER NOT NULL, `month` INTEGER NOT NULL, `year` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`), FOREIGN KEY(`accountId`) REFERENCES `accounts`(`id`) ON UPDATE NO ACTION ON DELETE CASCADE )",
        "CREATE INDEX IF NOT EXISTS `index_budgets_accountId` ON `budgets` (`accountId`)",
        "CREATE TABLE IF NOT EXISTS `goals` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `emoji` TEXT NOT NULL, `targetCents` INTEGER NOT NULL, `currentCents` INTEGER NOT NULL DEFAULT 0, `deadline` INTEGER, `isCompleted` INTEGER NOT NULL DEFAULT 0, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`))",
        "CREATE TABLE IF NOT EXISTS `categories` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `icon` TEXT NOT NULL, `isDefault` INTEGER NOT NULL, `sortOrder` INTEGER NOT NULL, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`))",
        "CREATE TABLE IF NOT EXISTS `recurring_rules` (`id` TEXT NOT NULL, `name` TEXT NOT NULL, `type` TEXT NOT NULL, `category` TEXT NOT NULL, `categoryIcon` TEXT NOT NULL, `notes` TEXT NOT NULL DEFAULT '', `amountCents` INTEGER NOT NULL, `isFixed` INTEGER NOT NULL DEFAULT 0, `accountId` TEXT, `frequency` TEXT NOT NULL, `startDate` INTEGER NOT NULL, `endDate` INTEGER, `exceptionsJson` TEXT NOT NULL DEFAULT '{}', `materializedThrough` INTEGER, `createdAt` INTEGER NOT NULL, PRIMARY KEY(`id`))",
    )

    /**
     * `cents` con segno -> tipo + importo assoluto; `planned` -> `isDone=false` (anche le voci con giorno futuro
     * alla data della migrazione, che nel v2 erano «pianificate» per derivazione); `entryDay` -> 12:00 locali di quel
     * giorno (altrimenti `recordedAt`); `title` -> `name`; categoria «Altro»; conti -> «Conto Bancario».
     */
    fun run(sql: MigrationSql, zone: ZoneId = ZoneId.systemDefault(), today: LocalDate = LocalDate.now(zone), now: Long = System.currentTimeMillis()) {
        val accounts = sql.rows("SELECT id, name, openingCents FROM accounts")
        val movements = sql.rows("SELECT id, accountId, title, cents, recordedAt, entryDay, planned FROM movements")
        sql.exec("DROP TABLE movements")
        sql.exec("DROP TABLE accounts")
        createStatements.forEach { sql.exec(it) }
        for (a in accounts) {
            sql.exec(
                "INSERT INTO accounts (id, name, type, initialBalanceCents, colorHex, createdAt, isArchived, isExcludedFromTotal) VALUES (?, ?, 'Conto Bancario', ?, '000000', ?, 0, 0)",
                listOf(a["id"], a["name"], a["openingCents"], now),
            )
        }
        for (m in movements) {
            val cents = (m["cents"] as Number).toLong()
            val recordedAt = (m["recordedAt"] as Number).toLong()
            val entryDay = (m["entryDay"] as Number?)?.toLong()
            // un `entryDay` assurdo (dato corrotto) non deve far fallire la migrazione e bloccare l'apertura dell'app: si ripiega su `recordedAt`
            val date = entryDay?.let { runCatching { LocalDate.ofEpochDay(it).atTime(12, 0).atZone(zone).toInstant().toEpochMilli() }.getOrNull() } ?: recordedAt
            val planned = (m["planned"] as Number).toLong() != 0L || (entryDay != null && entryDay > today.toEpochDay())
            sql.exec(
                "INSERT INTO transactions (id, accountId, name, amountCents, type, category, categoryIcon, date, isDone, isFixed, isTransfer, transferGroupId, notes, recurringFrequency, templateId, createdAt) VALUES (?, ?, ?, ?, ?, 'Altro', 'tray.fill', ?, ?, 0, 0, '', '', '', '', ?)",
                listOf(m["id"], m["accountId"], m["title"], if (cents == Long.MIN_VALUE) Long.MAX_VALUE else kotlin.math.abs(cents), if (cents < 0) "Uscita" else "Entrata", date, if (planned) 0L else 1L, recordedAt),
            )
        }
    }

    val migration = object : Migration(2, 3) {
        override fun migrate(db: SupportSQLiteDatabase) = run(SupportSql(db))
    }
}

/** Migrazione 1 -> 2 (invariata rispetto alle versioni precedenti). */
val migration1To2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE movements ADD COLUMN entryDay INTEGER")
        db.execSQL("ALTER TABLE movements ADD COLUMN planned INTEGER NOT NULL DEFAULT 0")
    }
}
