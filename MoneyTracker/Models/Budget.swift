import Foundation
import SwiftData

// MARK: - Budget

@Model
final class Budget {
    var id: UUID
    var category: String        // nome categoria (o "Tutti" per budget globale conto)
    var categoryIcon: String    // icona per display
    var monthlyLimit: Decimal
    var month: Int
    var year: Int
    var createdAt: Date

    // Budget per conto specifico (nil = budget per categoria su tutti i conti)
    @Relationship(deleteRule: .nullify)
    var account: Account?

    init(category: String, categoryIcon: String = "circle.dotted",
         monthlyLimit: Decimal, month: Int, year: Int, account: Account? = nil) {
        self.id           = UUID()
        self.category     = category
        self.categoryIcon = categoryIcon
        self.monthlyLimit = monthlyLimit
        self.month        = month
        self.year         = year
        self.createdAt    = Date()
        self.account      = account
    }
}
