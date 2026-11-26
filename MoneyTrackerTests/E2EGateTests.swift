import CryptoKit
import Foundation
import Security
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct E2EGateTests {
    private let keyStore = E2EKeyStore()
    private let key = SymmetricKey(data: Data(repeating: 0xA5, count: 32))
    private let otherKey = SymmetricKey(data: Data(repeating: 0x7C, count: 32))
    private let user = UUID()
    private let remote = InMemoryRemote()

    private var gate: E2EGate { E2EGate(server: remote, keyStore: keyStore) }

    @Test func featureIsOffWithoutLaunchArgument() {
        #expect(!ProcessInfo.processInfo.arguments.contains("-E2EEnabled"))
        #expect(E2EFeature.isEnabled == false)
        #if DEBUG
        #expect(E2EFeature.isEnabled(arguments: ["MoneyTracker", "-E2EEnabled"]) == false)
        #expect(E2EFeature.isEnabled(arguments: ["MoneyTracker", "-E2EEnabled", "NO"]) == false)
        #expect(E2EFeature.isEnabled(arguments: ["MoneyTracker", "-E2EEnabled", "YES"]) == true)
        #endif
    }

    @Test func disabledGateDoesNotReadServer() async throws {
        remote.lookupError = URLError(.notConnectedToInternet)
        let result = try await gate.resolve(userId: user, enabled: false)
        guard case .plain = result.mode else { Issue.record("Expected plain mode"); return }
        #expect(result.serverSupported == nil)
        #expect(remote.calls.isEmpty)
    }

    @Test func absentAndUnavailableAreDistinct() async throws {
        defer { try? keyStore.remove(userId: user) }
        let empty = try await gate.resolve(userId: user, enabled: true)
        guard case .plain = empty.mode else { Issue.record("Expected plain mode"); return }
        #expect(empty.serverSupported == true)
        #expect(!empty.needsPlainInitialSync)

        try keyStore.save(key, userId: user)
        remote.supportsE2E = false
        let unavailable = try await gate.resolve(userId: user, enabled: true)
        guard case .plain = unavailable.mode else { Issue.record("Expected plain mode"); return }
        #expect(unavailable.serverSupported == false)
        #expect(try keyStore.load(userId: user)?.dek == key)

        remote.supportsE2E = true
        let removed = try await gate.resolve(userId: user, enabled: true)
        guard case .plain = removed.mode else { Issue.record("Expected plain mode"); return }
        #expect(removed.needsPlainInitialSync)
        #expect(try keyStore.load(userId: user) == nil)
    }

    @Test func activeRequiresMatchingKeyAndClearsStaleKey() async throws {
        defer { try? keyStore.remove(userId: user) }
        remote.e2eRows[user] = try makeRow()
        try expectLocked(.needsSecret, try await gate.resolve(userId: user, enabled: true))

        try keyStore.save(key, userId: user)
        let active = try await gate.resolve(userId: user, enabled: true)
        guard case .vault(let resolvedKey) = active.mode else {
            Issue.record("Expected vault mode")
            return
        }
        #expect(resolvedKey == key)

        remote.e2eRows[user] = try makeRow(dek: otherKey)
        try expectLocked(.needsSecret, try await gate.resolve(userId: user, enabled: true))
        #expect(try keyStore.load(userId: user) == nil)
    }

    @Test(arguments: [E2EMigrationDirection.enable, .disable])
    func transitionRequiresMatchingDirectionUserKeyAndLocalDEK(direction: E2EMigrationDirection) async throws {
        defer { try? keyStore.remove(userId: user) }
        let state: E2EServerState = direction == .enable ? .migrating : .disabling
        let row = try makeRow(state: state)
        remote.e2eRows[user] = row
        let marker = E2EMigrationMarker(direction: direction, userId: user, keyId: row.keyId, startedAt: 1)
        try expectLocked(.transition, try await gate.resolve(userId: user, enabled: true, marker: marker))

        try keyStore.save(key, userId: user)
        let wrongDirection: E2EMigrationDirection = direction == .enable ? .disable : .enable
        let invalidMarkers: [E2EMigrationMarker?] = [
            nil,
            .init(direction: wrongDirection, userId: user, keyId: row.keyId, startedAt: 1),
            .init(direction: direction, userId: UUID(), keyId: row.keyId, startedAt: 1),
            .init(direction: direction, userId: user, keyId: "0000000000000000", startedAt: 1)
        ]
        for invalid in invalidMarkers {
            try expectLocked(.transition, try await gate.resolve(userId: user, enabled: true, marker: invalid))
        }
        let resumable = try await gate.resolve(userId: user, enabled: true, marker: marker)
        guard case .resume(let resolvedDirection) = resumable.mode else {
            Issue.record("Expected resume mode")
            return
        }
        #expect(resolvedDirection == direction)
    }

    @Test func unsupportedStateNeverWritesOrDiscardsKey() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try makeService()
        try keyStore.save(key, userId: user)
        let unsupported = [
            try makeRow(version: 2), try makeRow(kdf: "unknown"),
            try makeRow(iterations: 99_999), try makeRow(iterations: 10_000_001),
            try makeRow(salt: "bad"), try makeRow(wrapped: "bt2.invalid"), try makeRow(userId: UUID())
        ]
        for row in unsupported {
            remote.e2eRows[user] = row
            #expect(await fixture.service.pushResilient(context: fixture.context) == false)
            #expect(fixture.service.e2eLockReason == .unsupported)
            #expect(fixture.service.status == .idle)
        }
        #expect(remote.calls == Array(repeating: .lookupE2E(user), count: unsupported.count))
        #expect(try keyStore.load(userId: user)?.dek == key)
    }

    @Test func networkErrorUsesBackoffWithoutPlainOrVaultRequests() async throws {
        remote.lookupError = URLError(.notConnectedToInternet)
        let fixture = try makeService()
        defer { fixture.service.clearLocalData(context: fixture.context) }
        await fixture.service.syncOnForeground(context: fixture.context)
        #expect(fixture.service.status == .waitingForRetry(attempt: 1))
        #expect(fixture.defaults.bool(forKey: "syncService.hasPendingChanges"))
        #expect(remote.calls == [.lookupE2E(user)])
    }

    @Test func lockPreservesDirtyEditsAndUploadsThemAfterUnlock() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try makeService()
        remote.e2eRows[user] = try makeRow()
        let account = Account(name: "Conto locale", type: .conto)
        let transaction = Transaction(name: "Caffè", amount: 2, type: .uscita, account: account)
        fixture.context.insert(account)
        fixture.context.insert(transaction)
        try fixture.context.save()

        await fixture.service.manualRefresh(context: fixture.context)
        transaction.name = "Caffè durante la pausa"
        try fixture.context.save()
        fixture.service.markTransactionDirty(transaction.id)

        #expect(await fixture.service.pushResilient(context: fixture.context) == false)
        #expect(fixture.service.status == .idle)
        #expect(fixture.service.e2eLockReason == .needsSecret)
        #expect(fixture.defaults.bool(forKey: "syncService.hasPendingChanges"))
        #expect(remote.calls == [.lookupE2E(user), .lookupE2E(user)])

        try keyStore.save(key, userId: user)
        #expect(await fixture.service.pushResilient(context: fixture.context))
        #expect(!fixture.defaults.bool(forKey: "syncService.hasPendingChanges"))
        #expect(fixture.service.e2eLockReason == nil)
        let vault = VaultRemote(access: remote, dek: key, owner: user)
        let rows: [SBTransaction] = try await vault.select(table: .transactions, userId: user)
        #expect(rows.map(\.name) == ["Caffè durante la pausa"])
    }

    @Test func plainWriteBlockedByTriggerImmediatelyRechecksMode() async throws {
        let fixture = try makeService()
        let account = Account(name: "Locale", type: .conto)
        fixture.context.insert(account)
        try fixture.context.save()
        remote.transitionOnNextPlainWrite = try makeRow(state: .migrating)
        #expect(await fixture.service.pushResilient(context: fixture.context) == false)
        #expect(remote.calls == [.lookupE2E(user), .upsert(.accounts, user, [account.id]), .lookupE2E(user)])
        #expect(fixture.service.e2eLockReason == .transition)
        #expect(fixture.service.status == .idle)
        #expect(fixture.defaults.bool(forKey: "syncService.hasPendingChanges"))
        #expect(try await remote.fetchIds(table: .accounts, userId: user).isEmpty)
    }

    @Test func removedServerRowUsesInitialPullBeforeSendingLocalSnapshot() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try makeService()
        try keyStore.save(key, userId: user)
        let cloud = Account(name: "Conto cloud", type: .conto)
        let local = Account(name: "Vecchia copia locale", type: .conto)
        fixture.context.insert(local)
        try fixture.context.save()
        remote.seed([SBAccount(cloud, userId: user)], table: .accounts, userId: user)

        await fixture.service.syncOnForeground(context: fixture.context)

        #expect(remote.calls == [.lookupE2E(user), .fetchIds(.accounts, user)]
            + SyncTable.allCases.map { .select($0, user) })
        #expect(try keyStore.load(userId: user) == nil)
        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).map(\.name) == [cloud.name])
    }

    @Test func foregroundAndRefreshEachResolveOnlyOnce() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try makeService()
        remote.e2eRows[user] = try makeRow()
        try keyStore.save(key, userId: user)
        let account = Account(name: "Locale", type: .conto)
        fixture.context.insert(account)
        try fixture.context.save()

        await fixture.service.syncOnForeground(context: fixture.context)
        #expect(remote.calls.filter { $0 == .lookupE2E(user) }.count == 1)
        #expect(remote.calls.contains(.vaultRows(.accounts, user)))
        await fixture.service.manualRefresh(context: fixture.context)
        #expect(remote.calls.filter { $0 == .lookupE2E(user) }.count == 2)
        #expect(remote.calls.filter { $0 == .vaultRows(.accounts, user) }.count == 2)
    }

    @Test func corruptLaterTableAbortsPullBeforeChangingLocalAccounts() async throws {
        defer { try? keyStore.remove(userId: user) }
        let fixture = try makeService()
        defer { fixture.service.clearLocalData(context: fixture.context) }
        remote.e2eRows[user] = try makeRow()
        try keyStore.save(key, userId: user)
        let local = Account(name: "Locale", type: .conto)
        fixture.context.insert(local)
        try fixture.context.save()
        let cloud = Account(name: "Cloud", type: .conto)
        let vault = VaultRemote(access: remote, dek: key, owner: user)
        try await vault.upsert([SBAccount(cloud, userId: user)], table: .accounts, userId: user)
        let broken = VaultRecord(id: UUID(), userId: user, kind: SyncTable.goals.kind, keyId: try VaultCrypto.keyId(dek: key), payload: "bt1.invalid")
        remote.records[broken.id] = broken

        await fixture.service.pull(context: fixture.context)

        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).map(\.id) == [local.id])
        #expect(fixture.service.status == .waitingForRetry(attempt: 1))
    }

    @Test func keychainScopesKeysByUserAndLogoutClearsOnlyCurrentKey() async throws {
        let otherUser = UUID()
        defer {
            try? keyStore.remove(userId: user)
            try? keyStore.remove(userId: otherUser)
        }
        let fixture = try makeService()
        try keyStore.save(key, userId: user)
        try keyStore.save(otherKey, userId: otherUser)
        try keyStore.save(otherKey, userId: user)
        #expect(try keyStore.load(userId: user)?.dek == otherKey)
        try keyStore.save(key, userId: user)
        #expect(try keyStore.load(userId: user)?.dek == key)
        try expectKeychainAttributes(userId: user)
        fixture.service.clearLocalData(context: fixture.context)
        fixture.service.clearLocalData(context: fixture.context)
        #expect(try keyStore.load(userId: user) == nil)
        #expect(try keyStore.load(userId: otherUser)?.dek == otherKey)
    }

    @Test func switchingUserClearsPreviousKeyAndKeepsIncomingKey() async throws {
        let otherUser = UUID()
        defer {
            try? keyStore.remove(userId: user)
            try? keyStore.remove(userId: otherUser)
        }
        let fixture = try makeService(previousUser: otherUser)
        let oldAccount = Account(name: "Conto precedente", type: .conto)
        fixture.context.insert(oldAccount)
        try fixture.context.save()
        try keyStore.save(key, userId: otherUser)
        try keyStore.save(otherKey, userId: user)
        remote.e2eRows[user] = try makeRow(dek: otherKey)

        await fixture.service.syncOnLogin(context: fixture.context)

        #expect(try keyStore.load(userId: otherUser) == nil)
        #expect(try keyStore.load(userId: user)?.dek == otherKey)
        #expect(fixture.service.e2eLockReason == nil)
        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).isEmpty)
        #expect(remote.calls.filter { $0 == .lookupE2E(user) }.count == 1)
        #expect(remote.records.isEmpty)
    }

    private func expectLocked(_ reason: E2EGate.LockReason, _ result: E2EGate.Resolution) throws {
        guard case .locked(let actual) = result.mode else {
            Issue.record("Expected locked mode")
            return
        }
        #expect(actual == reason)
        #expect(result.serverSupported == true)
    }

    private func expectKeychainAttributes(userId: UUID) throws {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrService as String: "com.bucktrail.e2e.dek",
            kSecAttrAccount as String: userId.uuidString.lowercased(),
            kSecReturnAttributes as String: true
        ]
        var result: CFTypeRef?
        #expect(SecItemCopyMatching(query as CFDictionary, &result) == errSecSuccess)
        let attributes = try #require(result as? [String: Any])
        #expect(attributes[kSecAttrAccessible as String] as? String
            == kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly as String)
        #expect(attributes[kSecAttrSynchronizable as String] as? Bool != true)
    }

    private func makeRow(state: E2EServerState = .active, dek: SymmetricKey? = nil,
                         version: Int = 1, kdf: String = "pbkdf2-sha256",
                         iterations: Int = VaultCrypto.defaultIterations, salt: String? = nil,
                         wrapped: String? = nil, userId: UUID? = nil) throws -> E2EServerRow {
        let dek = dek ?? key
        let passphrase = try VaultCrypto.wrap(dek, key: otherKey,
                                              aad: VaultCrypto.wrapAAD(.passphrase, userID: user))
        let recovery = try VaultCrypto.wrap(dek, key: otherKey,
                                            aad: VaultCrypto.wrapAAD(.recovery, userID: user))
        return E2EServerRow(userId: userId ?? user, state: state, version: version, kdf: kdf,
                            kdfIterations: iterations,
                            salt: salt ?? VaultCrypto.encodeBase64URL(Data(repeating: 1, count: 16)),
                            wrappedKeyPassphrase: wrapped ?? passphrase, wrappedKeyRecovery: recovery,
                            keyId: try VaultCrypto.keyId(dek: dek))
    }

    private func makeService(previousUser: UUID? = nil) throws -> Fixture {
        try Fixture(remote: remote, user: user, previousUser: previousUser)
    }

    @MainActor
    private final class Fixture {
        let store: ModelContainer
        let service: SyncService
        let defaultsName: String
        let defaults: UserDefaults

        var context: ModelContext { store.mainContext }

        init(remote: InMemoryRemote, user: UUID, previousUser: UUID?) throws {
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            defaultsName = "E2EGateTests.\(user)"
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set((previousUser ?? user).uuidString, forKey: "syncService.lastUserId")
            service = SyncService(remote: remote, userId: user, defaults: defaults,
                                  e2eLaunchArguments: ["MoneyTracker", "-E2EEnabled", "YES"])
        }

        isolated deinit {
            defaults.removePersistentDomain(forName: defaultsName)
        }
    }
}
