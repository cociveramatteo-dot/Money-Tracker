import CryptoKit
import Foundation
import OSLog
import SwiftData

enum E2EVerifier {
    enum Failure: Error, Equatable {
        case duplicateID(SyncTable)
        case count(SyncTable)
        case ids(SyncTable)
        case fields(SyncTable)
    }

    struct Snapshot: Codable {
        let accounts: [SBAccount]
        let transactions: [SBTransaction]
        let budgets: [SBBudget]
        let goals: [SBGoal]
        let rules: [SBRecurringRule]

        init(context: ModelContext, userId: UUID) throws {
            accounts = try context.fetch(FetchDescriptor<Account>()).map { SBAccount($0, userId: userId) }
            transactions = try context.fetch(FetchDescriptor<Transaction>()).map { SBTransaction($0, userId: userId) }
            budgets = try context.fetch(FetchDescriptor<Budget>()).map { SBBudget($0, userId: userId) }
            goals = try context.fetch(FetchDescriptor<Goal>()).map { SBGoal($0, userId: userId) }
            rules = try context.fetch(FetchDescriptor<RecurringRule>()).map { SBRecurringRule($0, userId: userId) }
        }

        init(remote: any SyncRemote, userId: UUID) async throws {
            accounts = try await remote.select(table: .accounts, userId: userId)
            transactions = try await remote.select(table: .transactions, userId: userId)
            budgets = try await remote.select(table: .budgets, userId: userId)
            goals = try await remote.select(table: .goals, userId: userId)
            rules = try await remote.select(table: .recurringRules, userId: userId)
        }

        func rows(_ table: SyncTable) -> [any SyncRow] {
            switch table {
            case .accounts: accounts
            case .transactions: transactions
            case .budgets: budgets
            case .goals: goals
            case .recurringRules: rules
            }
        }
    }

    struct Receipt: Equatable {
        let byKind: [String: String]
        let combined: String
    }

    // Compact UTF-8 JSON, object keys in lexical order, one object per line
    // prefixed with kind|lowercase-id|. Both hashes omit a trailing newline.
    static func verify(local: Snapshot, remote: Snapshot,
                       allowingMissingRemoteTransactions: Bool = false,
                       allowingRemoteSubset: Bool = false) throws -> Receipt {
        var before = [String: [String]]()
        var after = [String: [String]]()
        for table in SyncTable.allCases {
            let localRows = try normalize(local.rows(table), table: table)
            var actual = try normalize(remote.rows(table), table: table)
            // A0 can leave locally-only transactions for the full vault push.
            let expected = allowingRemoteSubset || (allowingMissingRemoteTransactions && table == .transactions)
                ? localRows.filter { actual[$0.key] != nil }
                : localRows
            guard expected.count == actual.count else { throw Failure.count(table) }
            guard expected.keys == actual.keys else { throw Failure.ids(table) }
            for (id, fields) in expected {
                guard var other = actual[id], fields.keys == other.keys else { throw Failure.fields(table) }
                for (key, field) in fields {
                    guard let value = other[key] else { throw Failure.fields(table) }
                    if dateKeys.contains(key), case .number(let lhs) = field, case .number(let rhs) = value,
                       abs(lhs - rhs) <= 1 {
                        // The local millisecond is the reference for this pair.
                        // Independent rounding cannot preserve every ±1 ms match.
                        other[key] = field
                    } else if field != value {
                        throw Failure.fields(table)
                    }
                }
                actual[id] = other
            }
            before[table.kind] = try lines(expected, table: table)
            after[table.kind] = try lines(actual, table: table)
        }
        let expectedReceipt = receipt(before)
        let actualReceipt = receipt(after)
        guard expectedReceipt == actualReceipt else { throw VaultCrypto.Failure.operationFailed }
        #if DEBUG
        // Hashes of plaintext content: diagnostic only, never in release builds.
        for kind in expectedReceipt.byKind.keys.sorted() {
            Logger.persistence.debug("E2E receipt \(kind, privacy: .public): \(expectedReceipt.byKind[kind] ?? "", privacy: .public)")
        }
        Logger.persistence.debug("E2E receipt combined: \(expectedReceipt.combined, privacy: .public)")
        #endif
        return expectedReceipt
    }

