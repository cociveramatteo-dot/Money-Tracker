import Foundation
import Supabase
import Synchronization
import Testing
@testable import MoneyTracker

@Suite(.serialized)
@MainActor
struct E2EServerTests {
    @Test func distinguishesMissingSchemaFromNetworkAndServerFailures() async throws {
        let fixture = try Fixture()
        defer { fixture.session.invalidateAndCancel() }

        for (status, body) in [
            (404, "gateway without JSON"),
            (404, #"{"code":"unknown","message":"Not found"}"#),
            (400, #"{"code":"PGRST205","message":"Table absent"}"#),
            (400, #"{"code":"42P01","message":"Table absent"}"#)
        ] {
            E2EURLProtocol.enqueue(status, body)
            let result = try await fixture.server.lookup(userId: fixture.user)
            guard case .unavailable = result else { Issue.record("Expected unavailable schema"); continue }
        }

        E2EURLProtocol.enqueue(200, "[]")
        let result = try await fixture.server.lookup(userId: fixture.user)
        guard case .absent = result else { Issue.record("Expected absent row"); return }

        E2EURLProtocol.enqueue(503, #"{"code":"PGRST205","message":"Service unavailable"}"#)
        do {
            _ = try await fixture.server.lookup(userId: fixture.user)
            Issue.record("Expected server error")
        } catch let error as HTTPError {
            #expect(error.response.statusCode == 503)
        }

        E2EURLProtocol.enqueue(nil, "")
        await #expect(throws: URLError.self) {
            _ = try await fixture.server.lookup(userId: fixture.user)
        }
        let requests = E2EURLProtocol.requests
        #expect(requests.count == 7)
        #expect(requests.allSatisfy {
            $0.httpMethod == "GET" && $0.url?.path == "/rest/v1/mt_e2e"
                && Self.query($0)["select"] == "*"
                && Self.query($0)["user_id"] == "eq.\(fixture.user.uuidString.lowercased())"
        })
    }

    @Test func readsInsertsPatchesAndDeletesOneUserRow() async throws {
        let fixture = try Fixture()
        defer { fixture.session.invalidateAndCancel() }

        let json = """
        [{"user_id":"\(fixture.user.uuidString.lowercased())","state":"migrating","version":1,
        "kdf":"pbkdf2-sha256","kdf_iterations":600000,"salt":"test",
        "wrapped_key_passphrase":"bt1.test","wrapped_key_recovery":"bt1.test",
        "key_id":"abcdef0123456789","updated_at":"2026-11-25T10:00:00.123+00:00"}]
        """
        E2EURLProtocol.enqueue(200, json)
        let result = try await fixture.server.lookup(userId: fixture.user)
        guard case .row(let row) = result else { Issue.record("Expected E2E row"); return }
        #expect(row.userId == fixture.user)
        #expect(row.state == .migrating)
        #expect(row.kdfIterations == 600_000)
        #expect(row.updatedAt != nil)

        E2EURLProtocol.enqueue(201, "")
        try await fixture.server.insert(row)
        E2EURLProtocol.enqueue(204, "")
        try await fixture.server.patch(E2EServerPatch(state: .active), userId: fixture.user)
        E2EURLProtocol.enqueue(204, "")
        try await fixture.server.delete(userId: fixture.user)
        let requests = E2EURLProtocol.requests
        try #require(requests.count == 4)
        #expect(requests.map(\.httpMethod) == ["GET", "POST", "PATCH", "DELETE"])
        #expect(requests.allSatisfy { $0.url?.path == "/rest/v1/mt_e2e" })
        #expect(requests[1].value(forHTTPHeaderField: "Prefer") == "return=minimal")
        #expect(Self.query(requests[1])["on_conflict"] == nil)
        for index in [0, 2, 3] {
            #expect(Self.query(requests[index])["user_id"] == "eq.\(fixture.user.uuidString.lowercased())")
        }
    }

    @Test func vaultRequestsArePagedAndScopedToUserAndKind() async throws {
        let fixture = try Fixture()
        defer { fixture.session.invalidateAndCancel() }
        // Id-only reads use 1000-row pages; full rows (ciphertext) use 200.
        let ids = (1...1001).compactMap {
            UUID(uuidString: String(format: "abcdef00-0000-4000-8000-%012x", $0))
        }
        try #require(ids.count == 1001)
        let page = try JSONEncoder().encode(ids.prefix(1000).map { ["id": $0] })
        E2EURLProtocol.enqueue(200, String(decoding: page, as: UTF8.self))
        E2EURLProtocol.enqueue(200, #"[{"id":"\#(ids[1000].uuidString)"}]"#)
        let vault = SupabaseVaultAccess(client: fixture.client)
        #expect(try await vault.vaultIds(table: .transactions, userId: fixture.user, keyId: "abcdef0123456789") == Set(ids))

        E2EURLProtocol.enqueue(204, "")
        try await vault.deleteVault(ids: [ids[0]], table: .transactions, userId: fixture.user, keyId: "abcdef0123456789")
        let requests = E2EURLProtocol.requests
        try #require(requests.count == 3)
        #expect(requests.map(\.httpMethod) == ["GET", "GET", "DELETE"])
        for request in requests {
            let query = Self.query(request)
            #expect(request.url?.path == "/rest/v1/mt_vault")
            #expect(query["user_id"] == "eq.\(fixture.user.uuidString.lowercased())")
            #expect(query["kind"] == "eq.transaction")
            #expect(query["key_id"] == "eq.abcdef0123456789")
        }
        #expect(Self.query(requests[0])["select"] == "id")
        #expect(Self.query(requests[0])["limit"] == "1000")
        #expect(Self.query(requests[1])["id"] == "gt.\(ids[999].uuidString.lowercased())")
        #expect(Self.query(requests[2])["id"] == "in.(\(ids[0].uuidString.lowercased()))")

        E2EURLProtocol.enqueue(200, "[]")
        #expect(try await vault.vaultRows(table: .transactions, userId: fixture.user, keyId: "abcdef0123456789").isEmpty)
        let full = try #require(E2EURLProtocol.requests.last)
        #expect(Self.query(full)["select"] == "*")
        #expect(Self.query(full)["limit"] == "200")
    }

    @Test func claimsExactGenerationAndActivatesViaRPCWithCounts() async throws {
        let fixture = try Fixture()
        defer { fixture.session.invalidateAndCancel() }
        let previous = "2026-11-26T10:00:00.123456+00:00"
        let next = "2026-11-26T10:00:01.123456Z"
        let row = E2EServerRow(userId: fixture.user, state: .migrating, version: 1, kdf: "pbkdf2-sha256",
                               kdfIterations: 600_000, salt: "test", wrappedKeyPassphrase: "bt1.test",
                               wrappedKeyRecovery: "bt1.test", keyId: "abcdef0123456789", updatedAt: previous)
        E2EURLProtocol.enqueue(200, "[]")
        #expect(try await !fixture.server.patch(E2EServerPatch(updatedAt: next), ifCurrent: row))
        E2EURLProtocol.enqueue(204, "")
        #expect(try await fixture.server.activate(ifCurrent: row, generation: next, counts: ["goal": 2, "rule": 0]))
        E2EURLProtocol.enqueue(400, #"{"code":"P0001","message":"bt_e2e_counts"}"#)
        #expect(try await !fixture.server.activate(ifCurrent: row, generation: next, counts: ["goal": 2]))

        let requests = E2EURLProtocol.requests
        try #require(requests.count == 3)
        #expect(requests[0].httpMethod == "PATCH")
        #expect(Self.query(requests[0])["updated_at"] == "eq.\(previous)")
        #expect(Self.query(requests[0])["key_id"] == "eq.\(row.keyId)")
        #expect(Self.query(requests[0])["state"] == "eq.migrating")
        #expect(requests.dropFirst().allSatisfy { $0.httpMethod == "POST" && $0.url?.path == "/rest/v1/rpc/mt_e2e_activate" })
        let data = try #require(E2EURLProtocol.activationBody)
        let body = try #require(JSONSerialization.jsonObject(with: data) as? [String: Any])
        #expect(body["p_from_generation"] as? String == previous)
        #expect(body["p_to_generation"] as? String == next)
        #expect(body["p_key_id"] as? String == row.keyId)
        #expect(body["p_counts"] as? [String: Int] == ["goal": 2, "rule": 0])
    }

    @Test func rollbackPostsExactGenerationAndMapsTransitionErrors() async throws {
        let fixture = try Fixture()
        defer { fixture.session.invalidateAndCancel() }
        let generation = "2026-11-26T10:00:00.123456+00:00"
        let row = E2EServerRow(userId: fixture.user, state: .migrating, version: 1, kdf: "pbkdf2-sha256",
                               kdfIterations: 600_000, salt: "test", wrappedKeyPassphrase: "bt1.test",
                               wrappedKeyRecovery: "bt1.test", keyId: "abcdef0123456789", updatedAt: generation)
        E2EURLProtocol.enqueue(204, "")
        #expect(try await fixture.server.rollbackActivation(ifCurrent: row))
        for message in ["bt_e2e_state_changed", "bt_e2e_use_rollback"] {
            E2EURLProtocol.enqueue(400, #"{"code":"P0001","message":"\#(message)"}"#)
            #expect(try await !fixture.server.rollbackActivation(ifCurrent: row))
        }
        let requests = E2EURLProtocol.requests
        #expect(requests.count == 3)
        #expect(requests.allSatisfy { $0.httpMethod == "POST" && $0.url?.path == "/rest/v1/rpc/mt_e2e_rollback" })
        let data = try #require(E2EURLProtocol.rollbackBody)
        let body = try #require(JSONSerialization.jsonObject(with: data) as? [String: String])
        #expect(body == ["p_key_id": row.keyId, "p_generation": generation])
    }

    private static func query(_ request: URLRequest) -> [String: String] {
        guard let url = request.url else { return [:] }
        let items = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        return Dictionary(uniqueKeysWithValues: items.compactMap { item in item.value.map { (item.name, $0) } })
    }

    @MainActor
    private struct Fixture {
        let user = UUID()
        let session: URLSession
        let client: SupabaseClient
        var server: E2EServer { E2EServer(client: client) }

        init() throws {
            E2EURLProtocol.reset()
            let config = URLSessionConfiguration.ephemeral
            config.protocolClasses = [E2EURLProtocol.self]
            session = URLSession(configuration: config)
            client = SupabaseClient(supabaseURL: try #require(URL(string: "https://e2e-http-tests.invalid")),
                                    supabaseKey: "fake-anon-key",
                                    options: .init(global: .init(session: session)))
        }
    }
}

private final class E2EURLProtocol: URLProtocol, @unchecked Sendable {
    private struct State {
        var requests: [URLRequest] = []
        var replies: [(Int?, String)] = []
        var activationBody: Data?
        var rollbackBody: Data?
    }

    private static let state = Mutex(State())

    static var requests: [URLRequest] { state.withLock { $0.requests } }
    static var activationBody: Data? { state.withLock { $0.activationBody } }

    static var rollbackBody: Data? { state.withLock { $0.rollbackBody } }

    static func reset() { state.withLock { $0 = State() } }

    static func enqueue(_ status: Int?, _ body: String) {
        state.withLock { $0.replies.append((status, body)) }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let path = request.url?.path
        let isActivation = path == "/rest/v1/rpc/mt_e2e_activate"
        let isRollback = path == "/rest/v1/rpc/mt_e2e_rollback"
        let body = isActivation || isRollback ? Self.readBody(request) : nil
        let reply = Self.state.withLock { state -> (Int?, String)? in
            state.requests.append(request)
            if isActivation, state.activationBody == nil { state.activationBody = body }
            if isRollback, state.rollbackBody == nil { state.rollbackBody = body }
            guard !state.replies.isEmpty else { return nil }
            return state.replies.removeFirst()
        }

        guard let (status, body) = reply, let status, let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: status, httpVersion: nil,
                                             headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.notConnectedToInternet))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(body.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readBody(_ request: URLRequest) -> Data? {
        if let body = request.httpBody { return body }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { return nil }
            if count == 0 { return body }
            body.append(contentsOf: buffer.prefix(count))
        }
    }
}
