# Graph Report - .  (2026-07-15)

## Corpus Check
- 7 files · ~57,650 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 989 nodes · 1656 edges · 174 communities (37 shown, 137 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 71 edges (avg confidence: 0.81)
- Token cost: 97,721 input · 0 output

## Community Hubs (Navigation)
- Account Balance Cache & Migration
- Onboarding Tour Overlay
- App Entry Point & File Protection
- Login & Supabase Auth
- Account & Category Models
- SyncService & Supabase Models
- Budget View & History
- Domain Services (Audit/Notifications/Classifier)
- UI Tests: Account & Category Flows
- Demo Data Seeding
- App Lock (Biometric Gate)
- Shortcuts / Siri App Intents
- PDF Report Generation
- Keyword Category Classifier
- Settings View & Data Export
- Audit Logger
- System Notification Manager
- Budget/Goal Add Views & i18n Bugs
- Pianifica View (Budget/Goal Tab)
- Category Seeding & Migration
- Recurring Series Detector
- Transfer Creation & Edit (AddTransferView)
- Dashboard View & Semantic Colors
- Nightly UI Test Automation
- Dashboard Account Ordering
- Accounts/Budget/Goals Views & Bugs
- Transactions & Transfers Overview
- Onboarding Tour Manager & Hints
- Product Vision & Account/Budget Models
- Tour Anchor Preference Key
- Share Sheet (UIActivityViewController)
- CLAUDE.md Workflow & Quality Gate
- Sync Dirty-Flag Fix & Siri Intents
- AI Financial Coach & Health Score
- Couple Mode & Cross-Device Sync
- App Icon & Visual Branding
- Binding
- AppIntents framework
- Apple Watch App (watchOS + WatchConnectivity)
- AppLockGate (biometric lock)
- AppStorage persistence pattern
- Calendario flusso di cassa
- Category model
- CategoryClassifier.resultCache (NSCache)
- CSVFile (Transferable)
- Goal model
- Haptic Feedback pattern
- Feature fiscali italiane (F24, 730, TFR, detrazioni)
- Tracciatore Patrimonio Netto
- NSFileProtectionComplete
- OSLog logging
- PDFReportGenerator
- Split spese
- Swift 6.0 strict concurrency
- SwiftData
- SwiftUI
- UserDefaults persistence pattern
- UserNotifications
- Widget Home/Lock Screen (WidgetKit + AppGroup)
- LocalizedStringKey
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
- PersistentIdentifier
- Date
- Category
- Decimal
- Int
- Void
- NSCoder
- Set
- UITabBar
- UIView
- UIViewRepresentable
- UIWindow
- URL

## God Nodes (most connected - your core abstractions)
1. `View` - 37 edges
2. `CodingKeys` - 32 edges
3. `Date` - 32 edges
4. `SwiftData` - 31 edges
5. `SyncService` - 28 edges
6. `Foundation` - 25 edges
7. `Double` - 24 edges
8. `TransactionsView` - 22 edges
9. `Decimal` - 21 edges
10. `TourManager` - 20 edges

## Surprising Connections (you probably didn't know these)
- `Tentativo 1 fallito (UI test failures)` --references--> `accessibilityIdentifier su elementi interattivi`  [INFERRED]
  report_notturno.md → docs/MoneyTracker.md
- `MoneyTracker.pdf — Documento Distribuibile` --references--> `MoneyTracker.md — Documento Master`  [EXTRACTED]
  docs/MoneyTracker.pdf → docs/MoneyTracker.md
- `Report notturno 14/07/2026` --references--> `TransactionFlowUITests`  [INFERRED]
  report_notturno.md → docs/MoneyTracker.md
- `Report notturno 14/07/2026` --references--> `AccountFlowUITests`  [INFERRED]
  report_notturno.md → docs/MoneyTracker.md
- `Report notturno 14/07/2026` --references--> `CategoryFlowUITests`  [INFERRED]
  report_notturno.md → docs/MoneyTracker.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Onboarding Tour System Components** — docs_moneytracker_tourmanager, docs_moneytracker_touroverlayview, docs_moneytracker_tabbarframecapture, docs_moneytracker_contextualhint, docs_moneytracker_tourstep [EXTRACTED 1.00]
- **Nightly Automated Test & Auto-Fix Pipeline** — docs_moneytracker_launchagent_nightlytests, docs_moneytracker_run_nightly_tests_script, docs_moneytracker_moneytrackeruitests_target, report_notturno_report [INFERRED 0.85]
- **Theme.swift Design System Components** — docs_moneytracker_theme_design_system, docs_moneytracker_heroamount, docs_moneytracker_sectionlabel, docs_moneytracker_primarybutton, docs_moneytracker_ghostbutton, docs_moneytracker_thindivider, docs_moneytracker_dstransactionrow, docs_moneytracker_monthbar, docs_moneytracker_emptystateview [EXTRACTED 1.00]

## Communities (174 total, 137 thin omitted)

### Community 0 - "Account Balance Cache & Migration"
Cohesion: 0.07
Nodes (35): MigrationStage, AccountBalanceCache, Account, PersistentIdentifier, Date, Decimal, Double, Bool (+27 more)

### Community 1 - "Onboarding Tour Overlay"
Cohesion: 0.06
Nodes (54): AccountType, Anchor, CGRect, Content, GeometryProxy, HintCard, ModalCard, StepCard (+46 more)

### Community 2 - "App Entry Point & File Protection"
Cohesion: 0.05
Nodes (31): App, Combine, FileProtectionType, applyFileProtection(), MoneyTrackerApp, Bool, ModelContainer, String (+23 more)

### Community 3 - "Login & Supabase Auth"
Cohesion: 0.05
Nodes (38): Hashable, AuthField, LoginView, Bool, Error, String, SignUpView, Bool (+30 more)

### Community 4 - "Account & Category Models"
Cohesion: 0.08
Nodes (37): CaseIterable, Category, Account, AccountType, carta, contanti, conto, investimento (+29 more)

### Community 5 - "SyncService & Supabase Models"
Cohesion: 0.10
Nodes (28): Equatable, ModelContext, SBAccount, SBBudget, SBGoal, SBTransaction, Account, Bool (+20 more)

### Community 6 - "Budget View & History"
Cohesion: 0.09
Nodes (27): Charts, Identifiable, AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget (+19 more)

### Community 7 - "Domain Services (Audit/Notifications/Classifier)"
Cohesion: 0.08
Nodes (17): AnyObject, Foundation, MoneyTracker, NotificationScheduling, RecurringTransactionActor, FormatterCache, DateFormatter, String (+9 more)

### Community 8 - "UI Tests: Account & Category Flows"
Cohesion: 0.12
Nodes (12): Int, AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, TransactionFlowUITests, MoneyTrackerUITestCase, String, StaticString (+4 more)

### Community 9 - "Demo Data Seeding"
Cohesion: 0.06
Nodes (33): CodingKey, DemoDataSeeder, ModelContext, CodingKeys, accountId, amount, category, categoryIcon (+25 more)

### Community 10 - "App Lock (Biometric Gate)"
Cohesion: 0.09
Nodes (17): AppLockGate, AppLockState, LockOverlay, Bool, Content, View, Void, View (+9 more)

### Community 11 - "Shortcuts / Siri App Intents"
Cohesion: 0.12
Nodes (20): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, IntentResult, LocalizedStringResource, AccountOptionsProvider (+12 more)

### Community 12 - "PDF Report Generation"
Cohesion: 0.26
Nodes (14): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+6 more)

