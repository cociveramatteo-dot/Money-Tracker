import CryptoKit
import Foundation
import Supabase
import Testing
@testable import MoneyTracker

@MainActor
struct E2EStressTests {
    @Test func twentyThousandMovementsMigrateAndVerifyInMemory() async throws {
        let f = try LifecycleFixture(count: 20_000)
        let start = ContinuousClock.now
        try await f.enable()
        let migrated = ContinuousClock.now
        let local = try E2EVerifier.Snapshot(context: f.context, userId: f.user)
        let loaded = try f.keys.load(userId: f.user)
        let key = try #require(loaded)
        let transport = VaultRemote(access: f.remote, dek: key.dek, owner: f.user)
        let restored = try await E2EVerifier.Snapshot(remote: transport, userId: f.user)
        _ = try E2EVerifier.verify(local: local, remote: restored)
        #expect(restored.transactions.count == 20_000)
        #expect(f.remote.records.values.filter { $0.kind == "transaction" }.count == 20_000)
        #expect(try await f.remote.fetchIds(table: .transactions, userId: f.user).isEmpty)
        print("S-50l iOS : 20000 movimenti, migrazione \(start.duration(to: migrated)), lettura e verifica \(migrated.duration(to: .now))")
    }

    @Test func exceptionsNearEnvelopeLimitRoundTripAndOversizeFailsClosed() async throws {
        let f = try LifecycleFixture()
        let key = SymmetricKey(size: .bits256)
        let transport = VaultRemote(access: f.remote, dek: key, owner: f.user)
        func rule(notesLength: Int) -> SBRecurringRule {
            let data = #"{"2026-01-01":{"notes":""# + String(repeating: "x", count: notesLength) + #""}}"#
            return SBRecurringRule(RecurringRule(name: "Fixture", amount: 5, type: "uscita", frequency: "mensile",
                                                  startDate: Date(), exceptionsJSON: data), userId: f.user)
        }
        let near = rule(notesLength: 48_300)
        try await transport.upsert([near], table: .recurringRules, userId: f.user)
        let read: [SBRecurringRule] = try await transport.select(table: .recurringRules, userId: f.user)
        let matches = read.first?.exceptionsJSON == near.exceptionsJSON
        #expect(matches)
        let envelope = try #require(f.remote.records[near.id]?.payload.utf8.count)
        #expect((64_000..<65_536).contains(envelope))

        let oversized = rule(notesLength: 63_500)
        f.remote.seed([oversized], table: .recurringRules, userId: f.user)
        await #expect(throws: VaultCrypto.Failure.self) {
            try await transport.upsert([oversized], table: .recurringRules, userId: f.user)
        }
        #expect(f.remote.records[oversized.id] == nil)
        #expect(try await f.remote.fetchIds(table: .recurringRules, userId: f.user) == [oversized.id])
        print("S-50l iOS : busta accettata \(envelope) byte, exceptions eccedente rifiutata con il chiaro intatto")
    }

    @Test func networkLossAtEveryCheckpointRecoversWithoutLosingRows() async throws {
        let steps = E2EMigrator.Step.allCases
        for step in steps {
            let f = try LifecycleFixture(count: 1)
            let expected = try E2EVerifier.Snapshot(context: f.context, userId: f.user)
            let edited = try #require(expected.transactions.first)
            f.service.markTransactionDirty(edited.id)
            let enabling = step.rawValue.hasPrefix("a")
            if !enabling { try await f.enable() }
            let interrupt: (E2EMigrator.Step) throws -> Void = { actual in
                if actual == step { throw URLError(.networkConnectionLost) }
            }
            do {
                if enabling { try await f.enable(checkpoint: interrupt) }
                else { try await f.disable(checkpoint: interrupt) }
                Issue.record("Checkpoint \(step) did not simulate the network loss")
            } catch let error as URLError {
                #expect(error.code == .networkConnectionLost)
            }
            await f.service.manualRefresh(context: f.context)
            if enabling {
                if f.remote.e2eRows[f.user] == nil { try await f.enable() }
                let loaded = try f.keys.load(userId: f.user)
                let key = try #require(loaded)
                let transport = VaultRemote(access: f.remote, dek: key.dek, owner: f.user)
                let restored = try await E2EVerifier.Snapshot(remote: transport, userId: f.user)
                try #require(restored.transactions.count == 1, "Recovery after \(step)")
                _ = try E2EVerifier.verify(local: expected, remote: restored)
                #expect(try await f.remote.fetchIds(table: .transactions, userId: f.user).isEmpty)
            } else {
                if f.remote.e2eRows[f.user]?.state == .active { try await f.disable() }
                let restored = try await E2EVerifier.Snapshot(remote: f.remote, userId: f.user)
                try #require(restored.transactions.count == 1, "Recovery after \(step)")
                _ = try E2EVerifier.verify(local: expected, remote: restored)
                #expect(f.remote.e2eRows[f.user] == nil)
                #expect(f.remote.records.isEmpty)
            }
        }
        print("S-50l iOS : \(steps.count) interruzioni, ricevute verificate dopo ogni ripresa")
    }

    @Test func simultaneousActivationKeepsTheWinnerAndReportsK46ToTheLoser() async throws {
        let f = try LifecycleFixture()
        let server = RacingServer(remote: f.remote)
        let snapshot = try E2EVerifier.Snapshot(context: f.context, userId: f.user)
        let aKey = E2EKeyStore(service: UUID().uuidString)
        let bKey = E2EKeyStore(service: UUID().uuidString)
        defer {
            try? aKey.remove(userId: f.user)
            try? bKey.remove(userId: f.user)
        }
        let secondSuite = "LifecycleRace.\(f.user)"
        let secondDefaults = try #require(UserDefaults(suiteName: secondSuite))
        defer { secondDefaults.removePersistentDomain(forName: secondSuite) }
        func device(_ keyStore: E2EKeyStore, _ defaults: UserDefaults, _ directory: String) -> E2EMigrator {
            E2EMigrator(userId: f.user, defaults: defaults, keyStore: keyStore, server: server, vault: f.remote,
                        plain: f.remote, backupDirectory: f.root.appending(path: directory),
                        checkpoint: { _ in }, validateSession: {}, authenticate: {},
                        snapshot: { snapshot }, push: { _, _ in }, pull: { _, _ in }, initialSync: { _ in })
        }
        let a = device(aKey, f.defaults, "first")
        let b = device(bKey, secondDefaults, "second")
        let last = try #require(f.recovery.split(separator: "-").last.map(String.init))
        let loser = Task {
            try await a.enable(passphrase: LifecycleFixture.phrase, recoveryKey: f.recovery, confirmation: last)
        }
        await server.firstInsertReady()
        do {
            try await b.enable(passphrase: LifecycleFixture.phrase, recoveryKey: f.recovery, confirmation: last)
        } catch {
            server.releaseFirstInsert()
            _ = try? await loser.value
            throw error
        }
        server.releaseFirstInsert()
        do {
            try await loser.value
            Issue.record("Both devices activated protection")
        } catch {
            #expect(E2EController.issue(for: error) == .concurrentActivation)
        }
        let onlyWinnerHasKey = try aKey.load(userId: f.user) == nil && bKey.load(userId: f.user) != nil
        #expect(onlyWinnerHasKey)
        #expect(f.remote.e2eRows[f.user]?.state == .active)
    }
}

