import Foundation
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct SyncServiceFlagOffTests {
    private let tables: [SyncTable] = [.accounts, .transactions, .budgets, .goals, .recurringRules]

    @Test func pushUploadsInOrderAndDeletesOnlyCurrentUsersOrphans() async throws {
        let fixture = try Fixture()
        let account = Account(name: "Conto", type: .conto)
        let dirty = Transaction(name: "Da inviare", amount: 2, type: .uscita, account: account)
        let unchanged = Transaction(name: "Già inviata", amount: 3, type: .uscita, account: account)
        let budget = Budget(category: "Casa", monthlyLimit: 25, month: 11, year: 2026, account: account)
        let goal = Goal(name: "Viaggio", targetAmount: 500)
        let rule = RecurringRule(name: "Affitto", amount: 10, type: "uscita",
                                 frequency: "mensile", startDate: Date())
        let orphan = Transaction(name: "Cancellata", amount: 1, type: .uscita)
        let secondUser = UUID()
        let context = fixture.context
        context.insert(account)
        context.insert(dirty)
        context.insert(unchanged)
        context.insert(budget)
        context.insert(goal)
        context.insert(rule)
        try context.save()
        fixture.service.markTransactionDirty(dirty.id)
        let user = fixture.user
        let remote = fixture.remote
        remote.seed([SBTransaction(unchanged, userId: user), SBTransaction(orphan, userId: user)],
                    table: .transactions, userId: user)
        remote.seed([SBTransaction(orphan, userId: secondUser)], table: .transactions, userId: secondUser)

        try SyncBaseline(user: user, tables: [SyncTable.transactions.kind: [orphan.id]]).save(to: fixture.defaults)

        #expect(!E2EFeature.isEnabled)
        #expect(await fixture.service.push(context: context))
        let expected: [InMemoryRemote.Call] = [
            .fetchIds(.accounts, user), .upsert(.accounts, user, [account.id]),
            .fetchIds(.transactions, user), .upsert(.transactions, user, [dirty.id]),
            .delete(.transactions, user, [orphan.id]),
            .fetchIds(.budgets, user), .upsert(.budgets, user, [budget.id]),
            .fetchIds(.goals, user), .upsert(.goals, user, [goal.id]),
            .fetchIds(.recurringRules, user), .upsert(.recurringRules, user, [rule.id])
        ]
        #expect(remote.calls == expected)
        #expect(try await remote.fetchIds(table: .transactions, userId: user) == [dirty.id, unchanged.id])
        #expect(try await remote.fetchIds(table: .transactions, userId: secondUser) == [orphan.id])
    }

    @Test func pullKeepsDirtyRowsAndReadsAllTablesInOrder() async throws {
        let fixture = try Fixture()
        let context = fixture.context
        let user = fixture.user
        let account = Account(name: "Conto", type: .conto)
        let dirty = Transaction(name: "Da inviare", amount: 2, type: .uscita, account: account)
        let obsolete = Transaction(name: "Cancellata", amount: 1, type: .uscita, account: account)
        context.insert(account)
        context.insert(dirty)
        context.insert(obsolete)
        try context.save()
        fixture.service.markTransactionDirty(dirty.id)
        let remoteAccount = Account(name: "Conto", type: .conto)
        remoteAccount.id = account.id
        let remoteTransaction = Transaction(name: "Dal remoto", amount: 5, type: .uscita, account: remoteAccount)
        fixture.remote.seed([SBAccount(remoteAccount, userId: user)], table: .accounts, userId: user)
        fixture.remote.seed([SBTransaction(remoteTransaction, userId: user)], table: .transactions, userId: user)

        await fixture.service.pull(context: context)

        #expect(fixture.remote.calls == tables.map { .select($0, user) })
        let remaining = try context.fetch(FetchDescriptor<Transaction>())
        #expect(Set(remaining.map(\.id)) == [dirty.id, remoteTransaction.id])
        #expect(remaining.first { $0.id == remoteTransaction.id }?.account?.id == account.id)
    }

    @Test func emptyRemotePullDoesNotDeleteLocalAccounts() async throws {
        let fixture = try Fixture()
        let context = fixture.context
        let account = Account(name: "Locale", type: .contanti)
        context.insert(account)
        try context.save()

        await fixture.service.pull(context: context)

        #expect(fixture.remote.calls == [.select(.accounts, fixture.user)])
        #expect(try context.fetch(FetchDescriptor<Account>()).map(\.id) == [account.id])
        #expect(fixture.service.shouldPull)
    }

    @Test func loginWithRemoteAccountsPullsAfterIdProbe() async throws {
        let fixture = try Fixture()
        let account = Account(name: "Remoto", type: .conto)
        let user = fixture.user
        fixture.remote.seed([SBAccount(account, userId: user)], table: .accounts, userId: user)

        await fixture.service.syncOnLogin(context: fixture.context)

        #expect(fixture.remote.calls == [.fetchIds(.accounts, user)] + tables.map { .select($0, user) })
        #expect(try fixture.context.fetch(FetchDescriptor<Account>()).map(\.id) == [account.id])
    }

    @Test(arguments: [false, true])
    func loginWithEmptyRemoteOrProbeFailurePushesLocalRecords(probeFails: Bool) async throws {
        let fixture = try Fixture()
        let account = Account(name: "Locale", type: .contanti)
        fixture.context.insert(account)
        try fixture.context.save()
        let user = fixture.user
        if probeFails {
            fixture.remote.failOnce = .fetchIds(.accounts, user)
        }

        await fixture.service.syncOnLogin(context: fixture.context)

        #expect(fixture.remote.calls == [.fetchIds(.accounts, user), .fetchIds(.accounts, user), .upsert(.accounts, user, [account.id])]
                + tables.dropFirst().map { .fetchIds($0, user) })
    }

    @Test func loginAsDifferentUserClearsLocalRecordsBeforePush() async throws {
        let fixture = try Fixture(previousUser: UUID())
        fixture.defaults.set(Date(), forKey: "syncService.lastPull")
        let context = fixture.context
        let account = Account(name: "Conto del precedente utente", type: .conto)
        let row = Transaction(name: "Movimento", amount: 2, type: .uscita, account: account)
        context.insert(account)
        context.insert(row)
        try context.save()
        fixture.service.markTransactionDirty(row.id)

        await fixture.service.syncOnLogin(context: context)

        let user = fixture.user
        #expect(fixture.remote.calls == [.fetchIds(.accounts, user)] + tables.map { .fetchIds($0, user) })
        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(fixture.defaults.string(forKey: "syncService.lastUserId") == user.uuidString)
        #expect(fixture.auditClears.count == 1)
        #expect(fixture.service.shouldPull)
    }

    @Test func failedIdReadStopsPushBeforeDeletionOrLaterTables() async throws {
        let fixture = try Fixture()
        let user = fixture.user
        fixture.remote.failOnce = .fetchIds(.accounts, user)

        #expect(await fixture.service.push(context: fixture.context) == false)
        #expect(fixture.remote.calls == [.fetchIds(.accounts, user)])
    }

    @MainActor
    private final class AuditClears {
        var count = 0
    }

    @MainActor
    private final class Fixture {
        let user = UUID()
        let remote = InMemoryRemote()
        let auditClears = AuditClears()
        let defaults: UserDefaults
        let defaultsName: String
        let store: ModelContainer
        let service: SyncService

        var context: ModelContext { store.mainContext }

        init(previousUser: UUID? = nil) throws {
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            defaultsName = "SyncServiceFlagOffTests.\(user.uuidString)"
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set((previousUser ?? user).uuidString, forKey: "syncService.lastUserId")
            service = SyncService(remote: remote, userId: user, defaults: defaults, clearAuditLog: { [auditClears] in
                auditClears.count += 1
            })
        }

        isolated deinit {
            defaults.removePersistentDomain(forName: defaultsName)
        }
    }
}
