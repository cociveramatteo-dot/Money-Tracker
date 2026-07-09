# Graph Report - .  (2026-07-10)

## Corpus Check
- 27 files · ~56,801 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 993 nodes · 1690 edges · 169 communities (48 shown, 121 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 69 edges (avg confidence: 0.81)
- Token cost: 90,000 input · 14,435 output

## Community Hubs (Navigation)
- Onboarding Tour Overlay & Cards
- Supabase Sync Models (SB*)
- Budget View & History
- XCUITest Suites (Account/Category)
- Demo Data Seeding
- SwiftData Schema Migration
- Contextual Hints (Level 2 tour)
- Recurring Series Detection
- Siri/Shortcuts App Intents
- Supabase Manager & Auth Bootstrap
- Product Vision & Roadmap Features
- PDF Report Generation
- Category Auto-Classification
- Settings & Data Export
- Audit Logger
- Core Domain Utilities
- App Lock Gate (Face ID/Touch ID)
- Transaction Core Types
- Add Transaction Flow
- Account Balance Cache
- Pianifica (Budget+Goals) View
- Account Model & Types
- Semantic Colors & Home Feature Notes
- Category Model & Seeding
- Category Management View
- Enterprise Audit Bug Fixes v3
- Feature Complete Changelog v2
- Changelog v3.x Colors & Recurring Fix
- Login View
- Transaction Model
- Tour Anchor Geometry
- Unit Test Suites (Balance/Category/Migration)
- Siri Intent Sync Fix
- Changelog v1 & Core Models
- Onboarding Tour Fix Changelog
- Tour Anchor Preference Key
- Add Transfer Flow
- Goals View
- Share Sheet (CSV export)
- Project Docs & Checkpoint Workflow
- Sign Up View
- Budget Model
- Currency/Date Formatting Helpers
- Formatter Cache Singleton
- Goal Model
- Commissione Suprema & Nightly Test Automation
- Statistics & PDF Export Feature
- App Icon & Branding Assets
- Add Transaction Feature Note
- AppStorage per preferenze UI (hideBalance, filtri)
- Changelog v3.x: riorganizzazione cartelle e documentazione consolidata
- Feature: Haptic Feedback
- Feature: Localizzazione (7 lingue, 340 chiavi)
- Roadmap Livello 4 — Futuro
- UserDefaults per soglie saldo keyed by account UUID (evita migration SwiftData)
- Int
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
- Date
- PersistentIdentifier
- Date
- Binding
- Decimal
- NSCoder
- Report Notturno 09/07/2026
- Set
- UITabBar
- UIView
- UIViewRepresentable
- UIWindow
- URL

## God Nodes (most connected - your core abstractions)
1. `View` - 46 edges
2. `Date` - 33 edges
3. `CodingKeys` - 32 edges
4. `SwiftData` - 31 edges
5. `SyncService` - 28 edges
6. `Foundation` - 25 edges
7. `Double` - 24 edges
8. `TransactionsView` - 22 edges
9. `Decimal` - 21 edges
10. `TourManager` - 20 edges

## Surprising Connections (you probably didn't know these)
- `Audit Qualità — Score 7.2/10 (5 aree valutate)` --semantically_similar_to--> `Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit`  [INFERRED] [semantically similar]
  docs/MoneyTracker.md → CLAUDE.md
- `Workflow Checkpoint (sezione 11, MoneyTracker.md)` --semantically_similar_to--> `Workflow checkpoint (CLAUDE.md, 5 step: audit → doc → PDF → commit → graphify)`  [INFERRED] [semantically similar]
  docs/MoneyTracker.md → CLAUDE.md
- `Automazione notturna (run_nightly_tests.sh + LaunchAgent, fix automatico via Claude Code headless, report_notturno.md + PR)` --semantically_similar_to--> `Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit`  [INFERRED] [semantically similar]
  docs/MoneyTracker.md → CLAUDE.md
- `Struttura cartella immutabile (regola)` --references--> `MoneyTracker.pdf — Documento Distribuibile`  [EXTRACTED]
  CLAUDE.md → docs/MoneyTracker.pdf
- `CLAUDE.md — Istruzioni per Claude` --references--> `MoneyTracker.pdf — Documento Distribuibile`  [EXTRACTED]
  CLAUDE.md → docs/MoneyTracker.pdf

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Fix duplicazione occorrenze motore ricorrenze vs detector passivo** — docs_moneytracker_model_transaction, docs_moneytracker_file_recurringtransactionengine, docs_moneytracker_file_recurringseriesdetector, docs_moneytracker_changelog_v3x_colori_ricorrenze_tour [EXTRACTED 1.00]
- **Fix sync dirty-flag cross-process (Intents Siri/tocco posteriore)** — docs_moneytracker_file_addexpenseintent, docs_moneytracker_file_syncservice, docs_moneytracker_feature_shortcuts, docs_moneytracker_changelog_v3x_sync_dirty_fix [EXTRACTED 1.00]
- **Fix montaggio overlay tour a due livelli (panoramica + hint contestuali)** — docs_moneytracker_file_touroverlayview, docs_moneytracker_file_contextualhint, docs_moneytracker_file_tourmanager, docs_moneytracker_file_moneytrackerapp, docs_moneytracker_changelog_v3x_minitour_fix [EXTRACTED 1.00]

## Communities (169 total, 121 thin omitted)

### Community 0 - "Onboarding Tour Overlay & Cards"
Cohesion: 0.05
Nodes (62): AccountType, Binding, Content, HintCard, ModalCard, StepCard, AccountRow, AccountsView (+54 more)

### Community 1 - "Supabase Sync Models (SB*)"
Cohesion: 0.10
Nodes (28): Equatable, ModelContext, SBAccount, SBBudget, SBGoal, SBTransaction, Account, Bool (+20 more)

### Community 2 - "Budget View & History"
Cohesion: 0.09
Nodes (27): Charts, Identifiable, AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget (+19 more)

### Community 3 - "XCUITest Suites (Account/Category)"
Cohesion: 0.13
Nodes (11): AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, TransactionFlowUITests, MoneyTrackerUITestCase, String, StaticString, UInt (+3 more)

### Community 4 - "Demo Data Seeding"
Cohesion: 0.06
Nodes (33): CodingKey, DemoDataSeeder, ModelContext, CodingKeys, accountId, amount, category, categoryIcon (+25 more)

### Community 5 - "SwiftData Schema Migration"
Cohesion: 0.17
Nodes (20): MigrationStage, Double, Account, Budget, DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+12 more)

