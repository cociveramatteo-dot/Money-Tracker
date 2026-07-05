import Foundation
import OSLog

// MARK: - Loggers

// nonisolated: `Logger` è Sendable e questi logger sono usati anche da contesti non-main-actor
// (es. RecurringTransactionActor in background). SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor
// li renderebbe altrimenti @MainActor per default.
extension Logger {
    nonisolated static let persistence = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyTracker", category: "Persistence")
    nonisolated static let recurring   = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyTracker", category: "Recurring")
    nonisolated static let classifier  = Logger(subsystem: Bundle.main.bundleIdentifier ?? "MoneyTracker", category: "Classifier")
}
