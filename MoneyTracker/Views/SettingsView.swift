import SwiftUI
import SwiftData
import UniformTypeIdentifiers
import LocalAuthentication

// MARK: - In-memory CSV file (SEC-03: no temp file on disk; SEC-05: safe to share)
struct CSVFile: Transferable {
    let csvString: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .commaSeparatedText) { file in
            Data(file.csvString.utf8)
        }
        .suggestedFileName { _ in "transazioni.csv" }
    }
}

// MARK: - Full data export (JSON) — GDPR art. 20, diritto alla portabilità dei dati
//
// Il CSV sopra copre solo le transazioni (comodo per Excel/Numbers); questo export
// copre TUTTI i dati personali dell'utente in un unico file leggibile (conti, budget,
// obiettivi inclusi), così l'utente può richiedere/portare via l'intero suo profilo.

struct JSONExportFile: Transferable {
    let jsonString: String
    static var transferRepresentation: some TransferRepresentation {
        DataRepresentation(exportedContentType: .json) { file in
            Data(file.jsonString.utf8)
        }
        .suggestedFileName { _ in "i-miei-dati-moneytracker.json" }
    }
}

private struct GDPRExport: Codable {
    struct AccountExport: Codable {
        let id, name, type: String
        let initialBalance: Decimal
        let isArchived, isExcludedFromTotal: Bool
        let createdAt: Date
    }
    struct TransactionExport: Codable {
        let id, name, type, category, notes: String
        let amount: Decimal
        let date, createdAt: Date
        let isDone, isFixed, isTransfer: Bool
        let accountName: String?
    }
    struct BudgetExport: Codable {
        let id, category: String
        let monthlyLimit: Decimal
        let month, year: Int
        let accountName: String?
    }
    struct GoalExport: Codable {
        let id, name: String
        let targetAmount, currentAmount: Decimal
        let deadline: Date?
        let isCompleted: Bool
    }

    let exportedAt: Date
    let userEmail: String?
    let accounts: [AccountExport]
    let transactions: [TransactionExport]
    let budgets: [BudgetExport]
    let goals: [GoalExport]
}

struct SettingsView: View {
    @Environment(\.modelContext) private var context
    @Environment(\.dismiss)      private var dismiss

    // PERF-04: replaced @Query (keeps all rows in memory) with lazy fetch for count + CSV
    @State private var transactionCount: Int = 0
    @State private var csvData: CSVFile? = nil
    @State private var isGeneratingCSV: Bool = false
    @State private var jsonExportData: JSONExportFile? = nil
    @State private var isGeneratingJSON: Bool = false

    @AppStorage("currencyCode")          private var savedCurrency:       String = "EUR"
    @AppStorage("notificationsEnabled")  private var notificationsEnabled: Bool = true
    @AppStorage("monthlyReportEnabled")  private var monthlyReportEnabled: Bool = false
    @AppStorage("demoModeEnabled")       private var demoModeEnabled:      Bool = false
    @AppStorage("appLockEnabled")        private var appLockEnabled:       Bool = false

    // Letto una volta: cambia solo se l'utente aggiunge/rimuove Face ID o il codice
    // dispositivo mentre l'app è aperta, caso limite non ricontrollato ad ogni render.
    private let biometricAvailable = LAContextAuthenticator().isAvailable

    @State private var pickerCurrency: String = UserDefaults.standard.string(forKey: "currencyCode") ?? "EUR"
    @State private var pendingCurrency: String = ""
    @State private var showCurrencyConfirm = false

    // MARK: - Data

    private let currencyCodes: [(code: String, symbol: String)] = [
        ("EUR", "€"), ("USD", "$"), ("GBP", "£"), ("CHF", "₣"), ("JPY", "¥"),
        ("CAD", "CA$"), ("AUD", "A$"), ("SEK", "kr"), ("NOK", "kr"), ("DKK", "kr"),
        ("PLN", "zł"), ("RON", "lei"), ("HRK", "kn"), ("CZK", "Kč"), ("HUF", "Ft"),
    ]

