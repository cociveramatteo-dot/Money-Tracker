# Graph Report - MoneyTracker  (2026-11-17)

## Corpus Check
- 152 files · ~116,454 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 1698 nodes · 3196 edges · 304 communities (81 shown, 223 thin omitted)
- Extraction: 90% EXTRACTED · 10% INFERRED · 0% AMBIGUOUS · INFERRED: 309 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `acd268a5`
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
- RecurrenceCalculator
- Community 36
- Community 37
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
- String
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
- RecurrencePresentationCache
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
- Category
- FloatingTabBar
- Option
- 7. Audit Qualità (Score: 7.2 / 10)
- SwiftData
- Color
- DS
- Schema
- Action
- FontRegistrationTests
- SupabaseManager
- PlanningBudgetCard
- .classify
- TxFilter
- Budget.swift
- HapticStyle
- ThemeNavBarModifier
- NavigationStressUITests
- .capture
- RecurringRule
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
- SupabaseConfig.swift
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

## God Nodes (most connected - your core abstractions)
1. `Decimal` - 85 edges
2. `Foundation` - 46 edges
3. `ModelContext` - 44 edges
4. `SwiftData` - 41 edges
5. `SwiftUI` - 39 edges
6. `Double` - 37 edges
7. `CodingKeys` - 37 edges
8. `RecurringRule` - 31 edges
9. `RecurrenceCalculator` - 30 edges
10. `SyncService` - 29 edges

## Surprising Connections (you probably didn't know these)
- `RecurrenceCalculatorTests` --calls--> `RecurrenceCalculator`  [INFERRED]
  MoneyTrackerTests/RecurrenceCalculatorTests.swift → MoneyTracker/Domain/RecurrenceCalculator.swift
- `RecurringMaterializerTests` --references--> `RecurringMaterializer`  [EXTRACTED]
  MoneyTrackerTests/RecurringMaterializerTests.swift → MoneyTracker/Domain/RecurringMaterializer.swift
- `MoneyTrackerApp` --calls--> `RecurrenceOperationStatus`  [INFERRED]
  MoneyTracker/MoneyTrackerApp.swift → MoneyTracker/Domain/RecurringSeriesEditor.swift
- `AddTransactionView` --calls--> `RecurrenceOperationStatus`  [INFERRED]
  MoneyTracker/Views/AddTransactionView.swift → MoneyTracker/Domain/RecurringSeriesEditor.swift
- `RecurringSeriesEditorTests` --references--> `RecurringSeriesEditor`  [EXTRACTED]
  MoneyTrackerTests/RecurringSeriesEditorTests.swift → MoneyTracker/Domain/RecurringSeriesEditor.swift

## Import Cycles
- None detected.

## Communities (304 total, 223 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.22
Nodes (19): DSTransactionRow, EmptyStateView, FixedExpenseRow, FixedTotalTile, GhostButton, HeroAmount, MonthBar, PrimaryButton (+11 more)

### Community 1 - "Ricorrenze — motore backfill & Intents dirty-tracking"
Cohesion: 0.23
Nodes (18): Codable, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, GDPRExport, GoalExport, JSONExportFile (+10 more)

### Community 2 - "Sync/ricorrenze — file sorgente del checkpoint settembre 2026"
Cohesion: 0.07
Nodes (30): Any, CGContext, CGPoint, Charts, Context, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024), App Icon (Tinted, 1024x1024) (+22 more)

### Community 3 - "Schema Migration V1→V2 (Decimal precision)"
Cohesion: 0.07
Nodes (40): MigrationStage, Double, Account, Budget, decimalFromLegacyDouble(), DecimalMigrationBuffer, Goal, MoneyTrackerMigrationPlan (+32 more)

### Community 4 - "Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)"
Cohesion: 0.06
Nodes (23): Auth, Foundation, LocalizedError, MoneyTracker, EditorError, crossMonthOverride, invalidOccurrence, invalidValues (+15 more)

### Community 5 - "Community 5"
Cohesion: 0.18
Nodes (7): NavigationStressUITests, RecurrenceFlowUITests, TransactionFlowUITests, String, StaticString, UInt, XCUIElement

### Community 6 - "AppIntents — Tocco posteriore/Siri (AddExpenseIntent)"
Cohesion: 0.13
Nodes (24): Action, delete, edit, skipMonth, terminate, RecurrenceOperationStatus, RecurringSeriesEditor, Bool (+16 more)

