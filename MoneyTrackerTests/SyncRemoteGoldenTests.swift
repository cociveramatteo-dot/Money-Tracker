import Foundation
import Supabase
import Synchronization
import Testing
@testable import MoneyTracker

@Suite(.serialized)
@MainActor
struct SyncRemoteGoldenTests {
    // From SyncService.swift before S-50d (2351c99): full-array SDK upserts with
    // default options (including the SDK's sorted columns query), selects of
    // id or *, and one scoped DELETE with id before
    // user_id. The installed SDK emits UTC timestamps without a zone suffix.
    // The existing DTOs omit nil optionals except on recurring rules.
    @Test func plainRemoteMatchesPreviousSDKRequests() async throws {
        let config = URLSessionConfiguration.ephemeral
        config.protocolClasses = [GoldenURLProtocol.self]
        let session = URLSession(configuration: config)
        defer { session.invalidateAndCancel() }
        let client = SupabaseClient(
            supabaseURL: try #require(URL(string: "https://sync-golden.invalid")),
            supabaseKey: "fake-anon-key",
            options: .init(global: .init(session: session))
        )
        let remote = PlainRemote(client: client)
        GoldenURLProtocol.requests.withLock { $0.removeAll() }

        let user = try #require(UUID(uuidString: "ABCDEF00-0000-4000-8000-000000000001"))
        let row = try #require(UUID(uuidString: "ABCDEF00-0000-4000-8000-000000000002"))
        let orphan = try #require(UUID(uuidString: "ABCDEF00-0000-4000-8000-000000000003"))
        let date = Date(timeIntervalSince1970: 1_700_000_000.125)
        let account = Account(name: "Conto", type: .conto, initialBalance: 10.25,
                              colorHex: "123ABC", isExcludedFromTotal: true)
        account.id = row
        account.createdAt = date

        let transaction = Transaction(name: "Caffè 日本", amount: 2.50, type: .uscita,
                                      category: "Casa", categoryIcon: "house", date: date,
                                      isDone: false, isFixed: true, isTransfer: true,
                                      transferGroupId: "g1", notes: "Nota", recurringFrequency: "mensile",
                                      templateId: "t1", account: account)
        transaction.id = row
        transaction.createdAt = date

        let budget = Budget(category: "Casa", categoryIcon: "house", monthlyLimit: 100.25,
                            month: 11, year: 2026)
        budget.id = row
        budget.createdAt = date

        let goal = Goal(name: "Viaggio", targetAmount: 500, currentAmount: 25.5, emoji: "✈️")
        goal.id = row
        goal.createdAt = date

        let rule = RecurringRule(id: row, name: "Affitto", amount: 123.25, type: "uscita",
                                 category: "Casa", categoryIcon: "house", notes: "Nota",
                                 isFixed: true, frequency: "mensile", startDate: date, createdAt: date)
        rule.startDate = date

        try await remote.upsert([SBAccount(account, userId: user)], table: .accounts, userId: user)
        try await remote.upsert([SBTransaction(transaction, userId: user)], table: .transactions, userId: user)
        try await remote.upsert([SBBudget(budget, userId: user)], table: .budgets, userId: user)
        try await remote.upsert([SBGoal(goal, userId: user)], table: .goals, userId: user)
        try await remote.upsert([SBRecurringRule(rule, userId: user)], table: .recurringRules, userId: user)

        for table in SyncTable.allCases {
            let ids = try await remote.fetchIds(table: table, userId: user)
            #expect(ids == [row, orphan])
        }

        let accounts: [SBAccount] = try await remote.select(table: .accounts, userId: user)
        let transactions: [SBTransaction] = try await remote.select(table: .transactions, userId: user)
        let budgets: [SBBudget] = try await remote.select(table: .budgets, userId: user)
        let goals: [SBGoal] = try await remote.select(table: .goals, userId: user)
        let rules: [SBRecurringRule] = try await remote.select(table: .recurringRules, userId: user)
        #expect(accounts.first?.initialBalance == 10.25)
        #expect(accounts.first?.createdAt == date)
        #expect(transactions.first?.accountId == row)
        #expect(budgets.first?.accountId == nil)
        #expect(goals.first?.deadline == nil)
        #expect(rules.first?.exceptionsJSON == "{}")

        for table in SyncTable.allCases {
            try await remote.delete(ids: [row, orphan], table: table, userId: user)
        }

        let tables = ["mt_accounts", "mt_transactions", "mt_budgets", "mt_goals", "mt_recurring_rules"]
        #expect(SyncTable.allCases.map(\.kind) == ["account", "transaction", "budget", "goal", "rule"])
        let requests = GoldenURLProtocol.requests.withLock { $0 }
        try #require(requests.count == 20)
        let scope = URLQueryItem(name: "user_id", value: "eq.ABCDEF00-0000-4000-8000-000000000001")
        for (index, table) in tables.enumerated() {
            let path = "/rest/v1/" + table
            #expect(requests[index].method == "POST")
            #expect(requests[index].path == path)
            let expectedBody = try #require(GoldenURLProtocol.rows[table])
            let expectedRows = try #require(JSONSerialization.jsonObject(with: Data(expectedBody.utf8)) as? [[String: Any]])
            let expectedRow = try #require(expectedRows.first)
            let columns = expectedRow.keys.sorted().joined(separator: ",")
            #expect(requests[index].query == [URLQueryItem(name: "columns", value: columns)])
            #expect(requests[index].prefer == "resolution=merge-duplicates,return=representation")

            for (offset, columns) in [(5, "id"), (10, "*")] {
                let request = requests[offset + index]
                #expect(request.method == "GET")
                #expect(request.path == path)
                #expect(request.query == [URLQueryItem(name: "select", value: columns), scope])
                #expect(request.body == nil)
            }

            let deletion = requests[15 + index]
            #expect(deletion.method == "DELETE")
            #expect(deletion.path == path)
            #expect(deletion.query == [
                URLQueryItem(name: "id", value: "in.(ABCDEF00-0000-4000-8000-000000000002,ABCDEF00-0000-4000-8000-000000000003)"),
                scope
            ])
            #expect(deletion.body == nil)
            #expect(deletion.prefer == "return=representation")
        }

        for (request, table) in zip(requests.prefix(5), tables) {
            let body = try #require(request.body)
            let expected = try #require(GoldenURLProtocol.rows[table])
            // Key ordering is incidental to JSONEncoder, so compare canonical JSON.
            let actualJSON = try canonicalJSON(body)
            let expectedJSON = try canonicalJSON(Data(expected.utf8))
            #expect(actualJSON == expectedJSON, "POST (table)")
        }
    }

    private func canonicalJSON(_ data: Data) throws -> String {
        let canonical = try JSONSerialization.data(
            withJSONObject: JSONSerialization.jsonObject(with: data), options: .sortedKeys
        )
        return String(decoding: canonical, as: UTF8.self)
    }
}

