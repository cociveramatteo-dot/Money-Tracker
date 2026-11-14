# Graph Report - MoneyTracker  (2026-11-14)

## Corpus Check
- 127 files · ~96,403 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1436 nodes · 2562 edges · 302 communities (76 shown, 226 thin omitted)
- Extraction: 92% EXTRACTED · 8% INFERRED · 0% AMBIGUOUS · INFERRED: 210 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `9dbdccea`
- Run `git rev-parse HEAD` and compare to check if the graph is stale.
- Run `graphify update .` after code changes (no API cost).

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
- Community 161
- Community 162
- Community 163
- Community 164
- Community 165
- Community 166
- Community 167
- Community 168
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
- SupabaseManager
- AuditLogger
- Budget.swift
- MoneyTrackerApp.swift
- AddTransactionView
- RecurringRule
- ShareSheet
- SyncStatus
- Option
- RecurringSeriesDetailView
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
- Transaction
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
- Date
- Goal
- String
- String
- Transaction
- URL
- SignUpView
- Date
- Financial Health Score (0-100, 5 dimensions)
- "Fissi del mese" Home card (fixed expense/income totals)
- Folder reorg + documentation consolidation into single doc
- FormatterCache singleton pattern
- Goal (savings goal) data model
- Obiettivi / GoalsView feature set
- Haptic feedback (swipe edit/delete)
- i18n-01: Siri section untranslated in any language
- i18n-02: hardcoded Italian accessibility labels
- "Interrompi ricorrenza" (stop recurrence) feature
- Italian tax features (Bollette, F24, Detrazioni 19%, 730, TFR trackers)
- On-device keyword-based category classifier
- Localization (7 languages, 340 keys/file)
- Tracciatore Patrimonio Netto (assets - liabilities)
- Nightly test automation (run_nightly_tests.sh + LaunchAgent, 4:00 AM)
- Onboarding Tour (two-level: overview + contextual hints)
- PERF-01: NumberFormatter/DateFormatter allocated per render
- PERF-02: hardcoded € symbol in AddAccountView/AddTransferView
- PERF-R01: Account.currentBalance O(n_tx), scales poorly >5000 tx
- PERF-R02: @Query without fetchLimit in DashboardView
- Privacy radicale / Completamente offline positioning
- Audit Qualità (Score 7.2/10)
- Fix: recurring transactions backfill missed periods instead of only current one
- Fix: recurring engine generated a duplicate occurrence for the template's own period
- Fix: recurring engine now also runs on foreground return, not just cold launch
- Recurring transaction engine (RecurringTransactionActor.processRecurring)
- MoneyTrackerTests/RecurringTransactionEngineTests.swift (backfill/dedup coverage)
- Roadmap Livello 2 — competitive necessities
- Roadmap Livello 4 — future (investments, crypto wallet, FIRE calculator, marketplace, public API)
- SEC-01: try! on ModelContainer in Shortcuts extension crashed on failure
- SEC-02: NotificationManager.isEnabled doesn't verify actual OS authorization
- SEC-04: CheckBalanceIntent biometric policy removed (iOS 26 API change)
- DS.positive/DS.negative semantic colors + DS.signColor(_:)
- Impostazioni / SettingsView feature set
- Setup e Installazione (Xcode signing, USB pairing, Shortcuts banner config)
- Apple Shortcuts integration (AddExpenseIntent)
- Singleton architectural pattern (NotificationManager.shared, FormatterCache)
- SMELL-01: CategoryManagementView empty section bare Text
- SMELL-02: AddGoalView/AddBudgetView missing @FocusState
- Split spese (bill splitting via contacts + iMessage/WhatsApp)
- Statistics trend: bar+line → side-by-side BarMark redesign
- Statistiche / StatisticsView feature set
- Subscription tracker (recurring payment detection, unused-subscription alerts)
- Supabase cross-device sync (in sviluppo; offline-first, TLS+AES-256, last-write-wins)
- Swift 6.0 strict concurrency
- SwiftData persistence (@Model, ModelContext, FetchDescriptor)
- Fix: local data wiped on passive session loss, replaced by stale Supabase snapshot
- Theme.swift design system (DS namespace, spacing, components)
- TourFlowUITests.swift (17-step onboarding regression test)
- Onboarding tour rewrite: per-tab icon spotlight → 16 element-level steps
- Transaction data model
- Movimenti / TransactionsView feature set
- Fix: transfer deletion confirmation dialog not firing inside "Trasf." section
- Edit existing transfer (AddTransferView editing: parameter)
- CSVFile Transferable (DataRepresentation, no temp file on disk)
- v1 (inverno 2025) — Base milestone
- v2 (primavera 2026) — Feature complete milestone
- v3 (giugno-luglio 2026) Enterprise audit: 43 improvements across 6 areas
- Apple Watch App (watchOS + WatchConnectivity, planned)
- WidgetKit Home/Lock Screen widget (planned)
- MoneyTrackerUITests XCUITest target (12 tests, 4 classes)
- "Stipendio → Zero" zero-based budgeting (YNAB-style)
- Budgeting (per category/account)
- Demo mode (try without account)
- Multi-account tracking
- Multi-device sync via Supabase
- Multi-language support (7 languages)
- Personal Finance Tracker (README)
- Savings goals
- Security via Supabase Row Level Security (RLS)
- Smart categorization (keyword-based)
- Visual insights (color-coded charts)
- Esito test notturno: TEST OK (tentativo 1/5)
- TxFilter
- SyncService.swift

