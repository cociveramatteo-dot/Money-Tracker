import SwiftUI
import SwiftData

struct AddTransferView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query private var accounts: [Account]
    @Query private var allTransactions: [Transaction]

    /// Una delle due gambe del trasferimento da modificare (indifferentemente
    /// quella .uscita o quella .entrata: la gamba gemella viene ritrovata via
    /// `transferGroupId`). Nil = crea un nuovo trasferimento.
    var editing: Transaction? = nil

    @State private var amount:      String   = ""
    @State private var fromAccount: Account? = nil
    @State private var toAccount:   Account? = nil
    @State private var date:        Date     = Date()
    @State private var notes:       String   = ""
    @State private var isDone:      Bool     = true

    @FocusState private var amountFocused: Bool

    private var active: [Account] { accounts.filter { !$0.isArchived } }

    private var canSave: Bool {
        let v = Decimal.parseAmount(amount) ?? 0
        return v > 0 && v <= 1_000_000_000 && fromAccount != nil && toAccount != nil
            && fromAccount?.id != toAccount?.id
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    Text(editing == nil ? "Trasferimento" : "Modifica trasferimento")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.ink)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Importo")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(Double.currencySymbol)
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: $amount)
                                .font(.system(size: 56, weight: .black))
                                .foregroundStyle(DS.ink)
                                .keyboardType(.decimalPad)
                                .focused($amountFocused)
                                .submitLabel(.done)
                                .onSubmit { amountFocused = false }
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Da")
                        accountPicker(selected: $fromAccount, exclude: toAccount)
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "A")
                        accountPicker(selected: $toAccount, exclude: fromAccount)
                    }

                    if let from = fromAccount, let to = toAccount {
                        HStack(spacing: DS.Space.m) {
                            Spacer()
                            Text(from.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DS.ink)
                            Image(systemName: "arrow.right")
                                .font(.system(size: 13))
                                .foregroundStyle(DS.smoke)
                            Text(to.name)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DS.ink)
                            Spacer()
                        }
                        .padding(.vertical, DS.Space.m)
                        .background(DS.fog)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Opzioni")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Già effettuato")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Togli la spunta se il trasferimento è pianificato")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $isDone)
                                .tint(DS.ink)
                                .labelsHidden()
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
                        TextField("Note (opzionale)", text: $notes, axis: .vertical)
                            .font(.system(size: 15, weight: .light))
                            .foregroundStyle(DS.ink)
                            .lineLimit(3, reservesSpace: false)
                        ThinDivider()
                    }

                    PrimaryButton(title: editing == nil ? (isDone ? "Trasferisci" : "Pianifica") : "Aggiorna") { save() }
                        .disabled(!canSave)
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

    private func accountPicker(selected: Binding<Account?>, exclude: Account?) -> some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: DS.Space.l) {
                let available = active.filter { $0.id != exclude?.id }
                if available.isEmpty {
                    Text("Nessun altro conto").font(.system(size: 13)).foregroundStyle(DS.smoke)
                } else {
                    ForEach(available) { acc in
                        Button {
                            selected.wrappedValue = acc
                        } label: {
                            VStack(spacing: 5) {
                                Text(acc.name)
                                    .font(.system(size: 13,
                                          weight: selected.wrappedValue?.id == acc.id ? .semibold : .regular))
                                    .foregroundStyle(selected.wrappedValue?.id == acc.id ? DS.ink : DS.smoke)
                                Rectangle()
                                    .fill(selected.wrappedValue?.id == acc.id ? DS.ink : Color.clear)
                                    .frame(height: 1)
                            }
                        }
                    }
                }
            }
            .padding(.vertical, DS.Space.xs)
        }
    }

    /// Trova la gamba gemella di `t` (stesso `transferGroupId`, id diverso).
    private func pairedLeg(of t: Transaction) -> Transaction? {
        allTransactions.first { $0.isTransfer && $0.id != t.id && $0.transferGroupId == t.transferGroupId }
    }

    private func load() {
        guard let t = editing else {
            amount    = ""
            notes     = ""
            date      = Date()
            isDone    = true
            if active.count >= 2 { fromAccount = active[0]; toAccount = active[1] }
            else if active.count == 1 { fromAccount = active[0]; toAccount = nil }
            else { fromAccount = nil; toAccount = nil }
            return
        }
        let pair = pairedLeg(of: t)
        amount      = t.amount.editableString
        date        = t.date
        notes       = t.notes
        isDone      = t.isDone
        // `t` può essere indifferentemente la gamba .uscita o .entrata: si
        // ricostruisce "Da"/"A" in base al ruolo di ciascuna gamba, non in base
        // a quale delle due è stata toccata.
        fromAccount = (t.transactionType == .uscita  ? t : pair)?.account
        toAccount   = (t.transactionType == .entrata ? t : pair)?.account
    }

    private func save() {
        guard let from = fromAccount, let to = toAccount else { return }
        let amt = Decimal.parseAmount(amount) ?? 0
        guard amt > 0 else { return }

        if let t = editing {
            let pair = pairedLeg(of: t)
            let uscitaLeg  = t.transactionType == .uscita  ? t : pair
            let entrataLeg = t.transactionType == .entrata ? t : pair

            uscitaLeg?.name    = "Trasferimento → \(to.name)"
            uscitaLeg?.amount  = amt
            uscitaLeg?.date    = date
            uscitaLeg?.notes   = notes
            uscitaLeg?.isDone  = isDone
            uscitaLeg?.account = from

            entrataLeg?.name    = "Trasferimento ← \(from.name)"
            entrataLeg?.amount  = amt
            entrataLeg?.date    = date
            entrataLeg?.notes   = notes
            entrataLeg?.isDone  = isDone
            entrataLeg?.account = to
        } else {
            let groupId = UUID().uuidString

            context.insert(Transaction(
                name:            "Trasferimento → \(to.name)",
                amount:          amt,
                type:            .uscita,
                category:        "Giroconto",
                categoryIcon:    "arrow.left.arrow.right",
                date:            date,
                isDone:          isDone,
                isFixed:         false,
                isTransfer:      true,
                transferGroupId: groupId,
                notes:           notes,
                account:         from
            ))

            context.insert(Transaction(
                name:            "Trasferimento ← \(from.name)",
                amount:          amt,
                type:            .entrata,
                category:        "Giroconto",
                categoryIcon:    "arrow.left.arrow.right",
                date:            date,
                isDone:          isDone,
                isFixed:         false,
                isTransfer:      true,
                transferGroupId: groupId,
                notes:           notes,
                account:         to
            ))
        }

        context.safeSave()
        dismiss()
    }
}