private final class GoldenURLProtocol: URLProtocol, @unchecked Sendable {
    struct Request: Sendable {
        let method: String?
        let path: String
        let query: [URLQueryItem]
        let prefer: String?
        let body: Data?
    }

    static let requests = Mutex<[Request]>([])
    static let rows = [
        "mt_accounts": """
        [{"id":"ABCDEF00-0000-4000-8000-000000000002","user_id":"ABCDEF00-0000-4000-8000-000000000001",
          "name":"Conto","type":"Conto Bancario","initial_balance":10.25,"color_hex":"123ABC",
          "created_at":"2023-11-14T22:13:20.125","is_archived":false,"is_excluded_from_total":true}]
        """,
        "mt_transactions": """
        [{"id":"ABCDEF00-0000-4000-8000-000000000002","user_id":"ABCDEF00-0000-4000-8000-000000000001",
          "account_id":"ABCDEF00-0000-4000-8000-000000000002","name":"Caffè 日本","amount":2.5,"type":"Uscita",
          "category":"Casa","category_icon":"house","date":"2023-11-14T22:13:20.125","is_done":false,
          "is_fixed":true,"is_transfer":true,"transfer_group_id":"g1","notes":"Nota","recurring_frequency":"mensile",
          "template_id":"t1","created_at":"2023-11-14T22:13:20.125"}]
        """,
        "mt_budgets": """
        [{"id":"ABCDEF00-0000-4000-8000-000000000002","user_id":"ABCDEF00-0000-4000-8000-000000000001",
          "category":"Casa","category_icon":"house","monthly_limit":100.25,"month":11,"year":2026,
          "created_at":"2023-11-14T22:13:20.125"}]
        """,
        "mt_goals": """
        [{"id":"ABCDEF00-0000-4000-8000-000000000002","user_id":"ABCDEF00-0000-4000-8000-000000000001",
          "name":"Viaggio","emoji":"✈️","target_amount":500,"current_amount":25.5,"is_completed":false,
          "created_at":"2023-11-14T22:13:20.125"}]
        """,
        "mt_recurring_rules": """
        [{"id":"ABCDEF00-0000-4000-8000-000000000002","user_id":"ABCDEF00-0000-4000-8000-000000000001",
          "name":"Affitto","type":"uscita","category":"Casa","category_icon":"house","notes":"Nota","amount":123.25,
          "is_fixed":true,"account_id":null,"frequency":"mensile","start_date":"2023-11-14T22:13:20.125",
          "end_date":null,"exceptions":"{}","materialized_through":null,"created_at":"2023-11-14T22:13:20.125"}]
        """
    ]

