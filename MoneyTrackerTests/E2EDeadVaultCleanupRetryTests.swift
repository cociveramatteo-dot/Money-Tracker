import CryptoKit
import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct E2EDeadVaultCleanupRetryTests {
    @Test(arguments: [false, true])
    func retriesAfterA4Failure(duringDisable: Bool) async throws {
        let user = UUID()
        let suite = "E2EDeadVaultCleanupRetryTests.\(user)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        let backup = FileManager.default.temporaryDirectory.appending(path: suite)
        let keyStore = E2EKeyStore(service: suite)
        defer {
            defaults.removePersistentDomain(forName: suite)
            try? keyStore.remove(userId: user)
            try? FileManager.default.removeItem(at: backup)
        }
        defaults.set(user.uuidString, forKey: "syncService.lastUserId")
        let schema = Schema(versionedSchema: SchemaV3.self)
        let container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        let context = container.mainContext
        let live = Account(name: "Conto vivo", type: .conto)
        context.insert(live)
        try context.save()

        let remote = InMemoryRemote()
        let service = SyncService(remote: remote, userId: user, defaults: defaults,
                                  e2eLaunchArguments: ["-E2EEnabled", "YES"], e2eBackupDirectory: backup,
                                  e2eKeyStore: keyStore)
        let obsolete = Account(name: "Conto rimosso", type: .conto)
        let oldVault = VaultRemote(access: remote, dek: SymmetricKey(size: .bits256), owner: user)
        try await oldVault.upsert([SBAccount(obsolete, userId: user)], table: .accounts, userId: user)
        let deleteObsolete = InMemoryRemote.Call.deleteVault(.accounts, user, [obsolete.id])
        remote.failOnce = deleteObsolete

        let recovery = try E2EMigrator.makeRecoveryKey()
        let confirmation = String(try #require(recovery.split(separator: "-").last))
        try await service.withE2EMigrator(context: context, authenticationReason: "", authenticateForTest: {}) {
            try await $0.enable(passphrase: "sentiero tra le betulle", recoveryKey: recovery, confirmation: confirmation)
        }

        #expect(remote.failOnce == nil)
        #expect(remote.calls.filter { $0 == deleteObsolete }.count == 1)
        #expect(remote.records[obsolete.id] != nil)
        let liveRecord = try #require(remote.records[live.id])
        #expect(liveRecord.keyId == remote.e2eRows[user]?.keyId)

        if duringDisable {
            try await service.withE2EMigrator(context: context, authenticationReason: "", authenticateForTest: {}) {
                try await $0.disable()
            }
            #expect(remote.e2eRows[user] == nil)
            #expect(remote.records[live.id] == nil)
            let plain: [SBAccount] = try await remote.select(table: .accounts, userId: user)
            #expect(plain.map(\.id) == [live.id])
        } else {
            remote.failOnce = .vaultRows(.accounts, user)
            await service.pull(context: context)
            #expect(remote.calls.filter { $0 == deleteObsolete }.count == 1)
            #expect(remote.records[obsolete.id] != nil)

            await service.pull(context: context)
            #expect(service.status == .idle)
            #expect(remote.records[live.id]?.payload == liveRecord.payload)
        }
        #expect(remote.calls.filter { $0 == deleteObsolete }.count == 2)
        #expect(remote.records[obsolete.id] == nil)
        #expect(try context.fetch(FetchDescriptor<Account>()).map(\.id) == [live.id])
    }
}


// Model the real id,key_id projection separately from a ciphertext read.
// Otherwise the default VaultAccess implementation records both as full pulls.
extension InMemoryRemote {
    func vaultKeyRows(table: SyncTable, userId: UUID) async throws -> [VaultKeyRow] {
        records.values.compactMap { record in
            guard record.userId == userId, record.kind == table.kind else { return nil }
            return VaultKeyRow(id: record.id, keyId: record.keyId)
        }
    }
}
