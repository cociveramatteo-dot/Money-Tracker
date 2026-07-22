# Graph Report - .  (2026-07-22)

## Corpus Check
- 9 files · ~58,825 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 964 nodes · 1730 edges · 151 communities (34 shown, 117 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 67 edges (avg confidence: 0.8)
- Token cost: 112,171 input · 0 output

## Community Hubs (Navigation)
- Account Management UI
- QA Automation & UITests
- Authentication Views
- Account Data Model
- Cloud Sync (Supabase)
- Balance Caching & Date Helpers
- Budget View & History
- Demo Data Seeding
- SwiftData Schema Migration
- Siri Shortcuts Intents
- Biometric App Lock
- Tour State Management
- Settings & Data Export
- PDF Report Generation
- Domain Services Overview
- Category Auto-Classification
- Product Roadmap
- Audit Logging
- Transfer Entry & Dashboard
- Local Notifications
- Onboarding Tour Overlay
- Formatting Cache & Version History
- Quality Audit Findings
- Recurring Series Detection
- Fixed Items & Transfers Changelog
- Category Model & Persistence
- Pianifica Budget/Goals View
- App Bootstrap & File Protection
- Tour Spotlight Positioning
- Tour Anchor System
- Share Sheet Export
- Claude Project Instructions
- Goals View & Model
- App Branding Assets
- Binding
- ModelContainer
- Account
- Bool
- String
- Bool
- ModelContainer
- String
- Account
- Bool
- Date
- Never
- String
- Task
- Transaction
- Void
- Account
- Binding
- Bool
- Date
- String
- Account
- Bool
- Budget
- Date
- Set
- String
- Transaction
- Bool
- Int
- String
- Transaction
- Account
- Bool
- Set
- String
- Transaction
- Date
- Goal
- String
- View
- Bool
- Date
- Int
- String
- CGFloat
- CGRect
- Context
- Void
- CGFloat
- CGRect
- CGRect
- Bool
- CGFloat
- Date
- DateFormatter
- String
- URL
- Bool
- Budget
- Goal
- Int
- LocalizedStringKey
- PersistentIdentifier
- Transaction
- Bool
- Int
- String
- Void
- Bool
- Context
- Date
- Int
- LocalizedStringKey
- String
- Transaction
- URL
- Date
- ModelContext
- Never
- Notification
- Task
- UUID
- Bool
- CGFloat
- Content
- Date
- LocalizedStringKey
- String
- Transaction
- View
- Void
- Binding
- Bool
- Int
- Transaction
- Void
- Never
- Task
- Account
- Date
- Account
- Set
- PersistentIdentifier
- Int
- LocalizedStringKey
- Category
- Decimal
- Int
- Void
- NSCoder
- UITabBar
- UIView
- UIViewRepresentable
- UIWindow
- URL

## God Nodes (most connected - your core abstractions)
1. `View` - 38 edges
2. `CodingKeys` - 32 edges
3. `SwiftData` - 31 edges
4. `SyncService` - 28 edges
5. `Date` - 27 edges
6. `Foundation` - 25 edges
7. `Double` - 24 edges
8. `TransactionsView` - 22 edges
9. `Decimal` - 21 edges
10. `TourManager` - 20 edges

## Surprising Connections (you probably didn't know these)
- `MoneyTracker.pdf — Documento Distribuibile` --references--> `MoneyTracker.md — Documento Master`  [EXTRACTED]
  docs/MoneyTracker.pdf → docs/MoneyTracker.md
- `MoneyTrackerMigrationPlan` --calls--> `Decimal`  [INFERRED]
  MoneyTracker/Persistence/SchemaMigration.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `ContentView` --references--> `View`  [EXTRACTED]
  MoneyTracker/Views/ContentView.swift → MoneyTracker/Views/Theme.swift
- `ModalCard` --references--> `View`  [EXTRACTED]
  MoneyTracker/OnboardingTour/TourOverlayView.swift → MoneyTracker/Views/Theme.swift
- `StepCard` --references--> `View`  [EXTRACTED]
  MoneyTracker/OnboardingTour/TourOverlayView.swift → MoneyTracker/Views/Theme.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flusso automazione notturna XCUITest** — docs_moneytracker_md_automazione_notturna, report_notturno_md_doc, moneytrackeruitests_categoryflowuitests, moneytrackeruitests_navigationstressuitests, moneytrackeruitests_tourflowuitests [INFERRED 0.85]
- **Fix trasferimenti: eliminazione e modifica** — moneytracker_views_transactionsview, moneytracker_views_addtransferview, moneytracker_models_transaction, docs_moneytracker_md_bug_transfer_delete_dialog, docs_moneytracker_md_feature_transfer_edit [EXTRACTED 1.00]
- **Sistema tour onboarding a due livelli** — moneytracker_onboardingtour_tourmanager, moneytracker_onboardingtour_touroverlayview, moneytracker_onboardingtour_contextualhint, moneytracker_onboardingtour_tourstep, moneytracker_moneytrackerapp [EXTRACTED 1.00]

## Communities (151 total, 117 thin omitted)

### Community 0 - "Account Management UI"
Cohesion: 0.07
Nodes (49): AccountType, Content, ContextualHint, DS namespace / componenti riutilizzabili, LocalizedStringKey, HintCard, AccountRow, AccountsView (+41 more)

### Community 1 - "QA Automation & UITests"
Cohesion: 0.08
Nodes (21): Automazione notturna (run_nightly_tests.sh + LaunchAgent), Changelog: riorganizzazione struttura e documentazione, Changelog: XCUITest e automazione notturna, QA: tour onboarding verificato end-to-end (TourFlowUITests, 17 step), AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, String (+13 more)

### Community 2 - "Authentication Views"
Cohesion: 0.05
Nodes (38): Hashable, AuthField, LoginView, Bool, Error, String, SignUpView, Bool (+30 more)

### Community 3 - "Account Data Model"
Cohesion: 0.08
Nodes (37): CaseIterable, Category, Account, AccountType, carta, contanti, conto, investimento (+29 more)

### Community 4 - "Cloud Sync (Supabase)"
Cohesion: 0.10
Nodes (29): Connessione bancaria automatica (GoCardless/Nordigen), Equatable, ModelContext, SBAccount, SBBudget, SBGoal, SBTransaction, Account (+21 more)

### Community 5 - "Balance Caching & Date Helpers"
Cohesion: 0.07
Nodes (23): MoneyTracker, AccountBalanceCache, Account, PersistentIdentifier, Date, Decimal, Bool, String (+15 more)

### Community 6 - "Budget View & History"
Cohesion: 0.10
Nodes (25): Identifiable, AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget, Category (+17 more)

### Community 7 - "Demo Data Seeding"
Cohesion: 0.06
Nodes (33): CodingKey, DemoDataSeeder, ModelContext, CodingKeys, accountId, amount, category, categoryIcon (+25 more)

### Community 8 - "SwiftData Schema Migration"
Cohesion: 0.17
Nodes (20): MigrationStage, Double, Account, Budget, DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+12 more)