### Community 7 - "Supabase CodingKeys (snake_case mapping)"
Cohesion: 0.19
Nodes (9): Card, Content, HeroCard, Text, Layout, Space, CGFloat, Typo (+1 more)

### Community 8 - "Community 8"
Cohesion: 0.22
Nodes (3): AnyObject, SystemNotificationManager, NotificationScheduling

### Community 9 - "Community 9"
Cohesion: 0.13
Nodes (17): Identifiable, Occurrence, ProgrammedRuleCard, Calendar, Date, Void, VirtualOccurrenceRow, RecurrenceSelection (+9 more)

### Community 10 - "Community 10"
Cohesion: 0.06
Nodes (37): CGSize, Equatable, GraphicsContext, BalanceTrail, Entry, Point, Bool, Calendar (+29 more)

### Community 11 - "Community 11"
Cohesion: 0.16
Nodes (7): String, RecurringSeries, RecurringSeriesDetector, Goal, AuditLogView, AddGoalView, GoalRow

### Community 12 - "Community 12"
Cohesion: 0.50
Nodes (3): RecurrenceContextMenu, Void, View

### Community 15 - "Community 15"
Cohesion: 0.20
Nodes (9): a) Diagnosi: perché oggi le ricorrenti "non compaiono", b) Modello dati, c) Algoritmi, d) Eccezioni (`Domain/RecurringSeriesEditor.swift`, `@MainActor`), Domande per Matteo, e) Viste (solo interfaccia dati, la grafica la fa l'impresa grafica sul mockup), f) Test (Swift Testing, `@Suite`, container in memoria `SchemaV3`), g) Sotto-task (ordine obbligato) (+1 more)

### Community 17 - "Community 17"
Cohesion: 0.28
Nodes (5): Transaction, RecurrencePresentationTests, Date, Int, Self

### Community 20 - "Community 20"
Cohesion: 0.29
Nodes (6): Chi fa meglio cosa (osservazioni, non verità: aggiornare), Cosa va bene (da tenere), Da cambiare nell'azienda (priorità alta), Esiti recenti, LEZIONI PER L'AZIENDA — da MoneyTracker (redesign Sentiero), Suggerimenti per la versione successiva

### Community 27 - "Community 27"
Cohesion: 0.11
Nodes (6): DemoShowcaseUITests, String, MoneyTrackerUITestCase, AccountFlowUITests, XCTest, XCTestCase

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (20): chiave(), leggi(), Lettore, main(), Pagina, Path, radice_web(), Cartella servita come "/" del sito: quella con index.html più vicina alla radice (+12 more)

### Community 30 - "Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate"
Cohesion: 0.06
Nodes (34): CodingKey, CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt (+26 more)

### Community 31 - "Community 31"
Cohesion: 0.17
Nodes (11): Cartellino, Claude Code = CAPOCANTIERE, Commissione Suprema (controllo qualità pre-checkpoint), Graphify, graphify, MoneyTracker — Istruzioni per Claude, Quando un'impresa o un subagente ha finito, Regole del cantiere (il resto di questo file ha la precedenza in caso di conflitto) (+3 more)

### Community 34 - "Community 34"
Cohesion: 0.11
Nodes (24): accessibilita(), AXE, BASE, cliccaTutto(), confrontaScreenshot(), controllaLink(), controllaPagina(), differenze (+16 more)

### Community 35 - "RecurrenceCalculator"
Cohesion: 0.09
Nodes (27): CryptoKit, RecurrenceCalculator, RecurrenceException, RecurrenceExceptionCodec, RuleSnapshot, Bool, Calendar, Date (+19 more)

### Community 36 - "Community 36"
Cohesion: 0.20
Nodes (9): CaseIterable, CategoryTint, amber, blue, green, violet, String, UInt32 (+1 more)

### Community 37 - "Community 37"
Cohesion: 0.32
Nodes (6): Account, AccountType, carta, contanti, conto, risparmio

### Community 38 - "Community 38"
Cohesion: 0.05
Nodes (43): Commissione Suprema S-13h (2026-11-14 11:08), Fatti, In corso / prossimi, PIANO DEI LAVORI, S-0 [x] Rimozione del tour, S-10 [x] (2026-11-16: Commissione S-10, nessun difetto bloccante; 92 unit verdi; UI 42/45 nel run completo, i 3 falliti rilanciati singolarmente verdi; 2 voti 9 per commento obsoleto e sentence() lunga, corretti in 1748ef5 senza nuova valutazione) Verifica finale + Commissione Suprema, S-11 [x] Riserve da S-5 (XL e badge demo) — assorbito da S-12; resta solo tab bar XL in S-10, S-12 [x] Movimenti: pagina unica + zona sotto i chip + Ricorrenti (da mockup) — collaudo 2026-11-14 01:30 ok (+35 more)

### Community 39 - "Community 39"
Cohesion: 0.09
Nodes (23): 10. Changelog, v1 (inverno 2025) — Base, v2 (primavera 2026) — Feature complete, v3.10 (settembre 2026) — Tre bug critici: Tocco posteriore che "sparisce", perdita dati al login, ricorrenze arretrate, v3.11 (novembre 2026) — Redesign «Sentiero», step 0: rimozione del tour, v3.12 (novembre 2026) — Redesign «Sentiero», step 1: token, font, dark mode, v3.13 (novembre 2026) — Redesign «Sentiero», step 2–12: componenti, tab bar, Home, Movimenti, Impostazioni (S-2…S-5, S-9, S-12), v3.14 (novembre 2026) — Ricorrenze a serie virtuali (S-13) — cambio di schema, sync e modello dati (+15 more)

### Community 40 - "Community 40"
Cohesion: 0.12
Nodes (17): 6. Funzionalità Implementate, Aggiunta Transazione (AddTransactionView), Biometria (Auth/), Budget (BudgetView), Conti (AccountsView), Haptic Feedback, Home (DashboardView), Impostazioni (SettingsView) (+9 more)

### Community 42 - "RecurrenceOperationStatus"
Cohesion: 0.31
Nodes (3): SentieroAccountsUITests, String, XCUIApplication

### Community 43 - "Community 43"
Cohesion: 0.21
Nodes (7): LocalAuthentication, AppLockGate, AppLockState, LockOverlay, View, BiometricAuthenticating, LAContextAuthenticator

### Community 44 - "Community 44"
Cohesion: 0.15
Nodes (11): CATEGORIE, data, dirLh, lh, OUT, perTipo, principali, r (+3 more)

### Community 45 - "AddTransactionView"
Cohesion: 0.20
Nodes (9): AddTransactionView, Account, Bool, Date, Never, String, Task, Transaction (+1 more)

### Community 46 - "Community 46"
Cohesion: 0.17
Nodes (11): dependencies, axe-core, gremlins.js, lighthouse, pixelmatch, playwright, pngjs, description (+3 more)

### Community 48 - "Community 48"
Cohesion: 0.17
Nodes (10): LastUsedCategory, Movement, Bool, Date, Set, String, LastUsedCategoryTests, Bool (+2 more)

### Community 50 - "Community 50"
Cohesion: 0.38
Nodes (9): esegui_json(), limita(), main(), peso_locale_kb(), Path, radice(), Interpolazione lineare a tratti: punti = [(x, voto), ...] con x crescente., Peso della home: HTML + risorse locali che richiama (stima senza browser). (+1 more)

### Community 51 - "Community 51"
Cohesion: 0.20
Nodes (9): 11. Workflow Checkpoint, 2. Stack Tecnico e Architettura, 3. Struttura del Progetto, 7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»), Bug risolti (sessioni precedenti), Cosa funziona bene, Issue residue (non critiche), MoneyTracker — Documento Completo (+1 more)

