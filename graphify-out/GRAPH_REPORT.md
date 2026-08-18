# Graph Report - .  (2026-08-19)

## Corpus Check
- 7 files · ~59,459 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 971 nodes · 1671 edges · 170 communities (35 shown, 135 thin omitted)
- Extraction: 96% EXTRACTED · 4% INFERRED · 0% AMBIGUOUS · INFERRED: 61 edges (avg confidence: 0.8)
- Token cost: 199,326 input · 0 output

## Community Hubs (Navigation)
- CategoryManagementView & AddTransactionView
- TransactionsView & Account
- SyncService
- TourManager & MoneyTrackerApp
- Theme
- UITestSupport & TourFlowUITests
- StatisticsView & BudgetView
- SchemaMigration
- SyncService
- AppLockGate & SupabaseManager
- SchemaMigrationTests & FormatterCache
- CurrencyFormatting & AccountBalanceCache
- AccountsView & AddTransferView
- MoneyTracker
- KeywordCategoryClassifierTests & KeywordCategoryClassifier
- AddExpenseIntent & SyncService
- PDFReportGenerator
- SettingsView
- AuditLogger & AuditLogView
- NotificationManager
- RecurringSeriesDetector & RecurringSeriesDetailView
- MoneyTracker
- PianificaView
- TourOverlayView
- TourHighlight
- StatisticsView
- CLAUDE
- MoneyTracker
- Report Notturno & MoneyTracker
- Appicon Light 1024
- MoneyTracker
- MoneyTracker
- MoneyTracker
- Community 33
- MoneyTracker
- MoneyTracker
- MoneyTracker
- MoneyTracker
- MoneyTracker
- MoneyTracker
- Community 40
- Community 41
- Community 42
- Community 43
- Community 44
- Community 45
- Community 46
- Community 47
- Community 48
- Community 49
- Community 50
- Community 51
- Community 52
- Community 53
- Community 54
- Community 55
- Community 56
- Community 57
- Community 58
- Community 59
- Community 60
- Community 61
- Community 62
- Community 63
- Community 64
- Community 65
- Community 66
- Community 67
- Community 68
- Community 69
- Community 70
- Community 71
- Community 72
- Community 73
- Community 74
- Community 75
- Community 76
- Community 77
- Community 78
- Community 79
- MoneyTracker-Bridging-Header
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
- Community 87
- Community 88
- Community 89
- Community 90
- Community 91
- Community 92
- Community 93
- Community 94
- Community 95
- Community 96
- Community 97
- Community 98
- Community 99
- Community 100
- Community 101
- Community 102
- Community 103
- Community 104
- Community 105
- Community 106
- Community 107
- Community 108
- Community 109
- Community 110
- Community 111
- Community 112
- Community 113
- Community 114
- Community 115
- Community 116
- Community 117
- Community 118
- Community 119
- Community 120
- Community 121
- Community 122
- Community 123
- Community 124
- Community 125
- Community 126
- Community 127
- Community 128
- Community 129
- Community 130
- Community 131
- Community 132
- Community 133
- Community 134
- Community 135
- Community 136
- Community 137
- Community 138
- Community 139
- Community 140
- Community 141
- Community 142
- Community 143
- Community 144
- Community 145
- Community 146
- Community 147
- Community 148
- Community 149
- Community 150
- Community 151
- Community 152
- Community 153
- Community 154
- Community 155
- Community 156
- Community 157
- Community 158
- Community 159
- Community 160
- Category Type Reference
- Decimal Type Reference
- Transaction Type Reference
- Void Type Reference
- NSCoder Reference
- UITabBar Reference
- UIView Reference
- UIViewRepresentable Reference
- UIWindow Reference

## God Nodes (most connected - your core abstractions)
1. `CodingKeys` - 32 edges
2. `SwiftData` - 31 edges
3. `View` - 31 edges
4. `SyncService` - 28 edges
5. `Date` - 27 edges
6. `Foundation` - 25 edges
7. `Double` - 24 edges
8. `TransactionsView` - 23 edges
9. `Decimal` - 21 edges
10. `TourManager` - 20 edges

## Surprising Connections (you probably didn't know these)
- `MoneyTrackerMigrationPlan` --calls--> `Decimal`  [INFERRED]
  MoneyTracker/Persistence/SchemaMigration.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `ContentView` --references--> `View`  [EXTRACTED]
  MoneyTracker/Views/ContentView.swift → MoneyTracker/Views/Theme.swift
- `Goal` --references--> `Double`  [EXTRACTED]
  MoneyTracker/Models/Goal.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `Account` --references--> `Decimal`  [EXTRACTED]
  MoneyTracker/Models/Account.swift → MoneyTracker/Formatting/CurrencyFormatting.swift
