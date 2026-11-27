# Graph Report - MoneyTracker  (2026-11-27)

## Corpus Check
- 422 files · ~451,548 words
- Verdict: corpus is large enough that graph structure adds value.

## Summary
- 5966 nodes · 13315 edges · 498 communities (287 shown, 211 thin omitted)
- Extraction: 89% EXTRACTED · 11% INFERRED · 0% AMBIGUOUS · INFERRED: 1456 edges (avg confidence: 0.8)
- Token cost: 0 input · 0 output

## Graph Freshness
- Built from commit: `dd09649c`
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
- make
- HapticStyle
- .invalidateAll
- RecurringRule
- .capture
- TransactionsAdvancedFilterSheet
- DaysRemainingPluralTests.swift
- Row
- MemorySyncState
- .dao
- .materializeDue
- ProgrammedRuleCard
- .build
- FilterChip
- S-44 · Sicurezza dei dati — verifica sul codice (2026-11-24)
- AuditLogView
- RecurringSeriesDetailView
- 7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)
- 8. Roadmap
- Scope
- FormatterCache
- DaysRemainingPluralTests.swift
- commissione-suprema-2026-11-24-giro3.md
- SupabaseConfig.swift
- 3. Architettura tecnica
- KeywordCategoryClassifier
- 4. Modello dati
- 7. Migrazione
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
- 11. Piano di lavoro
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
- Content
- 10. Piano di prova
- RecurringMaterializerTests
- 12. Rischi, costi, decisioni
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
- SupabaseManager
- 4. Schermata per schermata
- AccountEditing
- 7. Interfaccia
- TransactionEntity
- .build
- 9. Setup e Installazione
- HomeScreen
- .ledger
- SchemaMigration.swift
- MoneyTrackerApp.swift
- ScriptedApi
- PianificaView
- DemoDataTest
- H
- 6. Coerenza con S-50
- HomeAccountOrder
- SessionStore
- StatisticsTest
- 3. Logica di dominio da portare identica
- 11. Rischi e decisioni
- Theme.kt
- 5. Interfaccia
- SupabaseManager
- .rule
- 10. Piano di lavoro
- 1. Visione e Posizionamento
- SfIcons
- AmountsTest
- HomeAccountOrderTest
- SyncStatus
- FontRegistrationTests.swift
- .suggest
- e2e-vectors.py
- .authenticate
- TransactionOpsTest
- .tx
- TrailView
- Calendario social Bucktrail · v2 (23/11/2026)
- ClassifierProvider
- Categories
- ShortcutSetup
- Parità Android ↔ iOS — inventario e checklist
- 5. Auth, sync, Intents, notifiche, export
- Collaudo Android — 2026-11-23
- Commissione Suprema 2026-11-24
- make
- DaysRemainingPluralTests.swift
- Type.kt
- WidgetContentTest
- 1. Token grafici
- Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)
- Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet)
- RecurrenceCalculator
- RecurringSeriesEditor
- .rule
- CategoryTintTest
- ExportsTest
- AmountsLimitsTest
- 7. Checklist funzioni (F-xxx)
- Stress test Android Bucktrail (2026-11-23)
- SwipeRules
- NetworkMonitor
- Sendable
- CategoryEntity
- CategoryTint.kt
- KeywordCategoryClassifier
- RecurringOps.kt
- Error
- riassunto.mjs
- Mode
- AddGoalView
- AuditLogger
- TxFilter
- Movement
- RecoveryKey
- ApiException
- esporta.py
- FilterChip
- MovementRow
- TransactionsSecondaryChips
- ProgrammedRuleCard
- RecurringSeriesDetailView
- Date
- .format
- Fixture
- Type.kt
- .plan
- AuditLogView
- .tx
- .resolve
- 4. Modelli Dati
- CodingKeys
- .forceReset
- .build
- .loginAndBothPushAndPullUseOnlyOriginalPlainCalls
- Selection
- .dateFormatter
- .dateFormatter
- SyncEngine.kt
- SupabaseConfig.swift
- CodingKeys
- categoryLabel
- .plan
- AdvancedFilterSheet
- .movement
- Failure
- E2EStringsTest
- .saveTransaction
- FilterChip
- MovementRow
- FormatterCache
- TransactionsAdvancedFilterSheet
- CodingKeys
- Scope
- E2EOperation
- SyncStatus
- ExportsTest
- MoneyTrackerApp.swift
- RecurringSeriesDetailView
- RecoveryKeyCard
- DaysRemainingPluralTests.swift
- E2EMigratorGenerationTests.swift
- ObsoleteVaultFilterTest
- FontRegistrationTests
- AuditLogView
- HapticStyle
- .testLiveSync
- 1. Modello di minaccia
- .plan
- MoneyTrackerApp.swift
- InMemoryRemote.swift
- SyncBaselineTest
- UploadMode
- DaysRemainingPluralTests.swift

## God Nodes (most connected - your core abstractions)
1. `Decimal` - 109 edges
2. `Text` - 98 edges
3. `Foundation` - 87 edges
4. `ModelContext` - 83 edges
5. `SyncTable` - 79 edges
6. `Row` - 63 edges
7. `SwiftData` - 61 edges
8. `E2EMigrator` - 57 edges
9. `E2EServerRow` - 57 edges
10. `E2EMigrator` - 56 edges

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

## Communities (498 total, 211 thin omitted)

### Community 0 - "CategoryManagementView & AddTransactionView"
Cohesion: 0.11
Nodes (32): BudgetStatus, FilterChip, Style, advanced, primary, secondary, Void, Color (+24 more)

### Community 1 - "Ricorrenze — motore backfill & Intents dirty-tracking"
Cohesion: 0.14
Nodes (16): ArraySlice, keyId, Row, SymmetricKey, UUID, VaultRemote, E2EDeadVaultCleanupRetryTests, InMemoryRemote (+8 more)

### Community 2 - "Sync/ricorrenze — file sorgente del checkpoint settembre 2026"
Cohesion: 0.07
Nodes (30): LayoutRegressionTest, BalanceWidget, BalanceWidgetReceiver, hide(), BigDecimal, Boolean, Context, String (+22 more)

### Community 3 - "Schema Migration V1→V2 (Decimal precision)"
Cohesion: 0.25
Nodes (11): RecurringRuleEntity, Changes, BigDecimal, Instant, List, RecurrenceCalculator, RuleSnapshot, Set (+3 more)

### Community 4 - "Supabase DTOs (SBAccount/SBBudget/SBGoal/SBTransaction)"
Cohesion: 0.20
Nodes (28): E2EBackend, applyGateEffects(), clearE2ESession(), downloadE2E(), e2eRemote(), initialE2ESync(), makeMigrator(), pauseE2ESync() (+20 more)

### Community 5 - "Community 5"
Cohesion: 0.19
Nodes (9): NavigationStressUITests, RecurrenceFlowUITests, TransactionFlowUITests, MoneyTrackerUITestCase, StaticString, String, UInt, XCUIElement (+1 more)

### Community 6 - "AppIntents — Tocco posteriore/Siri (AddExpenseIntent)"
Cohesion: 0.12
Nodes (11): AccountBalanceCache, Account, PersistentIdentifier, Date, Decimal, Bool, String, CurrencyFormattingTests (+3 more)

### Community 7 - "Supabase CodingKeys (snake_case mapping)"
Cohesion: 0.23
Nodes (5): Instant, Int, RuleSnapshot, String, RecurrenceCalculatorTest

### Community 9 - "Community 9"
Cohesion: 0.12
Nodes (20): haptic(), SeriesCache, Binding, Bool, Date, Int, Occurrence, RecurringSeries (+12 more)

### Community 10 - "Community 10"
Cohesion: 0.12
Nodes (18): DashboardView, HomeAccountOrderSheet, ProjectionCache, Account, BalanceTrail, Bool, Calendar, CGFloat (+10 more)

### Community 11 - "Community 11"
Cohesion: 0.06
Nodes (36): Bar, BigDecimal, List, String, YearMonth, ZoneId, Labels, Line (+28 more)

### Community 12 - "Community 12"
Cohesion: 0.24
Nodes (5): E2EController, E2EDeadVaultCleanupRetryTest, Boolean, E2EFlagOffTest, CoroutineScope

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
Cohesion: 0.21
Nodes (18): Codable, AccountExport, BudgetExport, CSVFile, CurrencyConfirmSheet, EnvironmentValues, GDPRExport, GoalExport (+10 more)

### Community 29 - "Community 29"
Cohesion: 0.12
Nodes (20): chiave(), leggi(), Lettore, main(), Pagina, Path, radice_web(), Cartella servita come "/" del sito: quella con index.html più vicina alla radice (+12 more)

### Community 30 - "Checkpoint settembre 2026 — Tocco posteriore, perdita dati, ricorrenze arretrate"
Cohesion: 0.06
Nodes (33): CodingKeys, accountId, amount, category, categoryIcon, colorHex, createdAt, currentAmount (+25 more)

### Community 31 - "Community 31"
Cohesion: 0.40
Nodes (4): Cartellino, Claude Code = CAPOCANTIERE, Quando un'impresa o un subagente ha finito, Risparmio di crediti (regole ferree)

