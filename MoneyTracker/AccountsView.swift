import SwiftUI
import SwiftData

struct AccountsView: View {
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var context
    @Binding var showAdd: Bool
    @State private var editing: Account?           = nil
    @State private var showSettings               = false
    @State private var accountToDelete: Account?  = nil
    private var partitioned: (active: [Account], archived: [Account]) {
        var active:   [Account] = []
        var archived: [Account] = []
        for acc in accounts {
            if acc.isArchived { archived.append(acc) } else { active.append(acc) }
        }
        return (active, archived)
    }

    private var active:   [Account] { partitioned.active }
    private var archived: [Account] { partitioned.archived }

    private var included: [Account] { active.filter { !$0.isExcludedFromTotal } }
    private var excluded: [Account] { active.filter {  $0.isExcludedFromTotal } }

    private var totalCurrent: Decimal { included.reduce(0) { $0 + $1.currentBalance } }
    private var totalFuture:  Decimal { included.reduce(0) { $0 + $1.futureBalance } }

    var body: some View {
        NavigationStack {
            List {
                VStack(alignment: .leading, spacing: DS.Space.s) {
                    SectionLabel(text: "Totale attuale")
                    HeroAmount(amount: totalCurrent)
                    HStack(spacing: DS.Space.xs) {
                        Text("A conti fatti:")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                        Text(totalFuture.currencyFormatted)
                            .font(.system(size: 13, weight: .medium))
                            .foregroundStyle(DS.ink)
                    }
                    .padding(.top, 2)
                }
                .padding(.top, DS.Space.xl)
                .padding(.bottom, DS.Space.m)
                .listRowBackground(DS.paper)
                .listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: DS.Layout.margin, bottom: 0, trailing: DS.Layout.margin))

                if active.isEmpty {
                    EmptyStateView(
                        icon: "creditcard",
                        title: "Nessun conto",
                        subtitle: "Aggiungi un conto per iniziare a tracciare le tue finanze.",
                        cta: "Aggiungi conto",
                        ctaAction: { showAdd = true }
                    )
                    .listRowBackground(DS.paper)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(top: DS.Space.xl, leading: DS.Layout.margin, bottom: 0, trailing: DS.Layout.margin))
                } else {
                    ForEach(included + excluded) { acc in
                        AccountRow(account: acc)
                            .contentShape(Rectangle())
                            .onTapGesture { editing = acc }
                            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                Button(role: .destructive) {
                                    haptic(.medium)
                                    accountToDelete = acc
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                            .contextMenu {
                                Button {
                                    haptic(.soft)
                                    editing = acc
                                } label: {
                                    Label("Modifica", systemImage: "pencil")
                                }
                                Button {
                                    acc.isExcludedFromTotal.toggle()
                                    context.safeSave()
                                } label: {
                                    Label(
                                        acc.isExcludedFromTotal
                                            ? "Includi nel totale"
                                            : "Escludi dal totale",
                                        systemImage: acc.isExcludedFromTotal
                                            ? "eye" : "eye.slash"
                                    )
                                }
                                Button {
                                    acc.isArchived = true
                                    context.safeSave()
                                } label: {
                                    Label("Archivia", systemImage: "archivebox")
                                }
                                Divider()
                                Button(role: .destructive) {
                                    accountToDelete = acc
                                } label: {
                                    Label("Elimina", systemImage: "trash")
                                }
                            }
                            .listRowBackground(DS.paper)
                            .listRowSeparatorTint(DS.fog)
                            .listRowInsets(EdgeInsets(top: 0, leading: DS.Layout.margin, bottom: 0, trailing: DS.Layout.margin))
                    }
                }

                if !archived.isEmpty {
                    Section {
                        ForEach(archived) { acc in
                            AccountRow(account: acc)
                                .opacity(0.35)
                                .contextMenu {
                                    Button {
                                        acc.isArchived = false
                                        context.safeSave()
                                    } label: {
                                        Label("Ripristina", systemImage: "arrow.uturn.left")
                                    }
                                    Divider()
                                    Button(role: .destructive) {
                                        context.delete(acc)
                                        context.safeSave()
                                    } label: {
                                        Label("Elimina definitivamente", systemImage: "trash")
                                    }
                                }
                                .listRowBackground(DS.paper)
                                .listRowSeparatorTint(DS.fog)
                                .listRowInsets(EdgeInsets(top: 0, leading: DS.Layout.margin, bottom: 0, trailing: DS.Layout.margin))
                        }
                    } header: {
                        SectionLabel(text: "Archiviati")
                            .padding(.top, DS.Space.xl)
                            .textCase(nil)
                    }
                    .listRowBackground(DS.paper)
                }
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .tourAnchor("accountList")
            .navigationTitle("Conti")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.ink)
                    }
                }
            }
            .sheet(isPresented: $showAdd) { AddAccountView() }
            .sheet(item: $editing)        { AddAccountView(editing: $0) }
            .themePickerButton()
            .sheet(isPresented: $showSettings) { SettingsView() }
            .alert(
                accountToDelete.map { String(format: NSLocalizedString("Eliminare \"%@\"?", comment: "Delete account alert title"), $0.name) } ?? "",
                isPresented: Binding(
                    get: { accountToDelete != nil },
                    set: { if !$0 { accountToDelete = nil } }
                )
            ) {
                if let acc = accountToDelete {
                    let txCount = acc.transactions.count
                    Button("Elimina\(txCount > 0 ? " (\(txCount) moviment\(txCount == 1 ? "o" : "i"))" : "")", role: .destructive) {
                        context.delete(acc)
                        context.safeSave()
                        accountToDelete = nil
                    }
                    Button("Annulla", role: .cancel) { accountToDelete = nil }
                }
            }
        }
    }
}

