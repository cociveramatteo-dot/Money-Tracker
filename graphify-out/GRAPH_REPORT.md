# Graph Report - .  (2026-07-08)

## Corpus Check
- 18 files · ~52,557 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 922 nodes · 1570 edges · 130 communities (39 shown, 91 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 67 edges (avg confidence: 0.79)
- Token cost: 90,000 input · 8,979 output

## Community Hubs (Navigation)
- Views Theme
- Views Transactionsview
- Sync Syncservice
- Models
- Persistence Schemamigration
- Onboardingtour Tourstep
- Auth Applockgate
- Sync Syncservice
- Uitestsupport Moneyt
- Models
- Views Statisticsview
- Moneytracker Accountsview
- Intents Addexpenseintent
- Export Pdfreportgenerator
- Views Settingsview
- Domain Keywordcategoryclass
- Domain Auditlogger
- Auth Loginview
- Onboardingtour Tabbarframec
- Views Addtransactionview
- Domain Notificationmanager
- Views Budgetview
- Views Pianificaview
- Views Categorymanagementvie
- Moneytracker Nightly
- Views Accountsview
- Onboardingtour Touroverlayv
- Moneytracker Model
- Moneytracker Applockgate
- Moneytracker Model
- Onboardingtour Tourhighligh
- Views Goalsview
- Auth Signupview
- Views Contentview
- Claude Md Checkpoint
- Moneytracker Bug01
- Moneytracker Bug03
- Moneytracker I18n01
- Assets Xcassets
- Accountsview
- Accountsview
- Accountsview
- Addexpenseintent
- Addexpenseintent Modelconta
- Addexpenseintent
- Addtransactionview
- Addtransactionview
- Addtransactionview
- Addtransactionview
- Addtransactionview
- Addtransactionview
- Addtransactionview
- Addtransactionview
- Addtransferview
- Addtransferview Binding
- Addtransferview
- Addtransferview
- Addtransferview
- Budgetview
- Budgetview
- Budgetview
- Budgetview
- Budgetview
- Budgetview
- Budgetview
- Categorymanagementview
- Categorymanagementview
- Categorymanagementview
- Categorymanagementview
- Dashboardview
- Dashboardview
- Dashboardview
- Dashboardview
- Dashboardview
- Goalsview
- Goalsview
- Goalsview
- Moneytrackerapp Modelcontai
- Moneytrackerapp Url
- Notificationmanager
- Notificationmanager
- Notificationmanager
- Notificationmanager
- Pdfreportgenerator
- Pdfreportgenerator Cgfloat
- Pdfreportgenerator
- Pdfreportgenerator Dateform
- Pdfreportgenerator
- Pdfreportgenerator Url
- Pianificaview
- Pianificaview
- Pianificaview
- Pianificaview
- Pianificaview Localizedstri
- Pianificaview Persistentide
- Pianificaview
- Settingsview
- Settingsview
- Settingsview
- Settingsview
- Statisticsview
- Statisticsview Context
- Statisticsview
- Statisticsview
- Statisticsview Localizedstr
- Statisticsview
- Statisticsview
- Statisticsview Url
- Sync Syncservice
- Theme
- Theme Cgfloat
- Theme Content
- Theme
- Theme Localizedstringkey
- Theme
- Theme
- Theme View
- Theme
- Transactionsview Binding
- Transactionsview
- Transactionsview
- Transactionsview
- Transactionsview
- Views Addtransactionview
- Views Addtransactionview
- Views Budgetview
- Views Pianificaview
- Views Pianificaview
- Views Transactionsview

## God Nodes (most connected - your core abstractions)
1. `MoneyTracker — Documento Completo` - 73 edges
2. `CodingKeys` - 32 edges
3. `SwiftData` - 30 edges
4. `TourStep` - 27 edges
5. `SyncService` - 27 edges
6. `Foundation` - 24 edges
7. `Double` - 24 edges
8. `Date` - 22 edges
9. `Decimal` - 21 edges
10. `View` - 21 edges

## Surprising Connections (you probably didn't know these)
- `MoneyTrackerMigrationPlan` --calls--> `Decimal`  [INFERRED]
  MoneyTracker/Persistence/SchemaMigration.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `Goal` --references--> `Double`  [EXTRACTED]
  MoneyTracker/Models/Goal.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `Account` --references--> `Decimal`  [EXTRACTED]
  MoneyTracker/Models/Account.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `Transaction` --references--> `Decimal`  [EXTRACTED]
  MoneyTracker/Models/Transaction.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `StepCard` --references--> `TourStep`  [EXTRACTED]
  MoneyTracker/OnboardingTour/TourOverlayView.swift → MoneyTracker/OnboardingTour/TourStep.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Routine di test notturna automatizzata** — docs_moneytracker_nightly_script, docs_moneytracker_launchagent, docs_moneytracker_claude_code_headless, docs_moneytracker_report_notturno, docs_moneytracker_nightly_pr, docs_moneytracker_xcuitest_target [EXTRACTED 1.00]
- **Suite XCUITest MoneyTrackerUITests** — docs_moneytracker_uitestsupport, docs_moneytracker_transactionflowuitests, docs_moneytracker_accountflowuitests, docs_moneytracker_categoryflowuitests, docs_moneytracker_navigationstressuitests [EXTRACTED 1.00]
- **Ecosistema sync cross-device e famiglia** — docs_moneytracker_supabase, docs_moneytracker_sync_crossdevice, docs_moneytracker_modalita_coppia, docs_moneytracker_syncservice [INFERRED 0.75]

## Communities (130 total, 91 thin omitted)

### Community 0 - "Views Theme"
Cohesion: 0.06
Nodes (48): Content, AddTransferView, Account, Binding, Bool, String, DashboardView, HomeAccountOrderSheet (+40 more)

### Community 1 - "Views Transactionsview"
Cohesion: 0.07
Nodes (36): Binding, CaseIterable, Account, AccountType, carta, contanti, conto, investimento (+28 more)

### Community 2 - "Sync Syncservice"
Cohesion: 0.10
Nodes (29): Equatable, SBAccount, SBBudget, SBGoal, SBTransaction, Account, Bool, Budget (+21 more)

### Community 3 - "Models"
Cohesion: 0.07
Nodes (22): AnyObject, Foundation, MoneyTracker, NotificationScheduling, RecurringTransactionActor, FormatterCache, DateFormatter, String (+14 more)

### Community 4 - "Persistence Schemamigration"
Cohesion: 0.14
Nodes (22): MigrationStage, Double, Account, Budget, DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+14 more)

