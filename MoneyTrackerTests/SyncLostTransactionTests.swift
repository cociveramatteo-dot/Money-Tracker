import Combine
import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct SyncLostTransactionTests {
    @Test(arguments: [false, true])
    func manualRefreshAndForegroundKeepAndUploadNewTransactions(encrypted: Bool) async throws {
        let fixture = try Fixture(e2e: encrypted)
        defer { fixture.cleanup() }
        if encrypted { try await fixture.enableProtection() }

        let refreshID = try fixture.saveTransaction()
        await fixture.service.manualRefresh(context: fixture.context)
        try await fixture.expectUploaded(refreshID, encrypted: encrypted)

        let foregroundID = try fixture.saveTransaction()
        fixture.defaults.removeObject(forKey: "syncService.lastPull")
        await fixture.service.syncOnForeground(context: fixture.context)
        try await fixture.expectUploaded(foregroundID, encrypted: encrypted)
        #expect(try fixture.transactionIDs() == [refreshID, foregroundID])
    }

    @Test func initialE2ELoginDownloadsThenSchedulesUploadForDirtyTransaction() async throws {
        let fixture = try Fixture(e2e: true)
        defer { fixture.cleanup() }
        // Start with a populated vault as on a device that just unlocked it.
        let existingID = try fixture.saveTransaction()
        try await fixture.enableProtection()
        fixture.defaults.set(fixture.user.uuidString, forKey: fixture.service.initialSyncKey)
        let newID = try fixture.saveTransaction()

        await fixture.service.syncOnLogin(context: fixture.context)

        #expect(try fixture.transactionIDs() == [existingID, newID])
        #expect(fixture.service.dirtyTransactionIds.contains(newID))
        #expect(fixture.remote.records[newID] == nil)
        let scheduledPush = try #require(fixture.service.debounceTask)
        await scheduledPush.value
        try await fixture.expectUploaded(newID, encrypted: true)
    }

    @Test(arguments: [false, true])
    func volatileStoreSkipsLoginPullAndDownload(e2e: Bool) async throws {
        let fixture = try Fixture(e2e: e2e, volatileStore: true)
        defer { fixture.cleanup() }
        // Login would clear this store if it proceeded to account isolation.
        fixture.defaults.set(UUID().uuidString, forKey: SyncService.lastUserKey)
        let id = try fixture.saveTransaction()
        fixture.remote.seed([SBAccount(Account(name: "Remote", type: .conto), userId: fixture.user)],
                            table: .accounts, userId: fixture.user)

        await fixture.service.pull(context: fixture.context)
        await fixture.service.syncOnLogin(context: fixture.context)
        let downloaded = try await fixture.service.download(context: fixture.context, remote: fixture.remote,
                                                            userId: fixture.user)

        #expect(!downloaded)
        #expect(fixture.remote.calls.isEmpty)
        #expect(try fixture.transactionIDs() == [id])
        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).map(\.name) == ["Conto"])
    }

    @MainActor
    private final class Fixture {
        let user = UUID()
        let remote = InMemoryRemote()
        let defaultsName = "SyncLostTransactionTests.\(UUID())"
        let defaults: UserDefaults
        let backup = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let keyStore = E2EKeyStore()
        let store: ModelContainer
        let service: SyncService
        let account = Account(name: "Conto", type: .conto)

        init(e2e: Bool, volatileStore: Bool = false) throws {
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set(user.uuidString, forKey: SyncService.lastUserKey)
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema,
                                       configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            service = SyncService(remote: remote, userId: user, defaults: defaults,
                                  e2eLaunchArguments: ["-E2EEnabled", e2e ? "YES" : "NO"],
                                  e2eBackupDirectory: backup, e2eKeyStore: keyStore, volatileStore: volatileStore)
            context.insert(account)
            try context.save()
        }

        var context: ModelContext { store.mainContext }

        func saveTransaction() throws -> UUID {
            let subscription = NotificationCenter.default.publisher(for: ModelContext.didSave, object: context)
                .sink { [service, context] notification in
                    service.recordChanges(from: notification, context: context)
                }
            defer { subscription.cancel() }
            let transaction = Transaction(name: "Nuovo", amount: 4, type: .uscita, account: account)
            context.insert(transaction)
            try context.save()
            #expect(service.dirtyTransactionIds.contains(transaction.id))
            return transaction.id
        }

        func transactionIDs() throws -> Set<UUID> {
            Set(try context.fetch(FetchDescriptor<Transaction>()).map(\.id))
        }

        func expectUploaded(_ id: UUID, encrypted: Bool) async throws {
            if encrypted {
                #expect(remote.calls.contains { if case .upsertVault = $0 { true } else { false } })
                #expect(remote.records[id]?.kind == SyncTable.transactions.kind)
            } else {
                #expect(remote.calls.contains(.upsert(.transactions, user, [id])))
            }
            #expect(try transactionIDs().contains(id))
            #expect(!service.dirtyTransactionIds.contains(id))
        }

        func enableProtection() async throws {
            let recovery = try E2EMigrator.makeRecoveryKey()
            let confirmation = try #require(recovery.split(separator: "-").last)
            try await service.withE2EMigrator(context: context, authenticationReason: "", authenticateForTest: {}) {
                try await $0.enable(passphrase: "sentiero tra le betulle", recoveryKey: recovery,
                                    confirmation: String(confirmation))
            }
        }

        func cleanup() {
            service.debounceTask?.cancel()
            service.retryTask?.cancel()
            defaults.removePersistentDomain(forName: defaultsName)
            try? keyStore.remove(userId: user)
            try? FileManager.default.removeItem(at: backup)
        }
    }
}
