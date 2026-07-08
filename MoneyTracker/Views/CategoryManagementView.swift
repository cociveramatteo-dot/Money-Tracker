import SwiftUI
import SwiftData

struct CategoryManagementView: View {
    @Query(sort: \Category.sortOrder) private var allCategories: [Category]
    @Query private var allTransactions: [Transaction]
    @Environment(\.modelContext) private var context
    @State private var showAdd            = false
    @State private var editing: Category? = nil
    @State private var selectedDefault: Category? = nil
    @State private var categoryToDelete: Category? = nil
    // PERF-04: cache del conteggio transazioni per categoria.
    // Era una computed var O(n) ricalcolata ad ogni render; ora è @State ricostruita
    // solo in .onAppear e .onChange(of: allTransactions).
    @State private var txCountByCategory: [String: Int] = [:]

    private var defaults: [Category] { allCategories.filter {  $0.isDefault } }
    private var custom:   [Category] { allCategories.filter { !$0.isDefault } }

    private func rebuildTxCount() {
        var dict: [String: Int] = [:]
        for t in allTransactions { dict[t.category, default: 0] += 1 }
        txCountByCategory = dict
    }

    private func txCount(for cat: Category) -> Int {
        txCountByCategory[cat.name] ?? 0
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    SectionLabel(text: "Predefinite")
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.xl)
                        .padding(.bottom, DS.Space.m)

                    VStack(spacing: 0) {
                        ForEach(defaults) { cat in
                            CategoryRow(cat: cat, isDefault: true)
                                .padding(.horizontal, DS.Layout.margin)
                                .contentShape(Rectangle())
                                .onTapGesture { selectedDefault = cat }
                            ThinDivider().padding(.leading, DS.Layout.margin + 36 + DS.Space.m)
                        }
                    }

                    SectionLabel(text: "Personalizzate")
                        .padding(.horizontal, DS.Layout.margin)
                        .padding(.top, DS.Space.xl)
                        .padding(.bottom, DS.Space.m)

                    if custom.isEmpty {
                        Text("Nessuna categoria personalizzata.\nPremi + per aggiungerne una.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, DS.Layout.margin)
                            .padding(.bottom, DS.Space.l)
                    } else {
                        VStack(spacing: 0) {
                            ForEach(custom) { cat in
                                CategoryRow(cat: cat, isDefault: false)
                                    .padding(.horizontal, DS.Layout.margin)
                                    .contentShape(Rectangle())
                                    .onTapGesture { editing = cat }
                                    .contextMenu {
                                        Button { editing = cat } label: {
                                            Label("Modifica", systemImage: "pencil")
                                        }
                                        Divider()
                                        Button(role: .destructive) {
                                            categoryToDelete = cat
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    }
                                ThinDivider().padding(.leading, DS.Layout.margin + 36 + DS.Space.m)
                            }
                        }
                    }

                    Spacer(minLength: 80)
                }
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .onAppear { rebuildTxCount() }
            .onChange(of: allTransactions) { _, _ in rebuildTxCount() }
            .navigationTitle("Categorie")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showAdd = true } label: {
                        Image(systemName: "plus").foregroundStyle(DS.ink)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddCategoryView() }
            .sheet(item: $editing) { AddCategoryView(editing: $0) }
            .alert("Categoria predefinita", isPresented: Binding(
                       get: { selectedDefault != nil },
                       set: { if !$0 { selectedDefault = nil } }
                   )) {
                Button("OK", role: .cancel) {}
            } message: {
                Text("Le categorie predefinite non possono essere modificate o eliminate.")
            }
            .alert(
                deleteAlertTitle,
                isPresented: Binding(
                    get: { categoryToDelete != nil },
                    set: { if !$0 { categoryToDelete = nil } }
                )
            ) {
                Button("Annulla", role: .cancel) { categoryToDelete = nil }
                Button("Elimina", role: .destructive) {
                    if let cat = categoryToDelete {
                        for tx in allTransactions where tx.category == cat.name {
                            tx.categoryIcon = DS.categoryIcon(for: tx.category)
                        }
                        context.delete(cat)
                        context.safeSave()
                    }
                    categoryToDelete = nil
                }
            } message: {
                Text(deleteAlertMessage)
            }
        }
    }

    private var deleteAlertTitle: String {
        guard let cat = categoryToDelete else { return "Elimina categoria" }
        return NSLocalizedString("Elimina", comment: "") + " \"\(cat.name)\""
    }

    private var deleteAlertMessage: String {
        guard let cat = categoryToDelete else { return "" }
        let count = txCount(for: cat)
        if count == 0 {
            return NSLocalizedString("Sei sicuro di voler eliminare questa categoria?", comment: "")
        } else if count == 1 {
            return NSLocalizedString("1 transazione usa questa categoria. L'icona tornerà a quella predefinita. Continuare?", comment: "")
        } else {
            return String(format: NSLocalizedString("%d transazioni usano questa categoria. Le icone torneranno a quella predefinita. Continuare?", comment: ""), count)
        }
    }
}

