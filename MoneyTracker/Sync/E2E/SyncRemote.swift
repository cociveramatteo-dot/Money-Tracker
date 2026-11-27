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

nonisolated protocol SyncRow: Codable, Sendable {
    var id: UUID { get }
}

enum AccountSyncError: LocalizedError {
    case stillReferenced

    var errorDescription: String? { "A transaction still refers to an account selected for deletion." }
}

@MainActor
protocol SyncRemote {
    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID>
    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row]
    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws
    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws
    func repairAccountLinks(_ links: [UUID: UUID], userId: UUID) async throws
}

extension SyncRemote {
    func repairAccountLinks(_ links: [UUID: UUID], userId: UUID) async throws {}
}

struct PlainRemote: SyncRemote {
    let client: SupabaseClient
    var forMigration = false

    private struct IDRow: Decodable { let id: UUID }

    private func readAll<Row: Decodable>(_ columns: String, table: SyncTable, userId: UUID,
                                         id: KeyPath<Row, UUID>) async throws -> [Row] {
        var result: [Row] = []
        var cursor: UUID?
        repeat {
            try Task.checkCancellation()
            let query = client.from(table.rawValue).select(columns).eq("user_id", value: userId.uuidString)
            if let cursor { _ = query.gt("id", value: cursor.uuidString) }
            let page: [Row] = try await query.order("id").limit(200).execute().value
            result.append(contentsOf: page)
            cursor = page.count == 200 ? page.last?[keyPath: id] : nil
        } while cursor != nil
        return result
    }

    /// Recupera gli UUID di tutti i record di un utente in una tabella.
    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
        let rows: [IDRow] = try await readAll("id", table: table, userId: userId, id: \.id)
        return Set(rows.map(\.id))
    }

    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
        try await readAll("*", table: table, userId: userId, id: \.id)
    }

    private nonisolated struct TransactionWrite: Encodable, Sendable {
        let row: SBTransaction

        func encode(to encoder: Encoder) throws {
            try row.encode(to: encoder, explicitNullAccount: true)
        }
    }

    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
        func send<Payload: Encodable & Sendable>(_ rows: [Payload]) async throws {
            if forMigration {
                for offset in stride(from: 0, to: rows.count, by: 200) {
                    try Task.checkCancellation()
                    try await client.from(table.rawValue).upsert(Array(rows[offset..<min(offset + 200, rows.count)]))
                        .execute()
                }
            } else {
                try await client.from(table.rawValue).upsert(rows).execute()
            }
        }

        // PostgREST needs an explicit JSON null to unlink an existing transaction.
        if table == .transactions, let transactions = rows as? [SBTransaction] {
            try await send(transactions.map { TransactionWrite(row: $0) })
        } else {
            try await send(rows)
        }
    }

    func repairAccountLinks(_ links: [UUID: UUID], userId: UUID) async throws {
        let entries = links.map { ($0.key.uuidString, $0.value.uuidString) }
        for offset in stride(from: 0, to: entries.count, by: 200) {
            let batch = Dictionary(uniqueKeysWithValues: entries[offset..<min(offset + 200, entries.count)])
            try await client.rpc("mt_repair_transaction_accounts", params: ["links": batch]).execute()
        }
    }

    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
        try await client.from(table.rawValue)
            .delete()
            .in("id", values: ids.map { $0.uuidString })
            .eq("user_id", value: userId.uuidString)
            .execute()
    }
}
