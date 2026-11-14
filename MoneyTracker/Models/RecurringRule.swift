import Foundation
import SwiftData

/// A new series, independent of legacy transaction templates. Account ID is not a relationship.
@Model
final class RecurringRule {
    var id: UUID
    var name: String
    var type: String
    var category: String
    var categoryIcon: String
    var notes: String
    var amount: Decimal
    var isFixed: Bool
    var accountId: UUID?
    var frequency: String
    var startDate: Date
    var endDate: Date?
    var exceptionsJSON: String
    var materializedThrough: Date?
    var createdAt: Date

    init(id: UUID = UUID(), name: String, amount: Decimal, type: String,
         category: String = "Altro", categoryIcon: String = "circle.dotted", notes: String = "",
         isFixed: Bool = false, accountId: UUID? = nil, frequency: String, startDate: Date,
         endDate: Date? = nil, exceptionsJSON: String = "{}", materializedThrough: Date? = nil,
         createdAt: Date = Date()) {
        let calculator = RecurrenceCalculator()
        self.id = id
        self.name = name
        self.amount = amount
        self.type = type
        self.category = category
        self.categoryIcon = categoryIcon
        self.notes = notes
        self.isFixed = isFixed
        self.accountId = accountId
        self.frequency = frequency
        self.startDate = calculator.noon(startDate)
        self.endDate = endDate.map(calculator.noon)
        self.exceptionsJSON = exceptionsJSON
        self.materializedThrough = materializedThrough
        self.createdAt = createdAt
    }
}
