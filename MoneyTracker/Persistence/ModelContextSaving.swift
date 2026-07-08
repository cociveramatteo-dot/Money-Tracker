import Foundation
import SwiftData
import OSLog

// MARK: - ModelContext safe save

extension ModelContext {
    /// Salva il context loggando l'errore invece di sopprimerlo silenziosamente.
    /// In debug crasha per permettere di individuare il problema immediatamente.
    /// In release logga e ritorna false senza crashare.
    @discardableResult
    func safeSave(file: String = #file, line: Int = #line) -> Bool {
        guard hasChanges else { return true }
        do {
            try save()
            AccountBalanceCache.shared.invalidateAll()
            return true
        } catch {
            let source = (file as NSString).lastPathComponent
            Logger.persistence.error("SwiftData save failed at \(source, privacy: .public):\(line) → \(error.localizedDescription, privacy: .public)")
            return false
        }
    }
}
