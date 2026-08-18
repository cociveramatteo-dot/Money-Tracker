import SwiftUI
import SwiftData
import Charts

struct StatisticsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
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

                VStack(alignment: .leading, spacing: DS.Space.s) {
                    SectionLabel(text: "Riepilogo")
                        .padding(.top, DS.Space.xl)

                    HStack(alignment: .lastTextBaseline, spacing: DS.Space.xl) {
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Uscite")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.smoke)
                            HeroAmount(amount: monthSpent, size: 44, forceColor: DS.negative)
                        }
                        VStack(alignment: .leading, spacing: 2) {
                            Text("Entrate")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.smoke)
                            HeroAmount(amount: monthIncome, size: 44, forceColor: DS.positive)
                        }
                    }

                    if prevSpent > 0 {
                        HStack(spacing: DS.Space.xs) {
                            Image(systemName: monthSpent - prevSpent >= 0 ? "arrow.up" : "arrow.down")
                                .font(.system(size: 10))
                            Text(abs(monthSpent - prevSpent).currencyFormatted)
                                .font(.system(size: 13, weight: .medium))
                            Text("rispetto al mese scorso")
                                .font(.system(size: 13))
                        }
                        // Più spese del mese scorso = peggioramento (rosso), meno = miglioramento (verde).
                        .foregroundStyle(monthSpent - prevSpent >= 0 ? DS.negative : DS.positive)
                    }

                }
                .padding(.horizontal, DS.Layout.margin)
                .tourAnchor("monthSummary")

                MonthBar(month: $selectedMonth)
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.xl)

                ThinDivider().padding(.top, DS.Space.xl)

                VStack(alignment: .leading, spacing: DS.Space.m) {
                    HStack {
                        SectionLabel(text: trendMonths == 6 ? "Andamento 6 mesi" : "Andamento 12 mesi")
                        Spacer()
                        HStack(spacing: 0) {
                            ForEach([6, 12], id: \.self) { n in
                                Button {
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        trendMonths = n
                                    }
                                } label: {
                                    Text("\(n)m")
                                        .font(.system(size: 12, weight: trendMonths == n ? .semibold : .regular))
                                        .foregroundStyle(trendMonths == n ? DS.paper : DS.smoke)
                                        .padding(.horizontal, DS.Space.m)
                                        .padding(.vertical, DS.Space.xs)
                                        .background(trendMonths == n ? DS.ink : Color.clear)
                                        .clipShape(RoundedRectangle(cornerRadius: 6))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .background(DS.fog)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.l)

                    if trend.allSatisfy({ $0.expenses == 0 && $0.income == 0 }) {
                        Text("Nessun dato disponibile.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, DS.Layout.margin)
                    } else {
                        Chart {
                            ForEach(trend) { stat in
                                BarMark(
                                    x: .value("Mese", stat.label),
                                    y: .value("Importo", stat.income),
                                    width: .ratio(0.35)
                                )
                                .foregroundStyle(DS.positive)
                                .position(by: .value("Tipo", "Entrate"))
                                .cornerRadius(3)

                                BarMark(
                                    x: .value("Mese", stat.label),
                                    y: .value("Importo", stat.expenses),
                                    width: .ratio(0.35)
                                )
                                .foregroundStyle(DS.negative.opacity(0.85))
                                .position(by: .value("Tipo", "Uscite"))
                                .cornerRadius(3)
                            }
                        }
                        .frame(height: 180)
                        .chartYAxis {
                            AxisMarks(position: .leading) { val in
                                AxisValueLabel {
                                    if let d = val.as(Double.self) {
                                        Text(d.currencyCompact)
                                            .font(.system(size: 10))
                                            .foregroundStyle(DS.smoke)
                                    }
                                }
                            }
                        }
                        .chartXAxis {
                            AxisMarks { val in
                                AxisValueLabel {
                                    if let s = val.as(String.self) {
                                        Text(s)
                                            .font(.system(size: 10))
                                            .foregroundStyle(DS.smoke)
                                    }
                                }
                            }
                        }
                        .padding(.horizontal, DS.Layout.margin)

                        HStack(spacing: DS.Space.l) {
                            legendItem(color: DS.positive, label: "Entrate")
                            legendItem(color: DS.negative.opacity(0.85), label: "Uscite")
                        }
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.xs)
                    }
                }
                .tourAnchor("trendChart")

                ThinDivider().padding(.top, DS.Space.l)

                VStack(alignment: .leading, spacing: DS.Space.m) {
                    SectionLabel(text: "Uscite per categoria")
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.l)

                    if categoryData.isEmpty {
                        Text("Nessuna uscita questo mese.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, DS.Layout.margin)
                    } else {
                        // Barre orizzontali per categoria
                        VStack(spacing: 0) {
                            ForEach(categoryData) { cat in
                                VStack(alignment: .leading, spacing: DS.Space.s) {
                                    HStack {
                                        Image(systemName: cat.icon.isEmpty ? "circle.dotted" : cat.icon)
                                            .font(.system(size: 13))
                                            .foregroundStyle(DS.smoke)
                                            .frame(width: 18)
                                        Text(LocalizedStringKey(cat.name))
                                            .font(.system(size: 14))
                                            .foregroundStyle(DS.ink)
                                        Spacer()
                                        Text(cat.amount.currencyFormatted)
                                            .font(.system(size: 13, weight: .medium))
                                            .foregroundStyle(DS.ink)
                                        Text(monthSpent > 0 ? String(format: "%.0f%%", (cat.amount / monthSpent).asDouble * 100) : "0%")
                                            .font(.system(size: 11))
                                            .foregroundStyle(DS.smoke)
                                            .frame(width: 30, alignment: .trailing)
                                    }

                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Rectangle().fill(DS.fog).frame(height: 2)
                                            Rectangle()
                                                .fill(DS.negative)
                                                .frame(width: monthSpent > 0 ? geo.size.width * (cat.amount / monthSpent).asDouble : 0, height: 2)
                                        }
                                    }
                                    .frame(height: 2)
                                }
                                .padding(.horizontal, DS.Layout.margin)
                                .padding(.vertical, DS.Space.m)

                                if cat.id != categoryData.last?.id {
                                    ThinDivider().padding(.leading, DS.Layout.margin + 18 + DS.Space.m)
                                }
                            }
                        }
                    }
                }
                .tourAnchor("categoryBreakdown")

                ThinDivider().padding(.top, DS.Space.l)

                VStack(alignment: .leading, spacing: DS.Space.m) {
                    SectionLabel(text: "Media mensile — ultimi 12 mesi")
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.l)

                    if avgExp == 0 && avgInc == 0 {
                        Text("Dati insufficienti.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, DS.Layout.margin)
                    } else {
                        HStack(spacing: 0) {
                            // Uscite medie
                            VStack(alignment: .leading, spacing: DS.Space.xs) {
                                Text("Uscite medie")
                                    .font(.system(size: 11))
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
                                    .font(.system(size: 11))
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
                            .font(.system(size: 13))
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
        .navigationTitle("Statistiche")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .topBarTrailing) {
                HStack(spacing: DS.Space.m) {
                    // Esporta PDF — un solo tap: genera e apre share sheet automaticamente
                    if isGeneratingPDF {
                        ProgressView()
                            .tint(DS.ink)
                            .scaleEffect(0.8)
                    } else {
                        Button {
                            haptic(.soft)
                            generatePDF()
                        } label: {
                            Image(systemName: "square.and.arrow.up")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.ink)
                        }
                        .disabled(isGeneratingPDF)
                    }
                    // Impostazioni
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.ink)
                    }
                }
            }
        }
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
        } // NavigationStack
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
                            .font(.system(size: 11))
                    }
                    .foregroundStyle(good ? DS.positive : DS.negative)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.vertical, DS.Space.m)
    }

    // MARK: - Helper

    private func legendItem(color: Color, label: String) -> some View {
        HStack(spacing: DS.Space.xs) {
            RoundedRectangle(cornerRadius: 2).fill(color).frame(width: 12, height: 8)
            Text(LocalizedStringKey(label))
                .font(.system(size: 11))
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
