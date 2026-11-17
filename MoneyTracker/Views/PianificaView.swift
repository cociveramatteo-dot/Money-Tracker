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

                    HStack {
                        Text("Pianifica").font(DS.Typo.screenTitle).tracking(DS.Typo.screenTitleTracking)
                        Spacer()
                        if segment == 0 {
                            Button { showHistory = true } label: {
                                Image(systemName: "clock.arrow.circlepath").frame(width: 44, height: 44)
                            }.accessibilityLabel("Storico Budget")
                        }
                        Button { showSettings = true } label: {
                            Image(systemName: "gearshape").frame(width: 44, height: 44)
                        }.accessibilityLabel("Impostazioni")
                    }.foregroundStyle(DS.ink).padding(.horizontal, 20)
                    HStack(spacing: 4) {
                        segButton("Budget", tag: 0)
                        segButton("Obiettivi", tag: 1)
                    }
                    .padding(4).background(DS.fog, in: RoundedRectangle(cornerRadius: 14))
                    .padding(.horizontal, 16).padding(.top, 8)

                    if segment == 0 {
                        budgetContent
                    } else {
                        goalsContent
                    }

                    Spacer(minLength: 100)
                }
            }
            // Riserva la fascia del FAB dentro il contenuto: la lista scorre sotto la barra
            // senza essere tagliata (un padding sullo ScrollView lascia una striscia vuota).
            .contentMargins(.bottom, DS.Space.xxl + DS.Space.xl + DS.Space.l, for: .scrollContent)
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .refreshable { await SyncService.shared.manualRefresh(context: context) }
            .toolbar(.hidden, for: .navigationBar)
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
            Text(title).font(DS.Typo.rowName)
                .foregroundStyle(segment == tag ? DS.ink : DS.smoke)
                .frame(maxWidth: .infinity, minHeight: 44)
                .background(segment == tag ? DS.surface : DS.fog, in: RoundedRectangle(cornerRadius: 11))
        }
        .buttonStyle(.plain)
        .accessibilityIdentifier(tag == 0 ? "planning_budget" : "planning_goals")
        .accessibilityAddTraits(segment == tag ? [.isSelected] : [])
    }

    // MARK: - Budget content

    @ViewBuilder
    private var budgetContent: some View {
        // spentMap viene calcolato UNA SOLA VOLTA per render cycle.
        // Senza questo let, ogni accesso a overallBudgetPct e ogni riga del ForEach
        // ricalcolerebbe indipendentemente la mappa O(B×T), per un totale di N+2 passate.
        let map = spentMap
        let pct = overallBudgetPct(map: map)
        let total = currentBudgets.reduce(Decimal(0)) { $0 + $1.monthlyLimit }
        let used = map.values.reduce(Decimal(0), +)
        MonthBar(month: $selectedMonth).frame(minHeight: 44)
            .padding(.horizontal, 20).padding(.top, 8)
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text("Budget usato").font(DS.Typo.secondary).foregroundStyle(DS.heroSecondary)
                Spacer()
                Text(pct, format: .percent.precision(.fractionLength(0)))
                    .font(DS.Typo.screenTitle).foregroundStyle(DS.heroPlanned).monospacedDigit()
            }
            Text(used.currencyFormatted + " / " + total.currencyFormatted)
                .font(DS.Typo.rowAmount).foregroundStyle(DS.heroText)
            ProgressBar(progress: pct, onHero: true)
            ViewThatFits(in: .horizontal) {
                HStack { Text(daysRemaining); Spacer(minLength: 8); Text("Avviso all’80%") }
                VStack(alignment: .leading, spacing: 4) { Text(daysRemaining); Text("Avviso all’80%") }
            }.font(DS.Typo.caption).foregroundStyle(DS.heroSecondary)
        }
        .padding(18).background(DS.hero, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16).padding(.top, 4)

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
            VStack(spacing: 8) {
                ForEach(Array(currentBudgets.enumerated()), id: \.element.id) { _, budget in
                    PlanningBudgetCard(budget: budget, spentAmount: map[budget.id] ?? 0)
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
                }
            }
            .padding(.horizontal, 16).padding(.top, 10)
        }
    }

    // Countdown solo di presentazione: non partecipa ai calcoli del budget.
    private var daysRemaining: String {
        let calendar = Calendar.current
        let end = calendar.dateInterval(of: .month, for: selectedMonth)?.end ?? selectedMonth
        let days = max(0, calendar.dateComponents([.day], from: Date(), to: end).day ?? 0)
        return String.localizedStringWithFormat(NSLocalizedString("Mancano %lld giorni", comment: "Budget days remaining"), Int64(days))
    }

    // MARK: - Goals content

    @ViewBuilder
    private var goalsContent: some View {
        HStack(spacing: 18) {
            PlanningProgressRing(progress: overallGoalProgress)
            VStack(alignment: .leading, spacing: 4) {
                Text("Progresso complessivo").font(DS.Typo.secondary).foregroundStyle(DS.heroSecondary)
                Text(overallGoalProgress, format: .percent.precision(.fractionLength(0)))
                    .font(DS.Typo.screenTitle).foregroundStyle(DS.heroAccent).monospacedDigit()
                Text(goals.reduce(Decimal(0)) { $0 + $1.currentAmount }.currencyFormatted
                     + " / " + goals.reduce(Decimal(0)) { $0 + $1.targetAmount }.currencyFormatted)
                    .font(DS.Typo.secondary).foregroundStyle(DS.heroText).monospacedDigit()
            }
            Spacer(minLength: 0)
        }
        .padding(18).frame(maxWidth: .infinity, alignment: .leading)
        .background(DS.hero, in: RoundedRectangle(cornerRadius: 24))
        .padding(.horizontal, 16).padding(.top, 12)

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
            VStack(spacing: 8) {
                ForEach(Array(goals.enumerated()), id: \.element.id) { _, goal in
                    PlanningGoalCard(goal: goal, addProgress: { editingGoal = goal })
                        .contentShape(Rectangle())
                        .onTapGesture { editingGoal = goal }
                        .accessibilityElement(children: .contain)
                        .accessibilityIdentifier("goalRow_\(goal.id.uuidString)")
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
                }
            }
            .padding(.horizontal, 16).padding(.top, 10)
        }
    }
}
