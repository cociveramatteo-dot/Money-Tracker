import Foundation
import SwiftData

// MARK: - AccountType

enum AccountType: String, Codable, CaseIterable {
    case contanti    = "Contanti"
    case carta       = "Carta"
    case conto       = "Conto Bancario"
    case risparmio   = "Risparmio"
    case investimento = "Investimento"

    var localizedName: String { NSLocalizedString(rawValue, comment: "") }
}

// MARK: - Account

@Model
final class Account {
    var id: UUID
    var name: String
    var type: String
    var initialBalance: Decimal
    var colorHex: String
    var createdAt: Date
    var isArchived: Bool
    var isExcludedFromTotal: Bool   // se true, non contribuisce al saldo totale

    @Relationship(deleteRule: .cascade, inverse: \Transaction.account)
    var transactions: [Transaction]

    @Relationship(deleteRule: .cascade, inverse: \Budget.account)
    var budgets: [Budget]

    init(name: String, type: AccountType, initialBalance: Decimal = 0,
         colorHex: String = "000000", isExcludedFromTotal: Bool = false) {
        self.id                  = UUID()
        self.name                = name
        self.type                = type.rawValue
        self.initialBalance      = initialBalance
        self.colorHex            = colorHex
        self.createdAt           = Date()
        self.isArchived          = false
        self.isExcludedFromTotal = isExcludedFromTotal
        self.transactions        = []
        self.budgets             = []
    }

    var accountType: AccountType { AccountType(rawValue: type) ?? .conto }

    var emoji: String {
        switch accountType {
        case .contanti:     return "💵"
        case .carta:        return "💳"
        case .conto:        return "🏦"
        case .risparmio:    return "🐷"
        case .investimento: return "📈"
        }
    }

    // PERF-04: delegano alla cache O(1) invece di iterare `transactions` (O(n))
    // ad ogni lettura — vedi Domain/AccountBalanceCache.swift per il razionale completo.
    var currentBalance: Decimal { AccountBalanceCache.shared.currentBalance(for: self) }
    var futureBalance: Decimal { AccountBalanceCache.shared.futureBalance(for: self) }
    var plannedDelta: Decimal { futureBalance - currentBalance }
}
