import Foundation
import SwiftData

// MARK: - TransactionType

enum TransactionType: String, Codable, CaseIterable {
    case uscita  = "Uscita"
    case entrata = "Entrata"

    var localizedName: String { NSLocalizedString(rawValue, comment: "") }
}

// MARK: - Transaction

@Model
final class Transaction {
    var id: UUID
    var name: String
    var amount: Decimal
    var type: String            // TransactionType.rawValue
    var category: String        // nome categoria (stringa libera)
    var categoryIcon: String    // SF Symbol name (copiato al salvataggio)
    var date: Date
    var isDone: Bool            // Fatto? false = pianificato
    var isFixed: Bool           // Spesa fissa (affitto, abbonamenti, ecc.)
    var isTransfer: Bool        // Trasferimento tra conti
    var transferGroupId: String // UUID stringa condiviso dai 2 leg dello stesso trasferimento
    var notes: String
    var recurringFrequency: String  // "": nessuna, "settimanale", "mensile", "annuale"
    var templateId: String          // UUID del template padre (vuoto se non generata da ricorrente)
    var createdAt: Date

    var account: Account?

    init(
        name: String,
        amount: Decimal,
        type: TransactionType,
        category: String = "Altro",
        categoryIcon: String = "circle.dotted",
        date: Date = Date(),
        isDone: Bool = true,
        isFixed: Bool = false,
        isTransfer: Bool = false,
        transferGroupId: String = "",
        notes: String = "",
        recurringFrequency: String = "",
        templateId: String = "",
        account: Account? = nil
    ) {
        self.id                 = UUID()
        self.name               = name
        self.amount             = amount
        self.type               = type.rawValue
        self.category           = category
        self.categoryIcon       = categoryIcon
        self.date               = date
        self.isDone             = isDone
        self.isFixed            = isFixed
        self.isTransfer         = isTransfer
        self.transferGroupId    = transferGroupId
        self.notes              = notes
        self.recurringFrequency = recurringFrequency
        self.templateId         = templateId
        self.createdAt          = Date()
        self.account            = account
    }

    var transactionType: TransactionType { TransactionType(rawValue: type) ?? .uscita }

    var signedAmount: Decimal {
        transactionType == .entrata ? amount : -amount
    }
}
