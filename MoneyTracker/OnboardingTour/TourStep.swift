import SwiftUI

// MARK: - TourStep

/// Ordered sequence of onboarding steps.
/// Modal steps (`.welcome`, `.siriShortcuts`, `.done`) fill the full screen.
/// Element steps use a spotlight cutout + tooltip card.
enum TourStep: Int, CaseIterable, Identifiable {

    // ── Modal steps ────────────────────────────────────────────────────────
    case welcome

    // ── Element steps — Home tab ───────────────────────────────────────────
    case tabBar
    case balance
    case expectedBalance    // saldo atteso — appare subito dopo il saldo attuale
    case eyeButton
    case accountPanel
    case addButton

    // ── Element steps — other tabs ─────────────────────────────────────────
    case filters        // Movimenti
    case swipeActions   // Movimenti — azioni swipe sulla lista transazioni
    case statistics     // Statistiche
    case budget         // Pianifica / Budget
    case goals          // Pianifica / Obiettivi
    case accounts       // Conti

    // ── Modal steps ────────────────────────────────────────────────────────
    case siriShortcuts
    case done

    var id: Int { rawValue }

    // ── Navigation ─────────────────────────────────────────────────────────

    /// Tab index that must be active before showing this step.
    /// Home-tab element steps return 0 explicitly so that going backwards
    /// from another tab correctly switches back to the home tab.
    /// Modal steps (welcome / siriShortcuts / done) return nil — no tab switch.
    var requiredTab: Int? {
        switch self {
        case .tabBar, .balance, .expectedBalance,
             .eyeButton, .accountPanel, .addButton:  return 0
        case .filters, .swipeActions:               return 1
        case .statistics:                           return 2
        case .budget, .goals:                       return 3
        case .accounts:                             return 4
        default:                                    return nil   // modal steps
        }
    }

    /// PianificaView segment (0 = Budget, 1 = Obiettivi).
    var requiredSegment: Int? {
        switch self {
        case .budget: return 0
        case .goals:  return 1
        default:      return nil
        }
    }

    // ── Spotlight anchor ───────────────────────────────────────────────────

    /// ID that must be registered via `.tourAnchor(_:)` on the target view.
    var anchorID: String? {
        switch self {
        // Overlay is now rendered at App level (MoneyTrackerApp) — above UITabBar.
        // The cutout reveals the real UITabBar through the dark overlay. ✓
        case .tabBar:           return "tabBar"
        case .balance:          return "balanceHero"
        case .expectedBalance:  return "saldoAtteso"
        case .eyeButton:        return "eyeButton"
        case .accountPanel:     return "accountPanel"
        case .addButton:        return "addButton"
        case .swipeActions:     return "movimentiList"
        case .filters:          return "filterChips"
        case .statistics:       return "statisticsContent"
        case .budget:           return "budgetList"
        case .goals:            return "goalsList"
        case .accounts:         return "accountList"
        default:                return nil
        }
    }

    /// Outward padding applied to the anchor rect before drawing the cutout.
    var spotlightPadding: CGFloat {
        switch self {
        case .eyeButton, .accountPanel: return 4
        case .addButton:                return 4
        default:                        return 0
        }
    }

    var spotlightCornerRadius: CGFloat {
        switch self {
        case .addButton:                            return 30
        case .eyeButton, .accountPanel:            return 10
        case .balance, .expectedBalance:           return 16
        case .swipeActions:                        return 12
        case .filters:                             return 20
        case .statistics, .budget,
             .goals, .accounts:                    return 12
        case .tabBar:                              return 28
        default:                                   return 0
        }
    }

    // ── Section breadcrumb ─────────────────────────────────────────────────

    /// Human-readable tab label shown in StepCard when the tour is NOT on the Home tab.
    /// `nil` = Home tab (no breadcrumb shown).
    var tabLabel: (icon: String, name: String)? {
        switch self {
        case .filters,
             .swipeActions:     return ("list.bullet",      "Movimenti")
        case .statistics:       return ("chart.bar.fill",   "Statistiche")
        case .budget:           return ("chart.pie",        "Pianifica › Budget")
        case .goals:            return ("chart.pie",        "Pianifica › Obiettivi")
        case .accounts:         return ("creditcard",       "Conti")
        default:                return nil
        }
    }

    // ── Card position hint ─────────────────────────────────────────────────

    var cardAtTop: Bool {
        switch self {
        case .tabBar, .addButton:
            return true
        default:
            return false
        }
    }

    // ── Presentation ───────────────────────────────────────────────────────

    var isModal: Bool {
        switch self {
        case .welcome, .siriShortcuts, .done: return true
        default:                              return false
        }
    }

    var icon: String {
        switch self {
        case .welcome:          return "chart.pie.fill"
        case .tabBar:           return "rectangle.bottomthird.inset.filled"
        case .balance:          return "eurosign.circle.fill"
        case .expectedBalance:  return "clock.badge.fill"
        case .eyeButton:        return "eye.slash.fill"
        case .accountPanel:     return "slider.horizontal.3"
        case .addButton:        return "plus.circle.fill"
        case .swipeActions:     return "hand.point.right.fill"
        case .filters:          return "line.3.horizontal.decrease.circle.fill"
        case .statistics:       return "chart.bar.fill"
        case .budget:           return "chart.bar.doc.horizontal.fill"
        case .goals:            return "target"
        case .accounts:         return "creditcard.fill"
        case .siriShortcuts:    return "mic.fill"
        case .done:             return "checkmark.circle.fill"
        }
    }

    // Keys must be present in every Localizable.strings (see tour.* section).
    var titleKey: LocalizedStringKey {
        switch self {
        case .welcome:          return "tour.welcome.title"
        case .tabBar:           return "tour.tabBar.title"
        case .balance:          return "tour.saldoAttuale.title"
        case .expectedBalance:  return "tour.saldoAtteso.title"
        case .eyeButton:        return "tour.hideBalance.title"
        case .accountPanel:     return "tour.accountOrder.title"
        case .addButton:        return "tour.addButton.title"
        case .swipeActions:     return "tour.swipeAction.title"
        case .filters:          return "tour.filters.title"
        case .statistics:       return "tour.statistics.title"
        case .budget:           return "tour.budgetHero.title"
        case .goals:            return "tour.goalHero.title"
        case .accounts:         return "tour.accountSwipe.title"
        case .siriShortcuts:    return "tour.shortcuts.title"
        case .done:             return "tour.done.title"
        }
    }

    var bodyKey: LocalizedStringKey {
        switch self {
        case .welcome:          return "tour.welcome.body"
        case .tabBar:           return "tour.tabBar.body"
        case .balance:          return "tour.saldoAttuale.body"
        case .expectedBalance:  return "tour.saldoAtteso.body"
        case .eyeButton:        return "tour.hideBalance.body"
        case .accountPanel:     return "tour.accountOrder.body"
        case .addButton:        return "tour.addButton.body"
        case .swipeActions:     return "tour.swipeAction.body"
        case .filters:          return "tour.filters.body"
        case .statistics:       return "tour.statistics.body"
        case .budget:           return "tour.budgetHero.body"
        case .goals:            return "tour.goalHero.body"
        case .accounts:         return "tour.accountSwipe.body"
        case .siriShortcuts:    return "tour.shortcuts.body"
        case .done:             return "tour.done.body"
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
