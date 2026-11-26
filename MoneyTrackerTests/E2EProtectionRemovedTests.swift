import CryptoKit
import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

/// Gate with no `mt_e2e` row (S-50m, decision of 2026-11-26).
@MainActor
struct E2EProtectionRemovedTests {
    private let keyStore = E2EKeyStore()
    private let key = SymmetricKey(data: Data(repeating: 0x3B, count: 32))
    private let user = UUID()
    private let remote = InMemoryRemote()

    private var gate: E2EGate { E2EGate(server: remote, keyStore: keyStore) }

    // (a) DEK + no marker + no row: locked, key intact, nothing uploaded.
    @Test func keyWithoutRowLocksWithoutUploading() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try Fixture(remote: remote, user: user)
        try keyStore.save(key, userId: user)
        fixture.context.insert(Account(name: "Locale", type: .conto))
        try fixture.context.save()

        #expect(await fixture.service.pushResilient(context: fixture.context) == false)
        await fixture.service.syncOnForeground(context: fixture.context)

        #expect(fixture.service.e2eLockReason == .protectionRemoved)
        #expect(fixture.service.currentE2EProtection == .locked(.protectionRemoved, isEnabling: false))
        #expect(try keyStore.load(userId: user)?.dek == key)
        #expect(remote.calls.allSatisfy { $0 == .lookupE2E(user) })
        #expect(fixture.defaults.bool(forKey: "syncService.hasPendingChanges"))
    }

    // (b) "Continue without protection": key removed, first exchange pulls, no upload or delete.
    @Test func continuingRemovesKeyAndPullsBeforePushing() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try Fixture(remote: remote, user: user)
        try keyStore.save(key, userId: user)
        let cloud = Account(name: "Altro dispositivo", type: .conto)
        remote.seed([SBAccount(cloud, userId: user)], table: .accounts, userId: user)
        fixture.context.insert(Account(name: "Copia locale", type: .conto))
        try fixture.context.save()
        await fixture.service.syncOnForeground(context: fixture.context)
        try #require(fixture.service.e2eLockReason == .protectionRemoved)

        #expect(await fixture.service.continueWithoutE2EProtection(context: fixture.context))

        #expect(try keyStore.load(userId: user) == nil)
        #expect(fixture.service.e2eLockReason == nil)
        #expect(fixture.service.currentE2EProtection == .off)
        #expect(!remote.calls.contains { if case .upsert = $0 { true } else { false } })
        #expect(!remote.calls.contains { if case .delete = $0 { true } else { false } })
        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).map(\.name) == [cloud.name])
        #expect(fixture.defaults.string(forKey: "e2e.initialSyncUser") == nil)
    }

    @Test func continuingIsIgnoredOutsideProtectionRemoved() async throws {
        let fixture = try Fixture(remote: remote, user: user)
        #expect(await fixture.service.continueWithoutE2EProtection(context: fixture.context) == false)
        #expect(remote.calls.isEmpty)
    }

    // (c) Disable rollback marker + no row + DEK: locked, marker removed, no loop.
    @Test func rollbackMarkerWithoutRowLocksOnceAndClearsMarker() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try Fixture(remote: remote, user: user)
        try keyStore.save(key, userId: user)
        try fixture.setMarker(.disable, phase: .rollingBack)

        await fixture.service.syncOnForeground(context: fixture.context)
        await fixture.service.manualRefresh(context: fixture.context)

        #expect(fixture.service.e2eLockReason == .protectionRemoved)
        #expect(fixture.service.e2eMigrationToResume == nil)
        #expect(fixture.defaults.data(forKey: E2EMigrationMarker.defaultsKey) == nil)
        #expect(try keyStore.load(userId: user)?.dek == key)
        #expect(remote.calls == [.lookupE2E(user), .lookupE2E(user)])
    }

    // (d) D2 without D3: plain first exchange, never deleting another device's rows.
    @Test func disableMarkerWithoutPhasePullsWithoutDeletingRemoteRows() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try Fixture(remote: remote, user: user)
        try keyStore.save(key, userId: user)
        try fixture.setMarker(.disable, phase: nil)
        let other = Account(name: "Da un altro dispositivo", type: .conto)
        remote.seed([SBAccount(other, userId: user)], table: .accounts, userId: user)
        fixture.context.insert(Account(name: "Locale", type: .conto))
        try fixture.context.save()

        let resolution = try await gate.resolve(userId: user, enabled: true,
                                                marker: E2EMigrator.marker(in: fixture.defaults, userId: user))
        guard case .plain = resolution.mode else { Issue.record("Expected plain mode"); return }
        #expect(resolution.needsPlainInitialSync)
        try keyStore.save(key, userId: user)

        await fixture.service.syncOnForeground(context: fixture.context)

        #expect(try keyStore.load(userId: user) == nil)
        #expect(fixture.defaults.data(forKey: E2EMigrationMarker.defaultsKey) == nil)
        #expect(fixture.service.e2eLockReason == nil)
        #expect(!remote.calls.contains { if case .delete = $0 { true } else { false } })
        #expect(!remote.calls.contains { if case .upsert = $0 { true } else { false } })
        #expect(try await remote.fetchIds(table: .accounts, userId: user) == [other.id])
        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).map(\.id) == [other.id])
    }

    // Cleanup phases already deleted the row on purpose: finish them.
    @Test(arguments: [E2EMigrationMarker.Phase.verified, .resetting])
    func cleanupMarkerWithoutRowResumesDisable(phase: E2EMigrationMarker.Phase) async throws {
        defer { try? keyStore.remove(userId: user) }
        try keyStore.save(key, userId: user)
        var marker = E2EMigrationMarker(direction: .disable, userId: user, keyId: "k", startedAt: 1)
        marker.phase = phase
        let resolution = try await gate.resolve(userId: user, enabled: true, marker: marker)
        guard case .resume(.disable) = resolution.mode else { Issue.record("Expected disable resume"); return }
        #expect(try keyStore.load(userId: user)?.dek == key)
    }

    @Test func enableMarkerWithoutRowKeepsCurrentBehaviour() async throws {
        defer { try? keyStore.remove(userId: user) }
        try keyStore.save(key, userId: user)
        let marker = E2EMigrationMarker(direction: .enable, userId: user, keyId: "k", startedAt: 1)
        let resolution = try await gate.resolve(userId: user, enabled: true, marker: marker)
        guard case .plain = resolution.mode else { Issue.record("Expected plain mode"); return }
        #expect(resolution.needsPlainInitialSync)
        #expect(try keyStore.load(userId: user) == nil)
    }

    @MainActor
    private final class Fixture {
        let store: ModelContainer
        let service: SyncService
        let defaultsName: String
        let defaults: UserDefaults
        let user: UUID

        var context: ModelContext { store.mainContext }

        init(remote: InMemoryRemote, user: UUID) throws {
            self.user = user
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            defaultsName = "E2EProtectionRemovedTests.\(user)"
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set(user.uuidString, forKey: SyncService.lastUserKey)
            service = SyncService(remote: remote, userId: user, defaults: defaults,
                                  e2eLaunchArguments: ["MoneyTracker", "-E2EEnabled", "YES"])
        }

        func setMarker(_ direction: E2EMigrationDirection, phase: E2EMigrationMarker.Phase?) throws {
            var marker = E2EMigrationMarker(direction: direction, userId: user, keyId: "k", startedAt: 1)
            marker.phase = phase
            defaults.set(try JSONEncoder().encode(marker), forKey: E2EMigrationMarker.defaultsKey)
        }

        isolated deinit {
            defaults.removePersistentDomain(forName: defaultsName)
        }
    }
}