### Community 34 - "Community 34"
Cohesion: 0.11
Nodes (24): accessibilita(), AXE, BASE, cliccaTutto(), confrontaScreenshot(), controllaLink(), controllaPagina(), differenze (+16 more)

### Community 35 - "RecurrenceCalculator"
Cohesion: 0.22
Nodes (12): Date, Failure, decodedOnMainThread, encodedOnMainThread, RecurringCollisionTests, RecurringSeriesEditorTests, Calendar, Date (+4 more)

### Community 36 - "Community 36"
Cohesion: 0.10
Nodes (20): 11.3 Task di Claude Code, S-60a · Contratto e vettori condivisi (≈ 1,5 h), S-60b · Funzione `bank` (≈ 2 h), S-60c · SQL e server finto (≈ 1,5 h), S-60d · Dominio puro iOS (≈ 2 h), S-60e · Dominio puro Android (≈ 2 h), S-60f · Modelli iOS e SchemaV4 (≈ 1,5 h), S-60g · Room 3 → 4 (≈ 1,5 h) (+12 more)

### Community 37 - "ModelConfiguration"
Cohesion: 0.22
Nodes (22): background(), body_slide(), brand(), closer(), diagram(), font(), frame(), infographic() (+14 more)

### Community 38 - "Community 38"
Cohesion: 0.09
Nodes (22): Commissione Suprema S-13h (2026-11-14 11:08), Fatti, S-16 [x] FUORI DAL RESTYLING (test su precisione Decimal elevata) Verificare precisione Decimal elevata nella persistenza RecurringRule, S-17 [x] (collaudo ok 2026-11-14) Pull: non cancellare regole locali non ancora spedite, S-18 [x] Rifinitura grafica dei virtuali e delle serie programmate, S-19 [x] Revisione testi e traduzioni S-13g · collaudato 2026-11-16 09:47: collaudo ok (solo 7 strings + .cantiere, plutil ok, 380 chiavi allineate, nessuna chiave persa, 0 marker). Approvazione Matteo in APPROVAZIONI.md ancora ⏳. Note: de "Keine" per "Conto" (neutro) → "Keines"; es "Ninguno" per "Conto" (cuenta) → "Ninguna"; de riga 103 resta "Vorkommen"; zh riga 103 "记录" per occorrenze (vs 项目). · **chiuso 2026-11-16 09:48: collaudo ok** (5ca721e): de «Keines»/«Termine», es «Ninguna», zh «项目» applicati, chiavi invariate, plutil ok, nessun altro «Vorkommen»/«记录» residuo (99 «历史记录» = Storico ok). Approvazione Matteo in APPROVAZIONI.md resta ⏳; «Termin» (de) e i termini segnalati vanno riletti da un madrelingua., S-20 [x] collaudato 2026-11-14 11:06 (bf9727e: guard ok, regressione ok, 68 unit verdi) CONFERMATO Verificare editor di una serie terminata prima della prima occorrenza, S-21 [x] Performance: ricalcoli per riga in TransactionsView (Commissione S-13h, giudice 4: 8/10) (+14 more)

### Community 39 - "Community 39"
Cohesion: 0.06
Nodes (33): 10. Changelog, v1 (inverno 2025) — Base, v2 (primavera 2026) — Feature complete, v3.10 (settembre 2026) — Tre bug critici: Tocco posteriore che "sparisce", perdita dati al login, ricorrenze arretrate, v3.11 (novembre 2026) — Redesign «Sentiero», step 0: rimozione del tour, v3.12 (novembre 2026) — Redesign «Sentiero», step 1: token, font, dark mode, v3.13 (novembre 2026) — Redesign «Sentiero», step 2–12: componenti, tab bar, Home, Movimenti, Impostazioni (S-2…S-5, S-9, S-12), v3.14 (novembre 2026) — Ricorrenze a serie virtuali (S-13) — cambio di schema, sync e modello dati (+25 more)

### Community 40 - "Community 40"
Cohesion: 0.11
Nodes (19): 6. Funzionalità Implementate, Aggiunta Transazione (AddTransactionView), Android (`03_CODICE/bucktrail-android`), Biometria (Auth/), Budget (BudgetView), Conti (AccountsView), Haptic Feedback, Home (DashboardView) (+11 more)

### Community 42 - "RecurrenceOperationStatus"
Cohesion: 0.25
Nodes (3): SentieroAccountsUITests, String, XCUIApplication

### Community 43 - "Community 43"
Cohesion: 0.11
Nodes (17): 1. Profili (@bucktrailapp), 2. Caption per format (primo blocco), 3. Scheda App Store, 4. Landing, Aggiornamento lancio mobile · testi approvati il 20/11, Bucktrail — testi social, App Store, landing (v1), Dubbi per Matteo, English (+9 more)

### Community 44 - "Community 44"
Cohesion: 0.14
Nodes (15): ByteArray, String, RecoveryKey, CryptoException, Failure, ByteArray, Int, String (+7 more)

### Community 45 - "AddTransactionView"
Cohesion: 0.36
Nodes (5): hero(), html(), Prima slide / copertina: scura, di impatto. alto=1350 (carosello 4:5) o 1920 (co, slide_app(), slide_fine()

### Community 46 - "Community 46"
Cohesion: 0.17
Nodes (11): dependencies, axe-core, gremlins.js, lighthouse, pixelmatch, playwright, pngjs, description (+3 more)

### Community 48 - "Community 48"
Cohesion: 0.12
Nodes (22): Snapshot, SyncRow, SBAccount, SBBudget, SBGoal, SBRecurringRule, SBTransaction, Account (+14 more)

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
Cohesion: 0.04
Nodes (46): 2026-11-16 · Riferimenti S-6/S-7/S-8 (Matteo), 2026-11-17 · Nessun premium in abbonamento, 2026-11-17 · Nome utente dei profili social: @bucktrailapp, 2026-11-17 · Regola permanente del progetto SOCIAL, 2026-11-17 · Social prima di Apple Developer Program, 2026-11-17 · Social senza elementi personali; video in IA in valutazione, 2026-11-17 · Soglie del segnale di interesse (✅ CONFERMATE da Matteo il 2026-11-17, cifre comprese: 40 iscritti, 200 visite, 5%, 5 commenti — non si spostano più) — SC-1b, 2026-11-17 · TikTok: account personale, senza musica (+38 more)

### Community 58 - "PianificaView"
Cohesion: 0.14
Nodes (18): MigrationDirection, E2EMigrator, Failure, Boolean, ByteArray, E2EMigrationMarker, JsonObject, Map (+10 more)

### Community 59 - "Community 59"
Cohesion: 0.50
Nodes (7): candidati(), impronta(), leggi_fonti(), magazzino(), main(), Path, scrivi_fonti()

### Community 61 - "Community 61"
Cohesion: 0.27
Nodes (12): E2EGate, Boolean, Int, JsonObject, String, Locked, LockReason, Mode (+4 more)

### Community 63 - "Community 63"
Cohesion: 0.06
Nodes (35): Boolean, Flow, List, LedgerState, Repository, Source, NotSignedInException, Backoff (+27 more)

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
Cohesion: 0.06
Nodes (45): accountTypeCategoryProxy(), accountTypeIcon(), accountTypeRes(), categoryLabel(), AccountType, android, Int, String (+37 more)

### Community 68 - "Community 68"
Cohesion: 0.07
Nodes (49): Work, build(), main(), p_dir(), testi(), bars(), before_after(), cards() (+41 more)

### Community 69 - "Community 69"
Cohesion: 0.16
Nodes (17): AppIntent, AppIntents, AppShortcut, AppShortcutsProvider, DynamicOptionsProvider, LocalizedStringResource, AccountOptionsProvider, AddExpenseIntent (+9 more)

### Community 70 - "AccountType"
Cohesion: 0.11
Nodes (21): E2EMigratorTests, Fixture, Interrupted, OldClientURLProtocol, Remote, Bool, E2EMigrationMarker, E2EMigrator (+13 more)

### Community 71 - "Community 71"
Cohesion: 0.33
Nodes (5): Cantiere di sviluppo, Features, Personal Finance Tracker, Security, Tech Stack

### Community 72 - "Community 72"
Cohesion: 0.23
Nodes (9): CGContext, CGPoint, FontRegistrationTests, UIColor, UIFont, UIGraphicsPDFRendererContext, NumberFormatter, PDFReportGenerator (+1 more)

### Community 73 - "Community 73"
Cohesion: 0.80
Nodes (4): esegui(), manca(), peggiora(), collaudo.sh script

### Community 74 - "Community 74"
Cohesion: 0.60
Nodes (4): main(), Path, radice_progetto(), suggerisci()

### Community 75 - "Community 75"
Cohesion: 0.25
Nodes (7): Instant, Int, Set, String, RecurringOpsTest, World, Action

### Community 77 - "Community 77"
Cohesion: 0.18
Nodes (10): Bug, Cantiere, CHECKPOINT — MoneyTracker, Cose che deve fare Matteo, Domani si riparte così, Fatto dall'ultimo checkpoint (2026-11-26 15:36), Siamo qui, Stato di salute (+2 more)

### Community 78 - "Community 78"
Cohesion: 0.40
Nodes (4): Come si costruisce, Dettaglio, MAPPA DEL CANTIERE — dove sta tutto, Social · backup novembre 2026

### Community 79 - "Community 79"
Cohesion: 0.17
Nodes (11): ANDROID · aggiornare l'app sul tuo telefono, BANCA · modello economico — cosa resta a te (tutto spiegato in `.cantiere/banca-modello-economico.md`, copia su Drive `02_RISORSE/lavorate/banca-modello-economico-2026-11-25.md`), BANCA · S-60t — tre verifiche prima del collegamento bancario (si può fare quando vuoi, non blocca il lavoro dell'IA), Da fare, E2E · prova reale della Protezione avanzata con un account di prova (dopo S-50p, quando vuoi), Fatte, NotebookLM (bibliotecario) · 6 fonti da aggiungere, PER MATTEO — le cose che aspettano te (+3 more)

