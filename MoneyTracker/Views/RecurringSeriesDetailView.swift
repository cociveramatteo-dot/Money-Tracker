import SwiftUI
import SwiftData

// MARK: - RecurringSeriesDetailView
//
// Sheet di dettaglio per una serie ricorrente: card riassuntiva + storico completo
// delle occorrenze. Ha un proprio @Query così si aggiorna da solo dopo modifica o
// cancellazione, senza binding da far tornare indietro a TransactionsView.

struct RecurringSeriesDetailView: View {
    let seriesID: String

    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    @State private var editing: Transaction? = nil

    private var series: RecurringSeries? {
        RecurringSeriesDetector.detect(from: all).first { $0.id == seriesID }
    }

    var body: some View {
        // Calcolata una sola volta per render: `series` ricalcola il rilevamento
        // su tutte le transazioni (RecurringSeriesDetector.detect), quindi va
        // riusata invece di essere riletta più volte nella stessa `body`.
        let series = self.series
        return NavigationStack {
            Group {
                if let series {
                    List {
                        Section {
                            RecurringSeriesCard(series: series)
                                .padding(.horizontal, DS.Layout.margin)
                                .padding(.vertical, DS.Space.m)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(DS.paper)
                                .listRowSeparator(.hidden)
                        }
                        Section {
                            ForEach(series.occurrences.reversed()) { t in
                                DSTransactionRow(transaction: t)
                                    .padding(.horizontal, DS.Layout.margin)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editing = t }
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(DS.paper)
                                    .listRowSeparatorTint(DS.fog)
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            haptic(.medium)
                                            deleteTransaction(t)
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    }
                            }
                        } header: {
                            SectionLabel(text: "Storico")
                                .padding(.horizontal, DS.Layout.margin)
                                .padding(.bottom, DS.Space.xs)
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(DS.paper)
                                .listRowInsets(EdgeInsets())
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                } else {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Serie eliminata",
                        subtitle: "Tutte le occorrenze di questo pagamento ricorrente sono state cancellate."
                    )
                    .onAppear { dismiss() }
                }
            }
            .background(DS.paper)
            .navigationTitle(series?.name ?? "")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.ink)
                }
            }
            .sheet(item: $editing) { AddTransactionView(editing: $0) }
        }
    }

    private func deleteTransaction(_ t: Transaction) {
        context.delete(t)
        context.safeSave()
    }
}