- `Budget` --references--> `Decimal`  [EXTRACTED]
  MoneyTracker/Models/Budget.swift → MoneyTracker/Formatting/CurrencyFormatting.swift

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Flusso di rettifica saldo conto** — docs_moneytracker_account, docs_moneytracker_transaction, docs_moneytracker_addaccountview, docs_moneytracker_category [EXTRACTED 1.00]
- **Ciclo di vita delle transazioni ricorrenti** — docs_moneytracker_transaction, docs_moneytracker_recurringtransactions, docs_moneytracker_transactionsview, docs_moneytracker_recurringseriesdetector [EXTRACTED 1.00]
- **Sistema di onboarding tour a due livelli** — docs_moneytracker_onboardingtour, docs_moneytracker_tabbarframecapture, docs_moneytracker_dashboardview, docs_moneytracker_changelog_v3_jul2026_minitour [EXTRACTED 0.90]

## Communities (170 total, 135 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.05
Nodes (42): Bool, Charts, Decimal, Double, Identifiable, Int, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024) (+34 more)

### Community 1 - "TransactionsView & Account"
Cohesion: 0.07
Nodes (49): Anchor, CGRect, Content, ContextualHint, GeometryProxy, LocalizedStringKey, HintCard, ModalCard (+41 more)

### Community 2 - "SyncService"
Cohesion: 0.08
Nodes (37): Binding, CaseIterable, Account, AccountType, carta, contanti, conto, investimento (+29 more)

### Community 3 - "TourManager & MoneyTrackerApp"
Cohesion: 0.09
Nodes (31): Equatable, ModelContext, Category, Bool, Int, String, SBAccount, SBBudget (+23 more)

### Community 4 - "Theme"
Cohesion: 0.06
Nodes (28): App, Combine, FileProtectionType, ModelContainer, AppLockGate, AppLockState, LockOverlay, Bool (+20 more)

### Community 5 - "UITestSupport & TourFlowUITests"
Cohesion: 0.10
Nodes (14): AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, String, TourFlowUITests, TransactionFlowUITests, MoneyTrackerUITestCase, String (+6 more)

### Community 6 - "StatisticsView & BudgetView"
Cohesion: 0.07
Nodes (26): Account, AccountType, Color, Date, AccountRow, AccountsView, AddAccountView, Bool (+18 more)

### Community 7 - "SchemaMigration"
Cohesion: 0.06
Nodes (33): CodingKey, DemoDataSeeder, ModelContext, CodingKeys, accountId, amount, category, categoryIcon (+25 more)

### Community 8 - "SyncService"
Cohesion: 0.17
Nodes (20): MigrationStage, Double, Account, Budget, DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+12 more)

### Community 9 - "AppLockGate & SupabaseManager"
Cohesion: 0.11
Nodes (15): ContextualHint, movimentiSection, Bool, CGFloat, LocalizedStringKey, Bool, Int, String (+7 more)

### Community 10 - "SchemaMigrationTests & FormatterCache"
Cohesion: 0.10
Nodes (22): Hashable, RecurringSeries, RecurringSeriesDetector, Bool, Decimal, Int, String, Transaction (+14 more)

### Community 11 - "CurrencyFormatting & AccountBalanceCache"
Cohesion: 0.12
Nodes (20): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, IntentResult, LocalizedStringResource, AccountOptionsProvider (+12 more)

### Community 12 - "AccountsView & AddTransferView"
Cohesion: 0.26
Nodes (14): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+6 more)

### Community 13 - "MoneyTracker"
Cohesion: 0.21
Nodes (19): Codable, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport (+11 more)

### Community 14 - "KeywordCategoryClassifierTests & KeywordCategoryClassifier"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 15 - "AddExpenseIntent & SyncService"
Cohesion: 0.17
Nodes (6): AnyObject, Foundation, NotificationScheduling, RecurringTransactionActor, OSLog, SwiftData

### Community 16 - "PDFReportGenerator"
Cohesion: 0.15
Nodes (8): AccountBalanceCache, Account, PersistentIdentifier, Date, Decimal, Bool, String, AccountBalanceTests

### Community 17 - "SettingsView"
Cohesion: 0.16
Nodes (8): Bool, Decimal, Double, Int, ModelContext, String, SystemNotificationManager, NotificationScheduling

### Community 18 - "AuditLogger & AuditLogView"
Cohesion: 0.18
Nodes (17): Account (modello dati), AccountsView (Conti), AddAccountView, AddTransferView, Budget (modello dati), Category (modello dati), Changelog v1 (inverno 2025) — Base, Changelog v2 (primavera 2026) — Feature complete (+9 more)

### Community 19 - "NotificationManager"
Cohesion: 0.23
Nodes (9): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, Logger, NSCache, NSString (+1 more)

### Community 20 - "RecurringSeriesDetector & RecurringSeriesDetailView"
Cohesion: 0.19
Nodes (11): PianificaView, Bool, Budget, Decimal, Double, Goal, Int, LocalizedStringKey (+3 more)

### Community 21 - "MoneyTracker"
Cohesion: 0.24
Nodes (8): AddCategoryView, CategoryManagementView, CategoryRow, Bool, Category, Int, String, Transaction