### Community 82 - "Community 82"
Cohesion: 0.50
Nodes (3): Dettaglio tentativi, Modifiche automatiche, Report notturno MoneyTracker — 25/07/2026

### Community 85 - "Community 85"
Cohesion: 0.13
Nodes (14): APPROVAZIONI DEL COMMITTENTE, S-14 · confronto mese su mese · ritirate — Matteo 2026-11-16 (S-31), S-14 · formulazione percentuali italiana · ritirate — Matteo 2026-11-16 (S-31), S-30 · Categoria dall’ultima volta · ✅ traduzioni approvate da Matteo 2026-11-16, S-50p · Sito: FAQ sicurezza (IT/EN) e informativa privacy con la Protezione avanzata · ✅ Matteo 2026-11-26 18:23 (operaio, 2026-11-26), S-50v · Privacy dell'app (it/en) · ✅ Matteo 2026-11-26 18:23 (redattore, 2026-11-26), S-50x · Privacy: email dell'account inviate tramite Brevo · ✅ Matteo 2026-11-26 18:54 (capocantiere, 2026-11-26 18:52), S-50y · Meta description e hreflang del sito · ✅ Matteo 2026-11-26 18:54 (redattore, 2026-11-26) (+6 more)

### Community 99 - "Community 99"
Cohesion: 0.08
Nodes (15): Auth, Combine, CommonCrypto, CryptoKit, Foundation, LocalAuthentication, MoneyTracker, Observation (+7 more)

### Community 100 - "Community 100"
Cohesion: 0.07
Nodes (14): AppViewModel, Boolean, com, Instant, java, List, Long, StateFlow (+6 more)

### Community 101 - "Community 101"
Cohesion: 0.06
Nodes (31): Issue, concurrentActivation, failed, incorrectSecret, offline, LocalizedStringKey, E2EFeature, Bool (+23 more)

### Community 102 - "Community 102"
Cohesion: 0.07
Nodes (27): Hashable, AddTransactionView, AddTxFocus, importo, nome, CategoryPickerView, Account, Bool (+19 more)

### Community 104 - "Community 104"
Cohesion: 0.19
Nodes (6): AuditLog, AuditTracker, Entry, Flow, List, Long

### Community 105 - "Community 105"
Cohesion: 0.09
Nodes (23): RecurringSeriesEditor, Calendar, RecurrenceCalculator, TimeZone, Void, PendingAction, skip, terminateAfter (+15 more)

### Community 106 - "Community 106"
Cohesion: 0.19
Nodes (8): Bundle, MainActivity, AppLockGate(), LockOverlay(), BalanceActivity, BalanceCard(), Bundle, FragmentActivity

### Community 107 - "Community 107"
Cohesion: 0.10
Nodes (15): BudgetData, Budgeting, GoalData, BigDecimal, Collection, List, Set, String (+7 more)

### Community 108 - "Community 108"
Cohesion: 0.05
Nodes (34): CategoryEditing, DeleteMessage, Boolean, Int, List, String, fold(), KeywordCategoryClassifier (+26 more)

### Community 109 - "Community 109"
Cohesion: 0.10
Nodes (20): data, Secret, passphrase, recovery, Data, Int, SymmetricKey, UInt32 (+12 more)

### Community 110 - "Community 110"
Cohesion: 0.17
Nodes (13): AnyCancellable, E2EController, Protection, active, locked, off, pending, Bool (+5 more)

### Community 111 - "Community 111"
Cohesion: 0.14
Nodes (15): E2ESettingsOffUITests, E2EUITests, Fixture, interrupted, locked, off, offline, priorAttempt (+7 more)

### Community 112 - "TxFilter"
Cohesion: 0.15
Nodes (9): HttpSupabaseApi, Boolean, Int, java, JsonObject, List, Map, String (+1 more)

### Community 113 - "Schema"
Cohesion: 0.14
Nodes (18): Error, Encodable, Activation, ActivationRollback, E2EServer, E2EServerAccess, E2EServerPatch, E2EServerRow (+10 more)

### Community 126 - "Community 126"
Cohesion: 0.29
Nodes (3): IntentResult, ProvidesDialog, AccountBalanceTests

### Community 127 - "Community 127"
Cohesion: 0.10
Nodes (15): VaultSupabaseApi, E2EMigratorTest, expectError(), InterruptedMigration, E2EController, Int, MigrationRows, Snapshot (+7 more)

### Community 128 - "Community 128"
Cohesion: 0.25
Nodes (10): Fixture, Account, Bool, ModelContainer, Set, SyncBaseline, SyncService, UserDefaults (+2 more)

### Community 129 - "Community 129"
Cohesion: 0.18
Nodes (13): CaseIterable, Account, AccountType, carta, contanti, conto, investimento, risparmio (+5 more)

### Community 130 - "Community 130"
Cohesion: 0.09
Nodes (23): Content, Card, AdvancedProtectionView, E2EAction, E2EMessage, E2EPage, E2EProgress, E2ESettingsRow (+15 more)

### Community 137 - "StatisticsView.swift"
Cohesion: 0.16
Nodes (14): CodingKeys, id, kind, payload, userId, IDRow, SupabaseVaultAccess, KeyPath (+6 more)

### Community 165 - ".invalidateAll"
Cohesion: 0.29
Nodes (6): Caption, Instagram, Musica, Post 1 — Carosello «Ogni conto al suo posto» (v2), Slide (ordine di pubblicazione), TikTok

### Community 181 - "ModelConfiguration"
Cohesion: 0.24
Nodes (4): BucktrailDatabase, Snapshot, RoomLocalStore, RoomDatabase

### Community 182 - "FloatingTabBar"
Cohesion: 0.18
Nodes (9): FloatingTabBar, Item, CGFloat, Int, LocalizedStringKey, String, ContentView, LocalizedStringKey (+1 more)

### Community 183 - ".init"
Cohesion: 0.24
Nodes (3): Failure, String, VaultCryptoVectorsTest

### Community 184 - "7. Audit Qualità (Score: 7.2 / 10)"
Cohesion: 0.20
Nodes (10): LockReason, needsSecret, protectionRemoved, transition, unsupported, Mode, locked, plain (+2 more)

### Community 185 - ".init"
Cohesion: 0.08
Nodes (24): Progetto SOCIAL (avviato 2026-11-17), S-10 [x] (2026-11-16: Commissione S-10, nessun difetto bloccante; 92 unit verdi; UI 42/45 nel run completo, i 3 falliti rilanciati singolarmente verdi; 2 voti 9 per commento obsoleto e sentence() lunga, corretti in 1748ef5 senza nuova valutazione) Verifica finale + Commissione Suprema, S-14 [x] Statistiche: confronto mese su mese — rimosso su richiesta di Matteo 2026-11-16, S-15 [x] Diagnosticare due test UI che non trovano il movimento appena salvato, S-38 [x] Commissione — pacchetto A (Codex): virtuali che ignorano filtri avanzati, date filtro personalizzato non salvate, conferma per «Salta mese/Termina…», «•••• €» fisso, detector ricalcolato a ogni render, set di ID regole in `movementList`, force-unwrap (RecurrenceControls:69, RecurringSeriesDetector:58-66), `RecurringMaterializer` duplica `snapshot`, tipo/selected ridondanti in `typeChips`., S-39 [x] Commissione — traduzioni (redattore): ~40 stringhe visibili in italiano in tutte le lingue (Settings, notifiche, Login/SignUp, AuditLog, Budget, filtri…), frasi composte a pezzi, chiavi doppie «Fine»/«Tipo». Poi approvazione Matteo., S-40 [x] Commissione — font fissi (Codex): ~200 `.font(.system(size:))` → token `DS.Typo.*` (Dynamic Type), `SectionLabel` incluso., S-41 [x] Home — spesa fissa singola nel mese di competenza (Matteo, 2026-11-20) (+16 more)

### Community 186 - "Color"
Cohesion: 0.16
Nodes (34): BudgetStatus(), Card(), CategoryIconBox(), dashedBorder(), defaultMinSize18(), DemoBanner(), EmptyState(), FilterChip() (+26 more)

### Community 189 - "Action"
Cohesion: 0.18
Nodes (10): AppLockGate, AppLockState, LockOverlay, Bool, View, Void, View, ObservableObject (+2 more)

### Community 190 - "FontRegistrationTests"
Cohesion: 0.36
Nodes (8): AdvancedFilterSheet(), AmountField(), DateRow(), Boolean, Int, LocalDate, Modifier, String

