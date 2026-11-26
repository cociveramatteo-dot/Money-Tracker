import SwiftData
import SwiftUI

#if DEBUG
/// A UI-test entry point with its own SwiftData context and no live account or transport.
struct E2EUITestHarness: View {
    nonisolated static var isRequested: Bool {
        E2EFeature.isEnabled && UserDefaults.standard.bool(forKey: "E2EUITestHarness")
    }

    private enum Fixture: String {
        case off, locked, transition, offline, interrupted, priorAttempt, removed
    }

    private let fixture = Fixture(rawValue: UserDefaults.standard.string(forKey: "E2EFixture") ?? "") ?? .off
    @State private var environment: TestEnvironment?
    @State private var failed = false

    var body: some View {
        Group {
            if let environment {
                AdvancedProtectionView(controller: environment.controller)
                    .modifier(E2EUnlockPrompt(controller: environment.controller, requiresAccount: false))
                    .modelContainer(environment.container)
            } else if failed {
                E2EMessage("e2e_errore", color: DS.danger)
            } else {
                ProgressView().tint(DS.accent)
            }
        }
        .task {
            guard environment == nil else { return }
            do { environment = try await makeEnvironment() }
            catch { failed = true }
        }
    }

    private func makeEnvironment() async throws -> TestEnvironment {
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(isStoredInMemoryOnly: true))
        let user = UUID(uuid: (0xE2, 0xE0, 0, 0, 0, 0, 0x40, 0, 0x80, 0, 0, 0, 0, 0, 0, 1))
        let suite = "com.bucktrail.e2e.uitest"
        guard let defaults = UserDefaults(suiteName: suite) else { throw E2EMigrator.Failure.unavailable }
        defaults.removePersistentDomain(forName: suite)
        defaults.set(user.uuidString, forKey: SyncService.lastUserKey)
        try E2EKeyStore().remove(userId: user)
        let remote = MemoryRemote()
        let service = SyncService(remote: remote, userId: user, defaults: defaults)
        let controller = E2EController(service: service, authenticateForTest: {})
        let context = container.mainContext
        if fixture == .locked || fixture == .transition || fixture == .removed {
            let key = try E2EMigrator.makeRecoveryKey()
            let confirmation = key.split(separator: "-").last.map(String.init) ?? ""
            try await controller.run(.enable, context: context) {
                try await $0.enable(passphrase: "correct horse battery staple", recoveryKey: key,
                                    confirmation: confirmation)
            }
            if fixture == .removed {
                // Protection turned off elsewhere: no server row, this device keeps its key.
                remote.row = nil
            } else {
                try E2EKeyStore().remove(userId: user)
            }
            if fixture == .transition { remote.row?.state = .migrating }
        }
        remote.failNextInsert = fixture == .offline
        remote.failNextVaultRead = fixture == .interrupted || fixture == .priorAttempt
        if UserDefaults.standard.bool(forKey: "E2ECaptureProgress") {
            remote.migrationDelay = .seconds(8)
        }
        await service.manualRefresh(context: context)
        if fixture == .priorAttempt {
            let previousKey = try E2EMigrator.makeRecoveryKey()
            let last = previousKey.split(separator: "-").last.map(String.init) ?? ""
            do {
                // Leave the displayed state stale, as if the server committed
                // after a failed request from a previous activation form.
                try await service.withE2EMigrator(context: context, authenticationReason: "") {
                    try await $0.enable(passphrase: "previous security phrase", recoveryKey: previousKey,
                                        confirmation: last)
                }
            } catch let error as URLError where error.code == .badServerResponse {
                // The previous attempt has a server row and a local marker.
            }
        }
        return TestEnvironment(container: container, controller: controller)
    }

    private struct TestEnvironment {
        let container: ModelContainer
        let controller: E2EController
    }

    private final class MemoryRemote: SyncRemote, VaultAccess, E2EServerAccess {
        var row: E2EServerRow?
        var failNextInsert = false
        var failNextVaultRead = false
        var migrationDelay: Duration = .zero
        private var tables: [SyncTable: [UUID: Data]] = [:]
        private var vault: [UUID: VaultRecord] = [:]

        func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
            Set(tables[table, default: [:]].keys)
        }

        func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
            try tables[table, default: [:]].values.map { try VaultJSON.decoder.decode(Row.self, from: $0) }
        }

        func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
            for row in rows { tables[table, default: [:]][row.id] = try VaultJSON.encoder.encode(row) }
        }

        func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
            for id in ids { tables[table]?.removeValue(forKey: id) }
        }

        func vaultIds(table: SyncTable, userId: UUID, keyId: String) async throws -> Set<UUID> {
            Set(try await vaultRows(table: table, userId: userId, keyId: keyId).map(\.id))
        }

        func vaultRows(table: SyncTable, userId: UUID, keyId: String?) async throws -> [VaultRecord] {
            if failNextVaultRead {
                failNextVaultRead = false
                throw URLError(.badServerResponse)
            }
            return vault.values.filter { $0.kind == table.kind && $0.userId == userId && (keyId == nil || $0.keyId == keyId) }
        }

        func upsertVault(_ rows: [VaultRecord]) async throws {
            for row in rows { vault[row.id] = row }
        }

        func deleteVault(ids: [UUID], table: SyncTable, userId: UUID, keyId: String) async throws {
            for id in ids where vault[id]?.keyId == keyId { vault.removeValue(forKey: id) }
        }

        func lookup(userId: UUID) async throws -> E2EServerLookup {
            row.map(E2EServerLookup.row) ?? .absent
        }

        func insert(_ row: E2EServerRow) async throws {
            try await Task.sleep(for: migrationDelay)
            if failNextInsert {
                failNextInsert = false
                throw URLError(.notConnectedToInternet)
            }
            self.row = row
        }

        func patch(_ changes: E2EServerPatch, userId: UUID) async throws {
            if changes.state == .disabling { try await Task.sleep(for: migrationDelay) }
            if let state = changes.state { row?.state = state }
            if let kdfIterations = changes.kdfIterations { row?.kdfIterations = kdfIterations }
            if let salt = changes.salt { row?.salt = salt }
            if let wrapped = changes.wrappedKeyPassphrase { row?.wrappedKeyPassphrase = wrapped }
            if let wrapped = changes.wrappedKeyRecovery { row?.wrappedKeyRecovery = wrapped }
            if let generation = changes.updatedAt { row?.updatedAt = generation }
        }

        func delete(userId: UUID) async throws { row = nil }

        func rollbackActivation(ifCurrent expected: E2EServerRow) async throws -> Bool {
            guard let row, row.state == .migrating, expected.state == .migrating,
                  row.userId == expected.userId, row.keyId == expected.keyId,
                  E2EServerRow.sameGeneration(row.updatedAt, expected.updatedAt) else { return false }
            self.row = nil
            vault = vault.filter { $0.value.userId != row.userId || $0.value.keyId != row.keyId }
            return true
        }
    }
}
#endif
