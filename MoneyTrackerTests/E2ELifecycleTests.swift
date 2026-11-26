import CryptoKit
import Foundation
import Supabase
import Synchronization
import SwiftData
import Testing
@testable import MoneyTracker

@MainActor
struct E2ELifecycleTests {
    @Test(arguments: [true, false], [true, false])
    func userChangeRemovesBothKindsOfMovementBeforeSync(inMemory: Bool, encrypted: Bool) async throws {
        let previousUser = UUID()
        let currentUser = UUID()
        let root = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
        try FileManager.default.createDirectory(at: root, withIntermediateDirectories: true)
        defer { try? FileManager.default.removeItem(at: root) }

        let schema = Schema(versionedSchema: SchemaV3.self)
        let config = inMemory
            ? ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            : ModelConfiguration(schema: schema, url: root.appending(path: "test.store"))
        let store = try ModelContainer(for: schema, configurations: config)
        let context = store.mainContext
        let account = Account(name: "Previous account", type: .conto)
        let linked = Transaction(name: "Linked fixture", amount: 2, type: .uscita, account: account)
        let unlinked = Transaction(name: "Unlinked fixture", amount: 3, type: .uscita)
        context.insert(account)
        context.insert(linked)
        context.insert(unlinked)
        try context.save()

        let suite = "E2ELifecycleTests.\(currentUser)"
        let defaults = try #require(UserDefaults(suiteName: suite))
        defer { defaults.removePersistentDomain(forName: suite) }
        defaults.set(previousUser.uuidString, forKey: "syncService.lastUserId")
        let remote = InMemoryRemote()
        let keys = E2EKeyStore()
        let backup = root.appending(path: "backup")
        if encrypted {
            try keys.save(SymmetricKey(size: .bits256), userId: previousUser)
            try FileManager.default.createDirectory(at: backup, withIntermediateDirectories: true)
        }
        defer { try? keys.remove(userId: previousUser) }
        let service = SyncService(remote: remote, userId: currentUser, defaults: defaults,
                                  e2eLaunchArguments: encrypted ? ["-E2EEnabled", "YES"] : [],
                                  e2eBackupDirectory: backup)
        service.markTransactionDirty(linked.id)
        service.markTransactionDirty(unlinked.id)

        await service.syncOnLogin(context: context)

        #expect(try context.fetchCount(FetchDescriptor<Account>()) == 0)
        #expect(try context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        #expect(defaults.string(forKey: "syncService.lastUserId") == currentUser.uuidString)
        #expect(!remote.calls.isEmpty)
        if encrypted {
            let oldKeyRemoved = try keys.load(userId: previousUser) == nil
            #expect(oldKeyRemoved)
            #expect(!FileManager.default.fileExists(atPath: backup.path))
        }
        #expect(try await remote.fetchIds(table: .transactions, userId: currentUser).isEmpty)
        #expect(remote.calls.allSatisfy { call in
            if case .upsert(_, let user, _) = call { return user != currentUser }
            return true
        })
    }

    @Test func logoutRemovesSecretsAndNextLoginRequiresUnlock() async throws {
        let f = try LifecycleFixture()
        try await f.enable()
        let row = try #require(f.remote.e2eRows[f.user])
        try f.recordMarker(keyId: row.keyId)
        var closed = false

        await f.service.signOutAndClear(context: f.context, pushPending: false) { owner in
            #expect(owner == f.user)
            #expect(f.secretsHaveBeenErased())
            closed = true
        }

        #expect(closed)
        #expect(f.service.currentE2EProtection == nil)
        await f.service.syncOnLogin(context: f.context)
        #expect(f.service.e2eLockReason == .needsSecret)
        #expect(try f.context.fetchCount(FetchDescriptor<Transaction>()) == 0)
    }

    @Test(arguments: [false, true])
    func deleteAccountRequiresRpcAndContinuesAfterRevokedToken(rpcFails: Bool) async throws {
        let f = try LifecycleFixture(count: 1)
        try await f.enable()
        let row = try #require(f.remote.e2eRows[f.user])
        try f.recordMarker(keyId: row.keyId)
        let host = "\(rpcFails ? "rpc-fail" : "rpc-ok")-\(UUID().uuidString.lowercased()).invalid"
        let configuration = URLSessionConfiguration.ephemeral
        configuration.protocolClasses = [LifecycleURLProtocol.self]
        let client = SupabaseClient(
            supabaseURL: try #require(URL(string: "https://\(host)")), supabaseKey: "fixture",
            options: SupabaseClientOptions(auth: .init(accessToken: { "test-token" }),
                                           global: .init(session: URLSession(configuration: configuration)))
        )
        var signedOut = false
        var rejected = false
        do {
            try await f.service.deleteEncryptedAccount(context: f.context, deleteRemote: { owner in
                #expect(owner == f.user)
                try await SupabaseManager.deleteRemoteAccount(client: client)
            }, signOut: { owner in
                #expect(owner == f.user)
                #expect(f.secretsHaveBeenErased())
                signedOut = true
            })
        } catch {
            rejected = true
        }

        let requests = LifecycleURLProtocol.requests.withLock { $0.removeValue(forKey: host) ?? [] }
        let rpc = LifecycleURLProtocol.Request(method: "POST", path: "/rest/v1/rpc/delete_own_account",
                                               ownershipFilter: nil, pinnedAuthorization: true)
        if rpcFails {
            #expect(rejected && !signedOut)
            #expect(requests == [rpc])
            #expect(!f.secretsHaveBeenErased())
            #expect(E2EMigrator.marker(in: f.defaults, userId: f.user) != nil)
            #expect(FileManager.default.fileExists(atPath: f.backup.path))
            #expect(try f.context.fetchCount(FetchDescriptor<Transaction>()) == 1)
        } else {
            #expect(!rejected && signedOut)
            #expect(requests == [rpc])
            #expect(try f.context.fetchCount(FetchDescriptor<Transaction>()) == 0)
        }
    }
}

