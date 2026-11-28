import SwiftUI
import SwiftData

enum TxFilter: String, CaseIterable {
    case tutti      = "Tutti"
    case fisse      = "Fisse"
    case ricorrenti = "Ricorrenti"
    case trasf      = "Trasf."
    case uscite     = "Uscite"
    case entrate    = "Entrate"
}

struct TransactionsView: View {
    @Query private var rules: [RecurringRule]
    @State private var recurrenceSelection: RecurrenceSelection?

    @State private var occurrenceCache = RecurrencePresentationCache()
    @AppStorage("hideBalance") private var hideBalance: Bool = false

    private var isFutureMonth: Bool {
        let calendar = Calendar(identifier: .gregorian)
        guard let month = calendar.dateInterval(of: .month, for: selectedMonth),
              let current = calendar.dateInterval(of: .month, for: Date()) else { return false }
        return month.start > current.start
    }

    private var virtualOccurrences: [Occurrence] {
        let calendar = Calendar(identifier: .gregorian)
        guard isFutureMonth,
              let month = calendar.dateInterval(of: .month, for: selectedMonth) else { return [] }
        let realIDs = Set(all.map(\.id))
        let query = hubSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        // Stessi filtri avanzati delle righe reali: importo minimo/massimo e periodo personalizzato.
        let minAmt = Decimal.parseAmount(filterMinAmount)
        let maxAmt = Decimal.parseAmount(filterMaxAmount)
        let from = Calendar.current.startOfDay(for: filterFromDate)
        let to = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: filterToDate)) ?? filterToDate
        return occurrenceCache.occurrences(rules: rules, in: month)
            .filter { occ in
                !realIDs.contains(occ.id) && (selectedCat.isEmpty || occ.category == selectedCat)
                    && (query.isEmpty || occ.name.localizedCaseInsensitiveContains(query))
                    && (selectedType == .tutti
                        || selectedType == .ricorrenti
                        || selectedType == .fisse && occ.isFixed
                        || selectedType == .uscite && occ.type == TransactionType.uscita.rawValue
                        || selectedType == .entrate && occ.type == TransactionType.entrata.rawValue)
                    && (minAmt.map { occ.amount >= $0 } ?? true)
                    && (maxAmt.map { occ.amount <= $0 } ?? true)
                    && (!filterUseCustomDates || (occ.date >= from && occ.date < to))
            }
            .sorted { $0.date < $1.date }
    }

    @Query(sort: [SortDescriptor(\Transaction.date, order: .reverse), SortDescriptor(\Transaction.createdAt, order: .reverse)]) private var all: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var context
    @Environment(\.dynamicTypeSize) private var dynamicTypeSize
    @ScaledMetric(relativeTo: .footnote) private var secondaryChipHeight = 32
    @ScaledMetric(relativeTo: .footnote) private var typeChipHeight = 34

    var isSearchActive: Binding<Bool>? = nil

    @State private var selectedType:   TxFilter = .tutti
    @State private var selectedMonth            = Date()
    @State private var selectedCat              = ""
    @State private var hubSearchQuery           = ""
    @State private var editing: Transaction?    = nil
    @State private var showSettings             = false
    @State private var showAdvancedFilter       = false
    @FocusState private var searchFocused: Bool
    // Pending transfer delete — shows confirmationDialog before removing both legs.
    @State private var transferToDelete: Transaction? = nil
    // Tap su un trasferimento: apre AddTransferView in modalità modifica, che
    // aggiorna entrambe le gambe collegate in modo sincronizzato.
    @State private var transferEditing: Transaction? = nil

    // Filtri avanzati — le stringhe importo e il flag date sono persistiti via AppStorage
    @AppStorage("txFilterMin")      private var filterMinAmount:      String = ""
    @AppStorage("txFilterMax")      private var filterMaxAmount:      String = ""
    @AppStorage("txFilterUseDates") private var filterUseCustomDates: Bool   = false
    // Date del periodo personalizzato: persistite come timestamp (0 = non ancora scelte → ultimo mese).
    @AppStorage("txFilterFrom") private var filterFromStamp: Double = 0
    @AppStorage("txFilterTo")   private var filterToStamp:   Double = 0

    private var filterFromDate: Date {
        filterFromStamp > 0 ? Date(timeIntervalSince1970: filterFromStamp)
            : Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    }
    private var filterToDate: Date {
        filterToStamp > 0 ? Date(timeIntervalSince1970: filterToStamp) : Date()
    }
    private var filterFromBinding: Binding<Date> {
        Binding(get: { filterFromDate }, set: { filterFromStamp = $0.timeIntervalSince1970 })
    }
    private var filterToBinding: Binding<Date> {
        Binding(get: { filterToDate }, set: { filterToStamp = $0.timeIntervalSince1970 })
    }

    private var activeAdvancedFilterCount: Int {
        var n = 0
        if !filterMinAmount.isEmpty  { n += 1 }
        if !filterMaxAmount.isEmpty  { n += 1 }
        if filterUseCustomDates      { n += 1 }
        return n
    }

    // MARK: - Filtering

    private func filtered(for f: TxFilter) -> [Transaction] {
        let minAmt = Decimal.parseAmount(filterMinAmount)
        let maxAmt = Decimal.parseAmount(filterMaxAmount)
        let query  = hubSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines)
        if f == .ricorrenti {
            let ruleIDs = Set(rules.map { $0.id.uuidString })
            return RecurringSectionFilter.filterTransactions(
                all,
                ruleIDs: ruleIDs,
                selectedMonth: selectedMonth,
                query: query,
                selectedCategory: selectedCat,
                minAmount: minAmt,
                maxAmount: maxAmt,
                useCustomDates: filterUseCustomDates,
                fromDate: filterFromDate,
                toDate: filterToDate
            ).sortedForDisplay()
        }
        return all.filter { t in
            if filterUseCustomDates {
                let from = Calendar.current.startOfDay(for: filterFromDate)
                let to   = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: filterToDate)) ?? filterToDate
                guard t.date >= from && t.date < to else { return false }
            } else if query.isEmpty {
                guard t.date.isSameMonth(as: selectedMonth) else { return false }
            }
            guard query.isEmpty || t.name.localizedCaseInsensitiveContains(query) else { return false }
            switch f {
            case .tutti:      break
            case .fisse:      if !t.isFixed    { return false }
            case .ricorrenti: break
            case .trasf:      if !t.isTransfer { return false }
            // Una gamba di trasferimento ha comunque type .uscita/.entrata (serve a far
            // quadrare i due conti), ma non è una spesa/entrata reale — va in Trasf., non qui.
            case .uscite:     if t.transactionType != .uscita  || t.isTransfer { return false }
            case .entrate:    if t.transactionType != .entrata || t.isTransfer { return false }
            }
            if !selectedCat.isEmpty && t.category != selectedCat { return false }
            if let min = minAmt, t.amount < min { return false }
            if let max = maxAmt, t.amount > max { return false }
            return true
        }.sortedForDisplay()
    }

    private var recentMonths: [Date] {
        let cal = Calendar.current
        let now = Date()
        return (-6...6).compactMap { offset in
            cal.date(byAdding: .month, value: offset, to: now)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                HStack(spacing: DS.Space.m) {
                    Text("Movimenti")
                        .font(DS.Typo.screenTitle)
                        .tracking(DS.Typo.screenTitleTracking)
                        .foregroundStyle(DS.ink)
                        .lineLimit(1)
                        .minimumScaleFactor(0.65)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: DS.Space.s)
                    Button { showAdvancedFilter = true } label: {
                        Image(systemName: "line.3.horizontal.decrease")
                            .scaledFont(size: 16)
                            .foregroundStyle(DS.ink)
                            .frame(width: 44, height: 44)
                    }
                    .frame(width: 44, height: 44)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                    .overlay(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius).strokeBorder(DS.fog))
                    // Il badge sta DOPO il bordo: così il contorno del pulsante non lo taglia.
                    .overlay(alignment: .topTrailing) {
                        if activeAdvancedFilterCount > 0 {
                            Text("\(activeAdvancedFilterCount)")
                                .font(DS.Typo.tabLabelActive)
                                .foregroundStyle(DS.onAccent)
                                .dynamicTypeSize(...DynamicTypeSize.xxxLarge)
                                .padding(.horizontal, 5)
                                .frame(minWidth: 18, minHeight: 18)
                                .fixedSize()
                                .background(DS.accent, in: Capsule())
                                .offset(x: 6, y: -6)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
                    .accessibilityLabel(Text("Filtri"))
                    .accessibilityValue(Text("\(activeAdvancedFilterCount)"))
                    .accessibilityIdentifier("btn_advancedFilter")
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .scaledFont(size: 16)
                            .foregroundStyle(DS.ink)
                    }
                    .accessibilityLabel(Text("Impostazioni"))
                    .accessibilityIdentifier("btn_openSettings")
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.vertical, DS.Space.s)
                searchField($hubSearchQuery, identifier: "tf_searchTransactions")
                    .padding(.horizontal, 16)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xs)
                    .focused($searchFocused)

                typeChips
                secondaryChips

                let currentList = filtered(for: selectedType)
                let virtual = virtualOccurrences
                if currentList.isEmpty && virtual.isEmpty {
                    let queryEmpty = hubSearchQuery.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
                    EmptyStateView(
                        icon: queryEmpty ? "tray" : "magnifyingglass",
                        title: queryEmpty ? "Nessun movimento" : "Nessun risultato",
                        subtitle: !queryEmpty
                            ? "Nessun movimento corrisponde alla ricerca."
                            : selectedType == .ricorrenti
                                ? "Nessuna serie programmata in questo mese."
                                : "I movimenti di questo periodo appariranno qui."
                    )
                    Spacer()
                } else {
                    movementList(currentList, virtual: virtual)
                }
            }
            .background(DS.paper)
            .navigationTitle("Movimenti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: hubSearchQuery) { _, v in
                isSearchActive?.wrappedValue = !v.isEmpty || searchFocused
            }
            .onChange(of: searchFocused)  { _, f in isSearchActive?.wrappedValue = f || !hubSearchQuery.isEmpty }
            .sheet(item: $editing) { AddTransactionView(editing: $0) }
            .sheet(item: $recurrenceSelection) { RecurrenceEditorView(selection: $0) }
            .sheet(item: $transferEditing) { AddTransferView(editing: $0) }
            .sheet(isPresented: $showAdvancedFilter) { advancedFilterSheet }
            .tint(DS.ink)
            .themedNavBar()
            .sheet(isPresented: $showSettings) { SettingsView() }
            .transferDeleteConfirmation(pending: $transferToDelete, onConfirm: deleteTransactionOrPair)
        }
    }

    // MARK: - Search bar

    private func searchField(_ text: Binding<String>, identifier: String) -> some View {
        TransactionsSearchField(text: text, identifier: identifier)
    }

    // MARK: - Presentation

    private var typeChips: some View {
        TransactionsTypeChips(typeChipHeight: typeChipHeight, selectedType: $selectedType)
    }

    private var secondaryChips: some View {
        TransactionsSecondaryChips(
            selectedMonth: $selectedMonth, selectedCat: $selectedCat,
            showAdvancedFilter: $showAdvancedFilter,
            filterMinAmount: $filterMinAmount, filterMaxAmount: $filterMaxAmount,
            filterUseCustomDates: $filterUseCustomDates, categories: categories,
            recentMonths: recentMonths, secondaryChipHeight: secondaryChipHeight,
            activeAdvancedFilterCount: activeAdvancedFilterCount,
            activeFilterSummaryLabel: activeFilterSummaryLabel
        )
    }

    private var activeFilterSummaryLabel: String {
        let hasMin = !filterMinAmount.isEmpty
        let hasMax = !filterMaxAmount.isEmpty
        if hasMin && !hasMax && !filterUseCustomDates {
            return "≥ \(filterMinAmount) \(Double.currencySymbol)"
        } else if !hasMin && hasMax && !filterUseCustomDates {
            return "≤ \(filterMaxAmount) \(Double.currencySymbol)"
        } else if hasMin && hasMax && !filterUseCustomDates {
            return "\(filterMinAmount)–\(filterMaxAmount) \(Double.currencySymbol)"
        } else {
            return String(format: String(localized: "Filtri (%lld)"), activeAdvancedFilterCount)
        }
    }

    private func dayTitle(_ day: Date) -> String {
        if Calendar.current.isDateInToday(day) { return NSLocalizedString("Oggi", comment: "") }
        if Calendar.current.isDateInYesterday(day) { return NSLocalizedString("Ieri", comment: "") }
        return day.dayMonthFormatted
    }

    private func groupHeader(_ title: String, items: [MovementListItem], planned: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(DS.Typo.secondary)
                .fontWeight(.semibold)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            Spacer(minLength: DS.Space.s)
            Text(items.reduce(Decimal.zero) { $0 + $1.signedAmount }.currencyFormatted)
                .font(DS.Typo.rowAmount)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(planned ? DS.plannedText : DS.smoke)
        .textCase(nil)
        .padding(.top, DS.Space.s)
        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 6, trailing: 4))
    }

    private func movementList(_ snapshot: [Transaction], virtual: [Occurrence]) -> some View {
        let layout = MovementListLayout.make(real: snapshot, virtual: virtual, isFutureMonth: isFutureMonth)
        let totals = MovementSectionTotals.compute(real: snapshot, virtual: virtual)
        let ruleIDs = Set(rules.map { $0.id.uuidString })
        return List {
            if !layout.planned.isEmpty {
                Section {
                    ForEach(layout.planned) { item in
                        listItemRow(item, ruleIDs: ruleIDs, isFirst: item.id == layout.planned.first?.id, isLast: item.id == layout.planned.last?.id)
                    }
                } header: {
                    groupHeader(NSLocalizedString("In arrivo · pianificati", comment: ""), items: layout.planned, planned: true)
                }
                .listSectionSeparator(.hidden)
            }
            ForEach(layout.days, id: \.day) { group in
                Section {
                    ForEach(group.items) { item in
                        listItemRow(item, ruleIDs: ruleIDs, isFirst: item.id == group.items.first?.id, isLast: item.id == group.items.last?.id)
                    }
                } header: {
                    groupHeader(dayTitle(group.day), items: group.items)
                }
                .listSectionSeparator(.hidden)
            }
            if !snapshot.isEmpty || !virtual.isEmpty {
                Section {
                    MovementTotalsBlock(filter: selectedType, totals: totals, hidden: hideBalance)
                        .listRowInsets(EdgeInsets(top: DS.Space.s, leading: 0, bottom: 0, trailing: 0))
                        .listRowBackground(Color.clear)
                        .listRowSeparator(.hidden)
                }
                .listSectionSeparator(.hidden)
            }
            Section {
                Color.clear.frame(height: 100)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.grouped)
        .listSectionSpacing(DS.Space.m)
        .contentMargins(.horizontal, 16, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .refreshable { await SyncService.shared.manualRefresh(context: context) }
    }

    @ViewBuilder
    private func listItemRow(_ item: MovementListItem, ruleIDs: Set<String>, isFirst: Bool, isLast: Bool) -> some View {
        switch item {
        case .real(let t):
            swipeableRow(t, ruleIDs: ruleIDs, isFirst: isFirst, isLast: isLast)
        case .virtual(let occ):
            virtualCell(occ)
                .alignmentGuide(.listRowSeparatorLeading) { _ in 14 }
                .listRowInsets(EdgeInsets())
                .listRowBackground(
                    UnevenRoundedRectangle(
                        topLeadingRadius: isFirst ? 18 : 0,
                        bottomLeadingRadius: isLast ? 18 : 0,
                        bottomTrailingRadius: isLast ? 18 : 0,
                        topTrailingRadius: isFirst ? 18 : 0
                    ).fill(DS.surface)
                )
                .listRowSeparatorTint(DS.divider)
        }
    }

    @ViewBuilder
    private func virtualCell(_ occ: Occurrence) -> some View {
        let row = MovementRow(
            name: occ.name,
            metadata: [NSLocalizedString(occ.isFixed ? "Fissa" : occ.category, comment: ""), occ.date.dayMonthFormatted]
                .filter { !$0.isEmpty }.joined(separator: " · "),
            amount: occ.amount.currencyFormatted,
            categoryName: occ.category,
            categorySymbol: occ.categoryIcon.isEmpty ? DS.categoryIcon(for: occ.category) : occ.categoryIcon,
            kind: TransactionType(rawValue: occ.type) == .entrata ? .income : .expense,
            isPlanned: true,
            compact: true,
            isRecurring: true
        )
        .padding(.horizontal, 14)
        .contentShape(Rectangle())

        if selectedType == .ricorrenti {
            Button {
                if let rule = rules.first(where: { $0.id == occ.ruleId }) {
                    recurrenceSelection = RecurrenceSelection(rule: rule, occurrence: occ)
                }
            } label: {
                row
            }
            .buttonStyle(.plain)
            .accessibilityIdentifier("editRecurrence_\(occ.name)")
            .accessibilityValue(Text("Pianificato"))
        } else {
            row
                .accessibilityIdentifier("virtualRow_\(occ.id.uuidString)")
                .accessibilityValue(Text("Pianificato"))
                .onTapGesture {
                    if let rule = rules.first(where: { $0.id == occ.ruleId }) {
                        recurrenceSelection = RecurrenceSelection(rule: rule, occurrence: occ)
                    }
                }
        }
    }

    // MARK: - Advanced filter sheet

    private var advancedFilterSheet: some View {
        TransactionsAdvancedFilterSheet(
            filterMinAmount: $filterMinAmount, filterMaxAmount: $filterMaxAmount,
            filterUseCustomDates: $filterUseCustomDates,
            filterFromDate: filterFromBinding, filterToDate: filterToBinding,
            showAdvancedFilter: $showAdvancedFilter,
            activeAdvancedFilterCount: activeAdvancedFilterCount
        )
    }

    // MARK: - Transaction cell

    @ViewBuilder
    private func transactionCell(_ t: Transaction, ruleIDs: Set<String>) -> some View {
        let row = MovementRow(
            name: t.name,
            metadata: (t.isDone
                ? [NSLocalizedString(t.category, comment: ""), t.account?.name ?? ""]
                : [NSLocalizedString(t.isFixed ? "Fissa" : t.category, comment: ""), t.date.dayMonthFormatted])
                .filter { !$0.isEmpty }.joined(separator: " · "),
            amount: t.amount.currencyFormatted,
            categoryName: t.category,
            categorySymbol: t.categoryIcon.isEmpty ? DS.categoryIcon(for: t.category) : t.categoryIcon,
            kind: t.isTransfer ? .transfer : t.transactionType == .entrata ? .income : .expense,
            isPlanned: !t.isDone,
            compact: true,
            isRecurring: ruleIDs.contains(t.templateId)
        )
        .padding(.horizontal, 14)
        .contentShape(Rectangle())

        Group {
            if selectedType == .ricorrenti {
                Button {
                    if let selection = RecurrenceSelection.resolve(t, rules: rules) {
                        recurrenceSelection = selection
                    }
                } label: {
                    row
                }
                .buttonStyle(.plain)
                .accessibilityIdentifier("editRecurrence_\(t.name)")
                .accessibilityValue(Text(t.isDone ? "Fatto" : "Pianificato"))
            } else {
                row
                    .accessibilityIdentifier("txRow_\(t.id.uuidString)")
                    .accessibilityValue(Text(t.isDone ? "Fatto" : "Pianificato"))
                    .onTapGesture {
                        // I trasferimenti sono 2 transazioni collegate (transferGroupId): l'editor
                        // generico modificherebbe solo una delle due gambe, disallineando i saldi
                        // dei due conti coinvolti — per questo usano AddTransferView (che aggiorna
                        // entrambe le gambe) invece dell'editor generico.
                        if t.isTransfer {
                            transferEditing = t
                        } else {
                            editing = t
                        }
                    }
            }
        }
        // long press → elimina, + interrompi ricorrenza da qualunque occorrenza della serie
        .contextMenu {
            RecurrenceContextMenu(transaction: t, rules: rules, onSelect: { recurrenceSelection = $0 }) {
                haptic(.medium)
                if t.isTransfer && !t.transferGroupId.isEmpty {
                    transferToDelete = t
                } else {
                    deleteTransactionOrPair(t)
                }
            }
        }
    }

    // MARK: - Riga con swipe actions (riusata da tutte le sezioni)

    @ViewBuilder
    private func swipeableRow(_ t: Transaction, ruleIDs: Set<String>, isFirst: Bool, isLast: Bool) -> some View {
        transactionCell(t, ruleIDs: ruleIDs)
            .alignmentGuide(.listRowSeparatorLeading) { _ in 14 }
            .listRowInsets(EdgeInsets())
            .listRowBackground(
                UnevenRoundedRectangle(
                    topLeadingRadius: isFirst ? 18 : 0,
                    bottomLeadingRadius: isLast ? 18 : 0,
                    bottomTrailingRadius: isLast ? 18 : 0,
                    topTrailingRadius: isFirst ? 18 : 0
                ).fill(DS.surface)
            )
            .listRowSeparatorTint(DS.divider)
            .swipeActions(edge: .leading, allowsFullSwipe: true) {
                if t.isFixed || !t.isDone || AddTransactionView.isFutureDate(t.date) {
                    Button {
                        haptic(.soft)
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                            toggleTransferOrFixed(t)
                        }
                    } label: {
                        Label(
                            t.isDone ? "Pianificato" : "Conferma",
                            systemImage: t.isDone ? "clock" : "checkmark.circle.fill"
                        )
                    }
                    .tint(t.isDone ? DS.smoke : DS.accent)
                }
            }
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                // A destructive swipe removes the row optimistically, even if the user cancels the editor.
                Button(role: t.templateId.isEmpty ? .destructive : nil) {
                    haptic(.medium)
                    if t.isTransfer && !t.transferGroupId.isEmpty {
                        transferToDelete = t
                    } else {
                        deleteTransactionOrPair(t)
                    }
                } label: {
                    Label("Elimina", systemImage: "trash")
                }
                // Senza tint esplicito eredita l'ambient .tint(DS.ink) impostato più
                // sotto sul NavigationStack (fix del tint verde di sistema iOS 26) —
                // DS.ink è quasi bianco in tema scuro, quindi lo sfondo dello swipe
                // "Elimina" diventava bianco con l'icona scura invece che rosso.
                .tint(.red)
                .accessibilityIdentifier("btn_deleteTransaction")
            }
    }

    // MARK: - Helpers

    private func toggleTransferOrFixed(_ t: Transaction) {
        let newValue = !t.isDone
        t.isDone = newValue
        if t.isTransfer, !t.transferGroupId.isEmpty {
            if let pair = all.first(where: { $0.isTransfer && $0.id != t.id && $0.transferGroupId == t.transferGroupId }) {
                pair.isDone = newValue
            }
        }
        context.safeSave()
    }

    private func deleteTransactionOrPair(_ t: Transaction) {
        if let selection = RecurrenceSelection.resolve(t, rules: rules) {
            recurrenceSelection = selection
            return
        }
        if t.isTransfer, !t.transferGroupId.isEmpty {
            if let pair = all.first(where: { $0.isTransfer && $0.id != t.id && $0.transferGroupId == t.transferGroupId }) {
                context.delete(pair)
            }
        }
        context.delete(t)
        context.safeSave()
    }
}

// MARK: - Transfer delete confirmation (condivisa tra hub e sezione)

private extension View {
    /// Chiede conferma prima di eliminare entrambe le gambe di un trasferimento.
    /// Va applicata su ogni vista che può diventare quella in primo piano nello
    /// stack di navigazione da cui può partire l'eliminazione (hub e sezione
    /// "Trasf."), altrimenti il dialog resta "in sospeso" finché quella vista
    /// non torna in primo piano — vedi commenti in `TransactionsView.body`.
    func transferDeleteConfirmation(pending: Binding<Transaction?>, onConfirm: @escaping (Transaction) -> Void) -> some View {
        confirmationDialog(
            "Elimina trasferimento",
            isPresented: Binding(
                get: { pending.wrappedValue != nil },
                set: { if !$0 { pending.wrappedValue = nil } }
            ),
            titleVisibility: .visible
        ) {
            Button("Elimina entrambi i movimenti", role: .destructive) {
                if let t = pending.wrappedValue { onConfirm(t) }
                pending.wrappedValue = nil
            }
            Button("Annulla", role: .cancel) { pending.wrappedValue = nil }
        } message: {
            Text("Questo trasferimento è composto da due movimenti collegati. Verranno eliminati entrambi.")
        }
    }
}
