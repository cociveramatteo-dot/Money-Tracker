package com.bucktrail.android

import com.bucktrail.android.data.*
import androidx.room.Database
import androidx.room.RoomDatabase

@Database(
    entities = [AccountEntity::class, TransactionEntity::class, BudgetEntity::class, GoalEntity::class,
        CategoryEntity::class, RecurringRuleEntity::class],
    version = 3,
)
abstract class BucktrailDatabase : RoomDatabase() {
    abstract fun dao(): BucktrailDao

    companion object {
        const val NAME = "bucktrail.db"
    }
}

