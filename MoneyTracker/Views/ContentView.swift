import SwiftUI
import SwiftData

struct ContentView: View {
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
        ZStack(alignment: .bottomTrailing) {
            VStack(spacing: 0) {
            TabView(selection: $selectedTab) {
                DashboardView(showAdd: $showAdd, goToTab: { selectedTab = $0 })
                    .hidingNativeTabBar()
                    .tag(0)

                TransactionsView(isSearchActive: $isSearchingTransactions)
                    .hidingNativeTabBar()
                    .tag(1)

                StatisticsView()
                    .hidingNativeTabBar()
                    .tag(2)

                PianificaView(
                    showAddBudget: $showAddBudget,
                    showAddGoal:   $showAddGoal,
                    segment:       $planningSegment
                )
                .hidingNativeTabBar()
                .tag(3)

                AccountsView(showAdd: $showAddAccount)
                    .hidingNativeTabBar()
                    .tag(4)
            }
            // Spazio sotto la TabView: i contenuti (anche le schermate aperte in push)
            // finiscono sopra la barra flottante, quindi righe e swipe restano raggiungibili.
            Color.clear.frame(height: FloatingTabBar.reservedHeight)
            }
            .background(DS.paper)

            FloatingTabBar(items: Self.tabItems, selection: $selectedTab)
                .frame(maxHeight: .infinity, alignment: .bottom)

            let fabHidden = selectedTab == 1 && isSearchingTransactions
            fabButton
                .padding(.trailing, 22)
                .padding(.bottom, 100)
                .opacity(fabHidden ? 0 : 1)
                .scaleEffect(fabHidden ? 0.7 : 1)
                .animation(.spring(response: 0.25, dampingFraction: 0.8), value: fabHidden)
                .allowsHitTesting(!fabHidden)
        }
        .sheet(isPresented: $showAdd)      { AddTransactionView() }
        .sheet(isPresented: $showTransfer) { AddTransferView() }
    }

    private static let tabItems: [FloatingTabBar.Item] = [
        .init(id: 0, title: "Home",        symbol: "house",      identifier: "tab_home"),
        .init(id: 1, title: "Movimenti",   symbol: "list.bullet", identifier: "tab_movimenti"),
        .init(id: 2, title: "Statistiche", symbol: "chart.bar",   identifier: "tab_statistiche"),
        .init(id: 3, title: "Pianifica",   symbol: "scope",       identifier: "tab_pianifica"),
        .init(id: 4, title: "Conti",       symbol: "creditcard",  identifier: "tab_conti"),
    ]

    private var fabLabel: LocalizedStringKey {
        switch selectedTab {
        case 3:  return planningSegment == 0 ? "Nuovo budget" : "Nuovo obiettivo"
        case 4:  return "Nuovo conto"
        default: return "Nuovo movimento"
        }
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
            .buttonStyle(.plain)
            .fabShadow()
            .accessibilityIdentifier("fabButton")
            .accessibilityLabel(fabLabel)
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
            .buttonStyle(.plain)
            .fabShadow()
            .accessibilityIdentifier("fabButton")
            .accessibilityLabel(fabLabel)
        }
    }

    /// Forma unica del FAB: serve anche come anteprima del menu, così il tocco
    /// non mostra il rettangolo di selezione di sistema attorno allo squircle.
    private static let fabShape = RoundedRectangle(cornerRadius: 20)

    private var fabCircle: some View {
        Image(systemName: "plus")
            .scaledFont(size: 24, weight: .semibold)
            .foregroundStyle(DS.onAccent)
            .frame(width: 58, height: 58)
            .background(DS.accent, in: Self.fabShape)
            .contentShape(.contextMenuPreview, Self.fabShape)
            .contentShape(Self.fabShape)
    }
}

private extension View {
    /// Ombra del FAB applicata fuori dall'etichetta del Menu/Button: durante la
    /// pressione il sistema ricalca solo l'etichetta e l'ombra interna spariva.
    func fabShadow() -> some View {
        background {
            RoundedRectangle(cornerRadius: 20)
                .fill(DS.accent)
                .shadow(color: DS.accent.opacity(0.35), radius: 12, y: 6)
        }
    }
}

private extension View {
    /// Nasconde la barra nativa (va dichiarato su ogni tab, non sulla TabView).
    func hidingNativeTabBar() -> some View {
        toolbar(.hidden, for: .tabBar)
    }
}
