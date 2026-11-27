import Combine
import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct SyncAccountLinkTests {
    @Test func pullRepairsOnlyTheLostLinkAcrossTwoDevices() async throws {
        let user = UUID()
        let remote = InMemoryRemote()
        let first = try Device(user: user, remote: remote)
        let second = try Device(user: user, remote: remote)
        let account = Account(name: "Conto", type: .conto, initialBalance: 100)
        let lost = Transaction(name: "Da recuperare", amount: 12, type: .uscita, isDone: true, account: account)
        let intact = Transaction(name: "Integro", amount: 3, type: .uscita, isDone: true, account: account)
        first.context.insert(account)
        first.context.insert(lost)
        first.context.insert(intact)
        try first.context.save()
        first.service.dirtyTransactionIds = []
        let accountRow = SBAccount(account, userId: user)
        remote.seed([accountRow], table: .accounts, userId: user)
        remote.seed([SBTransaction(lost, userId: user)], table: .transactions, userId: user)
        try await remote.delete(ids: [account.id], table: .accounts, userId: user)
        remote.seed([accountRow], table: .accounts, userId: user)
        remote.seed([SBTransaction(intact, userId: user)], table: .transactions, userId: user)
        try SyncBaseline(user: user, tables: ["account": [account.id], "transaction": [lost.id, intact.id]])
            .save(to: first.defaults)

        await second.service.pull(context: second.context)
        #expect(try second.transactions().first { $0.id == lost.id }?.account == nil)
        #expect(await second.service.push(context: second.context))
        #expect(second.service.dirtyTransactionIds.isEmpty)
        #expect(!remote.calls.contains { if case .upsert(.transactions, _, _) = $0 { true } else { false } })

        await first.service.pull(context: first.context)
        let repaired: [SBTransaction] = try await remote.select(table: .transactions, userId: user)
        #expect(repaired.first { $0.id == lost.id }?.accountId == account.id)

        await second.service.pull(context: second.context)
        let transactions = try second.transactions()
        #expect(transactions.first { $0.id == lost.id }?.account?.id == account.id)
        #expect(transactions.first { $0.id == lost.id }?.account?.currentBalance == 85)
        #expect(remote.calls.filter { if case .repairLinks = $0 { true } else { false } } == [.repairLinks(user, [lost.id])])
        #expect(second.service.dirtyTransactionIds.isEmpty)

        // A deliberate unlink from D1 propagates to D2 and stays null.
        lost.account = nil
        try first.context.save()
        #expect(first.service.dirtyTransactionIds.contains(lost.id))
        #expect(await first.service.push(context: first.context))
        await second.service.pull(context: second.context)
        #expect(try second.transactions().first { $0.id == lost.id }?.account == nil)
        #expect(second.service.dirtyTransactionIds.isEmpty)
    }


    @Test func deletingAccountElsewherePreservesSurvivingMovementWithoutEcho() async throws {
        let user = UUID()
        let remote = InMemoryRemote()
        let device = try Device(user: user, remote: remote)
        let account = Account(name: "Ultimo conto", type: .conto)
        let movement = Transaction(name: "Rimane sul server", amount: 12, type: .uscita, account: account)
        remote.seed([SBAccount(account, userId: user)], table: .accounts, userId: user)
        remote.seed([SBTransaction(movement, userId: user)], table: .transactions, userId: user)

        await device.service.pull(context: device.context)
        try await remote.delete(ids: [account.id], table: .accounts, userId: user)
        await device.service.pull(context: device.context)
        #expect(try device.context.fetchCount(FetchDescriptor<Account>()) == 0)
        let surviving = try #require(device.transactions().first)
        #expect(surviving.id == movement.id)
        #expect(surviving.account == nil)
        #expect(device.service.dirtyTransactionIds.isEmpty)
        #expect(await device.service.push(context: device.context))
        #expect(!remote.calls.contains { if case .upsert = $0 { true } else { false } })
    }

    @Test(arguments: [false, true])
    func accountDeletionRequiresAnExplicitChoice(explicit: Bool) async throws {
        let user = UUID()
        let remote = InMemoryRemote()
        let device = try Device(user: user, remote: remote)
        let account = Account(name: "Conto condiviso", type: .conto)
        let movement = Transaction(name: "Dipendente", amount: 12, type: .uscita, account: account)
        remote.seed([SBAccount(account, userId: user)], table: .accounts, userId: user)
        remote.seed([SBTransaction(movement, userId: user)], table: .transactions, userId: user)
        await device.service.pull(context: device.context)
        let local = try #require(device.context.fetch(FetchDescriptor<Account>()).first)
        if explicit {
            device.service.deleteLedgerAccount(local, context: device.context)
        } else {
            device.context.delete(local)
            try device.context.save()
        }
        #expect(await device.service.push(context: device.context))
        let deletes = remote.calls.filter { if case .delete = $0 { true } else { false } }
        #expect(deletes == (explicit ? [
            .delete(.transactions, user, [movement.id]), .delete(.accounts, user, [account.id])
        ] : []))
    }

    @MainActor private final class Device {
        let container: ModelContainer
        let defaults: UserDefaults
        let service: SyncService
        private var observer: AnyCancellable?
        private let suite = "SyncAccountLinkTests.\(UUID())"
        var context: ModelContext { container.mainContext }

        init(user: UUID, remote: InMemoryRemote) throws {
            let schema = Schema(versionedSchema: SchemaV3.self)
            container = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            defaults = try #require(UserDefaults(suiteName: suite))
            defaults.set(user.uuidString, forKey: SyncService.lastUserKey)
            service = SyncService(remote: remote, userId: user, defaults: defaults, e2eLaunchArguments: ["-E2EEnabled", "NO"])
            observer = NotificationCenter.default.publisher(for: ModelContext.didSave, object: context)
                .sink { [weak self] notification in
                    guard let self else { return }
                    service.recordChanges(from: notification, context: context)
                }
        }

        func transactions() throws -> [Transaction] { try context.fetch(FetchDescriptor<Transaction>()) }
    }
}