    private var currencies: [(code: String, symbol: String, name: String)] {
        currencyCodes.map { pair in
            let localizedName = Locale.current.localizedString(forCurrencyCode: pair.code)
                             ?? pair.code
            return (pair.code, pair.symbol, localizedName)
        }
    }

    // MARK: - Body

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: DS.Space.xxl) {

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Lingua")
                        Text("La lingua dell'app segue le preferenze di sistema.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)
                        Button {
                            if let url = URL(string: UIApplication.openSettingsURLString) {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "gear")
                                    .font(.system(size: 15))
                                Text("Apri Impostazioni iOS")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(DS.ink)
                        }
                        .buttonStyle(.plain)
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Valuta")
                        Picker("", selection: $pickerCurrency) {
                            ForEach(currencies, id: \.code) { c in
                                Text(c.symbol + "  " + c.name).tag(c.code)
                            }
                        }
                        .pickerStyle(.menu)
                        .tint(DS.ink)
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .onChange(of: pickerCurrency) { _, newVal in
                            guard newVal != savedCurrency else { return }
                            pendingCurrency = newVal
                            showCurrencyConfirm = true
                        }
                    }
                    .sheet(isPresented: $showCurrencyConfirm) {
                        CurrencyConfirmSheet(
                            newSymbol: currencies.first(where: { $0.code == pendingCurrency })?.symbol ?? pendingCurrency,
                            newName:   currencies.first(where: { $0.code == pendingCurrency })?.name   ?? pendingCurrency
                        ) {
                            savedCurrency = pendingCurrency
                            showCurrencyConfirm = false
                        } onCancel: {
                            pickerCurrency = savedCurrency
                            showCurrencyConfirm = false
                        }
                        .presentationDetents([.height(272)])
                        .presentationDragIndicator(.visible)
                        .presentationCornerRadius(24)
                        .presentationBackground(DS.paper)
                        .interactiveDismissDisabled()
                    }
                    .onChange(of: savedCurrency) { _, newVal in
                        if pickerCurrency != newVal { pickerCurrency = newVal }
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Notifiche")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Avvisi automatici")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Budget quasi esaurito, fissi in scadenza, obiettivi vicini")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $notificationsEnabled)
                                .tint(DS.ink)
                                .labelsHidden()
                                .onChange(of: notificationsEnabled) { _, enabled in
                                    if enabled {
                                        SystemNotificationManager.shared.requestPermission()
                                    } else {
                                        SystemNotificationManager.shared.cancelAll()
                                        monthlyReportEnabled = false
                                    }
                                }
                        }
                        ThinDivider()
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Report mensile PDF")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Promemoria il 1° di ogni mese per generare il report PDF")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $monthlyReportEnabled)
                                .tint(DS.ink)
                                .labelsHidden()
                                .disabled(!notificationsEnabled)
                                .onChange(of: monthlyReportEnabled) { _, enabled in
                                    SystemNotificationManager.shared.scheduleMonthlyReportReminder(enabled: enabled)
                                }
                        }
                        .opacity(notificationsEnabled ? 1 : 0.4)
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Sicurezza")
                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Blocco con Face ID")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text(biometricAvailable
                                     ? "Richiede Face ID, Touch ID o il codice del dispositivo all'apertura"
                                     : "Nessun metodo di sblocco configurato su questo dispositivo")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            // PROP-03: disattivare una protezione di sicurezza è un'azione
                            // ad alto rischio (es. telefono già sbloccato in mano a
                            // qualcun altro) — richiede una nuova conferma biometrica,
                            // non basta che l'app fosse già aperta. Attivarla invece resta
                            // libero: non c'è nulla da proteggere nell'aumentare la sicurezza.
                            Toggle("", isOn: Binding(
                                get: { appLockEnabled },
                                set: { newValue in
                                    if newValue {
                                        appLockEnabled = true
                                    } else {
                                        Task {
                                            let authenticator = LAContextAuthenticator()
                                            var confirmed = true
                                            if authenticator.isAvailable {
                                                confirmed = await authenticator.authenticate()
                                            }
                                            if confirmed { appLockEnabled = false }
                                        }
                                    }
                                }
                            ))
                            .tint(DS.ink)
                            .labelsHidden()
                            .disabled(!biometricAvailable)
                        }

                        ThinDivider()

                        Button {
                            showAuditLog = true
                        } label: {
                            HStack {
                                Text("Cronologia modifiche")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.smoke)
                            }
                        }
                        .buttonStyle(.plain)
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Esportazione dati")

                        Text("Esporta tutte le transazioni in formato CSV, compatibile con Excel e Numbers.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)

                        if let file = csvData {
                            ShareLink(
                                item: file,
                                preview: SharePreview("transazioni.csv", icon: Image(systemName: "tablecells"))
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15))
                                    Text("Condividi CSV")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundStyle(DS.paper)
                                .frame(maxWidth: .infinity)
                                .frame(height: DS.Layout.buttonHeight)
                                .background(DS.ink)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                            }
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else if isGeneratingCSV {
                            HStack {
                                ProgressView()
                                    .tint(DS.paper)
                                Text("Generazione in corso…")
                                    .font(.system(size: 17, weight: .semibold))
                                    .foregroundStyle(DS.paper)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Layout.buttonHeight)
                            .background(DS.ink.opacity(0.6))
                            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                        } else {
                            PrimaryButton(title: "Genera CSV") {
                                Task { @MainActor in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isGeneratingCSV = true
                                    }
                                    generateCSV()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isGeneratingCSV = false
                                    }
                                }
                            }
                        }

                        ThinDivider()

                        // GDPR art. 20 — export completo (conti, movimenti, budget, obiettivi),
                        // non solo le transazioni: la portabilità copre l'intero profilo dati.
                        Text("Oppure esporta l'intero tuo profilo (conti, budget e obiettivi inclusi) in un unico file JSON.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)

                        if let file = jsonExportData {
                            ShareLink(
                                item: file,
                                preview: SharePreview("i-miei-dati-moneytracker.json", icon: Image(systemName: "doc.text"))
                            ) {
                                HStack {
                                    Image(systemName: "square.and.arrow.up")
                                        .font(.system(size: 15))
                                    Text("Condividi tutti i dati (JSON)")
                                        .font(.system(size: 15, weight: .medium))
                                }
                                .foregroundStyle(DS.ink)
                                .frame(maxWidth: .infinity)
                                .frame(height: DS.Layout.buttonHeight)
                                .background(DS.fog)
                                .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                            }
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        } else if isGeneratingJSON {
                            HStack {
                                ProgressView().tint(DS.ink)
                                Text("Generazione in corso…")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(DS.ink)
                            }
                            .frame(maxWidth: .infinity)
                            .frame(height: DS.Layout.buttonHeight)
                            .background(DS.fog)
                            .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                        } else {
                            Button {
                                Task { @MainActor in
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isGeneratingJSON = true
                                    }
                                    generateFullExport()
                                    withAnimation(.spring(response: 0.3, dampingFraction: 0.8)) {
                                        isGeneratingJSON = false
                                    }
                                }
                            } label: {
                                Text("Esporta tutti i dati (JSON)")
                                    .font(.system(size: 15, weight: .medium))
                                    .foregroundStyle(DS.ink)
                                    .frame(maxWidth: .infinity)
                                    .frame(height: DS.Layout.buttonHeight)
                                    .background(DS.fog)
                                    .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                            }
                        }
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Modalità Demo")
                        Text("Mostra l'app con dati di esempio senza esporre i tuoi dati reali. Utile per mostrare MoneyTracker ad amici o colleghi.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)

                        HStack {
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Attiva modalità demo")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("I tuoi dati reali restano intatti e privati")
                                    .font(.system(size: 11))
                                    .foregroundStyle(DS.smoke)
                            }
                            Spacer()
                            Toggle("", isOn: $demoModeEnabled)
                                .tint(.orange)
                                .labelsHidden()
                        }

                        if demoModeEnabled {
                            HStack(spacing: DS.Space.s) {
                                Image(systemName: "info.circle.fill")
                                    .font(.system(size: 13))
                                    .foregroundStyle(.orange)
                                Text("L'app si riavvierà con dati demo. Per tornare ai tuoi dati basta disattivare il toggle.")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.smoke)
                            }
                            .padding(DS.Space.m)
                            .background(DS.fog.opacity(0.5))
                            .clipShape(RoundedRectangle(cornerRadius: 10))
                            .transition(.scale(scale: 0.95).combined(with: .opacity))
                        }
                    }
                    .animation(.spring(response: 0.3, dampingFraction: 0.8), value: demoModeEnabled)

                    ThinDivider()

                    // ── Siri & Shortcut ───────────────────────────────────
                    VStack(alignment: .leading, spacing: DS.Space.l) {
                        SectionLabel(text: "Siri & Shortcut")

                        Text("Aggiungi spese senza aprire l'app: con la voce, un widget o una scorciatoia rapida.")
                            .font(.system(size: 13))
                            .foregroundStyle(DS.smoke)

                        Button {
                            if let url = URL(string: "shortcuts://") {
                                UIApplication.shared.open(url)
                            }
                        } label: {
                            HStack {
                                Image(systemName: "apps.iphone")
                                    .font(.system(size: 15))
                                Text("Apri Shortcut")
                                    .font(.system(size: 15, weight: .medium))
                                Spacer()
                                Image(systemName: "arrow.up.right")
                                    .font(.system(size: 12))
                            }
                            .foregroundStyle(DS.ink)
                        }
                        .buttonStyle(.plain)

                        // Tip callout
                        HStack(alignment: .top, spacing: DS.Space.s) {
                            Image(systemName: "lightbulb.fill")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.ink.opacity(0.5))
                                .padding(.top, 1)
                            Text("Crea una Shortcut in Shortcut, poi vai in Impostazioni → Accessibilità → Tocco → Tocca sul retro → Doppio tocco e scegli la tua scorciatoia per accesso istantaneo.")
                                .font(.system(size: 12))
                                .foregroundStyle(DS.smoke)
                                .lineSpacing(2)
                        }
                        .padding(DS.Space.m)
                        .background(DS.fog.opacity(0.5))
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }

                    ThinDivider()

                    // ── Tour ──────────────────────────────────────────────
                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        SectionLabel(text: "Tour")
                        Button {
                            dismiss()
                            DispatchQueue.main.asyncAfter(deadline: .now() + 0.4) {
                                TourManager.shared.start()
                            }
                        } label: {
                            HStack {
                                Image(systemName: "hand.point.right")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Text("Rivedi tour")
                                    .font(.system(size: 15))
                                    .foregroundStyle(DS.ink)
                                Spacer()
                                Image(systemName: "chevron.right")
                                    .font(.system(size: 12))
                                    .foregroundStyle(DS.smoke)
                            }
                        }
                    }

                    ThinDivider()

                    VStack(alignment: .leading, spacing: DS.Space.s) {
                        SectionLabel(text: "Info")
                        HStack {
                            Text("Versione")
                                .font(.system(size: 15))
                                .foregroundStyle(DS.smoke)
                            Spacer()
                            Text(Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "1.0")
                                .font(.system(size: 15))
                                .foregroundStyle(DS.smoke)
                        }
                        ThinDivider()
                        HStack {
                            Text("Transazioni totali")
                                .font(.system(size: 15))
                                .foregroundStyle(DS.smoke)
                            Spacer()
                            Text("\(transactionCount)")
                                .font(.system(size: 15))
                                .foregroundStyle(DS.smoke)
                        }
                    }

                    Spacer(minLength: DS.Space.xxl)
                }
                .padding(.horizontal, DS.Layout.margin)
                // MARK: Profilo / Account
                accountSection
                    .padding(.top, DS.Space.xl)
                    .padding(.horizontal, DS.Layout.margin)
            }
            .background(DS.paper)
            .scrollIndicators(.hidden)
            .navigationTitle("Impostazioni")
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    GhostButton(title: "Chiudi") { dismiss() }
                }
            }
            .sheet(isPresented: $showAuditLog) { AuditLogView() }
            .onAppear {
                // PERF-04: fetch only the count, not all rows
                transactionCount = (try? context.fetchCount(FetchDescriptor<Transaction>())) ?? 0
            }
        }
    }

    // MARK: - Account / Profilo

    @State private var showLogoutConfirm = false
    // Diritto all'oblio (GDPR art. 17): due passaggi separati — un primo avviso, poi
    // una conferma testuale ("ELIMINA") — perché è irreversibile e cancella anche
    // l'account Supabase stesso, non solo i dati locali.
    @State private var showDeleteAccountWarning  = false
    @State private var showDeleteAccountConfirm  = false
    @State private var deleteAccountConfirmText  = ""
    @State private var isDeletingAccount         = false
    @State private var deleteAccountError: String? = nil
    @State private var showAuditLog = false

    @ViewBuilder private var accountSection: some View {
        let auth = SupabaseManager.shared
        VStack(alignment: .leading, spacing: DS.Space.l) {
            SectionLabel(text: "Account")

            // Email utente
            if let email = auth.userEmail {
                HStack(spacing: DS.Space.m) {
                    Image(systemName: "person.circle")
                        .font(.system(size: 20))
                        .foregroundStyle(DS.smoke)
                    Text(email)
                        .font(.system(size: 15))
                        .foregroundStyle(DS.ink)
                }
                ThinDivider()
            }

            // Logout
            Button {
                showLogoutConfirm = true
            } label: {
                HStack {
                    Image(systemName: "rectangle.portrait.and.arrow.right")
                        .font(.system(size: 15))
                    Text("Esci dall'account")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .confirmationDialog("Esci dall'account?",
                                isPresented: $showLogoutConfirm,
                                titleVisibility: .visible) {
                Button("Esci", role: .destructive) {
                    Task { try? await auth.signOut() }
                }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Dovrai effettuare di nuovo il login la prossima volta.")
            }

            // Elimina account — diritto all'oblio (GDPR art. 17). Due passaggi: un
            // avviso con le conseguenze, poi una conferma testuale, perché è l'unica
            // azione dell'app che cancella dati in modo irreversibile.
            Button {
                showDeleteAccountWarning = true
            } label: {
                HStack {
                    Image(systemName: "trash.fill")
                        .font(.system(size: 15))
                    Text("Elimina account")
                        .font(.system(size: 15, weight: .medium))
                    Spacer()
                }
                .foregroundStyle(.red)
            }
            .buttonStyle(.plain)
            .disabled(isDeletingAccount)
            .confirmationDialog(
                "Eliminare l'account?",
                isPresented: $showDeleteAccountWarning,
                titleVisibility: .visible
            ) {
                Button("Continua", role: .destructive) {
                    deleteAccountConfirmText = ""
                    showDeleteAccountConfirm = true
                }
                Button("Annulla", role: .cancel) { }
            } message: {
                Text("Verranno cancellati per sempre tutti i tuoi conti, movimenti, budget e obiettivi, sia sul dispositivo che sul cloud. L'operazione non è reversibile.")
            }
            .alert("Conferma eliminazione", isPresented: $showDeleteAccountConfirm) {
                TextField("Scrivi ELIMINA", text: $deleteAccountConfirmText)
                    .autocorrectionDisabled()
                // PROP-03: azione irreversibile più ad alto impatto dell'app — richiede
                // una nuova conferma biometrica anche se il telefono era già sbloccato,
                // non solo la conferma testuale sopra.
                Button("Elimina definitivamente", role: .destructive) {
                    Task {
                        let authenticator = LAContextAuthenticator()
                        var confirmed = true
                        if authenticator.isAvailable {
                            confirmed = await authenticator.authenticate()
                        }
                        if confirmed {
                            deleteAccountAction()
                        } else {
                            deleteAccountConfirmText = ""
                        }
                    }
                }
                .disabled(deleteAccountConfirmText != "ELIMINA")
                Button("Annulla", role: .cancel) { deleteAccountConfirmText = "" }
            } message: {
                Text("Per confermare, scrivi ELIMINA in maiuscolo.")
            }

            if isDeletingAccount {
                HStack(spacing: DS.Space.s) {
                    ProgressView().tint(DS.smoke)
                    Text("Eliminazione in corso…")
                        .font(.system(size: 13))
                        .foregroundStyle(DS.smoke)
                }
            }
            if let err = deleteAccountError {
                Text(err)
                    .font(.system(size: 12))
                    .foregroundStyle(.red)
            }
        }
    }

    private func deleteAccountAction() {
        isDeletingAccount = true
        deleteAccountError = nil
        Task {
            do {
                try await SupabaseManager.shared.deleteAccount()
                // L'account su Supabase è già cancellato: ripulisci lo store locale
                // e disconnetti — MoneyTrackerApp mostrerà automaticamente il login.
                SyncService.shared.clearLocalData(context: context)
                try? await SupabaseManager.shared.signOut()
            } catch {
                deleteAccountError = String(
                    format: NSLocalizedString("Impossibile eliminare l'account: %@", comment: ""),
                    error.localizedDescription
                )
            }
            isDeletingAccount = false
            deleteAccountConfirmText = ""
        }
    }

    // MARK: - CSV Export

    /// Sanitises a CSV field: quotes it and escapes formula-injection characters.
    /// SEC-05: prevents =CMD(), +HYPERLINK(), etc. being treated as formulas by spreadsheet apps.
    private func csvEscape(_ field: String) -> String {
        var s = field
        // Prefix fields that start with formula-injection chars with a single apostrophe.
        if let first = s.first, "=+-@\t\r\n".contains(first) {
            s = "'" + s
        }
        // Always wrap in double-quotes; escape internal quotes per RFC 4180.
        return "\"" + s.replacingOccurrences(of: "\"", with: "\"\"") + "\""
    }

    private func generateCSV() {
        // SEC-03: fetch transactions on demand (no permanent @Query keeping all rows in memory)
        let allTransactions = (try? context.fetch(
            FetchDescriptor<Transaction>(sortBy: [SortDescriptor(\Transaction.date, order: .reverse)])
        )) ?? []

        let h1 = csvEscape(NSLocalizedString("Data", comment: ""))
        let h2 = csvEscape(NSLocalizedString("Descrizione", comment: ""))
        let h3 = csvEscape(NSLocalizedString("Importo", comment: ""))
        let h4 = csvEscape(NSLocalizedString("Tipo", comment: ""))
        let h5 = csvEscape(NSLocalizedString("Categoria", comment: ""))
        let h6 = csvEscape(NSLocalizedString("Conto", comment: ""))
        let h7 = csvEscape(NSLocalizedString("Fatto", comment: ""))
        let h8 = csvEscape(NSLocalizedString("Ricorrenza", comment: ""))
        var csv = "\(h1),\(h2),\(h3),\(h4),\(h5),\(h6),\(h7),\(h8)\n"

        for t in allTransactions {
            let date   = csvEscape(FormatterCache.csvDate.string(from: t.date))
            let name   = csvEscape(t.name)
            let amount = csvEscape(t.amount.fixedFractionString)
            let tipo   = csvEscape(NSLocalizedString(t.transactionType == .uscita ? "Uscita" : "Entrata", comment: ""))
            let cat    = csvEscape(NSLocalizedString(t.category, comment: ""))
            let acc    = csvEscape(t.account?.name ?? "")
            let done   = csvEscape(NSLocalizedString(t.isDone ? "Sì" : "No", comment: ""))
            let rec    = csvEscape(t.recurringFrequency)
            csv += "\(date),\(name),\(amount),\(tipo),\(cat),\(acc),\(done),\(rec)\n"
        }

        // SEC-03: share in memory — no temp file written to disk
        csvData = CSVFile(csvString: csv)
    }

    /// GDPR art. 20 — export completo e leggibile di tutti i dati personali dell'utente,
    /// non solo le transazioni (vedi generateCSV sopra).
    private func generateFullExport() {
        let accounts     = (try? context.fetch(FetchDescriptor<Account>()))     ?? []
        let transactions = (try? context.fetch(FetchDescriptor<Transaction>())) ?? []
        let budgets      = (try? context.fetch(FetchDescriptor<Budget>()))      ?? []
        let goals        = (try? context.fetch(FetchDescriptor<Goal>()))        ?? []

        let export = GDPRExport(
            exportedAt: Date(),
            userEmail: SupabaseManager.shared.userEmail,
            accounts: accounts.map {
                .init(id: $0.id.uuidString, name: $0.name, type: $0.type,
                      initialBalance: $0.initialBalance, isArchived: $0.isArchived,
                      isExcludedFromTotal: $0.isExcludedFromTotal, createdAt: $0.createdAt)
            },
            transactions: transactions.map {
                .init(id: $0.id.uuidString, name: $0.name, type: $0.type, category: $0.category,
                      notes: $0.notes, amount: $0.amount, date: $0.date, createdAt: $0.createdAt,
                      isDone: $0.isDone, isFixed: $0.isFixed, isTransfer: $0.isTransfer,
                      accountName: $0.account?.name)
            },
            budgets: budgets.map {
                .init(id: $0.id.uuidString, category: $0.category, monthlyLimit: $0.monthlyLimit,
                      month: $0.month, year: $0.year, accountName: $0.account?.name)
            },
            goals: goals.map {
                .init(id: $0.id.uuidString, name: $0.name, targetAmount: $0.targetAmount,
                      currentAmount: $0.currentAmount, deadline: $0.deadline, isCompleted: $0.isCompleted)
            }
        )

        let encoder = JSONEncoder()
        encoder.dateEncodingStrategy = .iso8601
        encoder.outputFormatting = [.prettyPrinted, .sortedKeys]
        guard let data = try? encoder.encode(export),
              let json = String(data: data, encoding: .utf8) else { return }
        jsonExportData = JSONExportFile(jsonString: json)
    }
}

// MARK: - CurrencyConfirmSheet

private struct CurrencyConfirmSheet: View {
    let newSymbol: String
    let newName:   String
    let onConfirm: () -> Void
    let onCancel:  () -> Void

    var body: some View {
        VStack(spacing: 0) {

            VStack(spacing: 4) {
                Text(newSymbol)
                    .font(.system(size: 52, weight: .black))
                    .foregroundStyle(DS.ink)
                Text(newName)
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(DS.ink)
            }
            .frame(maxWidth: .infinity)
            .padding(.top, DS.Space.xl)
            .padding(.bottom, DS.Space.m)

            Text("Il simbolo verrà aggiornato ovunque nell'app. Gli importi restano invariati.")
                .font(.system(size: 13))
                .foregroundStyle(DS.smoke)
                .multilineTextAlignment(.center)
                .padding(.horizontal, DS.Layout.margin)

            Spacer()

            HStack(spacing: DS.Space.m) {
                Button {
                    haptic(.soft)
                    onCancel()
                } label: {
                    Text("Annulla")
                        .font(.system(size: 16))
                        .foregroundStyle(DS.ink)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.Layout.buttonHeight)
                        .background(DS.fog)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                }
                .buttonStyle(.plain)

                Button {
                    haptic(.medium)
                    onConfirm()
                } label: {
                    Text("Conferma")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(DS.paper)
                        .frame(maxWidth: .infinity)
                        .frame(height: DS.Layout.buttonHeight)
                        .background(DS.ink)
                        .clipShape(RoundedRectangle(cornerRadius: DS.Layout.buttonRadius))
                }
                .buttonStyle(.plain)
            }
            .padding(.horizontal, DS.Layout.margin)
            .padding(.bottom, DS.Space.l)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(DS.paper)
    }
}
