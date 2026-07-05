import SwiftUI

// MARK: - TourStep
//
// Tour essenziale in 5 passi: benvenuto → tab bar → saldo → bottone + → fine.
// Tutto il resto (statistiche, swipe, budget, obiettivi, conti, saldo atteso)
// è insegnato just-in-time dai tip contestuali (vedi ContextualTips.swift):
// un solo suggerimento, sulla schermata giusta, alla prima visita.
// Razionale: il completamento dei tour crolla oltre i 5-7 passi, e i gesti
// si imparano facendoli — non guardando uno spotlight che li descrive.
enum TourStep: Int, CaseIterable, Identifiable {

    case welcome        // modale
    case tabBar         // spotlight
    case balance        // spotlight
    case addButton      // spotlight
    case done           // modale — CTA: "Aggiungi la tua prima spesa"

    var id: Int { rawValue }

    // ── Navigation ─────────────────────────────────────────────────────────

    /// Tutti gli step spotlight vivono sulla tab Home: il tour non trascina
    /// più l'utente per 5 tab. nil = step modale, nessun cambio tab.
    var requiredTab: Int? {
        switch self {
        case .tabBar, .balance, .addButton: return 0
        default:                            return nil
        }
    }

    /// Mantenuto per compatibilità con ContentView (sempre nil: il tour
    /// non tocca più i segmenti di PianificaView).
    var requiredSegment: Int? { nil }

    // ── Spotlight anchor ───────────────────────────────────────────────────

    /// ID registrato via `.tourAnchor(_:)` sulla vista bersaglio.
    var anchorID: String? {
        switch self {
        case .tabBar:    return "tabBar"
        case .balance:   return "balanceHero"
        case .addButton: return "addButton"
        default:         return nil
        }
    }

    /// Padding esterno applicato al rect dell'anchor prima del ritaglio.
    var spotlightPadding: CGFloat {
        self == .addButton ? 4 : 0
    }

    var spotlightCornerRadius: CGFloat {
        switch self {
        case .addButton: return 30
        case .balance:   return 16
        case .tabBar:    return 28
        default:         return 0
        }
    }

    // ── Card position hint ─────────────────────────────────────────────────

    var cardAtTop: Bool {
        switch self {
        case .tabBar, .addButton: return true
        default:                  return false
        }
    }

    // ── Presentation ───────────────────────────────────────────────────────

    var isModal: Bool {
        switch self {
        case .welcome, .done: return true
        default:              return false
        }
    }

    var icon: String {
        switch self {
        case .welcome:   return "chart.pie.fill"
        case .tabBar:    return "rectangle.bottomthird.inset.filled"
        case .balance:   return "eurosign.circle.fill"
        case .addButton: return "plus.circle.fill"
        case .done:      return "checkmark.circle.fill"
        }
    }

    // Le chiavi devono esistere in ogni Localizable.strings (sezione tour.*).
    var titleKey: LocalizedStringKey {
        switch self {
        case .welcome:   return "tour.welcome.title"
        case .tabBar:    return "tour.tabBar.title"
        case .balance:   return "tour.saldoAttuale.title"
        case .addButton: return "tour.addButton.title"
        case .done:      return "tour.done.title"
        }
    }

    var bodyKey: LocalizedStringKey {
        switch self {
        case .welcome:   return "tour.welcome.body"
        case .tabBar:    return "tour.tabBar.body"
        case .balance:   return "tour.saldoAttuale.body"
        case .addButton: return "tour.addButton.body"
        case .done:      return "tour.done.body"
        }
    }

    var ctaKey: LocalizedStringKey {
        switch self {
        case .welcome: return "tour.startButton"
        case .done:    return "tour.doneButton"
        default:       return "Avanti"
        }
    }

    // ── Progress ───────────────────────────────────────────────────────────

    static var elementSteps: [TourStep] {
        allCases.filter { !$0.isModal }
    }

    var isFirstElementStep: Bool { self == Self.elementSteps.first }
    var isLastElementStep:  Bool { self == Self.elementSteps.last  }
}
