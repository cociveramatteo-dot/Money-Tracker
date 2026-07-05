import SwiftUI
import Combine

// MARK: - Contextual tips (just-in-time)
//
// Sostituiscono i 9 step rimossi dal tour: un solo suggerimento, sulla
// schermata giusta, alla prima visita — mai più di uno alla volta, mai
// durante il tour, mai due volte. Riusano le chiavi tour.* già tradotte
// in tutte le lingue.

// MARK: - TipID

enum TipID: String, CaseIterable {
    case swipeActions    // Movimenti — prima visita
    case statistics      // Statistiche — prima visita
    case budget          // Pianifica › Budget — prima visita
    case goals           // Pianifica › Obiettivi — prima visita al segmento
    case accounts        // Conti — prima visita
    case expectedBalance // Home — la prima volta che il saldo atteso appare

    var titleKey: LocalizedStringKey {
        switch self {
        case .swipeActions:    return "tour.swipeAction.title"
        case .statistics:      return "tour.statistics.title"
        case .budget:          return "tour.budgetHero.title"
        case .goals:           return "tour.goalHero.title"
        case .accounts:        return "tour.accountSwipe.title"
        case .expectedBalance: return "tour.saldoAtteso.title"
        }
    }

    var bodyKey: LocalizedStringKey {
        switch self {
        case .swipeActions:    return "tour.swipeAction.body"
        case .statistics:      return "tour.statistics.body"
        case .budget:          return "tour.budgetHero.body"
        case .goals:           return "tour.goalHero.body"
        case .accounts:        return "tour.accountSwipe.body"
        case .expectedBalance: return "tour.saldoAtteso.body"
        }
    }

    var icon: String {
        switch self {
        case .swipeActions:    return "hand.point.right.fill"
        case .statistics:      return "chart.bar.fill"
        case .budget:          return "chart.bar.doc.horizontal.fill"
        case .goals:           return "target"
        case .accounts:        return "creditcard.fill"
        case .expectedBalance: return "clock.badge.fill"
        }
    }
}

// MARK: - TipManager

@MainActor
final class TipManager: ObservableObject {

    static let shared = TipManager()
    private init() {}

    @Published private(set) var visibleTip: TipID? = nil

    /// Task di presentazione in attesa (ritardo di assestamento). Cancellato
    /// da hide()/dismiss(): se l'utente cambia schermata durante i 600 ms,
    /// il tip della schermata precedente NON appare su quella nuova.
    private var pendingShow: Task<Void, Never>? = nil

    private func seenKey(_ id: TipID) -> String { "tip.seen.\(id.rawValue)" }

    /// Mostra il tip se: mai visto prima, tour completato e non attivo,
    /// nessun altro tip a schermo. Il breve ritardo lascia assestare la vista.
    func showIfNeeded(_ id: TipID) {
        guard TourManager.shared.hasCompleted, !TourManager.shared.isActive else { return }
        guard !UserDefaults.standard.bool(forKey: seenKey(id)) else { return }
        guard visibleTip == nil else { return }

        pendingShow?.cancel()
        pendingShow = Task { @MainActor in
            try? await Task.sleep(for: .milliseconds(600))
            guard !Task.isCancelled else { return }
            // Ricontrolla: lo stato può essere cambiato nel frattempo.
            guard self.visibleTip == nil, !TourManager.shared.isActive else { return }
            guard !UserDefaults.standard.bool(forKey: self.seenKey(id)) else { return }
            withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
                self.visibleTip = id
            }
        }
    }

    /// Chiude il tip corrente e lo marca come visto (non riapparirà).
    func dismiss() {
        pendingShow?.cancel()
        guard let id = visibleTip else { return }
        UserDefaults.standard.set(true, forKey: seenKey(id))
        withAnimation(.easeOut(duration: 0.25)) { visibleTip = nil }
    }

    /// Chiude senza marcare come visto (es. cambio tab a metà animazione):
    /// il tip riapparirà alla prossima visita della schermata.
    func hide() {
        pendingShow?.cancel()
        guard visibleTip != nil else { return }
        withAnimation(.easeOut(duration: 0.2)) { visibleTip = nil }
    }

    /// Reset completo (chiamato da "Rivedi tour": i tip tornano vergini).
    func resetAll() {
        for id in TipID.allCases {
            UserDefaults.standard.removeObject(forKey: seenKey(id))
        }
        visibleTip = nil
    }
}

// MARK: - TipCard

/// Card leggera ancorata in basso, sopra la tab bar. Nessuno spotlight,
/// nessun overlay scuro: informa senza interrompere.
struct TipCard: View {
    let tip: TipID

    var body: some View {
        HStack(alignment: .top, spacing: DS.Space.m) {
            Image(systemName: tip.icon)
                .font(.system(size: 13, weight: .medium))
                .foregroundStyle(DS.ink)
                .frame(width: 30, height: 30)
                .background(DS.fog)
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 3) {
                Text(tip.titleKey)
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(DS.ink)
                Text(tip.bodyKey)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.smoke)
                    .lineSpacing(3)
                    .fixedSize(horizontal: false, vertical: true)
            }

            Button { TipManager.shared.dismiss() } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(DS.smoke)
                    .frame(width: 26, height: 26)
                    .background(DS.fog)
                    .clipShape(Circle())
            }
            .accessibilityLabel(Text("OK"))
        }
        .padding(14)
        .background(DS.paper)
        .clipShape(RoundedRectangle(cornerRadius: 16))
        .shadow(color: .black.opacity(0.12), radius: 16, x: 0, y: 4)
        .padding(.horizontal, 12)
        .transition(.move(edge: .bottom).combined(with: .opacity))
        .accessibilityElement(children: .combine)
    }
}