### Community 9 - "Siri Shortcuts Intents"
Cohesion: 0.10
Nodes (25): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, AddIncomeIntent (Apple Shortcuts), Bug: transazioni create via Siri/tocco posteriore sparivano dopo il salvataggio, i18n-01: sezione Siri non tradotta in nessuna lingua, SEC-01: try! su ModelContainer in Shortcuts causava crash estensione (+17 more)

### Community 10 - "Biometric App Lock"
Cohesion: 0.09
Nodes (17): AppLockGate, AppLockState, LockOverlay, Bool, Content, View, Void, View (+9 more)

### Community 11 - "Tour State Management"
Cohesion: 0.11
Nodes (15): ContextualHint, movimentiSection, Bool, CGFloat, LocalizedStringKey, Bool, Int, String (+7 more)

### Community 12 - "Settings & Data Export"
Cohesion: 0.20
Nodes (20): Codable, Int, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport (+12 more)

### Community 13 - "PDF Report Generation"
Cohesion: 0.27
Nodes (14): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+6 more)

### Community 14 - "Domain Services Overview"
Cohesion: 0.16
Nodes (6): AnyObject, Foundation, NotificationScheduling, RecurringTransactionActor, OSLog, SwiftData

### Community 15 - "Category Auto-Classification"
Cohesion: 0.18
Nodes (10): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, Logger, KeywordCategoryClassifierTests, NSCache (+2 more)

