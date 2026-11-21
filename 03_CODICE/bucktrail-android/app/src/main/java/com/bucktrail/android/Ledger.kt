package com.bucktrail.android

import androidx.room.Dao
import androidx.room.ColumnInfo
import androidx.room.Database
import androidx.room.Embedded
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.Relation
import androidx.room.RoomDatabase
import androidx.room.Transaction
import androidx.room.Update
import androidx.room.migration.Migration
import androidx.sqlite.db.SupportSQLiteDatabase
import kotlinx.coroutines.flow.Flow
import java.math.BigDecimal
import java.text.NumberFormat
import java.time.Instant
import java.time.LocalDate
import java.time.YearMonth
import java.time.ZoneId
import java.util.Locale
import java.util.UUID

@Entity(tableName = "accounts")
data class Account(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val openingCents: Long
)

@Entity(
    tableName = "movements",
    foreignKeys = [ForeignKey(
        entity = Account::class,
        parentColumns = ["id"],
        childColumns = ["accountId"],
        onDelete = ForeignKey.RESTRICT
    )],
    indices = [Index("accountId")]
)
data class Movement(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val accountId: String,
    val title: String,
    val cents: Long,
    val recordedAt: Long = System.currentTimeMillis(),
    val entryDay: Long? = null,
    @ColumnInfo(defaultValue = "0") val planned: Boolean = false
)

data class AccountWithMovements(
    @Embedded val account: Account,
    @Relation(parentColumn = "id", entityColumn = "accountId") val movements: List<Movement>
)

data class AccountBalance(val id: String, val name: String, val cents: Long)
data class MovementLine(val entry: Movement, val accountName: String, val date: LocalDate, val planned: Boolean)
data class LedgerSnapshot(
    val accounts: List<AccountBalance>,
    val booked: List<MovementLine>,
    val planned: List<MovementLine>,
    val expectedBalance: Long
)

fun Movement.date(zone: ZoneId): LocalDate =
    entryDay?.let(LocalDate::ofEpochDay) ?: Instant.ofEpochMilli(recordedAt).atZone(zone).toLocalDate()

fun summarize(
    entries: List<AccountWithMovements>,
    today: LocalDate,
    zone: ZoneId
): LedgerSnapshot {
    val balances = mutableListOf<AccountBalance>()
    val booked = mutableListOf<MovementLine>()
    val planned = mutableListOf<MovementLine>()
    entries.forEach { (account, movements) ->
        var balance = account.openingCents
        movements.forEach { entry ->
            val day = entry.date(zone)
            val inArrivo = entry.planned || day > today
            val row = MovementLine(entry, account.name, day, inArrivo)
            if (inArrivo) planned.add(row) else {
                balance += entry.cents
                booked.add(row)
            }
        }
        balances.add(AccountBalance(account.id, account.name, balance))
    }
    val currentMonth = YearMonth.from(today)
    val expected = balances.sumOf { it.cents } +
        planned.filter { YearMonth.from(it.date) == currentMonth }.sumOf { it.entry.cents }
    return LedgerSnapshot(
        balances,
        booked.sortedWith(compareByDescending<MovementLine> { it.date }.thenByDescending { it.entry.recordedAt }),
        planned.sortedWith(compareBy<MovementLine> { it.date }.thenBy { it.entry.recordedAt }),
        expected
    )
}

@Dao
interface Ledger {
    @Insert suspend fun insert(account: Account)
    @Insert suspend fun insert(movement: Movement)
    @Update suspend fun update(movement: Movement): Int

    @Transaction
    @Query("SELECT * FROM accounts ORDER BY name COLLATE NOCASE, id")
    fun observe(): Flow<List<AccountWithMovements>>
}

val migration1To2 = object : Migration(1, 2) {
    override fun migrate(db: SupportSQLiteDatabase) {
        db.execSQL("ALTER TABLE movements ADD COLUMN entryDay INTEGER")
        db.execSQL("ALTER TABLE movements ADD COLUMN planned INTEGER NOT NULL DEFAULT 0")
    }
}

@Database(entities = [Account::class, Movement::class], version = 2)
abstract class BucktrailDatabase : RoomDatabase() {
    abstract fun ledger(): Ledger
}

private val amountPattern = Regex("[+-]?[0-9]{1,10}([,.][0-9]{1,2})?")

fun parseCents(raw: String): Long? {
    val value = raw.trim()
    if (!amountPattern.matches(value)) return null
    return value.replace(',', '.').toBigDecimal().movePointRight(2).longValueExact()
}

fun euros(cents: Long): String =
    NumberFormat.getCurrencyInstance(Locale.ITALY).format(BigDecimal.valueOf(cents, 2))
