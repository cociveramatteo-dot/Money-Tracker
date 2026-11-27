import SwiftUI
import SwiftData

/// Pagina «Abitudini»: movimenti effettuati che si ripetono almeno 3 volte in 3 mesi diversi.
struct HabitsView: View {
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse), SortDescriptor(\Transaction.createdAt, order: .reverse)]) private var all: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    @State private var searchQuery = ""
    @State private var selectedCategory = ""
    @State private var selectedSeries: RecurringSeries? = nil
    @State private var seriesCache = SeriesCache()

    private final class SeriesCache {
        var fingerprint: Int?
        var value: [RecurringSeries] = []
    }

    private func detectedSeries() -> [RecurringSeries] {
        var hasher = Hasher()
        for t in all {
            hasher.combine(t.id); hasher.combine(t.name); hasher.combine(t.category)
            hasher.combine(t.type); hasher.combine(t.date); hasher.combine(t.amount)
            hasher.combine(t.isDone); hasher.combine(t.isTransfer); hasher.combine(t.recurringFrequency)
            hasher.combine(t.categoryIcon)
        }
        let fingerprint = hasher.finalize()
        if seriesCache.fingerprint != fingerprint {
            seriesCache.value = RecurringSeriesDetector.detect(from: all)
            seriesCache.fingerprint = fingerprint
        }
        return seriesCache.value
    }

    private func filteredSeries(from detected: [RecurringSeries]) -> [RecurringSeries] {
        let query = searchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        return detected.filter { s in
            (query.isEmpty || s.name.localizedCaseInsensitiveContains(query))
                && (selectedCategory.isEmpty || s.category == selectedCategory)
        }
    }

    var body: some View {
        let detected = detectedSeries()
        let series = filteredSeries(from: detected)
        VStack(spacing: 0) {
            TransactionsSearchField(text: $searchQuery, identifier: "tf_habitsSearch")
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.s)
                .padding(.bottom, DS.Space.xs)

            if !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.s) {
                        FilterChip(
                            title: Text(String(localized: "Tutte le categorie")),
                            isActive: selectedCategory.isEmpty,
                            style: .secondary
                        ) {
                            selectedCategory = ""
                        }
                        ForEach(categories) { cat in
                            FilterChip(
                                title: DS.categoryText(cat.name),
                                isActive: selectedCategory == cat.name,
                                style: .secondary
                            ) {
                                selectedCategory = (selectedCategory == cat.name ? "" : cat.name)
                            }
                        }
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.vertical, DS.Space.s)
                }
            }

            if detected.isEmpty {
                EmptyStateView(
                    icon: "arrow.triangle.2.circlepath",
                    title: "Nessuna abitudine",
                    subtitle: "I movimenti che si ripetono almeno 3 volte in 3 mesi diversi appariranno qui."
                )
                Spacer()
            } else if series.isEmpty {
                EmptyStateView(
                    icon: "magnifyingglass",
                    title: "Nessun risultato",
                    subtitle: "Nessun movimento corrisponde alla ricerca."
                )
                Spacer()
            } else {
                ScrollView {
                    LazyVStack(spacing: DS.Space.m) {
                        ForEach(series) { s in
                            RecurringSeriesCard(series: s)
                                .contentShape(Rectangle())
                                .accessibilityIdentifier("habitCard_\(s.name)")
                                .onTapGesture { selectedSeries = s }
                        }
                        Color.clear.frame(height: 100)
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.m)
                }
                .scrollIndicators(.hidden)
            }
        }
        .background(DS.paper)
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle("Abitudini")
        .navigationBarTitleDisplayMode(.inline)
        .sheet(item: $selectedSeries) { s in
            RecurringSeriesDetailView(seriesID: s.id)
        }
    }
}
