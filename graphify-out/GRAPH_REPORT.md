# Graph Report - .  (2026-09-08)

## Corpus Check
- 25 files · ~63,163 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1041 nodes · 1862 edges · 183 communities (34 shown, 149 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 114 edges (avg confidence: 0.81)
- Token cost: 122,363 input · 0 output

## Community Hubs (Navigation)
- CategoryManagementView & AddTransactionView
- Ricorrenze — motore backfill & Intents dirty-tracking
- Sync/ricorrenze — file sorgente del checkpoint settembre 2026
- Schema Migration V1→V2 (Decimal precision)
- Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)
- Community 5
- AppIntents — Tocco posteriore/Siri (AddExpenseIntent)
- Supabase CodingKeys (snake_case mapping)
- Community 8
- Community 9
- Community 10
- Community 11
- Community 12
- AddTransactionView & roadmap funzionalità future
- Community 14
- Community 15
- SettingsView — biometria, export, GDPR
- Community 17
- Bug noti Dashboard/GoalsView & FormatterCache
- AddTransferView, changelog, automazione test notturni
- Community 20
- Community 21
- Community 22
- Community 23
- Budget/Obiettivi & localizzazione 7 lingue
- Modelli dati (Account/Budget/Transaction) & rettifica saldo
- Design system, App Icon Bucktrail, colori semantici
- Community 27
- Community 28
- Community 29
- Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate
- Community 31
- Biometria & roadmap Livello 2 (Watch/Widget)
- Community 33
- Community 34
- Community 35
- Community 36
- Community 37
- Community 38
- Community 39
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
- Community 80
- Community 81
- Community 82
- Community 83
- Community 84
- Community 85
- Community 86
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
- Community 161
- Community 162
- Community 163
- Community 164
- Community 165
- Community 166
- Community 167
- Community 168
- Community 169
- Community 170
- Community 171
- Community 172
- Community 173
- Community 174
- Community 175
- Community 176
- Community 177
- Community 178
- Community 179
- Community 180
- Community 181
- Community 182

## God Nodes (most connected - your core abstractions)
1. `Decimal` - 54 edges
2. `MoneyTracker — Documento Completo (master doc)` - 45 edges
3. `Transaction` - 40 edges
4. `SwiftData` - 33 edges
5. `Double` - 33 edges
6. `CodingKeys` - 32 edges
7. `Foundation` - 29 edges
8. `SyncService` - 28 edges
9. `Changelog (section 10)` - 27 edges
10. `Account` - 25 edges

## Surprising Connections (you probably didn't know these)
- `Personal Finance Tracker (README)` --semantically_similar_to--> `MoneyTracker — Documento Completo (master doc)`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Multi-device sync via Supabase` --semantically_similar_to--> `Supabase cross-device sync (in sviluppo; offline-first, TLS+AES-256, last-write-wins)`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Demo mode (try without account)` --semantically_similar_to--> `Demo mode / deterministic UI-testing data (--uitesting launch arg)`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Security via Supabase Row Level Security (RLS)` --semantically_similar_to--> `Supabase cross-device sync (in sviluppo; offline-first, TLS+AES-256, last-write-wins)`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Multi-account tracking` --semantically_similar_to--> `Conti / AccountsView feature set`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **September 2026 sync/recurring bug-fix cluster (shared root cause: local↔cloud sync + recurring engine)** — docs_moneytracker_app_group_bug_fix, docs_moneytracker_sync_clearlocaldata_bug, docs_moneytracker_recurring_backfill_fix, docs_moneytracker_decimal_migration_fix [INFERRED 0.85]
- **SwiftData schema: Account, Transaction, Budget, Goal, Category models** — docs_moneytracker_account_model, docs_moneytracker_transaction_model, docs_moneytracker_budget_model, docs_moneytracker_goal_model, docs_moneytracker_category_model [EXTRACTED 1.00]
- **Recurring transaction engine evolution (trigger fix → backfill → dedup → stop-recurrence feature)** — docs_moneytracker_recurring_transaction_engine, docs_moneytracker_recurring_foreground_trigger_fix, docs_moneytracker_recurring_backfill_fix, docs_moneytracker_recurring_duplicate_fix, docs_moneytracker_interrompi_ricorrenza_feature [INFERRED 0.85]

## Communities (183 total, 149 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.05
Nodes (60): Binding, CGFloat, Content, Transaction, Bool, LocalizedStringKey, Color, DS (+52 more)

### Community 1 - "Ricorrenze — motore backfill & Intents dirty-tracking"
Cohesion: 0.05
Nodes (29): IntentResult, AccountBalanceCache, Bool, Date, Int, String, SystemNotificationManager, RecurringTransactionActor (+21 more)

### Community 2 - "Sync/ricorrenze — file sorgente del checkpoint settembre 2026"
Cohesion: 0.06
Nodes (25): AnyObject, Combine, Foundation, MoneyTracker, SupabaseConfig, NotificationScheduling, FormatterCache, DateFormatter (+17 more)

