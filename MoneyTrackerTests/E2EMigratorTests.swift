import CryptoKit
import Foundation
import Supabase
import SwiftData
import Synchronization
import Testing
@testable import MoneyTracker

@MainActor
struct E2EMigratorTests {
    private static let phrase = "sentiero tra le betulle"
    private static let newPhrase = "sentiero lungo il torrente"

    @Test func t7ActivatesAllKindsAndWritesOneProtectedBackup() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate(transactions: 205)
        let expected = try f.snapshot()

        try await f.enable { step in
            if step == .a5 {
                #expect(f.remote.base.e2eRows[f.user]?.state == .migrating)
                #expect(f.remote.plainDeletes.isEmpty)
            }
        }
        try await f.expectActive(expected)
        #expect(f.remote.plainDeletes.allSatisfy { $0.state == .active && $0.count <= 100 })
        #expect(f.remote.plainDeletes.filter { $0.table == .transactions }.map(\.count) == [100, 100, 5])
        let uploads = f.remote.base.calls.compactMap { call -> Int? in
            if case .upsertVault(let count) = call { return count }
            return nil
        }
        #expect(uploads.contains(200))
        #expect(uploads.allSatisfy { $0 <= 200 })

        let files = try FileManager.default.contentsOfDirectory(at: f.backup, includingPropertiesForKeys: nil)
        let file = try #require(files.count == 1 ? files.first : nil)
        let attributes = try FileManager.default.attributesOfItem(atPath: file.path())
        let protection = attributes[.protectionKey]
        #if !targetEnvironment(simulator)
        #expect(protection != nil)
        #endif
        if let protection {
            let rawValue = (protection as? FileProtectionType)?.rawValue ?? (protection as? String)
            #expect(rawValue == FileProtectionType.complete.rawValue)
        }
        let backupRows = try VaultJSON.decoder.decode(E2EVerifier.Snapshot.self, from: Data(contentsOf: file))
        let receipt = try E2EVerifier.verify(local: expected, remote: backupRows)
        #expect(receipt.byKind.count == 5)
        #expect(receipt.combined.count == 64)
        f.service.clearLocalData(context: f.context)
        #expect(!FileManager.default.fileExists(atPath: f.backup.path()))
        #expect(try f.keyStore.load(userId: f.user) == nil)
    }

    @Test(arguments: [E2EMigrator.Step.a2, .a3, .a4, .a5, .a6, .a7])
    func t8ResumesActivationAfterEveryCheckpoint(step: E2EMigrator.Step) async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        await #expect(throws: Interrupted.self) {
            try await f.enable { if $0 == step { throw Interrupted() } }
        }
        #expect(f.marker?.direction == .enable)
        if step != .a7 {
            _ = try E2EVerifier.verify(local: expected, remote: try await f.readPlain())
        }
        if [E2EMigrator.Step.a2, .a3, .a4, .a5].contains(step) {
            #expect(f.remote.plainDeletes.isEmpty)
        }
        let restarted = f.newService()
        await restarted.pull(context: f.context)
        if step == .a2 {
            #expect(f.marker == nil)
            #expect(try f.keyStore.load(userId: f.user) == nil)
            try await f.enable(using: restarted)
        }
        await restarted.pull(context: f.context)
        try await f.expectActive(expected)
    }

    @Test(arguments: [E2EMigrator.Step.d3, .d4, .d5, .d6, .d7])
    func t8ResumesDisablingAfterEveryCheckpoint(step: E2EMigrator.Step) async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        try await f.enable()
        await #expect(throws: Interrupted.self) {
            try await f.disable { if $0 == step { throw Interrupted() } }
        }
        #expect(f.marker?.direction == .disable)
        let restarted = f.newService()
        await restarted.pull(context: f.context)
        await restarted.pull(context: f.context)
        try await f.expectPlain(expected)
    }

    @Test func t8ResumesPartiallyCompletedPlaintextCleanup() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        f.remote.failDeleteTable = .budgets
        await #expect(throws: Interrupted.self) { try await f.enable() }
        #expect(f.remote.base.e2eRows[f.user]?.state == .active)
        #expect(try await f.remote.fetchIds(table: .transactions, userId: f.user).isEmpty)
        #expect(try await !f.remote.fetchIds(table: .budgets, userId: f.user).isEmpty)
        let restarted = f.newService()
        await restarted.pull(context: f.context)
        await restarted.pull(context: f.context)
        try await f.expectActive(expected)
    }

    @Test func t9TamperedCiphertextFailsTwiceAndRollsBackWithoutDeletingPlaintext() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        f.remote.corruptVault = true
        await #expect(throws: E2EMigrator.Failure.verificationFailed) { try await f.enable() }
        #expect(f.remote.corruptedReads == 2)
        #expect(f.remote.plainDeletes.isEmpty)
        #expect(f.remote.base.calls.contains(.rollbackActivation(f.user)))
        #expect(!f.remote.base.calls.contains {
            if case .deleteVault = $0 { return true }
            return false
        })
        try await f.expectPlain(expected)
    }

    @Test func t9CancellationResumesRollbackAndPreservesPlaintext() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        await #expect(throws: Interrupted.self) {
            try await f.enable { if $0 == .a4 { throw Interrupted() } }
        }
        f.remote.failRollback = true
        await #expect(throws: Interrupted.self) {
            try await f.service.withE2EMigrator(context: f.context, authenticationReason: "") {
                try await $0.cancelEnable()
            }
        }
        #expect(f.marker?.phase == .rollingBack)
        #expect(f.remote.base.e2eRows[f.user]?.state == .migrating)
        #expect(!f.remote.base.records.isEmpty)
        let restarted = f.newService()
        await restarted.pull(context: f.context)
        await restarted.pull(context: f.context)
        #expect(f.remote.plainDeletes.isEmpty)
        try await f.expectPlain(expected)
    }

    @Test func t9DisablingRollbackVerifiesVaultAndReturnsToActiveBeforeDeletingPlaintext() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        try await f.enable()
        f.remote.corruptPlainWhileDisabling = true
        await #expect(throws: E2EMigrator.Failure.verificationFailed) { try await f.disable() }
        #expect(f.remote.corruptedReads == 2)
        #expect(f.remote.plainDeletes.allSatisfy { $0.state == .active })
        try await f.expectActive(expected)
    }

    @Test func disablingRollbackKeepsRowsWrittenByAnOldDevice() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        try await f.enable()
        let deletesBefore = f.remote.plainDeletes.count
        let orphan = Goal(name: "Da un client precedente", targetAmount: 50)
        await #expect(throws: E2EMigrator.Failure.verificationFailed) {
            try await f.disable { step in
                if step == .d3 {
                    f.remote.base.seed([SBGoal(orphan, userId: f.user)], table: .goals, userId: f.user)
                }
            }
        }
        #expect(f.remote.base.e2eRows[f.user]?.state == .active)
        #expect(f.marker?.phase == .rollingBack)
        #expect(f.remote.plainDeletes.count == deletesBefore)
        #expect(try await f.remote.fetchIds(table: .goals, userId: f.user).contains(orphan.id))
    }

    @Test func disableReconcilesKnownDeletionsAndCopiesNewVaultRow() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let localDeletion = Goal(name: "Cancellato qui", targetAmount: 8)
        f.context.insert(localDeletion)
        try f.context.save()
        let remoteDeletion = try #require(f.snapshot().goals.first { $0.id != localDeletion.id })
        let localDeletionID = localDeletion.id
        try await f.enable()
        await f.service.pull(context: f.context)
        f.context.delete(localDeletion)
        try f.context.save()
        let key = try #require(try f.keyStore.load(userId: f.user))
        let encrypted = VaultRemote(access: f.remote, dek: key.dek, owner: f.user)
        try await encrypted.delete(ids: [remoteDeletion.id], table: .goals, userId: f.user)

        let other = SBGoal(Goal(name: "Altro dispositivo", targetAmount: 20), userId: f.user)
        f.remote.beforeVaultIds = { table in
            guard table == .goals else { return }
            f.remote.beforeVaultIds = nil
            try await encrypted.upsert([other], table: .goals, userId: f.user)
        }

        try await f.disable()

        let local = try f.snapshot()
        let remote = try await f.readPlain()
        #expect(local.goals.map(\.id) == [other.id])
        #expect(!remote.goals.contains { $0.id == localDeletionID || $0.id == remoteDeletion.id })
        _ = try E2EVerifier.verify(local: local, remote: remote)
        #expect(f.remote.base.e2eRows[f.user] == nil)
        #expect(f.remote.base.records.isEmpty)
    }

    @Test func t10OldClientPushIsBlockedAndEmptyPullKeepsLocalData() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        try await f.enable()
        let callsBefore = f.remote.base.calls.count
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [OldClientURLProtocol.self]
        let client = SupabaseClient(supabaseURL: try #require(URL(string: "https://old-client.invalid")),
                                    supabaseKey: "stub", options: .init(global: .init(session: URLSession(configuration: config))))
        let legacy = SyncService(remote: PlainRemote(client: client), userId: f.user, defaults: f.defaults,
                                 e2eLaunchArguments: [])
        OldClientURLProtocol.requests.withLock { $0.removeAll() }
        #expect(!(await legacy.push(context: f.context)))
        await legacy.pull(context: f.context)
        #expect(OldClientURLProtocol.requests.withLock { $0 } == ["GET /rest/v1/mt_accounts", "POST /rest/v1/mt_accounts", "GET /rest/v1/mt_accounts"])
        _ = try E2EVerifier.verify(local: expected, remote: f.snapshot())
        #expect(f.remote.base.calls.count == callsBefore)
        try await f.expectActive(expected)
    }

    @Test func t11TwoDevicesSwitchModesThroughFirstLoginPath() async throws {
        let a = try Fixture()
        let b = try Fixture(remote: a.remote, user: a.user)
        defer { a.cleanup(); b.cleanup() }
        try a.populate()
        let expected = try a.snapshot()
        try await a.enable()
        let key = try #require(try a.keyStore.load(userId: a.user))
        // Both instances run in one test host. Remove A's key to emulate B's
        // separate keychain, then restore it at the end for A's next foreground.
        try a.keyStore.remove(userId: a.user)
        await b.service.pull(context: b.context)
        #expect(b.service.e2eLockReason == .needsSecret)
        try await b.unlock(.passphrase(Self.phrase))
        _ = try E2EVerifier.verify(local: expected, remote: b.snapshot())
        try await b.disable()
        try await b.expectPlain(expected)

        let localAccount = try #require(a.context.fetch(FetchDescriptor<Account>()).first)
        localAccount.name = "Valore locale obsoleto"
        try a.context.save()
        try a.keyStore.save(key.dek, userId: a.user)
        let count = a.remote.base.calls.count
        await a.service.syncOnForeground(context: a.context)
        #expect(a.service.e2eLockReason == .protectionRemoved)
        #expect(try a.keyStore.load(userId: a.user)?.keyId == key.keyId)
        #expect(!a.remote.base.calls.dropFirst(count).contains { if case .upsert = $0 { true } else { false } })
        #expect(await a.service.continueWithoutE2EProtection(context: a.context))
        _ = try E2EVerifier.verify(local: expected, remote: a.snapshot())
        #expect(try a.keyStore.load(userId: a.user) == nil)
        let calls = Array(a.remote.base.calls.dropFirst(count))
        let firstPull = try #require(calls.firstIndex(of: .select(.accounts, a.user)))
        // Edits queued while locked may be sent later, never before the first pull.
        #expect(!calls.prefix(firstPull).contains { if case .upsert = $0 { true } else { false } })
    }

    @Test func t11BlockedPlainWriteRechecksGate() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        try await f.enable()
        let transition = f.remote.base.e2eRows.removeValue(forKey: f.user)
        let active = try #require(transition)
        try f.keyStore.remove(userId: f.user)
        f.remote.base.transitionOnNextPlainWrite = active
        #expect(!(await f.service.pushResilient(context: f.context)))
        #expect(f.service.e2eLockReason == .needsSecret)
        #expect(f.service.status == .idle)
    }

    @Test func secondDeviceCanContinueActivationWithThePhrase() async throws {
        let a = try Fixture()
        let b = try Fixture(remote: a.remote, user: a.user)
        defer { a.cleanup(); b.cleanup() }
        try a.populate()
        let expected = try a.snapshot()
        await #expect(throws: Interrupted.self) {
            try await a.enable { if $0 == .a3 { throw Interrupted() } }
        }
        try a.keyStore.remove(userId: a.user)
        await b.service.pull(context: b.context)
        #expect(b.service.e2eLockReason == .transition)
        try await b.unlock(.passphrase(Self.phrase))
        try await b.expectActive(expected)
        _ = try E2EVerifier.verify(local: expected, remote: b.snapshot())
    }

    @Test func t13RecoveryRewrapRotationAndRestart() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let expected = try f.snapshot()
        try await f.enable()
        let original = try #require(f.remote.base.e2eRows[f.user])
        try f.keyStore.remove(userId: f.user)
        try await f.unlock(.recovery(f.recovery, newPassphrase: Self.newPhrase))
        let updated = try #require(f.remote.base.e2eRows[f.user])
        #expect(updated.keyId == original.keyId)
        #expect(updated.salt != original.salt)
        #expect(updated.wrappedKeyPassphrase != original.wrappedKeyPassphrase)
        #expect(updated.wrappedKeyRecovery == original.wrappedKeyRecovery)

        let rotated = try await f.action { try await $0.rotateRecoveryKey() }
        #expect(rotated != f.recovery)
        try f.keyStore.remove(userId: f.user)
        await #expect(throws: VaultCrypto.Failure.authenticationFailed) {
            try await f.unlock(.passphrase(Self.phrase))
        }
        await #expect(throws: VaultCrypto.Failure.authenticationFailed) {
            try await f.unlock(.recovery(f.recovery, newPassphrase: Self.phrase))
        }
        try await f.unlock(.passphrase(Self.newPhrase))
        try f.keyStore.remove(userId: f.user)
        try await f.unlock(.recovery(rotated, newPassphrase: Self.phrase))
        try f.keyStore.remove(userId: f.user)
        await f.service.pull(context: f.context)
        try await f.action { try await $0.restartFromDevice() }
        try await f.expectPlain(expected)
    }

    @Test func preflightUnalignedPlaintextNeverDeletesOrBeginsMigration() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let orphan = Goal(name: "Altro dispositivo", targetAmount: 20)
        f.remote.base.seed([SBGoal(orphan, userId: f.user)], table: .goals, userId: f.user)
        await #expect(throws: E2EVerifier.Failure.ids(.goals)) { try await f.enable() }
        #expect(f.remote.plainDeletes.isEmpty)
        #expect(f.remote.base.e2eRows[f.user] == nil)
        #expect(f.marker == nil)
        #expect(try await f.remote.fetchIds(table: .goals, userId: f.user).contains(orphan.id))
    }

    @Test func activationKeepsLocalOnlyTransactionsAndPullsCleanRemoteChanges() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate(transactions: 2, markDirty: false)
        let rows = try f.context.fetch(FetchDescriptor<Transaction>())
        let local = try #require(rows.first)
        let remote = try #require(rows.last)
        let originalName = remote.name
        remote.name = "Aggiornato da un altro dispositivo"
        f.remote.base.seed([SBTransaction(remote, userId: f.user)], table: .transactions, userId: f.user)
        remote.name = originalName
        try f.context.save()

        try await f.enable()
        let snapshot = try f.snapshot()
        #expect(snapshot.transactions.count == 2)
        #expect(snapshot.transactions.first { $0.id == remote.id }?.name == "Aggiornato da un altro dispositivo")
        #expect(snapshot.transactions.contains { $0.id == local.id })
        try await f.expectActive(snapshot)
    }

    @Test func emptyStoreRoundTripsAndAuthenticationDenialHasNoEffects() async throws {
        let f = try Fixture()
        defer { f.cleanup() }
        let expected = try f.snapshot()
        try await f.enable()
        try await f.expectActive(expected)
        await #expect(throws: Interrupted.self) {
            try await f.service.withE2EMigrator(context: f.context, authenticationReason: "",
                                               authenticateForTest: { throw Interrupted() }) {
                try await $0.disable()
            }
        }
        try await f.expectActive(expected)
        try await f.disable()
        try await f.expectPlain(expected)
    }

    @Test func receiptNormalizesDatesMoneyUUIDAndDistinguishesUTF8() throws {
        let f = try Fixture()
        defer { f.cleanup() }
        try f.populate()
        let tx = try #require(f.context.fetch(FetchDescriptor<Transaction>()).first)
        tx.date = Date(timeIntervalSince1970: 1_700_000_000)
        tx.amount = Decimal(string: "-1.235") ?? 0
        tx.transferGroupId = "ABCDEF00-0000-4000-8000-000000000001"
        tx.notes = "Café 日本"
        let snapshot = try f.snapshot()
        tx.date = tx.date.addingTimeInterval(0.001)
        tx.amount = Decimal(string: "-1.24") ?? 0
        tx.transferGroupId = tx.transferGroupId.lowercased()
        let receipt = try E2EVerifier.verify(local: snapshot, remote: f.snapshot())
        #expect(receipt == (try E2EVerifier.verify(local: snapshot, remote: snapshot)))
        tx.date = tx.date.addingTimeInterval(0.001)
        #expect(throws: E2EVerifier.Failure.fields(.transactions)) {
            try E2EVerifier.verify(local: snapshot, remote: f.snapshot())
        }
        tx.date = snapshot.transactions[0].date
        tx.notes = "Cafe\u{301} 日本"
        #expect(throws: E2EVerifier.Failure.fields(.transactions)) {
            try E2EVerifier.verify(local: snapshot, remote: f.snapshot())
        }
    }

    @Test func receiptMatchesCanonicalUTF8Vector() throws {
        let user = try #require(UUID(uuidString: "abcdef00-0000-4000-8000-000000000001"))
        let f = try Fixture(user: user)
        defer { f.cleanup() }
        let goal = Goal(name: "A/B 日本", targetAmount: try #require(Decimal(string: "500.125")), emoji: "🧾")
        goal.id = try #require(UUID(uuidString: "abcdef00-0000-4000-8000-000000000002"))
        goal.createdAt = Date(timeIntervalSince1970: 1_700_000_000.125)
        f.context.insert(goal)
        let snapshot = try f.snapshot()
        let receipt = try E2EVerifier.verify(local: snapshot, remote: snapshot)
        #expect(receipt.combined == "b513c49f5dc4941b8fc400e764ca49c1ea2b5b5c79878011a7d9a30eb9ed5fe6")
        #expect(receipt.combined == receipt.byKind["goal"])
    }

    private struct Interrupted: Error {}

    @MainActor
    private final class Fixture {
        let user: UUID
        let remote: Remote
        let defaultsName = "E2EMigratorTests.\(UUID())"
        let defaults: UserDefaults
        let store: ModelContainer
        let backup = FileManager.default.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        let keyStore = E2EKeyStore()
        let recovery: String
        lazy var service = newService()

        init(remote: Remote = Remote(), user: UUID = UUID()) throws {
            self.remote = remote
            self.user = user
            defaults = try #require(UserDefaults(suiteName: defaultsName))
            defaults.set(user.uuidString, forKey: "syncService.lastUserId")
            let schema = Schema(versionedSchema: SchemaV3.self)
            store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
            recovery = try E2EMigrator.makeRecoveryKey()
        }

        var context: ModelContext { store.mainContext }
        var marker: E2EMigrationMarker? { E2EMigrator.marker(in: defaults, userId: user) }

        func newService() -> SyncService {
            SyncService(remote: remote, userId: user, defaults: defaults,
                        e2eLaunchArguments: ["-E2EEnabled", "YES"], e2eBackupDirectory: backup)
        }

        func cleanup() {
            defaults.removePersistentDomain(forName: defaultsName)
            try? keyStore.remove(userId: user)
            try? FileManager.default.removeItem(at: backup)
        }

        func populate(transactions: Int = 1, markDirty: Bool = true) throws {
            let account = Account(name: "Conto 日本", type: .conto, initialBalance: 35)
            context.insert(account)
            for i in 0..<transactions {
                let transaction = Transaction(name: "Movimento \(i)", amount: 2, type: .uscita, account: account)
                transaction.notes = "Spesa 🧾"
                context.insert(transaction)
                if markDirty { service.markTransactionDirty(transaction.id) }
            }
            context.insert(Budget(category: "Casa", monthlyLimit: 30, month: 11, year: 2026, account: account))
            context.insert(Goal(name: "Viaggio", targetAmount: 500))
            context.insert(RecurringRule(name: "Affitto", amount: 20, type: "uscita",
                                         frequency: "mensile", startDate: .now))
            try context.save()
        }

        func action<T>(on other: SyncService? = nil, checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in },
                       _ operation: (E2EMigrator) async throws -> T) async throws -> T {
            try await (other ?? service).withE2EMigrator(context: context, authenticationReason: "",
                                                         checkpoint: checkpoint, authenticateForTest: {},
                                                         action: operation)
        }

        func enable(using other: SyncService? = nil,
                    checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in }) async throws {
            let last = try #require(recovery.split(separator: "-").last)
            try await action(on: other, checkpoint: checkpoint) {
                try await $0.enable(passphrase: phrase, recoveryKey: recovery, confirmation: String(last).lowercased())
            }
        }

        func disable(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in }) async throws {
            try await action(checkpoint: checkpoint) { try await $0.disable() }
        }

        func unlock(_ secret: E2EMigrator.Secret) async throws {
            try await action { try await $0.unlock(secret) }
        }

        func snapshot() throws -> E2EVerifier.Snapshot {
            try E2EVerifier.Snapshot(context: context, userId: user)
        }

        func readPlain() async throws -> E2EVerifier.Snapshot {
            try await E2EVerifier.Snapshot(remote: remote, userId: user)
        }

        func expectActive(_ expected: E2EVerifier.Snapshot) async throws {
            #expect(remote.base.e2eRows[user]?.state == .active)
            #expect(marker == nil)
            let key = try #require(try keyStore.load(userId: user))
            let encrypted = VaultRemote(access: remote.base, dek: key.dek, owner: user)
            let actual = try await E2EVerifier.Snapshot(remote: encrypted, userId: user)
            _ = try E2EVerifier.verify(local: expected, remote: actual)
            for table in SyncTable.allCases {
                #expect(try await remote.fetchIds(table: table, userId: user).isEmpty)
            }
        }

        func expectPlain(_ expected: E2EVerifier.Snapshot) async throws {
            #expect(remote.base.e2eRows[user] == nil)
            #expect(remote.base.records.values.filter { $0.userId == user }.isEmpty)
            #expect(try keyStore.load(userId: user) == nil)
            #expect(marker == nil)
            _ = try E2EVerifier.verify(local: expected, remote: try await readPlain())
        }
    }

    @MainActor
    private final class Remote: SyncRemote, E2EServerAccess, VaultAccess {
        let base = InMemoryRemote()
        var corruptVault = false
        var corruptPlainWhileDisabling = false
        var corruptedReads = 0
        var failDeleteTable: SyncTable?
        var failRollback = false
        var beforeVaultIds: ((SyncTable) async throws -> Void)?
        var plainDeletes: [(table: SyncTable, state: E2EServerState?, count: Int)] = []

        func fetchIds(table: SyncTable, userId: UUID) async throws -> Set<UUID> {
            try await base.fetchIds(table: table, userId: userId)
        }

        func select<Row: SyncRow>(table: SyncTable, userId: UUID) async throws -> [Row] {
            let rows: [Row] = try await base.select(table: table, userId: userId)
            if corruptPlainWhileDisabling, table == .transactions, base.e2eRows[userId]?.state == .disabling {
                corruptedReads += 1
                return []
            }
            return rows
        }

        func upsert<Row: SyncRow>(_ rows: [Row], table: SyncTable, userId: UUID) async throws {
            try await base.upsert(rows, table: table, userId: userId)
        }

        func delete(ids: [UUID], table: SyncTable, userId: UUID) async throws {
            if failDeleteTable == table {
                failDeleteTable = nil
                throw Interrupted()
            }
            plainDeletes.append((table, base.e2eRows[userId]?.state, ids.count))
            try await base.delete(ids: ids, table: table, userId: userId)
        }

        func lookup(userId: UUID) async throws -> E2EServerLookup { try await base.lookup(userId: userId) }
        func insert(_ row: E2EServerRow) async throws { try await base.insert(row) }
        func patch(_ changes: E2EServerPatch, userId: UUID) async throws { try await base.patch(changes, userId: userId) }
        func delete(userId: UUID) async throws { try await base.delete(userId: userId) }

        func vaultIds(table: SyncTable, userId: UUID, keyId: String) async throws -> Set<UUID> {
            try await beforeVaultIds?(table)
            return try await base.vaultIds(table: table, userId: userId, keyId: keyId)
        }

        func vaultRows(table: SyncTable, userId: UUID, keyId: String?) async throws -> [VaultRecord] {
            let rows = try await base.vaultRows(table: table, userId: userId, keyId: keyId)
            guard corruptVault, table == .transactions, let row = rows.first else { return rows }
            corruptedReads += 1
            // Change a byte of the authentication tag, keeping the envelope valid.
            var bytes = try VaultCrypto.decodeBase64URL(row.payload.dropFirst(4))
            bytes[bytes.index(before: bytes.endIndex)] ^= 1
            return [VaultRecord(id: row.id, userId: row.userId, kind: row.kind, keyId: row.keyId,
                                payload: "bt1." + VaultCrypto.encodeBase64URL(bytes))] + rows.dropFirst()
        }

        func upsertVault(_ rows: [VaultRecord]) async throws { try await base.upsertVault(rows) }

        func deleteVault(ids: [UUID], table: SyncTable, userId: UUID, keyId: String) async throws {
            try await base.deleteVault(ids: ids, table: table, userId: userId, keyId: keyId)
        }

        func rollbackActivation(ifCurrent row: E2EServerRow) async throws -> Bool {
            if failRollback {
                failRollback = false
                throw Interrupted()
            }
            return try await base.rollbackActivation(ifCurrent: row)
        }
    }
}

private final class OldClientURLProtocol: URLProtocol, @unchecked Sendable {
    static let requests = Mutex<[String]>([])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let method = request.httpMethod,
              let response = HTTPURLResponse(url: url, statusCode: method == "GET" ? 200 : 400,
                                             httpVersion: nil, headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        Self.requests.withLock { $0.append("\(method) \(url.path)") }
        let json = method == "GET" ? "[]" : #"{"code":"P0001","message":"bt_e2e_active"}"#
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