### Community 191 - "SupabaseManager"
Cohesion: 0.46
Nodes (7): fetch(), handle(), json(), secure(), SECURITY, subscribe(), UTM

### Community 192 - "ShareSheet"
Cohesion: 0.09
Nodes (37): AccountSaveRequest, AddAccountForm(), BigDecimal, Boolean, List, String, AddTransactionForm(), freqLabelRes() (+29 more)

### Community 193 - "MaterializationError"
Cohesion: 0.05
Nodes (50): E2EMigrationTransportInstrumentedTest, Instant, ZoneId, E2EVerifier, Boolean, JsonElement, JsonObject, List (+42 more)

### Community 194 - "LoginView"
Cohesion: 0.22
Nodes (8): attribution, button, campaign, fields, form, localPreview, msg, status

### Community 195 - "make"
Cohesion: 0.07
Nodes (29): 0. Richieste di Matteo (testo vincolante), 1. Sintesi e fattibilità, 2.1 Autorizzazione (primo passo della sessione), 2.2 File, 2.3 Decisioni tecniche (motivate), 2.4 Forma del tipo puro (indicativa, Codex può adattare i nomi), 2.5 Casi limite, 2.6 Localizzazione (chiave = testo italiano, come da convenzione; aggiungere in tutti e 7 i `.lproj`, incluso `it`) (+21 more)

### Community 196 - "HapticStyle"
Cohesion: 0.24
Nodes (12): AlreadyExists, AuthErrors, AuthMessage, EmailNotConfirmed, Generic, InvalidCredentials, InvalidEmail, Offline (+4 more)

### Community 197 - ".invalidateAll"
Cohesion: 0.23
Nodes (7): RecurringMaterializerTests, Calendar, Date, Int, ModelContainer, String, RecurringMaterializer

### Community 198 - "RecurringRule"
Cohesion: 0.18
Nodes (10): Calcolo settimanale, Colonne dal 25/11/2026, Decisione sui format, Diario delle metriche social, Engagement rate, Post 1 · Instagram, Post 1 · TikTok, Post 2 · Instagram (+2 more)

### Community 201 - "TransactionsAdvancedFilterSheet"
Cohesion: 0.22
Nodes (8): RecoveryKeyCard, Binding, Bool, String, Void, Substring, UIKit, UniformTypeIdentifiers

### Community 202 - "DaysRemainingPluralTests.swift"
Cohesion: 0.27
Nodes (6): E2EProtectionUiTest, Boolean, Int, Long, Set, String

### Community 204 - "MemorySyncState"
Cohesion: 0.27
Nodes (8): Bt, BucktrailColors, c(), colors(), Boolean, Int, Long, TintColors

### Community 205 - ".dao"
Cohesion: 0.24
Nodes (10): AddBudgetView, BudgetHistorySheet, BudgetRow, Account, Bool, Budget, Date, Set (+2 more)

### Community 206 - ".materializeDue"
Cohesion: 0.12
Nodes (17): 10.3 Task, S-50a · Server finto e test del server finto (≈ 1 h), S-50b · Nucleo crittografico iOS + vettori (≈ 2 h), S-50c · Nucleo crittografico Android + vettori (≈ 1,5 h), S-50d · iOS: trasporto `SyncRemote` senza cambiare comportamento (≈ 2 h) → poi COLLAUDO BLOCCO 1, S-50e · iOS: vault, Keychain, server `mt_e2e`, gate (≈ 2 h), S-50f · Android: `VaultApi`, decoratore, Keystore, gate (≈ 2 h), S-50g · Interoperabilità delle righe iOS↔Android (≈ 1 h) (+9 more)

### Community 207 - "ProgrammedRuleCard"
Cohesion: 0.05
Nodes (24): E2EKeyStoreInstrumentedTest, TwoDeviceLiveSyncTest, E2EKeyStore, E2ESecrets, Boolean, ByteArray, E2EMigrationMarker, JsonObject (+16 more)

### Community 208 - ".build"
Cohesion: 0.21
Nodes (21): AdvancedProtectionRow(), AdvancedProtectionSheet(), clearClipboardLater(), findActivity(), Boolean, Context, E2EController, Int (+13 more)

### Community 209 - "FilterChip"
Cohesion: 0.16
Nodes (11): ApiException, FakeVaultSupabase, Boolean, ByteArray, E2EMigrationMarker, Int, JsonObject, List (+3 more)

### Community 210 - "S-44 · Sicurezza dei dati — verifica sul codice (2026-11-24)"
Cohesion: 0.33
Nodes (5): Android, Cloud (Supabase, comune a iOS e Android), iOS, Lacune e decisione, S-44 · Sicurezza dei dati — verifica sul codice (2026-11-24)

### Community 211 - "AuditLogView"
Cohesion: 0.16
Nodes (15): RecurringRule, Bool, Date, String, UUID, RecurrencePresentationCache, RuleKey, Bool (+7 more)

### Community 212 - "RecurringSeriesDetailView"
Cohesion: 0.08
Nodes (10): E2EDeadVaultKeyTest, OldClientTest, VaultSupabaseApiTest, budget(), FixedAuth, goal(), T, rule() (+2 more)

### Community 213 - "7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)"
Cohesion: 0.15
Nodes (12): 1.1 In 12 righe, 1.2 Cosa fa, 1.3 Cosa NON fa (v1), 1. Sintesi e perimetro, 2.1 Confronto (verificato sul web il 2026-11-24; dove la fonte è di terzi è scritto), 2.2 Raccomandazione, 2.3 Uscita dal fornitore (lock-in), 2. Scelta del fornitore (+4 more)

### Community 214 - "8. Roadmap"
Cohesion: 0.17
Nodes (11): 0. Sintesi, 10.1 Regole comuni a tutti i task (R1–R10) — valgono come parte di ogni prompt, 10.2 Ordine e dipendenze, 10. Piano di lavoro, 2. Cosa si cifra, 4.1 Dove sta la DEK sul dispositivo, 4.2 Casi di vita, 4. Custodia delle chiavi (+3 more)

### Community 215 - "Scope"
Cohesion: 0.12
Nodes (15): 10. Cosa fare, in ordine, 11. Fonti, 1. Sintesi in dieci righe, 2. Chi paga chi (il flusso dei soldi), 3. Perché serve un abbonamento: il problema dei costi, 4. Cosa sappiamo e cosa NO su Enable Banking, 5. Il modello scelto (decisione di Matteo, 2026-11-25), 6. Tabelle con `c` variabile (+7 more)

### Community 216 - "FormatterCache"
Cohesion: 0.13
Nodes (15): Call, delete, deleteE2E, deleteVault, fetchIds, insertE2E, lookupE2E, patchE2E (+7 more)

### Community 217 - "DaysRemainingPluralTests.swift"
Cohesion: 0.15
Nodes (9): E2EMigrationMarker, E2EGateTest, Fixture, ByteArray, E2EGate, JsonObject, String, AutoCloseable (+1 more)

### Community 219 - "SupabaseConfig.swift"
Cohesion: 0.30
Nodes (9): keyId, E2EKeyStore, Entry, keychain, StoredEntry, Any, String, SymmetricKey (+1 more)

### Community 220 - "3. Architettura tecnica"
Cohesion: 0.18
Nodes (11): 3.1 Componenti, 3.2 Segreti (mai nell'app, mai nel repository, mai nei log), 3.3 Interfaccia interna `BankProvider`, 3.4.1 Azioni, 3.4.2 Sigilli (`session_token`, `account_token`), 3.4.3 Errori (HTTP + `{"error":"<codice>"}`, nient'altro), 3.4 Contratto v1 tra app e funzione (unico, uguale per iOS e Android), 3.5 Flusso di collegamento (con protezione tipo PKCE) (+3 more)

### Community 221 - "KeywordCategoryClassifier"
Cohesion: 0.16
Nodes (6): LifecycleURLProtocol, URLRequest, ObsoleteVaultURLProtocol, Bool, URLRequest, URLProtocol

### Community 222 - "4. Modello dati"
Cohesion: 0.22
Nodes (9): 4.1 Principio, 4.2 Entità nuove, 4.3 Identificativi stabili e deduplica idempotente, 4.4 Riconciliazione con i movimenti manuali (soglie esatte), 4.5 Schema server (SQL completo, idempotente, additivo, reversibile), 4.6 Migrazioni locali (senza perdita di dati, retrocompatibili), 4.7 Codice puro aggiunto (Domain, solo file nuovi, motivati: logica testabile senza UI né rete, condivisa nei vettori), 4.8 Sincronizzazione delle entità nuove (+1 more)

### Community 223 - "7. Migrazione"
Cohesion: 0.22
Nodes (9): 7.1 Stati, 7.2 Modalità decisa a ogni operazione di sync — `E2EGate.resolve()`, 7.3 Attivazione (dispositivo A), 7.4 Disattivazione (dispositivo con DEK), 7.5 Prova che nessuna riga si perde (verifica), 7.6 Cambi di modalità e conflitti, 7.7 Rollback dell'attivazione (automatico dopo 2 verifiche fallite, o pulsante K44 finché lo stato è `migrating`), 7.8 «Ricomincia da questo dispositivo» (frase e chiave perse) (+1 more)

