import CryptoKit
import Foundation
import Testing
@testable import MoneyTracker

@MainActor
struct E2ERowInteropTests {
    private static let owner = UUID(uuidString: "abcdefab-cdef-4abc-8def-abcdefabcdef")!
    private static let keyBytes = Data(0xA0...0xBF)
    private static let key = SymmetricKey(data: keyBytes)

    #if DEBUG
    @Test func nativeDTORowsMatchSharedVectors() throws {
        let fixture = try Self.fixture()
        for (index, sample) in Self.nativeRows().enumerated() {
            let (table, row) = sample
            let plaintext = try VaultJSON.encoder.encode(row)
            let nonce = Data(repeating: 0, count: 11) + Data([UInt8(index + 1)])
            let aad = VaultCrypto.rowAAD(kind: table.kind, id: row.id, userID: Self.owner)
            let sealed = try VaultCrypto.sealForTest(plaintext, key: Self.key, aad: aad, nonce: nonce)
            let sample = try #require(fixture.cases.first { $0.kind == table.kind })
            #expect(sample.id == row.id)
            #expect(sample.ios.plaintext == String(decoding: plaintext, as: UTF8.self))
            #expect(sample.ios.nonceHex == Self.hex(nonce))
            #expect(sample.ios.sealed == sealed)
        }
    }
    #endif

    @Test func bothClientsDecodeAllVaultRows() async throws {
        let fixture = try Self.fixture()
        #expect(fixture.userId == Self.owner)
        #expect(fixture.keyHex == Self.hex(Self.keyBytes))
        #expect(fixture.cases.map(\.kind).sorted() == SyncTable.allCases.map(\.kind).sorted())

        let backend = InMemoryRemote()
        let vault = VaultRemote(access: backend, dek: Self.key, owner: Self.owner)
        var nonces = Set<String>()
        for sample in fixture.cases {
            let table = try #require(SyncTable.allCases.first { $0.kind == sample.kind })
            for (client, wire) in [("ios", sample.ios), ("android", sample.android)] {
                let label = "\(sample.kind)/\(client)"
                nonces.insert(wire.nonceHex)
                let aad = VaultCrypto.rowAAD(kind: table.kind, id: sample.id, userID: Self.owner)
                let combined = try VaultCrypto.decodeBase64URL(wire.sealed.dropFirst(4))
                #expect(Self.hex(combined.prefix(12)) == wire.nonceHex, "\(label)")
                let plaintext = try VaultCrypto.open(wire.sealed, key: Self.key, aad: aad)
                #expect(plaintext == Data(wire.plaintext.utf8), "\(label)")

                backend.records[sample.id] = VaultRecord(id: sample.id, userId: Self.owner, kind: table.kind, keyId: try VaultCrypto.keyId(dek: Self.key), payload: wire.sealed)
                let decoded = try await decode(table: table, via: vault)
                var observed = try normalize(decoded)
                for (field, value) in sample.expected where value == .null && observed[field] == nil {
                    // Some iOS DTOs encode nil by omitting a field. Android writes JSON null.
                    observed[field] = .null
                }
                #expect(observed == sample.expected, "\(label)")
            }
        }
        #expect(nonces.count == 10)
    }

    private func decode(table: SyncTable, via vault: VaultRemote) async throws -> Data {
        func read<Row: SyncRow>(_: Row.Type) async throws -> Row {
            let rows: [Row] = try await vault.select(table: table, userId: Self.owner)
            #expect(rows.count == 1)
            return try #require(rows.first)
        }

        let encoder = VaultJSON.encoder
        switch table {
        case .accounts: return try await encoder.encode(read(SBAccount.self))
        case .transactions: return try await encoder.encode(read(SBTransaction.self))
        case .budgets: return try await encoder.encode(read(SBBudget.self))
        case .goals: return try await encoder.encode(read(SBGoal.self))
        case .recurringRules:
            let rule = try await read(SBRecurringRule.self)
            #expect(RecurrenceExceptionCodec.decode(rule.exceptionsJSON)["2023-11-16"]?.skip == true)
            return try encoder.encode(rule)
        }
    }

    private func normalize(_ data: Data) throws -> [String: Scalar] {
        let fields = try JSONDecoder().decode([String: Scalar].self, from: data)
        return try Dictionary(uniqueKeysWithValues: fields.map { field, value in
            let normalized: Scalar
            switch (field, value) {
            case ("id", .text(let id)), ("user_id", .text(let id)), ("account_id", .text(let id)):
                normalized = .text(id.lowercased())
            case ("initial_balance", .number(let amount)), ("amount", .number(let amount)),
                 ("monthly_limit", .number(let amount)), ("target_amount", .number(let amount)),
                 ("current_amount", .number(let amount)):
                normalized = .text(NSDecimalNumber(decimal: amount).stringValue)
            case ("created_at", .text(let text)), ("date", .text(let text)), ("deadline", .text(let text)),
                 ("start_date", .text(let text)), ("end_date", .text(let text)), ("materialized_through", .text(let text)):
                let date = try VaultJSON.decoder.decode(Date.self, from: JSONEncoder().encode(text))
                normalized = .number(Decimal(Int64((date.timeIntervalSince1970 * 1_000).rounded())))
            default:
                normalized = value
            }
            return (field, normalized)
        })
    }

