package com.bucktrail.android.data

import androidx.room.ColumnInfo
import androidx.room.Entity
import androidx.room.ForeignKey
import androidx.room.Index
import androidx.room.PrimaryKey
import com.bucktrail.android.domain.AccountData
import com.bucktrail.android.domain.Amounts
import com.bucktrail.android.domain.Budgeting
import com.bucktrail.android.domain.RuleSnapshot
import com.bucktrail.android.domain.RecurrenceExceptionCodec
import com.bucktrail.android.domain.TransactionData
import java.time.Instant
import java.util.UUID

/** Schema Room v3 (§2.2). Importi in centesimi (scala 2); id UUID minuscolo; `templateId`/`transferGroupId` MAIUSCOLI. */
@Entity(tableName = "accounts")
data class AccountEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val type: String = "Conto Bancario",
    val initialBalanceCents: Long = 0,
    val colorHex: String = "000000",
    val createdAt: Long = System.currentTimeMillis(),
    val isArchived: Boolean = false,
    val isExcludedFromTotal: Boolean = false,
)

@Entity(
    tableName = "transactions",
    foreignKeys = [ForeignKey(AccountEntity::class, ["id"], ["accountId"], onDelete = ForeignKey.CASCADE)],
    indices = [Index("accountId"), Index("date"), Index("templateId"), Index("transferGroupId")],
)
data class TransactionEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val accountId: String? = null,
    val name: String,
    val amountCents: Long,
    val type: String,
    val category: String = "Altro",
    val categoryIcon: String = "circle.dotted",
    val date: Long,
    @ColumnInfo(defaultValue = "1") val isDone: Boolean = true,
    @ColumnInfo(defaultValue = "0") val isFixed: Boolean = false,
    @ColumnInfo(defaultValue = "0") val isTransfer: Boolean = false,
    @ColumnInfo(defaultValue = "''") val transferGroupId: String = "",
    @ColumnInfo(defaultValue = "''") val notes: String = "",
    @ColumnInfo(defaultValue = "''") val recurringFrequency: String = "",
    @ColumnInfo(defaultValue = "''") val templateId: String = "",
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(
    tableName = "budgets",
    foreignKeys = [ForeignKey(AccountEntity::class, ["id"], ["accountId"], onDelete = ForeignKey.CASCADE)],
    indices = [Index("accountId")],
)
data class BudgetEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val accountId: String? = null,
    val category: String,
    val categoryIcon: String = "circle.dotted",
    val monthlyLimitCents: Long,
    val month: Int,
    val year: Int,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "goals")
data class GoalEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val emoji: String = "target",
    val targetCents: Long,
    @ColumnInfo(defaultValue = "0") val currentCents: Long = 0,
    val deadline: Long? = null,
    @ColumnInfo(defaultValue = "0") val isCompleted: Boolean = false,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "categories")
data class CategoryEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val icon: String,
    val isDefault: Boolean = false,
    val sortOrder: Int = 0,
    val createdAt: Long = System.currentTimeMillis(),
)

@Entity(tableName = "recurring_rules")
data class RecurringRuleEntity(
    @PrimaryKey val id: String = UUID.randomUUID().toString(),
    val name: String,
    val type: String,
    val category: String,
    val categoryIcon: String,
    @ColumnInfo(defaultValue = "''") val notes: String = "",
    val amountCents: Long,
    @ColumnInfo(defaultValue = "0") val isFixed: Boolean = false,
    /** Non è una relazione (come iOS): l'id del conto può non esistere più. */
    val accountId: String? = null,
    val frequency: String,
    val startDate: Long,
    val endDate: Long? = null,
    @ColumnInfo(defaultValue = "'{}'") val exceptionsJson: String = "{}",
    val materializedThrough: Long? = null,
    val createdAt: Long = System.currentTimeMillis(),
)

fun AccountEntity.toData() = AccountData(id, name, type, Amounts.fromCents(initialBalanceCents), isArchived, isExcludedFromTotal)

fun TransactionEntity.toData() = TransactionData(
    id, accountId, name, Amounts.fromCents(amountCents), type, category, categoryIcon, Instant.ofEpochMilli(date),
    isDone, isFixed, isTransfer, transferGroupId, notes, recurringFrequency, templateId, Instant.ofEpochMilli(createdAt),
)

fun BudgetEntity.toData() = Budgeting.BudgetData(id, accountId, category, Amounts.fromCents(monthlyLimitCents), month, year)
fun GoalEntity.toData() = Budgeting.GoalData(id, Amounts.fromCents(targetCents), Amounts.fromCents(currentCents))

fun RecurringRuleEntity.toSnapshot() = RuleSnapshot(
    id = UUID.fromString(id), name = name, amount = Amounts.fromCents(amountCents), type = type, category = category,
    categoryIcon = categoryIcon, notes = notes, isFixed = isFixed, accountId = accountId?.let { runCatching { UUID.fromString(it) }.getOrNull() },
    frequency = frequency, startDate = Instant.ofEpochMilli(startDate), endDate = endDate?.let(Instant::ofEpochMilli),
    exceptions = RecurrenceExceptionCodec.decode(exceptionsJson),
)