### Community 226 - "Option"
Cohesion: 0.24
Nodes (8): ModelConfiguration, DemoDataSeederTests, RecurringDecimalRoundTripTests, Schema, UUID, SchemaMigrationTests, URL, UUID

### Community 303 - "8. Roadmap"
Cohesion: 0.25
Nodes (7): Commissione Suprema (controllo qualità pre-checkpoint), Graphify, graphify, Progetto SOCIAL, REGOLE DEL PROGETTO — MoneyTracker, Struttura cartella, Workflow checkpoint

### Community 304 - "Decimal"
Cohesion: 0.25
Nodes (8): Fixture, interrupted, locked, off, offline, priorAttempt, removed, transition

### Community 307 - "PIANO DEI LAVORI"
Cohesion: 0.40
Nodes (4): PIANO DEI LAVORI, Proposte prodotto · Android e collegamento bancario, Richieste di Matteo · 2026-11-24 sera, S-70 · Doppio tap con categorie + simulazione «E se…?» (idee di Matteo, 2026-11-26)

### Community 309 - "README.md"
Cohesion: 0.27
Nodes (5): RecurrenceCalculatorTests, Date, Int, RuleSnapshot, String

### Community 310 - ".centsSurviveSwiftDataAndDTOJSON"
Cohesion: 0.83
Nodes (3): gradlew script, die(), warn()

### Community 311 - "README.md"
Cohesion: 0.15
Nodes (8): Calendario social Bucktrail · v2 (23/11/2026), Mappa vecchi post → nuovi, Note di verifica, Nuovo elenco, Guida alle schermate di Bucktrail, Master social Bucktrail, Cosa raccogliere, Schermate dell’app

### Community 312 - "7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)"
Cohesion: 0.12
Nodes (5): BucktrailDao, com, Flow, List, String

### Community 313 - "build.py"
Cohesion: 0.35
Nodes (11): calculation(), editorial(), inset(), laptop(), left(), phone(), right_phone(), save() (+3 more)

### Community 314 - "FormatterCache"
Cohesion: 0.38
Nodes (5): ShareSheet, Any, Context, UIActivityViewController, UIViewControllerRepresentable

### Community 315 - ".resolve"
Cohesion: 0.15
Nodes (12): E2EObsoleteVaultFilterTests, E2EServerTests, E2EURLProtocol, Fixture, State, Bool, Data, Int (+4 more)

### Community 316 - "README.md"
Cohesion: 0.50
Nodes (3): Account, sync e prove senza toccare il cloud, Bucktrail per Android, Prova S-51b su Supabase reale

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
Cohesion: 0.23
Nodes (17): Text, Bundle, QuickAddActivity, QuickAddCard(), AuthActions, AuthButton(), AuthErrorText(), AuthField() (+9 more)

### Community 323 - "Proposte in ordine"
Cohesion: 0.11
Nodes (18): Calendario social Bucktrail, Consegna prima serie, Consegna seconda serie, Gate · dom 06/12, Già pubblicati, Mappa di copertura, Orari di partenza · Europe/Rome, Post-10 · Sequenza approvata (+10 more)

### Community 324 - "Decimal"
Cohesion: 0.25
Nodes (8): 3.1 Primitive (decisioni), 3.2 Gerarchia delle chiavi, 3.3 Formato dell'involucro (identico per payload e chiavi avvolte), 3.4 AAD (dati associati, in UTF-8, tutto minuscolo), 3.5 Contenuto in chiaro del payload, 3.6 Riga `mt_e2e` (una per utente), 3.7 Vettori di test condivisi, 3. Crittografia

### Community 325 - "Direttive social Bucktrail"
Cohesion: 0.25
Nodes (8): Calendario, approvazione e consegna, Comunicazione sul lancio, Direttive social Bucktrail, Grafica e controllo prima della consegna, Prima di preparare ogni nuovo post, Regole dal 25/11/2026 (prevalgono su tutto quanto segue), Stile v2 (dal 23/11/2026, Post-5 in poi), Tre rubriche

### Community 326 - ".rule"
Cohesion: 0.13
Nodes (15): IDRow, PlainRemote, KeyPath, Row, Set, SupabaseClient, UUID, GoldenURLProtocol (+7 more)

### Community 327 - "AddAccountView"
Cohesion: 0.27
Nodes (8): CategoryTint, AccountRow, AccountsView, AddAccountView, Account, AccountType, Bool, String

### Community 328 - "11. Piano di lavoro"
Cohesion: 0.29
Nodes (7): 11.1 Regole comuni (R1–R12) — fanno parte di ogni prompt, 11.2 Ordine e dipendenze, 11.4 Passi di Matteo (3 in tutto, istruzioni complete AGENTS §6.13), 11. Piano di lavoro, S-60r · [?] Matteo · Banco di prova tecnico + prova guidata in sandbox (dopo S-60m, ~40 minuti, una sola seduta), S-60t · [?] Matteo · Verifiche commerciali e legali (si può fare SUBITO, in parallelo; ~30 minuti + attese), S-60u · [?] Matteo · Produzione e dichiarazioni (dopo S-60q, S-60s, S-60t; ~30 minuti)

### Community 329 - "ShareSheet"
Cohesion: 0.14
Nodes (13): Int64, E2EMigrator, Bool, Data, E2EKeyStore, E2EMigrationMarker, Int, Snapshot (+5 more)

### Community 330 - "AccountBalanceCache"
Cohesion: 0.31
Nodes (8): Fixture, Bool, ModelContainer, Set, SyncService, UserDefaults, UUID, SyncLostTransactionTests

### Community 331 - "SyncStatus"
Cohesion: 0.13
Nodes (16): BalanceTrail, Entry, Any, BigDecimal, Boolean, Instant, List, ZoneId (+8 more)

### Community 332 - "Option"
Cohesion: 0.18
Nodes (11): 6.10 Istruzioni per Matteo — passo S-50q.1, 6.1 Perché una modifica SQL è inevitabile (e perché è sicura), 6.2 Lo script (da incollare UNA volta; rieseguirlo non fa danni), 6.3 Istruzioni per Matteo (AGENTS.md §6.13) — passo S-50n, 6.4 Script di ritorno (SOLO se Matteo lo chiede; cancella i dati cifrati di chi ha attivato la protezione), 6.5 Cosa vede un client vecchio, 6.6 Server finto (`03_CODICE/bucktrail-android/scripts/fake-supabase.py`) — estensioni richieste, 6.7 S-50q · Guardia atomica sul vault (secondo script, dopo il §6.2) (+3 more)

### Community 333 - ".centsSurviveSwiftDataAndDTOJSON"
Cohesion: 0.15
Nodes (8): AuthManager, Boolean, StateFlow, String, T, AuthManagerTest, Long, MemorySessionStore

### Community 334 - "7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)"
Cohesion: 0.12
Nodes (14): Criteria, BigDecimal, Boolean, Int, List, String, T, ZoneId (+6 more)

### Community 335 - "FormatterCache"
Cohesion: 0.15
Nodes (8): AppPrefs, K, Boolean, Flow, Int, List, String, PrefsState

### Community 336 - "HttpSupabaseApiTest"
Cohesion: 0.08
Nodes (12): HttpSupabaseApiGoldenTest, Int, String, LoopbackServer, Request, HttpSupabaseApiTest, Int, ServerSocket (+4 more)

### Community 337 - "Row"
Cohesion: 0.40
Nodes (4): Row, Decoder, Encoder, UUID

### Community 338 - "FakeLocalStore"
Cohesion: 0.13
Nodes (10): Snapshot, Int, SyncEngineTest, account(), FakeLocalStore, tx(), Int, JsonObject (+2 more)

### Community 339 - "Statistics"
Cohesion: 0.25
Nodes (10): CategoryStat, BigDecimal, Int, List, Map, YearMonth, ZoneId, MonthStat (+2 more)

### Community 340 - "NotificationScheduler"
Cohesion: 0.11
Nodes (21): BootReceiver, Kind, Boolean, Collection, Context, Instant, Int, java (+13 more)

### Community 341 - "RecurrenceEditorSheet"
Cohesion: 0.22
Nodes (22): SectionLabel(), ActionRow(), frequencyLabel(), android, androidx, com, KeyboardType, List (+14 more)

### Community 342 - "RecurringRuleEntity"
Cohesion: 0.27
Nodes (4): kotlinx, List, String, ScriptedApi

### Community 343 - "AuthManager.kt"
Cohesion: 0.21
Nodes (4): BucktrailApplication, Boolean, String, Application

### Community 344 - "NotificationRules"
Cohesion: 0.10
Nodes (28): AuthGateway, Decoded, DeletionGuard, Done, Failed, Boolean, Collection, Int (+20 more)

### Community 345 - "QuickAdd.kt"
Cohesion: 0.22
Nodes (12): Add, Balance, BalanceLine, BalanceSummary, Draft, Home, Kind, List (+4 more)

### Community 346 - "Snapshot"
Cohesion: 0.32
Nodes (8): E2EGate, E2EMigrationMarker, Resolution, Bool, E2EKeyStore, Phase, UUID, Void

### Community 347 - "categoryLabel"
Cohesion: 0.47
Nodes (3): SignUpView, Bool, String