// MARK: - Category Row

struct CategoryRow: View {
    let cat: Category
    let isDefault: Bool

    var body: some View {
        HStack(spacing: DS.Space.m) {
            ZStack {
                Circle()
                    .fill(DS.fog)
                    .frame(width: 36, height: 36)
                Image(systemName: cat.icon)
                    .font(.system(size: 15))
                    .foregroundStyle(DS.smoke)
            }

            Text(LocalizedStringKey(cat.name))
                .font(.system(size: 15, weight: .medium))
                .foregroundStyle(DS.ink)

            Spacer()

            if isDefault {
                Text("predefinita")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.smoke)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(DS.fog)
                    .clipShape(Capsule())
            } else {
                Image(systemName: "chevron.right")
                    .font(.system(size: 11))
                    .foregroundStyle(DS.smoke)
            }
        }
        .padding(.vertical, DS.Layout.rowVPad)
    }
}

// MARK: - Add / Edit Category

struct AddCategoryView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var allCategories: [Category]

    var editing: Category? = nil

    @State private var name:         String = ""
    @State private var selectedIcon: String = "circle.dotted"
    @State private var showIconGrid: Bool   = false

    private let columns = Array(repeating: GridItem(.flexible()), count: 6)

    /// true se un'altra categoria (diversa da quella in modifica) ha già questo nome,
    /// a meno di maiuscole/minuscole — evita doppioni che confonderebbero filtri e budget.
    private var isDuplicateName: Bool {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return false }
        return allCategories.contains {
            $0.id != editing?.id && $0.name.localizedCaseInsensitiveCompare(trimmed) == .orderedSame
        }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    Text(LocalizedStringKey(editing == nil ? "Nuova categoria" : "Modifica categoria"))
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.ink)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Icona")
                        Button { showIconGrid.toggle() } label: {
                            HStack(spacing: DS.Space.m) {
                                ZStack {
                                    Circle()
                                        .fill(DS.fog)
                                        .frame(width: 48, height: 48)
                                    Image(systemName: selectedIcon)
                                        .font(.system(size: 20))
                                        .foregroundStyle(DS.ink)
                                }
                                Text("Cambia icona")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.smoke)
                                Spacer()
                                Image(systemName: showIconGrid ? "chevron.up" : "chevron.down")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                        }

                        if showIconGrid {
                            LazyVGrid(columns: columns, spacing: DS.Space.m) {
                                ForEach(DS.availableIcons, id: \.symbol) { item in
                                    Button {
                                        selectedIcon = item.symbol
                                        showIconGrid = false
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(selectedIcon == item.symbol ? DS.ink : DS.fog)
                                                .frame(width: 44, height: 44)
                                            Image(systemName: item.symbol)
                                                .font(.system(size: 16))
                                                .foregroundStyle(
                                                    selectedIcon == item.symbol ? DS.paper : DS.smoke
                                                )
                                        }
                                    }
                                }
                            }
                            .padding(.top, DS.Space.m)
                        }

                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Nome")
                        TextField("es. Musica, Sport, Palestra...", text: $name)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(DS.ink)
                        ThinDivider()
                        if isDuplicateName {
                            Text("Esiste già una categoria con questo nome.")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.smoke)
                        }
                    }

                    PrimaryButton(title: editing == nil ? "Salva" : "Aggiorna") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespaces).isEmpty || isDuplicateName)
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
                }
            }
            .onAppear { load() }
        }
    }

    private func load() {
        guard let c = editing else {
            name         = ""
            selectedIcon = "circle.dotted"
            showIconGrid = false
            return
        }
        name         = c.name
        selectedIcon = c.icon
        showIconGrid = false
    }

    private func save() {
        let trimmed = name.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else { return }
        if let c = editing {
            let oldName = c.name
            c.name = trimmed
            c.icon = selectedIcon
            // Rinominare una categoria non deve "orfanizzare" i dati già salvati:
            // Transaction.category e Budget.category sono stringhe indipendenti
            // (non una relazione), quindi vanno aggiornate esplicitamente qui.
            if oldName != trimmed {
                renameCategoryEverywhere(from: oldName, to: trimmed)
            }
        } else {
            context.insert(Category(name: trimmed, icon: selectedIcon, isDefault: false))
        }
        context.safeSave()
        dismiss()
    }

    private func renameCategoryEverywhere(from oldName: String, to newName: String) {
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>(
            predicate: #Predicate { $0.category == oldName }
        ))) ?? []
        for t in transactions { t.category = newName }

        // budget.category è "Tutti" oppure un elenco separato da virgola di nomi
        // categoria (vedi AddBudgetView.save()) — va aggiornato token per token.
        let budgets = (try? context.fetch(FetchDescriptor<Budget>())) ?? []
        for b in budgets where b.category != "Tutti" {
            let names = b.category.split(separator: ",").map(String.init)
            guard names.contains(oldName) else { continue }
            b.category = names.map { $0 == oldName ? newName : $0 }.sorted().joined(separator: ",")
        }
    }
}
