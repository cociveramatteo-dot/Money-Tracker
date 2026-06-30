import SwiftUI
import SwiftData

// MARK: - Budget Row

struct BudgetRow: View {
    let budget: Budget
    let spentAmount: Double

    private var pct:       Double { guard budget.monthlyLimit > 0 else { return 0 }; return min(spentAmount / budget.monthlyLimit, 1.0) }
    private var remaining: Double { budget.monthlyLimit - spentAmount }
    private var over:      Bool   { spentAmount > budget.monthlyLimit }

    var body: some View {
        VStack(alignment: .leading, spacing: DS.Space.m) {
            HStack(alignment: .firstTextBaseline) {
                Image(systemName: budget.categoryIcon.isEmpty ? "circle.dotted" : budget.categoryIcon)
                    .font(.system(size: 13))
                    .foregroundStyle(DS.smoke)
                VStack(alignment: .leading, spacing: 2) {
                    let cats = budget.category == "Tutti"
                        ? []
                        : budget.category.split(separator: ",").map(String.init)
                    let displayLabel: String = {
                        if cats.isEmpty { return budget.account?.name ?? NSLocalizedString("Tutti", comment: "") }
                        return cats.map { NSLocalizedString($0, comment: "") }.joined(separator: ", ")
                    }()
                    Text(displayLabel)
                        .font(.system(size: 15, weight: .medium))
                        .foregroundStyle(DS.ink)
                    if !cats.isEmpty, let acc = budget.account {
                        Text(acc.name)
                            .font(.system(size: 11))
                            .foregroundStyle(DS.smoke)
                    }
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(spentAmount.currencyFormatted + " / " + budget.monthlyLimit.currencyFormatted)
                        .font(.system(size: 13))
                        .foregroundStyle(DS.smoke)
                    Text(over
                         ? NSLocalizedString("Sforato di", comment: "") + " " + abs(remaining).currencyFormatted
                         : remaining.currencyFormatted + " " + NSLocalizedString("rimasti", comment: ""))
                        .font(.system(size: 11))
                        .foregroundStyle(over ? DS.ink : DS.smoke)
                }
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DS.fog).frame(height: 2)
                    Rectangle()
                        .fill(over ? DS.ink : DS.smoke)
                        .frame(width: geo.size.width * pct, height: 2)
                        .animation(.spring(response: 0.5, dampingFraction: 0.8), value: pct)
                }
            }
            .frame(height: 2)
        }
        .padding(.vertical, DS.Space.l)
        .accessibilityElement(children: .combine)
        .accessibilityLabel({
            let cats = budget.category == "Tutti"
                ? []
                : budget.category.split(separator: ",").map(String.init)
            let label: String = {
                if cats.isEmpty { return budget.account?.name ?? NSLocalizedString("Tutti i conti", comment: "") }
                return cats.map { NSLocalizedString($0, comment: "") }.joined(separator: ", ")
            }()
            let pctStr  = "\(Int(pct * 100))%"
            let statusStr = over
                ? "sforato di \(abs(remaining).currencyFormatted)"
                : "\(remaining.currencyFormatted) rimanenti"
            return "Budget \(label), \(spentAmount.currencyFormatted) su \(budget.monthlyLimit.currencyFormatted), \(pctStr), \(statusStr)"
        }())
    }
}

// MARK: - Add Budget

