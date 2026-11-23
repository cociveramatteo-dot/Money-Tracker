package com.bucktrail.android

import android.app.Application
import androidx.room.Room
import com.bucktrail.android.data.AppPrefs
import com.bucktrail.android.data.Migration2To3
import com.bucktrail.android.data.Repository
import com.bucktrail.android.data.migration1To2

class BucktrailApplication : Application() {
    val database by lazy {
        Room.databaseBuilder(applicationContext, BucktrailDatabase::class.java, BucktrailDatabase.NAME)
            .addMigrations(migration1To2, Migration2To3.migration).build()
    }
    val repository by lazy { Repository(database.dao()) }
    val prefs by lazy { AppPrefs(applicationContext) }
}
