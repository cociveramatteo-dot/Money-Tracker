import Foundation

extension Sequence where Element == Transaction {
    /// Ordine unico di visualizzazione: prima il giorno di calendario dal più recente;
    /// a parità di giorno, `createdAt` dal più recente (l'ultimo aggiunto in cima).
    func sortedForDisplay(calendar: Calendar = .current) -> [Transaction] {
        sorted { lhs, rhs in
            let lDay = calendar.startOfDay(for: lhs.date)
            let rDay = calendar.startOfDay(for: rhs.date)
            if lDay != rDay { return lDay > rDay }
            if lhs.createdAt != rhs.createdAt { return lhs.createdAt > rhs.createdAt }
            return lhs.id.uuidString < rhs.id.uuidString
        }
    }
}