### Community 16 - "Product Roadmap"
Cohesion: 0.10
Nodes (22): Differenziatori chiave (italiana, offline, una tantum, privacy, minimale), MoneyTracker.md — Documento Master, Idea centrale: app unica di finanza personale, Modello di business (TestFlight → App Store 4,99€ → Premium 1,99€/mese), Roadmap (Livello 2–4), AI Financial Coach (report mensile, sintesi Claude Haiku), Apple Watch App (watchOS + WatchConnectivity), Calendario flusso di cassa (proiezione saldo giorno per giorno) (+14 more)

### Community 17 - "Audit Logging"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 18 - "Transfer Entry & Dashboard"
Cohesion: 0.13
Nodes (14): Account, Date, AddTransferView, Binding, Bool, String, Transaction, DashboardView (+6 more)

### Community 19 - "Local Notifications"
Cohesion: 0.16
Nodes (8): Bool, Decimal, Double, Int, ModelContext, String, SystemNotificationManager, NotificationScheduling

### Community 20 - "Onboarding Tour Overlay"
Cohesion: 0.19
Nodes (10): Combine, Bug correlato: trigger mini-tour solo su onChange(selectedTab), Bug: TourOverlayView montata solo se isActive → mini-tour Livello 2 mai mostrati, Changelog: fix mini-tour contestuali che non comparivano mai, Changelog: fix tocco posteriore/Siri — transazioni sparivano dopo salvataggio, Nuovo mini-tour hint.goalsList per sezione Obiettivi, ModalCard, StepCard (+2 more)

### Community 21 - "Formatting Cache & Version History"
Cohesion: 0.13
Nodes (11): Charts, BUG-03: CategoryStat.id UUID instabile rompeva diffing SwiftUI, Pattern architetturali (Singleton, NSCache, Transferable, AppStorage, UserDefaults), PERF-01: allocazione NumberFormatter/DateFormatter per ogni render, v1: Base (transazioni, categorie, saldo singolo conto), v2: Feature complete (conti multipli, trasferimenti, budget, obiettivi), v3: Enterprise audit (43 miglioramenti su 6 aree), FormatterCache (+3 more)

### Community 22 - "Quality Audit Findings"
Cohesion: 0.14
Nodes (12): Audit Qualità Score 7.2/10, BUG-01: DashboardView List+frame fisso → testo troncato, BUG-04: print() debug in TabBarFrameCapture su hot-path, i18n-02: accessibility labels in italiano hard-coded, PERF-02: € hardcoded in AddAccountView e AddTransferView, PERF-R01: Account.currentBalance O(n_tx), scala male oltre 5000 tx, PERF-R02: @Query senza fetchLimit in DashboardView, SEC-02: NotificationManager.isEnabled non verifica autorizzazione OS (+4 more)

### Community 23 - "Recurring Series Detection"
Cohesion: 0.23
Nodes (11): RecurringSeries, RecurringSeriesDetector, Bool, Decimal, Int, String, Transaction, RecurringSeriesDetailView (+3 more)

