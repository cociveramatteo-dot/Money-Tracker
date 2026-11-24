# Graph Report - MoneyTracker  (2026-11-24)

## Corpus Check
- 327 files · ~303,275 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 3901 nodes · 7763 edges · 430 communities (195 shown, 235 thin omitted)
- Extraction: 88% EXTRACTED · 12% INFERRED · 0% AMBIGUOUS · INFERRED: 897 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `437e5a05`
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
- DashboardView
- Community 15
- SettingsView — biometria, export, GDPR
- View
- Bug noti Dashboard/GoalsView & FormatterCache
- AddTransferView, changelog, automazione test notturni
- Community 20
- Community 21
- RecurrenceEditorView
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
- RecurrenceCalculator
- Community 36
- ModelConfiguration
- Community 38
- Community 39
- Community 40
- Community 41
- RecurrenceOperationStatus
- Community 43
- Community 44
- AddTransactionView
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
- PianificaView
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
- AccountType
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
- AuditLogger
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
- TxFilter
- Schema
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
- StatisticsView.swift
- MoneyTrackerApp.swift
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
- .invalidateAll
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
- ModelConfiguration
- FloatingTabBar
- .init
- 7. Audit Qualità (Score: 7.2 / 10)
- .init
- Color
- DS
- Schema
- Action
- FontRegistrationTests
- SupabaseManager
- ShareSheet
- MaterializationError
- LoginView
- Budget.swift
- HapticStyle
- ThemeNavBarModifier
- RecurringRule
- .capture
- TransactionsAdvancedFilterSheet
- DaysRemainingPluralTests.swift
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
- Option
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
- 8. Roadmap
- Decimal
- RecurringSeriesDetailView
- test-fumo.sh
- PIANO DEI LAVORI
- copilot-instructions.md
- README.md
- .centsSurviveSwiftDataAndDTOJSON
- README.md
- 7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)
- build.py
- FormatterCache
- .resolve
- README.md
- ProgrammedRuleCard
- build.gradle.kts
- script.js
- Bundle
- ModelConfiguration
- Proposte in ordine
- Decimal
- Direttive social Bucktrail
- .rule
- AddAccountView
- Budget.swift
- ShareSheet
- AccountBalanceCache
- SyncStatus
- Option
- .centsSurviveSwiftDataAndDTOJSON
- 7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)
- FormatterCache
- HttpSupabaseApiTest
- Row
- FakeLocalStore
- Statistics
- NotificationScheduler
- RecurrenceEditorSheet
- RecurringRuleEntity
- AuthManager.kt
- NotificationRules
- QuickAdd.kt
- Snapshot
- categoryLabel
- LedgerFuzzTest
- account
- RecurringMaterializerTests
- AccountEntity
- Budgeting
- QuickAddTest
- .rule
- SyncMapperTest
- String
- StatisticsScreen
- AccountEditingTest
- NotificationRulesTest
- HttpHostileServerTest
- TransactionData
- BudgetCard
- 4. Schermata per schermata
- AccountEditing
- Amounts
- TransactionEntity
- .build
- .provideGlance
- HomeScreen
- .ledger
- Account
- FloatingTabBar
- ScriptedApi
- PianificaView
- DemoDataTest
- H
- .build
- HomeAccountOrder
- SessionStore
- StatisticsTest
- 3. Logica di dominio da portare identica
- LedgerState
- Theme.kt
- MemorySyncState
- SupabaseManager
- .rule
- .dao
- .tx
- SfIcons
- AmountsTest
- HomeAccountOrderTest
- .world
- PlanningBudgetCard
- .suggest
- .detect
- .authenticate
- TransactionOpsTest
- .tx
- TrailView
- .materializeDue
- ClassifierProvider
- Categories
- ShortcutSetup
- Parità Android ↔ iOS — inventario e checklist
- 5. Auth, sync, Intents, notifiche, export
- Collaudo Android — 2026-11-23
- Commissione Suprema 2026-11-24
- make
- AppViewModel.kt
- Type.kt
- WidgetContentTest
- 1. Token grafici
- Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)
- Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet)
- SchemaMigration.swift
- SyncStatus
- RecurringSeriesDetailView
- CategoryTintTest
- ExportsTest
- AmountsLimitsTest
- 7. Checklist funzioni (F-xxx)
- Stress test Android Bucktrail (2026-11-23)
- SwipeRules
- NetworkMonitor
- Scope
- HomeHeroCard
- CategoryTint.kt
- KeywordCategoryClassifier

## God Nodes (most connected - your core abstractions)
1. `Text` - 94 edges
2. `Decimal` - 93 edges
3. `Row` - 61 edges
4. `AppViewModel` - 53 edges
5. `Double` - 50 edges
6. `Foundation` - 48 edges
7. `BucktrailDao` - 46 edges
8. `ModelContext` - 44 edges
9. `TransactionEntity` - 41 edges
10. `Snapshot` - 41 edges

## Surprising Connections (you probably didn't know these)
- `BudgetStatus` --references--> `Text`  [EXTRACTED]
  MoneyTracker/Views/Components/BudgetStatus.swift → 03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/domain/PdfReport.kt
- `FilterChip` --references--> `Text`  [EXTRACTED]
  MoneyTracker/Views/Components/FilterChip.swift → 03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/domain/PdfReport.kt
- `HeroCard` --references--> `Text`  [EXTRACTED]
  MoneyTracker/Views/Components/HeroCard.swift → 03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/domain/PdfReport.kt
- `HomeHeroCard` --references--> `Text`  [EXTRACTED]
  MoneyTracker/Views/Components/HomeHeroCard.swift → 03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/domain/PdfReport.kt
- `Option` --references--> `Text`  [EXTRACTED]
  MoneyTracker/Views/Components/SegmentedPill.swift → 03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/domain/PdfReport.kt

## Import Cycles
- None detected.

## Communities (430 total, 235 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.10
Nodes (34): Card, HeroCard, ProgressBar, DS, DSIcon, DSTransactionRow, EmptyStateView, FixedExpenseRow (+26 more)

### Community 1 - "Ricorrenze — motore backfill & Intents dirty-tracking"
Cohesion: 0.10
Nodes (26): Codable, LocalAuthentication, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport (+18 more)

### Community 2 - "Sync/ricorrenze — file sorgente del checkpoint settembre 2026"
Cohesion: 0.09
Nodes (29): LayoutRegressionTest, Text, Bundle, MainActivity, AppLockGate(), LockOverlay(), BalanceActivity, BalanceCard() (+21 more)

