import SwiftUI

/// Tinta di una categoria («Sentiero»): colore di sfondo e di icona per il quadratino
/// della riga movimento. Le categorie non hanno colore nel modello SwiftData, quindi la
/// tinta è **derivata dal nome** con una regola deterministica e stabile (vedi DECISIONI.md D-006):
/// mappa fissa per le 14 categorie predefinite, hash FNV-1a 32 bit del nome per le altre
/// (non `hashValue`, che in Swift cambia a ogni avvio).
enum CategoryTint: CaseIterable, Sendable {
    case green, amber, blue, violet

    /// Categorie predefinite → tinta (nomi canonici in italiano, come in `DS.categoryIcon`).
    private static let defaults: [String: CategoryTint] = [
        "Cibo": .amber, "Trasporti": .blue, "Svago": .violet, "Shopping": .amber,
        "Salute": .green, "Casa": .blue, "Abbonamenti": .violet, "Lavoro": .green,
        "Istruzione": .violet, "Viaggi": .blue, "Regali": .amber, "Giroconto": .blue,
        "Risparmio": .green, "Altro": .green,
    ]

    /// FNV-1a 32 bit sui byte UTF-8: stabile tra avvii, dispositivi e versioni di Swift.
    static func stableHash(_ name: String) -> UInt32 {
        var hash: UInt32 = 2166136261
        for byte in name.utf8 {
            hash ^= UInt32(byte)
            hash = hash &* 16777619
        }
        return hash
    }

    /// Tinta per il nome di una categoria (funzione pura).
    static func tint(for categoryName: String) -> CategoryTint {
        if let fixed = defaults[categoryName] { return fixed }
        let all = CategoryTint.allCases
        return all[Int(stableHash(categoryName) % UInt32(all.count))]
    }

    /// Sfondo del quadratino icona.
    var background: Color {
        switch self {
        case .green:  return Color(lightHex: 0xE3EFE7, darkHex: 0x1C2E25)
        case .amber:  return Color(lightHex: 0xFBEBDD, darkHex: 0x3A2A16)
        case .blue:   return Color(lightHex: 0xE4ECF6, darkHex: 0x1B2A3B)
        case .violet: return Color(lightHex: 0xECE8F6, darkHex: 0x2A2540)
        }
    }

    /// Colore dell'icona.
    var foreground: Color {
        switch self {
        case .green:  return Color(lightHex: 0x1F7A4D, darkHex: 0x5FD19B)
        case .amber:  return Color(lightHex: 0x8A4A0C, darkHex: 0xF2A65A)
        case .blue:   return Color(lightHex: 0x2F6FB0, darkHex: 0x6FA8E0)
        case .violet: return Color(lightHex: 0x5A4AA3, darkHex: 0xA99BE0)
        }
    }
}
