import SwiftUI
import SwiftData

extension View {
    func recurrenceErrorAlert(_ status: RecurrenceOperationStatus) -> some View {
        alert("Ricorrenze", isPresented: Binding(get: { status.errorMessage != nil }, set: { if !$0 { status.errorMessage = nil } })) {
            Button("OK", role: .cancel) { status.errorMessage = nil }
        } message: {
            Text((status.errorMessage ?? "").components(separatedBy: "\n")
                .map { NSLocalizedString($0, comment: "Recurrence error") }.joined(separator: "\n"))
        }
    }
}

/// The original date is recovered from the deterministic ID, never from an overridden date.
struct RecurrenceSelection: Identifiable {
    let rule: RecurringRule
    let occurrence: Occurrence
    var id: UUID { occurrence.id }

    static func resolve(_ transaction: Transaction, rules: [RecurringRule]) -> Self? {
        guard let rule = rules.first(where: { $0.id.uuidString == transaction.templateId }) else { return nil }
        var snapshot = RecurringSeriesEditor.snapshot(rule)
        snapshot.exceptions = [:]
        snapshot.endDate = nil
        let calendar = Calendar(identifier: .gregorian)
        // Include the whole anchor-to-copy range: historical copies may have been moved manually.
        guard let end = calendar.date(byAdding: .month, value: 1, to: max(transaction.date, rule.startDate, rule.materializedThrough ?? rule.startDate)) else { return nil }
        let interval = DateInterval(start: rule.startDate, end: end)
        guard let original = RecurrenceCalculator().occurrences(rule: snapshot, in: interval).first(where: { $0.id == transaction.id }) else { return nil }
        let effective = RecurrenceCalculator().occurrences(rule: RecurringSeriesEditor.snapshot(rule), in: interval).first { $0.id == transaction.id } ?? original
        return Self(rule: rule, occurrence: effective)
    }
}

struct RecurrenceEditorView: View {
    let selection: RecurrenceSelection
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @State private var status = RecurrenceOperationStatus()
    @State private var scope = 0
    @State private var name = ""
    @State private var amount = ""
    @State private var notes = ""
    @State private var date = Date()
    @State private var frequency = "mensile"
    @State private var type = "uscita"
    @State private var category = "Altro"
    @State private var accountID: UUID?
    @State private var fixed = false
    @State private var confirmDelete = false

    private var editorScope: RecurringSeriesEditor.Scope { scope == 0 ? .onlyThis : scope == 1 ? .following : .all }
    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Picker("Ambito", selection: $scope) {
                        Text("Solo questa").tag(0)
                        Text("Questa e le successive").tag(1)
                        Text("Tutte").tag(2)
                    }.accessibilityIdentifier("recurrence_scope")
                    Text("Le occorrenze già effettuate restano invariate.")
                        .foregroundStyle(DS.smoke)
                    TextField("Descrizione", text: $name).accessibilityIdentifier("recurrence_name")
                    TextField("Importo", text: $amount).keyboardType(.decimalPad)
                    TextField("Note", text: $notes, axis: .vertical)
                    if scope == 0 {
                        let month = Calendar(identifier: .gregorian).dateInterval(of: .month, for: selection.occurrence.originalDate)!
                        DatePicker("Data", selection: $date, in: month.start...month.end.addingTimeInterval(-1), displayedComponents: .date)
                    } else {
                        DatePicker("Data", selection: $date, displayedComponents: .date).disabled(scope == 1)
                    }
                    if scope == 0 { Text("La data deve restare nello stesso mese.").foregroundStyle(DS.smoke) }
                    if scope != 0 {
                        Picker("Ricorrenza", selection: $frequency) {
                            Text("Settimanale").tag("settimanale")
                            Text("Mensile").tag("mensile")
                            Text("Annuale").tag("annuale")
                        }
                        Picker("Tipo", selection: $type) {
                            Text("Uscita").tag("uscita")
                            Text("Entrata").tag("entrata")
                        }
                        Picker("Categoria", selection: $category) {
                            ForEach(categories) { Text(LocalizedStringKey($0.name)).tag($0.name) }
                        }
                        Picker("Conto", selection: $accountID) {
                            Text("Nessuno").tag(nil as UUID?)
                            ForEach(accounts) { Text($0.name).tag(Optional($0.id)) }
                        }
                        Toggle("Fissa", isOn: $fixed)
                    }
                }
                Section {
                    Button("Salta mese") { apply(.skipMonth) }
                    Button("Termina da qui", role: .destructive) { apply(.terminate(afterThis: false)) }
                    Button("Termina dopo questa", role: .destructive) { apply(.terminate(afterThis: true)) }
                    Button("Elimina", role: .destructive) { confirmDelete = true }
                }
            }
            .scrollContentBackground(.hidden)
            .background(DS.paper)
            .tint(DS.ink)
            .navigationTitle("Ricorrenza")
            .toolbar {
                ToolbarItem(placement: .cancellationAction) { Button("Annulla") { dismiss() } }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Salva") { save() }
                        .disabled(name.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || (Decimal.parseAmount(amount) ?? 0) <= 0 || (Decimal.parseAmount(amount) ?? 0) > 1_000_000_000)
                }
            }
            .confirmationDialog("Eliminare le occorrenze selezionate?", isPresented: $confirmDelete, titleVisibility: .visible) {
                Button("Elimina", role: .destructive) { apply(.delete(editorScope)) }
                Button("Annulla", role: .cancel) { }
            }
            .recurrenceErrorAlert(status)
            .onAppear { load() }
            .onChange(of: scope) { _, _ in load() }
        }
    }

    private func load() {
        let rule = selection.rule, occurrence = selection.occurrence
        name = scope == 0 ? occurrence.name : rule.name
        amount = (scope == 0 ? occurrence.amount : rule.amount).editableString
        notes = scope == 0 ? occurrence.notes : rule.notes
        date = scope == 0 ? occurrence.date : scope == 1 ? occurrence.originalDate : rule.startDate
        frequency = rule.frequency; type = rule.type; category = rule.category
        accountID = rule.accountId; fixed = rule.isFixed
    }
    private func save() {
        guard let value = Decimal.parseAmount(amount), value > 0, value <= 1_000_000_000 else { return }
        var values = RecurringSeriesEditor.snapshot(selection.rule)
        values.name = name; values.amount = value; values.notes = notes; values.startDate = date
        values.frequency = frequency; values.type = type; values.category = category
        values.categoryIcon = categories.first { $0.name == category }?.icon ?? values.categoryIcon
        values.accountId = accountID; values.isFixed = fixed
        apply(.edit(editorScope, values))
    }
    private func apply(_ action: RecurringSeriesEditor.Action) {
        if status.perform({
            try RecurringSeriesEditor().apply(action, to: selection.rule,
                originalDate: selection.occurrence.originalDate, context: context)
        }) { dismiss() }
    }
}

/// Resolve only when the context menu is presented, never while building list rows.
struct RecurrenceContextMenu: View {
    let transaction: Transaction
    let rules: [RecurringRule]
    let onSelect: (RecurrenceSelection) -> Void
    let onDelete: () -> Void
    @State private var selection: RecurrenceSelection?

    var body: some View {
        Group {
            if let selection {
                Button("Ricorrenza") { onSelect(selection) }
            }
            Button(role: .destructive, action: onDelete) {
                Label("Elimina", systemImage: "trash")
            }
            .onAppear { selection = RecurrenceSelection.resolve(transaction, rules: rules) }
            .onDisappear { selection = nil }
        }
    }
}
