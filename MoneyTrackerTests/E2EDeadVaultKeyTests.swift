import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct E2EDeadVaultKeyTests {
    @Test(arguments: [false, true])
    func reactivationAfterInterruptedD7ResumesPull(cleanupFails: Bool) async throws {
        let user = UUID()
        let remote = InMemoryRemote()
        let first = try Device(user: user, remote: remote)
        defer { first.cleanup() }
        let second = try Device(user: user, remote: remote)
        defer { second.cleanup() }

        let account = Account(name: "Conto", type: .conto)
        let obsoleteGoal = Goal(name: "Obiettivo rimosso", targetAmount: 500)
        first.context.insert(account)
        first.context.insert(obsoleteGoal)
        try first.context.save()
        try await first.enable()
        let deadKey = try #require(remote.e2eRows[user]?.keyId)

        await #expect(throws: InMemoryRemote.Failure.injected) {
            try await first.migrate(checkpoint: { step in
                if step == .d6 { remote.failOnce = .vaultIds(.goals, user) }
            }) { try await $0.disable() }
        }
        #expect(remote.e2eRows[user] == nil)
        #expect(Set(remote.records.keys) == [obsoleteGoal.id])
        #expect(first.marker?.direction == .disable)

        // The goal was deleted in plain mode before the second device re-enabled.
        try await remote.delete(ids: [obsoleteGoal.id], table: .goals, userId: user)
        await second.service.pull(context: second.context)
        if cleanupFails {
            remote.failOnce = .deleteVault(.goals, user, [obsoleteGoal.id])
        }
        try await second.enable()

        let current = try #require(remote.e2eRows[user])
        #expect(current.keyId != deadKey)
        #expect(current.state == .active)
        #expect(remote.records.values.contains { $0.keyId == deadKey } == cleanupFails)
        #expect(remote.records[account.id]?.keyId == current.keyId)

        await first.service.pull(context: first.context)
        #expect(first.marker == nil)
        #expect(first.service.e2eLockReason == .needsSecret)
        try await first.migrate { try await $0.unlock(.passphrase(Device.phrase)) }

        let added = Account(name: "Arrivato dal cloud", type: .conto)
        let key = try #require(try second.keyStore.load(userId: user))
        try await VaultRemote(access: remote, dek: key.dek, owner: user, scopeReads: true)
            .upsert([SBAccount(added, userId: user)], table: .accounts, userId: user)
        await first.service.pull(context: first.context)
        #expect(first.service.status == .idle)
        #expect(Set(try first.context.fetch(FetchDescriptor<Account>()).map(\.id)) == [account.id, added.id])
        #expect(try first.context.fetchCount(FetchDescriptor<Goal>()) == 0)
    }

    @Test func wrongKeyIsAStateChange() {
        #expect(E2EServer.operationStateChanged(VaultRemote.Failure.wrongKey))
        #expect(!E2EServer.operationStateChanged(VaultRemote.Failure.wrongKind))
    }

    @MainActor
    private final class Device {
        static let phrase = "sentiero tra le betulle"
        let user: UUID
        let defaultsName = "E2EDeadVaultKeyTests.\(UUID())"
        let defaults: UserDefaults
        let backup = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString)
        let keyStore = E2EKeyStore(service: "com.bucktrail.tests.\(UUID())")
        let container: ModelContainer
        let service: SyncService

        init(user: UUID, remote: InMemoryRemote) throws {
            self.user = user
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set(user.uuidString, forKey: "syncService.lastUserId")
            let schema = Schema(versionedSchema: SchemaV3.self)
            container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            service = SyncService(remote: remote, userId: user, defaults: defaults,
                                  e2eLaunchArguments: ["-E2EEnabled", "YES"], e2eBackupDirectory: backup,
                                  e2eKeyStore: keyStore)
        }

        var context: ModelContext { container.mainContext }
        var marker: E2EMigrationMarker? { E2EMigrator.marker(in: defaults, userId: user) }

        func migrate(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                     _ action: (E2EMigrator) async throws -> Void) async throws {
            try await service.withE2EMigrator(context: context, authenticationReason: "",
                                              checkpoint: checkpoint, authenticateForTest: {}, action: action)
        }

        func enable() async throws {
            let recovery = try E2EMigrator.makeRecoveryKey()
            let confirmation = try #require(recovery.split(separator: "-").last)
            try await migrate {
                try await $0.enable(passphrase: Self.phrase, recoveryKey: recovery, confirmation: String(confirmation))
            }
        }

        func cleanup() {
            defaults.removePersistentDomain(forName: defaultsName)
            try? keyStore.remove(userId: user)
            try? FileManager.default.removeItem(at: backup)
        }
    }
}
