import Foundation
@testable import MoneyTracker

@MainActor
final class InMemoryRemote: SyncRemote {
    enum Call: Equatable {
        case fetchIds(SyncTable, UUID)
        case select(SyncTable, UUID)
        case upsert(SyncTable, UUID, Set<UUID>)
        case delete(SyncTable, UUID, Set<UUID>)
    }

    enum Failure: Error {
        case injected
        case wrongRowType
    }

    private var tables: [SyncTable: [UUID: [UUID: any SyncRow]]] = [:]
    private(set) var calls: [Call] = []
    var failOnce: Call?

    func seed<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) {
        for row in rows {
            tables[table, default: [:]][userId, default: [:]][row.id] = row
        }
    }

    func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
        try record(.fetchIds(table, userId))
        return Set(tables[table, default: [:]][userId, default: [:]].keys)
    }

    func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
        try record(.select(table, userId))
        let rows = Array(tables[table, default: [:]][userId, default: [:]].values)
        guard let typed = rows as? [Row] else { throw Failure.wrongRowType }
        return typed
    }

    func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
        try record(.upsert(table, userId, Set(rows.map(\.id))))
        seed(rows, table: table, userId: userId)
    }

    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
        try record(.delete(table, userId, Set(ids)))
        for id in ids {
            tables[table]?[userId]?.removeValue(forKey: id)
        }
    }

    private func record(_ call: Call) throws {
        calls.append(call)
        if call == failOnce {
            failOnce = nil
            throw Failure.injected
        }
    }
}
