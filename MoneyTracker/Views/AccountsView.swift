import SwiftUI
import SwiftData

struct AccountsView: View {
    @Query private var accounts: [Account]
    @Environment(\.modelContext) private var context
    @Binding var showAdd: Bool
    @AppStorage("hideBalance") private var hideBalance: Bool = false
    @State private var editing: Account?           = nil
    @State private var showSettings               = false
    @State private var accountToDelete: Account?  = nil
    @State private var showArchived = false
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

    // Raggruppamento esclusivamente di presentazione, senza modificare ordine o modelli.
    private func isSavings(_ account: Account) -> Bool {
        switch account.accountType {
        case .risparmio, .investimento: return true
        default: return false
        }
    }

    var body: some View {
        NavigationStack {
            List {
                HStack {
                    Text("Conti").font(DS.Typo.screenTitle).tracking(DS.Typo.screenTitleTracking)
                    Spacer()
                    Button { showSettings = true } label: {
                        Image(systemName: "gearshape").frame(width: 44, height: 44).contentShape(Rectangle())
                    }.buttonStyle(.plain).accessibilityLabel("Impostazioni")
                }
                .foregroundStyle(DS.ink)
                .listRowBackground(DS.paper).listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 20, bottom: 12, trailing: 20))

                VStack(alignment: .leading, spacing: 4) {
                    Text("Patrimonio totale").font(DS.Typo.secondary).foregroundStyle(DS.heroSecondary)
                    Text(hideBalance ? "• • •" : totalCurrent.currencyFormatted)
                        .font(DS.Typo.heroAmountSm).tracking(DS.Typo.heroAmountSmTracking)
                        .foregroundStyle(DS.heroText).lineLimit(1).minimumScaleFactor(0.6)
                        .accessibilityIdentifier("accounts_total")
                        .accessibilityLabel(hideBalance ? String(localized: "Saldo nascosto") : totalCurrent.currencyFormatted)
                    Rectangle().fill(DS.heroDivider).frame(height: 1).padding(.top, 10)
                    HStack {
                        Text("A conti fatti").font(DS.Typo.secondary).foregroundStyle(DS.heroSecondary)
                        Spacer(minLength: 8)
                        Text(hideBalance ? "• • •" : totalFuture.currencyFormatted)
                            .font(DS.Typo.rowAmount).foregroundStyle(DS.heroPlanned)
                            .lineLimit(1).minimumScaleFactor(0.7)
                    }.padding(.top, 8)
                }
                .padding(.horizontal, 20).padding(.vertical, 18)
                .background(DS.hero, in: RoundedRectangle(cornerRadius: 24))
                .listRowBackground(DS.paper).listRowSeparator(.hidden)
                .listRowInsets(EdgeInsets(top: 0, leading: 16, bottom: 0, trailing: 16))

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
                    ForEach([false, true], id: \.self) { savings in
                        let groupAccounts = (included + excluded).filter { isSavings($0) == savings }
                        if !groupAccounts.isEmpty {
                            HStack(alignment: .firstTextBaseline) {
                                Text(savings ? "Risparmio e investimenti" : "Liquidità")
                                Spacer(minLength: 8)
                                Text(hideBalance ? "• • •" : groupAccounts.filter { !$0.isExcludedFromTotal }
                                    .reduce(Decimal(0)) { $0 + $1.currentBalance }.currencyFormatted)
                                    .monospacedDigit().fixedSize(horizontal: true, vertical: false)
                            }
                            .font(DS.Typo.secondary).fontWeight(.semibold).foregroundStyle(DS.smoke)
                            .listRowBackground(DS.paper).listRowSeparator(.hidden)
                            .listRowInsets(EdgeInsets(top: 18, leading: 20, bottom: 8, trailing: 20))
                            ForEach(Array(groupAccounts.enumerated()), id: \.element.id) { index, acc in
                                AccountRow(account: acc, hidden: hideBalance)
                                    .contentShape(Rectangle())
                                    .accessibilityIdentifier("accountRow_\(acc.name)")
                                    .onTapGesture { editing = acc }
                                    .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                                        Button(role: .destructive) {
                                            haptic(.medium)
                                            accountToDelete = acc
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                        .accessibilityIdentifier("btn_deleteAccount")
                                    }
                                    .contextMenu {
                                        Button {
                                            haptic(.soft)
                                            editing = acc
                                        } label: {
                                            Label("Modifica", systemImage: "pencil")
                                        }.accessibilityIdentifier("account_edit")
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
                                        }.accessibilityIdentifier("account_exclude")
                                        Button {
                                            acc.isArchived = true
                                            context.safeSave()
                                        } label: {
                                            Label("Archivia", systemImage: "archivebox")
                                        }.accessibilityIdentifier("account_archive")
                                        Divider()
                                        Button(role: .destructive) {
                                            accountToDelete = acc
                                        } label: {
                                            Label("Elimina", systemImage: "trash")
                                        }
                                    }
                                    .listRowBackground(
                                        UnevenRoundedRectangle(
                                            topLeadingRadius: index == 0 ? 20 : 0,
                                            bottomLeadingRadius: index == groupAccounts.count - 1 ? 20 : 0,
                                            bottomTrailingRadius: index == groupAccounts.count - 1 ? 20 : 0,
                                            topTrailingRadius: index == 0 ? 20 : 0
                                        ).fill(DS.surface).padding(.horizontal, 16)
                                    )
                                    .listRowSeparator(index == groupAccounts.count - 1 ? .hidden : .visible)
                                    .listRowSeparatorTint(DS.divider)
                                    .listRowInsets(EdgeInsets(top: 0, leading: 30, bottom: 0, trailing: 30))
                            }
                        }
                    }
                }

                if !archived.isEmpty {
                    Button { showArchived.toggle() } label: {
                        HStack {
                            Text("Archiviati")
                            Spacer()
                            Text(archived.count, format: .number).monospacedDigit()
                            Image(systemName: showArchived ? "chevron.down" : "chevron.right")
                        }
                        .font(DS.Typo.secondary).foregroundStyle(DS.smoke)
                        .padding(.horizontal, 16).frame(minHeight: 48)
                        .contentShape(Rectangle())
                        .overlay(RoundedRectangle(cornerRadius: 16)
                            .strokeBorder(DS.filterBorder, style: StrokeStyle(lineWidth: 1, dash: [5, 4])))
                    }
                    .buttonStyle(.plain).accessibilityIdentifier("accounts_archived")
                    .accessibilityValue(showArchived ? Text("Archiviati") : Text(archived.count, format: .number))
                    .listRowSeparator(.hidden).listRowBackground(DS.paper)
                    .listRowInsets(EdgeInsets(top: 10, leading: 16, bottom: 0, trailing: 16))
                    if showArchived {
                        Section {
                            ForEach(archived) { acc in
                                AccountRow(account: acc, hidden: hideBalance)
                                    .contextMenu {
                                        Button {
                                            acc.isArchived = false
                                            context.safeSave()
                                        } label: {
                                            Label("Ripristina", systemImage: "arrow.uturn.left")
                                        }.accessibilityIdentifier("account_restore")
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
                Color.clear.frame(height: 100)
                    .listRowBackground(DS.paper).listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .scrollContentBackground(.hidden)
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .refreshable { await SyncService.shared.manualRefresh(context: context) }
            .toolbar(.hidden, for: .navigationBar)
            .sheet(isPresented: $showAdd) { AddAccountView() }
            .sheet(item: $editing)        { AddAccountView(editing: $0) }
            .themedNavBar()
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
                    .accessibilityIdentifier("btn_confirmDeleteAccount")
                    Button("Annulla", role: .cancel) { accountToDelete = nil }
                }
            }
        }
    }
}

