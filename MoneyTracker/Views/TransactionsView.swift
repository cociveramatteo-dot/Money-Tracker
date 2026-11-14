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
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
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
    @State private var sectionSearch            = ""
    @State private var recurringCategory        = ""
    @State private var editing: Transaction?    = nil
    @State private var showSettings             = false
    @State private var showAdvancedFilter       = false
    @State private var selectedSeries: RecurringSeries? = nil
    @State private var navPath: [TxFilter]      = []
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
    @State private var filterFromDate = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var filterToDate   = Date()

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
            case .ricorrenti: return false   // non passa da qui, vedi recurringSeries(matchingCategory:)
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
        }
    }

    private var recentMonths: [Date] {
        let cal = Calendar.current
        let now = Date()
        return (-6...6).compactMap { offset in
            cal.date(byAdding: .month, value: offset, to: now)
        }
    }

    // "Ricorrenti" è all-time (ignora il mese) e usa il rilevamento automatico
    // invece del filtro per tipo/mese di `filtered(for:)`.
    private func recurringSeries(matchingCategory: String) -> [RecurringSeries] {
        let detected = RecurringSeriesDetector.detect(from: all)
        let bySearch = sectionSearch.isEmpty
            ? detected
            : detected.filter { $0.name.localizedCaseInsensitiveContains(sectionSearch) }
        return matchingCategory.isEmpty ? bySearch : bySearch.filter { $0.category == matchingCategory }
    }

    private func grouped(from snapshot: [Transaction]) -> [(key: String, value: [Transaction])] {
        var dict: [String: [Transaction]] = [:]
        var order: [String] = []
        for t in snapshot {
            let k = t.date.dayMonthFormatted
            if dict[k] == nil { order.append(k) }
            dict[k, default: []].append(t)
        }
        return order.compactMap { key in dict[key].map { (key: key, value: $0) } }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack(path: $navPath) {
            VStack(spacing: 0) {
                HStack(spacing: DS.Space.m) {
                    Text("Movimenti")
                        .font(DS.Typo.screenTitle)
                        .tracking(DS.Typo.screenTitleTracking)
                        .foregroundStyle(DS.ink)
                        .accessibilityAddTraits(.isHeader)
                    Spacer(minLength: DS.Space.s)
                    Button { showAdvancedFilter = true } label: {
                        ZStack(alignment: .topTrailing) {
                            Image(systemName: "line.3.horizontal.decrease")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.ink)
                                .frame(width: 44, height: 44)
                            if activeAdvancedFilterCount > 0 {
                                Text("\(activeAdvancedFilterCount)")
                                    .font(DS.Typo.tabLabelActive)
                                    .foregroundStyle(DS.onAccent)
                                    .frame(minWidth: 18, minHeight: 18)
                                    .background(DS.accent)
                                    .clipShape(Circle())
                                    .offset(x: 6, y: -6)
                            }
                        }
                    }
                    .frame(width: 44, height: 44)
                    .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                    .overlay(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius).strokeBorder(DS.fog))
                    .accessibilityLabel(Text("Filtri"))
                    .accessibilityValue(Text("\(activeAdvancedFilterCount)"))
                    .accessibilityIdentifier("btn_advancedFilter")
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
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

                typeChips(selected: selectedType)
                secondaryChips

                let currentList = filtered(for: selectedType)
                if currentList.isEmpty {
                    EmptyStateView(
                        icon: hubSearchQuery.isEmpty ? "tray" : "magnifyingglass",
                        title: hubSearchQuery.isEmpty ? "Nessun movimento" : "Nessun risultato",
                        subtitle: hubSearchQuery.isEmpty ? "I movimenti di questo periodo appariranno qui." : "Nessun movimento corrisponde alla ricerca."
                    )
                    Spacer()
                } else {
                    movementList(currentList)
                }
            }
            .background(DS.paper)
            .navigationTitle("Movimenti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            .onChange(of: hubSearchQuery) { _, v in
                isSearchActive?.wrappedValue = navPath.isEmpty && (!v.isEmpty || searchFocused)
            }
            .onChange(of: searchFocused)  { _, f in isSearchActive?.wrappedValue = navPath.isEmpty && (f || !hubSearchQuery.isEmpty) }
            .onChange(of: navPath) { _, path in
                if !path.isEmpty { searchFocused = false }
                isSearchActive?.wrappedValue = path.isEmpty && (!hubSearchQuery.isEmpty || searchFocused)
            }
            .navigationDestination(for: TxFilter.self) { f in subListContent(for: f) }
            .sheet(item: $editing) { AddTransactionView(editing: $0) }
            .sheet(item: $transferEditing) { AddTransferView(editing: $0) }
            .sheet(isPresented: $showAdvancedFilter) { advancedFilterSheet }
            .tint(DS.ink)
            .themedNavBar()
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $selectedSeries) { s in RecurringSeriesDetailView(seriesID: s.id) }
            .transferDeleteConfirmation(pending: $transferToDelete, onConfirm: deleteTransactionOrPair)
        }
    }

    // MARK: - Search bar

    private func searchField(_ text: Binding<String>, identifier: String) -> some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
            TextField("", text: text, prompt: Text("Cerca per nome").foregroundStyle(DS.smoke))
                .accessibilityLabel(Text("Cerca per nome"))
                .font(DS.Typo.rowName)
                .foregroundStyle(DS.ink)
                .submitLabel(.done)
                .accessibilityIdentifier(identifier)
            if !text.wrappedValue.isEmpty {
                Button {
                    text.wrappedValue = ""
                } label: {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.smoke)
                }
            }
        }
        .padding(.horizontal, DS.Layout.margin)
        .frame(minHeight: 46)
        .background(DS.surface, in: RoundedRectangle(cornerRadius: DS.Layout.cardRadius))
        .overlay(RoundedRectangle(cornerRadius: DS.Layout.cardRadius).strokeBorder(DS.fog))
    }

    // MARK: - Presentation

    private func typeChips(selected: TxFilter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                ForEach([TxFilter.tutti, .fisse, .trasf, .uscite, .entrate, .ricorrenti], id: \.self) { f in
                    Button {
                        if f == .ricorrenti {
                            navPath.append(.ricorrenti)
                        } else {
                            withAnimation(.easeInOut(duration: 0.15)) {
                                selectedType = f
                            }
                        }
                    } label: {
                        Text(LocalizedStringKey(f.rawValue))
                            .font(DS.Typo.secondary.weight(selected == f ? .semibold : .medium))
                            .foregroundStyle(selected == f ? DS.surface : DS.ink)
                            .padding(.horizontal, 14)
                            .frame(minHeight: typeChipHeight)
                            .background(selected == f ? DS.ink : DS.surface, in: RoundedRectangle(cornerRadius: 12))
                            .overlay(RoundedRectangle(cornerRadius: 12).strokeBorder(selected == f ? Color.clear : DS.fog))
                    }
                    .buttonStyle(.plain)
                    .accessibilityAddTraits(selected == f ? [.isSelected] : [])
                    .accessibilityIdentifier("txFilterBlock_\(f.rawValue)")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, DS.Space.s)
        }
        .accessibilityIdentifier("tx_typeChips")
    }

    private var secondaryChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 6) {
                // 1. Mese ▾ (compatto con bordo tratteggiato, da mockup)
                Menu {
                    Button {
                        selectedMonth = Date()
                    } label: {
                        Label(String(localized: "Questo mese"), systemImage: "calendar")
                    }
                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: -1, to: selectedMonth) ?? selectedMonth
                    } label: {
                        Label(String(localized: "Mese precedente"), systemImage: "chevron.left")
                    }
                    Button {
                        selectedMonth = Calendar.current.date(byAdding: .month, value: 1, to: selectedMonth) ?? selectedMonth
                    } label: {
                        Label(String(localized: "Mese successivo"), systemImage: "chevron.right")
                    }
                    Divider()
                    ForEach(recentMonths, id: \.self) { m in
                        Button {
                            selectedMonth = m
                        } label: {
                            HStack {
                                Text(m.monthYearFormatted)
                                if m.isSameMonth(as: selectedMonth) {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Text("\(selectedMonth.monthYearFormatted) ▾")
                            .font(DS.Typo.secondary)
                            .foregroundStyle(DS.ink)
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: secondaryChipHeight)
                    .background(Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(DS.filterBorder, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
                }
                .accessibilityIdentifier("btn_monthPicker")

                // 2. Categoria ▾ (menu pulito con icone e stato attivo)
                Menu {
                    Button {
                        selectedCat = ""
                    } label: {
                        HStack {
                            Text(String(localized: "Tutte le categorie"))
                            if selectedCat.isEmpty {
                                Image(systemName: "checkmark")
                            }
                        }
                    }
                    Divider()
                    ForEach(categories) { cat in
                        Button {
                            selectedCat = (selectedCat == cat.name ? "" : cat.name)
                        } label: {
                            HStack {
                                DS.categoryText(cat.name)
                                if selectedCat == cat.name {
                                    Image(systemName: "checkmark")
                                }
                            }
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        if selectedCat.isEmpty {
                            Text(String(localized: "Categoria"))
                        } else {
                            DS.categoryText(selectedCat)
                        }
                        Text("▾")
                    }
                    .font(DS.Typo.secondary)
                    .fontWeight(selectedCat.isEmpty ? .regular : .semibold)
                    .foregroundStyle(selectedCat.isEmpty ? DS.ink : DS.accent)
                    .padding(.horizontal, 12)
                    .frame(minHeight: secondaryChipHeight)
                    .background(selectedCat.isEmpty ? Color.clear : DS.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .strokeBorder(selectedCat.isEmpty ? DS.filterBorder : Color.clear, style: StrokeStyle(lineWidth: 1, dash: [3, 3]))
                    )
                }
                .accessibilityIdentifier("btn_categoryFilter")

                // 3. Filtri avanzati attivi (chip verde soft con xmark, presente solo se attivi)
                if activeAdvancedFilterCount > 0 {
                    HStack(spacing: 6) {
                        Button {
                            showAdvancedFilter = true
                        } label: {
                            Text(activeFilterSummaryLabel)
                                .font(DS.Typo.secondary.weight(.semibold))
                                .foregroundStyle(DS.accent)
                        }
                        Button {
                            filterMinAmount = ""
                            filterMaxAmount = ""
                            filterUseCustomDates = false
                        } label: {
                            Image(systemName: "xmark")
                                .font(.system(size: 10, weight: .bold))
                                .foregroundStyle(DS.accent)
                        }
                        .buttonStyle(.plain)
                        .accessibilityLabel(Text("Rimuovi filtri"))
                    }
                    .padding(.horizontal, 12)
                    .frame(minHeight: secondaryChipHeight)
                    .background(DS.accentSoft)
                    .clipShape(RoundedRectangle(cornerRadius: 10))
                    .accessibilityIdentifier("btn_activeFilterBadge")
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, DS.Space.xs)
        }
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

    private func dayTitle(_ transactions: [Transaction], fallback: String) -> String {
        guard let date = transactions.first?.date else { return fallback }
        if Calendar.current.isDateInToday(date) { return NSLocalizedString("Oggi", comment: "") }
        if Calendar.current.isDateInYesterday(date) { return NSLocalizedString("Ieri", comment: "") }
        return fallback
    }

    private func groupHeader(_ title: String, transactions: [Transaction], planned: Bool = false) -> some View {
        HStack {
            Text(title)
                .font(DS.Typo.secondary)
                .fontWeight(.semibold)
                .lineLimit(dynamicTypeSize.isAccessibilitySize ? nil : 1)
            Spacer(minLength: DS.Space.s)
            // Display-only subtotal; transfers do not represent income or expense.
            Text(transactions.filter { !$0.isTransfer }.reduce(Decimal.zero) { $0 + $1.signedAmount }.currencyFormatted)
                .font(DS.Typo.rowAmount)
                .lineLimit(1)
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(planned ? DS.plannedText : DS.smoke)
        .textCase(nil)
        .padding(.top, DS.Space.s)
        .listRowInsets(EdgeInsets(top: 0, leading: 4, bottom: 6, trailing: 4))
    }

    private func movementList(_ snapshot: [Transaction]) -> some View {
        let planned = snapshot.filter { !$0.isDone }
        let completed = snapshot.filter { $0.isDone }
        return List {
            if !planned.isEmpty {
                Section {
                    ForEach(planned) { t in
                        swipeableRow(t, isFirst: t.id == planned.first?.id, isLast: t.id == planned.last?.id)
                    }
                } header: {
                    groupHeader(NSLocalizedString("In arrivo · pianificati", comment: ""), transactions: planned, planned: true)
                }
                .listSectionSeparator(.hidden)
            }
            ForEach(grouped(from: completed), id: \.key) { group in
                Section {
                    ForEach(group.value) { t in
                        swipeableRow(t, isFirst: t.id == group.value.first?.id, isLast: t.id == group.value.last?.id)
                    }
                } header: {
                    groupHeader(dayTitle(group.value, fallback: group.key), transactions: group.value)
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

    // MARK: - Sezione Ricorrenti (l'unica che resta pagina a sé)

    @ViewBuilder
    private func subListContent(for f: TxFilter) -> some View {
        if f == .ricorrenti {
            VStack(spacing: 0) {
                searchField($sectionSearch, identifier: "tf_sectionSearch")
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xs)

                if !categories.isEmpty {
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Space.s) {
                            FilterChip(title: Text(String(localized: "Tutte le categorie")), isActive: recurringCategory.isEmpty, style: .secondary) {
                                recurringCategory = ""
                            }
                            ForEach(categories) { cat in
                                filterChip(cat.name, active: recurringCategory == cat.name) {
                                    recurringCategory = (recurringCategory == cat.name ? "" : cat.name)
                                }
                            }
                        }
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.vertical, DS.Space.s)
                    }
                }

                let series = recurringSeries(matchingCategory: recurringCategory)
                if series.isEmpty {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: "Nessuna serie ricorrente",
                        subtitle: "I pagamenti che si ripetono per almeno 2 mesi appariranno qui."
                    )
                    Spacer()
                } else {
                    ScrollView {
                        LazyVStack(spacing: DS.Space.m) {
                            ForEach(series) { s in
                                RecurringSeriesCard(series: s)
                                    .contentShape(Rectangle())
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
            .navigationTitle(Text(LocalizedStringKey(f.rawValue)))
            .navigationBarTitleDisplayMode(.inline)
            .onDisappear { sectionSearch = ""; recurringCategory = "" }
            .transferDeleteConfirmation(pending: $transferToDelete, onConfirm: deleteTransactionOrPair)
        } else {
            // Fallback difensivo nel caso improbabile di navigazione
            movementList(filtered(for: f))
        }
    }

    // MARK: - Advanced filter sheet

    private var advancedFilterSheet: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Importo")
                        HStack(spacing: DS.Space.l) {
                            VStack(alignment: .leading, spacing: DS.Space.s) {
                                Text("Minimo")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.smoke)
                                HStack(spacing: 4) {
                                    Text(Double.currencySymbol)
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(DS.smoke)
                                    TextField("0", text: $filterMinAmount)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(DS.ink)
                                        .keyboardType(.decimalPad)
                                }
                                ThinDivider()
                            }
                            VStack(alignment: .leading, spacing: DS.Space.s) {
                                Text("Massimo")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.smoke)
                                HStack(spacing: 4) {
                                    Text(Double.currencySymbol)
                                        .font(.system(size: 16, weight: .light))
                                        .foregroundStyle(DS.smoke)
                                    TextField("∞", text: $filterMaxAmount)
                                        .font(.system(size: 20, weight: .medium))
                                        .foregroundStyle(DS.ink)
                                        .keyboardType(.decimalPad)
                                }
                                ThinDivider()
                            }
                        }
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Periodo")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Periodo personalizzato")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Sostituisce il filtro mese")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $filterUseCustomDates)
                                .tint(DS.ink)
                                .labelsHidden()
                        }

                        if filterUseCustomDates {
                            HStack {
                                VStack(alignment: .leading, spacing: DS.Space.xs) {
                                    Text("Da")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.smoke)
                                    DatePicker("", selection: $filterFromDate, displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(DS.ink)
                                }
                                Spacer()
                                VStack(alignment: .leading, spacing: DS.Space.xs) {
                                    Text("A")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.smoke)
                                    DatePicker("", selection: $filterToDate,
                                               in: filterFromDate...,
                                               displayedComponents: .date)
                                        .labelsHidden()
                                        .tint(DS.ink)
                                }
                            }
                            .padding(.top, DS.Space.xs)
                        }
                    }

                    ThinDivider()

                    if activeAdvancedFilterCount > 0 {
                        Button {
                            filterMinAmount = ""
                            filterMaxAmount = ""
                            filterUseCustomDates = false
                        } label: {
                            HStack {
                                Image(systemName: "xmark.circle")
                                    .font(.system(size: 14))
                                Text("Rimuovi tutti i filtri")
                                    .font(.system(size: 15))
                            }
                            .foregroundStyle(DS.smoke)
                        }
                    }
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.xxl)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .navigationTitle("Filtri")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button("Fine") { showAdvancedFilter = false }
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.ink)
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Transaction cell

    @ViewBuilder
    private func transactionCell(_ t: Transaction) -> some View {
        MovementRow(
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
            compact: true
        )
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
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
        // long press → elimina, + interrompi ricorrenza da qualunque occorrenza della serie
        .contextMenu {
            // Disponibile sia sul template originale (recurringFrequency valorizzato)
            // sia su una qualunque copia generata (templateId valorizzato) — così non
            // serve risalire fino alla transazione creata magari un anno fa: basta
            // farlo dalla copia più recente/comoda da trovare. Svuota solo il campo
            // ricorrenza sul template: non tocca questa transazione né le altre copie
            // già generate, impedisce solo quelle dei mesi successivi.
            if !t.recurringFrequency.isEmpty || !t.templateId.isEmpty {
                Button {
                    haptic(.soft)
                    stopRecurrence(for: t)
                } label: {
                    Label("Interrompi ricorrenza", systemImage: "stop.circle")
                }
            }
            Button(role: .destructive) {
                haptic(.medium)
                if t.isTransfer && !t.transferGroupId.isEmpty {
                    transferToDelete = t
                } else {
                    deleteTransactionOrPair(t)
                }
            } label: {
                Label("Elimina", systemImage: "trash")
            }
        }
    }

    // MARK: - Riga con swipe actions (riusata da tutte le sezioni non-Ricorrenti)

    @ViewBuilder
    private func swipeableRow(_ t: Transaction, isFirst: Bool, isLast: Bool) -> some View {
        transactionCell(t)
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
                if t.isFixed || !t.isDone {
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
                Button(role: .destructive) {
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

    private func filterChip(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        FilterChip(title: DS.categoryText(label), isActive: active, style: .secondary, action: action)
    }

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

    /// Ferma la generazione futura della serie a cui appartiene `t`, che sia essa
    /// stessa il template originale o una qualunque copia già generata — evita di
    /// dover risalire alla transazione creata magari mesi/anni fa per interromperla.
    private func stopRecurrence(for t: Transaction) {
        if !t.recurringFrequency.isEmpty {
            t.recurringFrequency = ""
        } else if !t.templateId.isEmpty,
                  let template = all.first(where: { $0.id.uuidString == t.templateId }) {
            template.recurringFrequency = ""
        }
        context.safeSave()
    }

    private func deleteTransactionOrPair(_ t: Transaction) {
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