## God Nodes (most connected - your core abstractions)
1. `Decimal` - 75 edges
2. `ModelContext` - 38 edges
3. `Foundation` - 37 edges
4. `SwiftData` - 37 edges
5. `CodingKeys` - 37 edges
6. `Double` - 34 edges
7. `SwiftUI` - 32 edges
8. `SyncService` - 29 edges
9. `TransactionsView` - 26 edges
10. `DashboardView` - 20 edges

## Surprising Connections (you probably didn't know these)
- `RecurrenceCalculatorTests` --calls--> `RecurrenceCalculator`  [INFERRED]
  MoneyTrackerTests/RecurrenceCalculatorTests.swift → MoneyTracker/Domain/RecurrenceCalculator.swift
- `RecurringMaterializerTests` --references--> `RecurringMaterializer`  [EXTRACTED]
  MoneyTrackerTests/RecurringMaterializerTests.swift → MoneyTracker/Domain/RecurringMaterializer.swift
- `RecurringSeriesEditorTests` --references--> `RecurringSeriesEditor`  [EXTRACTED]
  MoneyTrackerTests/RecurringSeriesEditorTests.swift → MoneyTracker/Domain/RecurringSeriesEditor.swift
- `MoneyTracker.pdf (distributable, generated from MoneyTracker.md via pandoc/Chrome)` --references--> `MoneyTracker — Documento Completo (master doc)`  [EXTRACTED]
  docs/MoneyTracker.pdf → docs/MoneyTracker.md
- `SyncService` --references--> `SupabaseManager`  [EXTRACTED]
  MoneyTracker/Sync/SyncService.swift → MoneyTracker/Auth/SupabaseManager.swift

## Import Cycles
- None detected.

## Communities (302 total, 226 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.17
Nodes (25): Color, DS, DSIcon, DSTransactionRow, EmptyStateView, FixedExpenseRow, FixedTotalTile, GhostButton (+17 more)

### Community 1 - "Ricorrenze — motore backfill & Intents dirty-tracking"
Cohesion: 0.18
Nodes (19): Codable, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport, JSONExportFile (+11 more)

### Community 2 - "Sync/ricorrenze — file sorgente del checkpoint settembre 2026"
Cohesion: 0.21
Nodes (5): Foundation, OSLog, SwiftData, UserNotifications, SupabaseConfig

### Community 3 - "Schema Migration V1→V2 (Decimal precision)"
Cohesion: 0.12
Nodes (24): MigrationStage, Account, Budget, decimalFromLegacyDouble(), DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan, SchemaV1 (+16 more)

### Community 4 - "Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)"
Cohesion: 0.08
Nodes (34): CryptoKit, DateInterval, Occurrence, RecurrenceCalculator, RecurrenceException, RecurrenceExceptionCodec, RuleSnapshot, Bool (+26 more)

### Community 5 - "Community 5"
Cohesion: 0.13
Nodes (11): NavigationStressUITests, MoneyTrackerUITestCase, String, StaticString, UInt, AccountFlowUITests, CategoryFlowUITests, TransactionFlowUITests (+3 more)

### Community 6 - "AppIntents — Tocco posteriore/Siri (AddExpenseIntent)"
Cohesion: 0.12
Nodes (23): DemoDataSeeder, Action, delete, edit, skipMonth, terminate, RecurringSeriesEditor, Bool (+15 more)