### Community 6 - "Contextual Hints (Level 2 tour)"
Cohesion: 0.10
Nodes (16): ContextualHint, movimentiSection, Bool, CGFloat, LocalizedStringKey, Bool, Int, String (+8 more)

### Community 7 - "Recurring Series Detection"
Cohesion: 0.09
Nodes (20): RecurringSeries, RecurringSeriesDetector, Bool, Decimal, Int, String, Transaction, ContentView (+12 more)

### Community 8 - "Siri/Shortcuts App Intents"
Cohesion: 0.12
Nodes (20): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, IntentResult, LocalizedStringResource, AccountOptionsProvider (+12 more)

### Community 9 - "Supabase Manager & Auth Bootstrap"
Cohesion: 0.10
Nodes (16): App, Combine, FileProtectionType, SupabaseManager, Bool, String, applyFileProtection(), MoneyTrackerApp (+8 more)

### Community 10 - "Product Vision & Roadmap Features"
Cohesion: 0.09
Nodes (26): MoneyTracker (app iOS finanza personale), AppIntents framework (Shortcuts/Siri), Modello di business: una tantum €4,99, no abbonamenti al lancio, Claude Haiku API (sintesi opzionale AI Coach), Feature WOW: AI Financial Coach (report mensile on-device, opzionale Claude Haiku API), Feature WOW: Connessione bancaria automatica (GoCardless/Nordigen), Feature WOW: Calendario flusso di cassa (proiezione saldo giorno per giorno), Feature WOW: Feature fiscali italiane (F24, 730, TFR, bollette) (+18 more)