### Community 5 - "Onboardingtour Tourstep"
Cohesion: 0.07
Nodes (27): Int, Bool, CGFloat, CGRect, Int, TourManager, Bool, CGFloat (+19 more)

### Community 6 - "Auth Applockgate"
Cohesion: 0.08
Nodes (23): App, Combine, FileProtectionType, ModelContainer, AppLockGate, AppLockState, LockOverlay, Bool (+15 more)

### Community 7 - "Sync Syncservice"
Cohesion: 0.06
Nodes (33): CodingKey, DemoDataSeeder, ModelContext, CodingKeys, accountId, amount, category, categoryIcon (+25 more)

### Community 8 - "Uitestsupport Moneyt"
Cohesion: 0.12
Nodes (11): AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, TransactionFlowUITests, MoneyTrackerUITestCase, String, StaticString, UInt (+3 more)

### Community 9 - "Models"
Cohesion: 0.10
Nodes (19): AccountBalanceCache, Account, PersistentIdentifier, Date, Decimal, Bool, String, Budget (+11 more)

### Community 10 - "Views Statisticsview"
Cohesion: 0.14
Nodes (18): Any, Context, Identifiable, CategoryStat, Date, MonthStat, ShareSheet, StatisticsView (+10 more)

### Community 11 - "Moneytracker Accountsview"
Cohesion: 0.08
Nodes (30): AccountsView (Conti), AddExpenseIntent (Shortcuts Apple), AddTransactionView, AddTransferView, MoneyTracker App, AppIntents Framework (Shortcuts/Siri), Audit Qualità (Score 7.2/10), BudgetView (+22 more)

### Community 12 - "Intents Addexpenseintent"
Cohesion: 0.13
Nodes (19): AppIntent, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, IntentResult, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+11 more)

### Community 13 - "Export Pdfreportgenerator"
Cohesion: 0.24
Nodes (14): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+6 more)

### Community 14 - "Views Settingsview"
Cohesion: 0.21
Nodes (20): Codable, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport (+12 more)

### Community 15 - "Domain Keywordcategoryclass"
Cohesion: 0.18
Nodes (9): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, KeywordCategoryClassifierTests, NSCache, NSString (+1 more)

### Community 16 - "Domain Auditlogger"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 17 - "Auth Loginview"
Cohesion: 0.13
Nodes (11): AuthField, LoginView, Bool, Error, String, SupabaseManager, Bool, String (+3 more)

### Community 18 - "Onboardingtour Tabbarframec"
Cohesion: 0.20
Nodes (11): CapView, CGFloat, CGRect, Context, Void, TabBarFrameCapture, NSCoder, UITabBar (+3 more)

### Community 19 - "Views Addtransactionview"
Cohesion: 0.12
Nodes (16): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView, Account, Bool (+8 more)

### Community 20 - "Domain Notificationmanager"
Cohesion: 0.16
Nodes (8): Bool, Decimal, Double, Int, ModelContext, String, SystemNotificationManager, NotificationScheduling

### Community 21 - "Views Budgetview"
Cohesion: 0.19
Nodes (13): AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget, Category, Date (+5 more)

### Community 22 - "Views Pianificaview"
Cohesion: 0.21
Nodes (11): LocalizedStringKey, PianificaView, Bool, Budget, Decimal, Double, Goal, Int (+3 more)

### Community 23 - "Views Categorymanagementvie"
Cohesion: 0.24
Nodes (8): AddCategoryView, CategoryManagementView, CategoryRow, Bool, Category, Int, String, Transaction

