import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse), SortDescriptor(\Transaction.createdAt, order: .reverse)]) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @State private var selectedMonth = Date()
    @State private var trendMonths: Int = 6   // toggle 6 / 12
    // MARK: - Data per il mese selezionato

    private var monthPartitioned: (expenses: [Transaction], incomeTotal: Decimal) {
        var expenses: [Transaction] = []
        var incomeTotal = Decimal(0)
        // !isTransfer: spostare soldi tra i propri conti non è una spesa né un'entrata
        // reale — includerli gonfierebbe uscite/entrate con importi che si annullano
        // a vicenda nel totale complessivo (vedi anche NotificationManager.checkBudgets).
        for t in transactions where t.isDone && !t.isTransfer && t.date.isSameMonth(as: selectedMonth) {
            if t.transactionType == .uscita  { expenses.append(t) }
            else                             { incomeTotal += t.amount }
        }
        return (expenses, incomeTotal)
    }

    // Spese raggruppate per categoria (ordinate per importo).
    // Funzione invece di computed var: riceve le spese già estratte da monthPartitioned,
    // evitando di richiamare monthPartitioned una terza volta (PERF-03).
    private func buildCategoryData(from expenses: [Transaction]) -> [CategoryStat] {
        var dict: [String: (icon: String, amount: Decimal)] = [:]
        for t in expenses {
            let cur = dict[t.category] ?? (t.categoryIcon, 0)
            dict[t.category] = (cur.icon, cur.amount + t.amount)
        }
        return dict.map { CategoryStat(name: $0.key, icon: $0.value.icon, amount: $0.value.amount) }
            .sorted { $0.amount > $1.amount }
    }

    // MonthStat resta in Double: alimenta Swift Charts (BarMark/LineMark), che richiede
    // un tipo Plottable — Decimal non conforma. La somma avviene comunque in Decimal,
    // convertita a Double solo alla fine (asDouble), non nei modelli.
    private func monthlyTrend(byMonth: [Date: [Transaction]]) -> [MonthStat] {
        let cal = Calendar.current
        return (0..<trendMonths).reversed().compactMap { offset -> MonthStat? in
            guard let month = cal.date(byAdding: .month, value: -offset, to: selectedMonth) else { return nil }
            let key      = cal.dateInterval(of: .month, for: month)?.start ?? month
            let ts       = byMonth[key] ?? []
            let expenses = ts.filter { $0.transactionType == .uscita  }.reduce(Decimal(0)) { $0 + $1.amount }
            let income   = ts.filter { $0.transactionType == .entrata }.reduce(Decimal(0)) { $0 + $1.amount }
            return MonthStat(label: month.shortMonthFormatted, expenses: expenses.asDouble, income: income.asDouble, date: month)
        }
    }

    private func prevMonthSpent(byMonth: [Date: [Transaction]]) -> Decimal {
        let cal = Calendar.current
        guard let prev = cal.date(byAdding: .month, value: -1, to: selectedMonth) else { return 0 }
        let key = cal.dateInterval(of: .month, for: prev)?.start ?? prev
        return (byMonth[key] ?? [])
            .filter { $0.transactionType == .uscita }
            .reduce(Decimal(0)) { $0 + $1.amount }
    }

    // MARK: - Cached byMonth dictionary (PERF-02)
    // transactionsByMonth is O(n) over all transactions; rebuild only when the query changes.
    @State private var cachedByMonth: [Date: [Transaction]] = [:]

    private func rebuildByMonth() {
        let cal = Calendar.current
        var dict: [Date: [Transaction]] = [:]
        // !isTransfer: alimenta trend, confronto anno su anno e medie mensili —
        // gli stessi motivi di monthPartitioned sopra.
        for t in transactions where t.isDone && !t.isTransfer {
            let key = cal.dateInterval(of: .month, for: t.date)?.start ?? t.date
            dict[key, default: []].append(t)
        }
        cachedByMonth = dict
    }

    // MARK: - PDF Report

    @State private var pdfURL: URL?          = nil
    @State private var isGeneratingPDF: Bool  = false
    @State private var showShareSheet: Bool   = false
    @State private var showSettings: Bool     = false
    @State private var showHabits: Bool       = false

    private func generatePDF() {
        guard !isGeneratingPDF else { return }
        isGeneratingPDF = true

        // Estrae i dati necessari come Sendable value types sul main thread,
        // così il Task.detached non tocca mai tipi @MainActor (Transaction/@Model).
        let snapshots = transactions
            .filter { $0.isDone && $0.date.isSameMonth(as: selectedMonth) }
            .sortedForDisplay()
            .map { PDFTxSnapshot(
                name:       $0.name,
                amount:     $0.amount,
                date:       $0.date,
                isIncome:   $0.transactionType == .entrata,
                isDone:     $0.isDone,
                isTransfer: $0.isTransfer,
                category:   $0.category
            ) }
        let prevSpent = prevMonthSpent(byMonth: cachedByMonth)
        let month     = selectedMonth

        Task.detached(priority: .userInitiated) {
            let url = await PDFReportGenerator.generate(
                month: month,
                transactions: snapshots,
                prevMonthSpent: prevSpent
            )
            await MainActor.run {
                pdfURL = url
                isGeneratingPDF = false
            }
        }
    }

    // MARK: - Body

    var body: some View {
        // PERF-03: monthPartitioned scansiona transactions una sola volta.
        // In precedenza era chiamato indirettamente da monthExpenses (×2) e monthIncome (×1),
        // producendo tre O(n) scan per ogni render del body.
        let mp           = monthPartitioned
        let monthExpenses = mp.expenses
        let monthIncome   = mp.incomeTotal
        let monthSpent    = monthExpenses.reduce(Decimal(0)) { $0 + $1.amount }
        let categoryData  = buildCategoryData(from: monthExpenses)
        let byMonth      = cachedByMonth           // O(1) — dict already built in rebuildByMonth()
        let trend        = monthlyTrend(byMonth: byMonth)
        return NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Text("Statistiche")
                        .font(DS.Typo.screenTitle)
                        .tracking(DS.Typo.screenTitleTracking)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                    Spacer()
                    Button { haptic(.soft); generatePDF() } label: {
                        HStack(spacing: 6) {
                            if isGeneratingPDF { ProgressView() }
                            else { Image(systemName: "square.and.arrow.down") }
                            Text("PDF")
                        }
                        .font(DS.Typo.secondary).foregroundStyle(DS.ink)
                        .padding(.horizontal, 14).frame(minHeight: 44)
                        .background(DS.surface, in: RoundedRectangle(cornerRadius: 12))
                        .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(DS.fog))
                    }
                    .disabled(isGeneratingPDF)
                    .accessibilityIdentifier("statistics_pdf")
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44)
                    }.accessibilityLabel("Impostazioni")
                }
                .foregroundStyle(DS.ink).padding(.horizontal, DS.Layout.margin)

                MonthBar(month: $selectedMonth)
                    .frame(minHeight: 44)
                    .padding(.horizontal, DS.Layout.margin)

                HStack(spacing: 8) {
                    summaryTile("Uscite", amount: monthSpent, color: DS.ink)
                    summaryTile("Entrate", amount: monthIncome, color: DS.accent)
                    summaryTile("Netto", amount: monthIncome - monthSpent, color: DS.heroAccent, hero: true)
                }
                .padding(.horizontal, 16)

                VStack(alignment: .leading, spacing: 10) {
                    HStack {
                        Text("Andamento").font(DS.Typo.rowName)
                        Spacer()
                        HStack(spacing: 3) {
                            ForEach([6, 12], id: \.self) { n in
                                Button { trendMonths = n } label: {
                                    Text(verbatim: "\(n)M")
                                        .font(DS.Typo.caption)
                                        .foregroundStyle(trendMonths == n ? DS.ink : DS.smoke)
                                        .frame(minWidth: 44, minHeight: 44)
                                        .background(trendMonths == n ? DS.surface : DS.divider,
                                                    in: RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                                .accessibilityIdentifier("statistics_range_\(n)")
                                .accessibilityAddTraits(trendMonths == n ? [.isSelected] : [])
                            }
                        }.padding(3).background(DS.divider, in: RoundedRectangle(cornerRadius: 10))
                    }
                    HStack(spacing: 14) {
                        legendItem(color: DS.ink, label: "Uscite")
                        legendItem(color: DS.heroAccent, label: "Entrate")
                    }
                    if trend.allSatisfy({ $0.expenses == 0 && $0.income == 0 }) {
                        Text("Nessun dato disponibile.").font(DS.Typo.secondary).foregroundStyle(DS.smoke)
                    } else {
                        Chart {
                            ForEach(trend) { stat in
                                BarMark(x: .value("Mese", stat.label), y: .value("Importo", stat.expenses), width: .ratio(0.65))
                                    .foregroundStyle(DS.ink)
                                    .position(by: .value("Tipo", "Uscite")).cornerRadius(4)
                                BarMark(x: .value("Mese", stat.label), y: .value("Importo", stat.income), width: .ratio(0.65))
                                    .foregroundStyle(DS.heroAccent)
                                    .position(by: .value("Tipo", "Entrate")).cornerRadius(4)
                            }
                        }
                        .frame(height: 130)
                        .chartYAxis(.hidden)
                        .chartXAxis {
                            AxisMarks { value in
                                AxisValueLabel {
                                    if let label = value.as(String.self) {
                                        Text(trendMonths == 12 ? String(label.prefix(1)) : label).font(DS.Typo.tabLabel)
                                            .fontWeight(label == trend.last?.label ? .bold : .regular)
                                            .foregroundStyle(DS.smoke)
                                    }
                                }
                            }
                        }
                        .accessibilityElement(children: .ignore)
                        .accessibilityLabel(trendAccessibilitySummary(trend))
                    }
                }
                .padding(16).background(DS.surface, in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 16).padding(.top, 10)

                VStack(alignment: .leading, spacing: 6) {
                    Text("Per categoria").font(DS.Typo.rowName).padding(.bottom, 4)
                        .accessibilityIdentifier("statistics_categories_title")
                    if categoryData.isEmpty {
                        Text("Nessuna uscita questo mese.").font(DS.Typo.secondary).foregroundStyle(DS.smoke)
                    }
                    ForEach(categoryData) { cat in
                        VStack(alignment: .leading, spacing: 5) {
                            HStack(alignment: .firstTextBaseline, spacing: 8) {
                                DS.categoryText(cat.name).font(DS.Typo.secondary)
                                Spacer(minLength: 4)
                                Text(monthSpent > 0 ? String(format: "%.0f%%", (cat.amount / monthSpent).asDouble * 100) : "0%")
                                    .font(DS.Typo.caption).foregroundStyle(DS.smoke)
                                Text(cat.amount.currencyFormatted).font(DS.Typo.rowAmount)
                                    .fixedSize(horizontal: true, vertical: false)
                            }
                            GeometryReader { geo in
                                Capsule().fill(DS.divider)
                                Capsule().fill(CategoryTint.tint(for: cat.name).foreground)
                                    .frame(width: (categoryData.first?.amount ?? 0) > 0
                                           ? geo.size.width * (cat.amount / categoryData[0].amount).asDouble : 0)
                            }.frame(height: 6)
                        }.padding(.vertical, 5)
                    }
                }
                .foregroundStyle(DS.ink).padding(16)
                .background(DS.surface, in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 16).padding(.top, 10)

                Button { showHabits = true } label: {
                    HStack(spacing: DS.Space.m) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .scaledFont(size: 16)
                            .foregroundStyle(DS.ink)
                            .accessibilityHidden(true)
                        Text("Abitudini")
                            .font(DS.Typo.rowName)
                            .foregroundStyle(DS.ink)
                        Spacer(minLength: DS.Space.s)
                        Image(systemName: "chevron.right")
                            .scaledFont(size: 13, weight: .semibold)
                            .foregroundStyle(DS.smoke)
                            .accessibilityHidden(true)
                    }
                    .padding(.horizontal, 16)
                    .padding(.vertical, 14)
                    .frame(maxWidth: .infinity, minHeight: 44, alignment: .leading)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
                    .overlay(RoundedRectangle(cornerRadius: 18).strokeBorder(DS.fog))
                }
                .buttonStyle(.plain)
                .padding(.horizontal, 16)
                .padding(.top, 10)
                .accessibilityIdentifier("btn_openHabits")

                Spacer(minLength: 100)
            }
        }
        .background(DS.paper)
        .scrollIndicators(.hidden)
        .refreshable { await SyncService.shared.manualRefresh(context: context) }
        .toolbar(.hidden, for: .navigationBar)
        .sheet(isPresented: $showSettings) { SettingsView() }
        .sheet(isPresented: $showShareSheet, onDismiss: { pdfURL = nil }) {
            if let url = pdfURL { ShareSheet(items: [url]) }
        }
        .themedNavBar()
        .onChange(of: pdfURL) { _, url in if url != nil { showShareSheet = true } }
        .onChange(of: selectedMonth) { _, _ in pdfURL = nil }
        // PERF-02: rebuild the byMonth dictionary only when the transaction list changes
        .onAppear { rebuildByMonth() }
        .onChange(of: transactions) { _, _ in rebuildByMonth() }
        .navigationDestination(isPresented: $showHabits) { HabitsView() }
        } // NavigationStack
    }

    private func summaryTile(_ title: LocalizedStringKey, amount: Decimal, color: Color, hero: Bool = false) -> some View {
        VStack(alignment: .leading, spacing: 4) {
            Text(title).font(DS.Typo.caption).foregroundStyle(hero ? DS.heroSecondary : DS.smoke)
            Text(amount.currencyFormatted).font(DS.Typo.rowAmount).foregroundStyle(color)
                .lineLimit(1).minimumScaleFactor(0.65).monospacedDigit()
        }
        .padding(12).frame(maxWidth: .infinity, alignment: .leading)
        .background(hero ? DS.hero : DS.surface, in: RoundedRectangle(cornerRadius: 16))
    }

    // MARK: - Helper

    // Swift Charts non espone di suo alcuna informazione a VoiceOver: senza questa
    // label il grafico a barre risulterebbe muto per un utente non vedente.
    @MainActor
    private func trendAccessibilitySummary(_ trend: [MonthStat]) -> String {
        trend.map { stat in
            "\(stat.label): \(String(localized: "entrate")) \(stat.income.currencyFormatted), \(String(localized: "uscite")) \(stat.expenses.currencyFormatted)"
        }.joined(separator: ". ")
    }

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: DS.Space.xs) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 8)
            Text(LocalizedStringKey(label))
                .font(DS.Typo.caption)
                .foregroundStyle(DS.smoke)
        }
    }
}

// MARK: - Data models for Charts

struct CategoryStat: Identifiable {
    var id: String { name }   // stabile: i nomi categoria sono unici nel dataset
    let name: String
    let icon: String
    let amount: Decimal
}

struct MonthStat: Identifiable {
    var id: Date { date }            // label abbreviato ("Gen") si ripete tra anni diversi
    let label: String
    let expenses: Double
    let income: Double
    let date: Date
}

// MARK: - Date extension for chart labels

extension Date {
    @MainActor var shortMonthFormatted: String {
        String(FormatterCache.shortMonth.string(from: self).prefix(3).capitalized)
    }
}

// MARK: - ShareSheet (UIActivityViewController wrapper)
//
// Permette di presentare il foglio di condivisione nativo via .sheet —
// il foglio appare automaticamente appena il PDF è pronto (un solo tap).

import UIKit

struct ShareSheet: UIViewControllerRepresentable {
    let items: [Any]
    func makeUIViewController(context: Context) -> UIActivityViewController {
        UIActivityViewController(activityItems: items, applicationActivities: nil)
    }
    func updateUIViewController(_ vc: UIActivityViewController, context: Context) {}
}