    static func digest(_ data: Data) -> String {
        SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined()
    }

    private static func receipt(_ kinds: [String: [String]]) -> Receipt {
        let combined = kinds.keys.sorted().flatMap { kinds[$0, default: []] }
        return Receipt(byKind: kinds.mapValues { digest(Data($0.joined(separator: "\n").utf8)) },
                       combined: digest(Data(combined.joined(separator: "\n").utf8)))
    }

    private static let dateKeys: Set<String> = [
        "created_at", "date", "deadline", "start_date", "end_date", "materialized_through"
    ]
    private static let idKeys: Set<String> = ["id", "user_id", "account_id", "transfer_group_id", "template_id"]
    private static let amountKeys: Set<String> = [
        "amount", "initial_balance", "monthly_limit", "target_amount", "current_amount"
    ]

    private static func normalize(_ rows: [any SyncRow], table: SyncTable) throws -> [UUID: [String: Field]] {
        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .custom { date, encoder in
            let ms = (date.timeIntervalSince1970 * 1_000).rounded()
            guard let millis = Int64(exactly: ms) else { throw VaultCrypto.Failure.malformed }
            var container = encoder.singleValueContainer()
            try container.encode(millis)
        }
        let decoder = JSONDecoder()
        var result = [UUID: [String: Field]]()
        for row in rows {
            var fields = try decoder.decode([String: Field].self, from: encoder.encode(row))
            for key in idKeys {
                if case .string(let id) = fields[key], UUID(uuidString: id) != nil {
                    fields[key] = .string(id.lowercased())
                }
            }
            for key in amountKeys {
                if case .number(var amount) = fields[key] {
                    var rounded = Decimal()
                    NSDecimalRound(&rounded, &amount, 2, .plain)
                    fields[key] = .number(rounded)
                }
            }
            // Synthesized DTOs may omit optional values; other clients send null.
            switch table {
            case .transactions, .budgets, .recurringRules:
                fields["account_id"] = fields["account_id"] ?? .null
            case .goals:
                fields["deadline"] = fields["deadline"] ?? .null
            case .accounts:
                break
            }
            guard result.updateValue(fields, forKey: row.id) == nil else { throw Failure.duplicateID(table) }
        }
        return result
    }

    private static func lines(_ rows: [UUID: [String: Field]], table: SyncTable) throws -> [String] {
        let encoder = JSONEncoder()
        encoder.outputFormatting = [.sortedKeys, .withoutEscapingSlashes]
        return try rows.map { id, fields in
            let json = try encoder.encode(fields)
            return "\(table.kind)|\(id.uuidString.lowercased())|\(String(decoding: json, as: UTF8.self))"
        }.sorted()
    }

    private enum Field: Codable, Equatable {
        case null, bool(Bool), number(Decimal), string(String)

        init(from decoder: Decoder) throws {
            let container = try decoder.singleValueContainer()
            if container.decodeNil() {
                self = .null
            } else if let value = try? container.decode(Bool.self) {
                self = .bool(value)
            } else if let value = try? container.decode(String.self) {
                self = .string(value)
            } else {
                self = .number(try container.decode(Decimal.self))
            }
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            switch self {
            case .null: try container.encodeNil()
            case .bool(let value): try container.encode(value)
            case .number(let value): try container.encode(value)
            case .string(let value): try container.encode(value)
            }
        }

        static func == (lhs: Field, rhs: Field) -> Bool {
            switch (lhs, rhs) {
            case (.null, .null): true
            case (.bool(let lhs), .bool(let rhs)): lhs == rhs
            case (.number(let lhs), .number(let rhs)): lhs == rhs
            case (.string(let lhs), .string(let rhs)): lhs.utf8.elementsEqual(rhs.utf8)
            default: false
            }
        }
    }
}
