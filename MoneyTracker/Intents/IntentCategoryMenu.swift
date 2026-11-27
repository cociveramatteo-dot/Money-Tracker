import AppIntents
import Foundation
import SwiftData

/// Pure category ordering and resolution helpers for App Intents (S-70a / S-70a2 / S-70i).
enum IntentCategoryMenu {
    nonisolated static let defaultCategories = [
        "Cibo", "Trasporti", "Svago", "Shopping", "Salute",
        "Casa", "Abbonamenti", "Lavoro", "Istruzione", "Viaggi", "Regali", "Altro",
    ]

    private nonisolated static let localizableDefaultCategories: Set<String> = [
        "Cibo", "Trasporti", "Svago", "Shopping", "Salute", "Casa",
        "Abbonamenti", "Lavoro", "Istruzione", "Viaggi", "Regali",
        "Risparmio", "Giroconto", "Altro", "Rettifica saldo",
    ]

    nonisolated static let maxRowTitleLength = 34
    nonisolated static let titleSeparator = " · "

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

    /// Deduplicates the top entries in display order: last-used first, then suggested.
    /// When both match, keeps only last-used so a single row is shown.
    nonisolated static func top(suggested: String?, lastUsed: String?) -> (lastUsed: String?, suggested: String?) {
        let dedupSuggested = (suggested != nil && suggested == lastUsed) ? nil : suggested
        return (lastUsed, dedupSuggested)
    }

    /// Filters out categories already shown at the top so the list below has no duplicates.
    nonisolated static func remainingCategories(
        all: [String],
        excluding top: (lastUsed: String?, suggested: String?)
    ) -> [String] {
        let excluded = Set([top.lastUsed, top.suggested].compactMap { $0 })
        return all.filter { !excluded.contains($0) }
    }

    /// Localizes built-in category names while leaving user-defined custom names untouched.
    nonisolated static func localizedCategoryName(_ name: String, bundle: Bundle = .main) -> String {
        guard localizableDefaultCategories.contains(name) else { return name }
        return bundle.localizedString(forKey: name, value: name, table: nil)
    }

    /// Formats a picker row title on a single line (`"Category · Tag"`).
    /// If the combined text exceeds `maxLength`, truncates only the category name with "…"
    /// so the tag remains complete.
    nonisolated static func formattedTitle(
        categoryDisplayName: String,
        tag: String?,
        maxLength: Int = maxRowTitleLength
    ) -> String {
        guard let tag, !tag.isEmpty else { return categoryDisplayName }
        let full = "\(categoryDisplayName)\(titleSeparator)\(tag)"
        guard full.count > maxLength else { return full }
        let budget = maxLength - titleSeparator.count - tag.count
        let shortName: String
        if budget >= 2 {
            var prefix = String(categoryDisplayName.prefix(budget - 1))
            while prefix.last?.isWhitespace == true, prefix.count > 1 {
                prefix.removeLast()
            }
            shortName = "\(prefix)…"
        } else if let first = categoryDisplayName.first {
            shortName = "\(first)…"
        } else {
            return tag
        }
        return "\(shortName)\(titleSeparator)\(tag)"
    }

    /// Builds an IntentItem whose stored value is always the raw `category` name.
    nonisolated static func item(
        for category: String,
        tagKey: String? = nil,
        bundle: Bundle = .main
    ) -> IntentItem<String> {
        let displayName = localizedCategoryName(category, bundle: bundle)
        let tag = tagKey.map { bundle.localizedString(forKey: $0, value: $0, table: nil) }
        let titleText = formattedTitle(categoryDisplayName: displayName, tag: tag)
        return IntentItem(category, title: LocalizedStringResource("\(titleText)"))
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

    nonisolated enum NameSuggestionSource: Equatable, Sendable {
        case history   // same-name history match ("ultima usata" in AddTransactionView)
        case keyword   // keyword classifier match ("suggerita" in AddTransactionView)
    }

    nonisolated struct NameSuggestion: Equatable, Sendable {
        let category: String
        let source: NameSuggestionSource
    }

    nonisolated struct CategoryChoiceDisplay: Equatable, Sendable {
        let id: String
        let title: String
    }

    nonisolated static let lowercaseLastUsedTagKey = "ultima usata"
    nonisolated static let lowercaseSuggestedTagKey = "suggerita"

    /// Mirrors `AddTransactionView.applySuggestion(for:)` so Shortcuts and the in-app form
    /// produce the exact same suggested category and tag ("ultima usata" vs "suggerita").
    nonisolated static func suggestLikeApp(
        for name: String,
        history: [LastUsedCategory.Movement],
        available: Set<String>,
        classify: (String) -> String = { KeywordCategoryClassifier.shared.classify($0) }
    ) -> NameSuggestion? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        if let previous = LastUsedCategory.suggest(
            for: name,
            history: history,
            availableCategories: available
        ) {
            return NameSuggestion(category: previous, source: .history)
        }
        guard trimmed.count > 2 else { return nil }
        let classified = classify(trimmed)
        guard !classified.isEmpty, classified != "Altro", available.contains(classified) else {
            return nil
        }
        return NameSuggestion(category: classified, source: .keyword)
    }