### Community 55 - "Community 55"
Cohesion: 0.22
Nodes (8): 1. Il progetto, 2. La squadra, 3. Frasi-comando (uguali con ogni IA: le skill sono in `.agents/skills/`), 4. Turni (uno alla volta, sempre), 5. Lettura a strati (per risparmiare crediti), 6. Regole ferree, 7. Cartelle e nomi, REGOLAMENTO DI CANTIERE — MoneyTracker

### Community 56 - "Community 56"
Cohesion: 0.11
Nodes (17): 2026-11-16 · Riferimenti S-6/S-7/S-8 (Matteo), D-001 · 2026-11-13 · Adozione del modello Cantiere, D-002 · 2026-11-13 · Rimosso il guardiano dei siti web, D-003 · 2026-11-13 · `@MainActor` su CurrencyFormattingTests, D-004 · 2026-11-13 · Simulatore di riferimento, D-005 · 2026-11-13 · Token «Sentiero» e dark mode (S-1), D-006 · 2026-11-13 · Tinte categoria, D-007 · 2026-11-13 · Serie del saldo per la TrailView (+9 more)

### Community 58 - "PianificaView"
Cohesion: 0.19
Nodes (8): FileProtectionType, DemoDataSeeder, applyFileProtection(), ModelContainer, URL, date, name, SharedStore

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
Cohesion: 0.18
Nodes (15): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+7 more)

