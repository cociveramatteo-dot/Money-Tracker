import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @State private var recurrenceStatus = RecurrenceOperationStatus()
    @Query private var accounts: [Account]
    @Query private var rules: [RecurringRule]
    @Query(sort: \Category.sortOrder) private var categories: [Category]

    var editing: Transaction? = nil

    @State private var name:            String      = ""
    @State private var amount:          String      = ""
    @State private var type:            TransactionType = .uscita
    @State private var selectedCat:     Category?   = nil
    @State private var selectedAccount: Account?    = nil
    @State private var date:            Date        = Date()
    @State private var isDone:               Bool        = true
    @State private var isFixed:              Bool        = false
    @State private var recurringFrequency:   String      = ""
    @State private var notes:                String      = ""
    @State private var showCatPicker:        Bool        = false
    @State private var suggestedCat:         String      = ""
    @State private var suggestionFromHistory = false
    @State private var accountUsageCounts:   [UUID: Int] = [:]
    /// true = l'utente ha scelto la categoria manualmente dal picker in questa sessione.
    /// Quando è true, il cambio del nome NON sovrascrive la categoria.
    @State private var categoryManuallyOverridden: Bool = false
    /// Task corrente del debounce: annullato e ricreato ad ogni keystroke.
    @State private var classifyTask: Task<Void, Never>? = nil

    private enum AddTxFocus: Hashable { case importo, nome }
    @FocusState private var focus: AddTxFocus?

    private let frequencies: [(label: String, value: String)] = [
        ("Nessuna",     ""),
        ("Settimanale", "settimanale"),
        ("Mensile",     "mensile"),
        ("Annuale",     "annuale"),
    ]

    private var activeAccounts: [Account] {
        Self.orderByUsage(accounts.filter { !$0.isArchived }, counts: accountUsageCounts)
    }

    static func orderByUsage(_ accounts: [Account], counts: [UUID: Int]) -> [Account] {
        accounts.enumerated()
            .sorted { lhs, rhs in
                let leftCount = counts[lhs.element.id, default: 0]
                let rightCount = counts[rhs.element.id, default: 0]
                if leftCount != rightCount { return leftCount > rightCount }
                return lhs.offset < rhs.offset
            }
            .map(\.element)
    }

    static func isFutureDate(_ date: Date, relativeTo today: Date = Date(), calendar: Calendar = .current) -> Bool {
        calendar.startOfDay(for: date) > calendar.startOfDay(for: today)
    }

    static func defaultDone(isFixed: Bool, date: Date, relativeTo today: Date = Date(), calendar: Calendar = .current) -> Bool {
        !isFixed && !isFutureDate(date, relativeTo: today, calendar: calendar)
    }

    private var isSaveDisabled: Bool {
        let v = Decimal.parseAmount(amount) ?? 0
        return name.isEmpty || v <= 0 || v > 1_000_000_000
    }

    var body: some View {
        transactionForm
    }

    private var transactionForm: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    UnderlineSegment(options: TransactionType.allCases, selected: $type)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Importo")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(type == .uscita ? "−\(Double.currencySymbol)" : "+\(Double.currencySymbol)")
                                .scaledFont(size: 28, weight: .ultraLight)
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: $amount)
                                .scaledFont(size: 56, weight: .black)
                                .foregroundStyle(DS.ink)
                                .keyboardType(.decimalPad)
                                .focused($focus, equals: .importo)
                                .submitLabel(.next)
                                .onSubmit { focus = .nome }
                                .accessibilityIdentifier("tf_amount")
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Descrizione")
                        TextField("es. Affitto, Netflix, Pizza...", text: $name)
                            .scaledFont(size: 22, weight: .light)
                            .foregroundStyle(DS.ink)
                            .focused($focus, equals: .nome)
                            .submitLabel(.done)
                            .onSubmit {
                                focus = nil
                                let v = Decimal.parseAmount(amount) ?? 0
                                if !name.isEmpty && v > 0 && v <= 1_000_000_000 { save() }
                            }
                            .onChange(of: name) { _, v in
                                guard !categoryManuallyOverridden else { return }
                                // Debounce 280ms: annulla il task precedente ad ogni keystroke
                                classifyTask?.cancel()
                                classifyTask = Task {
                                    try? await Task.sleep(nanoseconds: 280_000_000)
                                    guard !Task.isCancelled else { return }
                                    guard !categoryManuallyOverridden else { return }
                                    applySuggestion(for: v)
                                }
                            }
                            .accessibilityIdentifier("tf_name")
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Categoria")
                        Button { showCatPicker = true } label: {
                            HStack {
                                Image(systemName: selectedCat?.icon ?? "circle.dotted")
                                    .scaledFont(size: 14)
                                    .foregroundStyle(DS.smoke)
                                    .frame(width: 20)
                                (selectedCat.map { DS.categoryText($0.name) } ?? Text("Scegli..."))
                                    .scaledFont(size: 17, weight: .medium)
                                    .foregroundStyle(selectedCat != nil ? DS.ink : DS.smoke)
                                if let cat = selectedCat, cat.name == suggestedCat {
                                    Text(suggestionFromHistory ? LocalizedStringKey("· Ultima usata") : LocalizedStringKey("· suggerita"))
                                        .scaledFont(size: 12)
                                        .foregroundStyle(DS.smoke)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .scaledFont(size: 11)
                                    .foregroundStyle(DS.smoke)
                            }
                        }
                        .accessibilityIdentifier("btn_categoryPicker")
                        ThinDivider()
                    }

                    if !activeAccounts.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Space.m) {
                            SectionLabel(text: "Conto")
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Space.l) {
                                    ForEach(activeAccounts) { acc in
                                        Button {
                                            selectedAccount = selectedAccount?.id == acc.id ? nil : acc
                                        } label: {
                                            VStack(spacing: 5) {
                                                Text(acc.name)
                                                    .scaledFont(size: 13, weight: selectedAccount?.id == acc.id ? .semibold : .regular)
                                                    .foregroundStyle(selectedAccount?.id == acc.id ? DS.ink : DS.smoke)
                                                Rectangle()
                                                    .fill(selectedAccount?.id == acc.id ? DS.ink : Color.clear)
                                                    .frame(height: 1)
                                            }
                                        }
                                        .accessibilityIdentifier("accountChip_\(acc.name)")
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Opzioni")

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text(LocalizedStringKey(type == .uscita ? "Spesa fissa" : "Entrata fissa"))
                                    .scaledFont(size: 15)
                                    .foregroundStyle(DS.ink)
                                Text("Appare in 'Fissi del mese' nella home")
                                    .scaledFont(size: 11)
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: Binding(
                                get: { isFixed },
                                set: { newValue in
                                    isFixed = newValue
                                    isDone = Self.defaultDone(isFixed: newValue, date: date)
                                }
                            ))
                                .tint(DS.ink)
                                .labelsHidden()
                                .accessibilityIdentifier("toggle_isFixed")
                        }

                        // "Già effettuato" appare per le voci fisse o con data futura
                        if isFixed || Self.isFutureDate(date) {
                            ThinDivider()
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Già effettuato")
                                        .scaledFont(size: 15)
                                        .foregroundStyle(DS.ink)
                                    Text("Togli la spunta se è pianificata ma non ancora fatta")
                                        .scaledFont(size: 11)
                                        .foregroundStyle(DS.smoke)
                                }
                                Spacer()
                                Toggle("", isOn: $isDone)
                                    .tint(DS.ink)
                                    .labelsHidden()
                                    .accessibilityIdentifier("toggle_isDone")
                            }
                        }

                        ThinDivider()

                        if editing == nil {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Ricorrenza")
                                        .scaledFont(size: 15)
                                        .foregroundStyle(DS.ink)
                                    Text("Crea automaticamente al prossimo periodo")
                                        .scaledFont(size: 11)
                                        .foregroundStyle(DS.smoke)
                                }
                                Spacer()
                                Picker("", selection: $recurringFrequency) {
                                    ForEach(frequencies, id: \.value) { f in
                                        Text(LocalizedStringKey(f.label)).tag(f.value)
                                    }
                                }
                                .pickerStyle(.menu)
                                .accessibilityIdentifier("picker_recurrence")
                                .tint(DS.ink)
                            }
                        }
                        ThinDivider()

                        HStack {
                            Text("Data")
                                .scaledFont(size: 15)
                                .foregroundStyle(DS.smoke)
                            Spacer()
                            DatePicker("", selection: Binding(
                                get: { date },
                                set: { newDate in
                                    date = newDate
                                    if !isFixed {
                                        isDone = !Self.isFutureDate(newDate)
                                    }
                                }
                            ), displayedComponents: [.date])
                                .labelsHidden()
                                .tint(DS.ink)
                                .accessibilityIdentifier("picker_date")
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Note")
                        TextField("Aggiungi una nota...", text: $notes, axis: .vertical)
                            .scaledFont(size: 15, weight: .light)
                            .foregroundStyle(DS.ink)
                            .lineLimit(3, reservesSpace: false)
                            .accessibilityIdentifier("tf_notes")
                        ThinDivider()
                    }

                    PrimaryButton(title: editing == nil ? "Salva" : "Aggiorna") { save() }
                        .disabled(isSaveDisabled)
                        .accessibilityIdentifier("btn_saveTransaction")
                }
                .padding(.horizontal, DS.Layout.margin)
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.xxl)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    GhostButton(title: "Annulla") { dismiss() }
                        .accessibilityIdentifier("btn_cancelAddTransaction")
                }
            }
            .sheet(isPresented: $showCatPicker) {
                CategoryPickerView(selected: $selectedCat)
            }
            .onChange(of: selectedCat) { _, newCat in
                if let cat = newCat, cat.name != suggestedCat {
                    categoryManuallyOverridden = true
                    suggestedCat = ""
                }
            }
            .recurrenceErrorAlert(recurrenceStatus)
            .onAppear { load() }
        }
    }

    // MARK: - Load / Save

    static func fetchAccountUsageCounts(for accounts: [Account], context: ModelContext) -> [UUID: Int] {
        var counts: [UUID: Int] = [:]
        counts.reserveCapacity(accounts.count)
        for acc in accounts where !acc.isArchived {
            let accountID = acc.id
            let descriptor = FetchDescriptor<Transaction>(
                predicate: #Predicate { $0.account?.id == accountID }
            )
            counts[accountID] = (try? context.fetchCount(descriptor)) ?? 0
        }
        return counts
    }

    private func load() {
        accountUsageCounts = Self.fetchAccountUsageCounts(for: accounts, context: context)

        guard let t = editing else {
            name                     = ""
            amount                   = ""
            type                     = .uscita
            selectedCat              = nil
            date                     = Date()
            isDone                   = true
            isFixed                  = false
            recurringFrequency       = ""
            notes                    = ""
            suggestedCat             = ""
            suggestionFromHistory    = false
            categoryManuallyOverridden = false
            selectedAccount          = activeAccounts.first
            return
        }
        name            = t.name
        amount          = t.amount.editableString
        type            = t.transactionType
        selectedCat     = categories.first { $0.name == t.category }
        selectedAccount = t.account
        date            = t.date
        isDone          = t.isDone
        isFixed             = t.isFixed
        recurringFrequency  = t.recurringFrequency
        notes               = t.notes
        categoryManuallyOverridden = false
    }

    /// Suggerisce la categoria: prima l'ultima usata per lo stesso nome, poi le parole chiave.
    @MainActor private func applySuggestion(for v: String) {
        let trimmed = v.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else {
            suggestedCat = ""
            suggestionFromHistory = false
            selectedCat = nil
            return
        }
        // Pre-filtro sulla prima parola (insensibile a maiuscole/accenti): il confronto esatto resta nel Domain.
        let firstWord = trimmed.split(whereSeparator: \.isWhitespace).first.map(String.init) ?? trimmed
        let descriptor = FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.isDone && !$0.isTransfer && $0.name.localizedStandardContains(firstWord) },
            sortBy: [SortDescriptor(\Transaction.createdAt)]
        )
        let history = (try? context.fetch(descriptor)) ?? []
        let previous = LastUsedCategory.suggest(
            for: v,
            history: history.filter { $0.id != editing?.id }.map {
                .init(name: $0.name, category: $0.category, createdAt: $0.createdAt,
                      isDone: $0.isDone, isTransfer: $0.isTransfer)
            },
            availableCategories: Set(categories.map(\.name))
        )
        let suggestion = previous ?? (v.count > 2 ? KeywordCategoryClassifier.shared.classify(v) : "Altro")
        suggestionFromHistory = previous != nil
        if previous != nil || suggestion != "Altro",
           let category = categories.first(where: { $0.name == suggestion }) {
            suggestedCat = suggestion
            selectedCat = category
        } else {
            suggestedCat = ""
            selectedCat = nil
        }
    }

    private func save() {
        let amt = Decimal.parseAmount(amount) ?? 0
        guard amt > 0 else { return }

        let catName = selectedCat?.name ?? "Altro"
        let catIcon = selectedCat?.icon ?? "circle.dotted"

        if let t = editing, let rule = rules.first(where: { $0.id.uuidString == t.templateId }) {
            var values = RecurringSeriesEditor.snapshot(rule)
            values.name = name; values.amount = amt; values.type = type.rawValue
            values.category = catName; values.categoryIcon = catIcon; values.accountId = selectedAccount?.id
            values.isFixed = isFixed; values.notes = notes
            // Preserve the selected occurrence's position in the series. A prior single-date
            // override shown in this form becomes the date shift for the entire series too.
            let originalDate = RecurrenceSelection.resolve(t, rules: [rule])?.occurrence.originalDate ?? t.date
            values.startDate = RecurrenceCalculator().anchorForSeriesEdit(rule: values, originalDate: originalDate, date: date)
            // Completion remains local to this copy (Matteo, 2026-11-15).
            // Apply it before reconciliation, which may replace a planned copy after a date change.
            let previousDone = t.isDone
            t.isDone = isDone
            guard recurrenceStatus.perform({
                try RecurringSeriesEditor().apply(.edit(.all, values), to: rule,
                                                 originalDate: rule.startDate, context: context)
            }) else { t.isDone = previousDone; return }
        } else if let t = editing {
            t.name         = name
            t.amount       = amt
            t.type         = type.rawValue
            t.category     = catName
            t.categoryIcon = catIcon
            t.account      = selectedAccount
            t.date         = date
            t.isDone              = isDone
            t.isFixed             = isFixed
            t.notes               = notes
        } else {
            let transaction = Transaction(
                name:               name,
                amount:             amt,
                type:               type,
                category:           catName,
                categoryIcon:       catIcon,
                date:               date,
                isDone:             isDone,
                isFixed:            isFixed,
                notes:              notes,
                recurringFrequency: "",
                account:            selectedAccount
            )
            if !recurringFrequency.isEmpty {
                let rule = RecurringRule(name: name, amount: amt, type: type.rawValue,
                                         category: catName, categoryIcon: catIcon, notes: notes,
                                         isFixed: isFixed, accountId: selectedAccount?.id,
                                         frequency: recurringFrequency, startDate: date)
                transaction.id = RecurrenceCalculator.occurrenceID(ruleId: rule.id, key: RecurrenceCalculator().key(for: date))
                transaction.templateId = rule.id.uuidString
                context.insert(rule)
                context.insert(transaction)
                // The materializer sees the pending first occurrence and saves it with the rule
                // and this month's other copies in a single persistence operation.
                guard recurrenceStatus.perform({ try RecurringMaterializer().materializeDue(context: context) }) else {
                    context.delete(transaction); context.delete(rule)
                    return
                }
            } else {
                context.insert(transaction)
                guard context.safeSave() else { return }
            }
        }
        guard context.safeSave() else { return }

        if type == .uscita && isDone {
            SystemNotificationManager.shared.checkBudgets(context: context, forMonth: date)
        }

        // Check balance threshold for the affected account
        if let acc = selectedAccount, isDone {
            SystemNotificationManager.shared.checkBalanceThreshold(
                accountId: acc.id.uuidString,
                accountName: acc.name,
                currentBalance: acc.currentBalance
            )
        }

        dismiss()
    }
}