@MainActor
final class LifecycleFixture {
    let user = UUID()
    let root = URL.temporaryDirectory.appending(path: UUID().uuidString, directoryHint: .isDirectory)
    let defaults: UserDefaults
    let suite: String
    let store: ModelContainer
    let remote = InMemoryRemote()
    let service: SyncService
    let keys = E2EKeyStore()
    let recovery: String
    static let phrase = "test fixture phrase only"

    var context: ModelContext { store.mainContext }
    var backup: URL { root.appending(path: "backup") }

    init(count: Int = 0) throws {
        let schema = Schema(versionedSchema: SchemaV3.self)
        store = try ModelContainer(for: schema, configurations: ModelConfiguration(schema: schema, isStoredInMemoryOnly: true))
        recovery = try E2EMigrator.makeRecoveryKey()
        suite = "LifecycleFixture.\(user)"
        defaults = try #require(UserDefaults(suiteName: suite))
        defaults.set(user.uuidString, forKey: "syncService.lastUserId")
        service = SyncService(remote: remote, userId: user, defaults: defaults,
                              e2eLaunchArguments: ["-E2EEnabled", "YES"],
                              e2eBackupDirectory: root.appending(path: "backup"))
        if count > 0 {
            var account: Account?
            for i in 0..<count {
                if i.isMultiple(of: 100) {
                    let next = Account(name: "Fixture \(i / 100)", type: .conto)
                    context.insert(next)
                    account = next
                }
                let name = i == 0 ? String(repeating: "長い名前 🧾 ", count: 128) : "Movement \(i)"
                let row = Transaction(name: name, amount: 2, type: .uscita, account: account)
                context.insert(row)
            }
            try context.save()
            // A4 uploads the entire transaction snapshot, including local-only rows.
        }
    }

    func enable(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in }) async throws {
        let last = try #require(recovery.split(separator: "-").last.map(String.init))
        try await service.withE2EMigrator(context: context, authenticationReason: "", checkpoint: checkpoint) {
            try await $0.enable(passphrase: Self.phrase, recoveryKey: recovery, confirmation: last)
        }
    }

    func disable(checkpoint: @escaping (E2EMigrator.Step) throws -> Void = { _ in }) async throws {
        try await service.withE2EMigrator(context: context, authenticationReason: "", checkpoint: checkpoint,
                                          authenticateForTest: {}) { try await $0.disable() }
    }

    func recordMarker(keyId: String) throws {
        let marker = E2EMigrationMarker(direction: .enable, userId: user, keyId: keyId, startedAt: 0)
        defaults.set(try JSONEncoder().encode(marker), forKey: E2EMigrationMarker.defaultsKey)
    }

    func secretsHaveBeenErased() -> Bool {
        guard let noKey = try? (keys.load(userId: user) == nil) else { return false }
        return noKey && E2EMigrator.marker(in: defaults, userId: user) == nil
            && !FileManager.default.fileExists(atPath: backup.path)
    }

    isolated deinit {
        try? keys.remove(userId: user)
        defaults.removePersistentDomain(forName: suite)
        try? FileManager.default.removeItem(at: root)
    }
}

private final class LifecycleURLProtocol: URLProtocol, @unchecked Sendable {
    struct Request: Equatable, Sendable {
        let method: String
        let path: String
        let ownershipFilter: String?
        let pinnedAuthorization: Bool
    }

    static let requests = Mutex<[String: [Request]]>([:])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url, let host = url.host, host.hasSuffix(".invalid"),
              let method = request.httpMethod else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let filter = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems?
            .first { $0.name == "user_id" }?.value
        let recorded = Request(method: method, path: url.path, ownershipFilter: filter,
                               pinnedAuthorization: request.value(forHTTPHeaderField: "Authorization") == "Bearer test-token")
        Self.requests.withLock { $0[host, default: []].append(recorded) }

        let rejected = (host.hasPrefix("rpc-fail") && method == "POST") || url.path.hasSuffix("/mt_vault")
        let status = rejected ? 400 : 204
        let headers = ["Content-Type": "application/json"]
        guard let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil, headerFields: headers) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        if rejected { client?.urlProtocol(self, didLoad: Data(#"{"message":"fixture rejected"}"#.utf8)) }
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