struct AddBudgetView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Category.sortOrder) private var categories: [Category]
    @Query private var accounts: [Account]

    let month: Date

    /// Nomi delle categorie selezionate (vuoto = budget globale sul conto)
    @State private var selectedCatNames: Set<String> = []
    @State private var limit:            String  = ""
    @State private var selectedAccount:  Account? = nil  // nil = tutti i conti
    /// Icona scelta manualmente (nil = automatica dalla prima categoria)
    @State private var chosenIcon: String? = nil

    private var activeAccounts: [Account] { accounts.filter { !$0.isArchived } }

    /// Almeno una categoria OPPURE un conto deve essere selezionato
    private var canSave: Bool {
        let l = Double(limit.replacingOccurrences(of: ",", with: ".")) ?? 0
        return l > 0 && (!selectedCatNames.isEmpty || selectedAccount != nil)
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    Text("Nuovo budget")
                        .font(.system(size: 28, weight: .semibold))
                        .foregroundStyle(DS.ink)

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Categoria (opzionale)")
                        Text("Lascia vuoto per un budget globale sul conto.")
                            .font(.system(size: 11))
                            .foregroundStyle(DS.smoke)

                        let cols = [GridItem(.flexible()), GridItem(.flexible())]
                        LazyVGrid(columns: cols, spacing: DS.Space.s) {
                            ForEach(categories) { cat in
                                let sel = selectedCatNames.contains(cat.name)
                                Button {
                                    if sel {
                                        selectedCatNames.remove(cat.name)
                                        if chosenIcon == cat.icon { chosenIcon = nil }
                                    } else {
                                        selectedCatNames.insert(cat.name)
                                    }
                                } label: {
                                    HStack(spacing: DS.Space.s) {
                                        Image(systemName: cat.icon)
                                            .font(.system(size: 12))
                                        Text(LocalizedStringKey(cat.name))
                                            .font(.system(size: 13, weight: .medium))
                                            .lineLimit(1)
                                    }
                                    .foregroundStyle(sel ? DS.paper : DS.smoke)
                                    .frame(maxWidth: .infinity)
                                    .padding(.vertical, DS.Space.s)
                                    .background(sel ? DS.ink : DS.fog)
                                    .clipShape(RoundedRectangle(cornerRadius: 8))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }

                    if selectedCatNames.count > 1 {
                        let selCats = categories.filter { selectedCatNames.contains($0.name) }
                        VStack(alignment: .leading, spacing: DS.Space.m) {
                            SectionLabel(text: "Icona budget")
                            HStack(spacing: DS.Space.m) {
                                ForEach(selCats) { cat in
                                    let isChosen = chosenIcon == cat.icon
                                    Button {
                                        chosenIcon = cat.icon
                                    } label: {
                                        ZStack {
                                            Circle()
                                                .fill(isChosen ? DS.ink : DS.fog)
                                                .frame(width: 44, height: 44)
                                            Image(systemName: cat.icon)
                                                .font(.system(size: 18))
                                                .foregroundStyle(isChosen ? DS.paper : DS.smoke)
                                        }
                                    }
                                    .buttonStyle(.plain)
                                }
                            }
                        }
                    }

                    if !activeAccounts.isEmpty {
                        VStack(alignment: .leading, spacing: DS.Space.m) {
                            SectionLabel(text: "Conto (opzionale)")
                            Text("Lascia vuoto per applicarlo a tutti i conti.")
                                .font(.system(size: 11))
                                .foregroundStyle(DS.smoke)
                            ScrollView(.horizontal, showsIndicators: false) {
                                HStack(spacing: DS.Space.l) {
                                    Button { selectedAccount = nil } label: {
                                        VStack(spacing: 5) {
                                            Text("Tutti")
                                                .font(.system(size: 13,
                                                      weight: selectedAccount == nil ? .semibold : .regular))
                                                .foregroundStyle(selectedAccount == nil ? DS.ink : DS.smoke)
                                            Rectangle()
                                                .fill(selectedAccount == nil ? DS.ink : Color.clear)
                                                .frame(height: 1)
                                        }
                                    }
                                    ForEach(activeAccounts) { acc in
                                        Button { selectedAccount = acc } label: {
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
                                    }
                                }
                            }
                        }
                    }

                    VStack(alignment: .leading, spacing: DS.Space.m) {
                        SectionLabel(text: "Limite mensile")
                        HStack(alignment: .lastTextBaseline, spacing: 4) {
                            Text(Double.currencySymbol)
                                .font(.system(size: 28, weight: .ultraLight))
                                .foregroundStyle(DS.smoke)
                            TextField("0", text: $limit)
                                .font(.system(size: 56, weight: .black))
                                .foregroundStyle(DS.ink)
                                .keyboardType(.decimalPad)
                        }
                        ThinDivider()
                    }

                    if !canSave && !(limit.isEmpty) {
                        Text("Seleziona almeno una categoria o un conto.")
                            .font(.system(size: 12))
                            .foregroundStyle(DS.smoke)
                    }

                    PrimaryButton(title: "Salva") { save() }
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
        }
    }

    private func save() {
        let raw = limit.replacingOccurrences(of: ",", with: ".")
        guard let l = Double(raw), l > 0 else { return }
        let cal = Calendar.current
        let m = cal.component(.month, from: month)
        let y = cal.component(.year, from: month)

        let sortedNames = Array(selectedCatNames).sorted()
        let catString  = sortedNames.isEmpty ? "Tutti" : sortedNames.joined(separator: ",")
        let resolvedIcon: String = {
            if let chosen = chosenIcon, !chosen.isEmpty { return chosen }
            guard let first = sortedNames.first else { return "building.columns.fill" }
            return categories.first { $0.name == first }?.icon ?? DS.categoryIcon(for: first)
        }()
        let budget = Budget(
            category:     catString,
            categoryIcon: resolvedIcon,
            monthlyLimit: l, month: m, year: y,
            account:      selectedAccount
        )
        context.insert(budget)
        context.safeSave()
        dismiss()
    }
}

// MARK: - Budget History Sheet

struct BudgetHistorySheet: View {
    let budgets: [Budget]
    let transactions: [Transaction]

    private let months: [Date] = {
        let cal = Calendar.current
        return (0..<6).reversed().compactMap { offset in
            cal.date(byAdding: .month, value: -offset, to: Date())
        }
    }()

    private func budgetsFor(_ month: Date) -> [Budget] {
        let cal = Calendar.current
        let m = cal.component(.month, from: month)
        let y = cal.component(.year, from: month)
        return budgets.filter { $0.month == m && $0.year == y }
    }

    private var outflowsByMonth: [Date: [Transaction]] {
        let cal = Calendar.current
        let window: Set<Date> = Set(months.compactMap { cal.dateInterval(of: .month, for: $0)?.start })
        var dict: [Date: [Transaction]] = [:]
        for t in transactions where t.isDone && t.transactionType == .uscita {
            let key = cal.dateInterval(of: .month, for: t.date)?.start ?? t.date
            guard window.contains(key) else { continue }
            dict[key, default: []].append(t)
        }
        return dict
    }

    private func spent(
        in month: Date,
        for budget: Budget,
        precomputed: [Date: [Transaction]]
    ) -> Double {
        let key      = Calendar.current.dateInterval(of: .month, for: month)?.start ?? month
        let outflows = precomputed[key] ?? []
        let cats: Set<String> = budget.category == "Tutti"
            ? []
            : Set(budget.category.split(separator: ",").map(String.init))
        return outflows.filter {
            (cats.isEmpty || cats.contains($0.category))
            && (budget.account == nil || $0.account?.id == budget.account?.id)
        }.reduce(0.0) { $0 + $1.amount }
    }

    var body: some View {
        // Calcola outflowsByMonth una sola volta per tutto il body.
        // In precedenza spent(in:for:) accedeva outflowsByMonth come computed var,
        // riscansionando transactions ad ogni chiamata → O(mesi × budget × transazioni).
        let precomputed = outflowsByMonth
        return NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {
                    ForEach(months, id: \.self) { month in
                        let monthBudgets = budgetsFor(month)

                        VStack(alignment: .leading, spacing: 0) {
                                Text(month.monthYearFormatted)
                                .font(.system(size: 13, weight: .semibold))
                                .foregroundStyle(DS.ink)
                                .padding(.horizontal, DS.Layout.margin)
                                .padding(.top, DS.Space.xl)
                                .padding(.bottom, DS.Space.m)

                            if monthBudgets.isEmpty {
                                Text("Nessun budget")
                                    .font(.system(size: 13))
                                    .foregroundStyle(DS.smoke)
                                    .padding(.horizontal, DS.Layout.margin)
                                    .padding(.bottom, DS.Space.m)
                            } else {
                                ForEach(monthBudgets) { budget in
                                    let s     = spent(in: month, for: budget, precomputed: precomputed)
                                    let pct   = budget.monthlyLimit > 0 ? min(s / budget.monthlyLimit, 1.0) : 0
                                    let over  = s > budget.monthlyLimit

                                    let catLabel: String = {
                                        if budget.category == "Tutti" {
                                            return budget.account?.name ?? NSLocalizedString("Tutti", comment: "")
                                        }
                                        return budget.category.split(separator: ",")
                                            .map { NSLocalizedString(String($0), comment: "") }
                                            .joined(separator: " + ")
                                    }()

                                    VStack(alignment: .leading, spacing: DS.Space.s) {
                                        HStack(spacing: DS.Space.s) {
                                            Image(systemName: budget.categoryIcon.isEmpty ? "circle.dotted" : budget.categoryIcon)
                                                .font(.system(size: 12))
                                                .foregroundStyle(DS.smoke)
                                                .frame(width: 16)
                                            Text(catLabel)
                                                .font(.system(size: 14))
                                                .foregroundStyle(DS.ink)
                                            Spacer()
                                            Text(s.currencyFormatted + " / " + budget.monthlyLimit.currencyFormatted)
                                                .font(.system(size: 12))
                                                .foregroundStyle(DS.smoke)
                                            Text(String(format: "%.0f%%", pct * 100))
                                                .font(.system(size: 12, weight: .semibold))
                                                .foregroundStyle(over ? DS.ink : DS.smoke)
                                                .frame(width: 36, alignment: .trailing)
                                        }
                                        GeometryReader { geo in
                                            ZStack(alignment: .leading) {
                                                Rectangle().fill(DS.fog).frame(height: 2)
                                                Rectangle()
                                                    .fill(over ? DS.ink : DS.smoke)
                                                    .frame(width: geo.size.width * pct, height: 2)
                                            }
                                        }
                                        .frame(height: 2)
                                    }
                                    .padding(.horizontal, DS.Layout.margin)
                                    .padding(.vertical, DS.Space.m)

                                    ThinDivider()
                                        .padding(.leading, DS.Layout.margin + 16 + DS.Space.s)
                                }
                            }
                        }

                        ThinDivider()
                    }
                    Spacer(minLength: 60)
                }
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .navigationTitle("Storico Budget")
            .navigationBarTitleDisplayMode(.large)
        }
    }
}
