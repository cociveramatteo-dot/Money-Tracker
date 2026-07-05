import Foundation
import SwiftData

// MARK: - Goal

@Model
final class Goal {
    var id: UUID
    var name: String
    var emoji: String
    var targetAmount: Decimal
    var currentAmount: Decimal
    var deadline: Date?
    var isCompleted: Bool
    var createdAt: Date

    init(name: String, targetAmount: Decimal, currentAmount: Decimal = 0,
         emoji: String = "target", deadline: Date? = nil) {
        self.id            = UUID()
        self.name          = name
        self.emoji         = emoji
        self.targetAmount  = targetAmount
        self.currentAmount = currentAmount
        self.deadline      = deadline
        self.isCompleted   = false
        self.createdAt     = Date()
    }

    // Il progresso resta Double: alimenta ProgressView/UI che lavorano in [0, 1],
    // non serve precisione decimale oltre quella già garantita dalla divisione qui sotto.
    var progress: Double {
        guard targetAmount > 0 else { return 0 }
        let ratio = currentAmount / targetAmount
        return min(NSDecimalNumber(decimal: ratio).doubleValue, 1.0)
    }
    var remaining: Decimal { max(targetAmount - currentAmount, 0) }
}