### Community 11 - "PDF Report Generation"
Cohesion: 0.26
Nodes (14): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+6 more)

### Community 12 - "Category Auto-Classification"
Cohesion: 0.17
Nodes (10): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, Logger, KeywordCategoryClassifierTests, NSCache (+2 more)

### Community 13 - "Settings & Data Export"
Cohesion: 0.21
Nodes (19): Codable, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport (+11 more)

### Community 14 - "Audit Logger"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 15 - "Core Domain Utilities"
Cohesion: 0.18
Nodes (6): AnyObject, Foundation, NotificationScheduling, RecurringTransactionActor, OSLog, SwiftData

### Community 16 - "App Lock Gate (Face ID/Touch ID)"
Cohesion: 0.16
Nodes (11): AppLockGate, AppLockState, LockOverlay, Bool, Content, View, Void, View (+3 more)

### Community 17 - "Transaction Core Types"
Cohesion: 0.16
Nodes (8): Bool, Decimal, Double, Int, ModelContext, String, SystemNotificationManager, NotificationScheduling

### Community 18 - "Add Transaction Flow"
Cohesion: 0.13
Nodes (15): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView, Account, Bool (+7 more)

### Community 19 - "Account Balance Cache"
Cohesion: 0.22
Nodes (6): AccountBalanceCache, Account, PersistentIdentifier, Decimal, String, AccountBalanceTests

### Community 20 - "Pianifica (Budget+Goals) View"
Cohesion: 0.19
Nodes (11): PianificaView, Bool, Budget, Decimal, Double, Goal, Int, LocalizedStringKey (+3 more)

### Community 21 - "Account Model & Types"
Cohesion: 0.18
Nodes (13): CaseIterable, Account, AccountType, carta, contanti, conto, investimento, risparmio (+5 more)

### Community 22 - "Semantic Colors & Home Feature Notes"
Cohesion: 0.16
Nodes (14): EmptyStateView (empty state coerente), HeroAmount (componente importo grande), DS.signColor / DS.positive / DS.negative — unica fonte di verità per colore da segno, Feature: Budget, Feature: Home (Dashboard), Feature: Impostazioni, Feature: Movimenti, BudgetView.swift (+6 more)

### Community 23 - "Category Model & Seeding"
Cohesion: 0.23
Nodes (10): Category, Bool, Date, Int, String, UUID, ModelContext, Bool (+2 more)

### Community 24 - "Category Management View"
Cohesion: 0.24
Nodes (8): AddCategoryView, CategoryManagementView, CategoryRow, Bool, Category, Int, String, Transaction

### Community 25 - "Enterprise Audit Bug Fixes v3"
Cohesion: 0.18
Nodes (13): BUG-01: DashboardView List+frame fisso troncava testo (Dynamic Type) → fix LazyVStack, BUG-02: GoalsView.load() mostrava '1000.0' → fix truncatingRemainder, BUG-03: CategoryStat.id UUID instabile rompeva diffing → fix computed var su name, BUG-04: print() di debug in TabBarFrameCapture (console noise) → fix rimossi 7 print, i18n-01: sezione Siri non tradotta → fix 10 chiavi in 6 file, i18n-02: accessibility labels italiano hard-coded → fix String(localized:), PERF-01: allocazione NumberFormatter/DateFormatter per render → fix FormatterCache singleton, PERF-02: € hardcoded in AddAccountView/AddTransferView → fix Double.currencySymbol (+5 more)