### Community 13 - "Keyword Category Classifier"
Cohesion: 0.17
Nodes (10): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, Logger, KeywordCategoryClassifierTests, NSCache (+2 more)

### Community 14 - "Settings View & Data Export"
Cohesion: 0.21
Nodes (19): Codable, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport (+11 more)

### Community 15 - "Audit Logger"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 16 - "System Notification Manager"
Cohesion: 0.16
Nodes (8): Bool, Decimal, Double, Int, ModelContext, String, SystemNotificationManager, NotificationScheduling

### Community 17 - "Budget/Goal Add Views & i18n Bugs"
Cohesion: 0.14
Nodes (16): AddBudgetView, AddGoalView, BUG-03 CategoryStat.id instabile, CheckBalanceIntent, FormatterCache (singleton), i18n-01 sezione Siri non tradotta, i18n-02 accessibility labels hardcoded in italiano, Localizzazione (7 lingue) (+8 more)

### Community 18 - "Pianifica View (Budget/Goal Tab)"
Cohesion: 0.19
Nodes (11): PianificaView, Bool, Budget, Decimal, Double, Goal, Int, LocalizedStringKey (+3 more)

### Community 19 - "Category Seeding & Migration"
Cohesion: 0.23
Nodes (10): Category, Bool, Date, Int, String, UUID, ModelContext, Bool (+2 more)

### Community 20 - "Recurring Series Detector"
Cohesion: 0.31
Nodes (8): RecurringSeries, RecurringSeriesDetector, Bool, Decimal, Int, String, Transaction, TransactionType

### Community 21 - "Transfer Creation & Edit (AddTransferView)"
Cohesion: 0.24
Nodes (7): Account, Date, AddTransferView, Binding, Bool, String, Transaction

### Community 22 - "Dashboard View & Semantic Colors"
Cohesion: 0.18
Nodes (12): BUG-01 DashboardView List/Dynamic Type, DashboardView (Home), DS.signColor / DS.positive / DS.negative, DSTransactionRow component, EmptyStateView component, GhostButton component, HeroAmount component, PERF-R02 @Query senza fetchLimit in DashboardView (+4 more)

### Community 23 - "Nightly UI Test Automation"
Cohesion: 0.35
Nodes (11): AccountFlowUITests, CategoryFlowUITests, com.moneytracker.nightlytests.plist (LaunchAgent), MoneyTrackerUITests target, NavigationStressUITests, report_notturno.md (concetto/output automazione), run_nightly_tests.sh, TransactionFlowUITests (+3 more)

