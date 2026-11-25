import Foundation
import Supabase

enum SyncTable: String, CaseIterable {
    case accounts = "mt_accounts"
    case transactions = "mt_transactions"
    case budgets = "mt_budgets"
    case goals = "mt_goals"
    case recurringRules = "mt_recurring_rules"

    var kind: String {
        switch self {
        case .accounts: "account"
        case .transactions: "transaction"
        case .budgets: "budget"
        case .goals: "goal"
        case .recurringRules: "rule"
        }
    }
}

protocol SyncRow: Codable {
    var id: UUID { get }
}

@MainActor
protocol SyncRemote {
    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID>
    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row]
    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws
    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws
}

struct PlainRemote: SyncRemote {
    let client: SupabaseClient

    /// Recupera gli UUID di tutti i record di un utente in una tabella.
    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
        struct Row: Decodable { let id: UUID }
        let rows: [Row] = try await client.from(table.rawValue)
            .select("id")
            .eq("user_id", value: userId.uuidString)
            .execute()
            .value
        return Set(rows.map { $0.id })
    }

    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
        try await client.from(table.rawValue)
            .select().eq("user_id", value: userId.uuidString).execute().value
    }

    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
        try await client.from(table.rawValue).upsert(rows).execute()
    }

    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
        try await client.from(table.rawValue)
            .delete()
            .in("id", values: ids.map { $0.uuidString })
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