### Community 26 - "Feature Complete Changelog v2"
Cohesion: 0.17
Nodes (13): Changelog v2: Feature complete (conti multipli, trasferimenti, budget, obiettivi), Feature: Conti, Feature: Biometria (Face ID/Touch ID), Feature: Obiettivi, Feature: Ricorrenze Automatiche, Feature: Trasferimenti, AccountsView.swift, AddTransferView.swift (+5 more)

### Community 27 - "Changelog v3.x Colors & Recurring Fix"
Cohesion: 0.22
Nodes (11): Changelog v3.x: colori semantici positivo/negativo, fix ricorrenze, tour a due livelli riscritto, FormatterCache.swift (singleton formatter costosi), KeywordCategoryClassifier.swift, NotificationManager.swift, RecurringSeriesDetector.swift (tab Ricorrenti, sola lettura/analisi), RecurringTransactionEngine.swift, Cartella Domain/, Cartella Formatting/ (+3 more)

### Community 28 - "Login View"
Cohesion: 0.25
Nodes (7): AuthField, LoginView, Bool, Error, String, UIKeyboardType, View

### Community 29 - "Transaction Model"
Cohesion: 0.33
Nodes (8): Account, Bool, Date, UUID, Transaction, TransactionType, entrata, uscita

### Community 30 - "Tour Anchor Geometry"
Cohesion: 0.47
Nodes (7): Anchor, CGRect, GeometryProxy, Bool, CGFloat, String, TourOverlayView

### Community 31 - "Unit Test Suites (Balance/Category/Migration)"
Cohesion: 0.31
Nodes (4): MoneyTracker, SchemaMigrationTests, URL, Testing

### Community 32 - "Siri Intent Sync Fix"
Cohesion: 0.29
Nodes (8): SEC-01: try! su ModelContainer in Shortcuts causava crash estensione → fix try? + guard, Changelog v3.x: fix tocco posteriore/Siri — transazioni sparivano dopo salvataggio (sync dirty flag), Feature: Shortcuts Apple (Siri/Comandi Rapidi), AddExpenseIntent.swift (Shortcuts/Siri), SyncService.swift (Sync Supabase), Cartella Intents/, Cartella Sync/, Setup e Installazione (Xcode, signing, TestFlight-style USB deploy)

### Community 33 - "Changelog v1 & Core Models"
Cohesion: 0.36
Nodes (8): Changelog v1: Base (transazioni, categorie, saldo singolo conto), Cartella Models/, PERF-R01: Account.currentBalance O(n_tx), scala male >5000 tx — Alta v2, Modello Account, Modello Budget, Modello Category, Modello Goal (obiettivo di risparmio), Modello Transaction

### Community 34 - "Onboarding Tour Fix Changelog"
Cohesion: 0.36
Nodes (8): Changelog v3.x: fix mini-tour contestuali che non comparivano mai, Feature: Onboarding Tour (Livello 1 panoramica + Livello 2 hint contestuali), ContextualHint.swift, TabBarFrameCapture.swift, TourManager.swift, TourOverlayView.swift, TourStep.swift, Cartella OnboardingTour/

### Community 35 - "Tour Anchor Preference Key"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 36 - "Add Transfer Flow"
Cohesion: 0.29
Nodes (5): AddTransferView, Account, Binding, Bool, String

### Community 37 - "Goals View"
Cohesion: 0.36
Nodes (5): AddGoalView, GoalRow, Date, Goal, String

### Community 38 - "Share Sheet (CSV export)"
Cohesion: 0.38
Nodes (5): Any, Context, ShareSheet, UIActivityViewController, UIViewControllerRepresentable

### Community 39 - "Project Docs & Checkpoint Workflow"
Cohesion: 0.62
Nodes (7): Struttura cartella immutabile (regola), Istruzioni Graphify (query/--update), CLAUDE.md — Istruzioni per Claude, Workflow checkpoint (CLAUDE.md, 5 step: audit → doc → PDF → commit → graphify), MoneyTracker.pdf — Documento Distribuibile, MoneyTracker.md — Documento Master, Workflow Checkpoint (sezione 11, MoneyTracker.md)