    /// Resolves top display choice matching `AddTransactionView.applySuggestion(for:)` with lowercase tags
    /// and no duplicates below:
    /// - History match for the same name -> single `"ultima usata"` row at the top.
    /// - Otherwise, keyword classifier match (>2 chars, != "Altro") -> single `"suggerita"` row at the top.
    /// - Neither -> no labeled rows at the top; all categories stay in app `sortOrder`.
    nonisolated static func movementChoices(
        all: [String],
        nameSuggestion: NameSuggestion?,
        bundle: Bundle = .main
    ) -> [CategoryChoiceDisplay] {
        let topPair: (lastUsed: String?, suggested: String?)
        switch nameSuggestion {
        case let .some(match):
            switch match.source {
            case .history:
                topPair = (lastUsed: match.category, suggested: nil)
            case .keyword:
                topPair = (lastUsed: nil, suggested: match.category)
            }
        case nil:
            topPair = (lastUsed: nil, suggested: nil)
        }

        var result: [CategoryChoiceDisplay] = []
        if let last = topPair.lastUsed {
            let tag = bundle.localizedString(forKey: lowercaseLastUsedTagKey, value: lowercaseLastUsedTagKey, table: nil)
            let title = formattedTitle(
                categoryDisplayName: localizedCategoryName(last, bundle: bundle),
                tag: tag
            )
            result.append(CategoryChoiceDisplay(id: last, title: title))
        }
        if let sug = topPair.suggested {
            let tag = bundle.localizedString(forKey: lowercaseSuggestedTagKey, value: lowercaseSuggestedTagKey, table: nil)
            let title = formattedTitle(
                categoryDisplayName: localizedCategoryName(sug, bundle: bundle),
                tag: tag
            )
            result.append(CategoryChoiceDisplay(id: sug, title: title))
        }

        let remaining = remainingCategories(all: all, excluding: topPair)
        result.append(contentsOf: remaining.map {
            CategoryChoiceDisplay(id: $0, title: localizedCategoryName($0, bundle: bundle))
        })
        return result
    }

    /// Suggests a category using the same priority as AddTransactionView: exact normalized
    /// history match first, then KeywordCategoryClassifier for descriptions > 2 chars.
    @MainActor
    static func suggestLikeApp(for name: String, context: ModelContext, available: Set<String>) -> NameSuggestion? {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return nil }
        let firstWord = trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isDone && !$0.isTransfer && $0.name.localizedStandardContains(firstWord) },
            sortBy: [SortDescriptor(\Transaction.createdAt)]
        )
        let history = (try? context.fetch(descriptor)) ?? []
        return suggestLikeApp(
            for: name,
            history: history.map {
                .init(name: $0.name, category: $0.category, createdAt: $0.createdAt,
                      isDone: $0.isDone, isTransfer: $0.isTransfer)
            },
            available: available
        )
    }

    @MainActor
    static func suggested(for name: String, context: ModelContext, available: Set<String>) -> String? {
        suggestLikeApp(for: name, context: context, available: available)?.category
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
    static func collection(
        name: String,
        type: String,
        context: ModelContext?,
        bundle: Bundle = .main
    ) -> IntentItemCollection<String> {
        guard let context else {
            let items = defaultCategories.map { item(for: $0, bundle: bundle) }
            let section = IntentItemSection(LocalizedStringResource("Tutte le categorie"), items: items)
            return IntentItemCollection(promptLabel: nil, usesIndexedCollation: false, sections: [section])
        }
        let dbCats = (try? context.fetch(FetchDescriptor<Category>(sortBy: [SortDescriptor(\Category.sortOrder)]))) ?? []
        let all = allCategories(custom: dbCats.map(\.name))
        let available = Set(all)
        let topPair = top(
            suggested: suggested(for: name, context: context, available: available),
            lastUsed: lastUsed(type: type, context: context, available: available)
        )
        var topItems: [IntentItem<String>] = []
        if let last = topPair.lastUsed {
            topItems.append(item(for: last, tagKey: "Ultima usata", bundle: bundle))
        }
        if let sug = topPair.suggested {
            topItems.append(item(for: sug, tagKey: "Suggerita", bundle: bundle))
        }
        let remaining = remainingCategories(all: all, excluding: topPair)
        var sections: [IntentItemSection<String>] = []
        if !topItems.isEmpty {
            sections.append(IntentItemSection(items: topItems))
        }
        if !remaining.isEmpty {
            sections.append(
                IntentItemSection(
                    LocalizedStringResource("Tutte le categorie"),
                    items: remaining.map { item(for: $0, bundle: bundle) }
                )
            )
        }
        return IntentItemCollection(promptLabel: nil, usesIndexedCollation: false, sections: sections)
    }

    /// Builds flat category choices for interactive selection inside `AddMovementIntent.perform()`
    /// and `IntentCategoryChoiceQuery`.
    @MainActor
    static func movementChoices(
        name: String,
        context: ModelContext?,
        bundle: Bundle = .main
    ) -> [CategoryChoiceDisplay] {
        guard let context else {
            return defaultCategories.map {
                CategoryChoiceDisplay(id: $0, title: localizedCategoryName($0, bundle: bundle))
            }
        }
        let catDescriptor = FetchDescriptor<Category>(sortBy: [SortDescriptor(\Category.sortOrder)])
        let dbCats = (try? context.fetch(catDescriptor)) ?? []
        let all = allCategories(custom: dbCats.map(\.name))
        let available = Set(all)
        let suggestion = suggestLikeApp(for: name, context: context, available: available)
        return movementChoices(
            all: all,
            nameSuggestion: suggestion,
            bundle: bundle
        )
    }
}
