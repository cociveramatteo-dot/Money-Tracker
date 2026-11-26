import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct E2EMigratorCleanupTests {
    @Test func emptyVaultAfterA6PreventsAnyPlaintextDelete() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        let expected = try f.snapshot()

        await #expect(throws: E2EMigrator.Failure.verificationFailed) {
            try await f.enable { step in
                if step == .a6 { f.remote.base.records.removeAll() }
            }
        }

        #expect(!f.remote.base.calls.contains {
            if case .delete = $0 { return true }
            return false
        })
        let actual = try await E2EVerifier.Snapshot(remote: f.remote, userId: f.user)
        _ = try E2EVerifier.verify(local: expected, remote: actual)
        #expect(f.marker?.phase == .verified)
    }

    @Test func d7PreservesVaultRowArrivingAfterTheVerifiedRead() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try await f.enable()
        let unexpected = VaultRecord(id: UUID(), userId: f.user, kind: SyncTable.accounts.kind,
                                     keyId: try #require(f.remote.base.e2eRows[f.user]?.keyId), payload: "not part of the verified vault read")

        await #expect(throws: E2EMigrator.Failure.verificationFailed) {
            try await f.disable { step in
                if step == .d6 { f.remote.addOnNextVaultIds = unexpected }
            }
        }

        #expect(f.remote.base.records[unexpected.id] != nil)
        #expect(!f.remote.base.calls.contains {
            if case .deleteVault(_, _, let ids) = $0 { return ids.contains(unexpected.id) }
            return false
        })
        #expect(f.marker?.direction == .disable)
        #expect(try f.keyStore.load(userId: f.user) != nil)
    }

    @Test func d7ResumesWithOnlyPartOfTheVerifiedVaultRemaining() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        let expected = try f.snapshot()
        try await f.enable()

        await #expect(throws: InMemoryRemote.Failure.injected) {
            try await f.disable { step in
                if step == .d6 { f.remote.base.failOnce = .vaultIds(.goals, f.user) }
            }
        }

        #expect(f.remote.base.records.values.map(\.kind) == [SyncTable.goals.kind])
        let marker = try #require(f.marker)
        try await f.action { try await $0.resume(marker, row: nil) }

        #expect(f.remote.base.records.isEmpty)
        #expect(f.marker == nil)
        #expect(try f.keyStore.load(userId: f.user) == nil)
        let actual = try await E2EVerifier.Snapshot(remote: f.remote, userId: f.user)
        _ = try E2EVerifier.verify(local: expected, remote: actual)
    }

    @MainActor
    private final class Fixture {
        let user = UUID()
        let remote = Remote()
        let defaultsName = "E2EMigratorCleanupTests.\(UUID())"
        let defaults: UserDefaults
        let backup = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let keyStore = E2EKeyStore()
        let store: ModelContainer
        lazy var service = SyncService(remote: remote, userId: user, defaults: defaults,
                                       e2eLaunchArguments: ["-E2EEnabled", "YES"], e2eBackupDirectory: backup)

        init() throws {
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set(user.uuidString, forKey: "syncService.lastUserId")
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            context.insert(Account(name: "Conto", type: .conto, initialBalance: 35))
            context.insert(Goal(name: "Viaggio", targetAmount: 500))
            try context.save()
        }

        var context: ModelContext { store.mainContext }
        var marker: E2EMigrationMarker? { E2EMigrator.marker(in: defaults, userId: user) }

        func cleanup() {
            defaults.removePersistentDomain(forName: defaultsName)
            try? keyStore.remove(userId: user)
            try? FileManager.default.removeItem(at: backup)
        }

        func snapshot() throws -> E2EVerifier.Snapshot {
            try E2EVerifier.Snapshot(context: context, userId: user)
        }

        func action(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                    _ operation: (E2EMigrator) async throws -> Void) async throws {
            try await service.withE2EMigrator(context: context, authenticationReason: "",
                                              checkpoint: checkpoint, authenticateForTest: {},
                                              action: operation)
        }

        func enable(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in }) async throws {
            let recovery = try E2EMigrator.makeRecoveryKey()
            let confirmation = try #require(recovery.split(separator: "-").last)
            try await action(checkpoint: checkpoint) {
                try await $0.enable(passphrase: "sentiero tra le betulle", recoveryKey: recovery,
                                    confirmation: String(confirmation))
            }
        }

        func disable(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in }) async throws {
            try await action(checkpoint: checkpoint) { try await $0.disable() }
        }
    }

    @MainActor
    private final class Remote: SyncRemote, E2EServerAccess, VaultAccess {
        let base = InMemoryRemote()
        var addOnNextVaultIds: VaultRecord?

        func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
            try await base.fetchIds(table: table, userId: userId)
        }

        func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
            try await base.select(table: table, userId: userId)
        }

        func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
            try await base.upsert(rows, table: table, userId: userId)
        }

        func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
            try await base.delete(ids: ids, table: table, userId: userId)
        }

        func lookup(userId: UUID) async throws -> E2EServerLookup { try await base.lookup(userId: userId) }
        func insert(_ row: E2EServerRow) async throws { try await base.insert(row) }
        func patch(_ changes: E2EServerPatch, userId: UUID) async throws { try await base.patch(changes, userId: userId) }
        func delete(userId: UUID) async throws { try await base.delete(userId: userId) }

        func vaultIds(table: SyncTable, userId: UUID, keyId: String) async throws -> Set<UUID> {
            if let row = addOnNextVaultIds {
                addOnNextVaultIds = nil
                base.records[row.id] = row
            }
            return try await base.vaultIds(table: table, userId: userId, keyId: keyId)
        }

        func vaultRows(table: SyncTable, userId: UUID, keyId: String?) async throws -> [VaultRecord] {
            try await base.vaultRows(table: table, userId: userId, keyId: keyId)
        }

        func upsertVault(_ rows: [VaultRecord]) async throws { try await base.upsertVault(rows) }

        func deleteVault(ids: [UUID], table: SyncTable, userId: UUID, keyId: String) async throws {
            try await base.deleteVault(ids: ids, table: table, userId: userId, keyId: keyId)
        }
    }
}
