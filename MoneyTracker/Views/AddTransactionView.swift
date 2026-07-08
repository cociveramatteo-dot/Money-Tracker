import SwiftUI
import SwiftData

struct AddTransactionView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
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

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    private var isSaveDisabled: Bool {
        let v = Decimal.parseAmount(amount) ?? 0
        return name.isEmpty || v <= 0 || v > 1_000_000_000
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    UnderlineSegment(options: TransactionType.allCases, selected: $type)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Importo")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(type == .uscita ? "−\(Double.currencySymbol)" : "+\(Double.currencySymbol)")
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: $amount)
                                .font(.system(size: 56, weight: .black))
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
                            .font(.system(size: 22, weight: .light))
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
                                    let suggestion = v.count > 2 ? KeywordCategoryClassifier.shared.classify(v) : "Altro"
                                    await MainActor.run {
                                        if suggestion != "Altro" {
                                            suggestedCat = suggestion
                                            selectedCat = categories.first { $0.name == suggestion }
                                        } else {
                                            suggestedCat = ""
                                            selectedCat = nil
                                        }
                                    }
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
                                    .font(.system(size: 14))
                                    .foregroundStyle(DS.smoke)
                                    .frame(width: 20)
                                Text(selectedCat?.name ?? NSLocalizedString("Scegli...", comment: ""))
                                    .font(.system(size: 17, weight: .medium))
                                    .foregroundStyle(selectedCat != nil ? DS.ink : DS.smoke)
                                if let cat = selectedCat, cat.name == suggestedCat {
                                    Text("· suggerita")
                                        .font(.system(size: 12))
                                        .foregroundStyle(DS.smoke)
                                }
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 11))
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
                                                    .font(.system(size: 13,
                                                          weight: selectedAccount?.id == acc.id ? .semibold : .regular))
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
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Appare in 'Fissi del mese' nella home")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $isFixed)
                                .tint(DS.ink)
                                .labelsHidden()
                                .onChange(of: isFixed) { _, v in
                                    if v { isDone = false } else { isDone = true }
                                }
                                .accessibilityIdentifier("toggle_isFixed")
                        }

                        // "Già effettuato" appare solo per le voci fisse
                        if isFixed {
                            ThinDivider()
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Già effettuato")
                                        .font(.system(size: 15))
                                        .foregroundStyle(DS.ink)
                                    Text("Togli la spunta se è pianificata ma non ancora fatta")
                                        .font(.system(size: 11))
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

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Ricorrenza")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Crea automaticamente al prossimo periodo")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Picker("", selection: $recurringFrequency) {
                                ForEach(frequencies, id: \.value) { f in
                                    Text(LocalizedStringKey(f.label)).tag(f.value)
                                }
                            }
                            .pickerStyle(.menu)
                            .tint(DS.ink)
                        }
                        ThinDivider()

                        HStack {
                            Text("Data")
                                .font(.system(size: 15))
                                .foregroundStyle(DS.smoke)
                            Spacer()
                            DatePicker("", selection: $date, displayedComponents: [.date])
                                .labelsHidden()
                                .tint(DS.ink)
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Note")
                        TextField("Aggiungi una nota...", text: $notes, axis: .vertical)
                            .font(.system(size: 15, weight: .light))
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
            .onAppear { load() }
        }
    }

    // MARK: - Load / Save

    private func load() {
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

    private func save() {
        let amt = Decimal.parseAmount(amount) ?? 0
        guard amt > 0 else { return }

        let catName = selectedCat?.name ?? "Altro"
        let catIcon = selectedCat?.icon ?? "circle.dotted"

        if let t = editing {
            t.name         = name
            t.amount       = amt
            t.type         = type.rawValue
            t.category     = catName
            t.categoryIcon = catIcon
            t.account      = selectedAccount
            t.date         = date
            t.isDone              = isDone
            t.isFixed             = isFixed
            t.recurringFrequency  = recurringFrequency
            t.notes               = notes
        } else {
            context.insert(Transaction(
                name:               name,
                amount:             amt,
                type:               type,
                category:           catName,
                categoryIcon:       catIcon,
                date:               date,
                isDone:             isDone,
                isFixed:            isFixed,
                notes:              notes,
                recurringFrequency: recurringFrequency,
                account:            selectedAccount
            ))
        }
        context.safeSave()

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
                                    .font(.system(size: 16))
                                    .foregroundStyle(DS.smoke)
                                    .frame(width: 20)
                                Text(LocalizedStringKey(cat.name))
                                    .font(.system(size: 15,
                                          weight: selected?.id == cat.id ? .semibold : .regular))
                                    .foregroundStyle(DS.ink)
                                Spacer()
                                if selected?.id == cat.id {
                                    Image(systemName: "checkmark")
                                        .font(.system(size: 13, weight: .medium))
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
                            .font(.system(size: 15))
                            .foregroundStyle(DS.smoke)
                    }
                    .accessibilityIdentifier("btn_manageCategories")
                }
            }
        }
    }
}
