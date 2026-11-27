import AppIntents
import Foundation
import SwiftData

/// Pure category ordering and resolution helpers for App Intents (S-70a / S-70a2).
enum IntentCategoryMenu {
    nonisolated static let defaultCategories = [
        "Cibo", "Trasporti", "Svago", "Shopping", "Salute",
        "Casa", "Abbonamenti", "Lavoro", "Istruzione", "Viaggi", "Regali", "Altro",
    ]

    struct Movement: Sendable {
        let category: String
        let type: String
        let createdAt: Date
        let isDone: Bool
        let isTransfer: Bool
        let isRecurring: Bool
    }

    /// Custom categories first, then built-in defaults not already present (no duplicates).
    nonisolated static func allCategories(custom: [String]) -> [String] {
        var seen = Set<String>()
        let uniqueCustom = custom.filter { seen.insert($0).inserted }
        return uniqueCustom + defaultCategories.filter { !seen.contains($0) }
    }

    /// Most recently entered completed non-transfer, non-recurring movement of `type`.
    /// Does not fall back to an older choice when the latest movement's category was deleted.
    nonisolated static func lastUsed(history: [Movement], type: String, available: Set<String>) -> String? {
        let latest = history.enumerated().filter {
            $0.element.type == type && $0.element.isDone && !$0.element.isTransfer && !$0.element.isRecurring
        }.max {
            if $0.element.createdAt == $1.element.createdAt { return $0.offset < $1.offset }
            return $0.element.createdAt < $1.element.createdAt
        }?.element
        guard let latest, available.contains(latest.category) else { return nil }
        return latest.category
    }

    /// Deduplicates the top suggestions so identical values only appear once (under Suggested).
    nonisolated static func top(suggested: String?, lastUsed: String?) -> (suggested: String?, lastUsed: String?) {
        let dedupLast = (lastUsed != nil && lastUsed == suggested) ? nil : lastUsed
        return (suggested, dedupLast)
    }

    /// Explicit user choice always wins over automatic suggestion; fallback applies when both are absent.
    nonisolated static func resolve(chosen: String?, suggested: String?, fallback: String) -> String {
        if let trimmed = chosen?.trimmingCharacters(in: .whitespacesAndNewlines), !trimmed.isEmpty {
            return trimmed
        }
        if let suggested, !suggested.isEmpty {
            return suggested
        }
        return fallback
    }

    /// Default income category matching AddIncomeIntent's existing fallback order.
    nonisolated static func incomeFallback(categories: [String]) -> String {
        categories.first { $0 == "Lavoro" } ?? categories.first ?? "Lavoro"
    }

    /// Suggests a category using the same priority as AddTransactionView: exact normalized
    /// history match first, then KeywordCategoryClassifier for descriptions > 2 chars.
    @MainActor
    static func suggested(for name: String, context: ModelContext, available: Set<String>) -> String? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let firstWord = trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isDone && !$0.isTransfer && $0.name.localizedStandardContains(firstWord) },
            sortBy: [SortDescriptor(\Transaction.createdAt)]
        )
        let history = (try? context.fetch(descriptor)) ?? []
        if let previous = LastUsedCategory.suggest(
            for: name,
            history: history.map {
                .init(name: $0.name, category: $0.category, createdAt: $0.createdAt,
                      isDone: $0.isDone, isTransfer: $0.isTransfer)
            },
            availableCategories: available
        ) {
            return previous
        }
        guard trimmed.count > 2 else { return nil }
        let classified = KeywordCategoryClassifier.shared.classify(trimmed)
        guard !classified.isEmpty, classified != "Altro", available.contains(classified) else { return nil }
        return classified
    }

    /// Fetches the single most recently entered transaction for `type` (fetchLimit = 1).
    @MainActor
    static func lastUsed(type: String, context: ModelContext, available: Set<String>) -> String? {
        var descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate {
                $0.type == type && $0.isDone && !$0.isTransfer
                    && $0.templateId == "" && $0.recurringFrequency == ""
            },
            sortBy: [SortDescriptor(\Transaction.createdAt, order: .reverse)]
        )
        descriptor.fetchLimit = 1
        guard let latest = (try? context.fetch(descriptor))?.first,
              available.contains(latest.category) else { return nil }
        return latest.category
    }

    /// Builds the sectioned IntentItemCollection shown by Shortcuts category pickers.
    @MainActor
    static func collection(name: String, type: String, context: ModelContext?) -> IntentItemCollection<String> {
        guard let context else {
            let section = IntentItemSection(LocalizedStringResource("Tutte le categorie"), items: defaultCategories)
            return IntentItemCollection(promptLabel: nil, usesIndexedCollation: false, sections: [section])
        }
        let dbCats = (try? context.fetch(FetchDescriptor<Category>())) ?? []
        let all = allCategories(custom: dbCats.map(\.name))
        let available = Set(all)
        let topPair = top(
            suggested: suggested(for: name, context: context, available: available),
            lastUsed: lastUsed(type: type, context: context, available: available)
        )
        var sections: [IntentItemSection<String>] = []
        if let s = topPair.suggested {
            sections.append(IntentItemSection(LocalizedStringResource("Suggerita"), items: [s]))
        }
        if let l = topPair.lastUsed {
            sections.append(IntentItemSection(LocalizedStringResource("Ultima usata"), items: [l]))
        }
        sections.append(IntentItemSection(LocalizedStringResource("Tutte le categorie"), items: all))
        return IntentItemCollection(promptLabel: nil, usesIndexedCollation: false, sections: sections)
    }
}
