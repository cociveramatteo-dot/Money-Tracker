# Graph Report - /Users/matteo/Desktop/MoneyTracker  (2026-07-08)

## Corpus Check
- 62 files · ~56,644 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 700 nodes · 1346 edges · 35 communities (31 shown, 4 thin omitted)
- Extraction: 97% EXTRACTED · 3% INFERRED · 0% AMBIGUOUS · INFERRED: 46 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Community Hubs (Navigation)
- Intents & Balance Computation
- Data Seeding & Logging
- Audit & Changelog Docs
- Account Data Model
- Schema Migration & Decimal
- Design System & Theme
- Currency Formatting & Notifications
- Add Transaction UI
- Onboarding Tour Manager
- Biometric App Lock
- PDF Export & Formatter Cache
- Supabase Sync Coding Keys
- Supabase Auth & Cloud Sync
- App Entry & Domain Services
- Keyword Category Classifier
- Tab Bar Frame Capture
- Apple Shortcuts Integration
- Budget UI
- Planning View (Pianifica)
- Dashboard & Account Order
- Accounts Management UI
- Transfer Between Accounts
- Login View
- Tour Highlight Anchoring
- Tour Overlay Geometry
- Share Sheet & Export
- Budget Data Model
- App Root & Navigation
- Sign Up View
- Tour Overlay Cards
- App Branding & Icon
- Italian Market Vision
- Audit Report Snapshot
- QA Debug Cleanup

## God Nodes (most connected - your core abstractions)
1. `Decimal` - 53 edges
2. `Double` - 33 edges
3. `CodingKeys` - 32 edges
4. `SwiftData` - 29 edges
5. `TourStep` - 27 edges
6. `Foundation` - 23 edges
7. `SwiftUI` - 22 edges
8. `Category` - 20 edges
9. `StatisticsView` - 19 edges
10. `SyncService` - 17 edges

## Surprising Connections (you probably didn't know these)
- `AI Financial Coach (Planned - Claude Haiku API)` --semantically_similar_to--> `'Me lo posso permettere?' Conversational Shortcut`  [INFERRED] [semantically similar]
  STATO_APP.md → VISIONE.md
- `MoneyTracker Project File Structure` --references--> `MoneyTracker App`  [EXTRACTED]
  MoneyTracker/SETUP.md → AUDIT_E_CHANGELOG.md
- `Custom Category Management` --conceptually_related_to--> `CategoryClassifier (Keyword Matching Engine)`  [INFERRED]
  MoneyTracker/SETUP.md → AUDIT_E_CHANGELOG.md
- `VoiceOver Accessibility Coverage` --conceptually_related_to--> `i18n BUG-02: Accessibility Labels Non-Localized`  [INFERRED]
  AUDIT_E_CHANGELOG.md → QA_Report.md
- `BUG-01: CategoryStat.id UUID Instability` --conceptually_related_to--> `DashboardView (Home Screen)`  [INFERRED]
  QA_Report.md → STATO_APP.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **Core SwiftData Models (Account, Transaction, Budget, Goal, Category)** — audit_e_changelog_account_model, audit_e_changelog_transaction_model, audit_e_changelog_budget_model, audit_e_changelog_goal_model, audit_e_changelog_category_model [EXTRACTED 1.00]
- **Security Architecture (NSFileProtection, SEC-01 Fix, Swift6 Concurrency)** — audit_e_changelog_nsfileprotection, audit_e_changelog_sec01_try_bang_fix, audit_e_changelog_swift6_concurrency, audit_e_changelog_add_expense_intent [EXTRACTED 0.95]
- **Planned Premium Features (Open Banking, AI Coach, Supabase Sync)** — stato_app_open_banking, stato_app_ai_financial_coach, stato_app_supabase_sync, stato_app_business_model [INFERRED 0.85]

## Communities (35 total, 4 thin omitted)

### Community 0 - "Intents & Balance Computation"
Cohesion: 0.08
Nodes (25): Charts, Identifiable, IntentResult, AccountBalanceCache, Account, PersistentIdentifier, Decimal, Goal (+17 more)

