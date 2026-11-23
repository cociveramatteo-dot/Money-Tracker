package com.bucktrail.android.data

import android.content.Context
import androidx.datastore.core.DataStore
import androidx.datastore.preferences.core.Preferences
import androidx.datastore.preferences.core.booleanPreferencesKey
import androidx.datastore.preferences.core.edit
import androidx.datastore.preferences.core.stringPreferencesKey
import androidx.datastore.preferences.preferencesDataStore
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.map

private val Context.dataStore: DataStore<Preferences> by preferencesDataStore(name = "bucktrail_prefs")

/** Preferenze locali (UserDefaults iOS, §2); non sincronizzate. */
data class PrefsState(
    val currencyCode: String = "EUR",
    val notificationsEnabled: Boolean = true,
    val monthlyReportEnabled: Boolean = false,
    val demoModeEnabled: Boolean = false,
    val appLockEnabled: Boolean = false,
    val hideBalance: Boolean = false,
    /** UUID separati da virgola, nell'ordine scelto per la Home. */
    val homeAccountOrderedShown: String = "",
    val showFixedExpensesTotal: Boolean = true,
    val showFixedIncomeTotal: Boolean = true,
    val txFilterMin: String = "",
    val txFilterMax: String = "",
    val txFilterUseDates: Boolean = false,
    /** `balanceThreshold_<accountId>` -> stringa `fixedFractionString` ("0.00" = disattivata). */
    val balanceThresholds: Map<String, String> = emptyMap(),
) {
    val homeAccountIds: List<String> get() = homeAccountOrderedShown.split(",").filter { it.isNotBlank() }
}

class AppPrefs(private val context: Context) {
    private object K {
        val currency = stringPreferencesKey("currencyCode")
        val notifications = booleanPreferencesKey("notificationsEnabled")
        val monthlyReport = booleanPreferencesKey("monthlyReportEnabled")
        val demo = booleanPreferencesKey("demoModeEnabled")
        val lock = booleanPreferencesKey("appLockEnabled")
        val hide = booleanPreferencesKey("hideBalance")
        val homeAccounts = stringPreferencesKey("homeAccountOrderedShown")
        val fixedExp = booleanPreferencesKey("showFixedExpensesTotal")
        val fixedInc = booleanPreferencesKey("showFixedIncomeTotal")
        val filterMin = stringPreferencesKey("txFilterMin")
        val filterMax = stringPreferencesKey("txFilterMax")
        val filterDates = booleanPreferencesKey("txFilterUseDates")
        const val THRESHOLD = "balanceThreshold_"
    }

    val state: Flow<PrefsState> = context.dataStore.data.map { p ->
        PrefsState(
            currencyCode = p[K.currency] ?: "EUR",
            notificationsEnabled = p[K.notifications] ?: true,
            monthlyReportEnabled = p[K.monthlyReport] ?: false,
            demoModeEnabled = p[K.demo] ?: false,
            appLockEnabled = p[K.lock] ?: false,
            hideBalance = p[K.hide] ?: false,
            homeAccountOrderedShown = p[K.homeAccounts] ?: "",
            showFixedExpensesTotal = p[K.fixedExp] ?: true,
            showFixedIncomeTotal = p[K.fixedInc] ?: true,
            txFilterMin = p[K.filterMin] ?: "",
            txFilterMax = p[K.filterMax] ?: "",
            txFilterUseDates = p[K.filterDates] ?: false,
            balanceThresholds = p.asMap().entries.filter { it.key.name.startsWith(K.THRESHOLD) }
                .associate { it.key.name.removePrefix(K.THRESHOLD) to it.value.toString() },
        )
    }

    suspend fun setHideBalance(value: Boolean) = context.dataStore.edit { it[K.hide] = value }
    suspend fun setCurrency(code: String) = context.dataStore.edit { it[K.currency] = code }
    suspend fun setNotifications(value: Boolean) = context.dataStore.edit { it[K.notifications] = value }
    suspend fun setMonthlyReport(value: Boolean) = context.dataStore.edit { it[K.monthlyReport] = value }
    suspend fun setDemoMode(value: Boolean) = context.dataStore.edit { it[K.demo] = value }
    suspend fun setAppLock(value: Boolean) = context.dataStore.edit { it[K.lock] = value }
    suspend fun setHomeAccounts(ids: List<String>) = context.dataStore.edit { it[K.homeAccounts] = ids.joinToString(",") }
    suspend fun setShowFixedExpenses(value: Boolean) = context.dataStore.edit { it[K.fixedExp] = value }
    suspend fun setShowFixedIncome(value: Boolean) = context.dataStore.edit { it[K.fixedInc] = value }
    suspend fun setTxFilters(min: String, max: String, useDates: Boolean) = context.dataStore.edit {
        it[K.filterMin] = min; it[K.filterMax] = max; it[K.filterDates] = useDates
    }
    suspend fun setBalanceThreshold(accountId: String, fixedFraction: String) =
        context.dataStore.edit { it[stringPreferencesKey(K.THRESHOLD + accountId)] = fixedFraction }
}
