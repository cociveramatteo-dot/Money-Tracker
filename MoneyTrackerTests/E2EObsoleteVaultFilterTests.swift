import Foundation
import Supabase
import Synchronization
import Testing
@testable import MoneyTracker

@MainActor
struct E2EObsoleteVaultFilterTests {
    @Test func cleanupSelectsOnlyObsoleteVaultKeys() async throws {
        ObsoleteVaultURLProtocol.requests.withLock { $0.removeAll() }
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [ObsoleteVaultURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let client = SupabaseClient(supabaseURL: try #require(URL(string: "https://obsolete-vault.invalid")),
                                    supabaseKey: "fake-anon-key", options: .init(global: .init(session: session)))
        let user = UUID()
        let liveKey = "abcdef0123456789"
        let vault = SupabaseVaultAccess(client: client)
        try await vault.clearDeadVaultKeys(userId: user, liveKey: liveKey, validateSession: {}, requireCurrent: {})

        let requests = ObsoleteVaultURLProtocol.requests.withLock { $0 }
        #expect(requests.count == SyncTable.allCases.count)
        for (request, table) in zip(requests, SyncTable.allCases) {
            let url = try #require(request.url)
            let items = try #require(URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems)
            #expect(request.httpMethod == "GET")
            #expect(url.path == "/rest/v1/mt_vault")
            #expect(items.contains(URLQueryItem(name: "select", value: "id,key_id")))
            #expect(items.contains(URLQueryItem(name: "kind", value: "eq.\(table.kind)")))
            #expect(items.contains(URLQueryItem(name: "user_id", value: "eq.\(user.uuidString.lowercased())")))
            #expect(items.filter { $0.name == "key_id" } == [URLQueryItem(name: "key_id", value: "neq.\(liveKey)")])
        }
    }
}

private final class ObsoleteVaultURLProtocol: URLProtocol, @unchecked Sendable {
    static let requests = Mutex<[URLRequest]>([])

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        Self.requests.withLock { $0.append(request) }
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                             headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badServerResponse))
            return
        }

        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data("[]".utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}
}