### Community 7 - "Supabase CodingKeys (snake_case mapping)"
Cohesion: 0.14
Nodes (15): DashboardView, HomeAccountOrderSheet, Account, Bool, CGFloat, Date, Int, LocalizedStringKey (+7 more)

### Community 8 - "Community 8"
Cohesion: 0.14
Nodes (8): Error, MaterializationError, requiresMainContext, saveFailed, UIKeyboardType, AuthField, LoginView, SignUpView

### Community 9 - "Community 9"
Cohesion: 0.24
Nodes (8): Binding, Bool, Date, Int, Transaction, Void, TransactionsView, View

### Community 10 - "Community 10"
Cohesion: 0.05
Nodes (36): Charts, Identifiable, IntentResult, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024), App Icon (Tinted, 1024x1024), AccountRow, AccountsView (+28 more)

### Community 11 - "Community 11"
Cohesion: 0.18
Nodes (15): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+7 more)

### Community 12 - "Community 12"
Cohesion: 0.20
Nodes (10): CGContext, CGPoint, FontRegistrationTests, UIColor, UIFont, UIGraphicsPDFRendererContext, UIKit, NumberFormatter (+2 more)

### Community 14 - "Community 14"
Cohesion: 0.22
Nodes (5): Bundle, NSCache, NSString, KeywordCategoryClassifier, KeywordCategoryClassifierTests

