import SwiftUI
import SwiftData

enum TxFilter: String, CaseIterable {
    case tutti    = "Tutti"
    case fisse    = "Fisse"
    case trasf    = "Trasf."
    case uscite   = "Uscite"
    case entrate  = "Entrate"
}

struct TransactionsView: View {
    @Query(sort: \Transaction.date, order: .reverse) private var all: [Transaction]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.modelContext) private var context

    var isSearchActive: Binding<Bool>? = nil

    @State private var selectedMonth  = Date()
    @State private var txFilter       = TxFilter.tutti
    @State private var selectedCat    = ""
    @State private var search         = ""
    @State private var editing: Transaction? = nil
    @State private var showSettings        = false
    @State private var showAdvancedFilter  = false
    @FocusState private var searchFocused: Bool
    // BUG-04: pending transfer delete — shows confirmationDialog before removing both legs
    @State private var transferToDelete: Transaction? = nil

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

    private var filtered: [Transaction] {
        let minAmt = Decimal.parseAmount(filterMinAmount)
        let maxAmt = Decimal.parseAmount(filterMaxAmount)
        return all.filter { t in
            if filterUseCustomDates {
                let from = Calendar.current.startOfDay(for: filterFromDate)
                let to   = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: filterToDate)) ?? filterToDate
                guard t.date >= from && t.date < to else { return false }
            } else {
                guard t.date.isSameMonth(as: selectedMonth) else { return false }
            }
            guard search.isEmpty || t.name.localizedCaseInsensitiveContains(search) else { return false }
            switch txFilter {
            case .tutti:   break
            case .fisse:   if !t.isFixed    { return false }
            case .trasf:   if !t.isTransfer { return false }
            case .uscite:  if t.transactionType != .uscita  { return false }
            case .entrate: if t.transactionType != .entrata { return false }
            }
            if !selectedCat.isEmpty && t.category != selectedCat { return false }
            if let min = minAmt, t.amount < min { return false }
            if let max = maxAmt, t.amount > max { return false }
            return true
        }
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

    private func monthIncome(from snapshot: [Transaction]) -> Decimal {
        snapshot.filter { $0.transactionType == .entrata && $0.isDone }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    private func monthExpenses(from snapshot: [Transaction]) -> Decimal {
        snapshot.filter { $0.transactionType == .uscita && $0.isDone }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    // MARK: - Body

    var body: some View {
        let snapshot = filtered
        return NavigationStack {
            VStack(spacing: 0) {

                // Implementata nel VStack anziché con .searchable() per evitare
                // che iOS 26 espanda la navigation bar creando un blocco visibile
                // sopra MonthBar (specialmente in tema Notte con nav bar nera).
                HStack(spacing: DS.Space.s) {
                    Image(systemName: "magnifyingglass")
                        .font(.system(size: 14))
                        .foregroundStyle(DS.smoke)
                    TextField("Cerca...", text: $search)
                        .font(.system(size: 15))
                        .foregroundStyle(DS.ink)
                        .focused($searchFocused)
                        .submitLabel(.done)
                        .onSubmit { searchFocused = false }
                    if !search.isEmpty {
                        Button {
                            search = ""
                            searchFocused = false
                        } label: {
                            Image(systemName: "xmark.circle.fill")
                                .font(.system(size: 14))
                                .foregroundStyle(DS.smoke)
                        }
                    }
                }
                .padding(.horizontal, DS.Space.m)
                .padding(.vertical, DS.Space.s + 2)
                .background(DS.fog.opacity(0.45))
                .clipShape(RoundedRectangle(cornerRadius: 10))
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.s)
                .padding(.bottom, DS.Space.xs)

                MonthBar(month: $selectedMonth)
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.vertical, DS.Space.m)

                if !snapshot.isEmpty {
                    let income   = monthIncome(from: snapshot)
                    let expenses = monthExpenses(from: snapshot)
                    HStack {
                        statsLabel("+" + income.currencyFormatted)
                        Spacer()
                        statsLabel("−" + expenses.currencyFormatted)
                        Spacer()
                        let net = income - expenses
                        statsLabel((net >= 0 ? "+" : "−") + abs(net).currencyFormatted)
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.bottom, DS.Space.m)
                }

                ThinDivider()

                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.xl) {
                        ForEach(TxFilter.allCases, id: \.self) { f in
                            filterChip(f.rawValue, active: txFilter == f) {
                                txFilter = f
                                if f != .tutti { selectedCat = "" }
                            }
                        }
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.vertical, DS.Space.m)
                }
                .tourAnchor("filterChips")

                if !categories.isEmpty {
                    ThinDivider()
                    ScrollView(.horizontal, showsIndicators: false) {
                        HStack(spacing: DS.Space.xl) {
                            ForEach(categories) { cat in
                                filterChip(cat.name, active: selectedCat == cat.name) {
                                    selectedCat = selectedCat == cat.name ? "" : cat.name
                                }
                            }
                        }
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.vertical, DS.Space.s)
                    }
                }

                ThinDivider()

                if snapshot.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "Nessun movimento",
                        subtitle: "I movimenti di questo periodo appariranno qui."
                    )
                    Spacer()
                } else {
                    List {
                        ForEach(Array(grouped(from: snapshot).enumerated()), id: \.element.key) { groupIndex, group in
                            Section {
                                ForEach(group.value) { t in
                                    transactionCell(t)
                                    .listRowInsets(EdgeInsets())
                                    .listRowBackground(DS.paper)
                                    .listRowSeparatorTint(DS.fog)
                                    .swipeActions(edge: .leading, allowsFullSwipe: true) {
                                        if t.isFixed || !t.isDone {
                                            Button {
                                                haptic(.soft)
                                                withAnimation(.spring(response: 0.3, dampingFraction: 0.75)) {
                                                    toggleTransferOrFixed(t)
                                                }
                                            } label: {
                                                Label(
                                                    t.isDone ? "Pianificato" : "Fatto",
                                                    systemImage: t.isDone ? "clock" : "checkmark.circle.fill"
                                                )
                                            }
                                            .tint(DS.smoke)
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
                                    }
                                }
                            } header: {
                                Text(LocalizedStringKey(group.key))
                                    .font(.system(size: 11, weight: .medium))
                                    .foregroundStyle(DS.smoke)
                                    .tracking(1.5)
                                    .padding(.horizontal, DS.Layout.margin)
                                    .padding(.top, DS.Space.l)
                                    .padding(.bottom, DS.Space.xs)
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                    .background(DS.paper)
                                    .listRowInsets(EdgeInsets())
                            }
                        }
                        // Spacer per non coprire il FAB.
                        // 60pt = FAB (52pt) + margine (8pt) − inset auto iOS per tab bar.
                        // 80pt era troppo → gap vuoto visibile sopra la tab bar.
                        Section {
                            Color.clear.frame(height: 60)
                                .listRowBackground(Color.clear)
                                .listRowSeparator(.hidden)
                        }
                    }
                    .listStyle(.plain)
                    .scrollContentBackground(.hidden)
                    .scrollIndicators(.hidden)
                    .tourAnchor("movimentiList")
                }
            }
            .background(DS.paper)
            .navigationTitle("Movimenti")
            .navigationBarTitleDisplayMode(.inline)
            // isSearchActive aggiornato tramite onChange: nasconde il FAB in ContentView
            // durante la ricerca (prima gestito da SearchActiveObserver + .searchable).
            .onChange(of: search)        { _, v in isSearchActive?.wrappedValue = !v.isEmpty || searchFocused }
            .onChange(of: searchFocused) { _, f in isSearchActive?.wrappedValue = f || !search.isEmpty }
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    HStack(spacing: DS.Space.m) {
                        Button { showAdvancedFilter = true } label: {
                            ZStack(alignment: .topTrailing) {
                                Image(systemName: "line.3.horizontal.decrease")
                                    .font(.system(size: 16))
                                    .foregroundStyle(DS.ink)
                                if activeAdvancedFilterCount > 0 {
                                    Text("\(activeAdvancedFilterCount)")
                                        .font(.system(size: 9, weight: .bold))
                                        .foregroundStyle(DS.paper)
                                        .frame(width: 14, height: 14)
                                        .background(DS.ink)
                                        .clipShape(Circle())
                                        .offset(x: 6, y: -6)
                                }
                            }
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape")
                                .font(.system(size: 16))
                                .foregroundStyle(DS.ink)
                        }
                    }
                }
            }
            .sheet(item: $editing) { AddTransactionView(editing: $0) }
            .sheet(isPresented: $showAdvancedFilter) { advancedFilterSheet }
            // Fix iOS 26: .tint(DS.ink) sovrascrive il tint di sistema (verde di default
            // in alcune versioni di iOS 26) per List, search bar e swipe actions.
            .tint(DS.ink)
            .themedNavBar()
            .sheet(isPresented: $showSettings) { SettingsView() }
            // BUG-04: confirm before deleting both legs of a transfer
            .confirmationDialog(
                "Elimina trasferimento",
                isPresented: Binding(
                    get: { transferToDelete != nil },
                    set: { if !$0 { transferToDelete = nil } }
                ),
                titleVisibility: .visible
            ) {
                Button("Elimina entrambi i movimenti", role: .destructive) {
                    if let t = transferToDelete { deleteTransactionOrPair(t) }
                    transferToDelete = nil
                }
                Button("Annulla", role: .cancel) { transferToDelete = nil }
            } message: {
                Text("Questo trasferimento è composto da due movimenti collegati. Verranno eliminati entrambi.")
            }
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
        Group {
            if t.isFixed {
                FixedExpenseRow(
                    transaction: t,
                    paid:     t.isDone,
                    isIncome: t.transactionType == .entrata
                ) {
                    // tap sul checkmark → apri modifica (toggle è sullo swipe destra)
                    editing = t
                }
                .padding(.horizontal, DS.Layout.margin)
            } else {
                DSTransactionRow(transaction: t)
                    .padding(.horizontal, DS.Layout.margin)
            }
        }
        .contentShape(Rectangle())
        .onTapGesture { editing = t }
        // long press → solo elimina
        .contextMenu {
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

    // MARK: - Helpers

    private func filterChip(_ label: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            VStack(spacing: 5) {
                Text(LocalizedStringKey(label))
                    .font(.system(size: 13, weight: active ? .semibold : .regular))
                    .foregroundStyle(active ? DS.ink : DS.smoke)
                Rectangle()
                    .fill(active ? DS.ink : Color.clear)
                    .frame(height: 1)
            }
        }
    }

    private func statsLabel(_ text: String) -> some View {
        Text(text)
            .font(.system(size: 11, weight: .medium))
            .foregroundStyle(DS.smoke)
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
