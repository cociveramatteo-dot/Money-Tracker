import Foundation
import SwiftData
import OSLog

// MARK: - SharedStore
//
// BUG: "Aggiungi spesa" via Tocco posteriore/Siri/Shortcuts (Intents/AddExpenseIntent.swift)
// gira fuori-processo rispetto all'app principale (openAppWhenRun = false). Senza un
// App Group, quel processo e l'app vedono due container sandbox DIVERSI: un
// `ModelConfiguration` senza `url:` esplicito risolve alla cartella Application Support
// del proprio processo, che per un'estensione fuori-processo non è la stessa dell'app
// host. Risultato osservato: il banner conferma "salvato!" (il ctx.save() riesce
// davvero) ma la transazione finisce in uno store che l'app non apre mai — non compare
// mai nella UI. La soluzione standard Apple per condividere uno store SwiftData/CoreData
// tra app e le sue estensioni è un App Group: entrambi i processi puntano allo stesso
// file, nello stesso container condiviso.
//
// ⚠️ Passo manuale richiesto in Xcode (non automatizzabile da qui): aprire il progetto →
// target "MoneyTracker" → Signing & Capabilities → "+ Capability" → "App Groups" →
// aggiungere `group.com.matteo.moneytracker.shared` (deve combaciare esattamente con
// `SharedStore.appGroupId` sotto). Xcode registra il gruppo sul portale sviluppatore
// automaticamente se si è loggati con un Apple ID/Team. Finché questo passo non viene
// fatto, `containerURL` resta nil e l'app ripiega sul comportamento precedente (store
// non condiviso) — nessuna regressione, ma il bug del Tocco posteriore resta presente
// finché la capability non viene attivata.
enum SharedStore {

    static let appGroupId = "group.com.matteo.moneytracker.shared"

    static var containerURL: URL? {
        FileManager.default.containerURL(forSecurityApplicationGroupIdentifier: appGroupId)
    }

    /// URL dello store reale nel container condiviso, se la capability App Groups è
    /// attiva. `nil` finché non lo è (vedi nota sopra) — i chiamanti devono ripiegare
    /// sulla configurazione precedente in quel caso.
    static var mainStoreURL: URL? {
        containerURL?.appendingPathComponent("default.store")
    }

    /// Copia lo store "legacy" (pre-App-Group, posizione di default di
    /// `ModelConfiguration` senza `url:`) nel nuovo container condiviso, una tantum,
    /// al primo lancio dopo l'attivazione della capability.
    ///
    /// Senza questa migrazione, il giorno in cui la capability viene attivata in Xcode
    /// l'app inizierebbe a leggere dal nuovo percorso condiviso — che non esiste ancora
    /// — e l'utente si ritroverebbe con uno store vuoto: esattamente il tipo di perdita
    /// dati totale che questo fix vuole eliminare, non introdurne uno nuovo.
    ///
    /// `copyItem` (non `moveItem`) deliberatamente: lascia intatto lo store legacy. Se
    /// la copia fallisce a metà per qualunque motivo, il vecchio store resta comunque
    /// integro e l'app può ripartire da quello al lancio successivo.
    static func migrateLegacyStoreIfNeeded(schema: Schema) {
        guard let newURL = mainStoreURL else { return }
        guard !FileManager.default.fileExists(atPath: newURL.path) else { return }

        let legacyURL = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false).url
        guard FileManager.default.fileExists(atPath: legacyURL.path) else { return }

        Logger.persistence.info("SharedStore: migrazione store legacy → container App Group")
        for ext in ["", "-wal", "-shm"] {
            let src = URL(fileURLWithPath: legacyURL.path + ext)
            let dst = URL(fileURLWithPath: newURL.path + ext)
            guard FileManager.default.fileExists(atPath: src.path) else { continue }
            do {
                try FileManager.default.copyItem(at: src, to: dst)
            } catch {
                Logger.persistence.error("SharedStore: copia \(ext.isEmpty ? "store" : ext, privacy: .public) fallita → \(error.localizedDescription, privacy: .public)")
            }
        }
    }
}