### Community 348 - "Content"
Cohesion: 0.14
Nodes (12): FakeSupabase, Boolean, Collection, Int, JsonObject, List, Long, Map (+4 more)

### Community 349 - "10. Piano di prova"
Cohesion: 0.33
Nodes (6): 10.1 Principi, 10.2 Strumenti, 10.3 Test, 10.4 Sandbox vera e banca vera (mai senza Matteo), 10.5 Comandi, 10. Piano di prova

### Community 350 - "RecurringMaterializerTests"
Cohesion: 0.21
Nodes (11): E2ELifecycleTests, LifecycleFixture, Bool, E2EMigrator, Int, ModelContainer, String, SyncService (+3 more)

### Community 351 - "12. Rischi, costi, decisioni"
Cohesion: 0.33
Nodes (6): 12.1 Rischi residui, 12.2 Costi, 12.3 Decisioni (riportate in `.cantiere/DECISIONI.md`), 12.4 Stima, 12.5 Cosa NON fare, 12. Rischi, costi, decisioni

### Community 352 - "Budgeting"
Cohesion: 0.14
Nodes (11): BudgetAlert, BigDecimal, Boolean, Instant, Int, List, String, YearMonth (+3 more)

### Community 353 - "QuickAddTest"
Cohesion: 0.16
Nodes (4): Boolean, Long, String, QuickAddTest

### Community 354 - ".rule"
Cohesion: 0.18
Nodes (11): Device, E2EDeadVaultKeyTests, Bool, E2EMigrationMarker, E2EMigrator, InMemoryRemote, ModelContainer, SyncService (+3 more)

### Community 356 - "String"
Cohesion: 0.33
Nodes (8): Failed, Invalid, Boolean, Context, String, Outcome, QuickAddOps, Saved

### Community 357 - "StatisticsScreen"
Cohesion: 0.19
Nodes (12): SyncTable, accounts, budgets, goals, recurringRules, transactions, InMemoryRemote, Bool (+4 more)

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
Cohesion: 0.13
Nodes (10): toData(), AccountType, BigDecimal, TransactionData, List, String, ZoneId, RecurringSeries (+2 more)

### Community 362 - "SupabaseManager"
Cohesion: 0.26
Nodes (12): Equatable, BalanceTrail, Entry, Point, Bool, Date, Int, MaterializationError (+4 more)

### Community 363 - "4. Schermata per schermata"
Cohesion: 0.12
Nodes (16): 4.0 Struttura app e navigazione (`ContentView`, `MoneyTrackerApp`), 4.10 Auth (`Auth/LoginView.swift`, `SignUpView.swift`), 4.11 Audit log (`V/AuditLogView.swift`), 4.12 Modalità demo e dati demo (`Debug/DemoDataSeeder.swift`), 4.13 Notifiche e permessi — vedi §5.5. Banner sync/demo — vedi §1.4., 4.1 Home (`V/DashboardView.swift`), 4.2 Movimenti (`V/TransactionsView.swift` + `TransactionsTypeChips/SecondaryChips/SearchField/AdvancedFilterSheet`), 4.3 Aggiungi / modifica movimento (`V/AddTransactionView.swift`) (+8 more)

### Community 364 - "AccountEditing"
Cohesion: 0.24
Nodes (10): AccountEditing, Adjust, BalanceChange, BigDecimal, Boolean, List, String, T (+2 more)

### Community 365 - "7. Interfaccia"
Cohesion: 0.33
Nodes (6): 7.1 Dove (design «Sentiero», stessi componenti delle righe vicine), 7.2 Schermate e flusso passo passo, 7.3 Stati (ogni stato ha una schermata o una riga; nessun dialogo bloccante), 7.4 Testi (chiavi `bank_*` identiche su iOS e Android, come `e2e_*` di S-50; in iOS anche in `it.lproj`), 7.5 Verifica visiva senza l'ok di Matteo (libertà data da Matteo), 7. Interfaccia

### Community 366 - "TransactionEntity"
Cohesion: 0.33
Nodes (6): 8.1 Modello di minaccia, 8.2 Cosa si conserva e per quanto, 8.3 Cancellazione, 8.4 Testi per il sito (da inserire in S-60v; l'approvazione dei testi del sito resta di Matteo, AGENTS §6.6), 8.5 Store, 8. Sicurezza e privacy

### Community 367 - ".build"
Cohesion: 0.21
Nodes (9): CsvExport, Any, Int, List, Map, String, ZoneId, Labels (+1 more)

### Community 368 - "9. Setup e Installazione"
Cohesion: 0.27
Nodes (7): MigrationStage, Double, decimalFromLegacyDouble(), DecimalMigrationBuffer, MoneyTrackerMigrationPlan, UUID, SchemaMigrationPlan

### Community 369 - "HomeScreen"
Cohesion: 0.27
Nodes (6): GenerationGuardedRemote, Row, Set, UUID, Void, ids

### Community 370 - ".ledger"
Cohesion: 0.10
Nodes (23): E2EActivationFlow, E2EPhrase, E2EPhraseFields, Mode, activate, change, Screen, done (+15 more)

### Community 371 - "SchemaMigration.swift"
Cohesion: 0.09
Nodes (27): CategoryStat, Charts, Identifiable, App Icon (Dark Mode, 1024x1024), App Icon (Light Mode, 1024x1024), App Icon (Tinted, 1024x1024), PlanningBudgetCard, PlanningGoalCard (+19 more)

### Community 372 - "MoneyTrackerApp.swift"
Cohesion: 0.18
Nodes (11): CodingKeys, kdf, kdfIterations, keyId, salt, state, updatedAt, userId (+3 more)

### Community 373 - "ScriptedApi"
Cohesion: 0.11
Nodes (18): Step, a0, a1, a2, a3, a4, a5, a6 (+10 more)

### Community 374 - "PianificaView"
Cohesion: 0.19
Nodes (9): PianificaView, Bool, Budget, Goal, Int, LocalizedStringKey, PersistentIdentifier, String (+1 more)

### Community 376 - "H"
Cohesion: 0.09
Nodes (20): e2e_error(), e2e_state(), eq_filter(), FakeServer, H, same_generation(), session(), timestamp() (+12 more)

### Community 377 - "6. Coerenza con S-50"
Cohesion: 0.40
Nodes (5): 6.1 Decisione, 6.2 Dove stanno i segreti e cosa vede chi, 6.3 Più dispositivi con Protezione avanzata, 6.4 Cosa si promette (e cosa no), 6. Coerenza con S-50

### Community 378 - "HomeAccountOrder"
Cohesion: 0.36
Nodes (5): HomeAccountOrder, Int, List, String, State

### Community 379 - "SessionStore"
Cohesion: 0.11
Nodes (9): SessionStore, KeystoreSessionStore, SecretKey, ErrorKind, fromJson(), Long, Response, Session (+1 more)

### Community 380 - "StatisticsTest"
Cohesion: 0.18
Nodes (3): Boolean, String, StatisticsTest

### Community 381 - "3. Logica di dominio da portare identica"
Cohesion: 0.18
Nodes (11): 3.10 Ordinamenti, 3.1 Importi e valuta (`Formatting/`), 3.2 Saldo (`AccountBalanceCache`), 3.3 «Saldo atteso» e curva (BalanceTrail, `D/BalanceTrail.swift`) — competenza mensile S-41, 3.4 Ricorrenze (serie virtuali, D-008/D-009) — `D/RecurrenceCalculator.swift`, `RecurringMaterializer`, `RecurringSeriesEditor`, 3.5 Budget (`PianificaView`, notifiche), 3.6 Obiettivi, 3.7 Trasferimenti (+3 more)

### Community 382 - "11. Rischi e decisioni"
Cohesion: 0.40
Nodes (5): 11.1 Rischi residui, 11.2 Decisioni (riportate in `.cantiere/DECISIONI.md`), 11.3 Stima di tempo e quota, 11.4 Cosa NON fare, 11. Rischi e decisioni

### Community 383 - "Theme.kt"
Cohesion: 0.22
Nodes (8): auditItems(), DemoData, List, AuditDiff, Event, Item, Collection, List

### Community 384 - "5. Interfaccia"
Cohesion: 0.40
Nodes (5): 5.1 Dove e come (design «Sentiero»), 5.2 Schermate, 5.3 Testi (chiavi e 7 lingue), 5.4 D-014 (prima il mockup), 5. Interfaccia

### Community 385 - "SupabaseManager"
Cohesion: 0.50
Nodes (4): 8.1 Interruttore, 8.2 Percorsi esistenti toccati e come restano identici a interruttore spento, 8.3 File nuovi, 8. Compatibilità

### Community 386 - ".rule"
Cohesion: 0.38
Nodes (3): RecurringRuleSyncTests, Date, ModelContainer

### Community 387 - "10. Piano di lavoro"
Cohesion: 0.33
Nodes (7): RecurringSeries, RecurringSeriesDetector, Bool, Date, Int, String, Transaction

### Community 388 - "1. Visione e Posizionamento"
Cohesion: 0.22
Nodes (10): Result, Boolean, JsonObject, Map, String, UUID, Occurrence, occurrenceId() (+2 more)

### Community 389 - "SfIcons"
Cohesion: 0.28
Nodes (6): Float, ImageVector, Map, Set, String, SfIcons

### Community 392 - "SyncStatus"
Cohesion: 0.36
Nodes (4): E2EProtectionRemovedUiTest, Boolean, Long, String

### Community 393 - "FontRegistrationTests.swift"
Cohesion: 0.17
Nodes (10): CATEGORIE, dirLh, lh, OUT, perTipo, principali, r, raggruppati (+2 more)

### Community 394 - ".suggest"
Cohesion: 0.36
Nodes (5): List, Set, String, LastUsedCategory, Movement

### Community 395 - "e2e-vectors.py"
Cohesion: 0.27
Nodes (5): Amounts, BigDecimal, Boolean, Long, String

### Community 396 - ".authenticate"
Cohesion: 0.29
Nodes (5): Authenticator, Boolean, Context, FragmentActivity, String

### Community 398 - ".tx"
Cohesion: 0.14
Nodes (19): JSONEncoder, E2EVerifier, Failure, count, duplicateID, fields, Field, bool (+11 more)

### Community 399 - "TrailView"
Cohesion: 0.25
Nodes (6): CGSize, GraphicsContext, BalanceTrail, CGFloat, Date, TrailView

### Community 400 - "Calendario social Bucktrail · v2 (23/11/2026)"
Cohesion: 0.27
Nodes (3): E2EVectorsInstrumentedTest, Failure, String

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

### Community 409 - "DaysRemainingPluralTests.swift"
Cohesion: 0.22
Nodes (9): AuditClears, Fixture, Bool, ModelContainer, String, SyncService, UserDefaults, UUID (+1 more)

### Community 410 - "Type.kt"
Cohesion: 0.29
Nodes (8): toSnapshot(), Instant, Int, List, LocalDate, Long, RecurrenceCalculator, RuleSnapshot

### Community 412 - "1. Token grafici"
Cohesion: 0.33
Nodes (6): 1.1 Colori (hex, light / dark) — `V/Theme.swift` `DS`, 1.2 Tipografia, 1.3 Spaziature e misure (`DS.Space`, `DS.Layout`), 1.4 Componenti riutilizzabili (Compose), 1.5 Icone (SF Symbols → Android), 1. Token grafici

### Community 413 - "Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)"
Cohesion: 0.33
Nodes (5): Compito B11, Differenze residue (decise o di piattaforma), Esito per schermata, Secondo giro (2026-11-23, sera): flussi che erano scoperti, Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)