    private static func fixture() throws -> Rows {
        let bundle = Bundle(for: FixtureBundle.self)
        let url = try #require(bundle.url(forResource: "e2e-vectors-v1", withExtension: "json", subdirectory: "Fixtures")
            ?? bundle.url(forResource: "e2e-vectors-v1", withExtension: "json"))
        return try JSONDecoder().decode(Fixture.self, from: Data(contentsOf: url)).rows
    }

    private static func hex(_ bytes: Data) -> String {
        bytes.map { String(format: "%02x", $0) }.joined()
    }

    private final class FixtureBundle {}

    private struct Fixture: Decodable {
        let rows: Rows
    }

    private struct Rows: Decodable {
        let keyHex: String
        let userId: UUID
        let cases: [RowCase]

        enum CodingKeys: String, CodingKey {
            case keyHex = "key_hex"
            case userId = "user_id"
            case cases
        }
    }

    private struct RowCase: Decodable {
        let kind: String
        let id: UUID
        let expected: [String: Scalar]
        let ios: Wire
        let android: Wire
    }

    private struct Wire: Decodable {
        let nonceHex: String
        let plaintext: String
        let sealed: String

        enum CodingKeys: String, CodingKey {
            case nonceHex = "nonce_hex"
            case plaintext, sealed
        }
    }

    private enum Scalar: Decodable, Equatable {
        case text(String), number(Decimal), bool(Bool), null

        init(from decoder: any Decoder) throws {
            let value = try decoder.singleValueContainer()
            if value.decodeNil() {
                self = .null
            } else if let boolean = try? value.decode(Bool.self) {
                self = .bool(boolean)
            } else if let number = try? value.decode(Decimal.self) {
                self = .number(number)
            } else {
                self = .text(try value.decode(String.self))
            }
        }
    }

    private static func nativeRows() -> [(SyncTable, any SyncRow)] {
        func id(_ index: Int) -> UUID {
            UUID(uuidString: "76543210-abcd-4ef0-8123-abcdef00000\(index)")!
        }
        func date(_ millis: Int64) -> Date {
            Date(timeIntervalSince1970: Double(millis) / 1_000)
        }
        func amount(_ cents: Int) -> Decimal { Decimal(cents) / 100 }

        let created = date(1_700_000_000_125)
        let account = Account(name: "Conto 東京 🏦", type: .conto, initialBalance: amount(-4_567),
                              colorHex: "2468AC", isExcludedFromTotal: true)
        account.id = id(1)
        account.createdAt = created
        account.isArchived = true

        let transaction = Transaction(name: "Caffè 京都 ☕", amount: amount(-1_234), type: .uscita,
                                      category: "旅", categoryIcon: "airplane", date: date(1_700_123_456_789),
                                      isDone: false, notes: "Rimborso 日本 🧾")
        transaction.id = id(2)
        transaction.createdAt = created

        let budget = Budget(category: "食費 🍜", categoryIcon: "fork.knife", monthlyLimit: amount(9_214),
                            month: 11, year: 2026, account: account)
        budget.id = id(3)
        budget.createdAt = created

        let goal = Goal(name: "旅行 🚄", targetAmount: amount(38_276), currentAmount: amount(1_245), emoji: "🌸")
        goal.id = id(4)
        goal.createdAt = created

        let start = date(1_700_086_400_250)
        let rule = RecurringRule(id: id(5), name: "家賃 🏡", amount: amount(27_865), type: "Uscita",
                                 category: "Casa", categoryIcon: "house", notes: "例外あり",
                                 isFixed: true, frequency: "Mensile", startDate: start,
                                 exceptionsJSON: #"{"2023-11-16":{"skip":true}}"#,
                                 materializedThrough: date(1_700_345_600_750), createdAt: created)
        // Set an exact wire timestamp independent of the simulator time zone.
        rule.startDate = start

        return [
            (.accounts, SBAccount(account, userId: owner)), (.transactions, SBTransaction(transaction, userId: owner)),
            (.budgets, SBBudget(budget, userId: owner)), (.goals, SBGoal(goal, userId: owner)),
            (.recurringRules, SBRecurringRule(rule, userId: owner))
        ]
    }
}