// MARK: - Category Picker Sheet

struct CategoryPickerView: View {
    @Binding var selected: Category?
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Environment(\.dismiss) private var dismiss

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 0) {
                    ForEach(categories) { cat in
                        Button {
                            selected = cat
                            dismiss()
                        } label: {
                            HStack(spacing: DS.Space.m) {
                                Image(systemName: cat.icon)
                                    .scaledFont(size: 16)
                                    .foregroundStyle(DS.smoke)
                                    .frame(width: 20)
                                DS.categoryText(cat.name)
                                    .scaledFont(size: 15, weight: selected?.id == cat.id ? .semibold : .regular)
                                    .foregroundStyle(DS.ink)
                                Spacer()
                                if selected?.id == cat.id {
                                    Image(systemName: "checkmark")
                                        .scaledFont(size: 13, weight: .medium)
                                        .foregroundStyle(DS.ink)
                                }
                            }
                            .padding(.horizontal, DS.Layout.margin)
                            .padding(.vertical, DS.Layout.rowVPad)
                        }
                        .accessibilityIdentifier("categoryRow_\(cat.name)")
                        ThinDivider()
                            .padding(.leading, DS.Layout.margin + 20 + DS.Space.m)
                    }
                }
                .padding(.top, DS.Space.m)
                .padding(.bottom, DS.Space.xl)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .navigationTitle("Categoria")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    GhostButton(title: "Chiudi") { dismiss() }
                        .accessibilityIdentifier("btn_closeCategoryPicker")
                }
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink {
                        CategoryManagementView()
                    } label: {
                        Text("Gestisci")
                            .scaledFont(size: 15)
                            .foregroundStyle(DS.smoke)
                    }
                    .accessibilityIdentifier("btn_manageCategories")
                }
            }
        }
    }
}
