# Graph Report - /Users/matteo/Desktop/MoneyTracker  (2026-07-08)

## Corpus Check
- 24 files · ~50,913 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 844 nodes · 1440 edges · 111 communities (27 shown, 84 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 39 edges (avg confidence: 0.82)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Accounts View
- Project Documentation
- App Core & Utilities
- Account Data Model
- Supabase Sync Layer
- Notification Scheduling
- Budget View
- Balance Cache
- App Lock / Biometrics
- Onboarding Tour Engine
- Schema Migration & Formatting
- Sync Serialization
- Auth Login UI
- App Intents & Shortcuts
- PDF Export
- Category Classifier
- Settings & CSV Export
- Audit Logger
- Tab Bar Frame Capture
- Demo Data Seeder
- Planning View
- Category Management
- Dashboard View
- Tour Highlight System
- Share Sheet UI
- Visual Assets & Branding
- Isolated Type Node 26
- Isolated Type Node 27
- Isolated Type Node 28
- Isolated Type Node 29
- Isolated Type Node 30
- Isolated Type Node 31
- Isolated Type Node 32
- Isolated Type Node 33
- Isolated Type Node 34
- Isolated Type Node 35
- Isolated Type Node 36
- Isolated Type Node 37
- Isolated Type Node 38
- Isolated Type Node 39
- Isolated Type Node 40
- Isolated Type Node 41
- Isolated Type Node 42
- Isolated Type Node 43
- Isolated Type Node 44
- Isolated Type Node 45
- Isolated Type Node 46
- Isolated Type Node 47
- Isolated Type Node 48
- Isolated Type Node 49
- Isolated Type Node 50
- Isolated Type Node 51
- Isolated Type Node 52
- Isolated Type Node 53
- Isolated Type Node 54
- Isolated Type Node 55
- Isolated Type Node 56
- Isolated Type Node 57
- Isolated Type Node 58
- Isolated Type Node 59
- Isolated Type Node 60
- Isolated Type Node 61
- Isolated Type Node 62
- Isolated Type Node 63
- Isolated Type Node 64
- Isolated Type Node 66
- Isolated Type Node 67
- Isolated Type Node 68
- Isolated Type Node 69
- Isolated Type Node 70
- Isolated Type Node 71
- Isolated Type Node 72
- Isolated Type Node 73
- Isolated Type Node 74
- Isolated Type Node 75
- Isolated Type Node 76
- Isolated Type Node 77
- Isolated Type Node 78
- Isolated Type Node 79
- Isolated Type Node 80
- Isolated Type Node 81
- Isolated Type Node 82
- Isolated Type Node 83
- Isolated Type Node 84
- Isolated Type Node 85
- Isolated Type Node 86
- Isolated Type Node 87
- Isolated Type Node 88
- Isolated Type Node 89
- Isolated Type Node 90
- Isolated Type Node 91
- Isolated Type Node 92
- Isolated Type Node 93
- Isolated Type Node 94
- Isolated Type Node 95
- Isolated Type Node 96
- Isolated Type Node 97
- Isolated Type Node 98
- Isolated Type Node 99
- Isolated Type Node 100
- Isolated Type Node 101
- Isolated Type Node 102
- Isolated Type Node 103
- Isolated Type Node 104
- Isolated Type Node 105
- Isolated Type Node 106
- Isolated Type Node 107
- Isolated Type Node 108
- Isolated Type Node 109
- Isolated Type Node 110

## God Nodes (most connected - your core abstractions)
1. `View` - 44 edges
2. `Date` - 33 edges
3. `CodingKeys` - 32 edges
4. `SwiftData` - 30 edges
5. `TourStep` - 27 edges
6. `SyncService` - 27 edges
7. `Foundation` - 24 edges
8. `Double` - 24 edges
9. `Decimal` - 21 edges
10. `StatisticsView` - 19 edges

## Surprising Connections (you probably didn't know these)
- `Checkpoint Workflow` --references--> `MoneyTracker App`  [EXTRACTED]
  CLAUDE.md → docs/MoneyTracker.md
- `MoneyTrackerMigrationPlan` --calls--> `Decimal`  [INFERRED]
  MoneyTracker/Persistence/SchemaMigration.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `ContentView` --references--> `View`  [EXTRACTED]
  MoneyTracker/Views/ContentView.swift → MoneyTracker/Views/Theme.swift
- `MoneyTracker Project (CLAUDE.md)` --references--> `MoneyTracker App`  [EXTRACTED]
  CLAUDE.md → docs/MoneyTracker.md
- `Goal` --references--> `Double`  [EXTRACTED]
  MoneyTracker/Models/Goal.swift → MoneyTracker/Formatting/CurrencyFormatting.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Offline-First Privacy Architecture (no server, on-device AI, NSFileProtection, no temp files)** — docs_moneytracker_md_privacy_radical, docs_moneytracker_md_category_classifier, docs_moneytracker_md_db_security, docs_moneytracker_md_transferable [INFERRED 0.85]
- **SwiftData Persistence Layer (Models + Schema Migration + Security)** — docs_moneytracker_md_swiftdata, docs_moneytracker_md_model_account, docs_moneytracker_md_model_transaction, docs_moneytracker_md_schema_migration, docs_moneytracker_md_db_security [EXTRACTED 0.95]
- **Performance Optimization via Singletons (FormatterCache, AccountBalanceCache, CategoryClassifier NSCache)** — docs_moneytracker_md_singleton_pattern, docs_moneytracker_md_formattercache, docs_moneytracker_md_account_balance_cache, docs_moneytracker_md_category_classifier [INFERRED 0.85]

## Communities (111 total, 84 thin omitted)

### Community 0 - "Accounts View"
Cohesion: 0.06
Nodes (49): AccountType, Content, AccountRow, AccountsView, AddAccountView, Account, Bool, Decimal (+41 more)

### Community 1 - "Project Documentation"
Cohesion: 0.05
Nodes (54): Checkpoint Workflow, Graphify Knowledge Graph Workflow, MoneyTracker Project (CLAUDE.md), AccountBalanceCache, AddTransactionView, AddTransferView, AI Financial Coach (Claude Haiku API, on-device), MoneyTracker App (+46 more)

### Community 2 - "App Core & Utilities"
Cohesion: 0.07
Nodes (23): AnyObject, Foundation, MoneyTracker, NotificationScheduling, RecurringTransactionActor, FormatterCache, DateFormatter, String (+15 more)

### Community 3 - "Account Data Model"
Cohesion: 0.07
Nodes (36): CaseIterable, Account, AccountType, carta, contanti, conto, investimento, risparmio (+28 more)

### Community 4 - "Supabase Sync Layer"
Cohesion: 0.10
Nodes (29): Equatable, SBAccount, SBBudget, SBGoal, SBTransaction, Account, Bool, Budget (+21 more)

### Community 5 - "Notification Scheduling"
Cohesion: 0.07
Nodes (27): Hashable, Bool, Decimal, Double, Int, ModelContext, String, SystemNotificationManager (+19 more)

### Community 6 - "Budget View"
Cohesion: 0.11
Nodes (24): Identifiable, AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget, Category (+16 more)

### Community 7 - "Balance Cache"
Cohesion: 0.08
Nodes (21): AccountBalanceCache, Account, PersistentIdentifier, Date, Decimal, Bool, String, Budget (+13 more)

### Community 8 - "App Lock / Biometrics"
Cohesion: 0.08
Nodes (19): Combine, AppLockGate, AppLockState, LockOverlay, Bool, Content, View, Void (+11 more)

### Community 9 - "Onboarding Tour Engine"
Cohesion: 0.07
Nodes (26): Int, Bool, CGFloat, CGRect, Int, TourManager, Bool, CGFloat (+18 more)

### Community 10 - "Schema Migration & Formatting"
Cohesion: 0.17
Nodes (20): MigrationStage, Double, Account, Budget, DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+12 more)