// MARK: - Account Row

struct AccountRow: View {
    let account: Account
    var hidden: Bool = false
    @AppStorage private var thresholdString: String

    init(account: Account, hidden: Bool = false) {
        self.account = account
        self.hidden = hidden
        _thresholdString = AppStorage(wrappedValue: "0", "balanceThreshold_\(account.id.uuidString)")
    }

    private var threshold: Decimal { Decimal.parseAmount(thresholdString) ?? 0 }
    private var belowThreshold: Bool { !hidden && threshold > 0 && account.currentBalance < threshold }
    private var tint: CategoryTint {
        switch account.accountType {
        case .contanti, .investimento: return .violet
        case .carta: return .amber
        case .conto: return .green
        case .risparmio: return .blue
        }
    }
    private var icon: String {
        switch account.accountType {
        case .contanti: return "banknote"
        case .carta: return "creditcard"
        case .conto: return "building.columns"
        case .risparmio: return "tray.full"
        case .investimento: return "chart.line.uptrend.xyaxis"
        }
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon).font(DS.Typo.rowName).foregroundStyle(account.isArchived ? DS.smoke : tint.foreground)
                .frame(width: 40, height: 40)
                .background(tint.background, in: RoundedRectangle(cornerRadius: 13))
                .accessibilityHidden(true)
            VStack(alignment: .leading, spacing: 2) {
                Text(account.name).font(DS.Typo.rowName).foregroundStyle(account.isArchived ? DS.smoke : DS.ink)
                if account.isExcludedFromTotal {
                    Text("Escluso dal totale").font(DS.Typo.caption).foregroundStyle(DS.smoke)
                } else if belowThreshold {
                    Text(String(format: String(localized: "Sotto la soglia di %@"), threshold.currencyFormatted))
                        .font(DS.Typo.caption).fontWeight(.semibold).foregroundStyle(account.isArchived ? DS.smoke : DS.plannedText)
                } else {
                    Text(account.accountType.localizedName).font(DS.Typo.caption).foregroundStyle(DS.smoke)
                }
            }
            Spacer(minLength: 4)
            VStack(alignment: .trailing, spacing: 2) {
                Text(hidden ? "• • •" : account.currentBalance.currencyFormatted)
                    .font(DS.Typo.rowAmount)
                    .accessibilityLabel(hidden ? String(localized: "Saldo nascosto") : account.currentBalance.currencyFormatted)
                    .foregroundStyle(account.isExcludedFromTotal || account.isArchived ? DS.smoke : DS.ink)
                    .lineLimit(1).minimumScaleFactor(0.7)
                if !hidden, abs(account.futureBalance - account.currentBalance) > 0.001 {
                    Text("→ " + account.futureBalance.currencyFormatted)
                        .font(DS.Typo.caption).foregroundStyle(account.isArchived ? DS.smoke : DS.plannedText)
                        .lineLimit(1).minimumScaleFactor(0.7)
                }
            }.layoutPriority(1)
        }
        .padding(.vertical, 11)
        .accessibilityElement(children: .contain)
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
                            .accessibilityIdentifier("tf_accountName")
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
                                .accessibilityIdentifier("tf_accountBalance")
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
                        .accessibilityIdentifier("btn_saveAccount")
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
                        .accessibilityIdentifier("btn_cancelAddAccount")
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
        balance = a.currentBalance == 0 ? "" : a.currentBalance.editableString
        excludeFromTotal = a.isExcludedFromTotal
        // Soglia esistente da UserDefaults — salvata come stringa (vedi save()), non Double,
        // per evitare qualunque conversione binaria su un valore finanziario.
        let raw = UserDefaults.standard.string(forKey: "balanceThreshold_\(a.id.uuidString)")
        let t = raw.flatMap { Decimal.parseAmount($0) } ?? 0
        alertThresholdStr = t > 0 ? t.editableString : ""
    }

    private func save() {
        let b = Decimal.parseAmount(balance) ?? 0
        let threshold = Decimal.parseAmount(alertThresholdStr) ?? 0
        if let a = editing {
            a.name                  = name
            a.type                  = type.rawValue
            a.isExcludedFromTotal   = excludeFromTotal
            if a.transactions.isEmpty {
                // Nessuno storico da preservare: il numero digitato diventa
                // direttamente l'ancora del conto, come alla creazione.
                a.initialBalance = b
            } else {
                applyBalanceAdjustment(to: a, newBalance: b)
            }
            UserDefaults.standard.set(threshold.fixedFractionString, forKey: "balanceThreshold_\(a.id.uuidString)")
        } else {
            let newAcc = Account(
                name: name, type: type, initialBalance: b,
                isExcludedFromTotal: excludeFromTotal
            )
            context.insert(newAcc)
            UserDefaults.standard.set(threshold.fixedFractionString, forKey: "balanceThreshold_\(newAcc.id.uuidString)")
            if !excludeFromTotal {
                let existing = homeAccountOrderedShown.isEmpty ? [] : homeAccountOrderedShown.split(separator: ",").map { String($0) }
                homeAccountOrderedShown = ([newAcc.id.uuidString] + existing).joined(separator: ",")
            }
        }
        context.safeSave()
        dismiss()
    }

    /// Il saldo di un conto è `initialBalance + somma di tutte le transazioni storiche`
    /// (vedi AccountBalanceCache): toccare `initialBalance` su un conto che ha già
    /// transazioni sposterebbe il risultato senza mai farlo coincidere col valore
    /// digitato. Per "aggiornare" il saldo attuale senza intaccare lo storico si
    /// registra invece una transazione di rettifica per la sola differenza, datata
    /// oggi — così il conto riparte esattamente dal numero inserito.
    private func applyBalanceAdjustment(to account: Account, newBalance: Decimal) {
        let delta = newBalance - account.currentBalance
        guard delta != 0 else { return }

        let catName = "Rettifica saldo"
        let catIcon = (try? context.fetch(
            FetchDescriptor<Category>(predicate: #Predicate { $0.name == catName })
        ))?.first?.icon ?? "arrow.triangle.2.circlepath"

        context.insert(Transaction(
            name:      catName,
            amount:    abs(delta),
            type:      delta > 0 ? .entrata : .uscita,
            category:  catName,
            categoryIcon: catIcon,
            date:      Date(),
            isDone:    true,
            account:   account
        ))
    }
}
