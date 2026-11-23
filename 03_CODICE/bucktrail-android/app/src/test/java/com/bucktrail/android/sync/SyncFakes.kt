package com.bucktrail.android.sync

import com.bucktrail.android.data.AccountEntity
import com.bucktrail.android.data.BudgetEntity
import com.bucktrail.android.data.GoalEntity
import com.bucktrail.android.data.RecurringRuleEntity
import com.bucktrail.android.data.TransactionEntity
import kotlinx.serialization.json.JsonObject
import kotlinx.serialization.json.JsonPrimitive
import kotlinx.serialization.json.jsonPrimitive

const val USER = "11111111-2222-3333-4444-555555555555"

/** Finto Supabase in memoria: tabelle di righe JSON per `user_id`, registro delle chiamate, guasti iniettabili. Mai rete. */
class FakeSupabase : SupabaseApi {
    val tables = mutableMapOf<String, MutableMap<String, JsonObject>>()
    val calls = mutableListOf<String>()
    var failSelectOn: String? = null
    var failUpsertOn: String? = null
    var requireUserId: String? = null

    fun table(name: String) = tables.getOrPut(name) { linkedMapOf() }
    fun rows(name: String): List<JsonObject> = table(name).values.toList()
    fun put(name: String, row: JsonObject) { table(name)[row["id"]!!.jsonPrimitive.content.lowercase()] = row }
    fun count(prefix: String) = calls.count { it.startsWith(prefix) }

    override suspend fun signIn(email: String, password: String) = throw UnsupportedOperationException()
    override suspend fun signUp(email: String, password: String) = throw UnsupportedOperationException()
    override suspend fun refresh(refreshToken: String) = throw UnsupportedOperationException()
    override suspend fun signOut(accessToken: String) { calls += "signOut" }
    override suspend fun recover(email: String) { calls += "recover:$email" }

    override suspend fun selectAll(table: String, userId: String, token: String, columns: String): List<JsonObject> {
        calls += "select:$table"
        if (failSelectOn == table) throw ApiException(ErrorKind.Network, 0, "network down")
        return table(table).values.filter { it["user_id"]!!.jsonPrimitive.content.equals(userId, true) }.map { row ->
            // il DB restituisce gli uuid in minuscolo
            JsonObject(row.mapValues { (k, v) -> if ((k == "id" || k == "user_id" || k == "account_id") && v is JsonPrimitive && v.isString) JsonPrimitive(v.content.lowercase()) else v })
        }
    }

    override suspend fun upsert(table: String, rows: List<JsonObject>, token: String) {
        calls += "upsert:$table:${rows.size}"
        if (failUpsertOn == table) throw ApiException(ErrorKind.Server, 500, "boom")
        rows.forEach { put(table, it) }
    }

    override suspend fun deleteIn(table: String, ids: List<String>, userId: String, token: String) {
        calls += "delete:$table:${ids.size}"
        deleted += table to ids
        ids.forEach { table(table).remove(it.lowercase()) }
    }
    val deleted = mutableListOf<Pair<String, List<String>>>()

    override suspend fun rpc(function: String, token: String) { calls += "rpc:$function" }
}

class FakeLocalStore(var snap: Snapshot = Snapshot()) : LocalStore {
    var applyCount = 0
    var clearCount = 0
    var failApply = false
    override suspend fun snapshot() = snap
    override suspend fun apply(plan: SyncPlan) {
        if (failApply) throw IllegalStateException("db")
        applyCount++
        fun <T> merge(list: List<T>, add: List<T>, del: List<String>, id: (T) -> String) =
            (list.filter { id(it) !in del } .filter { x -> add.none { id(it) == id(x) } }) + add
        // il cascade del conto cancella anche i figli
        val accounts = merge(snap.accounts, plan.accounts, plan.deleteAccountIds) { it.id }
        val alive = accounts.map { it.id }.toSet()
        snap = Snapshot(
            accounts,
            merge(snap.transactions, plan.transactions, plan.deleteTransactionIds) { it.id }.filter { it.accountId == null || it.accountId in alive },
            merge(snap.budgets, plan.budgets, plan.deleteBudgetIds) { it.id }.filter { it.accountId == null || it.accountId in alive },
            merge(snap.goals, plan.goals, plan.deleteGoalIds) { it.id },
            merge(snap.rules, plan.rules, plan.deleteRuleIds) { it.id },
        )
    }
    override suspend fun clear() { clearCount++; snap = Snapshot() }
}

class MemorySyncState : SyncStateStore {
    override var lastUserId: String? = null
    override var syncedUserId: String? = null
    override var lastPull: Long = 0
    override var hasPendingChanges: Boolean = false
    private var dirty = mapOf<String, Long>()
    override fun dirty() = dirty
    override fun markDirty(ids: Collection<String>, stamp: Long) { dirty = dirty + ids.associateWith { stamp } }
    override fun clearDirty(uploaded: Map<String, Long>) { dirty = dirty.filter { (id, st) -> uploaded[id] != st } }
    override fun reset() { dirty = emptyMap() }
}

class FixedAuth(override var userId: String? = USER) : SyncEngine.AuthGateway {
    override suspend fun <T> authed(block: suspend (String) -> T): T = block("token")
}

fun account(id: String, name: String = "Conto", cents: Long = 100_00) = AccountEntity(id = id, name = name, initialBalanceCents = cents, createdAt = 1_700_000_000_000)
fun tx(id: String, accountId: String?, cents: Long = 12_50, name: String = "Spesa", date: Long = 1_763_000_000_000, template: String = "") =
    TransactionEntity(id = id, accountId = accountId, name = name, amountCents = cents, type = "Uscita", date = date, templateId = template, createdAt = 1_700_000_000_000)
fun budget(id: String, accountId: String?) = BudgetEntity(id = id, accountId = accountId, category = "Cibo", monthlyLimitCents = 300_00, month = 11, year = 2026, createdAt = 1_700_000_000_000)
fun goal(id: String) = GoalEntity(id = id, name = "Vacanza", targetCents = 2_800_00, currentCents = 1_960_00, deadline = 1_780_000_000_000, createdAt = 1_700_000_000_000)
fun rule(id: String, accountId: String?, exceptions: String = "{}", through: Long? = null) = RecurringRuleEntity(
    id = id, name = "Affitto", type = "Uscita", category = "Casa", categoryIcon = "house.fill", amountCents = 780_00, accountId = accountId, frequency = "Mensile",
    startDate = 1_760_000_000_000, exceptionsJson = exceptions, materializedThrough = through, createdAt = 1_700_000_000_000,
)

const val A1 = "aaaaaaaa-0000-4000-8000-000000000001"
const val A2 = "aaaaaaaa-0000-4000-8000-000000000002"
const val T1 = "bbbbbbbb-0000-4000-8000-000000000001"
const val T2 = "bbbbbbbb-0000-4000-8000-000000000002"
const val T3 = "bbbbbbbb-0000-4000-8000-000000000003"
const val R1 = "cccccccc-0000-4000-8000-000000000001"

fun FakeSupabase.seed(s: Snapshot, userId: String = USER) {
    s.accounts.forEach { put("mt_accounts", SyncMapper.accountRow(it, userId)) }
    s.transactions.forEach { put("mt_transactions", SyncMapper.transactionRow(it, userId)) }
    s.budgets.forEach { put("mt_budgets", SyncMapper.budgetRow(it, userId)) }
    s.goals.forEach { put("mt_goals", SyncMapper.goalRow(it, userId)) }
    s.rules.forEach { put("mt_recurring_rules", SyncMapper.ruleRow(it, userId)) }
}
