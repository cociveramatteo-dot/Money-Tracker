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

    var isSearchActive: Binding<Bool>? = nil

    @State private var selectedMonth  = Date()
    @State private var selectedCat    = ""
    // Testo digitato sull'hub: alimenta solo la tendina `searchResults` (tutti i
    // movimenti, di qualunque sezione). Distinto da `sectionSearch`, che filtra
    // localmente la lista quando si è già dentro una sezione.
    @State private var hubSearchQuery = ""
    @State private var sectionSearch  = ""
    @State private var editing: Transaction? = nil
    @State private var showSettings        = false
    @State private var showAdvancedFilter  = false
    @State private var selectedSeries: RecurringSeries? = nil
    @State private var navPath: [TxFilter] = []
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
        return all.filter { t in
            if filterUseCustomDates {
                let from = Calendar.current.startOfDay(for: filterFromDate)
                let to   = Calendar.current.date(byAdding: .day, value: 1, to: Calendar.current.startOfDay(for: filterToDate)) ?? filterToDate
                guard t.date >= from && t.date < to else { return false }
            } else {
                guard t.date.isSameMonth(as: selectedMonth) else { return false }
            }
            guard sectionSearch.isEmpty || t.name.localizedCaseInsensitiveContains(sectionSearch) else { return false }
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

    // "Ricorrenti" è all-time (ignora il mese) e usa il rilevamento automatico
    // invece del filtro per tipo/mese di `filtered(for:)`.
    private func recurringSeries(matchingCategory: String) -> [RecurringSeries] {
        let detected = RecurringSeriesDetector.detect(from: all)
        let bySearch = sectionSearch.isEmpty
            ? detected
            : detected.filter { $0.name.localizedCaseInsensitiveContains(sectionSearch) }
        return matchingCategory.isEmpty ? bySearch : bySearch.filter { $0.category == matchingCategory }
    }

    // Tendina di ricerca sull'hub: TUTTI i movimenti (qualunque tipo/sezione, inclusi
    // i trasferimenti) il cui nome corrisponde — a differenza di `filtered(for:)`/
    // `recurringSeries`, nessuna esclusione per tipo, isFixed, isTransfer o mese.
    private var searchResults: [Transaction] {
        guard !hubSearchQuery.isEmpty else { return [] }
        return all.filter { $0.name.localizedCaseInsensitiveContains(hubSearchQuery) }
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
                    .accessibilityIdentifier("btn_openSettings")
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.vertical, DS.Space.s)
                searchField($hubSearchQuery, identifier: "tf_searchTransactions")
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.s)
                    .padding(.bottom, DS.Space.xs)
                    .focused($searchFocused)

                if hubSearchQuery.isEmpty {
                    typeChips(selected: .tutti)
                    secondaryChips
                    movementList(filtered(for: .tutti))
                } else {
                    ThinDivider()
                    // Tendina di ricerca: tutti i movimenti corrispondenti, di qualunque
                    // sezione — riusa transactionCell (tap = modifica/alert trasferimento,
                    // tieni premuto = elimina), nessuna funzionalità nuova da scrivere.
                    if searchResults.isEmpty {
                        Text("Nessun risultato")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                            .padding(.top, DS.Space.xl)
                        Spacer()
                    } else {
                        ScrollView {
                            LazyVStack(spacing: 0) {
                                ForEach(searchResults) { t in
                                    transactionCell(t)
                                    ThinDivider()
                                }
                                Color.clear.frame(height: 60)
                            }
                            .padding(.top, DS.Space.s)
                        }
                        .scrollIndicators(.hidden)
                    }
                }
            }
            .background(DS.paper)
            .navigationTitle("Movimenti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar(.hidden, for: .navigationBar)
            // isSearchActive aggiornato tramite onChange: nasconde il FAB in ContentView
            // durante la ricerca (prima gestito da SearchActiveObserver + .searchable).
            .onChange(of: hubSearchQuery) { _, v in
                isSearchActive?.wrappedValue = !v.isEmpty || searchFocused
            }
            .onChange(of: searchFocused)  { _, f in isSearchActive?.wrappedValue = f || !hubSearchQuery.isEmpty }
            // Aprire una sezione non chiude da solo il focus sulla ricerca
            // dell'hub (onDisappear non è affidabile su un push di
            // NavigationStack) — lo resettiamo esplicitamente qui, altrimenti la
            // tastiera ricompare da sola al ritorno sull'hub.
            .onChange(of: navPath) { _, path in
                if !path.isEmpty { searchFocused = false }
            }
            .navigationDestination(for: TxFilter.self) { f in subListContent(for: f) }
            .sheet(item: $editing) { AddTransactionView(editing: $0) }
            .sheet(item: $transferEditing) { AddTransferView(editing: $0) }
            .sheet(isPresented: $showAdvancedFilter) { advancedFilterSheet }
            // Fix iOS 26: .tint(DS.ink) sovrascrive il tint di sistema (verde di default
            // in alcune versioni di iOS 26) per List, search bar e swipe actions.
            .tint(DS.ink)
            .themedNavBar()
            .sheet(isPresented: $showSettings) { SettingsView() }
            .sheet(item: $selectedSeries) { s in RecurringSeriesDetailView(seriesID: s.id) }
            // Il dialog va agganciato anche qui (oltre che in subListContent) perché
            // questa root smette di essere la vista in primo piano quando si entra in
            // una sezione via NavigationLink: un .confirmationDialog attaccato a una
            // vista non in cima allo stack di navigazione resta "in sospeso" e
            // compare solo al ritorno sull'hub, invece che subito (era il Bug-04).
            .transferDeleteConfirmation(pending: $transferToDelete, onConfirm: deleteTransactionOrPair)
        }
    }

    // MARK: - Search bar (riusata sull'hub e dentro ogni sezione)

    private func searchField(_ text: Binding<String>, identifier: String) -> some View {
        HStack(spacing: DS.Space.s) {
            Image(systemName: "magnifyingglass")
                .font(.system(size: 14))
                .foregroundStyle(DS.smoke)
            TextField("Cerca...", text: text)
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

    // MARK: - Presentation (the existing filters still supply every snapshot)

    private func typeChips(selected: TxFilter) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.s) {
                ForEach([TxFilter.tutti, .fisse, .trasf, .uscite, .entrate, .ricorrenti], id: \.self) { f in
                    FilterChip(title: Text(LocalizedStringKey(f.rawValue)), isActive: selected == f) {
                        navPath.append(f)
                    }
                    .accessibilityIdentifier("txFilterBlock_\(f.rawValue)")
                }
            }
            .padding(.horizontal, DS.Layout.margin)
            .padding(.vertical, DS.Space.s)
        }
    }

    private var secondaryChips: some View {
        VStack(spacing: DS.Space.xs) {
            MonthBar(month: $selectedMonth)
                .padding(.horizontal, DS.Layout.margin)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: DS.Space.s) {
                    SegmentedPill(options: [.init(id: "", title: Text("Tutti"))] + categories.map {
                        .init(id: $0.name, title: DS.categoryText($0.name))
                    }, selection: $selectedCat)
                    .fixedSize(horizontal: true, vertical: false)
                    if activeAdvancedFilterCount > 0 {
                        FilterChip(title: Text("Filtri"), isActive: true, style: .secondary) {
                            showAdvancedFilter = true
                        }
                    }
                }
                .padding(.horizontal, DS.Layout.margin)
            }
        }
        .padding(.bottom, DS.Space.s)
    }

    private func dayTitle(_ transactions: [Transaction], fallback: String) -> String {
        guard let date = transactions.first?.date else { return fallback }
        if Calendar.current.isDateInToday(date) { return NSLocalizedString("Oggi", comment: "") }
        if Calendar.current.isDateInYesterday(date) { return NSLocalizedString("Ieri", comment: "") }
        return fallback
    }

    private func groupHeader(_ title: String, transactions: [Transaction], planned: Bool = false) -> some View {
        HStack {
            Text(title).font(DS.Typo.secondary).fontWeight(.semibold)
            Spacer(minLength: DS.Space.s)
            // Display-only subtotal; transfers do not represent income or expense.
            Text(transactions.filter { !$0.isTransfer }.reduce(Decimal.zero) { $0 + $1.signedAmount }.currencyFormatted)
                .font(DS.Typo.rowAmount)
        }
        .foregroundStyle(planned ? DS.plannedText : DS.smoke)
        .textCase(nil)
        .padding(.vertical, DS.Space.s)
    }

    private func movementList(_ snapshot: [Transaction]) -> some View {
        let planned = snapshot.filter { !$0.isDone }
        let completed = snapshot.filter { $0.isDone }
        return List {
            if !planned.isEmpty {
                Section {
                    ForEach(planned) { t in swipeableRow(t) }
                } header: {
                    groupHeader(NSLocalizedString("In arrivo · pianificati", comment: ""), transactions: planned, planned: true)
                }
            }
            ForEach(grouped(from: completed), id: \.key) { group in
                Section {
                    ForEach(group.value) { t in swipeableRow(t) }
                } header: {
                    groupHeader(dayTitle(group.value, fallback: group.key), transactions: group.value)
                }
            }
            Section {
                Color.clear.frame(height: 60)
                    .listRowBackground(Color.clear)
                    .listRowSeparator(.hidden)
            }
        }
        .listStyle(.insetGrouped)
        .listSectionSpacing(DS.Space.m)
        .contentMargins(.horizontal, DS.Layout.margin, for: .scrollContent)
        .scrollContentBackground(.hidden)
        .scrollIndicators(.hidden)
        .refreshable { await SyncService.shared.manualRefresh(context: context) }
    }

    // MARK: - Sezione (pagina di destinazione per ciascun blocco)

    @ViewBuilder
    private func subListContent(for f: TxFilter) -> some View {
        VStack(spacing: 0) {
            searchField($sectionSearch, identifier: "tf_sectionSearch")
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.s)
                .padding(.bottom, DS.Space.xs)

            if f != .trasf && !categories.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: DS.Space.xl) {
                        ForEach(categories) { cat in
                            filterChip(cat.name, active: selectedCat == cat.name) {
                                selectedCat = selectedCat == cat.name ? "" : cat.name
                            }
                        }
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.vertical, DS.Space.m)
                }
                ThinDivider()
            }

            if f == .ricorrenti {
                let series = recurringSeries(matchingCategory: selectedCat)
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
                            Color.clear.frame(height: 60)
                        }
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.m)
                    }
                    .scrollIndicators(.hidden)
                }
            } else {
                let snapshot = filtered(for: f)
                if snapshot.isEmpty {
                    EmptyStateView(
                        icon: "tray",
                        title: "Nessun movimento",
                        subtitle: "I movimenti di questo periodo appariranno qui."
                    )
                    Spacer()
                } else {
                    movementList(snapshot)
                }
            }
        }
        .background(DS.paper)
        .toolbar(.visible, for: .navigationBar)
        .navigationTitle(Text(LocalizedStringKey(f.rawValue)))
        .navigationBarTitleDisplayMode(.inline)
        // Filtro categoria e ricerca sono locali alla sezione: uscendo si azzerano,
        // così la prossima sezione aperta parte sempre senza stato ereditato per errore.
        .onDisappear { selectedCat = ""; sectionSearch = "" }
        // Vedi commento in `body`: questa è la vista realmente in primo piano quando si
        // è dentro una sezione (es. "Trasf."), quindi il dialog va agganciato anche qui
        // perché l'eliminazione con swipe funzioni subito, senza dover uscire e rientrare.
        .transferDeleteConfirmation(pending: $transferToDelete, onConfirm: deleteTransactionOrPair)
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
            metadata: [NSLocalizedString(t.category, comment: ""), t.account?.name ?? "", t.date.dayMonthFormatted]
                .filter { !$0.isEmpty }.joined(separator: " · "),
            amount: t.amount.currencyFormatted,
            categoryName: t.category,
            categorySymbol: t.categoryIcon.isEmpty ? DS.categoryIcon(for: t.category) : t.categoryIcon,
            kind: t.isTransfer ? .transfer : t.transactionType == .entrata ? .income : .expense,
            isPlanned: !t.isDone
        )
        .padding(.horizontal, DS.Space.l)
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
    private func swipeableRow(_ t: Transaction) -> some View {
        transactionCell(t)
            .listRowInsets(EdgeInsets())
            .listRowBackground(DS.surface)
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