### Community 15 - "Community 15"
Cohesion: 0.20
Nodes (9): a) Diagnosi: perché oggi le ricorrenti "non compaiono", b) Modello dati, c) Algoritmi, d) Eccezioni (`Domain/RecurringSeriesEditor.swift`, `@MainActor`), Domande per Matteo, e) Viste (solo interfaccia dati, la grafica la fa l'impresa grafica sul mockup), f) Test (Swift Testing, `@Suite`, container in memoria `SchemaV3`), g) Sotto-task (ordine obbligato) (+1 more)

### Community 16 - "SettingsView — biometria, export, GDPR"
Cohesion: 0.21
Nodes (7): LocalAuthentication, AppLockGate, AppLockState, LockOverlay, View, BiometricAuthenticating, LAContextAuthenticator

### Community 17 - "Community 17"
Cohesion: 0.15
Nodes (13): LocalizedError, EditorError, crossMonthOverride, invalidOccurrence, invalidValues, requiresMainContext, RecurrenceOperationStatus, Scope (+5 more)

### Community 20 - "Community 20"
Cohesion: 0.29
Nodes (6): Chi fa meglio cosa (osservazioni, non verità: aggiornare), Cosa va bene (da tenere), Da cambiare nell'azienda (priorità alta), Esiti recenti, LEZIONI PER L'AZIENDA — da MoneyTracker (redesign Sentiero), Suggerimenti per la versione successiva

### Community 22 - "Community 22"
Cohesion: 0.15
Nodes (13): App, MoneyTrackerApp, Bool, ModelContainer, Never, String, Task, UUID (+5 more)

### Community 27 - "Community 27"
Cohesion: 0.10
Nodes (23): CGSize, Equatable, GraphicsContext, BalanceTrail, Entry, Point, Bool, Calendar (+15 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (20): chiave(), leggi(), Lettore, main(), Pagina, Path, radice_web(), Cartella servita come "/" del sito: quella con index.html più vicina alla radice (+12 more)

### Community 30 - "Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate"
Cohesion: 0.06
Nodes (35): CodingKey, CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt (+27 more)

### Community 31 - "Community 31"
Cohesion: 0.17
Nodes (11): Cartellino, Claude Code = CAPOCANTIERE, Commissione Suprema (controllo qualità pre-checkpoint), Graphify, graphify, MoneyTracker — Istruzioni per Claude, Quando un'impresa o un subagente ha finito, Regole del cantiere (il resto di questo file ha la precedenza in caso di conflitto) (+3 more)

### Community 34 - "Community 34"
Cohesion: 0.11
Nodes (24): accessibilita(), AXE, BASE, cliccaTutto(), confrontaScreenshot(), controllaLink(), controllaPagina(), differenze (+16 more)

### Community 35 - "Community 35"
Cohesion: 0.33
Nodes (6): Kind, expense, income, transfer, MovementRow, String

### Community 36 - "Community 36"
Cohesion: 0.22
Nodes (5): String, Goal, AuditLogView, AddGoalView, GoalRow

### Community 37 - "Community 37"
Cohesion: 0.31
Nodes (3): AddCategoryView, CategoryManagementView, CategoryRow

### Community 38 - "Community 38"
Cohesion: 0.09
Nodes (21): Fatti, In corso / prossimi, PIANO DEI LAVORI, S-0 [x] Rimozione del tour, S-10 [ ] Verifica finale + Commissione Suprema, S-11 [x] Riserve da S-5 (XL e badge demo) — assorbito da S-12; resta solo tab bar XL in S-10, S-12 [x] Movimenti: pagina unica + zona sotto i chip + Ricorrenti (da mockup) — collaudo 2026-11-14 01:30 ok, S-13 [ ] Motore ricorrenze a serie virtuali (D-008) (+13 more)

### Community 39 - "Community 39"
Cohesion: 0.12
Nodes (16): 10. Changelog, v1 (inverno 2025) — Base, v2 (primavera 2026) — Feature complete, v3 (giugno–luglio 2026) — Enterprise audit e bug fix, v3.x (agosto 2026) — Nuova icona, nuovo nome "Bucktrail", grafico trend a barre affiancate, v3.x (agosto 2026) — Rettifica saldo conto, fix trigger ricorrenze, interrompi ricorrenza, v3.x (luglio 2026) — Card "Fissi del mese" in Home + tour onboarding testato end-to-end, v3.x (luglio 2026) — Colori semantici positivo/negativo, fix ricorrenze, tour a due livelli riscritto (+8 more)

### Community 40 - "Community 40"
Cohesion: 0.12
Nodes (16): 6. Funzionalità Implementate, Aggiunta Transazione (AddTransactionView), Biometria (Auth/), Budget (BudgetView), Conti (AccountsView), Haptic Feedback, Home (DashboardView), Impostazioni (SettingsView) (+8 more)

### Community 42 - "Community 42"
Cohesion: 0.39
Nodes (3): RecurringRuleSyncTests, Date, ModelContainer

### Community 43 - "Community 43"
Cohesion: 0.20
Nodes (9): CaseIterable, CategoryTint, amber, blue, green, violet, String, UInt32 (+1 more)

### Community 44 - "Community 44"
Cohesion: 0.15
Nodes (11): CATEGORIE, data, dirLh, lh, OUT, perTipo, principali, r (+3 more)

### Community 45 - "Community 45"
Cohesion: 0.18
Nodes (9): FloatingTabBar, Item, CGFloat, Int, LocalizedStringKey, String, ContentView, LocalizedStringKey (+1 more)

### Community 46 - "Community 46"
Cohesion: 0.17
Nodes (11): dependencies, axe-core, gremlins.js, lighthouse, pixelmatch, playwright, pngjs, description (+3 more)

### Community 48 - "Community 48"
Cohesion: 0.21
Nodes (3): AnyObject, SystemNotificationManager, NotificationScheduling

### Community 49 - "Community 49"
Cohesion: 0.12
Nodes (13): AccountBalanceCache, Account, AccountType, carta, contanti, conto, investimento, risparmio (+5 more)

### Community 50 - "Community 50"
Cohesion: 0.38
Nodes (9): esegui_json(), limita(), main(), peso_locale_kb(), Path, radice(), Interpolazione lineare a tratti: punti = [(x, voto), ...] con x crescente., Peso della home: HTML + risorse locali che richiama (stima senza browser). (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.20
Nodes (9): 11. Workflow Checkpoint, 2. Stack Tecnico e Architettura, 3. Struttura del Progetto, 8. Roadmap, Livello 2 — Necessario per essere competitivi, Livello 3 — Feature WOW (differenziazione totale), Livello 4 — Futuro, MoneyTracker — Documento Completo (+1 more)

### Community 55 - "Community 55"
Cohesion: 0.22
Nodes (8): 1. Il progetto, 2. La squadra, 3. Frasi-comando (uguali con ogni IA: le skill sono in `.agents/skills/`), 4. Turni (uno alla volta, sempre), 5. Lettura a strati (per risparmiare crediti), 6. Regole ferree, 7. Cartelle e nomi, REGOLAMENTO DI CANTIERE — MoneyTracker

### Community 56 - "Community 56"
Cohesion: 0.17
Nodes (11): D-001 · 2026-11-13 · Adozione del modello Cantiere, D-002 · 2026-11-13 · Rimosso il guardiano dei siti web, D-003 · 2026-11-13 · `@MainActor` su CurrencyFormattingTests, D-004 · 2026-11-13 · Simulatore di riferimento, D-005 · 2026-11-13 · Token «Sentiero» e dark mode (S-1), D-006 · 2026-11-13 · Tinte categoria, D-007 · 2026-11-13 · Serie del saldo per la TrailView, D-008 · 2026-11-13 · Nuovo motore delle ricorrenze (serie virtuali) — ok scritto di Matteo (+3 more)

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (7): candidati(), impronta(), leggi_fonti(), magazzino(), main(), Path, scrivi_fonti()

### Community 61 - "Community 61"
Cohesion: 0.29
Nodes (7): 4. Modelli Dati, Account, Budget, Category, FormatterCache (performance), Goal (Obiettivo di risparmio), Transaction

### Community 63 - "Community 63"
Cohesion: 0.29
Nodes (7): FilterChip, Style, advanced, primary, secondary, Text, Void

### Community 64 - "Community 64"
Cohesion: 0.33
Nodes (5): Catalogo, Da controllare prima di entrare sullo scaffale, Impronte (sha256, primi 16 caratteri), SCAFFALE DELLE SKILL, Scartate

### Community 65 - "Community 65"
Cohesion: 0.33
Nodes (5): Albo delle assunzioni, Quando un'IA è senza quota, Smistamento (chi fa cosa) — regola: il più economico che lo fa bene, Squadra fissa, SQUADRA — organigramma, smistamento e albo delle assunzioni

### Community 66 - "Community 66"
Cohesion: 0.47
Nodes (4): main(), Path, tipo_di(), trova_magazzino()

### Community 67 - "Community 67"
Cohesion: 0.33
Nodes (6): 5. Design System (Theme.swift), App Icon (Assets.xcassets/AppIcon.appiconset), Componenti riutilizzabili, Modalità chiara e scura, Palette colori — «Sentiero», Spacing

### Community 68 - "Community 68"
Cohesion: 0.33
Nodes (6): 9. Setup e Installazione, Configurare il banner Shortcuts, Errori comuni, Installazione da sorgente, Note, Requisiti

### Community 69 - "Community 69"
Cohesion: 0.29
Nodes (7): haptic(), HapticStyle, light, medium, rigid, soft, success

### Community 70 - "Community 70"
Cohesion: 0.33
Nodes (4): Content, View, ThemeNavBarModifier, ViewModifier

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (5): Cantiere di sviluppo, Features, Personal Finance Tracker, Security, Tech Stack

### Community 72 - "Community 72"
Cohesion: 0.50
Nodes (3): Aggiornamento 2026-11-14 10:27, CONSEGNA — collaudo SQL S-13f (563980d), Prossimo: Matteo, S-13e

### Community 73 - "Community 73"
Cohesion: 0.80
Nodes (4): esegui(), manca(), peggiora(), collaudo.sh script

### Community 74 - "Community 74"
Cohesion: 0.60
Nodes (4): main(), Path, radice_progetto(), suggerisci()

### Community 75 - "Community 75"
Cohesion: 0.40
Nodes (5): 1. Visione e Posizionamento, Differenziatori chiave, L'idea centrale, Modello di business, Posizionamento in una frase

### Community 77 - "Community 77"
Cohesion: 0.50
Nodes (3): CHECKPOINT — MoneyTracker, Prima cosa da fare alla ripresa, Siamo qui

### Community 78 - "Community 78"
Cohesion: 0.50
Nodes (3): Come si costruisce, Dettaglio, MAPPA DEL CANTIERE — dove sta tutto

### Community 79 - "Community 79"
Cohesion: 0.40
Nodes (4): Da fare, ✅ FATTA 2026-11-14 10:27 · S-13e — Creare `mt_recurring_rules` (SQL preparato in S-13f), Fatte, PER MATTEO — le cose che aspettano te

### Community 81 - "Community 81"
Cohesion: 0.50
Nodes (4): 7. Audit Qualità (Score: 7.2 / 10), Bug risolti (sessioni precedenti), Cosa funziona bene, Issue residue (non critiche)

### Community 82 - "Community 82"
Cohesion: 0.50
Nodes (3): Dettaglio tentativi, Modifiche automatiche, Report notturno MoneyTracker — 25/07/2026

### Community 165 - "Community 165"
Cohesion: 0.12
Nodes (12): BudgetStatus, Text, Card, Content, HeroCard, Text, Layout, Space (+4 more)

### Community 181 - "Community 181"
Cohesion: 0.18
Nodes (9): Account, Budget, Goal, Never, Task, Transaction, Void, SyncService (+1 more)

### Community 182 - "Community 182"
Cohesion: 0.27
Nodes (3): RecurringSeries, RecurringSeriesDetector, AddTransferView

### Community 183 - "SupabaseManager"
Cohesion: 0.22
Nodes (4): ObservableObject, Session, SupabaseClient, SupabaseManager

### Community 185 - "Budget.swift"
Cohesion: 0.36
Nodes (3): AddBudgetView, BudgetHistorySheet, BudgetRow

### Community 186 - "MoneyTrackerApp.swift"
Cohesion: 0.25
Nodes (6): Auth, Combine, FileProtectionType, applyFileProtection(), URL, Supabase

### Community 187 - "AddTransactionView"
Cohesion: 0.29
Nodes (6): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView

### Community 188 - "RecurringRule"
Cohesion: 0.43
Nodes (5): RecurringRule, Bool, Date, String, UUID

### Community 189 - "ShareSheet"
Cohesion: 0.38
Nodes (5): Any, Context, ShareSheet, UIActivityViewController, UIViewControllerRepresentable

### Community 190 - "SyncStatus"
Cohesion: 0.33
Nodes (6): Int, SyncStatus, idle, offline, syncing, waitingForRetry

### Community 191 - "Option"
Cohesion: 0.60
Nodes (4): Option, SegmentedPill, Text, Selection

### Community 192 - "RecurringSeriesDetailView"
Cohesion: 0.50
Nodes (3): RecurringSeriesDetailView, String, Transaction

### Community 306 - "TxFilter"
Cohesion: 0.22
Nodes (8): TxFilter, entrate, fisse, ricorrenti, trasf, tutti, uscite, View

### Community 309 - "SyncService.swift"
Cohesion: 0.22
Nodes (12): Encoder, SBAccount, SBBudget, SBGoal, SBRecurringRule, SBTransaction, Bool, Date (+4 more)

## Knowledge Gaps
- **365 isolated node(s):** `backup.sh script`, `esegui.sh script`, `CHROME_PATH`, `require`, `AXE` (+360 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **226 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Decimal` connect `Community 10` to `CategoryManagementView & AddTransactionView`, `Ricorrenze — motore backfill & Intents dirty-tracking`, `Schema Migration V1→V2 (Decimal precision)`, `Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)`, `Community 36`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `Supabase CodingKeys (snake_case mapping)`, `Community 42`, `SyncService.swift`, `Community 27`, `RecurringRule`?**
  _High betweenness centrality (0.086) - this node is a cross-community bridge._
- **Why does `SwiftData` connect `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` to `CategoryManagementView & AddTransactionView`, `Ricorrenze — motore backfill & Intents dirty-tracking`, `Schema Migration V1→V2 (Decimal precision)`, `Supabase CodingKeys (snake_case mapping)`, `Community 10`, `Community 11`, `Community 17`, `Community 36`, `Community 37`, `Community 45`, `Community 49`, `TxFilter`, `SyncService.swift`, `Community 182`, `AuditLogger`, `Budget.swift`, `Community 58`, `MoneyTrackerApp.swift`, `AddTransactionView`, `RecurringSeriesDetailView`?**
  _High betweenness centrality (0.056) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` to `Ricorrenze — motore backfill & Intents dirty-tracking`, `Schema Migration V1→V2 (Decimal precision)`, `Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)`, `Community 37`, `MoneyTrackerApp.swift`, `Community 11`, `SettingsView — biometria, export, GDPR`, `Community 17`, `Community 49`, `SyncService.swift`, `Community 182`, `AuditLogger`, `Budget.swift`, `Community 58`, `Community 27`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **Are the 31 inferred relationships involving `Decimal` (e.g. with `.perform()` and `.perform()`) actually correct?**
  _`Decimal` has 31 INFERRED edges - model-reasoned connections that need verification._
- **Are the 14 inferred relationships involving `ModelContext` (e.g. with `.mainContextOnly()` and `.allFrequenciesAndDoneEdits()`) actually correct?**
  _`ModelContext` has 14 INFERRED edges - model-reasoned connections that need verification._
- **What connects `backup.sh script`, `Cartella servita come "/" del sito: quella con index.html più vicina alla radice`, `(lingua dalla cartella, percorso senza cartella della lingua).` to the rest of the system?**
  _391 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Schema Migration V1→V2 (Decimal precision)` be split into smaller, more focused modules?**
  _Cohesion score 0.11839323467230443 - nodes in this community are weakly interconnected._