import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var accounts: [Account]
    // fetchLimit non è un parametro init di FetchDescriptor (è una var post-init).
    // recentNormal applica .prefix(4) client-side; il dataset dashboard è comunque piccolo.
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @Binding var showAdd: Bool

    @AppStorage("hideBalance")              private var hideBalance: Bool   = false
    @AppStorage("homeAccountOrderedShown") private var homeAccountOrderedShown: String = ""
    @AppStorage("showFixedExpensesTotal")  private var showFixedExpensesTotal: Bool = true
    @AppStorage("showFixedIncomeTotal")    private var showFixedIncomeTotal:   Bool = true

    @State private var showSettings          = false
    @State private var showRecentMovements   = true
    @State private var showAccountOrder      = false
    @State private var editingTransaction: Transaction? = nil

    // MARK: - Conti

    private var includedAccounts: [Account] {
        accounts.filter { !$0.isArchived && !$0.isExcludedFromTotal }
    }

    private var topAccounts: [Account] {
        let ids = homeAccountOrderedShown.split(separator: ",").map { String($0) }
        if ids.isEmpty {
            return Array(includedAccounts.sorted { $0.currentBalance > $1.currentBalance }.prefix(3))
        }
        let ordered = ids.compactMap { id in includedAccounts.first { $0.id.uuidString == id } }
        // Fallback: se nessun UUID corrisponde (es. in modalità demo i conti hanno UUID diversi
        // da quelli salvati in homeAccountOrderedShown), mostra i conti disponibili.
        return ordered.isEmpty
            ? Array(includedAccounts.sorted { $0.currentBalance > $1.currentBalance }.prefix(3))
            : ordered
    }

    // MARK: - Totals

    private var totalCurrent: Decimal { includedAccounts.reduce(0) { $0 + $1.currentBalance } }
    private var totalFuture:  Decimal { includedAccounts.reduce(0) { $0 + $1.futureBalance } }
    private var totalDelta:   Decimal { totalFuture - totalCurrent }

    private var recentNormal: [Transaction] {
        Array(transactions.filter { !$0.isFixed && !$0.isTransfer && $0.recurringFrequency.isEmpty }.prefix(4))
    }

    // Voci fisse del mese corrente, a prescindere da isDone (l'utente vuole
    // sapere quanto spende/incassa di fisso ogni mese anche se non ancora
    // pagato/ricevuto).
    private var monthlyFixedExpensesTotal: Decimal {
        transactions
            .filter { $0.isFixed && !$0.isTransfer && $0.transactionType == .uscita && $0.date.isSameMonth(as: Date()) }
            .reduce(0) { $0 + $1.amount }
    }

    private var monthlyFixedIncomeTotal: Decimal {
        transactions
            .filter { $0.isFixed && !$0.isTransfer && $0.transactionType == .entrata && $0.date.isSameMonth(as: Date()) }
            .reduce(0) { $0 + $1.amount }
    }

    // MARK: - Body
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    saldoHeroSection
                    if abs(totalDelta) > 0.001 {
                        saldoFuturoSection
                    }
                    ThinDivider()
                        .padding(.top, abs(totalDelta) > 0.001 ? DS.Space.l : DS.Space.xl)
                    fisseDelMeseSection
                    ultimiMovimentiSection
                    Spacer(minLength: 100)
                }
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .refreshable { await SyncService.shared.manualRefresh(context: context) }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DS.Space.m) {
                        Button {
                            withAnimation(.easeInOut(duration: 0.2)) { hideBalance.toggle() }
                        } label: {
                            Image(systemName: hideBalance ? "eye.slash" : "eye")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.ink)
                        }
                        .tourAnchor("eyeButton")

                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.ink)
                        }
                    }
                }
            }
            .themedNavBar()
            .sheet(isPresented: $showSettings)     { SettingsView() }
            .sheet(item: $editingTransaction)       { AddTransactionView(editing: $0) }
            .sheet(isPresented: $showAccountOrder)  {
                HomeAccountOrderSheet(
                    orderedShown: $homeAccountOrderedShown,
                    allAccounts:  includedAccounts.sorted { $0.currentBalance > $1.currentBalance }
                )
            }
        }
    }

    // MARK: - Saldo Attuale (hero)
    private var saldoHeroSection: some View {
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "Saldo attuale")
                .padding(.top, DS.Space.xl)
            HeroAmount(amount: totalCurrent, hidden: hideBalance, colorBySign: true)
                .tourAnchor("balanceHero")

            if !topAccounts.isEmpty {
                HStack(alignment: .bottom, spacing: 0) {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(alignment: .bottom, spacing: DS.Space.l) {
                            ForEach(topAccounts) { acc in
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(acc.name)
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.smoke)
                                    Text(hideBalance ? "• • •" : acc.currentBalance.currencyFormatted)
                                        .font(.system(size: 13, weight: .medium))
                                        .foregroundStyle(hideBalance ? DS.ink : DS.signColor(acc.currentBalance))
                                }
                            }
                        }
                        .padding(.trailing, DS.Space.m)
                    }
                    Button { showAccountOrder = true } label: {
                        Image(systemName: "slider.horizontal.3")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                    }
                    .tourAnchor("accountPanel")
                }
                .padding(.top, DS.Space.xs)
            }
        }
        .padding(.horizontal, DS.Layout.margin)
    }

    // MARK: - Saldo atteso (futuro)
    private var saldoFuturoSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            ThinDivider().padding(.top, DS.Space.xl)

            VStack(alignment: .leading, spacing: DS.Space.s) {
                SectionLabel(text: "Saldo atteso")
                    .padding(.top, DS.Space.l)

                HeroAmount(amount: totalFuture, size: 48, hidden: hideBalance, colorBySign: true)

                if totalDelta != 0 {
                    HStack(spacing: DS.Space.xs) {
                        Text(totalDelta >= 0 ? "▲" : "▼")
                            .font(.system(size: 10))
                        Text(hideBalance ? "• • •" : abs(totalDelta).currencyFormatted)
                            .font(.system(size: 13, weight: .medium))
                        Text(LocalizedStringKey(totalDelta >= 0 ? "in entrata pianificate" : "in uscite pianificate"))
                            .font(.system(size: 13))
                    }
                    .foregroundStyle(totalDelta >= 0 ? DS.positive : DS.negative)
                }

                if topAccounts.count > 1 {
                    VStack(alignment: .leading, spacing: DS.Space.xs) {
                        ForEach(topAccounts) { acc in
                            if abs(acc.plannedDelta) > 0.001 {
                                HStack(spacing: DS.Space.xs) {
                                    Text(acc.name)
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.smoke)
                                    Text("→")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.smoke)
                                    Text(hideBalance ? "• • •" : acc.futureBalance.currencyFormatted)
                                        .font(.system(size: 11, weight: .medium))
                                        .foregroundStyle(hideBalance ? DS.ink : DS.signColor(acc.futureBalance))
                                }
                            }
                        }
                    }
                    .padding(.top, DS.Space.xs)
                }
            }
            .padding(.horizontal, DS.Layout.margin)
            .padding(.bottom, DS.Space.l)
            .tourAnchor("saldoAtteso")
        }
    }

    // MARK: - Fisse del mese

    @ViewBuilder
    private var fisseDelMeseSection: some View {
        if showFixedExpensesTotal || showFixedIncomeTotal {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                SectionLabel(text: "Fissi del mese")
                    .padding(.top, DS.Space.l)

                HStack(spacing: DS.Space.m) {
                    if showFixedExpensesTotal {
                        FixedTotalTile(
                            title: "Spese fisse",
                            amount: monthlyFixedExpensesTotal,
                            color: DS.negative,
                            hidden: hideBalance
                        )
                    }
                    if showFixedIncomeTotal {
                        FixedTotalTile(
                            title: "Entrate fisse",
                            amount: monthlyFixedIncomeTotal,
                            color: DS.positive,
                            hidden: hideBalance
                        )
                    }
                }
            }
            .padding(.horizontal, DS.Layout.margin)
            .padding(.bottom, DS.Space.l)
        }
    }

    // MARK: - Ultimi Movimenti

    private var ultimiMovimentiSection: some View {
        VStack(alignment: .leading, spacing: 0) {

            Button {
                withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                    showRecentMovements.toggle()
                }
            } label: {
                HStack {
                    SectionLabel(text: "Ultimi movimenti")
                    Spacer()
                    Image(systemName: showRecentMovements ? "chevron.up" : "chevron.down")
                        .font(.system(size: 11))
                        .foregroundStyle(DS.smoke)
                        .animation(.spring(response: 0.35, dampingFraction: 0.8), value: showRecentMovements)
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.l)
                .padding(.bottom, DS.Space.m)
            }
            .buttonStyle(.plain)

            if showRecentMovements {
                if recentNormal.isEmpty {
                    // PERF-BUG: was List+fixed height which broke Dynamic Type; now EmptyStateView
                    EmptyStateView(
                        icon: "tray",
                        title: "Nessun movimento",
                        subtitle: "Premi + per aggiungere la tua prima spesa."
                    )
                    .transition(.opacity)
                } else {
                    // List enables native swipeActions (only available inside List).
                    // scrollDisabled(true) prevents inner-scroll conflict with the outer
                    // ScrollView. Row height is fixed (fonts use explicit size:, not Dynamic
                    // Type scalable), so a static multiplier is safe:
                    //   rowVPad(14) × 2 + lineH(18) + spacing(2) + lineH(14) ≈ 66 pt/row.
                    let rowH: CGFloat = 66
                    List {
                        ForEach(recentNormal) { t in
                            DSTransactionRow(transaction: t)
                                .padding(.horizontal, DS.Layout.margin)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(DS.paper)
                                .listRowSeparatorTint(DS.fog)
                                .contentShape(Rectangle())
                                .onTapGesture { editingTransaction = t }
                                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                    Button(role: .destructive) {
                                        haptic(.medium)
                                        context.delete(t)
                                        context.safeSave()
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                }
                                .contextMenu {
                                    Button {
                                        haptic(.soft)
                                        editingTransaction = t
                                    } label: {
                                        Label("Modifica", systemImage: "pencil")
                                    }
                                    Button(role: .destructive) {
                                        haptic(.medium)
                                        context.delete(t)
                                        context.safeSave()
                                    } label: {
                                        Label("Elimina", systemImage: "trash")
                                    }
                                }
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollDisabled(true)
                    .frame(height: CGFloat(recentNormal.count) * rowH)
                    .transition(.opacity)
                }
            }
        }
    }
}