### Community 70 - "AccountType"
Cohesion: 0.06
Nodes (38): Combine, Encoder, Logger, SBAccount, SBBudget, SBGoal, SBRecurringRule, SBTransaction (+30 more)

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
Cohesion: 0.40
Nodes (4): CHECKPOINT — MoneyTracker, Domani si riparte così, Siamo qui, Stato di salute

### Community 78 - "Community 78"
Cohesion: 0.50
Nodes (3): Come si costruisce, Dettaglio, MAPPA DEL CANTIERE — dove sta tutto

### Community 79 - "Community 79"
Cohesion: 0.22
Nodes (8): Approvazione traduzioni (APPROVAZIONI.md), Da fare, Fatte, PER MATTEO — le cose che aspettano te, S-21 — controllo manuale menu dopo il collaudo — ✅ fatto da Matteo 2026-11-16 21:49: tutto OK, S-24 — verifica del blocco sul caso reale, S-30 — approvazione traduzioni (dopo il collaudo), S-33 — decidere osservazione dopo diagnosi non riproducibile

### Community 82 - "Community 82"
Cohesion: 0.50
Nodes (3): Dettaglio tentativi, Modifiche automatiche, Report notturno MoneyTracker — 25/07/2026

### Community 85 - "Community 85"
Cohesion: 0.22
Nodes (8): APPROVAZIONI DEL COMMITTENTE, S-14 · confronto mese su mese · ritirate — Matteo 2026-11-16 (S-31), S-14 · formulazione percentuali italiana · ritirate — Matteo 2026-11-16 (S-31), S-30 · Categoria dall’ultima volta · ✅ traduzioni approvate da Matteo 2026-11-16, S-6 · testi del riferimento · ✅ (13 traduzioni compilate dal redattore, approvate da Matteo 2026-11-16), S-7 · testi di presentazione · ✅ (idem), S-7p · plurale giorni · ✅ approvato da Matteo 2026-11-16, S-8 · testi del riferimento · ✅ (idem)

### Community 112 - "String"
Cohesion: 0.23
Nodes (6): AccountBalanceCache, Account, PersistentIdentifier, Decimal, String, CurrencyFormattingTests

### Community 113 - "Schema"
Cohesion: 0.14
Nodes (8): Error, MaterializationError, requiresMainContext, saveFailed, UIKeyboardType, AuthField, LoginView, SignUpView

### Community 137 - "StatisticsView.swift"
Cohesion: 0.47
Nodes (5): DS, DSIcon, Set, String, Text

### Community 165 - "RecurrencePresentationCache"
Cohesion: 0.12
Nodes (10): Bool, CGFloat, Date, Int, String, TransactionsSecondaryChips, Category, AddCategoryView (+2 more)

### Community 181 - "Category"
Cohesion: 0.29
Nodes (7): ModelConfiguration, IntentContainer, ModelContainer, DemoDataSeederTests, SchemaMigrationTests, URL, UUID

### Community 182 - "FloatingTabBar"
Cohesion: 0.18
Nodes (9): FloatingTabBar, Item, CGFloat, Int, LocalizedStringKey, String, ContentView, LocalizedStringKey (+1 more)

### Community 183 - "Option"
Cohesion: 0.27
Nodes (3): IntentResult, ProvidesDialog, AccountBalanceTests

### Community 184 - "7. Audit Qualità (Score: 7.2 / 10)"
Cohesion: 0.22
Nodes (10): App, MoneyTrackerApp, Bool, Never, String, Task, UUID, View (+2 more)

### Community 185 - "SwiftData"
Cohesion: 0.21
Nodes (9): RecurrencePresentationCache, RuleKey, Bool, Date, DateInterval, String, TimeZone, UUID (+1 more)

### Community 186 - "Color"
Cohesion: 0.29
Nodes (4): BudgetStatus, Text, Color, UInt32

### Community 187 - "DS"
Cohesion: 0.60
Nodes (4): Option, SegmentedPill, Text, Selection

### Community 189 - "Action"
Cohesion: 0.33
Nodes (6): Kind, expense, income, transfer, MovementRow, String

### Community 191 - "SupabaseManager"
Cohesion: 0.35
Nodes (6): AccountRow, AccountsView, AddAccountView, Account, Bool, String

### Community 192 - "PlanningBudgetCard"
Cohesion: 0.33
Nodes (5): Hashable, AddTxFocus, importo, nome, CategoryPickerView

