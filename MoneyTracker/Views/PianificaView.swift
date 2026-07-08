import SwiftUI
import SwiftData

// MARK: - PianificaView
//
// Tab unificato "Pianifica" che combina Budget e Obiettivi in un unico
// NavigationStack con switcher orizzontale. Liberando uno slot nel TabView
// si ottengono esattamente 5 tab visibili: Home · Movimenti · Statistiche
// · Pianifica · Conti — nessun tab finisce nel menu "Altro".

struct PianificaView: View {

    @Query private var budgets:      [Budget]
    @Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]
    @Query private var goals:        [Goal]

    @Environment(\.modelContext) private var context

    @Binding var showAddBudget: Bool
    @Binding var showAddGoal:   Bool
    /// 0 = Budget  |  1 = Obiettivi — condiviso con ContentView per il FAB
    @Binding var segment:       Int

    @State private var selectedMonth = Date()
    @State private var showSettings  = false
    @State private var showHistory   = false
    @State private var editingGoal: Goal? = nil

    // MARK: - Budget computed

    private var currentBudgets: [Budget] {
        let cal = Calendar.current
        let m = cal.component(.month, from: selectedMonth)
        let y = cal.component(.year, from: selectedMonth)
        return budgets.filter { $0.month == m && $0.year == y }
    }

    // !isTransfer: coerente con NotificationManager.checkBudgets — uno spostamento tra i
    // propri conti non deve consumare il budget di spesa di una categoria.
    private var monthOutflows: [Transaction] {
        transactions.filter {
            $0.transactionType == .uscita
            && $0.isDone
            && !$0.isTransfer
            && $0.date.isSameMonth(as: selectedMonth)
        }
    }

    private func spent(for budget: Budget) -> Decimal {
        let cats: Set<String> = budget.category == "Tutti"
            ? []
            : Set(budget.category.split(separator: ",").map(String.init))
        return monthOutflows.filter {
            (cats.isEmpty || cats.contains($0.category))
            && (budget.account == nil || $0.account?.id == budget.account?.id)
        }.reduce(Decimal(0)) { $0 + $1.amount }
    }

    /// Calcola la mappa speso-per-budget in un'unica passata O(B×T).
    /// Non chiamare direttamente in body: usare `let map = spentMap` per evitare
    /// computazioni ripetute all'interno dello stesso render cycle.
    private var spentMap: [PersistentIdentifier: Decimal] {
        Dictionary(uniqueKeysWithValues: currentBudgets.map { ($0.id, spent(for: $0)) })
    }

    // Ritorna un Double: alimenta solo la barra di progresso complessiva.
    private func overallBudgetPct(map: [PersistentIdentifier: Decimal]) -> Double {
        let total = currentBudgets.reduce(Decimal(0)) { $0 + $1.monthlyLimit }
        let used  = map.values.reduce(Decimal(0), +)
        guard total > 0 else { return 0 }
        return min((used / total).asDouble, 1.0)
    }

    // MARK: - Goals computed

    private var overallGoalProgress: Double {
        guard !goals.isEmpty else { return 0 }
        let total   = goals.reduce(Decimal(0)) { $0 + $1.targetAmount }
        let current = goals.reduce(Decimal(0)) { $0 + $1.currentAmount }
        guard total > 0 else { return 0 }
        return min((current / total).asDouble, 1.0)
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 0) {

                    HStack(spacing: 0) {
                        segButton("Budget",    tag: 0)
                        segButton("Obiettivi", tag: 1)
                    }
                    .padding(.horizontal, DS.Layout.margin)
                    .padding(.top, DS.Space.l)

                    if segment == 0 {
                        budgetContent
                            .tourAnchor("budgetList")
                    } else {
                        goalsContent
                            .tourAnchor("goalsList")
                    }

                    Spacer(minLength: 100)
                }
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .refreshable { await SyncService.shared.manualRefresh(context: context) }
            .navigationTitle(segment == 0 ? "Budget" : "Obiettivi")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar { toolbarContent }
            .sheet(isPresented: $showAddBudget) { AddBudgetView(month: selectedMonth) }
            .sheet(isPresented: $showAddGoal)   { AddGoalView() }
            .sheet(item: $editingGoal)          { AddGoalView(editing: $0) }
            .sheet(isPresented: $showHistory)   {
                BudgetHistorySheet(budgets: budgets, transactions: transactions)
            }
            .themedNavBar()
            .sheet(isPresented: $showSettings) { SettingsView() }
        }
    }

    // MARK: - Segment button

    @ViewBuilder
    private func segButton(_ title: LocalizedStringKey, tag: Int) -> some View {
        Button {
            withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) { segment = tag }
        } label: {
            VStack(spacing: 5) {
                Text(title)
                    .font(.system(size: 14, weight: segment == tag ? .semibold : .regular))
                    .foregroundStyle(segment == tag ? DS.ink : DS.smoke)
                Rectangle()
                    .fill(segment == tag ? DS.ink : Color.clear)
                    .frame(height: 1)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, DS.Space.s)
        }
        .buttonStyle(.plain)
    }

    // MARK: - Toolbar

    @ToolbarContentBuilder
    private var toolbarContent: some ToolbarContent {
        ToolbarItem(placement: .topBarTrailing) {
            HStack(spacing: DS.Space.m) {
                if segment == 0 {
                    Button { showHistory = true } label: {
                        Image(systemName: "clock.arrow.circlepath")
                            .font(.system(size: 16))
                            .foregroundStyle(DS.ink)
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

    // MARK: - Budget content

    @ViewBuilder
    private var budgetContent: some View {
        // spentMap viene calcolato UNA SOLA VOLTA per render cycle.
        // Senza questo let, ogni accesso a overallBudgetPct e ogni riga del ForEach
        // ricalcolerebbe indipendentemente la mappa O(B×T), per un totale di N+2 passate.
        let map = spentMap
        let pct = overallBudgetPct(map: map)
        // Hero
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "Budget usato")
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(String(Int(pct * 100)))
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(DS.ink)
                Text("%")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(DS.smoke)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DS.fog).frame(height: 2)
                    Rectangle()
                        .fill(pct > 0.9 ? DS.ink : DS.smoke)
                        .frame(width: geo.size.width * pct, height: 2)
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.top, DS.Space.xl)

        // Selettore mese
        MonthBar(month: $selectedMonth)
            .padding(.horizontal, DS.Layout.margin)
            .padding(.top, DS.Space.xl)

        // Lista budget
        if currentBudgets.isEmpty {
            EmptyStateView(
                icon: "chart.bar",
                title: "Nessun budget",
                subtitle: "Imposta un limite mensile per categoria o conto.",
                cta: "Aggiungi budget",
                ctaAction: { showAddBudget = true }
            )
            .padding(.top, DS.Space.xl)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(currentBudgets.enumerated()), id: \.element.id) { _, budget in
                    BudgetRow(budget: budget, spentAmount: map[budget.id] ?? 0)
                        .padding(.horizontal, DS.Layout.margin)
                        .accessibilityIdentifier("budgetRow_\(budget.id.uuidString)")
                        .contextMenu {
                            Button(role: .destructive) {
                                context.delete(budget)
                                context.safeSave()
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                            .accessibilityIdentifier("btn_deleteBudget")
                        }
                    ThinDivider().padding(.leading, DS.Layout.margin)
                }
            }
            .padding(.top, DS.Space.xl)
        }
    }

    // MARK: - Goals content

    @ViewBuilder
    private var goalsContent: some View {
        // Hero
        VStack(alignment: .leading, spacing: DS.Space.s) {
            SectionLabel(text: "Progresso totale")
            HStack(alignment: .lastTextBaseline, spacing: 1) {
                Text(String(Int(overallGoalProgress * 100)))
                    .font(.system(size: 80, weight: .black))
                    .foregroundStyle(DS.ink)
                Text("%")
                    .font(.system(size: 40, weight: .ultraLight))
                    .foregroundStyle(DS.smoke)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Rectangle().fill(DS.fog).frame(height: 2)
                    Rectangle()
                        .fill(DS.ink)
                        .frame(width: geo.size.width * overallGoalProgress, height: 2)
                        .animation(
                            .spring(response: 0.5, dampingFraction: 0.8),
                            value: overallGoalProgress
                        )
                }
            }
            .frame(height: 2)
        }
        .padding(.horizontal, DS.Layout.margin)
        .padding(.top, DS.Space.xl)

        // Lista obiettivi
        if goals.isEmpty {
            EmptyStateView(
                icon: "target",
                title: "Nessun obiettivo",
                subtitle: "Imposta un obiettivo di risparmio e tieni traccia dei tuoi progressi.",
                cta: "Aggiungi obiettivo",
                ctaAction: { showAddGoal = true }
            )
            .padding(.top, DS.Space.xl)
        } else {
            VStack(spacing: 0) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { _, goal in
                    GoalRow(goal: goal)
                        .padding(.horizontal, DS.Layout.margin)
                        .contentShape(Rectangle())
                        .accessibilityIdentifier("goalRow_\(goal.id.uuidString)")
                        .onTapGesture { editingGoal = goal }
                        .contextMenu {
                            Button { editingGoal = goal } label: {
                                Label("Modifica", systemImage: "pencil")
                            }
                            .accessibilityIdentifier("btn_editGoal")
                            Button(role: .destructive) {
                                context.delete(goal)
                                context.safeSave()
                            } label: {
                                Label("Elimina", systemImage: "trash")
                            }
                            .accessibilityIdentifier("btn_deleteGoal")
                        }
                    ThinDivider().padding(.leading, DS.Layout.margin)
                }
            }
            .padding(.top, DS.Space.xl)
        }
    }
}
