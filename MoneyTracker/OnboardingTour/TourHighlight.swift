import SwiftUI

// MARK: - PreferenceKey

/// Collects named bounding-box anchors from any descendant view.
/// Each call to `.tourAnchor(_:)` registers a single entry; the last writer wins
/// (PreferenceKey.reduce keeps the rightmost value for duplicate IDs).
struct TourAnchorKey: PreferenceKey {
    typealias Value = [String: Anchor<CGRect>]
    static var defaultValue: Value = [:]
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value.merge(nextValue()) { _, new in new }
    }
}

// MARK: - View modifier

extension View {
    /// Registers the view's layout bounds with the onboarding-tour system.
    /// Add this modifier to any element you want the spotlight to highlight.
    ///
    ///     HeroAmount(amount: total, hidden: hideBalance)
    ///         .tourAnchor("balanceHero")
    func tourAnchor(_ id: String) -> some View {
        anchorPreference(key: TourAnchorKey.self, value: .bounds) { [id: $0] }
    }
}
