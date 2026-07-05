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
        do {
            try save()
            // PERF-04: ogni salvataggio può aver cambiato i saldi degli account
            // (nuova/eliminata transazione, importo o isDone modificati). Invece di
            // tracciare quale Account è coinvolto (rischio di dimenticare un call site
            // e mostrare un saldo stantio — un bug grave in un'app finanziaria),
            // invalidiamo l'intera cache: il prossimo render ricalcola gli account
            // effettivamente letti, una sola volta, non ad ogni frame.
            AccountBalanceCache.shared.invalidateAll()
            return true
        } catch {
            let source = (file as NSString).lastPathComponent
            Logger.persistence.error("SwiftData save failed at \(source, privacy: .public):\(line) → \(error.localizedDescription, privacy: .public)")
            assertionFailure("SwiftData save failed: \(error)")
            return false
        }
    }
}