### Community 3 - "Schema Migration V1→V2 (Decimal precision)"
Cohesion: 0.08
Nodes (34): AccountType, MigrationStage, Double, Account, Budget, decimalFromLegacyDouble(), DecimalMigrationBuffer, Goal (+26 more)

### Community 4 - "Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)"
Cohesion: 0.07
Nodes (31): Equatable, SupabaseManager, Bool, String, ModelContext, Bool, Int, String (+23 more)

### Community 5 - "Community 5"
Cohesion: 0.09
Nodes (15): Int, AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, String, TourFlowUITests, TransactionFlowUITests, MoneyTrackerUITestCase (+7 more)

### Community 6 - "AppIntents — Tocco posteriore/Siri (AddExpenseIntent)"
Cohesion: 0.08
Nodes (30): App, AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, FileProtectionType, LocalizedStringResource (+22 more)

### Community 7 - "Supabase CodingKeys (snake_case mapping)"
Cohesion: 0.06
Nodes (33): CodingKey, DemoDataSeeder, ModelContext, CodingKeys, accountId, amount, category, categoryIcon (+25 more)

### Community 8 - "Community 8"
Cohesion: 0.11
Nodes (15): ContextualHint, movimentiSection, Bool, CGFloat, LocalizedStringKey, Bool, Int, String (+7 more)

### Community 9 - "Community 9"
Cohesion: 0.09
Nodes (20): Account, Date, ModelContext, Category, Bool, Int, String, AddTransferView (+12 more)

### Community 10 - "Community 10"
Cohesion: 0.11
Nodes (18): Any, Charts, Context, Identifiable, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024), App Icon (Tinted, 1024x1024), CategoryStat (+10 more)

### Community 11 - "Community 11"
Cohesion: 0.11
Nodes (21): Hashable, RecurringSeries, RecurringSeriesDetector, Bool, Decimal, Int, String, Transaction (+13 more)

### Community 12 - "Community 12"
Cohesion: 0.25
Nodes (15): CGContext, CGPoint, DateFormatter, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Bool, CGFloat (+7 more)

### Community 13 - "AddTransactionView & roadmap funzionalità future"
Cohesion: 0.09
Nodes (25): AddTransactionView (add transaction flow), "Me lo posso permettere?" conversational afford-check shortcut, AI Financial Coach (monthly on-device report, optional Claude Haiku synthesis), Automatic bank connection (GoCardless/Nordigen API), Business model: one-time purchase (€4,99) + future optional Premium subscription, Calendario flusso di cassa (day-by-day balance projection), Claude Haiku API (optional AI coach synthesis), Financial Health Score (0-100, 5 dimensions) (+17 more)

### Community 14 - "Community 14"
Cohesion: 0.17
Nodes (10): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, Logger, KeywordCategoryClassifierTests, NSCache (+2 more)

### Community 15 - "Community 15"
Cohesion: 0.12
Nodes (21): CaseIterable, Account, AccountType, carta, contanti, conto, investimento, risparmio (+13 more)

### Community 16 - "SettingsView — biometria, export, GDPR"
Cohesion: 0.21
Nodes (19): Codable, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport (+11 more)

### Community 17 - "Community 17"
Cohesion: 0.17
Nodes (10): AuditLogger, Entry, ModelContext, Notification, PersistentIdentifier, String, URL, UUID (+2 more)

### Community 18 - "Bug noti Dashboard/GoalsView & FormatterCache"
Cohesion: 0.10
Nodes (21): BUG-01: DashboardView List+fixed frame truncated text with Dynamic Type, BUG-02: GoalsView.load() showed "1000.0" instead of "1000", BUG-03: CategoryStat.id unstable UUID broke SwiftUI diffing, BUG-04: debug print() in TabBarFrameCapture hot path, Home / DashboardView feature set, "Fissi del mese" Home card (fixed expense/income totals), FormatterCache singleton pattern, i18n-01: Siri section untranslated in any language (+13 more)

### Community 19 - "AddTransferView, changelog, automazione test notturni"
Cohesion: 0.16
Nodes (20): AddTransferView (transfer flow), Changelog (section 10), Claude Code headless (automated nightly fix agent), Fix: Level-2 contextual mini-tours never appeared, Demo mode / deterministic UI-testing data (--uitesting launch arg), Folder reorg + documentation consolidation into single doc, "Interrompi ricorrenza" (stop recurrence) feature, Nightly test automation (run_nightly_tests.sh + LaunchAgent, 4:00 AM) (+12 more)

### Community 20 - "Community 20"
Cohesion: 0.16
Nodes (11): AppLockGate, AppLockState, LockOverlay, Bool, Content, View, Void, View (+3 more)

### Community 21 - "Community 21"
Cohesion: 0.24
Nodes (11): Anchor, CGRect, ContextualHint, GeometryProxy, HintCard, ModalCard, StepCard, Bool (+3 more)

