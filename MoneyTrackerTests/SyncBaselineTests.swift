import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct SyncBaselineTests {
    @Test(arguments: [false, true])
    func plansAllFiveCases(fullUpsert: Bool) {
        let deletedHere = UUID(), newRemote = UUID(), deletedElsewhere = UUID()
        let newLocal = UUID(), sharedDirty = UUID(), sharedClean = UUID()
        let local: Set<UUID> = [deletedElsewhere, newLocal, sharedDirty, sharedClean]
        let remote: Set<UUID> = [deletedHere, newRemote, sharedDirty, sharedClean]
        let dirty: Set<UUID> = [deletedElsewhere, sharedDirty]
        let plan = SyncBaseline.plan(local: local, remote: remote,
                                     base: [deletedHere, deletedElsewhere, sharedDirty, sharedClean],
                                     dirty: dirty, fullUpsert: fullUpsert)
        #expect(plan.upload == (fullUpsert ? [newLocal, sharedDirty, sharedClean] : [newLocal, sharedDirty]))
        #expect(plan.deleteRemote == [deletedHere])
        #expect(plan.deletedElsewhere == [deletedElsewhere])
        #expect(plan.newBase == [newLocal, sharedDirty, sharedClean])

        let bootstrap = SyncBaseline.plan(local: local, remote: remote, base: nil, dirty: dirty, fullUpsert: fullUpsert)
        #expect(bootstrap.upload == (fullUpsert ? local : dirty))
        #expect(bootstrap.deleteRemote.isEmpty)
        #expect(bootstrap.deletedElsewhere.isEmpty)
        #expect(bootstrap.newBase == remote.intersection(local).union(bootstrap.upload))
    }

    @Test(arguments: [false, true])
    func refreshPullsNewRemoteTransactionAndBudget(encrypted: Bool) async throws {
        let fixture = try await Fixture(encrypted: encrypted)
        defer { fixture.cleanup() }
        await fixture.service.pull(context: fixture.context)
        let tx = Transaction(name: "Remoto", amount: 5, type: .uscita, account: fixture.remoteAccount())
        let budget = Budget(category: "Casa", monthlyLimit: 25, month: 11, year: 2026, account: fixture.remoteAccount())
        try await fixture.transport.upsert([SBTransaction(tx, userId: fixture.user)],
                                           table: .transactions, userId: fixture.user)
        try await fixture.transport.upsert([SBBudget(budget, userId: fixture.user)], table: .budgets, userId: fixture.user)

        #expect(try fixture.context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(try fixture.context.fetchCount(FetchDescriptor<Budget>()) == 0)
        await fixture.service.manualRefresh(context: fixture.context)

        #expect(try await fixture.ids(.transactions) == [tx.id])
        #expect(try await fixture.ids(.budgets) == [budget.id])
        #expect(try fixture.context.fetch(FetchDescriptor<Transaction>()).map(\.id) == [tx.id])
        #expect(try fixture.context.fetch(FetchDescriptor<Budget>()).map(\.id) == [budget.id])
    }

    @Test(arguments: [false, true])
    func localDeletionPropagatesAfterPull(encrypted: Bool) async throws {
        let fixture = try await Fixture(encrypted: encrypted)
        defer { fixture.cleanup() }
        let id = try await fixture.seedTransactionAndPull()
        let local = try #require(fixture.context.fetch(FetchDescriptor<Transaction>()).first)
        fixture.context.delete(local)
        try fixture.context.save()

        #expect(await fixture.service.push(context: fixture.context))
        #expect(try await fixture.ids(.transactions).isEmpty)
        #expect(fixture.baseline.tables[SyncTable.transactions.kind]?.contains(id) == false)
    }

    @Test(arguments: [false, true])
    func remoteDeletionWinsAcrossRepeatedPushes(encrypted: Bool) async throws {
        let fixture = try await Fixture(encrypted: encrypted)
        defer { fixture.cleanup() }
        let id = try await fixture.seedTransactionAndPull()
        try await fixture.transport.delete(ids: [id], table: .transactions, userId: fixture.user)
        fixture.service.markTransactionDirty(id)

        #expect(await fixture.service.push(context: fixture.context))
        #expect(await fixture.service.push(context: fixture.context))
        #expect(try await fixture.ids(.transactions).isEmpty)
        #expect(!fixture.service.dirtyTransactionIds.contains(id))
        await fixture.service.pull(context: fixture.context)
        #expect(try fixture.context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(fixture.baseline.deletedElsewhere == nil)
    }

    @Test(arguments: [false, true])
    func firstPushPreservesUnknownRowsAndRecordsOnlySharedOrUploadedIds(encrypted: Bool) async throws {
        let fixture = try await Fixture(encrypted: encrypted)
        defer { fixture.cleanup() }
        let shared = Transaction(name: "Condiviso", amount: 1, type: .uscita, account: fixture.account)
        let unknown = Transaction(name: "Remoto", amount: 2, type: .uscita, account: fixture.remoteAccount())
        let dirty = Transaction(name: "Locale", amount: 3, type: .uscita, account: fixture.account)
        let unmarked = Transaction(name: "Locale senza marca", amount: 4, type: .uscita, account: fixture.account)
        fixture.context.insert(shared)
        fixture.context.insert(dirty)
        fixture.context.insert(unmarked)
        try fixture.context.save()
        fixture.service.markTransactionDirty(dirty.id)
        try await fixture.transport.upsert([shared, unknown].map { SBTransaction($0, userId: fixture.user) },
                                           table: .transactions, userId: fixture.user)
        fixture.defaults.removeObject(forKey: SyncBaseline.key)

        #expect(await fixture.service.push(context: fixture.context))
        #expect(try await fixture.ids(.transactions) == [shared.id, unknown.id, dirty.id])
        #expect(fixture.baseline.tables[SyncTable.transactions.kind] == [shared.id, dirty.id])
    }

    @Test func clearLocalStoreRemovesBaseline() async throws {
        let fixture = try await Fixture(encrypted: false)
        defer { fixture.cleanup() }
        await fixture.service.pull(context: fixture.context)
        #expect(fixture.defaults.data(forKey: SyncBaseline.key) != nil)
        #expect(fixture.service.clearLocalStore(context: fixture.context))
        #expect(fixture.defaults.data(forKey: SyncBaseline.key) == nil)
    }

    @Test func failedDeleteAndSkippedPullDoNotReplaceBaseline() async throws {
        let fixture = try await Fixture(encrypted: false)
        defer { fixture.cleanup() }
        let id = try await fixture.seedTransactionAndPull()
        let local = try #require(fixture.context.fetch(FetchDescriptor<Transaction>()).first)
        fixture.context.delete(local)
        try fixture.context.save()
        fixture.remote.failOnce = .delete(.transactions, fixture.user, [id])

        #expect(await fixture.service.push(context: fixture.context) == false)
        #expect(fixture.baseline.tables[SyncTable.transactions.kind] == [id])
        #expect(await fixture.service.push(context: fixture.context))
        #expect(try await fixture.ids(.transactions).isEmpty)

        try await fixture.transport.delete(ids: [fixture.account.id], table: .accounts, userId: fixture.user)
        await fixture.service.pull(context: fixture.context)
        #expect(fixture.baseline.tables[SyncTable.accounts.kind] == [fixture.account.id])
    }

    @MainActor
    private final class Fixture {
        let user = UUID()
        let remote = InMemoryRemote()
        let defaultsName = "SyncBaselineTests.\(UUID())"
        let defaults: UserDefaults
        let backup = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let keyStore = E2EKeyStore()
        let store: ModelContainer
        let service: SyncService
        let account = Account(name: "Conto", type: .conto)
        private(set) var transport: any SyncRemote

        var context: ModelContext { store.mainContext }
        var baseline: SyncBaseline { SyncBaseline.load(from: defaults, user: user) }

        init(encrypted: Bool) async throws {
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set(user.uuidString, forKey: SyncService.lastUserKey)
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema,
                                       configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            service = SyncService(remote: remote, userId: user, defaults: defaults,
                                  e2eLaunchArguments: ["-E2EEnabled", encrypted ? "YES" : "NO"],
                                  e2eBackupDirectory: backup, e2eKeyStore: keyStore)
            transport = remote
            store.mainContext.insert(account)
            try store.mainContext.save()
            remote.seed([SBAccount(account, userId: user)], table: .accounts, userId: user)
            if encrypted {
                let recovery = try E2EMigrator.makeRecoveryKey()
                let confirmation = try #require(recovery.split(separator: "-").last)
                try await service.withE2EMigrator(context: store.mainContext, authenticationReason: "", authenticateForTest: {}) {
                    try await $0.enable(passphrase: "sentiero tra le betulle", recoveryKey: recovery,
                                        confirmation: String(confirmation))
                }
                let key = try #require(try keyStore.load(userId: user)).dek
                transport = VaultRemote(access: remote, dek: key, owner: user)
            }
        }

        func ids(_ table: SyncTable) async throws -> Set<UUID> {
            try await transport.fetchIds(table: table, userId: user)
        }

        func remoteAccount() -> Account {
            let copy = Account(name: account.name, type: .conto)
            copy.id = account.id
            return copy
        }

        func seedTransactionAndPull() async throws -> UUID {
            let tx = Transaction(name: "Condiviso", amount: 2, type: .uscita, account: remoteAccount())
            try await transport.upsert([SBTransaction(tx, userId: user)], table: .transactions, userId: user)
            await service.pull(context: context)
            #expect(baseline.tables[SyncTable.transactions.kind] == [tx.id])
            return tx.id
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