// MARK: - Account Row

struct AccountRow: View {
    let account: Account

    var body: some View {
        HStack(alignment: .top) {
            VStack(alignment: .leading, spacing: DS.Space.xs) {
                HStack(spacing: DS.Space.xs) {
                    Text(account.name)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.ink)
                    if account.isExcludedFromTotal {
                        Text("escluso")
                            .font(.system(size: 10))
                            .foregroundStyle(DS.smoke)
                            .padding(.horizontal, 5)
                            .padding(.vertical, 2)
                            .background(DS.fog)
                            .clipShape(Capsule())
                    }
                }
                Text(account.accountType.localizedName)
                    .font(.system(size: 12))
                    .foregroundStyle(DS.smoke)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: DS.Space.xs) {
                Text(account.currentBalance.currencyFormatted)
                    .font(.system(size: 17, weight: .semibold))
                    .foregroundStyle(DS.ink)
                if abs(account.futureBalance - account.currentBalance) > 0.001 {
                    HStack(spacing: 3) {
                        Text("→")
                        Text(account.futureBalance.currencyFormatted)
                            .fontWeight(.medium)
                    }
                    .font(.system(size: 11))
                    .foregroundStyle(DS.smoke)
                }
            }
        }
        .padding(.vertical, DS.Layout.rowVPad)
        .accessibilityElement(children: .combine)
        .accessibilityLabel({
            let excluded = account.isExcludedFromTotal
                ? ", \(String(localized: "escluso dal totale"))"
                : ""
            return "\(account.name), \(account.accountType.localizedName), \(String(localized: "saldo")) \(account.currentBalance.currencyFormatted)\(excluded)"
        }())
    }
}

// MARK: - Add / Edit Account

