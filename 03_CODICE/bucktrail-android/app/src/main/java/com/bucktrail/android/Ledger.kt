package com.bucktrail.android

import androidx.room.Dao
import androidx.room.Database
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.Insert
import androidx.room.PrimaryKey
import androidx.room.Query
import androidx.room.RoomDatabase
import kotlinx.coroutines.flow.Flow
import java.math.BigDecimal
import java.text.NumberFormat
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
    val recordedAt: Long = System.currentTimeMillis()
)

data class AccountBalance(val id: String, val name: String, val cents: Long)
data class MovementLine(val id: String, val title: String, val accountName: String, val cents: Long)

@Dao
interface Ledger {
    @Insert suspend fun insert(account: Account)
    @Insert suspend fun insert(movement: Movement)

    @Query("""
        SELECT a.id, a.name, a.openingCents + COALESCE(SUM(m.cents), 0) AS cents
        FROM accounts a LEFT JOIN movements m ON a.id = m.accountId
        GROUP BY a.id ORDER BY a.name COLLATE NOCASE, a.id
    """)
    fun balances(): Flow<List<AccountBalance>>

    @Query("""
        SELECT m.id, m.title, a.name AS accountName, m.cents
        FROM movements m JOIN accounts a ON m.accountId = a.id
        ORDER BY m.recordedAt DESC, m.rowid DESC
    """)
    fun movements(): Flow<List<MovementLine>>
}

@Database(entities = [Account::class, Movement::class], version = 1)
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