### Community 3 - "Schema Migration V1→V2 (Decimal precision)"
Cohesion: 0.22
Nodes (8): MigrationStage, Double, decimalFromLegacyDouble(), DecimalMigrationBuffer, MoneyTrackerMigrationPlan, UUID, BudgetStatus, SchemaMigrationPlan

### Community 4 - "Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)"
Cohesion: 0.08
Nodes (15): Auth, Combine, Foundation, MoneyTracker, DaysRemainingPluralTests, RecurringCollisionTests, StrictRecurrenceAmountTests, Network (+7 more)

### Community 5 - "Community 5"
Cohesion: 0.17
Nodes (6): NavigationStressUITests, RecurrenceFlowUITests, TransactionFlowUITests, MoneyTrackerUITestCase, AccountFlowUITests, XCTestCase

### Community 6 - "AppIntents — Tocco posteriore/Siri (AddExpenseIntent)"
Cohesion: 0.06
Nodes (33): CategoryStat, CGContext, CGPoint, Charts, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024), App Icon (Tinted, 1024x1024), CategoryStat (+25 more)

### Community 7 - "Supabase CodingKeys (snake_case mapping)"
Cohesion: 0.06
Nodes (33): Result, toSnapshot(), Boolean, Instant, Int, JsonObject, List, LocalDate (+25 more)

### Community 8 - "Community 8"
Cohesion: 0.27
Nodes (6): RecurrenceCancelAndHomeUITests, String, String, StaticString, UInt, XCUIElement

### Community 9 - "Community 9"
Cohesion: 0.07
Nodes (35): FilterChip, Style, advanced, primary, secondary, Void, ProgrammedRuleCard, Calendar (+27 more)

