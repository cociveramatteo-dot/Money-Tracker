import SwiftUI

// MARK: - ContextualHint
//
// Livello 2 del tour: mini-tour contestuali, uno spotlight + card singoli (niente
// avanti/indietro, niente pallini di progresso), mostrati una sola volta la prima
// volta che l'utente arriva davvero su quell'elemento — dopo aver già visto la
// panoramica di Livello 1 (OverviewStep). Copre SOLO le sottopagine di Movimenti
// non toccate dal Livello 1 (raggiunte da una navigazione, non da un semplice
// cambio tab/segmento). Ogni caso ha il proprio flag persistito (vedi
// TourManager.hasSeenHint/markHintSeen).
enum ContextualHint: String, CaseIterable, Identifiable {

    case movimentiSection

    var id: String { rawValue }

    /// ID registrato via `.tourAnchor(_:)` sull'elemento da spotlightare.
    /// `hint.settings` non spotlighta nulla (vive dentro un .sheet, sopra al quale
    /// l'overlay del tour non può disegnare) — è gestito come banner inline in
    /// SettingsView, non passa da qui.
    var anchorID: String {
        switch self {
        case .movimentiSection: return "sectionContent"
        }
    }

    var spotlightCornerRadius: CGFloat { 16 }

    /// Spotlighta contenuto in alto/centro schermo — la card resta in basso.
    var cardAtTop: Bool { false }

    var icon: String {
        switch self {
        case .movimentiSection: return "hand.point.right.fill"
        }
    }

    var titleKey: LocalizedStringKey {
        switch self {
        case .movimentiSection: return "hint.movimentiSection.title"
        }
    }

    var bodyKey: LocalizedStringKey {
        switch self {
        case .movimentiSection: return "hint.movimentiSection.body"
        }
    }
}
