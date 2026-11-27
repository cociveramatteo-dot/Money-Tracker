import SwiftUI
import SwiftData

struct DashboardView: View {
    @Query private var accounts: [Account]
    // fetchLimit non è un parametro init di FetchDescriptor (è una var post-init).
    // recentNormal applica .prefix(4) client-side; il dataset dashboard è comunque piccolo.
    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse), SortDescriptor(\Transaction.createdAt, order: .reverse)]) private var transactions: [Transaction]
    @Environment(\.modelContext) private var context
    @Environment(\.scenePhase) private var scenePhase
    @Binding var showAdd: Bool
    /// Cambia tab dalla Home («Gestisci» → Conti, «Vedi tutti» → Movimenti).
    var goToTab: (Int) -> Void = { _ in }

    @AppStorage("hideBalance")              private var hideBalance: Bool   = false
    @AppStorage("homeAccountOrderedShown") private var homeAccountOrderedShown: String = ""
    @AppStorage("showFixedExpensesTotal")  private var showFixedExpensesTotal: Bool = true
    @AppStorage("showFixedIncomeTotal")    private var showFixedIncomeTotal:   Bool = true

    @State private var showSettings          = false
    @State private var showRecentMovements   = true
    @State private var showAccountOrder      = false
    @State private var editingTransaction: Transaction? = nil
    @State private var projectionDay = Calendar.current.startOfDay(for: Date())
    @State private var trail: BalanceTrail? = nil
    @State private var recentListHeight: CGFloat?
    @ScaledMetric(relativeTo: .body) private var estimatedRowHeight: CGFloat = 66

    private struct TrailInput: Equatable {
        let currentBalance: Decimal
        let day: Date
        let entries: [BalanceTrail.Entry]
    }

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

    private var recentNormal: [Transaction] {
        Array(transactions.filter { !$0.isFixed && !$0.isTransfer && $0.recurringFrequency.isEmpty }.sortedForDisplay().prefix(4))
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

    private func money(_ value: Decimal) -> String {
        hideBalance ? "•••• \(Double.currencySymbol)" : value.currencyFormatted
    }

    // MARK: - Serie TrailView

    /// Cache della proiezione: evita di ricostruire entry e dizionario a ogni render non legato ai dati
    /// (es. oscura importi, altezza lista). Non è @State osservato: si scrive solo la scatola, mai durante l'osservazione.
    private final class ProjectionCache {
        var fingerprint: Int?
        var value: (trailInput: TrailInput, plannedByAccount: [PersistentIdentifier: Decimal])?
    }
    @State private var projectionCache = ProjectionCache()

    /// Impronta di TUTTO ciò che `buildMonthlyProjection` legge: se non cambia, il risultato è identico.
    private func projectionFingerprint() -> Int {
        var hasher = Hasher()
        hasher.combine(projectionDay)
        hasher.combine(totalCurrent)
        for account in includedAccounts { hasher.combine(account.persistentModelID) }
        for t in transactions {
            hasher.combine(t.persistentModelID)
            hasher.combine(t.account?.persistentModelID)
            hasher.combine(t.date)
            hasher.combine(t.amount)
            hasher.combine(t.type)
            hasher.combine(t.isDone)
            hasher.combine(t.isFixed)
            hasher.combine(t.isTransfer)
            hasher.combine(t.templateId)
            hasher.combine(t.recurringFrequency)
        }
        return hasher.finalize()
    }

    private func monthlyProjection() -> (trailInput: TrailInput, plannedByAccount: [PersistentIdentifier: Decimal]) {
        let fingerprint = projectionFingerprint()
        if let cached = projectionCache.value, projectionCache.fingerprint == fingerprint { return cached }
        let value = buildMonthlyProjection()
        projectionCache.fingerprint = fingerprint
        projectionCache.value = value
        return value
    }

    private func buildMonthlyProjection() -> (trailInput: TrailInput, plannedByAccount: [PersistentIdentifier: Decimal]) {
        let calendar = Calendar.current
        let ids = Set(includedAccounts.map(\.persistentModelID))
        var entries: [BalanceTrail.Entry] = []
        var plannedByAccount: [PersistentIdentifier: Decimal] = [:]

        for transaction in transactions {
            guard let accountID = transaction.account?.persistentModelID, ids.contains(accountID) else { continue }
            guard Self.countsInProjection(transaction, projectionDay: projectionDay, calendar: calendar) else { continue }

            let amount = transaction.signedAmount
            entries.append(.init(date: transaction.date, signedAmount: amount, isDone: transaction.isDone))
            if !transaction.isDone {
                plannedByAccount[accountID, default: 0] += amount
            }
        }

        return (TrailInput(currentBalance: totalCurrent, day: projectionDay, entries: entries), plannedByAccount)
    }

    /// Una spesa fissa singola pianificata (senza ricorrenza) pesa sulla previsione solo nel mese della sua data (S-41).
    /// Tutto il resto — fatti, entrate, trasferimenti, serie ricorrenti, spese non fisse — conta sempre.
    static func countsInProjection(_ transaction: Transaction, projectionDay: Date, calendar: Calendar = .current) -> Bool {
        let isOneOffFixedExpense = transaction.isFixed && transaction.transactionType == .uscita
            && !transaction.isTransfer && transaction.templateId.isEmpty && transaction.recurringFrequency.isEmpty
        guard !transaction.isDone && isOneOffFixedExpense else { return true }
        return calendar.isDate(transaction.date, equalTo: projectionDay, toGranularity: .month)
    }

    private func refreshProjectionDay() {
        projectionDay = Calendar.current.startOfDay(for: Date())
    }

    // MARK: - Body
    var body: some View {
        let projection = monthlyProjection()
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    header
                    saldoHeroSection
                    contiSection(plannedByAccount: projection.plannedByAccount)
                    fisseDelMeseSection
                    ultimiMovimentiSection
                    // Lascia scorrere anche l’ultimo importo sopra il pulsante + flottante.
                    Color.clear.frame(height: 72)
                        .accessibilityHidden(true)
                }
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .refreshable { await SyncService.shared.manualRefresh(context: context) }
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: projection.trailInput, initial: true) { _, input in
                trail = BalanceTrail.make(currentBalance: input.currentBalance, entries: input.entries, now: input.day)
            }
            .onChange(of: scenePhase) { _, phase in
                if phase == .active { refreshProjectionDay() }
            }
            .onReceive(NotificationCenter.default.publisher(for: .NSCalendarDayChanged)) { _ in
                refreshProjectionDay()
            }
            .onReceive(NotificationCenter.default.publisher(for: UIApplication.significantTimeChangeNotification)) { _ in
                refreshProjectionDay()
            }
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

    // MARK: - Header

    private var header: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(Date(), format: .dateTime.weekday(.wide).day().month(.wide))
                    .font(DS.Typo.secondary).foregroundStyle(DS.smoke)
                Text("Bucktrail").font(DS.Typo.wordmark).tracking(-0.5).foregroundStyle(DS.ink)
            }
            Spacer(minLength: DS.Space.s)
            HStack(spacing: DS.Space.s) {
                headerButton(symbol: hideBalance ? "eye.slash" : "eye",
                             label: hideBalance ? "Mostra importi" : "Oscura importi") {
                    withAnimation(.easeInOut(duration: 0.2)) { hideBalance.toggle() }
                }
                headerButton(symbol: "gearshape", label: "Impostazioni") { showSettings = true }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.top, DS.Space.s)
        .padding(.bottom, DS.Space.m)
    }

    private func headerButton(symbol: String, label: LocalizedStringKey, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: symbol)
                .scaledFont(size: 18)
                .foregroundStyle(DS.ink)
                .frame(width: 44, height: 44)
                .background(DS.surface, in: RoundedRectangle(cornerRadius: 14))
                .overlay(RoundedRectangle(cornerRadius: 14).strokeBorder(DS.fog, lineWidth: 1))
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }

    // MARK: - Hero (saldo attuale + TrailView + saldo atteso)

    @ViewBuilder
    private var saldoHeroSection: some View {
        if let trail {
            let cal = Calendar.current
            let start = cal.dateInterval(of: .month, for: projectionDay)?.start ?? projectionDay
            let end = cal.date(byAdding: .day, value: trail.daysInMonth - 1, to: start) ?? start
            HomeHeroCard(
                amount: Text(money(totalCurrent)),
                trail: trail,
                monthStart: start,
                monthEnd: end,
                expectedAmount: abs(trail.plannedDelta) > 0.001 ? Text(money(trail.expectedBalance)) : nil,
                plannedSummary: abs(trail.plannedDelta) > 0.001
                    ? plannedSummary(count: trail.plannedCount, delta: trail.plannedDelta) : nil
            )
            .padding(.horizontal, 16)
        }
    }

    private func plannedSummary(count: Int, delta: Decimal) -> Text {
        let amount = money(delta)
        let sign = delta > 0 && !hideBalance ? "+" : ""
        let label = count == 1
            ? Text("1 movimento pianificato")
            : Text("\(count) movimenti pianificati")
        return Text("\(label)\n\(sign)\(amount)")
    }

    // MARK: - Conti (scroll orizzontale)

    @ViewBuilder
    private func contiSection(plannedByAccount: [PersistentIdentifier: Decimal]) -> some View {
        if !topAccounts.isEmpty {
            sectionHeader("Conti", link: "Gestisci") { goToTab(4) } trailing: {
                Button { showAccountOrder = true } label: {
                    Image(systemName: "slider.horizontal.3")
                        .scaledFont(size: 14).foregroundStyle(DS.smoke)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Conti in home")
            }
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.s) {
                    ForEach(topAccounts) { account in
                        accountCard(account, plannedDelta: plannedByAccount[account.persistentModelID, default: 0])
                    }
                }
                .padding(.horizontal, 16)
            }
        }
    }

    private func accountCard(_ acc: Account, plannedDelta: Decimal) -> some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: DS.Space.s) {
                RoundedRectangle(cornerRadius: 3).fill(accountTint(acc)).frame(width: 10, height: 10)
                Text(acc.name).font(DS.Typo.secondary).foregroundStyle(DS.smoke).lineLimit(1)
            }
            Text(money(acc.currentBalance)).font(DS.Typo.rowAmount).foregroundStyle(DS.ink)
                .lineLimit(1).minimumScaleFactor(0.7)
            if abs(plannedDelta) > 0.001 {
                Text("→ \(money(acc.currentBalance + plannedDelta))").font(DS.Typo.caption).foregroundStyle(DS.plannedText)
                    .lineLimit(1).minimumScaleFactor(0.7)
            } else {
                Text("nessun movimento").font(DS.Typo.caption).foregroundStyle(DS.smoke).lineLimit(1)
            }
        }
        .padding(.horizontal, 14).padding(.vertical, DS.Space.m)
        .frame(width: 148, alignment: .leading)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: 18))
        .accessibilityElement(children: .combine)
    }

    /// Tinta adattiva per tipo di conto (colorHex dei conti è spesso grigio e non adattivo).
    private func accountTint(_ acc: Account) -> Color {
        switch acc.accountType {
        case .conto:        return DS.accent
        case .risparmio:    return DS.transfer
        case .carta:        return DS.planned
        case .contanti:     return DS.smoke
        case .investimento: return DS.ink
        }
    }

    // MARK: - Intestazione di sezione

    private func sectionHeader<Trailing: View>(
        _ title: LocalizedStringKey, link: LocalizedStringKey,
        action: @escaping () -> Void, @ViewBuilder trailing: () -> Trailing = { EmptyView() }
    ) -> some View {
        HStack(alignment: .center, spacing: DS.Space.xs) {
            Text(title).font(DS.Typo.sectionTitle).foregroundStyle(DS.ink)
            Spacer()
            trailing()
            Button(action: action) {
                Text(link).font(DS.Typo.secondary).fontWeight(.semibold).foregroundStyle(DS.accent)
                    .frame(minHeight: 44)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.top, DS.Space.l)
    }

    // MARK: - Fisse del mese

    @ViewBuilder
    private var fisseDelMeseSection: some View {
        if showFixedExpensesTotal || showFixedIncomeTotal {
            VStack(alignment: .leading, spacing: DS.Space.m) {
                Text("Fissi del mese").font(DS.Typo.sectionTitle).foregroundStyle(DS.ink)
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
        }
    }

    // MARK: - Ultimi Movimenti

    private var ultimiMovimentiSection: some View {
        VStack(alignment: .leading, spacing: 0) {
            sectionHeader("Ultimi movimenti", link: "Vedi tutti") { goToTab(1) } trailing: {
                Button {
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        showRecentMovements.toggle()
                    }
                } label: {
                    Image(systemName: showRecentMovements ? "chevron.up" : "chevron.down")
                        .scaledFont(size: 12).foregroundStyle(DS.smoke)
                        .frame(width: 44, height: 44)
                }
                .buttonStyle(.plain)
                .accessibilityLabel("Ultimi movimenti")
            }

            if showRecentMovements {
                if recentNormal.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "Nessun movimento",
                        subtitle: "Premi + per aggiungere la tua prima spesa."
                    )
                    .transition(.opacity)
                } else {
                    // Keep native row swipe actions. Size the non-scrolling list to its content,
                    // which varies with wrapped metadata and Dynamic Type.
                    List {
                        ForEach(recentNormal) { t in
                            movementRow(t)
                                .padding(.horizontal, DS.Space.l)
                                .listRowInsets(EdgeInsets())
                                .listRowBackground(DS.surface)
                                .listRowSeparatorTint(DS.divider)
                                .listRowSeparator(t.persistentModelID == recentNormal.last?.persistentModelID ? .hidden : .visible, edges: .bottom)
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
                    .onScrollGeometryChange(for: CGFloat.self) { geometry in
                        ceil(geometry.contentSize.height)
                    } action: { _, height in
                        if height > 0 { recentListHeight = height }
                    }
                    .frame(height: recentListHeight ?? CGFloat(recentNormal.count) * estimatedRowHeight)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: 20))
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .padding(.horizontal, 16)
                    .transition(.opacity)
                }
            }
        }
    }

    private func movementRow(_ t: Transaction) -> some View {
        let category = NSLocalizedString(t.category, comment: "")
        let accountName = t.account?.name ?? ""
        let metadata = [category, accountName, t.date.dayMonthFormatted]
            .filter { !$0.isEmpty }.joined(separator: " · ")
        return MovementRow(
            name: t.name,
            metadata: metadata,
            amount: money(t.amount),
            categoryName: t.category,
            categorySymbol: t.categoryIcon.isEmpty ? "circle.dotted" : t.categoryIcon,
            kind: t.transactionType == .entrata ? .income : .expense,
            isPlanned: !t.isDone
        )
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
                                .scaledFont(size: 20)
                                .foregroundStyle(shown.contains(acc.id.uuidString) ? DS.ink : DS.smoke)
                        }
                        .buttonStyle(.plain)

                        VStack(alignment: .leading, spacing: 2) {
                            Text(acc.name)
                                .scaledFont(size: 15, weight: .medium)
                                .foregroundStyle(DS.ink)
                            Text(acc.accountType.localizedName)
                                .scaledFont(size: 12)
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
                        .scaledFont(size: 15, weight: .medium)
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
