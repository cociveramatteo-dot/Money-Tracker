import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @State private var selectedMonth = Date()
    @State private var trendMonths: Int = 6   // toggle 6 / 12
    @Environment(\.scenePhase) private var scenePhase
    @State private var comparisonNow = Date()
    @State private var cachedComparison: MonthlySpendingComparison?

    /// Snapshot costruito fuori dal body: eseguito solo al cambio di transazioni, mese o giorno.
    private func rebuildComparison() {
        let entries: [MonthlySpendingComparison.Entry] = transactions.map {
            .init(date: $0.date, amount: $0.amount, category: $0.category,
                  isExpense: $0.transactionType == .uscita, isDone: $0.isDone, isTransfer: $0.isTransfer)
        }
        cachedComparison = MonthlySpendingComparison.make(
            entries: entries, month: selectedMonth,
            now: Calendar.current.startOfDay(for: comparisonNow), calendar: .current)
    }

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

    private func last12Stats(byMonth: [Date: [Transaction]]) -> [MonthStat] {
        let cal = Calendar.current
        return (0..<12).reversed().compactMap { offset -> MonthStat? in
            guard let month = cal.date(byAdding: .month, value: -offset, to: Date()) else { return nil }
            let key      = cal.dateInterval(of: .month, for: month)?.start ?? month
            let ts       = byMonth[key] ?? []
            let expenses = ts.filter { $0.transactionType == .uscita  }.reduce(Decimal(0)) { $0 + $1.amount }
            let income   = ts.filter { $0.transactionType == .entrata }.reduce(Decimal(0)) { $0 + $1.amount }
            return MonthStat(label: month.shortMonthFormatted, expenses: expenses.asDouble, income: income.asDouble, date: month)
        }
    }

    // MARK: - Media mensile (ultimi 12 mesi)

    private func avgMonthlyExpenses(stats: [MonthStat]) -> Double {
        let nonZero = stats.filter { $0.expenses > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0) { $0 + $1.expenses } / Double(nonZero.count)
    }

    private func avgMonthlyIncome(stats: [MonthStat]) -> Double {
        let nonZero = stats.filter { $0.income > 0 }
        guard !nonZero.isEmpty else { return 0 }
        return nonZero.reduce(0) { $0 + $1.income } / Double(nonZero.count)
    }

    // MARK: - Confronto anno corrente vs anno precedente

    // PERF-02: takes byMonth as parameter to avoid re-computing transactionsByMonth
    private func yearTotals(year: Int, byMonth: [Date: [Transaction]]) -> (expenses: Decimal, income: Decimal) {
        let cal = Calendar.current
        var expenses = Decimal(0), income = Decimal(0)
        for (key, ts) in byMonth {
            guard cal.component(.year, from: key) == year else { continue }
            for t in ts {
                if t.transactionType == .uscita  { expenses += t.amount }
                else                             { income  += t.amount }
            }
        }
        return (expenses, income)
    }

    private var currentYear: Int { Calendar.current.component(.year, from: Date()) }

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

    private func generatePDF() {
        guard !isGeneratingPDF else { return }
        isGeneratingPDF = true

        // Estrae i dati necessari come Sendable value types sul main thread,
        // così il Task.detached non tocca mai tipi @MainActor (Transaction/@Model).
        let snapshots = transactions
            .filter { $0.isDone && $0.date.isSameMonth(as: selectedMonth) }
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
        let prevSpent    = prevMonthSpent(byMonth: byMonth)
        let trend        = monthlyTrend(byMonth: byMonth)
        let l12          = last12Stats(byMonth: byMonth)
        let avgExp       = avgMonthlyExpenses(stats: l12)
        let avgInc       = avgMonthlyIncome(stats: l12)
        let curYear      = yearTotals(year: currentYear,     byMonth: byMonth)
        let prevYear     = yearTotals(year: currentYear - 1, byMonth: byMonth)
        return NavigationStack {
        ScrollView {
            VStack(alignment: .leading, spacing: 0) {

                HStack {
                    Text("Statistiche").font(DS.Typo.screenTitle)
                        .tracking(DS.Typo.screenTitleTracking)
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
                    Divider().overlay(DS.divider)
                    ViewThatFits(in: .horizontal) {
                        HStack {
                            Text("Uscite medie")
                            Spacer()
                            Text(avgExp.currencyFormatted).foregroundStyle(DS.ink).monospacedDigit()
                        }
                        VStack(alignment: .leading) {
                            Text("Uscite medie")
                            Text(avgExp.currencyFormatted).foregroundStyle(DS.ink).monospacedDigit()
                        }
                    }.font(DS.Typo.caption).foregroundStyle(DS.smoke)
                }
                .padding(16).background(DS.surface, in: RoundedRectangle(cornerRadius: 22))
                .padding(.horizontal, 16).padding(.top, 10)

                SpendingComparisonCard(comparison: cachedComparison)
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

                if prevSpent > 0 {
                    HStack(spacing: 4) {
                        Image(systemName: monthSpent - prevSpent >= 0 ? "arrow.up" : "arrow.down")
                        Text(abs(monthSpent - prevSpent).currencyFormatted)
                        Text("rispetto al mese scorso")
                    }
                    .font(DS.Typo.caption)
                    .foregroundStyle(monthSpent - prevSpent >= 0 ? DS.negative : DS.positive)
                    .padding(16)
                }

                VStack(alignment: .leading, spacing: DS.Space.m) {
                    SectionLabel(text: "Media mensile — ultimi 12 mesi")
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.l)

                    if avgExp == 0 && avgInc == 0 {
                        Text("Dati insufficienti.")
                            .font(DS.Typo.secondary)
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, DS.Layout.margin)
                    } else {
                        HStack(spacing: 0) {
                            // Uscite medie
                            VStack(alignment: .leading, spacing: DS.Space.xs) {
                                Text("Uscite medie")
                                    .font(DS.Typo.caption)
                                    .foregroundStyle(DS.smoke)
                                Text(avgExp.currencyFormatted)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(DS.negative)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DS.Space.l)
                            .background(DS.fog.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))

                            Spacer().frame(width: DS.Space.m)

                            // Entrate medie
                            VStack(alignment: .leading, spacing: DS.Space.xs) {
                                Text("Entrate medie")
                                    .font(DS.Typo.caption)
                                    .foregroundStyle(DS.smoke)
                                Text(avgInc.currencyFormatted)
                                    .font(.system(size: 22, weight: .semibold))
                                    .foregroundStyle(DS.positive)
                                    .minimumScaleFactor(0.7)
                                    .lineLimit(1)
                            }
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(DS.Space.l)
                            .background(DS.fog.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                        .padding(.horizontal, DS.Layout.margin)
                    }
                }

                ThinDivider().padding(.top, DS.Space.l)

                VStack(alignment: .leading, spacing: DS.Space.m) {
                    SectionLabel(text: "Anno \(currentYear) vs \(currentYear - 1)")
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.l)

                    if curYear.expenses == 0 && prevYear.expenses == 0 {
                        Text("Dati insufficienti.")
                            .font(DS.Typo.secondary)
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, DS.Layout.margin)
                    } else {
                        VStack(spacing: 0) {
                            yearCompareRow(
                                label: "Uscite",
                                current: curYear.expenses,
                                prev: prevYear.expenses,
                                invertSign: true  // più spese = peggioramento
                            )
                            ThinDivider().padding(.horizontal, DS.Layout.margin)
                            yearCompareRow(
                                label: "Entrate",
                                current: curYear.income,
                                prev: prevYear.income,
                                invertSign: false
                            )
                        }
                    }
                }

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
        .onAppear { rebuildByMonth(); comparisonNow = Date(); rebuildComparison() }
        .onChange(of: selectedMonth) { _, _ in rebuildComparison() }
        .onChange(of: comparisonNow) { _, _ in rebuildComparison() }
        .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in comparisonNow = Date() }
        .onChange(of: scenePhase) { _, phase in if phase == .active { comparisonNow = Date() } }
        .onChange(of: transactions) { _, _ in rebuildByMonth(); rebuildComparison() }
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

    // MARK: - Anno compare row helper

    private func yearCompareRow(label: LocalizedStringKey, current: Decimal, prev: Decimal, invertSign: Bool) -> some View {
        HStack {
            Text(label)
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
            Spacer()
            VStack(alignment: .trailing, spacing: 2) {
                Text(current.currencyFormatted)
                    .font(.system(size: 15, weight: .medium))
                    .foregroundStyle(DS.ink)
                if prev > 0 {
                    let delta = current - prev
                    let sign  = delta >= 0 ? "+" : "−"
                    // Bug fix: always use the positive percentage; the sign prefix and
                    // arrow icon already convey direction. Previously "-pct" produced
                    // "↓ -30%" (double negative) when delta was negative.
                    let pct   = abs((delta / prev).asDouble * 100)
                    let good  = invertSign ? delta < 0 : delta > 0
                    HStack(spacing: 2) {
                        Image(systemName: delta >= 0 ? "arrow.up" : "arrow.down")
                            .font(.system(size: 9))
                        Text("\(sign)\(String(format: "%.0f", pct))% vs \(currentYear - 1)")
                            .font(DS.Typo.caption)
                    }
                    .foregroundStyle(good ? DS.positive : DS.negative)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.vertical, DS.Space.m)
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