### Community 24 - "Fixed Items & Transfers Changelog"
Cohesion: 0.21
Nodes (11): Bug: bottone Elimina swipe ereditava tint sbagliato in dark mode, Bug: motore ricorrenze generava duplicato per il periodo del template, Bug: tastiera ricerca Movimenti ricompariva da sola tornando all'hub, Bug: dialog conferma eliminazione trasferimento agganciato alla vista sbagliata, Changelog: colori semantici, fix ricorrenze, tour a due livelli riscritto, Changelog: card "Fissi del mese" + tour testato end-to-end, Changelog: fix eliminazione + nuova modalità modifica trasferimenti, DS.positive/DS.negative/DS.signColor(_:) — colori semantici segno (+3 more)

### Community 25 - "Category Model & Persistence"
Cohesion: 0.23
Nodes (10): Category, Bool, Date, Int, String, UUID, ModelContext, Bool (+2 more)

### Community 26 - "Pianifica Budget/Goals View"
Cohesion: 0.21
Nodes (11): PianificaView, Bool, Budget, Decimal, Double, Goal, Int, LocalizedStringKey (+3 more)

### Community 27 - "App Bootstrap & File Protection"
Cohesion: 0.22
Nodes (9): App, FileProtectionType, applyFileProtection(), MoneyTrackerApp, Bool, ModelContainer, String, URL (+1 more)

### Community 28 - "Tour Spotlight Positioning"
Cohesion: 0.47
Nodes (7): Anchor, CGRect, GeometryProxy, Bool, CGFloat, String, TourOverlayView

### Community 29 - "Tour Anchor System"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 30 - "Share Sheet Export"
Cohesion: 0.38
Nodes (5): Any, Context, ShareSheet, UIActivityViewController, UIViewControllerRepresentable

### Community 31 - "Claude Project Instructions"
Cohesion: 0.40
Nodes (5): Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit, Struttura cartella immutabile (regola), Istruzioni Graphify (query/--update), CLAUDE.md — Istruzioni per Claude, Workflow checkpoint (CLAUDE.md, 5 step: audit → doc → PDF → commit → graphify)

### Community 33 - "App Branding Assets"
Cohesion: 1.00
Nodes (3): AppIcon Light 1024 — App Icon (Light Variant), Light Theme Branding — white/grey palette, minimalist design language, Visual Metaphor: Combined Bar + Line Chart with dot markers

## Knowledge Gaps
- **78 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+73 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **117 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Domain Services Overview` to `Goals View & Model`, `Account Management UI`, `Cloud Sync (Supabase)`, `Balance Caching & Date Helpers`, `SwiftData Schema Migration`, `Siri Shortcuts Intents`, `Settings & Data Export`, `Onboarding Tour Overlay`, `Formatting Cache & Version History`, `Quality Audit Findings`, `Fixed Items & Transfers Changelog`?**
  _High betweenness centrality (0.203) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Domain Services Overview` to `Goals View & Model`, `Cloud Sync (Supabase)`, `Balance Caching & Date Helpers`, `SwiftData Schema Migration`, `Siri Shortcuts Intents`, `Biometric App Lock`, `Formatting Cache & Version History`, `Quality Audit Findings`, `Fixed Items & Transfers Changelog`?**
  _High betweenness centrality (0.095) - this node is a cross-community bridge._
- **Why does `View` connect `Account Management UI` to `Budget View & History`, `Settings & Data Export`, `Audit Logging`, `Transfer Entry & Dashboard`, `Onboarding Tour Overlay`, `Recurring Series Detection`, `Pianifica Budget/Goals View`, `App Bootstrap & File Protection`, `Tour Spotlight Positioning`?**
  _High betweenness centrality (0.076) - this node is a cross-community bridge._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _84 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Account Management UI` be split into smaller, more focused modules?**
  _Cohesion score 0.06623376623376623 - nodes in this community are weakly interconnected._
- **Should `QA Automation & UITests` be split into smaller, more focused modules?**
  _Cohesion score 0.08350168350168351 - nodes in this community are weakly interconnected._
- **Should `Authentication Views` be split into smaller, more focused modules?**
  _Cohesion score 0.05224963715529753 - nodes in this community are weakly interconnected._