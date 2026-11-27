import Foundation

extension Sequence where Element == Transaction {
    /// Ordine unico di visualizzazione: prima il giorno di calendario dal più recente;
    /// a parità di giorno, `createdAt` dal più recente (l'ultimo aggiunto in cima).
    /// Il giorno si calcola una volta per elemento (non a ogni confronto del sort).
    func sortedForDisplay(calendar: Calendar = .current) -> [Transaction] {
        map { (day: calendar.startOfDay(for: $0.date), tx: $0) }
            .sorted { lhs, rhs in
                if lhs.day != rhs.day { return lhs.day > rhs.day }
                if lhs.tx.createdAt != rhs.tx.createdAt { return lhs.tx.createdAt > rhs.tx.createdAt }
                return lhs.tx.id.uuidString < rhs.tx.id.uuidString
            }
            .map(\.tx)
    }
}