### Community 1 - "Data Seeding & Logging"
Cohesion: 0.10
Nodes (27): Codable, DemoDataSeeder, Logger, ModelContext, Bool, Int, String, date (+19 more)

### Community 2 - "Audit & Changelog Docs"
Cohesion: 0.05
Nodes (45): Account Data Model, AddExpenseIntent (Shortcuts Extension), Budget Data Model, CategoryClassifier (Keyword Matching Engine), Category Data Model, EmptyStateView Reusable Component, Enterprise Readiness Roadmap, FormatterCache Singleton (+37 more)

### Community 3 - "Account Data Model"
Cohesion: 0.07
Nodes (34): CaseIterable, Account, AccountType, carta, contanti, conto, investimento, risparmio (+26 more)

### Community 4 - "Schema Migration & Decimal"
Cohesion: 0.13
Nodes (22): MigrationStage, Double, Account, Budget, DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+14 more)

### Community 5 - "Design System & Theme"
Cohesion: 0.09
Nodes (36): Color, DS, DSIcon, DSTransactionRow, EmptyStateView, FixedExpenseRow, GhostButton, haptic() (+28 more)

### Community 6 - "Currency Formatting & Notifications"
Cohesion: 0.09
Nodes (16): AnyObject, Transaction, NotificationScheduling, Date, Bool, String, AddGoalView, GoalRow (+8 more)

### Community 7 - "Add Transaction UI"
Cohesion: 0.08
Nodes (26): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView, Account, Bool (+18 more)

### Community 8 - "Onboarding Tour Manager"
Cohesion: 0.07
Nodes (26): Int, Bool, CGFloat, CGRect, Int, TourManager, Bool, CGFloat (+18 more)

### Community 9 - "Biometric App Lock"
Cohesion: 0.09
Nodes (22): LocalAuthentication, AppLockGate, AppLockState, LockOverlay, Bool, Content, View, Void (+14 more)

### Community 10 - "PDF Export & Formatter Cache"
Cohesion: 0.18
Nodes (17): CGContext, CGPoint, FormatterCache, DateFormatter, String, NumberFormatter, PDFReportGenerator, PDFTxSnapshot (+9 more)

### Community 11 - "Supabase Sync Coding Keys"
Cohesion: 0.07
Nodes (30): CodingKey, CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt (+22 more)

### Community 12 - "Supabase Auth & Cloud Sync"
Cohesion: 0.08
Nodes (16): App, Combine, FileProtectionType, SupabaseManager, Bool, String, applyFileProtection(), MoneyTrackerApp (+8 more)

### Community 13 - "App Entry & Domain Services"
Cohesion: 0.15
Nodes (7): Foundation, MoneyTracker, RecurringTransactionActor, OSLog, SwiftData, Testing, UserNotifications

### Community 14 - "Keyword Category Classifier"
Cohesion: 0.18
Nodes (9): Bundle, CategoryClassifying, KeywordCategoryClassifier, Int, String, KeywordCategoryClassifierTests, NSCache, NSString (+1 more)

### Community 15 - "Tab Bar Frame Capture"
Cohesion: 0.18
Nodes (12): CapView, CGFloat, CGRect, Context, Void, TabBarFrameCapture, NSCoder, UIKit (+4 more)

### Community 16 - "Apple Shortcuts Integration"
Cohesion: 0.16
Nodes (17): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+9 more)

### Community 17 - "Budget UI"
Cohesion: 0.24
Nodes (10): AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget, Date, Set (+2 more)

### Community 18 - "Planning View (Pianifica)"
Cohesion: 0.21
Nodes (9): PianificaView, Bool, Budget, Goal, Int, LocalizedStringKey, PersistentIdentifier, Transaction (+1 more)

### Community 19 - "Dashboard & Account Order"
Cohesion: 0.24
Nodes (7): DashboardView, HomeAccountOrderSheet, Account, Bool, Set, String, Transaction

