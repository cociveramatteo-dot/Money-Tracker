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
        let ids = (1...201).compactMap {
            UUID(uuidString: String(format: "abcdef00-0000-4000-8000-%012x", $0))
        }
        try #require(ids.count == 201)
        let page = try JSONEncoder().encode(ids.prefix(200).map { ["id": $0] })
        E2EURLProtocol.enqueue(200, String(decoding: page, as: UTF8.self))
        E2EURLProtocol.enqueue(200, #"[{"id":"\#(ids[200].uuidString)"}]"#)
        let vault = SupabaseVaultAccess(client: fixture.client)
        #expect(try await vault.vaultIds(table: .transactions, userId: fixture.user) == Set(ids))

        E2EURLProtocol.enqueue(204, "")
        try await vault.deleteVault(ids: [ids[0]], table: .transactions, userId: fixture.user)
        let requests = E2EURLProtocol.requests
        try #require(requests.count == 3)
        #expect(requests.map(\.httpMethod) == ["GET", "GET", "DELETE"])
        for request in requests {
            let query = Self.query(request)
            #expect(request.url?.path == "/rest/v1/mt_vault")
            #expect(query["user_id"] == "eq.\(fixture.user.uuidString.lowercased())")
            #expect(query["kind"] == "eq.transaction")
        }
        #expect(Self.query(requests[0])["select"] == "id")
        #expect(Self.query(requests[0])["limit"] == "200")
        #expect(Self.query(requests[1])["id"] == "gt.\(ids[199].uuidString.lowercased())")
        #expect(Self.query(requests[2])["id"] == "in.(\(ids[0].uuidString.lowercased()))")
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
    }

    private static let state = Mutex(State())

    static var requests: [URLRequest] { state.withLock { $0.requests } }

    static func reset() { state.withLock { $0 = State() } }

    static func enqueue(_ status: Int?, _ body: String) {
        state.withLock { $0.replies.append((status, body)) }
    }

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        let reply = Self.state.withLock { state -> (Int?, String)? in
            state.requests.append(request)
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
}