struct AddAccountView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss

    var editing: Account? = nil

    @AppStorage("homeAccountOrderedShown") private var homeAccountOrderedShown: String = ""

    @State private var name:               String     = ""
    @State private var type:               AccountType = .conto
    @State private var balance:            String     = ""
    @State private var excludeFromTotal:   Bool       = false
    @State private var alertThresholdStr:  String     = ""   // soglia saldo basso (vuota = disabilitata)

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    Text(editing == nil ? "Nuovo conto" : "Modifica conto")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.ink)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Tipo")
                        VStack(spacing: 0) {
                            ForEach(AccountType.allCases, id: \.self) { t in
                                Button { type = t } label: {
                                    HStack {
                                        Text(t.localizedName)
                                            .font(.system(size: 15,
                                                  weight: type == t ? .semibold : .regular))
                                            .foregroundStyle(DS.ink)
                                        Spacer()
                                        if type == t {
                                            Image(systemName: "checkmark")
                                                .font(.system(size: 12))
                                                .foregroundStyle(DS.ink)
                                        }
                                    }
                                    .padding(.vertical, DS.Layout.rowVPad)
                                }
                                ThinDivider()
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Nome")
                        TextField("es. Carta Unicredit, Portafoglio...", text: $name)
                            .font(.system(size: 22, weight: .light))
                            .foregroundStyle(DS.ink)
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        SectionLabel(text: "Saldo attuale")
                        Text("Inserisci il saldo che hai adesso su questo conto.")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.smoke)
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(Double.currencySymbol)
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: $balance)
                                .font(.system(size: 56, weight: .black))
                                .foregroundStyle(DS.ink)
                                .keyboardType(.decimalPad)
                        }
                        ThinDivider()
                    }

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Opzioni")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Escludi dal totale")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Non viene contato nel saldo totale dei conti")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $excludeFromTotal)
                                .tint(DS.ink)
                                .labelsHidden()
                        }
                        ThinDivider()

                        VStack(alignment: .leading, spacing: DS.Space.s) {
                            HStack {
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Avviso saldo basso")
                                        .font(.system(size: 15))
                                        .foregroundStyle(DS.ink)
                                    Text("Ricevi una notifica quando il saldo scende sotto questa soglia")
                                        .font(.system(size: 11))
                                        .foregroundStyle(DS.smoke)
                                }
                                Spacer()
                                HStack(spacing: 2) {
                                    Text(Double.currencySymbol)
                                        .font(.system(size: 15))
                                        .foregroundStyle(DS.smoke)
                                    TextField("0", text: $alertThresholdStr)
                                        .font(.system(size: 15, weight: .medium))
                                        .foregroundStyle(DS.ink)
                                        .keyboardType(.decimalPad)
                                        .multilineTextAlignment(.trailing)
                                        .frame(width: 80)
                                }
                            }
                        }
                        ThinDivider()
                    }

                    PrimaryButton(title: editing == nil ? "Aggiungi" : "Salva") { save() }
                        .disabled(name.isEmpty)
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
        guard let a = editing else {
            name             = ""
            type             = .conto
            balance          = ""
            excludeFromTotal = false
            alertThresholdStr = ""
            return
        }
        name             = a.name
        type             = a.accountType
        balance = a.initialBalance == 0 ? "" : a.initialBalance.editableString
        excludeFromTotal = a.isExcludedFromTotal
        // Load existing threshold from UserDefaults
        let t = UserDefaults.standard.double(forKey: "balanceThreshold_\(a.id.uuidString)")
        alertThresholdStr = t > 0 ? (t.truncatingRemainder(dividingBy: 1) == 0 ? String(Int(t)) : String(format: "%.2f", t)) : ""
    }

    private func save() {
        let b = Decimal.parseAmount(balance) ?? 0
        let threshold = Double(alertThresholdStr.replacingOccurrences(of: ",", with: ".")) ?? 0
        if let a = editing {
            a.name                  = name
            a.type                  = type.rawValue
            a.initialBalance        = b
            a.isExcludedFromTotal   = excludeFromTotal
            UserDefaults.standard.set(threshold, forKey: "balanceThreshold_\(a.id.uuidString)")
        } else {
            let newAcc = Account(
                name: name, type: type, initialBalance: b,
                isExcludedFromTotal: excludeFromTotal
            )
            context.insert(newAcc)
            UserDefaults.standard.set(threshold, forKey: "balanceThreshold_\(newAcc.id.uuidString)")
            if !excludeFromTotal {
                let existing = homeAccountOrderedShown.isEmpty ? [] : homeAccountOrderedShown.split(separator: ",").map { String($0) }
                homeAccountOrderedShown = ([newAcc.id.uuidString] + existing).joined(separator: ",")
            }
        }
        context.safeSave()
        dismiss()
    }
}