    override class func canInit(with request: URLRequest) -> Bool { true }
    override class func canonicalRequest(for request: URLRequest) -> URLRequest { request }

    override func startLoading() {
        guard let url = request.url,
              let response = HTTPURLResponse(url: url, statusCode: 200, httpVersion: nil,
                                             headerFields: ["Content-Type": "application/json"]) else {
            client?.urlProtocol(self, didFailWithError: URLError(.badURL))
            return
        }
        let query = URLComponents(url: url, resolvingAgainstBaseURL: false)?.queryItems ?? []
        let body: Data?
        do {
            body = try Self.readBody(request)
        } catch {
            client?.urlProtocol(self, didFailWithError: error)
            return
        }
        Self.requests.withLock {
            $0.append(Request(method: request.httpMethod, path: url.path, query: query,
                              prefer: request.value(forHTTPHeaderField: "Prefer"), body: body))
        }

        let json: String
        switch query.first(where: { $0.name == "select" })?.value {
        case "id":
            json = """
            [{"id":"ABCDEF00-0000-4000-8000-000000000002"},{"id":"ABCDEF00-0000-4000-8000-000000000003"}]
            """
        case "*":
            json = Self.rows[url.lastPathComponent] ?? "[]"
        default:
            json = "[]"
        }
        client?.urlProtocol(self, didReceive: response, cacheStoragePolicy: .notAllowed)
        client?.urlProtocol(self, didLoad: Data(json.utf8))
        client?.urlProtocolDidFinishLoading(self)
    }

    override func stopLoading() {}

    private static func readBody(_ request: URLRequest) throws -> Data? {
        if let data = request.httpBody { return data }
        guard let stream = request.httpBodyStream else { return nil }
        stream.open()
        defer { stream.close() }
        var body = Data()
        var buffer = [UInt8](repeating: 0, count: 4096)
        while true {
            let count = stream.read(&buffer, maxLength: buffer.count)
            if count < 0 { throw stream.streamError ?? URLError(.cannotDecodeRawData) }
            if count == 0 { return body }
            body.append(contentsOf: buffer.prefix(count))
        }
    }
}