@MainActor
private final class RacingServer: E2EServerAccess {
    let remote: InMemoryRemote
    private var paused = false
    private var pending: CheckedContinuation<Void, Never>?
    private var ready: CheckedContinuation<Void, Never>?

    init(remote: InMemoryRemote) { self.remote = remote }

    func firstInsertReady() async {
        guard pending == nil else { return }
        await withCheckedContinuation { ready = $0 }
    }

    func releaseFirstInsert() {
        pending?.resume()
        pending = nil
    }

    func lookup(userId: UUID) async throws -> E2EServerLookup { try await remote.lookup(userId: userId) }

    func insert(_ row: E2EServerRow) async throws {
        if !paused {
            paused = true
            await withCheckedContinuation { continuation in
                pending = continuation
                ready?.resume()
                ready = nil
            }
        }
        if remote.e2eRows[row.userId] != nil {
            throw PostgrestError(code: "23505", message: "fixture conflict")
        }
        try await remote.insert(row)
    }

    func patch(_ changes: E2EServerPatch, userId: UUID) async throws {
        try await remote.patch(changes, userId: userId)
    }

    func delete(userId: UUID) async throws { try await remote.delete(userId: userId) }

    func rollbackActivation(ifCurrent row: E2EServerRow) async throws -> Bool {
        try await remote.rollbackActivation(ifCurrent: row)
    }
}