// MARK: - HomeAccountOrderSheet

struct HomeAccountOrderSheet: View {
    @Binding var orderedShown: String
    let allAccounts: [Account]
    @Environment(\.dismiss) private var dismiss

    @State private var items: [Account] = []
    @State private var shown: Set<String> = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(items) { acc in
                    HStack(spacing: DS.Space.m) {
                        Button {
                            let id = acc.id.uuidString
                            if shown.contains(id) {
                                if shown.count > 1 { shown.remove(id) }
                            } else {
                                shown.insert(id)
                                if let fromIdx = items.firstIndex(where: { $0.id.uuidString == id }) {
                                    let item = items.remove(at: fromIdx)
                                    let insertAt = (items.lastIndex(where: { shown.contains($0.id.uuidString) }).map { $0 + 1 }) ?? 0
                                    items.insert(item, at: insertAt)
                                }
                            }
                        } label: {
                            Image(systemName: shown.contains(acc.id.uuidString)
                                  ? "checkmark.circle.fill" : "circle")
                                .font(.system(size: 20))
                                .foregroundStyle(shown.contains(acc.id.uuidString) ? DS.ink : DS.smoke)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(acc.name)
                                .font(.system(size: 15, weight: .medium))
                                .foregroundStyle(DS.ink)
                            Text(acc.accountType.localizedName)
                                .font(.system(size: 12))
                                .foregroundStyle(DS.smoke)
                        }
                        Spacer()
                    }
                    .padding(.vertical, 4)
                    .listRowBackground(DS.paper)
                    .listRowSeparatorTint(DS.fog)
                }
                .onMove { from, to in items.move(fromOffsets: from, toOffset: to) }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DS.paper)
            .environment(\.editMode, .constant(.active))
            .navigationTitle("Conti in home")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    GhostButton(title: "Annulla") { dismiss() }
                }
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { save(); dismiss() }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.ink)
                }
            }
            .onAppear { loadOrder() }
        }
        .presentationBackground(DS.paper)
    }

    private func loadOrder() {
        let ids = orderedShown.split(separator: ",").map { String($0) }
        if ids.isEmpty {
            items = allAccounts
            shown = Set(allAccounts.map { $0.id.uuidString })
        } else {
            var ordered = ids.compactMap { id in allAccounts.first { $0.id.uuidString == id } }
            let newAccs = allAccounts.filter { !ids.contains($0.id.uuidString) }
            ordered.append(contentsOf: newAccs)
            items = ordered
            shown = Set(ids)
        }
    }

    private func save() {
        let visibleIds = items
            .filter { shown.contains($0.id.uuidString) }
            .map { $0.id.uuidString }
        orderedShown = visibleIds.joined(separator: ",")
    }
}
