import SwiftUI
import Combine

// MARK: - TourManager

/// Single source of truth per il tour, in due livelli:
///   • Livello 1 — panoramica (`OverviewStep`): una sequenza lineare, mostrata
///     una volta sola al primo avvio (o su richiesta da "Rivedi tour").
///   • Livello 2 — mini-tour contestuali (`ContextualHint`): un singolo
///     spotlight + card, mostrato una sola volta la prima volta che l'utente
///     arriva davvero su quell'elemento, DOPO aver completato la panoramica.
/// Accessible via `TourManager.shared` from any context.
@MainActor
final class TourManager: ObservableObject {

    // MARK: Singleton

    static let shared = TourManager()
    private init() {}

    // MARK: Published state — panoramica (Livello 1)

    @Published private(set) var isActive         = false
    @Published private(set) var currentStep      = OverviewStep.welcome
    @Published private(set) var requiredTab      : Int? = nil
    /// Segmento richiesto dentro Pianifica (0 = Budget, 1 = Obiettivi) per lo
    /// step corrente — pilotato da ContentView verso il binding di PianificaView,
    /// stesso meccanismo di `requiredTab`.
    @Published private(set) var requiredSegment  : Int? = nil

    // MARK: Published state — mini-tour contestuali (Livello 2)

    @Published private(set) var activeHint: ContextualHint? = nil

    // MARK: Persistence

    private let completedKey = "onboarding.tour.overview.completed.v1"
    private let demoModeKey  = "demoModeEnabled"

    /// State of demo mode BEFORE the tour activated it.
    /// Restored when the tour ends, so users who had demo mode on manually keep their setting.
    private var demoStateBeforeTour = false

    var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    private func hintKey(_ hint: ContextualHint) -> String { "hint.\(hint.rawValue).seen" }

    func hasSeenHint(_ hint: ContextualHint) -> Bool {
        UserDefaults.standard.bool(forKey: hintKey(hint))
    }

    func markHintSeen(_ hint: ContextualHint) {
        UserDefaults.standard.set(true, forKey: hintKey(hint))
    }

    // MARK: Public API — panoramica

    /// Show the tour if the user hasn't completed it yet.
    func startIfNeeded() {
        guard !hasCompleted else { return }
        start()
    }

    /// Force-start the tour from the beginning (also called by "Rivedi tour" in Settings).
    func start() {
        // Set isActive = true SYNCHRONOUSLY before anything else.
        // This ensures ContentView.onAppear's guard fires correctly if ContentView
        // is recreated because we flip demoModeEnabled below.
        isActive        = true
        activeHint      = nil
        currentStep     = .welcome
        requiredTab     = nil
        requiredSegment = nil

        // Enable demo mode for the tour so the user sees realistic sample data.
        // Save the previous state so we can restore it when the tour ends.
        demoStateBeforeTour = UserDefaults.standard.bool(forKey: demoModeKey)
        if !demoStateBeforeTour {
            // Toggling this causes MoneyTrackerApp to swap the ModelContainer and
            // re-create ContentView via .id(). onAppear will guard against restart
            // because isActive is already true at this point.
            UserDefaults.standard.set(true, forKey: demoModeKey)
        }
    }

    /// "Rivedi tour" in Impostazioni: un vero ricomincia-da-capo — azzera sia la
    /// panoramica sia tutti i mini-tour già visti, poi riparte dall'inizio.
    func resetAll() {
        hasCompleted = false
        for hint in ContextualHint.allCases {
            UserDefaults.standard.removeObject(forKey: hintKey(hint))
        }
        UserDefaults.standard.removeObject(forKey: settingsHintKey)
        start()
    }

    func next() {
        let all = OverviewStep.all
        guard let idx = all.firstIndex(where: { $0.id == currentStep.id }) else { return }
        if idx + 1 < all.count {
            advance(to: all[idx + 1])
        } else {
            complete()
        }
    }

    func previous() {
        let all = OverviewStep.all
        guard let idx = all.firstIndex(where: { $0.id == currentStep.id }), idx > 0 else { return }
        advance(to: all[idx - 1])
    }

    func skip() { complete() }

    func complete() {
        // Il tour può finire lasciando l'utente sull'ultima tab visitata durante
        // il percorso (es. Conti) — riportarlo esplicitamente sulla Home tramite
        // lo stesso canale (requiredTab) con cui ContentView pilota i cambi tab
        // durante il tour, PRIMA di disattivare isActive: il flip di tab avviene
        // così nascosto dietro la modale "Fatto" ancora in dissolvenza.
        requiredTab     = 0
        requiredSegment = nil
        withAnimation(.easeOut(duration: 0.3)) { isActive = false }
        hasCompleted = true

        // Restore demo mode to whatever it was before the tour.
        // Delay slightly so the tour's fade-out animation plays before
        // ContentView is recreated by the demoModeEnabled toggle.
        let restore = demoStateBeforeTour
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            UserDefaults.standard.set(restore, forKey: self.demoModeKey)
        }
    }

    // MARK: Public API — mini-tour contestuali

    /// Mostra il mini-tour `hint` se non è già stato visto, e solo quando non c'è
    /// nessun altro tour/hint già in corso (evita sovrapposizioni tra la
    /// panoramica, un altro hint, o due trigger che scattano nello stesso istante).
    func showHintIfNeeded(_ hint: ContextualHint) {
        guard hasCompleted, !isActive, activeHint == nil, !hasSeenHint(hint) else { return }
        withAnimation(.spring(response: 0.4, dampingFraction: 0.85)) {
            activeHint = hint
        }
    }

    /// Chiude il mini-tour corrente e lo marca come visto — non ricompare più.
    func dismissHint() {
        guard let hint = activeHint else { return }
        markHintSeen(hint)
        withAnimation(.easeOut(duration: 0.25)) { activeHint = nil }
    }

    // MARK: - hint.settings (banner inline, non passa dallo spotlight — vedi SettingsView)

    private let settingsHintKey = "hint.settings.seen"

    var hasSeenSettingsHint: Bool {
        UserDefaults.standard.bool(forKey: settingsHintKey)
    }

    func markSettingsHintSeen() {
        UserDefaults.standard.set(true, forKey: settingsHintKey)
    }

    // MARK: Private

    private func advance(to step: OverviewStep) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep     = step
            requiredTab     = step.requiredTab
            requiredSegment = step.requiredSegment
        }
    }
}
