import SwiftUI
import Combine

// MARK: - TourManager

/// Single source of truth for the onboarding tour.
/// Accessible via `TourManager.shared` from any context.
@MainActor
final class TourManager: ObservableObject {

    // MARK: Singleton

    static let shared = TourManager()
    private init() {}

    // MARK: Published state

    @Published private(set) var isActive         = false
    @Published private(set) var currentStep      = TourStep.welcome
    @Published private(set) var requiredTab      : Int? = nil
    @Published private(set) var requiredSegment  : Int? = nil

    /// Exact UITabBar frame in screen-point coordinates, captured by TabBarFrameCapture.
    /// CGRect.zero = not yet captured (fall back to SwiftUI anchor).
    @Published var tabBarFrame          : CGRect  = .zero
    @Published var tabBarCornerRadius   : CGFloat = 0

    // MARK: Persistence

    private let completedKey = "onboarding.tour.completed.v1"
    private let demoModeKey  = "demoModeEnabled"

    /// State of demo mode BEFORE the tour activated it.
    /// Restored when the tour ends, so users who had demo mode on manually keep their setting.
    private var demoStateBeforeTour = false

    var hasCompleted: Bool {
        get { UserDefaults.standard.bool(forKey: completedKey) }
        set { UserDefaults.standard.set(newValue, forKey: completedKey) }
    }

    // MARK: Public API

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

    /// Called when the demo-mode toggle is flipped in Settings —
    /// clears completion and restarts the tour with a brief delay.
    func resetForDemo() {
        hasCompleted = false
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) { [weak self] in
            self?.start()
        }
    }

    func next() {
        let all = TourStep.allCases
        guard let idx = all.firstIndex(of: currentStep) else { return }
        if idx + 1 < all.count {
            advance(to: all[idx + 1])
        } else {
            complete()
        }
    }

    func previous() {
        let all = TourStep.allCases
        guard let idx = all.firstIndex(of: currentStep), idx > 0 else { return }
        advance(to: all[idx - 1])
    }

    func skip() { complete() }

    func complete() {
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

    // MARK: Private

    private func advance(to step: TourStep) {
        withAnimation(.spring(response: 0.45, dampingFraction: 0.85)) {
            currentStep     = step
            requiredTab     = step.requiredTab
            requiredSegment = step.requiredSegment
        }
    }
}