### Community 22 - "Community 22"
Cohesion: 0.21
Nodes (11): PianificaView, Bool, Budget, Decimal, Double, Goal, Int, LocalizedStringKey (+3 more)

### Community 23 - "Community 23"
Cohesion: 0.27
Nodes (7): AddCategoryView, CategoryManagementView, CategoryRow, Bool, Category, Int, String

### Community 24 - "Budget/Obiettivi & localizzazione 7 lingue"
Cohesion: 0.21
Nodes (12): Budget / BudgetView feature set, Obiettivi / GoalsView feature set, Localization (7 languages, 340 keys/file), v2 (primavera 2026) — Feature complete milestone, Budgeting (per category/account), Demo mode (try without account), Multi-device sync via Supabase, Multi-language support (7 languages) (+4 more)

### Community 25 - "Modelli dati (Account/Budget/Transaction) & rettifica saldo"
Cohesion: 0.31
Nodes (9): Account balance correction via "Rettifica saldo" adjustment transaction, Account data model, Conti / AccountsView feature set, Budget data model, Category data model, Fix: Double→Decimal migration precision (SchemaMigration.swift), Transaction data model, v1 (inverno 2025) — Base milestone (+1 more)

### Community 26 - "Design system, App Icon Bucktrail, colori semantici"
Cohesion: 0.22
Nodes (9): App Icon (light/dark/tinted variants, bar-chart design), New App Icon design (minimal ascending bars, gold/amber accent), Display name "Bucktrail" vs technical project name "MoneyTracker", DS.positive/DS.negative semantic colors + DS.signColor(_:), Statistics trend: bar+line → side-by-side BarMark redesign, Statistiche / StatisticsView feature set, Theme.swift design system (DS namespace, spacing, components), CSVFile Transferable (DataRepresentation, no temp file on disk) (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.31
Nodes (6): AuthField, LoginView, Bool, Error, String, UIKeyboardType

### Community 28 - "Community 28"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 29 - "Community 29"
Cohesion: 0.38
Nodes (4): SignUpView, Bool, Error, String

### Community 30 - "Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate"
Cohesion: 0.47
Nodes (6): App Group fix: back-tap/Siri expenses saved into an invisible sandbox store, Fix: back-tap/Siri transactions disappeared after save (markTransactionDirty), Modalità Coppia/Famiglia (shared DB via CloudKit/Supabase), Apple Shortcuts integration (AddExpenseIntent), Supabase cross-device sync (in sviluppo; offline-first, TLS+AES-256, last-write-wins), Fix: local data wiped on passive session loss, replaced by stale Supabase snapshot

### Community 31 - "Community 31"
Cohesion: 0.40
Nodes (5): Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit, Struttura cartella immutabile (regola), Istruzioni Graphify (query/--update), CLAUDE.md — Istruzioni per Claude, Workflow checkpoint (CLAUDE.md, 5 step: audit → doc → PDF → commit → graphify)

### Community 32 - "Biometria & roadmap Livello 2 (Watch/Widget)"
Cohesion: 0.50
Nodes (4): Biometric app lock (AppLockGate, Face ID/Touch ID), Roadmap Livello 2 — competitive necessities, Apple Watch App (watchOS + WatchConnectivity, planned), WidgetKit Home/Lock Screen widget (planned)

## Knowledge Gaps
- **103 isolated node(s):** `contanti`, `carta`, `conto`, `risparmio`, `investimento` (+98 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **149 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` to `CategoryManagementView & AddTransactionView`, `Schema Migration V1→V2 (Decimal precision)`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `Community 9`, `Community 10`, `Community 11`, `SettingsView — biometria, export, GDPR`, `Community 23`?**
  _High betweenness centrality (0.112) - this node is a cross-community bridge._
- **Why does `Decimal` connect `Ricorrenze — motore backfill & Intents dirty-tracking` to `CategoryManagementView & AddTransactionView`, `Schema Migration V1→V2 (Decimal precision)`, `Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)`, `Community 10`, `Community 15`, `SettingsView — biometria, export, GDPR`?**
  _High betweenness centrality (0.090) - this node is a cross-community bridge._
- **Why does `SyncService` connect `Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)` to `Ricorrenze — motore backfill & Intents dirty-tracking`, `Sync/ricorrenze — file sorgente del checkpoint settembre 2026`, `Community 5`?**
  _High betweenness centrality (0.078) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `Decimal` (e.g. with `.perform()` and `.perform()`) actually correct?**
  _`Decimal` has 13 INFERRED edges - model-reasoned connections that need verification._
- **Are the 7 inferred relationships involving `Transaction` (e.g. with `.processRecurring()` and `.perform()`) actually correct?**
  _`Transaction` has 7 INFERRED edges - model-reasoned connections that need verification._
- **What connects `contanti`, `carta`, `conto` to the rest of the system?**
  _105 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `CategoryManagementView & AddTransactionView` be split into smaller, more focused modules?**
  _Cohesion score 0.054363796650014694 - nodes in this community are weakly interconnected._