### Community 24 - "Dashboard Account Ordering"
Cohesion: 0.22
Nodes (8): DashboardView, HomeAccountOrderSheet, Account, Bool, Decimal, Set, String, Transaction

### Community 25 - "Accounts/Budget/Goals Views & Bugs"
Cohesion: 0.20
Nodes (10): accessibilityIdentifier su elementi interattivi, AccountsView (Conti), BudgetView, BUG-02 GoalsView.load() mostrava 1000.0, CategoryManagementView, GoalsView (Obiettivi), SettingsView, SMELL-01 sezione vuota bare Text in CategoryManagementView (+2 more)

### Community 26 - "Transactions & Transfers Overview"
Cohesion: 0.22
Nodes (9): AddTransactionView, AddTransferView, PERF-02 € hardcoded in AddAccountView/AddTransferView, RecurringSeriesDetector, RecurringTransactionEngine, Tracker abbonamenti, Transaction model, TransactionsView (Movimenti) (+1 more)

### Community 27 - "Onboarding Tour Manager & Hints"
Cohesion: 0.28
Nodes (9): BUG-04 print() debug in TabBarFrameCapture, ContextualHint (mini-tour Livello 2), MoneyTrackerApp.isUITesting hook, MoneyTrackerApp (entry point), Onboarding Tour (2 livelli), TabBarFrameCapture, TourManager, TourOverlayView (+1 more)

### Community 28 - "Product Vision & Account/Budget Models"
Cohesion: 0.29
Nodes (8): Account model, Connessione bancaria automatica (GoCardless/Nordigen), Budget model, Modello di business (one-time €4,99 + premium futuro), MoneyTracker.md — Documento Master, MoneyTracker.pdf — Documento Distribuibile, PERF-R01 Account.currentBalance O(n_tx), Posizionamento: app italiana di finanza personale

### Community 29 - "Tour Anchor Preference Key"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 30 - "Share Sheet (UIActivityViewController)"
Cohesion: 0.38
Nodes (5): Any, Context, ShareSheet, UIActivityViewController, UIViewControllerRepresentable

### Community 31 - "CLAUDE.md Workflow & Quality Gate"
Cohesion: 0.40
Nodes (5): Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit, Struttura cartella immutabile (regola), Istruzioni Graphify (query/--update), CLAUDE.md — Istruzioni per Claude, Workflow checkpoint (CLAUDE.md, 5 step: audit → doc → PDF → commit → graphify)

### Community 32 - "Sync Dirty-Flag Fix & Siri Intents"
Cohesion: 0.40
Nodes (5): AddExpenseIntent (Shortcuts/Siri), AddIncomeIntent (Shortcuts/Siri), SEC-01 try! su ModelContainer causava crash estensione, SyncService, SyncService.markTransactionDirty(_:) fix

### Community 33 - "AI Financial Coach & Health Score"
Cohesion: 0.67
Nodes (3): AI Financial Coach, Punteggio Salute Finanziaria, "Me lo posso permettere?" shortcut conversazionale

### Community 34 - "Couple Mode & Cross-Device Sync"
Cohesion: 0.67
Nodes (3): Modalità Coppia/Famiglia, Sync cross-device (Supabase), Supabase (cloud sync)

### Community 35 - "App Icon & Visual Branding"
Cohesion: 1.00
Nodes (3): AppIcon Light 1024 — App Icon (Light Variant), Light Theme Branding — white/grey palette, minimalist design language, Visual Metaphor: Combined Bar + Line Chart with dot markers

## Knowledge Gaps
- **106 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+101 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **137 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Domain Services (Audit/Notifications/Classifier)` to `Account Balance Cache & Migration`, `Onboarding Tour Overlay`, `App Entry Point & File Protection`, `Login & Supabase Auth`, `Account & Category Models`, `SyncService & Supabase Models`, `Budget View & History`, `Shortcuts / Siri App Intents`, `Settings View & Data Export`, `Pianifica View (Budget/Goal Tab)`, `Transfer Creation & Edit (AddTransferView)`, `Dashboard Account Ordering`?**
  _High betweenness centrality (0.216) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Domain Services (Audit/Notifications/Classifier)` to `Account Balance Cache & Migration`, `App Entry Point & File Protection`, `SyncService & Supabase Models`, `App Lock (Biometric Gate)`, `Shortcuts / Siri App Intents`, `Keyword Category Classifier`, `Recurring Series Detector`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Why does `TransactionsView` connect `Account & Category Models` to `UI Tests: Account & Category Flows`?**
  _High betweenness centrality (0.072) - this node is a cross-community bridge._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _108 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Account Balance Cache & Migration` be split into smaller, more focused modules?**
  _Cohesion score 0.07132867132867132 - nodes in this community are weakly interconnected._
- **Should `Onboarding Tour Overlay` be split into smaller, more focused modules?**
  _Cohesion score 0.057692307692307696 - nodes in this community are weakly interconnected._
- **Should `App Entry Point & File Protection` be split into smaller, more focused modules?**
  _Cohesion score 0.05451127819548872 - nodes in this community are weakly interconnected._