### Community 10 - "Community 10"
Cohesion: 0.12
Nodes (17): DashboardView, HomeAccountOrderSheet, ProjectionCache, Account, BalanceTrail, Bool, CGFloat, Date (+9 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (35): Bar, BigDecimal, List, String, YearMonth, ZoneId, Labels, Line (+27 more)

### Community 12 - "Community 12"
Cohesion: 0.13
Nodes (15): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView, Account, Bool (+7 more)

### Community 15 - "Community 15"
Cohesion: 0.20
Nodes (9): a) Diagnosi: perché oggi le ricorrenti "non compaiono", b) Modello dati, c) Algoritmi, d) Eccezioni (`Domain/RecurringSeriesEditor.swift`, `@MainActor`), Domande per Matteo, e) Viste (solo interfaccia dati, la grafica la fa l'impresa grafica sul mockup), f) Test (Swift Testing, `@Suite`, container in memoria `SchemaV3`), g) Sotto-task (ordine obbligato) (+1 more)

### Community 17 - "View"
Cohesion: 0.11
Nodes (19): In corso / prossimi, S-0 [x] Rimozione del tour, S-11 [x] Riserve da S-5 (XL e badge demo) — assorbito da S-12; resta solo tab bar XL in S-10, S-12 [x] Movimenti: pagina unica + zona sotto i chip + Ricorrenti (da mockup) — collaudo 2026-11-14 01:30 ok, S-13 [x] (S-13f chiuso da Matteo 2026-11-16) Motore ricorrenze a serie virtuali (D-008), S-1 [x] Token, font, dark mode, S-2 [x] Componenti base (chiuso 2026-11-13 20:40, collaudatore), S-2b [x] Correzioni componenti base (+11 more)

### Community 20 - "Community 20"
Cohesion: 0.29
Nodes (6): Chi fa meglio cosa (osservazioni, non verità: aggiornare), Cosa va bene (da tenere), Da cambiare nell'azienda (priorità alta), Esiti recenti, LEZIONI PER L'AZIENDA — da MoneyTracker (redesign Sentiero), Suggerimenti per la versione successiva

### Community 22 - "RecurrenceEditorView"
Cohesion: 0.13
Nodes (5): AnyObject, SystemNotificationManager, NotificationScheduling, AddGoalView, GoalRow

### Community 27 - "Community 27"
Cohesion: 0.15
Nodes (3): DemoShowcaseUITests, String, XCTest

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (20): chiave(), leggi(), Lettore, main(), Pagina, Path, radice_web(), Cartella servita come "/" del sito: quella con index.html più vicina alla radice (+12 more)

### Community 30 - "Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate"
Cohesion: 0.06
Nodes (34): CodingKey, CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt (+26 more)

### Community 31 - "Community 31"
Cohesion: 0.40
Nodes (4): Cartellino, Claude Code = CAPOCANTIERE, Quando un'impresa o un subagente ha finito, Risparmio di crediti (regole ferree)

### Community 34 - "Community 34"
Cohesion: 0.11
Nodes (24): accessibilita(), AXE, BASE, cliccaTutto(), confrontaScreenshot(), controllaLink(), controllaPagina(), differenze (+16 more)

### Community 35 - "RecurrenceCalculator"
Cohesion: 0.26
Nodes (8): Date, RecurringSeriesEditorTests, Calendar, Date, Int, ModelContainer, String, Transaction

### Community 36 - "Community 36"
Cohesion: 0.21
Nodes (8): CategoryTint, amber, blue, green, violet, String, UInt32, CategoryTintTests

### Community 37 - "ModelConfiguration"
Cohesion: 0.22
Nodes (22): background(), body_slide(), brand(), closer(), diagram(), font(), frame(), infographic() (+14 more)

### Community 38 - "Community 38"
Cohesion: 0.09
Nodes (22): Commissione Suprema S-13h (2026-11-14 11:08), Fatti, S-16 [?] FUORI DAL RESTYLING (serve decisione di Matteo: test su precisione Decimal elevata) Verificare precisione Decimal elevata nella persistenza RecurringRule, S-17 [x] (collaudo ok 2026-11-14) Pull: non cancellare regole locali non ancora spedite, S-18 [x] Rifinitura grafica dei virtuali e delle serie programmate, S-19 [x] Revisione testi e traduzioni S-13g · collaudato 2026-11-16 09:47: collaudo ok (solo 7 strings + .cantiere, plutil ok, 380 chiavi allineate, nessuna chiave persa, 0 marker). Approvazione Matteo in APPROVAZIONI.md ancora ⏳. Note: de "Keine" per "Conto" (neutro) → "Keines"; es "Ninguno" per "Conto" (cuenta) → "Ninguna"; de riga 103 resta "Vorkommen"; zh riga 103 "记录" per occorrenze (vs 项目). · **chiuso 2026-11-16 09:48: collaudo ok** (5ca721e): de «Keines»/«Termine», es «Ninguna», zh «项目» applicati, chiavi invariate, plutil ok, nessun altro «Vorkommen»/«记录» residuo (99 «历史记录» = Storico ok). Approvazione Matteo in APPROVAZIONI.md resta ⏳; «Termin» (de) e i termini segnalati vanno riletti da un madrelingua., S-20 [x] collaudato 2026-11-14 11:06 (bf9727e: guard ok, regressione ok, 68 unit verdi) CONFERMATO Verificare editor di una serie terminata prima della prima occorrenza, S-21 [x] Performance: ricalcoli per riga in TransactionsView (Commissione S-13h, giudice 4: 8/10) (+14 more)

### Community 39 - "Community 39"
Cohesion: 0.07
Nodes (27): 10. Changelog, v1 (inverno 2025) — Base, v2 (primavera 2026) — Feature complete, v3.10 (settembre 2026) — Tre bug critici: Tocco posteriore che "sparisce", perdita dati al login, ricorrenze arretrate, v3.11 (novembre 2026) — Redesign «Sentiero», step 0: rimozione del tour, v3.12 (novembre 2026) — Redesign «Sentiero», step 1: token, font, dark mode, v3.13 (novembre 2026) — Redesign «Sentiero», step 2–12: componenti, tab bar, Home, Movimenti, Impostazioni (S-2…S-5, S-9, S-12), v3.14 (novembre 2026) — Ricorrenze a serie virtuali (S-13) — cambio di schema, sync e modello dati (+19 more)

### Community 40 - "Community 40"
Cohesion: 0.12
Nodes (17): 6. Funzionalità Implementate, Aggiunta Transazione (AddTransactionView), Biometria (Auth/), Budget (BudgetView), Conti (AccountsView), Haptic Feedback, Home (DashboardView), Impostazioni (SettingsView) (+9 more)

### Community 42 - "RecurrenceOperationStatus"
Cohesion: 0.28
Nodes (3): SentieroAccountsUITests, String, XCUIApplication

### Community 43 - "Community 43"
Cohesion: 0.11
Nodes (17): 1. Profili (@bucktrailapp), 2. Caption per format (primo blocco), 3. Scheda App Store, 4. Landing, Aggiornamento lancio mobile · testi approvati il 20/11, Bucktrail — testi social, App Store, landing (v1), Dubbi per Matteo, English (+9 more)

### Community 44 - "Community 44"
Cohesion: 0.15
Nodes (11): CATEGORIE, data, dirLh, lh, OUT, perTipo, principali, r (+3 more)

### Community 45 - "AddTransactionView"
Cohesion: 0.36
Nodes (5): hero(), html(), Prima slide / copertina: scura, di impatto. alto=1350 (carosello 4:5) o 1920 (co, slide_app(), slide_fine()

### Community 46 - "Community 46"
Cohesion: 0.17
Nodes (11): dependencies, axe-core, gremlins.js, lighthouse, pixelmatch, playwright, pngjs, description (+3 more)

### Community 48 - "Community 48"
Cohesion: 0.31
Nodes (5): LastUsedCategoryTests, Bool, LastUsedCategory, Set, String

### Community 50 - "Community 50"
Cohesion: 0.38
Nodes (9): esegui_json(), limita(), main(), peso_locale_kb(), Path, radice(), Interpolazione lineare a tratti: punti = [(x, voto), ...] con x crescente., Peso della home: HTML + risorse locali che richiama (stima senza browser). (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.10
Nodes (19): 11. Workflow Checkpoint, 2. Stack Tecnico e Architettura, 3. Struttura del Progetto, 7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»), 8. Roadmap, 9. Setup e Installazione, Bug risolti (sessioni precedenti), Configurare il banner Shortcuts (+11 more)

### Community 55 - "Community 55"
Cohesion: 0.22
Nodes (8): 1. Il progetto, 2. La squadra, 3. Frasi-comando (uguali con ogni IA: le skill sono in `.agents/skills/`), 4. Turni (uno alla volta, sempre), 5. Lettura a strati (per risparmiare crediti), 6. Regole ferree, 7. Cartelle e nomi, REGOLAMENTO DI CANTIERE — MoneyTracker

### Community 56 - "Community 56"
Cohesion: 0.06
Nodes (34): 2026-11-16 · Riferimenti S-6/S-7/S-8 (Matteo), 2026-11-17 · Nessun premium in abbonamento, 2026-11-17 · Nome utente dei profili social: @bucktrailapp, 2026-11-17 · Regola permanente del progetto SOCIAL, 2026-11-17 · Social prima di Apple Developer Program, 2026-11-17 · Social senza elementi personali; video in IA in valutazione, 2026-11-17 · Soglie del segnale di interesse (✅ CONFERMATE da Matteo il 2026-11-17, cifre comprese: 40 iscritti, 200 visite, 5%, 5 commenti — non si spostano più) — SC-1b, 2026-11-17 · TikTok: account personale, senza musica (+26 more)

### Community 58 - "PianificaView"
Cohesion: 0.28
Nodes (5): Transaction, RecurrencePresentationTests, Date, Int, Self

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (7): candidati(), impronta(), leggi_fonti(), magazzino(), main(), Path, scrivi_fonti()

### Community 61 - "Community 61"
Cohesion: 0.29
Nodes (7): 4. Modelli Dati, Account, Budget, Category, FormatterCache (performance), Goal (Obiettivo di risparmio), Transaction

### Community 63 - "Community 63"
Cohesion: 0.07
Nodes (35): Boolean, Collection, Int, Long, Map, String, SharedPrefsSyncState, AuthGateway (+27 more)

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
Cohesion: 0.07
Nodes (46): Work, build(), main(), p_dir(), testi(), bars(), before_after(), cards() (+38 more)

### Community 69 - "Community 69"
Cohesion: 0.16
Nodes (17): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+9 more)

### Community 70 - "AccountType"
Cohesion: 0.11
Nodes (23): Encoder, Logger, SBAccount, SBBudget, SBGoal, SBRecurringRule, SBTransaction, Account (+15 more)

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (5): Cantiere di sviluppo, Features, Personal Finance Tracker, Security, Tech Stack

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
Cohesion: 0.29
Nodes (6): CHECKPOINT — MoneyTracker, Cose che deve fare Matteo, Domani si riparte così, Riferimenti, Siamo qui, Stato di salute

### Community 78 - "Community 78"
Cohesion: 0.40
Nodes (4): Come si costruisce, Dettaglio, MAPPA DEL CANTIERE — dove sta tutto, Social · backup novembre 2026

### Community 79 - "Community 79"
Cohesion: 0.12
Nodes (15): ANDROID · prova sync reale + telefono (quando vuoi, non urgente), Approvazione traduzioni (APPROVAZIONI.md), CHECKPOINT 2026-11-19 · Decisioni di pulizia (solo un sì/no, a parole va bene), CHECKPOINT 2026-11-19 · NotebookLM (bibliotecario): 6 fonti da aggiungere, Da fare, Fatte, PER MATTEO — le cose che aspettano te, S-21 — controllo manuale menu dopo il collaudo — ✅ fatto da Matteo 2026-11-16 21:49: tutto OK (+7 more)

### Community 82 - "Community 82"
Cohesion: 0.50
Nodes (3): Dettaglio tentativi, Modifiche automatiche, Report notturno MoneyTracker — 25/07/2026

### Community 85 - "Community 85"
Cohesion: 0.18
Nodes (10): APPROVAZIONI DEL COMMITTENTE, S-14 · confronto mese su mese · ritirate — Matteo 2026-11-16 (S-31), S-14 · formulazione percentuali italiana · ritirate — Matteo 2026-11-16 (S-31), S-30 · Categoria dall’ultima volta · ✅ traduzioni approvate da Matteo 2026-11-16, S-6 · testi del riferimento · ✅ (13 traduzioni compilate dal redattore, approvate da Matteo 2026-11-16), S-7 · testi di presentazione · ✅ (idem), S-7p · plurale giorni · ✅ approvato da Matteo 2026-11-16, S-8 · testi del riferimento · ✅ (idem) (+2 more)

### Community 100 - "Community 100"
Cohesion: 0.08
Nodes (10): AppViewModel, Boolean, com, java, List, Long, StateFlow, String (+2 more)

### Community 105 - "Community 105"
Cohesion: 0.12
Nodes (19): auditItems(), DemoData, Instant, List, ZoneId, AuditDiff, Event, Item (+11 more)

### Community 108 - "Community 108"
Cohesion: 0.06
Nodes (30): CategoryEditing, DeleteMessage, Boolean, Int, List, String, fold(), KeywordCategoryClassifier (+22 more)

### Community 112 - "TxFilter"
Cohesion: 0.11
Nodes (15): ApiException, ErrorKind, fromJson(), HttpSupabaseApi, Int, java, JsonObject, List (+7 more)

### Community 113 - "Schema"
Cohesion: 0.07
Nodes (22): CaseIterable, String, UIKeyboardType, AuthField, LoginView, SignUpView, AuditLogger, Entry (+14 more)

### Community 137 - "StatisticsView.swift"
Cohesion: 0.10
Nodes (22): Action, delete, edit, skipMonth, terminate, RecurrenceOperationStatus, RecurringSeriesEditor, Bool (+14 more)

### Community 165 - ".invalidateAll"
Cohesion: 0.29
Nodes (6): Caption, Instagram, Musica, Post 1 — Carosello «Ogni conto al suo posto» (v2), Slide (ordine di pubblicazione), TikTok

### Community 181 - "ModelConfiguration"
Cohesion: 0.10
Nodes (20): Backoff, ChangeWatcher, Idle, Boolean, com, Flow, Int, List (+12 more)

### Community 182 - "FloatingTabBar"
Cohesion: 0.18
Nodes (9): FloatingTabBar, Item, CGFloat, Int, LocalizedStringKey, String, ContentView, LocalizedStringKey (+1 more)

### Community 183 - ".init"
Cohesion: 0.18
Nodes (8): FileProtectionType, DemoDataSeeder, applyFileProtection(), ModelContainer, URL, date, name, SharedStore

### Community 184 - "7. Audit Qualità (Score: 7.2 / 10)"
Cohesion: 0.22
Nodes (10): App, MoneyTrackerApp, Bool, Never, String, Task, UUID, View (+2 more)

### Community 185 - ".init"
Cohesion: 0.09
Nodes (23): Progetto SOCIAL (avviato 2026-11-17), S-10 [x] (2026-11-16: Commissione S-10, nessun difetto bloccante; 92 unit verdi; UI 42/45 nel run completo, i 3 falliti rilanciati singolarmente verdi; 2 voti 9 per commento obsoleto e sentence() lunga, corretti in 1748ef5 senza nuova valutazione) Verifica finale + Commissione Suprema, S-14 [x] Statistiche: confronto mese su mese — rimosso su richiesta di Matteo 2026-11-16, S-15 [x] Diagnosticare due test UI che non trovano il movimento appena salvato, S-38 [ ] Commissione — pacchetto A (Codex): virtuali che ignorano filtri avanzati, date filtro personalizzato non salvate, conferma per «Salta mese/Termina…», «•••• €» fisso, detector ricalcolato a ogni render, set di ID regole in `movementList`, force-unwrap (RecurrenceControls:69, RecurringSeriesDetector:58-66), `RecurringMaterializer` duplica `snapshot`, tipo/selected ridondanti in `typeChips`., S-39 [ ] Commissione — traduzioni (redattore): ~40 stringhe visibili in italiano in tutte le lingue (Settings, notifiche, Login/SignUp, AuditLog, Budget, filtri…), frasi composte a pezzi, chiavi doppie «Fine»/«Tipo». Poi approvazione Matteo., S-40 [ ] Commissione — font fissi (Codex): ~200 `.font(.system(size:))` → token `DS.Typo.*` (Dynamic Type), `SectionLabel` incluso., S-41 [x] Home — spesa fissa singola nel mese di competenza (Matteo, 2026-11-20) (+15 more)

### Community 186 - "Color"
Cohesion: 0.13
Nodes (43): budgetColor(), BudgetStatus(), Card(), CategoryIconBox(), dashedBorder(), defaultMinSize18(), DemoBanner(), EmptyState() (+35 more)

### Community 187 - "DS"
Cohesion: 0.31
Nodes (3): AddCategoryView, CategoryManagementView, CategoryRow

### Community 189 - "Action"
Cohesion: 0.33
Nodes (6): Kind, expense, income, transfer, MovementRow, String

### Community 191 - "SupabaseManager"
Cohesion: 0.46
Nodes (7): fetch(), handle(), json(), secure(), SECURITY, subscribe(), UTM

### Community 192 - "ShareSheet"
Cohesion: 0.10
Nodes (38): SectionLabel(), AccountSaveRequest, AddAccountForm(), BigDecimal, Boolean, List, String, AddTransactionForm() (+30 more)

### Community 193 - "MaterializationError"
Cohesion: 0.14
Nodes (15): RecurringRule, Bool, Date, String, UUID, RecurrencePresentationCache, RuleKey, Bool (+7 more)

### Community 194 - "LoginView"
Cohesion: 0.22
Nodes (8): attribution, button, campaign, fields, form, localPreview, msg, status

### Community 195 - "Budget.swift"
Cohesion: 0.15
Nodes (7): Identifiable, RecurringSeries, RecurringSeriesDetector, entrata, AddTransferView, BudgetHistorySheet, BudgetRow

### Community 196 - "HapticStyle"
Cohesion: 0.33
Nodes (6): HapticStyle, light, medium, rigid, soft, success

### Community 197 - "ThemeNavBarModifier"
Cohesion: 0.21
Nodes (10): BootReceiver, Content, Kind, Context, NotificationTexts, Notifier, ReminderReceiver, BroadcastReceiver (+2 more)

### Community 198 - "RecurringRule"
Cohesion: 0.20
Nodes (9): Calcolo settimanale, Decisione sui format, Diario delle metriche social, Engagement rate, Post 1 · Instagram, Post 1 · TikTok, Post 2 · Instagram, Post 2 · TikTok (+1 more)

### Community 201 - "TransactionsAdvancedFilterSheet"
Cohesion: 0.33
Nodes (5): Bool, Date, Int, String, TransactionsAdvancedFilterSheet

### Community 202 - "DaysRemainingPluralTests.swift"
Cohesion: 0.24
Nodes (4): NSCache, NSString, KeywordCategoryClassifier, KeywordCategoryClassifierTests

### Community 226 - "Option"
Cohesion: 0.07
Nodes (39): AccountActions, AccountGroup(), AccountRow(), AccountRowContext, AccountsScreen(), ArchivedToggle(), Boolean, Int (+31 more)

### Community 303 - "8. Roadmap"
Cohesion: 0.25
Nodes (7): Commissione Suprema (controllo qualità pre-checkpoint), Graphify, graphify, Progetto SOCIAL, REGOLE DEL PROGETTO — MoneyTracker, Struttura cartella, Workflow checkpoint

### Community 304 - "Decimal"
Cohesion: 0.07
Nodes (39): CryptoKit, Equatable, BalanceTrail, Entry, Point, Bool, Calendar, Date (+31 more)

### Community 309 - "README.md"
Cohesion: 0.29
Nodes (7): Calendario social Bucktrail, Consegna prima serie, Consegna seconda serie, Gate · dom 06/12, Già pubblicati, Mappa di copertura, Orari di partenza · Europe/Rome

### Community 310 - ".centsSurviveSwiftDataAndDTOJSON"
Cohesion: 0.83
Nodes (3): gradlew script, die(), warn()

### Community 311 - "README.md"
Cohesion: 0.15
Nodes (8): Calendario social Bucktrail · v2 (23/11/2026), Mappa vecchi post → nuovi, Note di verifica, Nuovo elenco, Guida alle schermate di Bucktrail, Master social Bucktrail, Cosa raccogliere, Schermate dell’app

### Community 312 - "7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)"
Cohesion: 0.11
Nodes (5): BucktrailDao, com, Flow, List, String

### Community 313 - "build.py"
Cohesion: 0.35
Nodes (11): calculation(), editorial(), inset(), laptop(), left(), phone(), right_phone(), save() (+3 more)

### Community 314 - "FormatterCache"
Cohesion: 0.19
Nodes (7): IntentResult, AccountBalanceCache, Account, PersistentIdentifier, Decimal, ProvidesDialog, AccountBalanceTests

### Community 315 - ".resolve"
Cohesion: 0.07
Nodes (19): BucktrailApplication, Boolean, String, AuditLog, AuditTracker, Entry, Flow, List (+11 more)

### Community 317 - "ProgrammedRuleCard"
Cohesion: 0.09
Nodes (24): Any, List, LocalDate, Long, Map, String, ZoneId, migrate() (+16 more)

### Community 318 - "build.gradle.kts"
Cohesion: 0.83
Nodes (3): iosSupabase(), String, supabaseValue()

### Community 319 - "script.js"
Cohesion: 0.50
Nodes (3): bento, shots, steps

### Community 322 - "ModelConfiguration"
Cohesion: 0.24
Nodes (8): ModelConfiguration, DemoDataSeederTests, RecurringDecimalRoundTripTests, Schema, UUID, SchemaMigrationTests, URL, UUID

### Community 323 - "Proposte in ordine"
Cohesion: 0.18
Nodes (11): Post-10 · Sequenza approvata, Post-11 · Sequenza approvata, Post-12 · Sequenza approvata, Post-3 · Dettaglio grafico aggiornato, Post-4 · Sequenza approvata, Post-5 · Sequenza approvata, Post-6 · Sequenza approvata, Post-7 · Sequenza approvata (+3 more)

### Community 324 - "Decimal"
Cohesion: 0.17
Nodes (5): Date, Bool, String, CurrencyFormattingTests, StrictAmountParsingTests

### Community 325 - "Direttive social Bucktrail"
Cohesion: 0.29
Nodes (7): Calendario, approvazione e consegna, Comunicazione sul lancio, Direttive social Bucktrail, Grafica e controllo prima della consegna, Prima di preparare ogni nuovo post, Stile v2 (dal 23/11/2026, Post-5 in poi), Tre rubriche

### Community 326 - ".rule"
Cohesion: 0.33
Nodes (6): LocalizedError, EditorError, crossMonthOverride, invalidOccurrence, invalidValues, requiresMainContext

### Community 327 - "AddAccountView"
Cohesion: 0.27
Nodes (8): CategoryTint, AccountRow, AccountsView, AddAccountView, Account, AccountType, Bool, String

### Community 328 - "Budget.swift"
Cohesion: 0.29
Nodes (6): Bool, CGFloat, Date, Int, String, TransactionsSecondaryChips

### Community 329 - "ShareSheet"
Cohesion: 0.25
Nodes (7): Instant, Int, Set, String, RecurringOpsTest, World, Action

### Community 330 - "AccountBalanceCache"
Cohesion: 0.12
Nodes (28): Unit, rememberNotificationPermission(), AppData, BucktrailApp(), Boolean, LocalDate, ZoneId, Refreshable() (+20 more)

### Community 331 - "SyncStatus"
Cohesion: 0.13
Nodes (16): BalanceTrail, Entry, Any, BigDecimal, Boolean, Instant, List, ZoneId (+8 more)

### Community 332 - "Option"
Cohesion: 0.26
Nodes (10): Action, Delete, Edit, Problem, Scope, Selection, SkipMonth, Terminate (+2 more)

### Community 333 - ".centsSurviveSwiftDataAndDTOJSON"
Cohesion: 0.16
Nodes (8): AuthManager, Boolean, StateFlow, String, T, AuthManagerTest, Long, MemorySessionStore

### Community 334 - "7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)"
Cohesion: 0.12
Nodes (14): Criteria, BigDecimal, Boolean, Int, List, String, T, ZoneId (+6 more)

### Community 335 - "FormatterCache"
Cohesion: 0.12
Nodes (11): AppPrefs, K, Boolean, Flow, Int, List, String, PrefsState (+3 more)

### Community 336 - "HttpSupabaseApiTest"
Cohesion: 0.13
Nodes (7): HttpSupabaseApiTest, Int, ServerSocket, Socket, String, Recorded, Reply

### Community 337 - "Row"
Cohesion: 0.16
Nodes (23): Row, BarAction(), BtAlert(), androidx, Boolean, Float, Long, Modifier (+15 more)

### Community 338 - "FakeLocalStore"
Cohesion: 0.21
Nodes (3): Int, SyncEngineTest, FakeLocalStore

### Community 339 - "Statistics"
Cohesion: 0.23
Nodes (10): CategoryStat, BigDecimal, Int, List, Map, YearMonth, ZoneId, MonthStat (+2 more)

### Community 340 - "NotificationScheduler"
Cohesion: 0.21
Nodes (11): Boolean, Collection, Instant, Int, java, Long, String, YearMonth (+3 more)

### Community 341 - "RecurrenceEditorSheet"
Cohesion: 0.22
Nodes (21): ActionRow(), frequencyLabel(), android, androidx, com, KeyboardType, List, LocalDate (+13 more)

### Community 342 - "RecurringRuleEntity"
Cohesion: 0.22
Nodes (12): RecurringRuleEntity, Changes, BigDecimal, Instant, List, RecurrenceCalculator, RuleSnapshot, Set (+4 more)

### Community 343 - "AuthManager.kt"
Cohesion: 0.18
Nodes (15): EditorException, AlreadyExists, AuthErrors, AuthMessage, EmailNotConfirmed, Generic, InvalidCredentials, InvalidEmail (+7 more)

### Community 344 - "NotificationRules"
Cohesion: 0.14
Nodes (11): BudgetAlert, BigDecimal, Boolean, Instant, Int, List, String, YearMonth (+3 more)

### Community 345 - "QuickAdd.kt"
Cohesion: 0.22
Nodes (12): Add, Balance, BalanceLine, BalanceSummary, Draft, Home, Kind, List (+4 more)

### Community 346 - "Snapshot"
Cohesion: 0.16
Nodes (9): IgnoredIds, Boolean, Int, Set, String, Snapshot, SyncMerge, SyncPlan (+1 more)

### Community 347 - "categoryLabel"
Cohesion: 0.16
Nodes (18): AddCategoryForm(), CategoryManagementSheet(), CategoryPickerSheet(), CategoryRowItem(), Boolean, List, Modifier, String (+10 more)

### Community 348 - "LedgerFuzzTest"
Cohesion: 0.21
Nodes (7): Instant, Int, Long, String, LedgerFuzzTest, World, Random

### Community 349 - "account"
Cohesion: 0.25
Nodes (6): account(), tx(), Int, JsonObject, String, SyncGuardsTest

### Community 350 - "RecurringMaterializerTests"
Cohesion: 0.25
Nodes (7): RecurringMaterializerTests, Calendar, Date, Int, ModelContainer, String, RecurringMaterializer

### Community 351 - "AccountEntity"
Cohesion: 0.22
Nodes (7): AccountEntity, BudgetEntity, CategoryEntity, GoalEntity, seedDefaultCategories(), AuditLogTest, List

### Community 352 - "Budgeting"
Cohesion: 0.16
Nodes (10): Budgeting, GoalData, BigDecimal, Collection, List, Set, String, YearMonth (+2 more)

### Community 353 - "QuickAddTest"
Cohesion: 0.16
Nodes (4): Boolean, Long, String, QuickAddTest

### Community 354 - ".rule"
Cohesion: 0.27
Nodes (5): RecurrenceCalculatorTests, Date, Int, RuleSnapshot, String

### Community 355 - "SyncMapperTest"
Cohesion: 0.15
Nodes (4): budget(), goal(), rule(), SyncMapperTest

### Community 356 - "String"
Cohesion: 0.27
Nodes (5): FakeSupabase, JsonObject, List, String, seed()

### Community 357 - "StatisticsScreen"
Cohesion: 0.24
Nodes (16): AverageTile(), androidx, BigDecimal, Boolean, Int, List, LocalDate, Modifier (+8 more)

### Community 358 - "AccountEditingTest"
Cohesion: 0.15
Nodes (4): AccountEditingTest, CategoryEditingTest, String, SwipeRulesTest

### Community 359 - "NotificationRulesTest"
Cohesion: 0.21
Nodes (4): Boolean, Int, String, NotificationRulesTest

### Community 360 - "HttpHostileServerTest"
Cohesion: 0.24
Nodes (4): HttpHostileServerTest, Int, ServerSocket, Socket

### Community 361 - "TransactionData"
Cohesion: 0.34
Nodes (8): toData(), Balance, BigDecimal, List, AccountData, AccountType, BigDecimal, TransactionData

### Community 362 - "BudgetCard"
Cohesion: 0.30
Nodes (15): BudgetCard(), BudgetHistorySheet(), budgetName(), GoalCard(), GoalsContent(), BigDecimal, Int, List (+7 more)

### Community 363 - "4. Schermata per schermata"
Cohesion: 0.12
Nodes (16): 4.0 Struttura app e navigazione (`ContentView`, `MoneyTrackerApp`), 4.10 Auth (`Auth/LoginView.swift`, `SignUpView.swift`), 4.11 Audit log (`V/AuditLogView.swift`), 4.12 Modalità demo e dati demo (`Debug/DemoDataSeeder.swift`), 4.13 Notifiche e permessi — vedi §5.5. Banner sync/demo — vedi §1.4., 4.1 Home (`V/DashboardView.swift`), 4.2 Movimenti (`V/TransactionsView.swift` + `TransactionsTypeChips/SecondaryChips/SearchField/AdvancedFilterSheet`), 4.3 Aggiungi / modifica movimento (`V/AddTransactionView.swift`) (+8 more)

### Community 364 - "AccountEditing"
Cohesion: 0.24
Nodes (10): AccountEditing, Adjust, BalanceChange, BigDecimal, Boolean, List, String, T (+2 more)

### Community 365 - "Amounts"
Cohesion: 0.27
Nodes (5): Amounts, BigDecimal, Boolean, Long, String

### Community 366 - "TransactionEntity"
Cohesion: 0.33
Nodes (7): TransactionEntity, Boolean, List, Long, String, TransactionOps, TransferInput

### Community 367 - ".build"
Cohesion: 0.21
Nodes (9): CsvExport, Any, Int, List, Map, String, ZoneId, Labels (+1 more)

### Community 368 - ".provideGlance"
Cohesion: 0.20
Nodes (12): BalanceWidget, BalanceWidgetReceiver, hide(), BigDecimal, Boolean, Context, String, make() (+4 more)

### Community 369 - "HomeScreen"
Cohesion: 0.16
Nodes (12): BalanceTrail, Modifier, String, TrailView(), accountDotColor(), FixedTotalTile(), HomeScreen(), AccountType (+4 more)

### Community 370 - ".ledger"
Cohesion: 0.21
Nodes (5): Boolean, com, Int, List, SyncServiceTest

### Community 371 - "Account"
Cohesion: 0.34
Nodes (10): Account, Budget, Goal, Bool, Budget, Date, Int, String (+2 more)

### Community 372 - "FloatingTabBar"
Cohesion: 0.19
Nodes (9): QuickAddTileService, FabButton(), FloatingTabBar(), Boolean, Map, Modifier, String, Tab (+1 more)

### Community 373 - "ScriptedApi"
Cohesion: 0.27
Nodes (4): kotlinx, List, String, ScriptedApi

### Community 374 - "PianificaView"
Cohesion: 0.19
Nodes (9): PianificaView, Bool, Budget, Goal, Int, LocalizedStringKey, PersistentIdentifier, String (+1 more)

### Community 376 - "H"
Cohesion: 0.27
Nodes (3): H, session(), BaseHTTPRequestHandler

### Community 377 - ".build"
Cohesion: 0.27
Nodes (6): JsonExport, Instant, List, Long, String, Num

### Community 378 - "HomeAccountOrder"
Cohesion: 0.36
Nodes (5): HomeAccountOrder, Int, List, String, State

### Community 379 - "SessionStore"
Cohesion: 0.22
Nodes (3): SessionStore, KeystoreSessionStore, SecretKey

### Community 380 - "StatisticsTest"
Cohesion: 0.18
Nodes (3): Boolean, String, StatisticsTest

### Community 381 - "3. Logica di dominio da portare identica"
Cohesion: 0.18
Nodes (11): 3.10 Ordinamenti, 3.1 Importi e valuta (`Formatting/`), 3.2 Saldo (`AccountBalanceCache`), 3.3 «Saldo atteso» e curva (BalanceTrail, `D/BalanceTrail.swift`) — competenza mensile S-41, 3.4 Ricorrenze (serie virtuali, D-008/D-009) — `D/RecurrenceCalculator.swift`, `RecurringMaterializer`, `RecurringSeriesEditor`, 3.5 Budget (`PianificaView`, notifiche), 3.6 Obiettivi, 3.7 Trasferimenti (+3 more)

### Community 382 - "LedgerState"
Cohesion: 0.29
Nodes (6): Boolean, Flow, List, LedgerState, Repository, Source

### Community 383 - "Theme.kt"
Cohesion: 0.27
Nodes (8): Bt, BucktrailColors, c(), colors(), Boolean, Int, Long, TintColors

### Community 384 - "MemorySyncState"
Cohesion: 0.24
Nodes (6): Boolean, Collection, Int, Long, Map, MemorySyncState

### Community 385 - "SupabaseManager"
Cohesion: 0.24
Nodes (3): ObservableObject, SupabaseClient, SupabaseManager

### Community 386 - ".rule"
Cohesion: 0.38
Nodes (3): RecurringRuleSyncTests, Date, ModelContainer

### Community 387 - ".dao"
Cohesion: 0.28
Nodes (3): BucktrailDatabase, RoomLocalStore, RoomDatabase

### Community 388 - ".tx"
Cohesion: 0.25
Nodes (5): BudgetData, BudgetingTest, Boolean, Int, String

### Community 389 - "SfIcons"
Cohesion: 0.28
Nodes (6): Float, ImageVector, Map, Set, String, SfIcons

### Community 392 - ".world"
Cohesion: 0.33
Nodes (4): ExportRoundTripTest, Int, List, String

### Community 393 - "PlanningBudgetCard"
Cohesion: 0.22
Nodes (8): PlanningBudgetCard, PlanningGoalCard, PlanningProgressRing, Bool, Budget, Goal, String, Void

### Community 394 - ".suggest"
Cohesion: 0.36
Nodes (5): List, Set, String, LastUsedCategory, Movement

### Community 395 - ".detect"
Cohesion: 0.39
Nodes (5): List, String, ZoneId, RecurringSeries, RecurringSeriesDetector

### Community 396 - ".authenticate"
Cohesion: 0.29
Nodes (5): Authenticator, Boolean, Context, FragmentActivity, String

### Community 398 - ".tx"
Cohesion: 0.36
Nodes (3): BalanceTest, Boolean, String

### Community 399 - "TrailView"
Cohesion: 0.25
Nodes (6): CGSize, GraphicsContext, BalanceTrail, CGFloat, Date, TrailView

### Community 400 - ".materializeDue"
Cohesion: 0.36
Nodes (5): RecurringMaterializer, Date, Int, RecurrenceCalculator, TimeZone

### Community 401 - "ClassifierProvider"
Cohesion: 0.43
Nodes (4): ClassifierProvider, Context, KeywordCategoryClassifier, String

### Community 402 - "Categories"
Cohesion: 0.33
Nodes (5): Categories, Default, List, Set, String

### Community 403 - "ShortcutSetup"
Cohesion: 0.38
Nodes (3): Boolean, Context, ShortcutSetup

### Community 404 - "Parità Android ↔ iOS — inventario e checklist"
Cohesion: 0.29
Nodes (6): 2.1 Entità, 2.2 Proposta Room v3 (migrazione dal v2 attuale), 2. Modello dati (SwiftData SchemaV3 → Room), 6. Localizzazione (7 lingue: it, en, de, es, fr, ja, zh-Hans), 8. Ordine di costruzione consigliato (blocchi eseguibili uno alla volta), Parità Android ↔ iOS — inventario e checklist

### Community 405 - "5. Auth, sync, Intents, notifiche, export"
Cohesion: 0.29
Nodes (7): 5.1 Auth Supabase (`Auth/SupabaseManager.swift`, `SupabaseConfig.swift`), 5.2 Tabelle Supabase e DTO (`Sync/SyncService.swift`, snake_case, tutte con `user_id`), 5.3 Strategia di sync (`SyncService`), 5.4 Intents Apple → equivalenti Android (`Intents/AddExpenseIntent.swift`), 5.5 Notifiche (`Domain/NotificationManager.swift`, `NotificationScheduling`), 5.6 Export, 5. Auth, sync, Intents, notifiche, export

### Community 406 - "Collaudo Android — 2026-11-23"
Cohesion: 0.29
Nodes (6): Collaudo Android — 2026-11-23, Comandi e log, Difetti, Emulatore `Bucktrail_API_36` (modalità aereo, nessun account), Esito per blocco, Release e Supabase reale

### Community 407 - "Commissione Suprema 2026-11-24"
Cohesion: 0.29
Nodes (6): Commissione Suprema 2026-11-24, Correzioni, Giro 1 (prima delle correzioni), Giro 2 (dopo le correzioni), Per Matteo (non toccato: zone intoccabili o decisioni sue), Verifiche dopo le correzioni

### Community 408 - "make"
Cohesion: 0.40
Nodes (5): HomeProjection, List, LocalDate, ZoneId, make()

### Community 409 - "AppViewModel.kt"
Cohesion: 0.47
Nodes (4): Error, Ok, RecurrenceResult, UndoState

### Community 410 - "Type.kt"
Cohesion: 0.33
Nodes (4): Dim, Fonts, Int, Typo

### Community 412 - "1. Token grafici"
Cohesion: 0.33
Nodes (6): 1.1 Colori (hex, light / dark) — `V/Theme.swift` `DS`, 1.2 Tipografia, 1.3 Spaziature e misure (`DS.Space`, `DS.Layout`), 1.4 Componenti riutilizzabili (Compose), 1.5 Icone (SF Symbols → Android), 1. Token grafici

### Community 413 - "Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)"
Cohesion: 0.33
Nodes (5): Compito B11, Differenze residue (decise o di piattaforma), Esito per schermata, Secondo giro (2026-11-23, sera): flussi che erano scoperti, Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)