### Community 194 - "TxFilter"
Cohesion: 0.15
Nodes (12): String, TransactionsSearchField, CGFloat, TransactionsTypeChips, TxFilter, entrate, fisse, ricorrenti (+4 more)

### Community 195 - "Budget.swift"
Cohesion: 0.17
Nodes (10): investimento, Budget, Transaction, TransactionType, entrata, uscita, AddTransferView, AddBudgetView (+2 more)

### Community 196 - "HapticStyle"
Cohesion: 0.33
Nodes (6): HapticStyle, light, medium, rigid, soft, success

### Community 197 - "ThemeNavBarModifier"
Cohesion: 0.33
Nodes (4): Content, View, ThemeNavBarModifier, ViewModifier

### Community 200 - "RecurringRule"
Cohesion: 0.60
Nodes (5): RecurringRule, Bool, Date, String, UUID

### Community 201 - "TransactionsAdvancedFilterSheet"
Cohesion: 0.33
Nodes (5): Bool, Date, Int, String, TransactionsAdvancedFilterSheet

### Community 202 - "DaysRemainingPluralTests.swift"
Cohesion: 0.16
Nodes (7): Bundle, DaysRemainingPluralTests, NSCache, NSString, CategoryClassifying, KeywordCategoryClassifier, KeywordCategoryClassifierTests

### Community 226 - "SupabaseConfig.swift"
Cohesion: 0.70
Nodes (3): RecurringDecimalRoundTripTests, Schema, UUID

### Community 303 - "8. Roadmap"
Cohesion: 0.50
Nodes (4): 8. Roadmap, Livello 2 — Necessario per essere competitivi, Livello 3 — Feature WOW (differenziazione totale), Livello 4 — Futuro

## Knowledge Gaps
- **408 isolated node(s):** `backup.sh script`, `esegui.sh script`, `CHROME_PATH`, `require`, `AXE` (+403 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **223 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Decimal` connect `String` to `CategoryManagementView & AddTransactionView`, `.classify`, `Ricorrenze — motore backfill & Intents dirty-tracking`, `RecurrenceCalculator`, `Schema Migration V1→V2 (Decimal precision)`, `Sync/ricorrenze — file sorgente del checkpoint settembre 2026`, `AccountType`, `SupabaseConfig.swift`, `RecurringRule`, `Community 9`, `Community 10`, `Color`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `Category`, `Option`, `SwiftData`, `PianificaView`, `SupabaseManager`?**
  _High betweenness centrality (0.068) - this node is a cross-community bridge._
- **Why does `SwiftData` connect `Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)` to `PlanningBudgetCard`, `Ricorrenze — motore backfill & Intents dirty-tracking`, `Sync/ricorrenze — file sorgente del checkpoint settembre 2026`, `Schema Migration V1→V2 (Decimal precision)`, `CategoryManagementView & AddTransactionView`, `Community 69`, `AccountType`, `Community 37`, `Budget.swift`, `Community 9`, `Community 10`, `RecurrencePresentationCache`, `Community 12`, `Community 11`, `FloatingTabBar`, `SupabaseManager`?**
  _High betweenness centrality (0.041) - this node is a cross-community bridge._
- **Why does `Foundation` connect `Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)` to `.classify`, `RecurrenceCalculator`, `Schema Migration V1→V2 (Decimal precision)`, `Community 69`, `AccountType`, `NavigationStressUITests`, `Community 37`, `Community 10`, `Community 43`, `DaysRemainingPluralTests.swift`, `Community 11`, `Community 48`, `SwiftData`?**
  _High betweenness centrality (0.032) - this node is a cross-community bridge._
- **Are the 32 inferred relationships involving `Decimal` (e.g. with `.seed()` and `.perform()`) actually correct?**
  _`Decimal` has 32 INFERRED edges - model-reasoned connections that need verification._
- **Are the 20 inferred relationships involving `ModelContext` (e.g. with `.mainContextOnly()` and `.allFrequenciesAndDoneEdits()`) actually correct?**
  _`ModelContext` has 20 INFERRED edges - model-reasoned connections that need verification._
- **What connects `backup.sh script`, `Cartella servita come "/" del sito: quella con index.html più vicina alla radice`, `(lingua dalla cartella, percorso senza cartella della lingua).` to the rest of the system?**
  _434 weakly-connected nodes found - possible documentation gaps or missing edges._
- **Should `Sync/ricorrenze — file sorgente del checkpoint settembre 2026` be split into smaller, more focused modules?**
  _Cohesion score 0.06954997077732321 - nodes in this community are weakly interconnected._