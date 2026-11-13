# Graph Report - MoneyTracker  (2026-11-13)

## Corpus Check
- 119 files · ~83,283 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1629 nodes · 3023 edges · 228 communities (80 shown, 148 thin omitted)
- Extraction: 94% EXTRACTED · 6% INFERRED · 0% AMBIGUOUS · INFERRED: 192 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `f5aac301`
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
- Budget
- Date
- Goal
- Int
- Never
- Notification
- Set
- String
- Task
- Transaction
- UUID
- Void
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
- ModelContainer
- URL

## God Nodes (most connected - your core abstractions)
1. `Foundation` - 58 edges
2. `SwiftData` - 56 edges
3. `Decimal` - 53 edges
4. `Decimal` - 46 edges
5. `MoneyTracker — Documento Completo (master doc)` - 45 edges
6. `SwiftUI` - 42 edges
7. `Transaction` - 36 edges
8. `CodingKeys` - 32 edges
9. `Double` - 32 edges
10. `CodingKeys` - 31 edges

## Surprising Connections (you probably didn't know these)
- `Personal Finance Tracker (README)` --semantically_similar_to--> `MoneyTracker — Documento Completo (master doc)`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Multi-account tracking` --semantically_similar_to--> `Conti / AccountsView feature set`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Smart categorization (keyword-based)` --semantically_similar_to--> `On-device keyword-based category classifier`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Budgeting (per category/account)` --semantically_similar_to--> `Budget / BudgetView feature set`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md
- `Savings goals` --semantically_similar_to--> `Obiettivi / GoalsView feature set`  [INFERRED] [semantically similar]
  README.md → docs/MoneyTracker.md

## Import Cycles
- None detected.

## Hyperedges (group relationships)
- **September 2026 sync/recurring bug-fix cluster (shared root cause: local↔cloud sync + recurring engine)** — docs_moneytracker_app_group_bug_fix, docs_moneytracker_sync_clearlocaldata_bug, docs_moneytracker_recurring_backfill_fix, docs_moneytracker_decimal_migration_fix [INFERRED 0.85]
- **SwiftData schema: Account, Transaction, Budget, Goal, Category models** — docs_moneytracker_account_model, docs_moneytracker_transaction_model, docs_moneytracker_budget_model, docs_moneytracker_goal_model, docs_moneytracker_category_model [EXTRACTED 1.00]
- **Recurring transaction engine evolution (trigger fix → backfill → dedup → stop-recurrence feature)** — docs_moneytracker_recurring_transaction_engine, docs_moneytracker_recurring_foreground_trigger_fix, docs_moneytracker_recurring_backfill_fix, docs_moneytracker_recurring_duplicate_fix, docs_moneytracker_interrompi_ricorrenza_feature [INFERRED 0.85]

## Communities (228 total, 148 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.17
Nodes (25): Color, DS, DSIcon, DSTransactionRow, EmptyStateView, FixedExpenseRow, FixedTotalTile, GhostButton (+17 more)

### Community 1 - "Ricorrenze — motore backfill & Intents dirty-tracking"
Cohesion: 0.05
Nodes (40): Codable, IntentResult, AccountBalanceCache, Decimal, Budget, Goal, SBAccount, SBBudget (+32 more)

### Community 2 - "Sync/ricorrenze — file sorgente del checkpoint settembre 2026"
Cohesion: 0.06
Nodes (16): AnyObject, Combine, Foundation, MoneyTracker, SupabaseConfig, NotificationScheduling, FormatterCache, Category (+8 more)

### Community 3 - "Schema Migration V1→V2 (Decimal precision)"
Cohesion: 0.25
Nodes (5): Double, decimalFromLegacyDouble(), DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan

### Community 4 - "Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)"
Cohesion: 0.07
Nodes (11): AuthField, LoginView, SupabaseManager, SystemNotificationManager, ModelContext, SyncService, ObservableObject, Session (+3 more)

### Community 5 - "Community 5"
Cohesion: 0.08
Nodes (16): AccountFlowUITests, CategoryFlowUITests, NavigationStressUITests, TourFlowUITests, TransactionFlowUITests, MoneyTrackerUITestCase, String, StaticString (+8 more)

### Community 6 - "AppIntents — Tocco posteriore/Siri (AddExpenseIntent)"
Cohesion: 0.14
Nodes (19): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+11 more)

### Community 7 - "Supabase CodingKeys (snake_case mapping)"
Cohesion: 0.07
Nodes (29): CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt, currentAmount (+21 more)

### Community 8 - "Community 8"
Cohesion: 0.15
Nodes (4): ContextualHint, movimentiSection, TourManager, OverviewStep

### Community 9 - "Community 9"
Cohesion: 0.14
Nodes (15): DashboardView, HomeAccountOrderSheet, Account, Bool, CGFloat, Date, Int, LocalizedStringKey (+7 more)

### Community 10 - "Community 10"
Cohesion: 0.05
Nodes (36): Any, Charts, Context, Identifiable, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024), App Icon (Tinted, 1024x1024), ProgressBar (+28 more)

### Community 11 - "Community 11"
Cohesion: 0.29
Nodes (6): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView

### Community 12 - "Community 12"
Cohesion: 0.12
Nodes (16): CGContext, CGPoint, RecurringSeries, RecurringSeriesDetector, NumberFormatter, PDFReportGenerator, PDFTxSnapshot, Date (+8 more)

### Community 13 - "AddTransactionView & roadmap funzionalità future"
Cohesion: 0.09
Nodes (25): AddTransactionView (add transaction flow), "Me lo posso permettere?" conversational afford-check shortcut, AI Financial Coach (monthly on-device report, optional Claude Haiku synthesis), Automatic bank connection (GoCardless/Nordigen API), Business model: one-time purchase (€4,99) + future optional Premium subscription, Calendario flusso di cassa (day-by-day balance projection), Claude Haiku API (optional AI coach synthesis), Financial Health Score (0-100, 5 dimensions) (+17 more)

### Community 14 - "Community 14"
Cohesion: 0.10
Nodes (10): Bundle, CategoryClassifying, KeywordCategoryClassifier, Logger, KeywordCategoryClassifierTests, NSCache, NSString, CategoryClassifying (+2 more)

### Community 15 - "Community 15"
Cohesion: 0.16
Nodes (12): CaseIterable, Account, AccountType, carta, contanti, conto, investimento, risparmio (+4 more)

### Community 16 - "SettingsView — biometria, export, GDPR"
Cohesion: 0.21
Nodes (7): LocalAuthentication, AppLockGate, AppLockState, LockOverlay, View, BiometricAuthenticating, LAContextAuthenticator

### Community 17 - "Community 17"
Cohesion: 0.21
Nodes (3): AuditLogger, Entry, AuditLogView

### Community 18 - "Bug noti Dashboard/GoalsView & FormatterCache"
Cohesion: 0.12
Nodes (17): BUG-01: DashboardView List+fixed frame truncated text with Dynamic Type, BUG-02: GoalsView.load() showed "1000.0" instead of "1000", BUG-03: CategoryStat.id unstable UUID broke SwiftUI diffing, BUG-04: debug print() in TabBarFrameCapture hot path, FormatterCache singleton pattern, i18n-01: Siri section untranslated in any language, i18n-02: hardcoded Italian accessibility labels, PERF-01: NumberFormatter/DateFormatter allocated per render (+9 more)

### Community 19 - "AddTransferView, changelog, automazione test notturni"
Cohesion: 0.15
Nodes (23): AddTransferView (transfer flow), App Group fix: back-tap/Siri expenses saved into an invisible sandbox store, Fix: back-tap/Siri transactions disappeared after save (markTransactionDirty), Changelog (section 10), Claude Code headless (automated nightly fix agent), Demo mode / deterministic UI-testing data (--uitesting launch arg), Folder reorg + documentation consolidation into single doc, "Interrompi ricorrenza" (stop recurrence) feature (+15 more)

### Community 20 - "Community 20"
Cohesion: 0.23
Nodes (6): AppLockGate, AppLockState, LockOverlay, View, BiometricAuthenticating, LAContextAuthenticator

### Community 21 - "Community 21"
Cohesion: 0.33
Nodes (4): HintCard, ModalCard, StepCard, TourOverlayView

### Community 22 - "Community 22"
Cohesion: 0.06
Nodes (26): App, FileProtectionType, DemoDataSeeder, IntentContainer, applyFileProtection(), MoneyTrackerApp, Bool, ModelContainer (+18 more)

### Community 23 - "Community 23"
Cohesion: 0.09
Nodes (15): SignUpView, AddCategoryView, CategoryManagementView, CategoryRow, FilterChip, Style, advanced, primary (+7 more)

### Community 24 - "Budget/Obiettivi & localizzazione 7 lingue"
Cohesion: 0.17
Nodes (15): Budget / BudgetView feature set, Home / DashboardView feature set, Modalità Coppia/Famiglia (shared DB via CloudKit/Supabase), "Fissi del mese" Home card (fixed expense/income totals), Obiettivi / GoalsView feature set, Localization (7 languages, 340 keys/file), SEC-01: try! on ModelContainer in Shortcuts extension crashed on failure, Supabase cross-device sync (in sviluppo; offline-first, TLS+AES-256, last-write-wins) (+7 more)

### Community 25 - "Modelli dati (Account/Budget/Transaction) & rettifica saldo"
Cohesion: 0.31
Nodes (9): Account balance correction via "Rettifica saldo" adjustment transaction, Account data model, Conti / AccountsView feature set, Budget data model, Category data model, Fix: Double→Decimal migration precision (SchemaMigration.swift), Transaction data model, v1 (inverno 2025) — Base milestone (+1 more)

### Community 26 - "Design system, App Icon Bucktrail, colori semantici"
Cohesion: 0.22
Nodes (9): App Icon (light/dark/tinted variants, bar-chart design), New App Icon design (minimal ascending bars, gold/amber accent), Display name "Bucktrail" vs technical project name "MoneyTracker", DS.positive/DS.negative semantic colors + DS.signColor(_:), Statistics trend: bar+line → side-by-side BarMark redesign, Statistiche / StatisticsView feature set, Theme.swift design system (DS namespace, spacing, components), CSVFile Transferable (DataRepresentation, no temp file on disk) (+1 more)

### Community 27 - "Community 27"
Cohesion: 0.07
Nodes (32): CGSize, Equatable, GraphicsContext, BalanceTrail, Entry, Point, Bool, Calendar (+24 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (20): chiave(), leggi(), Lettore, main(), Pagina, Path, radice_web(), Cartella servita come "/" del sito: quella con index.html più vicina alla radice (+12 more)

### Community 30 - "Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate"
Cohesion: 0.07
Nodes (30): CodingKey, CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt (+22 more)

### Community 31 - "Community 31"
Cohesion: 0.12
Nodes (15): Cartellino, Claude Code = CAPOCANTIERE, Commissione Suprema — 6 giudici, tolleranza zero, 10/10 richiesto prima del commit, Commissione Suprema (controllo qualità pre-checkpoint), Struttura cartella immutabile (regola), Graphify, graphify, Istruzioni Graphify (query/--update) (+7 more)

### Community 32 - "Biometria & roadmap Livello 2 (Watch/Widget)"
Cohesion: 0.29
Nodes (7): Biometric app lock (AppLockGate, Face ID/Touch ID), Fix: Level-2 contextual mini-tours never appeared, Onboarding Tour (two-level: overview + contextual hints), Roadmap Livello 2 — competitive necessities, Onboarding tour rewrite: per-tab icon spotlight → 16 element-level steps, Apple Watch App (watchOS + WatchConnectivity, planned), WidgetKit Home/Lock Screen widget (planned)

### Community 34 - "Community 34"
Cohesion: 0.11
Nodes (24): accessibilita(), AXE, BASE, cliccaTutto(), confrontaScreenshot(), controllaLink(), controllaPagina(), differenze (+16 more)

### Community 35 - "Community 35"
Cohesion: 0.19
Nodes (5): RecurringSeries, RecurringSeriesDetector, SBTransaction, AddTransferView, RecurringSeriesDetailView

### Community 36 - "Community 36"
Cohesion: 0.19
Nodes (7): String, SignUpView, Account, Budget, Goal, Transaction, AuditLogView

### Community 37 - "Community 37"
Cohesion: 0.17
Nodes (8): AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView, AddCategoryView, CategoryManagementView, CategoryRow

### Community 38 - "Community 38"
Cohesion: 0.12
Nodes (15): Fatti, In corso / prossimi, PIANO DEI LAVORI, S-0 [x] Rimozione del tour, S-10 [ ] Verifica finale + Commissione Suprema, S-1 [x] Token, font, dark mode, S-2 [x] Componenti base (chiuso 2026-11-13 20:40, collaudatore), S-2b [x] Correzioni componenti base (+7 more)

### Community 39 - "Community 39"
Cohesion: 0.12
Nodes (16): 10. Changelog, v1 (inverno 2025) — Base, v2 (primavera 2026) — Feature complete, v3 (giugno–luglio 2026) — Enterprise audit e bug fix, v3.x (agosto 2026) — Nuova icona, nuovo nome "Bucktrail", grafico trend a barre affiancate, v3.x (agosto 2026) — Rettifica saldo conto, fix trigger ricorrenze, interrompi ricorrenza, v3.x (luglio 2026) — Card "Fissi del mese" in Home + tour onboarding testato end-to-end, v3.x (luglio 2026) — Colori semantici positivo/negativo, fix ricorrenze, tour a due livelli riscritto (+8 more)

### Community 40 - "Community 40"
Cohesion: 0.12
Nodes (16): 6. Funzionalità Implementate, Aggiunta Transazione (AddTransactionView), Biometria (Auth/), Budget (BudgetView), Conti (AccountsView), Haptic Feedback, Home (DashboardView), Impostazioni (SettingsView) (+8 more)

### Community 41 - "Community 41"
Cohesion: 0.21
Nodes (5): MigrationStage, SchemaMigrationPlan, decimalFromLegacyDouble(), DecimalMigrationBuffer, MoneyTrackerMigrationPlan

### Community 42 - "Community 42"
Cohesion: 0.18
Nodes (7): AccountBalanceCache, Budget, Transaction, TransactionType, entrata, uscita, SBAccount

### Community 43 - "Community 43"
Cohesion: 0.22
Nodes (8): CategoryTint, amber, blue, green, violet, String, UInt32, CategoryTintTests

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
Cohesion: 0.22
Nodes (4): Goal, SBGoal, AddGoalView, GoalRow

### Community 49 - "Community 49"
Cohesion: 0.27
Nodes (4): SBBudget, AddBudgetView, BudgetHistorySheet, BudgetRow

### Community 50 - "Community 50"
Cohesion: 0.38
Nodes (9): esegui_json(), limita(), main(), peso_locale_kb(), Path, radice(), Interpolazione lineare a tratti: punti = [(x, voto), ...] con x crescente., Peso della home: HTML + risorse locali che richiama (stima senza browser). (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.20
Nodes (9): 11. Workflow Checkpoint, 2. Stack Tecnico e Architettura, 3. Struttura del Progetto, 8. Roadmap, Livello 2 — Necessario per essere competitivi, Livello 3 — Feature WOW (differenziazione totale), Livello 4 — Futuro, MoneyTracker — Documento Completo (+1 more)

### Community 52 - "Community 52"
Cohesion: 0.42
Nodes (3): RecurringTransactionActor, Account, RecurringTransactionEngineTests

### Community 53 - "Community 53"
Cohesion: 0.31
Nodes (7): SchemaV1, SchemaV2, SchemaMigrationTests, PersistentModel, SchemaV1, SchemaV2, VersionedSchema

### Community 54 - "Community 54"
Cohesion: 0.31
Nodes (4): Budget, AddBudgetView, BudgetHistorySheet, BudgetRow

### Community 55 - "Community 55"
Cohesion: 0.22
Nodes (8): 1. Il progetto, 2. La squadra, 3. Frasi-comando (uguali con ogni IA: le skill sono in `.agents/skills/`), 4. Turni (uno alla volta, sempre), 5. Lettura a strati (per risparmiare crediti), 6. Regole ferree, 7. Cartelle e nomi, REGOLAMENTO DI CANTIERE — MoneyTracker

### Community 56 - "Community 56"
Cohesion: 0.22
Nodes (8): D-001 · 2026-11-13 · Adozione del modello Cantiere, D-002 · 2026-11-13 · Rimosso il guardiano dei siti web, D-003 · 2026-11-13 · `@MainActor` su CurrencyFormattingTests, D-004 · 2026-11-13 · Simulatore di riferimento, D-005 · 2026-11-13 · Token «Sentiero» e dark mode (S-1), D-006 · 2026-11-13 · Tinte categoria, D-007 · 2026-11-13 · Serie del saldo per la TrailView, REGISTRO DELLE DECISIONI

### Community 57 - "Community 57"
Cohesion: 0.25
Nodes (7): TxFilter, entrate, fisse, ricorrenti, trasf, tutti, uscite

### Community 58 - "Community 58"
Cohesion: 0.28
Nodes (7): Account, AccountType, carta, contanti, conto, investimento, risparmio

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (7): candidati(), impronta(), leggi_fonti(), magazzino(), main(), Path, scrivi_fonti()

### Community 61 - "Community 61"
Cohesion: 0.29
Nodes (7): 4. Modelli Dati, Account, Budget, Category, FormatterCache (performance), Goal (Obiettivo di risparmio), Transaction

### Community 62 - "Community 62"
Cohesion: 0.33
Nodes (6): Kind, expense, income, transfer, MovementRow, String

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
Cohesion: 0.33
Nodes (6): HapticStyle, light, medium, rigid, soft, success

### Community 70 - "Community 70"
Cohesion: 0.33
Nodes (4): Content, View, ThemeNavBarModifier, ViewModifier

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (5): Cantiere di sviluppo, Features, Personal Finance Tracker, Security, Tech Stack

### Community 72 - "Community 72"
Cohesion: 0.40
Nodes (4): CONSEGNA — il biglietto per chi entra in turno, Fatto, Note per la resa a vista (Matteo), Prossimo passo

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
Cohesion: 0.50
Nodes (3): Da fare, Fatte, PER MATTEO — le cose che aspettano te

### Community 81 - "Community 81"
Cohesion: 0.50
Nodes (4): 7. Audit Qualità (Score: 7.2 / 10), Bug risolti (sessioni precedenti), Cosa funziona bene, Issue residue (non critiche)

### Community 82 - "Community 82"
Cohesion: 0.50
Nodes (3): Dettaglio tentativi, Modifiche automatiche, Report notturno MoneyTracker — 25/07/2026

### Community 165 - "Community 165"
Cohesion: 0.10
Nodes (13): BudgetStatus, Text, Card, Content, HeroCard, Text, RecurringSeriesDetailView, Layout (+5 more)

### Community 168 - "Community 168"
Cohesion: 0.29
Nodes (7): Transaction, haptic(), Binding, Bool, Int, Transaction, TransactionsView

## Knowledge Gaps
- **315 isolated node(s):** `backup.sh script`, `esegui.sh script`, `CHROME_PATH`, `require`, `AXE` (+310 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **148 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `SwiftData` connect `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` to `CategoryManagementView & AddTransactionView`, `Ricorrenze — motore backfill & Intents dirty-tracking`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `Community 9`, `Community 10`, `Community 11`, `Community 23`, `Community 35`, `Community 36`, `Community 165`, `Community 37`, `Community 42`, `Community 45`, `Community 48`, `Community 49`, `Community 53`, `Community 54`, `Community 58`, `Community 60`?**
  _High betweenness centrality (0.084) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` to `Community 35`, `Community 36`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `Community 42`, `Community 10`, `Community 12`, `Community 76`, `Community 14`, `SettingsView — biometria, export, GDPR`, `Community 20`, `Community 53`, `Community 22`, `Community 58`, `Community 27`?**
  _High betweenness centrality (0.064) - this node is a cross-community bridge._
- **Why does `Decimal` connect `Ricorrenze — motore backfill & Intents dirty-tracking` to `CategoryManagementView & AddTransactionView`, `Community 36`, `Community 9`, `Community 10`, `Community 22`, `Community 27`?**
  _High betweenness centrality (0.050) - this node is a cross-community bridge._
- **Are the 13 inferred relationships involving `Decimal` (e.g. with `.perform()` and `.perform()`) actually correct?**
  _`Decimal` has 13 INFERRED edges - model-reasoned connections that need verification._
- **What connects `backup.sh script`, `Cartella servita come "/" del sito: quella con index.html più vicina alla radice`, `(lingua dalla cartella, percorso senza cartella della lingua).` to the rest of the system?**
  _322 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Ricorrenze — motore backfill & Intents dirty-tracking` be split into smaller, more focused modules?**
  _Cohesion score 0.05346164127238706 - nodes in this community are weakly interconnected._
- **Should `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` be split into smaller, more focused modules?**
  _Cohesion score 0.061018437225636525 - nodes in this community are weakly interconnected._