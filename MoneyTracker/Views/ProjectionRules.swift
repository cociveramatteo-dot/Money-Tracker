import Foundation

/// Regola condivisa di inclusione dei movimenti nella previsione mensile (S-41 / S-73c).
enum ProjectionRules {
    /// Un movimento singolo pianificato (non ricorrente, non trasferimento, fisso o no, uscita o entrata)
    /// pesa sulla previsione solo nel mese della sua data (S-41 / S-73c).
    /// Tutto il resto — fatti, trasferimenti, serie ricorrenti — conta sempre.
    static func countsInProjection(
        _ transaction: Transaction,
        projectionDay: Date,
        calendar: Calendar = .current
    ) -> Bool {
        let isSingleOneOff = !transaction.isTransfer
            && transaction.templateId.isEmpty && transaction.recurringFrequency.isEmpty
        guard !transaction.isDone && isSingleOneOff else { return true }
        return calendar.isDate(transaction.date, equalTo: projectionDay, toGranularity: .month)
    }
}