### Community 414 - "Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet)"
Cohesion: 0.33
Nodes (5): Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet), Difetti piccoli, Esito, S-36 — rami vecchi (nessuna cancellazione; proposta), Suggerimenti

### Community 415 - "RecurrenceCalculator"
Cohesion: 0.21
Nodes (8): CategoryTint, amber, blue, green, violet, String, UInt32, CategoryTintTests

### Community 416 - "RecurringSeriesEditor"
Cohesion: 0.28
Nodes (7): Calendar, BalanceTrailTests, BalanceTrail, Bool, Calendar, Date, Int

### Community 417 - ".rule"
Cohesion: 0.09
Nodes (35): Unit, rememberNotificationPermission(), BucktrailApp(), Boolean, LocalDate, ZoneId, Refreshable(), TransactionEditor() (+27 more)

### Community 419 - "ExportsTest"
Cohesion: 0.24
Nodes (7): AddTransferView, Account, Binding, Bool, Date, String, Transaction

### Community 421 - "7. Checklist funzioni (F-xxx)"
Cohesion: 0.40
Nodes (5): 7. Checklist funzioni (F-xxx), Auth, sync, piattaforma, Dati e dominio, Fondamenta e design, Schermate

### Community 422 - "Stress test Android Bucktrail (2026-11-23)"
Cohesion: 0.40
Nodes (4): Esiti e correzioni, Non completato / rischi residui, Scenari superati senza difetti, Stress test Android Bucktrail (2026-11-23)

### Community 425 - "Sendable"
Cohesion: 0.35
Nodes (6): ProjectionMonthTests, Bool, Calendar, Date, Int, Transaction

### Community 426 - "CategoryEntity"
Cohesion: 0.31
Nodes (5): AuthField, LoginView, Bool, String, UIKeyboardType

### Community 430 - "RecurringOps.kt"
Cohesion: 0.25
Nodes (7): Balance, BigDecimal, List, AccountData, BalanceTest, Boolean, String

### Community 431 - "Error"
Cohesion: 0.20
Nodes (10): CodingKey, CodingKeys, dek, userId, CodingKeys, amount, createdAt, id (+2 more)

### Community 433 - "Mode"
Cohesion: 0.33
Nodes (6): RecurrenceCalculator, Calendar, Date, DateInterval, Int, TimeZone

### Community 435 - "AuditLogger"
Cohesion: 0.50
Nodes (4): Scope, all, following, onlyThis

### Community 436 - "TxFilter"
Cohesion: 0.13
Nodes (13): Duration, vault, VaultJSON, E2EUITestHarness, MemoryRemote, Bool, Data, E2EController (+5 more)

### Community 438 - "RecoveryKey"
Cohesion: 0.29
Nodes (9): Action, Delete, Edit, EditorException, Problem, Scope, SkipMonth, Terminate (+1 more)

### Community 439 - "ApiException"
Cohesion: 0.25
Nodes (8): E2EMigratorCleanupTests, Fixture, E2EMigrationMarker, E2EMigrator, E2EVerifier, ModelContainer, UserDefaults, Void

### Community 440 - "esporta.py"
Cohesion: 0.12
Nodes (40): Row, AppData, budgetColor(), MonthBar(), Modifier, PageHeader(), BudgetCard(), BudgetContent() (+32 more)

### Community 441 - "FilterChip"
Cohesion: 0.50
Nodes (4): Phase, resetting, rollingBack, verified

### Community 442 - "MovementRow"
Cohesion: 0.64
Nodes (3): JSONDecoder, E2ERowInteropTests, Data

### Community 443 - "TransactionsSecondaryChips"
Cohesion: 0.30
Nodes (8): Boolean, Collection, Int, Long, Map, String, SyncBaseline, SharedPrefsSyncState

### Community 444 - "ProgrammedRuleCard"
Cohesion: 0.12
Nodes (15): E2EMigrator, Operation, cancelEnable, changePhrase, disable, enable, restart, resume (+7 more)

### Community 445 - "RecurringSeriesDetailView"
Cohesion: 0.17
Nodes (7): CheckedContinuation, RacingServer, Bool, InMemoryRemote, Never, UUID, Void

### Community 446 - "Date"
Cohesion: 0.32
Nodes (6): ProgrammedRuleCard, Calendar, Date, Occurrence, Void, VirtualOccurrenceRow

### Community 447 - ".format"
Cohesion: 0.13
Nodes (11): E2EServerLookup, absent, row, unavailable, VaultRecord, Remote, Bool, Row (+3 more)

### Community 448 - "Fixture"
Cohesion: 0.34
Nodes (10): Account, Budget, Goal, Bool, Budget, Date, Int, String (+2 more)

### Community 449 - "Type.kt"
Cohesion: 0.53
Nodes (3): RecoveryKey, Data, String

### Community 450 - ".plan"
Cohesion: 0.53
Nodes (3): DemoSeeder, Instant, ZoneId

### Community 451 - "AuditLogView"
Cohesion: 0.06
Nodes (26): Font, HeroCard, HomeHeroCard, BalanceTrail, Date, ProgressBar, RecurringSeriesDetailView, RecurringSeries (+18 more)

### Community 452 - ".tx"
Cohesion: 0.33
Nodes (4): InMemoryRemote, Bool, String, UUID

### Community 453 - ".resolve"
Cohesion: 0.07
Nodes (28): App, LocalizedError, Action, delete, edit, skipMonth, terminate, EditorError (+20 more)

### Community 454 - "4. Modelli Dati"
Cohesion: 0.29
Nodes (7): 4. Modelli Dati, Account, Budget, Category, FormatterCache (performance), Goal (Obiettivo di risparmio), Transaction

### Community 455 - "CodingKeys"
Cohesion: 0.47
Nodes (5): Selection, String, resolve(), Option, SegmentedPill

### Community 456 - ".forceReset"
Cohesion: 0.27
Nodes (5): AddGoalView, GoalRow, Date, Goal, String

### Community 457 - ".build"
Cohesion: 0.33
Nodes (9): Activating, Disabling, Locked, Off, On, Protection, Reason, Status (+1 more)

### Community 458 - ".loginAndBothPushAndPullUseOnlyOriginalPlainCalls"
Cohesion: 0.40
Nodes (3): ISO8601DateFormatter, Bool, StrictRecurrenceAmountTests

### Community 459 - "Selection"
Cohesion: 0.11
Nodes (24): Logger, continueWithoutE2EProtection(), E2EOperation, foreground, login, pull, push, refresh (+16 more)

### Community 460 - ".dateFormatter"
Cohesion: 0.34
Nodes (5): RuleState, Instant, Int, String, RecurringMaterializerTest

### Community 461 - ".dateFormatter"
Cohesion: 0.33
Nodes (4): Dim, Fonts, Int, Typo

### Community 462 - "SyncEngine.kt"
Cohesion: 0.25
Nodes (8): Failure, authenticationRequired, concurrentActivation, invalidPassphrase, recoveryNotConfirmed, stateChanged, unavailable, verificationFailed

