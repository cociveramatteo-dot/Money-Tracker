import SwiftUI
import SwiftData

struct ContentView: View {
    @ObservedObject private var tourManager = TourManager.shared
    @State private var selectedTab          = 0
    @State private var showAdd              = false
    @State private var showTransfer         = false
    @State private var showAddBudget        = false
    @State private var showAddGoal          = false
    @State private var showAddAccount       = false
    @State private var isSearchingTransactions = false
    /// Segmento attivo dentro PianificaView (0 = Budget, 1 = Obiettivi).
    @State private var planningSegment      = 0

    var body: some View {
        ZStack(alignment: .bottom) {
            TabView(selection: $selectedTab) {
                DashboardView(showAdd: $showAdd)
                    .tabItem { Label("Home",        systemImage: "house") }
                    .tag(0)

                TransactionsView(isSearchActive: $isSearchingTransactions)
                    .tabItem { Label("Movimenti",   systemImage: "list.bullet") }
                    .tag(1)

                StatisticsView()
                    .tabItem { Label("Statistiche", systemImage: "chart.bar.fill") }
                    .tag(2)

                PianificaView(
                    showAddBudget: $showAddBudget,
                    showAddGoal:   $showAddGoal,
                    segment:       $planningSegment
                )
                .tabItem { Label("Pianifica",   systemImage: "chart.pie") }
                .tag(3)

                AccountsView(showAdd: $showAddAccount)
                    .tabItem { Label("Conti",       systemImage: "creditcard") }
                    .tag(4)
            }
            .tint(DS.ink)
            .toolbarBackground(DS.paper, for: .tabBar)
            .toolbarBackground(.visible, for: .tabBar)

            let fabHidden = selectedTab == 1 && isSearchingTransactions
            fabButton
                .padding(.bottom, 90)
                .opacity(fabHidden ? 0 : 1)
                .scaleEffect(fabHidden ? 0.7 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: fabHidden)
                .allowsHitTesting(!fabHidden)
        }
        // ── Tour-driven tab/segment switching (panoramica, Livello 1) ─────────
        .onChange(of: tourManager.requiredTab) { _, tab in
            if let tab { selectedTab = tab }
        }
        .onChange(of: tourManager.requiredSegment) { _, segment in
            if let segment { planningSegment = segment }
        }
        // ── Tour trigger (panoramica) ──────────────────────────────────────────
        // ContentView is recreated when demoModeEnabled changes (via .id()).
        // Guard: don't restart if tour is already active (TourManager.start() caused
        // this re-creation by toggling demoModeEnabled).
        .onAppear {
            guard !TourManager.shared.isActive else { return }
            // "--forceTour": hook di QA per rivedere il tour in automazione senza
            // passare da Impostazioni (stessa idea di "--uitesting", vedi MoneyTrackerApp).
            if ProcessInfo.processInfo.arguments.contains("--forceTour") {
                TourManager.shared.start()
            } else {
                TourManager.shared.startIfNeeded()
            }
        }
        .sheet(isPresented: $showAdd)      { AddTransactionView() }
        .sheet(isPresented: $showTransfer) { AddTransferView() }
    }

    // MARK: - FAB

    @ViewBuilder
    private var fabButton: some View {
        if selectedTab <= 1 {
            Menu {
                Button { showAdd = true } label: {
                    Label("Spesa / Entrata", systemImage: "plus.circle")
                }
                .accessibilityIdentifier("fabMenu_addTransaction")
                Button { showTransfer = true } label: {
                    Label("Trasferimento tra conti", systemImage: "arrow.left.arrow.right")
                }
                .accessibilityIdentifier("fabMenu_addTransfer")
            } label: {
                fabCircle
            }
            .accessibilityIdentifier("fabButton")
            .simultaneousGesture(TapGesture().onEnded {
                haptic(.medium)
            })
        } else if selectedTab != 2 {
            Button {
                haptic(.medium)
                switch selectedTab {
                case 3:
                    if planningSegment == 0 { showAddBudget = true }
                    else                    { showAddGoal   = true }
                case 4: showAddAccount = true
                default: break
                }
            } label: {
                fabCircle
            }
            .accessibilityIdentifier("fabButton")
        }
    }

    private var fabCircle: some View {
        ZStack {
            Circle()
                .fill(DS.ink)
                .frame(width: 52, height: 52)
                .shadow(color: .black.opacity(0.14), radius: 8, y: 3)
            Image(systemName: "plus")
                .font(.system(size: 20, weight: .medium))
                .foregroundStyle(DS.paper)
        }
        .tourAnchor("addButton")
    }
}