### Community 11 - "Sync Serialization"
Cohesion: 0.07
Nodes (30): CodingKey, CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt (+22 more)

### Community 12 - "Auth Login UI"
Cohesion: 0.11
Nodes (19): Anchor, GeometryProxy, AuthField, LoginView, Bool, Error, String, SignUpView (+11 more)

### Community 13 - "App Intents & Shortcuts"
Cohesion: 0.13
Nodes (19): AppIntent, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, IntentResult, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+11 more)

### Community 14 - "PDF Export"
Cohesion: 0.26
Nodes (14): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+6 more)

### Community 15 - "Category Classifier"
Cohesion: 0.18
Nodes (9): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, KeywordCategoryClassifierTests, NSCache, NSString (+1 more)

### Community 16 - "Settings & CSV Export"
Cohesion: 0.23
Nodes (17): Codable, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport, JSONExportFile (+9 more)

### Community 17 - "Audit Logger"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 18 - "Tab Bar Frame Capture"
Cohesion: 0.20
Nodes (11): CapView, CGFloat, CGRect, Context, Void, TabBarFrameCapture, NSCoder, UITabBar (+3 more)

### Community 19 - "Demo Data Seeder"
Cohesion: 0.16
Nodes (12): App, FileProtectionType, DemoDataSeeder, ModelContext, applyFileProtection(), MoneyTrackerApp, Bool, ModelContainer (+4 more)