### Community 463 - "SupabaseConfig.swift"
Cohesion: 0.67
Nodes (3): Failure, invalidEntry, OSStatus

### Community 464 - "CodingKeys"
Cohesion: 0.20
Nodes (8): IgnoredIds, Boolean, Int, Set, String, SyncMerge, SyncPlan, Snapshot

### Community 465 - "categoryLabel"
Cohesion: 0.14
Nodes (26): CategoryEntity, BarAction(), BtAlert(), DialogStatusBarEffect(), androidx, Boolean, Float, Long (+18 more)

### Community 468 - "AdvancedFilterSheet"
Cohesion: 0.25
Nodes (8): Plan, Bool, Self, Set, String, UserDefaults, UUID, SyncBaseline

### Community 469 - ".movement"
Cohesion: 0.31
Nodes (5): LastUsedCategoryTests, Bool, LastUsedCategory, Set, String

### Community 470 - "Failure"
Cohesion: 0.10
Nodes (7): E2EProtectionRemovedUITests, String, XCUIDevice, TwoDeviceLiveReopenUITests, CategoryFlowUITests, XCTest, XCTestCase

### Community 472 - ".saveTransaction"
Cohesion: 0.40
Nodes (4): Collaudo c0ca6b8 (S-51f, S-51b): ok, entrambi [x], CONSEGNA — 2026-11-27 13:00 · collaudatore (Claude Code · Sonnet), File locali, Prossimo

### Community 473 - "FilterChip"
Cohesion: 0.27
Nodes (5): SupabaseManager, Bool, String, SupabaseClient, UUID

### Community 474 - "MovementRow"
Cohesion: 0.33
Nodes (6): LastUsedCategory, Movement, Bool, Date, Set, String

### Community 475 - "FormatterCache"
Cohesion: 0.40
Nodes (7): Occurrence, RecurrenceException, RecurrenceExceptionCodec, RuleSnapshot, Bool, String, UUID

### Community 476 - "TransactionsAdvancedFilterSheet"
Cohesion: 0.60
Nodes (5): SchemaV1, SchemaV2, SchemaV3, PersistentModel, VersionedSchema

### Community 477 - "CodingKeys"
Cohesion: 0.06
Nodes (50): b64url(), check_nonce_calls(), crockford_format(), crockford_parse(), envelope_bytes(), hkdf(), main(), pbkdf2() (+42 more)

### Community 478 - "Scope"
Cohesion: 0.11
Nodes (18): AccountEntity, BudgetEntity, GoalEntity, TransactionEntity, JsonExport, Instant, List, Long (+10 more)

### Community 480 - "E2EOperation"
Cohesion: 0.40
Nodes (5): Failure, authenticationFailed, malformed, operationFailed, unsupportedVersion

### Community 481 - "SyncStatus"
Cohesion: 0.25
Nodes (8): CodingKeys, activationGeneration, direction, generation, keyId, phase, startedAt, userId

### Community 482 - "ExportsTest"
Cohesion: 0.33
Nodes (6): Kind, expense, income, transfer, MovementRow, String

### Community 483 - "MoneyTrackerApp.swift"
Cohesion: 0.40
Nodes (5): 1. Visione e Posizionamento, Differenziatori chiave, L'idea centrale, Modello di business, Posizionamento in una frase

### Community 484 - "RecurringSeriesDetailView"
Cohesion: 0.40
Nodes (5): Failure, mismatchedID, wrongKey, wrongKind, wrongUser

### Community 488 - "E2EMigratorGenerationTests.swift"
Cohesion: 0.33
Nodes (6): 5. Design System (Theme.swift), App Icon (Assets.xcassets/AppIcon.appiconset), Componenti riutilizzabili, Modalità chiara e scura, Palette colori — «Sentiero», Spacing

### Community 491 - "ObsoleteVaultFilterTest"
Cohesion: 0.22
Nodes (8): 1. Causa, 2. Scelta: merge a tre vie sugli ID con «base» persistita per tabella, 3. Alternative scartate, 4. Fuori ambito (rischi residui, da tracciare), 5. Test di regressione, 6. Decisione da registrare (la scrive Codex in `.cantiere/DECISIONI.md`), 7. Prompt per Codex (una sessione), Progetto S-51d — cancellazioni nella sync (iOS + Android)

### Community 492 - "FontRegistrationTests"
Cohesion: 0.36
Nodes (5): Boolean, Set, String, Plan, SyncBaseline

### Community 494 - "HapticStyle"
Cohesion: 0.33
Nodes (6): HapticStyle, light, medium, rigid, soft, success

### Community 497 - ".testLiveSync"
Cohesion: 0.53
Nodes (4): ProbeFailure, Bool, String, TwoDeviceLiveSyncTests

### Community 499 - "1. Modello di minaccia"
Cohesion: 0.50
Nodes (4): 1.1 Cosa protegge, 1.2 Da chi, 1.3 Cosa NON protegge (va detto all'utente e sul sito), 1. Modello di minaccia

### Community 504 - ".plan"
Cohesion: 0.33
Nodes (5): Instant, List, RecurrenceCalculator, Plan, RecurringMaterializer

### Community 507 - "MoneyTrackerApp.swift"
Cohesion: 0.07
Nodes (17): AnyObject, FileProtectionType, DemoDataSeeder, RecurringMaterializer, Date, Int, RecurrenceCalculator, TimeZone (+9 more)

### Community 508 - "InMemoryRemote.swift"
Cohesion: 0.50
Nodes (4): Failure, duplicateState, injected, wrongRowType

### Community 510 - "UploadMode"
Cohesion: 0.40
Nodes (5): UploadMode, incremental, migrationCopy, migrationPreflight, migrationReconcile

## Knowledge Gaps
- **998 isolated node(s):** `backup.sh script`, `esegui.sh script`, `CHROME_PATH`, `require`, `AXE` (+993 more)
  These have ≤1 connection - possible missing edges or undocumented components.
- **211 thin communities (<3 nodes) omitted from report** — run `graphify query` to explore isolated nodes.

## Suggested Questions
_Questions this graph is uniquely positioned to answer:_

- **Why does `Text` connect `ModelConfiguration` to `ShareSheet`, `.rule`, `Sync/ricorrenze — file sorgente del checkpoint settembre 2026`, `Community 67`, `CategoryManagementView & AddTransactionView`, `AuditLogView`, `CodingKeys`, `Community 106`, `Community 11`, `Community 10`, `.build`, `categoryLabel`, `RecurrenceEditorSheet`, `esporta.py`, `Color`, `FontRegistrationTests`?**
  _High betweenness centrality (0.115) - this node is a cross-community bridge._
- **Why does `Double` connect `9. Setup e Installazione` to `CategoryManagementView & AddTransactionView`, `10. Piano di lavoro`, `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)`, `Community 9`, `e2e-vectors.py`, `esporta.py`, `Color`, `Community 63`, `Fixture`, `AuditLogView`, `Community 69`, `ShareSheet`, `Selection`, `.dao`, `.movement`, `QuickAdd.kt`, `String`, `Community 107`, `Community 108`, `SchemaMigration.swift`, `PianificaView`?**
  _High betweenness centrality (0.114) - this node is a cross-community bridge._
- **Why does `Decimal` connect `AppIntents — Tocco posteriore/Siri (AddExpenseIntent)` to `CategoryManagementView & AddTransactionView`, `Ricorrenze — motore backfill & Intents dirty-tracking`, `.rule`, `10. Piano di lavoro`, `Community 10`, `.tx`, `RecurrenceEditorView`, `RecurringSeriesEditor`, `RecurrenceCalculator`, `Community 48`, `Mode`, `README.md`, `MovementRow`, `.invalidateAll`, `AccountType`, `AddAccountView`, `.loginAndBothPushAndPullUseOnlyOriginalPlainCalls`, `.dao`, `AuditLogView`, `FormatterCache`, `CodingKeys`, `Option`, `SupabaseManager`, `9. Setup e Installazione`, `.testLiveSync`, `SchemaMigration.swift`, `PianificaView`, `MoneyTrackerApp.swift`, `Community 126`?**
  _High betweenness centrality (0.098) - this node is a cross-community bridge._
- **Are the 38 inferred relationships involving `Decimal` (e.g. with `.seed()` and `.perform()`) actually correct?**
  _`Decimal` has 38 INFERRED edges - model-reasoned connections that need verification._
- **Are the 86 inferred relationships involving `Text` (e.g. with `.pageHeaderStacksTitleAndActionsAtLargeFont()` and `LockOverlay()`) actually correct?**
  _`Text` has 86 INFERRED edges - model-reasoned connections that need verification._
- **Are the 31 inferred relationships involving `ModelContext` (e.g. with `.userChangeRemovesBothKindsOfMovementBeforeSync()` and `.init()`) actually correct?**
  _`ModelContext` has 31 INFERRED edges - model-reasoned connections that need verification._
- **What connects `backup.sh script`, `Cartella servita come "/" del sito: quella con index.html più vicina alla radice`, `(lingua dalla cartella, percorso senza cartella della lingua).` to the rest of the system?**
  _1036 weakly-connected nodes found - possible documentation gaps or missing edges._