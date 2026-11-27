import Foundation

enum MovementListItem: Identifiable {
    enum ID: Hashable {
        case real(UUID)
        case virtual(UUID)
    }

    case real(Transaction)
    case virtual(Occurrence)

    var id: ID {
        switch self {
        case .real(let t): return .real(t.id)
        case .virtual(let o): return .virtual(o.id)
        }
    }

    var date: Date {
        switch self {
        case .real(let t): return t.date
        case .virtual(let o): return o.date
        }
    }

    var createdAt: Date {
        switch self {
        case .real(let t): return t.createdAt
        case .virtual: return .distantPast
        }
    }

    var rawID: UUID {
        switch self {
        case .real(let t): return t.id
        case .virtual(let o): return o.id
        }
    }

    /// Importo con segno per i totali di gruppo; i trasferimenti non sono spese né entrate.
    var signedAmount: Decimal {
        switch self {
        case .real(let t): return t.isTransfer ? .zero : t.signedAmount
        case .virtual(let o): return TransactionType(rawValue: o.type) == .entrata ? o.amount : -o.amount
        }
    }

    var isPlanned: Bool {
        switch self {
        case .real(let t): return !t.isDone
        case .virtual: return true
        }
    }
}

struct MovementDayGroup {
    let day: Date
    let items: [MovementListItem]
}

enum MovementListLayout {
    struct Result {
        let planned: [MovementListItem]
        let days: [MovementDayGroup]
    }

    /// Nei mesi futuri raggruppa i pianificati (reali non effettuati + virtuali) in cima in ordine
    /// crescente di giorno; nei mesi correnti e passati lascia tutte le righe nei gruppi giornalieri.
    static func make(
        real: [Transaction],
        virtual: [Occurrence],
        isFutureMonth: Bool,
        calendar: Calendar = .current
    ) -> Result {
        let realItems = real.map(MovementListItem.real)
        let virtualItems = virtual.map(MovementListItem.virtual)

        if isFutureMonth {
            let planned = (realItems.filter(\.isPlanned) + virtualItems)
                .map { (day: calendar.startOfDay(for: $0.date), item: $0) }
                .sorted { lhs, rhs in
                    if lhs.day != rhs.day { return lhs.day < rhs.day }
                    if lhs.item.createdAt != rhs.item.createdAt { return lhs.item.createdAt > rhs.item.createdAt }
                    return lhs.item.rawID.uuidString < rhs.item.rawID.uuidString
                }
                .map(\.item)
            let completed = realItems.filter { !$0.isPlanned }
            return Result(planned: planned, days: groupByDayDescending(completed, calendar: calendar))
        } else {
            return Result(planned: [], days: groupByDayDescending(realItems + virtualItems, calendar: calendar))
        }
    }

    private static func groupByDayDescending(_ items: [MovementListItem], calendar: Calendar) -> [MovementDayGroup] {
        let sorted = items
            .map { (day: calendar.startOfDay(for: $0.date), item: $0) }
            .sorted { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day > rhs.day }
                if lhs.item.createdAt != rhs.item.createdAt { return lhs.item.createdAt > rhs.item.createdAt }
                return lhs.item.rawID.uuidString < rhs.item.rawID.uuidString
            }

        var groups: [MovementDayGroup] = []
        var currentDay: Date?
        var currentItems: [MovementListItem] = []

        for entry in sorted {
            if entry.day != currentDay {
                if let day = currentDay {
                    groups.append(MovementDayGroup(day: day, items: currentItems))
                }
                currentDay = entry.day
                currentItems = [entry.item]
            } else {
                currentItems.append(entry.item)
            }
        }
        if let day = currentDay {
            groups.append(MovementDayGroup(day: day, items: currentItems))
        }
        return groups
    }
}
