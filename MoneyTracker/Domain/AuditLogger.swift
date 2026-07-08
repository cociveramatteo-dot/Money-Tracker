import Foundation
import SwiftData
import OSLog

// MARK: - AuditLogger (PROP-02)
//
// Registro immutabile e append-only di ogni creazione/modifica/cancellazione ai dati
// finanziari. Non sostituisce nulla della logica esistente: osserva la stessa notifica
// di salvataggio già usata per il sync incrementale (vedi SyncService.recordChanges) —
// nessun nuovo punto da agganciare nelle singole view, quindi nessun rischio di
// dimenticare un salvataggio da qualche parte.
//
// Ogni evento è una riga scritta in coda a un file locale, mai riscritta né modificata:
// permette di ricostruire "cosa è successo e quando" ai dati finanziari, anche a
// distanza di anni. È un file locale (non su Supabase): protetto con la stessa
// crittografia a riposo del database principale, cancellato insieme ai dati locali al
// logout/cambio utente e all'eliminazione dell'account (vedi clearAll()).
@MainActor
final class AuditLogger {
    static let shared = AuditLogger()
    private init() {}

    struct Entry: Codable, Identifiable {
        let id: UUID
        let timestamp: Date
        let entityType: String   // "Transaction" | "Account" | "Budget" | "Goal"
        let action: String       // "created" | "updated" | "deleted"
        let summary: String
    }

    private lazy var fileURL: URL = {
        let dir = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)[0]
        try? FileManager.default.createDirectory(at: dir, withIntermediateDirectories: true)
        return dir.appendingPathComponent("audit-log.jsonl")
    }()

    /// Estrae dalla notifica di salvataggio cosa è cambiato e ne scrive una riga.
    /// Simmetrico a SyncService.recordChanges, stessa fonte di verità (SwiftData),
    /// ma copre tutti e 4 i tipi di dato finanziario, non solo le transazioni.
    func record(from notification: Notification, context: ModelContext) {
        let inserted = (notification.userInfo?[ModelContext.NotificationKey.insertedIdentifiers.rawValue] as? [PersistentIdentifier]) ?? []
        let updated  = (notification.userInfo?[ModelContext.NotificationKey.updatedIdentifiers.rawValue]  as? [PersistentIdentifier]) ?? []
        let deleted  = (notification.userInfo?[ModelContext.NotificationKey.deletedIdentifiers.rawValue]  as? [PersistentIdentifier]) ?? []

        for pid in inserted { appendIfResolvable(pid, action: "created", context: context) }
        for pid in updated  { appendIfResolvable(pid, action: "updated", context: context) }
        for pid in deleted  { appendDeleted(pid) }
    }

    private func appendIfResolvable(_ pid: PersistentIdentifier, action: String, context: ModelContext) {
        guard let summary = summary(for: pid, context: context) else { return }
        append(Entry(id: UUID(), timestamp: Date(), entityType: pid.entityName, action: action, summary: summary))
    }

    private func appendDeleted(_ pid: PersistentIdentifier) {
        // L'oggetto non esiste più nel momento in cui arriva questa notifica: non c'è
        // modo sicuro di leggerne i valori (rischierebbe di risolvere un fault non più
        // valido). Registriamo comunque CHE qualcosa è stato eliminato e quando —
        // meglio un evento senza dettagli che nessuna traccia della cancellazione.
        let known: Set<String> = ["Account", "Transaction", "Budget", "Goal"]
        guard known.contains(pid.entityName) else { return }
        append(Entry(id: UUID(), timestamp: Date(), entityType: pid.entityName, action: "deleted", summary: "—"))
    }

    private func summary(for pid: PersistentIdentifier, context: ModelContext) -> String? {
        switch pid.entityName {
        case "Transaction":
            guard let t = context.model(for: pid) as? Transaction else { return nil }
            return "\(t.name) — \(t.amount.fixedFractionString) (\(t.transactionType.rawValue))"
        case "Account":
            guard let a = context.model(for: pid) as? Account else { return nil }
            return "\(a.name) — saldo iniziale \(a.initialBalance.fixedFractionString)"
        case "Budget":
            guard let b = context.model(for: pid) as? Budget else { return nil }
            return "\(b.category) — \(b.monthlyLimit.fixedFractionString)/mese"
        case "Goal":
            guard let g = context.model(for: pid) as? Goal else { return nil }
            return "\(g.name) — obiettivo \(g.targetAmount.fixedFractionString)"
        default:
            return nil
        }
    }

    /// Scrittura in coda, mai una riscrittura del file — questo È la proprietà "append-only".
    private func append(_ entry: Entry) {
        guard let data = try? JSONEncoder().encode(entry) else { return }
        var line = data
        line.append(0x0A)   // newline: un evento per riga (JSON Lines)

        if let handle = try? FileHandle(forWritingTo: fileURL) {
            defer { try? handle.close() }
            handle.seekToEndOfFile()
            try? handle.write(contentsOf: line)
        } else {
            try? line.write(to: fileURL)
        }
        // Stessa protezione crittografica a riposo del database principale.
        try? FileManager.default.setAttributes(
            [.protectionKey: FileProtectionType.complete],
            ofItemAtPath: fileURL.path
        )
    }

    /// Tutte le voci, più recenti prima — per la UI di sola lettura (AuditLogView).
    func readAll() -> [Entry] {
        guard let data = try? Data(contentsOf: fileURL) else { return [] }
        let decoder = JSONDecoder()
        return data.split(separator: 0x0A)
            .compactMap { try? decoder.decode(Entry.self, from: Data($0)) }
            .reversed()
    }

    /// Cancella l'intero registro. Chiamato al logout/cambio utente (SyncService.clearLocalData)
    /// e dopo l'eliminazione account (diritto all'oblio) — non deve mai sopravvivere oltre
    /// i dati a cui si riferisce, né restare leggibile da un utente diverso sullo stesso dispositivo.
    func clearAll() {
        try? FileManager.default.removeItem(at: fileURL)
    }
}
