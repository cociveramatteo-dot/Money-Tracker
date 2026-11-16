import Foundation

/// Read-only values keep the history lookup independent of SwiftData and sync.
enum LastUsedCategory {
    struct Movement: Sendable {
        let name: String
        let category: String
        let createdAt: Date
        let isDone: Bool
        let isTransfer: Bool
    }

    /// The most recently entered normal movement wins, even when backdated.
    /// If its category was deleted, do not resurrect an older choice.
    nonisolated static func suggest(for name: String, history: [Movement], availableCategories: Set<String>) -> String? {
        let key = normalized(name)
        guard !key.isEmpty else { return nil }
        let latest = history.enumerated().filter {
            $0.element.isDone && !$0.element.isTransfer && normalized($0.element.name) == key
        }.max {
            if $0.element.createdAt == $1.element.createdAt { return $0.offset < $1.offset }
            return $0.element.createdAt < $1.element.createdAt
        }?.element
        guard let latest, availableCategories.contains(latest.category) else { return nil }
        return latest.category
    }

    private nonisolated static func normalized(_ name: String) -> String {
        name.folding(options: [.caseInsensitive, .diacriticInsensitive], locale: Locale(identifier: "en_US_POSIX"))
            .split(whereSeparator: \.isWhitespace).joined(separator: " ")
    }
}