### Community 414 - "Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet)"
Cohesion: 0.33
Nodes (5): Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet), Difetti piccoli, Esito, S-36 — rami vecchi (nessuna cancellazione; proposta), Suggerimenti

### Community 415 - "SchemaMigration.swift"
Cohesion: 0.60
Nodes (5): SchemaV1, SchemaV2, SchemaV3, PersistentModel, VersionedSchema

### Community 416 - "SyncStatus"
Cohesion: 0.33
Nodes (6): Int, SyncStatus, idle, offline, syncing, waitingForRetry

### Community 417 - "RecurringSeriesDetailView"
Cohesion: 0.40
Nodes (4): RecurringSeriesDetailView, RecurringSeries, String, Transaction

### Community 421 - "7. Checklist funzioni (F-xxx)"
Cohesion: 0.40
Nodes (5): 7. Checklist funzioni (F-xxx), Auth, sync, piattaforma, Dati e dominio, Fondamenta e design, Schermate

### Community 422 - "Stress test Android Bucktrail (2026-11-23)"
Cohesion: 0.40
Nodes (4): Esiti e correzioni, Non completato / rischi residui, Scenari superati senza difetti, Stress test Android Bucktrail (2026-11-23)

### Community 425 - "Scope"
Cohesion: 0.50
Nodes (4): Scope, all, following, onlyThis