### Community 20 - "Planning View"
Cohesion: 0.19
Nodes (11): PianificaView, Bool, Budget, Decimal, Double, Goal, Int, LocalizedStringKey (+3 more)

### Community 21 - "Category Management"
Cohesion: 0.24
Nodes (8): AddCategoryView, CategoryManagementView, CategoryRow, Bool, Category, Int, String, Transaction

### Community 22 - "Dashboard View"
Cohesion: 0.22
Nodes (8): DashboardView, HomeAccountOrderSheet, Account, Bool, Decimal, Set, String, Transaction

### Community 23 - "Tour Highlight System"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 24 - "Share Sheet UI"
Cohesion: 0.38
Nodes (5): Any, Context, ShareSheet, UIActivityViewController, UIViewControllerRepresentable

### Community 25 - "Visual Assets & Branding"
Cohesion: 1.00
Nodes (3): AppIcon Light 1024 — App Icon (Light Variant), Light Theme Branding — white/grey palette, minimalist design language, Visual Metaphor: Combined Bar + Line Chart with dot markers

## Knowledge Gaps
- **79 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+74 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **84 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `App Core & Utilities` to `Accounts View`, `Account Data Model`, `Supabase Sync Layer`, `Notification Scheduling`, `Budget View`, `Schema Migration & Formatting`, `App Intents & Shortcuts`, `Settings & CSV Export`, `Demo Data Seeder`, `Planning View`, `Category Management`, `Dashboard View`?**
  _High betweenness centrality (0.190) - this node is a cross-community bridge._
- **Why does `Foundation` connect `App Core & Utilities` to `Account Data Model`, `Supabase Sync Layer`, `Balance Cache`, `App Lock / Biometrics`, `Schema Migration & Formatting`, `App Intents & Shortcuts`, `Category Classifier`?**
  _High betweenness centrality (0.111) - this node is a cross-community bridge._
- **Why does `View` connect `Accounts View` to `App Core & Utilities`, `Account Data Model`, `Notification Scheduling`, `Budget View`, `Settings & CSV Export`, `Audit Logger`, `Demo Data Seeder`, `Planning View`, `Category Management`, `Dashboard View`?**
  _High betweenness centrality (0.108) - this node is a cross-community bridge._
- **Are the 2 inferred relationships involving `TourStep` (e.g. with `.next()` and `.previous()`) actually correct?**
  _`TourStep` has 2 INFERRED edges - model-reasoned connections that need verification._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _81 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Accounts View` be split into smaller, more focused modules?**
  _Cohesion score 0.05536723163841808 - nodes in this community are weakly interconnected._
- **Should `Project Documentation` be split into smaller, more focused modules?**
  _Cohesion score 0.053109713487071976 - nodes in this community are weakly interconnected._