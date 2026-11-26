import Foundation
import Supabase
@testable import MoneyTracker

@MainActor
final class InMemoryRemote: SyncRemote, E2EServerAccess, VaultAccess {
    enum Call: Equatable {
        case fetchIds(SyncTable, UUID)
        case select(SyncTable, UUID)
        case upsert(SyncTable, UUID, Set<UUID>)
        case delete(SyncTable, UUID, Set<UUID>)
        case lookupE2E(UUID)
        case insertE2E(UUID)
        case patchE2E(UUID)
        case deleteE2E(UUID)
        case vaultIds(SyncTable, UUID)
        case vaultRows(SyncTable, UUID)
        case upsertVault(Int)
        case deleteVault(SyncTable, UUID, Set<UUID>)
    }

    enum Failure: Error {
        case injected
        case wrongRowType
        case duplicateState
    }

    private var tables: [SyncTable: [UUID: [UUID: any SyncRow]]] = [:]
    private(set) var calls: [Call] = []
    var failOnce: Call?
    var lookupError: (any Error)?
    var supportsE2E = true
    var transitionOnNextPlainWrite: E2EServerRow?
    var e2eRows: [UUID: E2EServerRow] = [:]
    var records: [UUID: VaultRecord] = [:]

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
        if let transition = transitionOnNextPlainWrite {
            transitionOnNextPlainWrite = nil
            e2eRows[transition.userId] = transition
        }
        let state = e2eRows[userId]?.state
        if state == .migrating || state == .active {
            throw PostgrestError(code: "P0001", message: "bt_e2e_active")
        }
        seed(rows, table: table, userId: userId)
    }

    func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
        try record(.delete(table, userId, Set(ids)))
        if e2eRows[userId]?.state == .migrating {
            throw PostgrestError(code: "P0001", message: "bt_e2e_migrating")
        }
        for id in ids {
            tables[table]?[userId]?.removeValue(forKey: id)
        }
    }

    func lookup(userId: UUID) async throws -> E2EServerLookup {
        try record(.lookupE2E(userId))
        if let lookupError { throw lookupError }
        if !supportsE2E { return .unavailable }
        return e2eRows[userId].map(E2EServerLookup.row) ?? .absent
    }

    func insert(_ row: E2EServerRow) async throws {
        try record(.insertE2E(row.userId))
        guard e2eRows[row.userId] == nil else { throw Failure.duplicateState }
        e2eRows[row.userId] = row
    }

    func patch(_ changes: E2EServerPatch, userId: UUID) async throws {
        try record(.patchE2E(userId))
        guard var row = e2eRows[userId] else { return }
        row.state = changes.state ?? row.state
        row.kdfIterations = changes.kdfIterations ?? row.kdfIterations
        row.salt = changes.salt ?? row.salt
        row.wrappedKeyPassphrase = changes.wrappedKeyPassphrase ?? row.wrappedKeyPassphrase
        row.wrappedKeyRecovery = changes.wrappedKeyRecovery ?? row.wrappedKeyRecovery
        row.updatedAt = changes.updatedAt ?? row.updatedAt
        e2eRows[userId] = row
    }

    func delete(userId: UUID) async throws {
        try record(.deleteE2E(userId))
        e2eRows.removeValue(forKey: userId)
    }

    func vaultIds(table: SyncTable, userId: UUID, keyId: String) async throws -> Set<UUID> {
        try record(.vaultIds(table, userId))
        return Set(scopedVaultRows(table: table, userId: userId, keyId: keyId).map(\.id))
    }

    func vaultRows(table: SyncTable, userId: UUID, keyId: String?) async throws -> [VaultRecord] {
        try record(.vaultRows(table, userId))
        return scopedVaultRows(table: table, userId: userId, keyId: keyId)
    }

    func upsertVault(_ rows: [VaultRecord]) async throws {
        try record(.upsertVault(rows.count))
        for row in rows { records[row.id] = row }
    }

    func deleteVault(ids: [UUID], table: SyncTable, userId: UUID, keyId: String) async throws {
        try record(.deleteVault(table, userId, Set(ids)))
        for id in ids where records[id]?.userId == userId && records[id]?.kind == table.kind && records[id]?.keyId == keyId {
            records.removeValue(forKey: id)
        }
    }

    private func scopedVaultRows(table: SyncTable, userId: UUID, keyId: String?) -> [VaultRecord] {
        records.values.filter { $0.userId == userId && $0.kind == table.kind && (keyId == nil || $0.keyId == keyId) }
    }

    private func record(_ call: Call) throws {
        calls.append(call)
        if call == failOnce {
            failOnce = nil
            throw Failure.injected
        }
    }
}