### Community 20 - "Accounts Management UI"
Cohesion: 0.33
Nodes (6): AccountRow, AccountsView, AddAccountView, Account, Bool, String

### Community 21 - "Transfer Between Accounts"
Cohesion: 0.25
Nodes (6): AddTransferView, Account, Binding, Bool, Date, String

### Community 22 - "Login View"
Cohesion: 0.31
Nodes (6): AuthField, LoginView, Bool, Error, String, UIKeyboardType

### Community 23 - "Tour Highlight Anchoring"
Cohesion: 0.29
Nodes (5): String, TourAnchorKey, View, PreferenceKey, Value

### Community 24 - "Tour Overlay Geometry"
Cohesion: 0.43
Nodes (6): Anchor, GeometryProxy, CGFloat, CGRect, String, TourOverlayView

### Community 25 - "Share Sheet & Export"
Cohesion: 0.38
Nodes (5): Any, ShareSheet, Context, UIActivityViewController, UIViewControllerRepresentable

### Community 26 - "Budget Data Model"
Cohesion: 0.48
Nodes (6): Budget, Account, Date, Int, String, UUID

### Community 28 - "Sign Up View"
Cohesion: 0.47
Nodes (4): SignUpView, Bool, Error, String

### Community 29 - "Tour Overlay Cards"
Cohesion: 0.67
Nodes (3): ModalCard, StepCard, View

### Community 30 - "App Branding & Icon"
Cohesion: 1.00
Nodes (3): AppIcon Light 1024 — App Icon (Light Variant), Light Theme Branding — white/grey palette, minimalist design language, Visual Metaphor: Combined Bar + Line Chart with dot markers

## Knowledge Gaps
- **91 isolated node(s):** `AppIntents`, `importo`, `nome`, `contanti`, `carta` (+86 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **4 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Decimal` connect `Intents & Balance Computation` to `Data Seeding & Logging`, `Account Data Model`, `Schema Migration & Decimal`, `Design System & Theme`, `Currency Formatting & Notifications`, `PDF Export & Formatter Cache`, `Budget UI`, `Planning View (Pianifica)`, `Dashboard & Account Order`, `Accounts Management UI`, `Budget Data Model`?**
  _High betweenness centrality (0.229) - this node is a cross-community bridge._
- **Why does `SwiftData` connect `App Entry & Domain Services` to `Intents & Balance Computation`, `Data Seeding & Logging`, `Account Data Model`, `Schema Migration & Decimal`, `Design System & Theme`, `Currency Formatting & Notifications`, `Add Transaction UI`, `Biometric App Lock`, `Supabase Auth & Cloud Sync`, `Apple Shortcuts Integration`, `Budget UI`, `Dashboard & Account Order`, `Accounts Management UI`, `Transfer Between Accounts`, `App Root & Navigation`?**
  _High betweenness centrality (0.161) - this node is a cross-community bridge._
- **Why does `SwiftUI` connect `App Root & Navigation` to `Intents & Balance Computation`, `Account Data Model`, `Design System & Theme`, `Currency Formatting & Notifications`, `Add Transaction UI`, `Biometric App Lock`, `Supabase Auth & Cloud Sync`, `Tab Bar Frame Capture`, `Budget UI`, `Dashboard & Account Order`, `Accounts Management UI`, `Transfer Between Accounts`, `Login View`, `Tour Highlight Anchoring`, `Tour Overlay Cards`?**
  _High betweenness centrality (0.143) - this node is a cross-community bridge._
- **Are the 8 inferred relationships involving `Decimal` (e.g. with `.perform()` and `.perform()`) actually correct?**
  _`Decimal` has 8 INFERRED edges - model-reasoned connections that need verification._
- **What connects `AppIntents`, `importo`, `nome` to the rest of the system?**
  _95 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Intents & Balance Computation` be split into smaller, more focused modules?**
  _Cohesion score 0.08421985815602837 - nodes in this community are weakly interconnected._
- **Should `Data Seeding & Logging` be split into smaller, more focused modules?**
  _Cohesion score 0.10083256244218317 - nodes in this community are weakly interconnected._