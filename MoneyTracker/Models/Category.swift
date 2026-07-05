import Foundation
import SwiftData

// MARK: - Category (user-manageable)

@Model
final class Category {
    var id: UUID
    var name: String
    var icon: String        // SF Symbol name
    var isDefault: Bool     // default categories non eliminabili
    var sortOrder: Int
    var createdAt: Date

    init(name: String, icon: String, isDefault: Bool = false, sortOrder: Int = 0) {
        self.id        = UUID()
        self.name      = name
        self.icon      = icon
        self.isDefault = isDefault
        self.sortOrder = sortOrder
        self.createdAt = Date()
    }
}

// MARK: - Default Categories

extension Category {
    static let defaults: [(name: String, icon: String, order: Int)] = [
        ("Cibo",         "fork.knife",             0),
        ("Trasporti",    "car.fill",               1),
        ("Svago",        "gamecontroller.fill",    2),
        ("Shopping",     "bag.fill",               3),
        ("Salute",       "heart.fill",             4),
        ("Casa",         "house.fill",             5),
        ("Abbonamenti",  "repeat.circle.fill",     6),
        ("Lavoro",       "briefcase.fill",         7),
        ("Istruzione",   "book.fill",              8),
        ("Viaggi",       "airplane",               9),
        ("Regali",       "gift.fill",              10),
        ("Risparmio",    "banknote",               11),
        ("Giroconto",    "arrow.left.arrow.right", 12),
        ("Altro",        "tray.fill",               13),
    ]

    @MainActor
    static func seedIfNeeded(context: ModelContext) {
        let count = (try? context.fetchCount(FetchDescriptor<Category>())) ?? 0
        guard count == 0 else {
            migrateIconsIfNeeded(context: context)
            return
        }
        for (name, icon, order) in defaults {
            context.insert(Category(name: name, icon: icon, isDefault: true, sortOrder: order))
        }
        context.safeSave()
    }

    @MainActor
    private static func migrateIconsIfNeeded(context: ModelContext) {
        let all = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        var changed = false
        for cat in all {
            if let (_, icon, _) = defaults.first(where: { $0.0 == cat.name }), cat.icon != icon {
                cat.icon = icon
                changed = true
            }
        }
        if changed { context.safeSave() }
    }
}