### Community 426 - "HomeHeroCard"
Cohesion: 0.50
Nodes (3): HomeHeroCard, BalanceTrail, Date

## Knowledge Gaps
- **606 isolated node(s):** `backup.sh script`, `esegui.sh script`, `CHROME_PATH`, `require`, `AXE` (+601 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **235 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Text` connect `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` to `ShareSheet`, `CategoryManagementView & AddTransactionView`, `Option`, `Schema Migration V1→V2 (Decimal precision)`, `StatisticsScreen`, `Community 9`, `AccountBalanceCache`, `Community 11`, `BudgetCard`, `HomeHeroCard`, `Option`, `Community 10`, `.provideGlance`, `Row`, `HomeScreen`, `RecurrenceEditorSheet`, `Color`, `categoryLabel`?**
  _High betweenness centrality (0.148) - this node is a cross-community bridge._
- **Why does `Double` connect `Schema Migration V1→V2 (Decimal precision)` to `CategoryManagementView & AddTransactionView`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `PlanningBudgetCard`, `Community 48`, `ModelConfiguration`, `FormatterCache`, `Color`, `.resolve`, `Budget.swift`, `Decimal`, `Community 69`, `AccountType`, `QuickAdd.kt`, `Budgeting`, `BudgetCard`, `Community 108`, `Amounts`, `Account`, `PianificaView`?**
  _High betweenness centrality (0.144) - this node is a cross-community bridge._
- **Why does `TransactionEntity` connect `TransactionEntity` to `ShareSheet`, `Option`, `Community 100`, `.world`, `Community 105`, `AppViewModel.kt`, `AccountBalanceCache`, `ShareSheet`, `RecurringRuleEntity`, `7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)`, `.build`, `.resolve`, `LedgerFuzzTest`, `account`, `AccountEntity`?**
  _High betweenness centrality (0.127) - this node is a cross-community bridge._
- **Are the 82 inferred relationships involving `Text` (e.g. with `.pageHeaderStacksTitleAndActionsAtLargeFont()` and `LockOverlay()`) actually correct?**
  _`Text` has 82 INFERRED edges - model-reasoned connections that need verification._
- **Are the 34 inferred relationships involving `Decimal` (e.g. with `.seed()` and `.perform()`) actually correct?**
  _`Decimal` has 34 INFERRED edges - model-reasoned connections that need verification._
- **Are the 59 inferred relationships involving `Row` (e.g. with `BalanceCard()` and `.provideGlance()`) actually correct?**
  _`Row` has 59 INFERRED edges - model-reasoned connections that need verification._
- **What connects `backup.sh script`, `Cartella servita come "/" del sito: quella con index.html più vicina alla radice`, `(lingua dalla cartella, percorso senza cartella della lingua).` to the rest of the system?**
  _642 weakly-connected nodes found - possible documentation gaps or missing edges._