### Community 22 - "PianificaView"
Cohesion: 0.21
Nodes (13): AddTransactionView, Audit Qualità (Score 7.2/10), BudgetView, Changelog v3 (giu-lug 2026) — Enterprise audit e bug fix (43 miglioramenti), FormatterCache, GoalsView (Obiettivi), Localizzazione (7 lingue), NotificationManager (+5 more)

### Community 23 - "TourOverlayView"
Cohesion: 0.15
Nodes (12): App Icon (Assets.xcassets/AppIcon.appiconset), Bucktrail (nome visualizzato app), Modello di business, Changelog v3 (ago 2026) — Nuova icona, nome Bucktrail, grafico a barre affiancate, Changelog v3 (lug 2026) — Riorganizzazione e documentazione, Changelog v3 (lug 2026) — XCUITest e automazione notturna, Differenziatori chiave, MoneyTracker — Documento Completo (+4 more)

### Community 24 - "TourHighlight"
Cohesion: 0.18
Nodes (12): AI Financial Coach, Connessione bancaria automatica, Calendario flusso di cassa, Modalità Coppia/Famiglia, Punteggio Salute Finanziaria, Feature fiscali italiane, 'Me lo posso permettere?', Tracciatore Patrimonio Netto (+4 more)

### Community 26 - "CLAUDE"
Cohesion: 0.29
Nodes (8): AppLockGate (Biometria), Changelog v3 (lug 2026) — Card 'Fissi del mese' in Home + tour testato end-to-end, Changelog v3 (lug 2026) — Fix mini-tour contestuali che non comparivano mai, DashboardView (Home), Fissi del mese (card Home), Onboarding Tour (OnboardingTour/), Roadmap Livello 2 — Necessario per essere competitivi, TabBarFrameCapture

### Community 27 - "MoneyTracker"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 28 - "Report Notturno & MoneyTracker"
Cohesion: 0.38
Nodes (5): Any, Context, ShareSheet, UIActivityViewController, UIViewControllerRepresentable

### Community 29 - "Appicon Light 1024"
Cohesion: 0.48
Nodes (6): Budget, Account, Date, Int, String, UUID

### Community 30 - "MoneyTracker"
Cohesion: 0.33
Nodes (3): FormatterCache, DateFormatter, String

### Community 31 - "MoneyTracker"
Cohesion: 0.53
Nodes (5): Goal, Bool, Date, String, UUID

### Community 32 - "MoneyTracker"
Cohesion: 0.40
Nodes (5): Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit, Struttura cartella immutabile (regola), Istruzioni Graphify (query/--update), CLAUDE.md — Istruzioni per Claude, Workflow checkpoint (CLAUDE.md, 5 step: audit → doc → PDF → commit → graphify)

### Community 33 - "Community 33"
Cohesion: 0.40
Nodes (4): ModelContext, Bool, Int, String

### Community 34 - "MoneyTracker"
Cohesion: 0.67
Nodes (4): AddExpenseIntent (Shortcuts Apple), Changelog v3 (lug 2026) — Fix tocco posteriore/Siri: transazioni che sparivano dopo il salvataggio, Sync cross-device (Supabase), SyncService (Sync Supabase)

## Knowledge Gaps
- **91 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+86 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **135 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `AddExpenseIntent & SyncService` to `CategoryManagementView & AddTransactionView`, `TransactionsView & Account`, `SyncService`, `TourManager & MoneyTrackerApp`, `Theme`, `StatisticsView & BudgetView`, `SyncService`, `SchemaMigrationTests & FormatterCache`, `CurrencyFormatting & AccountBalanceCache`, `MoneyTracker`, `RecurringSeriesDetector & RecurringSeriesDetailView`, `MoneyTracker`?**
  _High betweenness centrality (0.184) - this node is a cross-community bridge._
- **Why does `Date` connect `CategoryManagementView & AddTransactionView` to `SyncService`, `TourManager & MoneyTrackerApp`, `SchemaMigrationTests & FormatterCache`, `AccountsView & AddTransferView`, `KeywordCategoryClassifierTests & KeywordCategoryClassifier`, `SettingsView`?**
  _High betweenness centrality (0.097) - this node is a cross-community bridge._
- **Why does `Foundation` connect `AddExpenseIntent & SyncService` to `SyncService`, `TourManager & MoneyTrackerApp`, `Theme`, `MoneyTracker`, `SyncService`, `SchemaMigrationTests & FormatterCache`, `CurrencyFormatting & AccountBalanceCache`, `PDFReportGenerator`, `NotificationManager`, `MoneyTracker`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _93 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `CategoryManagementView & AddTransactionView` be split into smaller, more focused modules?**
  _Cohesion score 0.050921861281826165 - nodes in this community are weakly interconnected._
- **Should `TransactionsView & Account` be split into smaller, more focused modules?**
  _Cohesion score 0.06892230576441102 - nodes in this community are weakly interconnected._
- **Should `SyncService` be split into smaller, more focused modules?**
  _Cohesion score 0.07609427609427609 - nodes in this community are weakly interconnected._