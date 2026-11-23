package com.bucktrail.android.data

import kotlinx.coroutines.flow.first
import java.time.Instant
import java.time.ZoneId

/** Semina del database demo separato (§4.12): se vuoto o con versione inferiore a quella corrente, ricrea tutto. */
object DemoSeeder {
    suspend fun seedIfNeeded(dao: BucktrailDao, prefs: AppPrefs, name: (String) -> String, now: Instant = Instant.now(), zone: ZoneId = ZoneId.systemDefault()) {
        dao.seedDefaultCategories()
        if (dao.accounts().isEmpty() || prefs.state.first().demoSeedVersion < DemoData.SEED_VERSION) forceReset(dao, prefs, name, now, zone)
    }

    suspend fun forceReset(dao: BucktrailDao, prefs: AppPrefs, name: (String) -> String, now: Instant = Instant.now(), zone: ZoneId = ZoneId.systemDefault()) {
        dao.replaceWithDemo(DemoData.build(now, zone, name))
        dao.seedDefaultCategories()
        prefs.setDemoSeedVersion(DemoData.SEED_VERSION)
    }
}