### Community 40 - "Sign Up View"
Cohesion: 0.38
Nodes (4): SignUpView, Bool, Error, String

### Community 41 - "Budget Model"
Cohesion: 0.48
Nodes (6): Budget, Account, Date, Int, String, UUID

### Community 43 - "Formatter Cache Singleton"
Cohesion: 0.33
Nodes (3): FormatterCache, DateFormatter, String

### Community 44 - "Goal Model"
Cohesion: 0.53
Nodes (5): Goal, Bool, Date, String, UUID

### Community 45 - "Commissione Suprema & Nightly Test Automation"
Cohesion: 0.50
Nodes (5): Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit, Changelog v3.x: XCUITest e automazione notturna, MoneyTrackerApp.swift (entry point), Automazione notturna (run_nightly_tests.sh + LaunchAgent, fix automatico via Claude Code headless, report_notturno.md + PR), MoneyTrackerUITests (target XCUITest, 12 test/4 classi)

### Community 46 - "Statistics & PDF Export Feature"
Cohesion: 0.40
Nodes (5): Feature: Statistiche, PDFReportGenerator.swift, StatisticsView.swift, Cartella Export/, Transferable CSVFile — nessun file temp su disco

### Community 47 - "App Icon & Branding Assets"
Cohesion: 1.00
Nodes (3): AppIcon Light 1024 — App Icon (Light Variant), Light Theme Branding — white/grey palette, minimalist design language, Visual Metaphor: Combined Bar + Line Chart with dot markers

## Knowledge Gaps
- **98 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+93 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **121 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Core Domain Utilities` to `Onboarding Tour Overlay & Cards`, `Supabase Sync Models (SB*)`, `Budget View & History`, `Add Transfer Flow`, `SwiftData Schema Migration`, `Goals View`, `Recurring Series Detection`, `Siri/Shortcuts App Intents`, `Supabase Manager & Auth Bootstrap`, `Settings & Data Export`, `Add Transaction Flow`, `Pianifica (Budget+Goals) View`, `Category Management View`, `Transaction Model`, `Unit Test Suites (Balance/Category/Migration)`?**
  _High betweenness centrality (0.162) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Core Domain Utilities` to `Supabase Sync Models (SB*)`, `SwiftData Schema Migration`, `Recurring Series Detection`, `Siri/Shortcuts App Intents`, `Supabase Manager & Auth Bootstrap`, `Currency/Date Formatting Helpers`, `Formatter Cache Singleton`, `Category Auto-Classification`, `App Lock Gate (Face ID/Touch ID)`, `Transaction Model`, `Unit Test Suites (Balance/Category/Migration)`?**
  _High betweenness centrality (0.080) - this node is a cross-community bridge._
- **Why does `View` connect `Onboarding Tour Overlay & Cards` to `Budget View & History`, `Add Transfer Flow`, `Recurring Series Detection`, `Supabase Manager & Auth Bootstrap`, `Settings & Data Export`, `Audit Logger`, `Pianifica (Budget+Goals) View`, `Tour Anchor Geometry`?**
  _High betweenness centrality (0.077) - this node is a cross-community bridge._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _112 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Onboarding Tour Overlay & Cards` be split into smaller, more focused modules?**
  _Cohesion score 0.050837496326770495 - nodes in this community are weakly interconnected._
- **Should `Supabase Sync Models (SB*)` be split into smaller, more focused modules?**
  _Cohesion score 0.09840425531914894 - nodes in this community are weakly interconnected._
- **Should `Budget View & History` be split into smaller, more focused modules?**
  _Cohesion score 0.09408033826638477 - nodes in this community are weakly interconnected._