### Community 24 - "Moneytracker Nightly"
Cohesion: 0.18
Nodes (12): AccountFlowUITests, CategoryFlowUITests, Claude Code headless auto-fix, com.moneytracker.nightlytests.plist (LaunchAgent), NavigationStressUITests, Pull Request automatica notturna, run_nightly_tests.sh, report_notturno.md (+4 more)

### Community 25 - "Views Accountsview"
Cohesion: 0.25
Nodes (8): AccountType, AccountRow, AccountsView, AddAccountView, Account, Bool, Decimal, String

### Community 26 - "Onboardingtour Touroverlayv"
Cohesion: 0.27
Nodes (9): Anchor, GeometryProxy, ModalCard, StepCard, CGFloat, CGRect, String, TourOverlayView (+1 more)

### Community 27 - "Moneytracker Model"
Cohesion: 0.22
Nodes (10): Account Model, AI Financial Coach (Claude Haiku API), Connessione bancaria automatica (GoCardless/Nordigen), Budget Model, Punteggio Salute Finanziaria (0-100), Goal Model, Tracciatore Patrimonio Netto, NotificationManager (+2 more)

### Community 28 - "Moneytracker Applockgate"
Cohesion: 0.25
Nodes (9): AppLockGate (Biometria Face ID/Touch ID), BUG-04 print() debug in TabBarFrameCapture, MoneyTrackerApp.isUITesting (--uitesting flag), Modalità Coppia/Famiglia, Onboarding Tour, Supabase Cloud Sync, SupabaseManager (client, auth, sync), Sync cross-device (Supabase, offline-first) (+1 more)

### Community 29 - "Moneytracker Model"
Cohesion: 0.25
Nodes (8): Calendario flusso di cassa, Category Model, Feature fiscali italiane (F24, 730, TFR, Detrazioni), RecurringTransactionEngine, Split spese (contatti + iMessage/WhatsApp), Tracker abbonamenti, Transaction Model, v2 Feature complete (primavera 2026)

### Community 30 - "Onboardingtour Tourhighligh"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 31 - "Views Goalsview"
Cohesion: 0.36
Nodes (5): AddGoalView, GoalRow, Date, Goal, String

### Community 32 - "Auth Signupview"
Cohesion: 0.38
Nodes (4): SignUpView, Bool, Error, String

### Community 34 - "Claude Md Checkpoint"
Cohesion: 0.67
Nodes (3): Checkpoint Workflow, Graphify Knowledge Graph Workflow, MoneyTracker Project (CLAUDE.md)

### Community 35 - "Moneytracker Bug01"
Cohesion: 0.67
Nodes (3): BUG-01 DashboardView List + Dynamic Type, DashboardView (Home), PERF-R02 @Query senza fetchLimit in DashboardView

### Community 36 - "Moneytracker Bug03"
Cohesion: 0.67
Nodes (3): BUG-03 CategoryStat.id instabile, PDFReportGenerator, StatisticsView (Statistiche)

### Community 37 - "Moneytracker I18n01"
Cohesion: 0.67
Nodes (3): i18n-01 Sezione Siri non tradotta, i18n-02 Accessibility labels hard-coded, Localizzazione (7 lingue)

### Community 38 - "Assets Xcassets"
Cohesion: 1.00
Nodes (3): AppIcon Light 1024 — App Icon (Light Variant), Light Theme Branding — white/grey palette, minimalist design language, Visual Metaphor: Combined Bar + Line Chart with dot markers

## Knowledge Gaps
- **88 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+83 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **91 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Models` to `Views Theme`, `Views Transactionsview`, `Sync Syncservice`, `Views Contentview`, `Persistence Schemamigration`, `Auth Applockgate`, `Views Statisticsview`, `Intents Addexpenseintent`, `Views Settingsview`, `Views Addtransactionview`, `Views Budgetview`, `Views Categorymanagementvie`, `Views Accountsview`, `Views Goalsview`?**
  _High betweenness centrality (0.242) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Models` to `Views Transactionsview`, `Sync Syncservice`, `Persistence Schemamigration`, `Auth Applockgate`, `Models`, `Intents Addexpenseintent`, `Domain Keywordcategoryclass`?**
  _High betweenness centrality (0.091) - this node is a cross-community bridge._
- **Why does `Date` connect `Views Statisticsview` to `Views Theme`, `Sync Syncservice`, `Export Pdfreportgenerator`, `Domain Auditlogger`, `Domain Notificationmanager`?**
  _High betweenness centrality (0.057) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `TourStep` (e.g. with `.next()` and `.previous()`) actually correct?**
  _`TourStep` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _91 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Views Theme` be split into smaller, more focused modules?**
  _Cohesion score 0.05565638233514821 - nodes in this community are weakly interconnected._
- **Should `Views Transactionsview` be split into smaller, more focused modules?**
  _Cohesion score 0.06648936170212766 - nodes in this community are weakly interconnected._