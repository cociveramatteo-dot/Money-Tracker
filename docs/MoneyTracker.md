# MoneyTracker — Documento Completo

*App iOS finanza personale per il mercato italiano · Aggiornato: novembre 2026 · Versione 3.30*

> **Nome visualizzato:** l'app compare sotto l'icona come **"Bucktrail"** (`INFOPLIST_KEY_CFBundleDisplayName`). Il nome tecnico del progetto — cartella, target Xcode, bundle identifier (`com.matteo.moneytracker.MoneyTracker`) — resta `MoneyTracker` e non cambia: questo documento e il codice continuano a riferirsi al progetto con quel nome.

---

## 1. Visione e Posizionamento

### L'idea centrale

Una singola app, pagamento una tantum, che sostituisce carta e penna, fogli Excel, quattro app diverse, il commercialista per le cose semplici, e la testa piena di conti da fare. Apri l'app e sai esattamente dove sei, dove stai andando, e cosa puoi permetterti adesso.

### Posizionamento in una frase

*"L'unica app italiana che conosce le tue banche, capisce le tue abitudini, e ti dice esattamente cosa puoi permetterti — adesso."*

### Differenziatori chiave

- **Italiana di design e cultura**: non una traduzione di un'app americana. Pensata per conti italiani, banche italiane, fisco italiano.
- **Completamente offline**: zero dipendenza da server, zero rischio di shutdown.
- **Una tantum**: in un mercato dominato da abbonamenti, il pagamento unico è un messaggio di fiducia.
- **Privacy radicale**: nessun dato condiviso, nessuna pubblicità, nessun tracking.
- **Design minimale**: funziona anche per chi non ha mai usato un'app di finanza.

### Modello di business

**Attuale:** distribuzione TestFlight con Apple ID personale (certificato 7 giorni).

**Al lancio App Store:** acquisto una tantum **€4,99** — accesso completo, nessun abbonamento, nessuna pubblicità.

**Futuro (monetizzazione aggiuntiva):** Piano Premium opzionale €1,99/mese per connessione bancaria automatica, AI Financial Coach, sync Supabase cross-device, Modalità Coppia/Famiglia.

---

## 2. Stack Tecnico e Architettura

| Componente | Tecnologia |
|---|---|
| Linguaggio | Swift 6.0 (strict concurrency) |
| UI Framework | SwiftUI |
| Persistenza | SwiftData (`@Model`, `ModelContext`, `FetchDescriptor`) |
| Concorrenza | Swift 6 `@MainActor`, structured concurrency con `Task` |
| Notifiche | UserNotifications (`UNCalendarNotificationTrigger`, `UNTimeIntervalNotificationTrigger`) |
| Shortcuts/Siri | AppIntents framework (`AppIntent`, `AppShortcutsProvider`) |
| Logging | OSLog (`Logger.persistence`, `.recurring`, `.classifier`) |
| Sicurezza DB | `NSFileProtectionComplete` su SQLite WAL/SHM |
| Cloud Sync | Supabase (SDK integrato, in sviluppo) |
| iOS target | iOS 17+ |
| Android | Kotlin, Jetpack Compose, Room v3 (`03_CODICE/bucktrail-android`). Parità con iOS sulle schermate B0–B11 |
| Localizzazione | 7 lingue (IT, EN, ES, FR, DE, ZH-Hans, JA) |
| Architettura | MVVM implicita, computed properties SwiftUI-native |
| Xcode project | `PBXFileSystemSynchronizedRootGroup` (auto-scan cartelle) |

### Pattern architetturali

- **Singleton:** `NotificationManager.shared`, `FormatterCache` (entrambi `@MainActor`)
- **NSCache:** `CategoryClassifier.resultCache` per risultati di classificazione
- **Transferable:** `CSVFile` con `DataRepresentation` (nessun file temp su disco)
- **AppStorage:** persistenza preferenze UI (`hideBalance`, `monthlyReportEnabled`, filtri)
- **UserDefaults:** soglie saldo (keyed by account UUID, evita migration SwiftData)

---

## 3. Struttura del Progetto

```
MoneyTracker/                    ← Source principale
├── MoneyTrackerApp.swift        ← Entry point, container SwiftData, seed categorie
├── Auth/
│   ├── AppLockGate.swift        ← Blocco biometrico app
│   ├── BiometricAuthenticating.swift
│   ├── LoginView.swift          ← Login Supabase
│   ├── SignUpView.swift
│   └── SupabaseManager.swift    ← Client Supabase, auth, sync
├── Debug/
│   └── DemoDataSeeder.swift     ← Dati demo per testing
├── Domain/
│   ├── AccountBalanceCache.swift ← Cache saldi calcolati
│   ├── AuditLogger.swift
│   ├── CategoryClassifying.swift ← Protocollo classificazione
│   ├── KeywordCategoryClassifier.swift ← Classificatore keyword on-device
│   ├── NotificationManager.swift ← Notifiche locali budget/saldo
│   ├── NotificationScheduling.swift
│   ├── RecurrenceCalculator.swift ← Occorrenze virtuali deterministiche (UUIDv5)
│   ├── RecurringMaterializer.swift ← Materializza le occorrenze dovute
│   ├── RecurringSeriesEditor.swift ← Modifica/salta/termina/elimina serie
│   └── RecurringSeriesDetector.swift ← Rilevamento passivo serie
├── Export/
│   └── PDFReportGenerator.swift ← Generazione PDF mensile
├── Formatting/
│   ├── CurrencyFormatting.swift  ← Estensioni Double/Date
│   └── FormatterCache.swift      ← Singleton formatter costosi
├── Intents/
│   └── AddExpenseIntent.swift    ← Apple Shortcuts integration
├── Models/
│   ├── Account.swift
│   ├── Budget.swift
│   ├── Category.swift
│   ├── Goal.swift
│   └── Transaction.swift
├── Persistence/
│   ├── Logging.swift
│   ├── ModelContextSaving.swift
│   └── SchemaMigration.swift
├── Resources/
│   └── CategoryKeywords.json    ← Keywords per classificazione automatica
├── Sync/
│   └── SyncService.swift        ← Sync Supabase (in sviluppo)
├── Views/
│   ├── AccountsView.swift
│   ├── AddTransactionView.swift
│   ├── AddTransferView.swift
│   ├── AuditLogView.swift
│   ├── BudgetView.swift
│   ├── CategoryManagementView.swift
│   ├── Components/              ← Componenti «Sentiero» (HeroCard, MovementRow, TrailView, FloatingTabBar, ...)
│   ├── ContentView.swift        ← Tab bar flottante + FAB
│   ├── DashboardView.swift      ← Home
│   ├── GoalsView.swift
│   ├── PianificaView.swift
│   ├── SettingsView.swift
│   ├── StatisticsView.swift
│   ├── Theme.swift              ← Design system completo
│   └── TransactionsView.swift
├── [*.lproj]                    ← Localizzazioni (it/en/de/fr/es/ja/zh-Hans)
└── Assets.xcassets/
MoneyTrackerTests/               ← Unit test (XCTest)
MoneyTrackerUITests/             ← UI test (XCUITest, simula uso reale)
├── UITestSupport.swift          ← Classe base, helper navigazione/FAB
├── TransactionFlowUITests.swift ← Aggiungi/modifica/elimina movimento
├── AccountFlowUITests.swift     ← Aggiungi/modifica/elimina conto
├── CategoryFlowUITests.swift    ← Aggiungi/modifica/elimina categoria
└── NavigationStressUITests.swift ← Uso intensivo: tab switching, sheet ripetuti
docs/
└── MoneyTracker.pdf             ← Questo documento (unico riferimento)
graphify-out/                    ← Knowledge graph del progetto
```

**Automazione notturna** (fuori dal repo, in `~/Desktop/NightTestApp/`):
uno script (`run_nightly_tests.sh`) lanciato ogni notte alle 4:00 da un
LaunchAgent (`~/Library/LaunchAgents/com.moneytracker.nightlytests.plist`)
esegue gli XCUITest su simulatore; se falliscono, invoca Claude Code headless
per analizzare e correggere il codice, riprova fino a 5 volte, scrive
`report_notturno.md` nella root del progetto e apre una Pull Request con le
correzioni. Vedi sezione 10 per i dettagli del funzionamento.

---

## 4. Modelli Dati

### Account

Rappresenta un conto bancario, carta, portafoglio o investimento.

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | UUID | Identificatore univoco |
| `name` | String | Nome del conto (es. "Carta Unicredit") |
| `type` | String | Tipo: conto corrente, carta, contanti, investimento |
| `initialBalance` | Double | Saldo iniziale inserito dall'utente |
| `isArchived` | Bool | Se archiviato, non appare nelle liste attive |
| `isExcludedFromTotal` | Bool | Se escluso, non concorre al saldo totale in home |
| `colorHex` | String | Colore personalizzato |

**Computed:** `currentBalance` (solo tx `isDone == true`), `futureBalance` (tutte le tx), `plannedDelta` (differenza futuro–attuale).

**Relazioni:** `transactions: [Transaction]` (cascade delete), `budgets: [Budget]` (cascade delete).

### Transaction

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | UUID | Identificatore univoco |
| `name` | String | Descrizione (es. "Affitto", "Stipendio") |
| `amount` | Double | Importo |
| `date` | Date | Data della transazione |
| `type` | String | "expense" o "income" |
| `isFixed` | Bool | Spesa/entrata fissa ricorrente |
| `isDone` | Bool | true = già effettuata, false = pianificata |
| `isTransfer` | Bool | Fa parte di un trasferimento tra conti |
| `transferGroupId` | String | UUID condiviso tra le due gambe di un trasferimento |
| `category` | String | Categoria assegnata |
| `recurringFrequency` | String | Frequenza: vuoto / daily / weekly / monthly / yearly |
| `account` | Account? | Relazione con il conto |

### Budget

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | UUID | Identificatore univoco |
| `category` | String | Categoria a cui si applica |
| `limit` | Double | Limite mensile in valuta |
| `account` | Account? | Opzionale: limita il budget a un conto specifico |

### Goal (Obiettivo di risparmio)

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | UUID | Identificatore univoco |
| `name` | String | Nome obiettivo |
| `emoji` | String | Emoji selezionata dall'utente |
| `targetAmount` | Double | Importo target |
| `currentAmount` | Double | Importo risparmiato finora |
| `hasDeadline` | Bool | Se ha una scadenza |
| `deadline` | Date? | Data scadenza opzionale |

### Category

| Campo | Tipo | Descrizione |
|---|---|---|
| `id` | UUID | Identificatore univoco |
| `name` | String | Nome categoria |
| `iconName` | String | Nome SF Symbol |
| `isDefault` | Bool | Le categorie default non sono eliminabili |

### FormatterCache (performance)

Singleton centralizzato per formatter costosi. Ricrea i formatter solo quando cambia la valuta o la locale — elimina N allocazioni `NumberFormatter`/`DateFormatter` per ogni render di ogni row.

- `currencyFormatter()` — `NumberFormatter` currency riutilizzato
- `monthYear` — `DateFormatter("MMMM yyyy")` singleton
- `dayMonth` — `DateFormatter("d MMM")` singleton
- `shortMonth` — `DateFormatter("MMM")` singleton per grafici

---

## 5. Design System (Theme.swift)

### Palette colori — «Sentiero»

Concetto: **verde, linea piena = già successo; ambra, tratteggiato = pianificato/atteso**. Tutti i colori sono adattivi (`Color(lightHex:darkHex:)`), nessun `preferredColorScheme`.

| Token | Light | Dark | Uso |
|---|---|---|---|
| `DS.ink` | `#121614` | `#F1F3EF` | Testo primario |
| `DS.paper` | `#F3F4EF` | `#0E1210` | Sfondo schermata (bg) |
| `DS.surface` | `#FFFFFF` | `#171C19` | Card, liste, tab bar |
| `DS.smoke` | `#5B635E` | `#9AA39D` | Testo secondario (inkSecondary) |
| `DS.fog` | `#DCDFD8` | `#2A332E` | Bordi, riempimenti neutri |
| `DS.divider` | `#ECEEE9` | `#232A26` | Separatori di riga, track barre |
| `DS.accent` (`positive`) | `#1F7A4D` | `#5FD19B` | Entrate, FAB, progress OK |
| `DS.planned` / `plannedText` | `#B45309` / `#8A4A0C` | `#F2A65A` | Pianificato, soglia 80% (testo < 18 pt: `plannedText`) |
| `DS.danger` (`negative`) | `#B42318` | `#F26B5E` | Budget sforato |
| `DS.transfer` | `#2F6FB0` | `#6FA8E0` | Trasferimenti |
| `DS.hero`, `heroText`, `heroSecondary`, `heroDivider`, `heroAccent`, `heroPlanned` | — | — | Card scura (superficie scura in entrambi i temi) |

Le varianti `*Soft` (`accentSoft`, `plannedSoft`, `dangerSoft`) sono gli sfondi dei badge. Valori dark e scarti dall'handoff: `DECISIONI.md` D-005.

**Tinte categoria** (`CategoryTint`): 4 tinte (verde, ambra, blu, viola) assegnate per nome — mappa fissa per le 14 predefinite, hash FNV-1a del nome per le personalizzate (nessuna modifica al modello). **Tipografia** (`DS.Typo`): Space Grotesk (titoli, importi) e Inter (testo) nel bundle, Dynamic Type via `relativeTo:`, fallback SF Pro, importi con cifre tabulari.

### Spacing

`DS.Space.xs / s / m / l / xl / xxl` — sistema a scala fissa per coerenza visiva.

### Componenti riutilizzabili

Componenti «Sentiero» (`Views/Components/`, ciascuno con `#Preview` light/dark):

| Componente | Descrizione |
|---|---|
| `Card` | Contenitore standard su `DS.surface` con raggio `cardRadius` |
| `HeroCard` | Card scura (token `hero*`, raggio 24): titolo, importo grande, divisore e riga secondaria (es. «Atteso») |
| `HomeHeroCard` | Hero della Home: «Saldo attuale», `TrailView`, «Saldo atteso» e riepilogo pianificati |
| `TrailView` | Il «sentiero»: curva del saldo del mese, tratto pieno verde = reale, tratteggiato ambra = proiezione (nascosta a VoiceOver); i dati arrivano da `Domain/BalanceTrail` |
| `MovementRow` | Riga movimento: icona con tinta categoria, nome (una riga), metadati, importo sempre intero |
| `FilterChip` | Chip di filtro, stile primario o secondario, stato attivo |
| `SegmentedPill` | Selettore a pillola generico |
| `ProgressBar` | Barra di avanzamento; annuncia a VoiceOver il valore reale anche oltre il 100% |
| `BudgetStatus` | Badge testuale di stato budget («Soglia 80%», «Sforato») |
| `PlanningBudgetCard` / `PlanningGoalCard` / `PlanningProgressRing` | Card e anello di Pianifica (budget e obiettivi) |
| `FloatingTabBar` | Tab bar flottante a 5 voci (id `tab_*`); la `TabView` nativa resta sotto con barra nascosta. Il **FAB** (58×58, `DS.accent`) sta in `ContentView` (`fabButton`, `fabMenu_*`) e cambia azione per tab |

Componenti di base in `Theme.swift`, ancora in uso:

| Componente | Descrizione |
|---|---|
| `SectionLabel(text:)` | Intestazione sezione in uppercase con letterspacing |
| `PrimaryButton(title:action:)` | Bottone principale (sheet di inserimento, export CSV) |
| `GhostButton(title:action:)` | Bottone secondario testo-only |
| `ThinDivider()` | Separatore sottile in `DS.fog` |
| `MonthBar` | Selettore mese (Statistiche, Pianifica) con label via `FormatterCache` |
| `UnderlineSegment` | Selettore entrata/uscita nello sheet di inserimento |
| `EmptyStateView(icon:title:subtitle:cta:)` | Empty state coerente con CTA opzionale |
| `FixedTotalTile` | Mini-card «Spese fisse»/«Entrate fisse» della Home |

`HeroAmount` e `DSTransactionRow` sono ancora definiti in `Theme.swift` ma non più usati da nessuna vista (sostituiti da `HeroCard` e `MovementRow`).

### Modalità chiara e scura

Full support Light/Dark mode nativo SwiftUI, senza override manuali.

### App Icon (Assets.xcassets/AppIcon.appiconset)

Grafico a barre crescenti in stile minimale (`DS.ink` su light, `DS.paper`-inverso su dark), con l'ultima barra colorata in oro/ambra come accento — il verde/rosso di `DS.positive`/`DS.negative` resta riservato ai saldi in-app, quindi l'icona usa un colore distinto. Tre varianti richieste da iOS 18+: `AppIcon_light_1024.png`, `AppIcon_dark_1024.png`, `AppIcon_tinted_1024.png` (quest'ultima in scala di grigi, colorata dal sistema quando l'utente sceglie un tema icone personalizzato). Tutti e tre i PNG sono 1024×1024 senza canale alpha (richiesto da Apple).

---

## 6. Funzionalità Implementate

### Home (DashboardView)

- **Header** — data del giorno, wordmark «Bucktrail», pulsanti occhio (nascondi importi) e ingranaggio (Impostazioni)
- **Hero con sentiero** — `HomeHeroCard`: «Saldo attuale» (totale dei conti inclusi) con sotto la `TrailView`, la curva del mese (verde pieno = reale, ambra tratteggiato = proiezione, serie da `Domain/BalanceTrail`, ricalcolata solo al cambio dei dati)
- **Saldo atteso** — appare nella hero solo se ci sono movimenti pianificati: saldo futuro, numero di pianificati e delta. Senza pianificati niente tratto ambra
- **Conti** — carte in scroll orizzontale (nome, saldo, saldo futuro se diverso). Link «Gestisci» porta al tab Conti; il pulsante a cursori apre selezione/ordinamento (`HomeAccountOrderSheet`), ordine persistito via `@AppStorage`
- **Nascondi saldo** — pulsante occhio: hero, carte conti e tile mostrano gli importi oscurati (`•••• ` + simbolo della valuta). Stato persistito via `@AppStorage("hideBalance")`
- **Fissi del mese** — mini-card affiancate "Spese fisse"/"Entrate fisse": somma di tutte le transazioni `isFixed` del mese corrente (pagate o da pagare, `isDone` ignorato). Ciascuna mostrabile/nascondibile indipendentemente da Impostazioni → Home (`@AppStorage("showFixedExpensesTotal")`/`("showFixedIncomeTotal")`); rispetta "Nascondi saldo" (`hideBalance`)
- **Ultimi movimenti** — collassabile, con link «Vedi tutti» verso il tab Movimenti. Ultime 4 transazioni non fisse (`MovementRow`). Swipe sinistra = Elimina, tap o menu contestuale = Modifica
- **Cache della proiezione** — la curva del saldo e la proiezione Home sono in cache e si ricalcolano solo quando cambiano i dati (correzione della Commissione del 2026-11-24)
- Il tema non si sceglie: l'app segue il sistema (chiaro/scuro)

### Movimenti (TransactionsView)

- **Pagina unica** (S-12): titolo, pulsante filtri avanzati (con badge del numero di filtri attivi), impostazioni, ricerca per nome e chip restano fermi; cambia solo la lista sotto
- **Chip tipo:** Tutti · Fisse · Trasf. · Uscite · Entrate (stessa pagina) + **Ricorrenti**, che apre una pagina a sé
- **Zona sotto i chip:** menu **Mese ▾** (questo mese, precedente, successivo, ±6 mesi), menu **Categoria ▾** e, se attivi, chip verde dei filtri avanzati con ✕ per rimuoverli. Filtri combinabili
- **Filtri avanzati** persistiti via `@AppStorage` (importo min/max, periodo personalizzato con le sue date, che sostituisce il filtro mese). Valgono anche per le occorrenze virtuali «Serie programmate» dei mesi futuri (S-38)
- **Lista:** movimenti pianificati in cima nella sezione «In arrivo · pianificati», poi card giornaliere (più recenti in cima) con subtotale del giorno solo visivo (trasferimenti esclusi), righe `MovementRow`
- **Swipe destra:** "Conferma"/"Pianificato" per i movimenti fissi o non ancora effettuati (trasferimenti inclusi); la modifica si apre dal tap sulla riga
- **Swipe sinistra:** Elimina (singola o entrambe le gambe del trasferimento via `transferGroupId`, con conferma)

### Aggiunta Transazione (AddTransactionView)

- Campi: nome (con categorizzazione automatica on-device), importo, tipo (uscita/entrata), categoria, conto, data
- Toggle "Già effettuato" (isDone), Toggle "Spesa fissa" (isFixed)
- Attivando "Spesa fissa" disattiva automaticamente "Già effettuato"
- Categorizzazione automatica: prima la categoria dell’ultimo movimento effettuato con nome esattamente uguale (ignorando maiuscole, accenti e spazi in eccesso), poi keyword matching on-device senza rete. La cronologia esclude pianificati e trasferimenti; l’ordine usa `createdAt` (inserimento, anche per movimenti retrodatati). Se la categoria dell’ultimo movimento è stata eliminata si passa alle parole chiave, senza recuperare scelte precedenti. Nessuna nuova tabella o sync.
- La categoria dalla cronologia è preselezionata e indicata da «Ultima usata»; l’utente può sovrascriverla manualmente e il nuovo movimento salvato guiderà il prossimo inserimento. In modifica il movimento stesso è escluso dalla ricerca.
- Keyboard navigation: importo → nome → `.done` (auto-save)
- Reset form corretto al riutilizzo (load() resetta tutto quando editing == nil)

### Trasferimenti (AddTransferView)

- Seleziona conto "Da" e "A", inserisci importo
- Toggle "Già effettuato" (default: attivo)
- Genera due transazioni collegate con stesso `transferGroupId`
- Bottone dinamico: "Trasferisci" o "Pianifica" in base allo stato

### Conti (AccountsView)

- Lista: prima conti inclusi nel totale, poi esclusi (badge "escluso")
- **Swipe:** destra = Modifica, sinistra = Elimina (con haptic)
- **Context menu** (long press): Modifica / Escludi-Includi / Archivia / Elimina
- **Conti archiviati:** riga tratteggiata «Archiviati» con conteggio, che si apre sulla sezione separata (testi in `DS.smoke` opaco, leggibili: contrasto 5,60:1 chiaro / 7,28:1 scuro). Context menu: Ripristina / Elimina definitivamente
- Hero patrimonio: saldo attuale + futuro dei conti inclusi; conti raggruppati per tipo (raggruppamento solo visivo, totali di gruppo senza gli esclusi)
- Nuovo conto non escluso → aggiunto automaticamente in home
- **Modifica saldo attuale:** il campo mostra e accetta sempre il saldo *reale* (`currentBalance`), non il saldo iniziale interno. Su un conto con transazioni già registrate, digitare un nuovo valore non sovrascrive lo storico: viene creata una transazione di rettifica ("Rettifica saldo", categoria dedicata) per la sola differenza, datata oggi — così il conto riparte esattamente dal numero inserito senza dover registrare le spese/entrate mancanti una per una. Su un conto senza transazioni il valore aggiorna direttamente il saldo iniziale, come prima.

### Pianifica: Budget e Obiettivi (PianificaView)

Il tab Pianifica ha un selettore a pillola Budget / Obiettivi, con hero ad anello e card dedicate (`PlanningBudgetCard`, `PlanningGoalCard`); il pulsante + (44×44) apre gli editor esistenti.

### Budget (BudgetView)

- Budget per categoria con limite mensile in valuta
- Barra di avanzamento con badge testuale di stato (`BudgetStatus`: «Soglia 80%» in ambra, «Sforato» in rosso; soglie lette dalla logica esistente)
- Filtro opzionale per conto specifico
- Storico budget (ultimi mesi) via `BudgetHistorySheet`
- Notifiche locali quando ci si avvicina o supera il limite

### Obiettivi (GoalsView)

- Nome + emoji, importo target, importo attuale, deadline opzionale
- Barra di avanzamento e percentuale completamento
- VoiceOver completo: nome, %, importi, deadline, stato completato

### Statistiche (StatisticsView)

- Header con titolo, pulsante PDF e impostazioni; selettore mese (`MonthBar`)
- Tre tile del mese: Uscite · Entrate · Netto
- **Andamento:** grafico a barre affiancate entrate/uscite per mese (Swift Charts, `BarMark` con `position(by:)`), con scelta **6M / 12M** e «Uscite medie»
- **Per categoria:** elenco delle uscite del mese con percentuale, importo e barra con la tinta della categoria (non c'è più il grafico a torta)
- Confronto con il mese scorso (frecce ▲/▼ e importo), se esiste un mese precedente con spese
- Media mensile degli ultimi 12 mesi (uscite ed entrate)
- Confronto annuale: anno corrente vs anno precedente (uscite ed entrate)
- Esportazione PDF mensile (via `PDFReportGenerator`)
- Esportazione CSV (via `Transferable`, nessun file temp su disco)
- Loading indicator animato durante generazione PDF/CSV

### Impostazioni (SettingsView)

- Cambio valuta (€, $, £, ¥, ecc.) — si aggiorna dinamicamente ovunque via `Double.currencySymbol`
- Lingua: l'app segue la lingua di sistema (7 lingue supportate); una scorciatoia apre le impostazioni iOS dell'app
- Nessuna selezione del tema: l'app segue il sistema chiaro/scuro (mai `preferredColorScheme`)
- Toggle "Report mensile PDF" — notifica locale il 1° di ogni mese alle 10:00
- Avviso saldo basso per conto (persistito in UserDefaults)
- Sezione "Home": toggle indipendenti per mostrare/nascondere le mini-card "Spese fisse mensili"/"Entrate fisse mensili"

### Biometria (Auth/)

- `AppLockGate`: blocco app con Face ID / Touch ID via `LocalAuthentication`
- Login/SignUp Supabase (in sviluppo per sync cloud)

### Shortcuts Apple (Intents/)

- Azione "Aggiungi spesa" disponibile nell'app Comandi di iOS
- Aggiungibile come widget su schermata home o di blocco
- Inserisci nome e importo → salvato direttamente nel database senza aprire l'app
- `try?` safe init del ModelContainer (no crash in caso di store non disponibile)

### Tour archiviato

Fino al tag `tour-v1` l'app aveva un **onboarding tour a due livelli**: una panoramica lineare (`TourStep`/`OverviewStep`, uno step per tab con spotlight) e mini-tour contestuali (`ContextualHint`, spotlight + card «Ho capito»), pilotati da `TourManager` e disegnati da `TourOverlayView` tramite gli ancoraggi `.tourAnchor(...)`. Con il redesign «Sentiero» è stato **rimosso dal codice** (cartella `MoneyTracker/OnboardingTour/`, `TourFlowUITests`, ancoraggi nelle viste, voce «Rivedi tour» e banner hint in Impostazioni, stringhe `tour.*`/`hint.*` nelle 7 lingue). La **modalità demo** resta invariata.

- **Tag:** `tour-v1` (annotato, su GitHub), commit `1853496`.
- **Ripristino:** `git checkout tour-v1 -- MoneyTracker/OnboardingTour MoneyTrackerUITests/TourFlowUITests.swift`, poi ricablare overlay (`.overlayPreferenceValue(TourAnchorKey…)` in `MoneyTrackerApp`), ancoraggi `.tourAnchor` nelle viste e stringhe `tour.*`/`hint.*` sulla nuova grafica.
- Le chiavi `UserDefaults` del tour rimaste sui dispositivi sono innocue.

### Ricorrenze Automatiche (serie virtuali, D-008/D-009)

- Ogni serie è una `RecurringRule` (sincronizzata, schema V3); le occorrenze hanno ID deterministico (UUIDv5 da regola + data originale), così più dispositivi non creano duplicati. `Transaction.templateId` punta alla regola. I template legacy (`recurringFrequency`) non generano più copie.
- Creazione: in `AddTransactionView` (solo nuova transazione) il picker "Ricorrenza" crea regola e prima occorrenza in un unico salvataggio.
- `RecurringMaterializer` crea come pianificate (`isDone = false`) le occorrenze dovute, mai storico retroattivo oltre il mese corrente. Avvii: login (dopo il sync), foreground (`scenePhase == .active`, anche offline/demo) e cambio giorno (`significantTimeChange`). Gli errori compaiono in un alert localizzato (`RecurrenceOperationStatus`).
- `RecurrenceEditorView`: ambiti *solo questa* (nome, importo, note, data nello stesso mese), *questa e successive* (split della serie), *tutte*; azioni *salta mese*, *termina da qui*, *termina dopo questa*, *elimina* con conferma. Le copie già fatte (`isDone`) restano invariate.
- Movimenti: tab "Ricorrenti" mostra le serie programmate (importo, frequenza, prossima, stato) accanto alle serie rilevate; nei mesi futuri le occorrenze **virtuali** compaiono in una sezione separata, etichettate «esclusa dai totali», e non entrano mai in totali, saldi o filtri importo.
- Sync: le regole viaggiano su Supabase; una regola locale non viene persa se il remoto è vuoto. La prova reale a due dispositivi è ancora da fare.

### Localizzazione

7 lingue (IT, EN, ES, FR, DE, ZH-Hans, JA). Le stringhe stanno in file `Localizable.strings` per lingua (non uno String Catalog): 395 chiavi in en/de/es/fr/ja/zh-Hans; il file italiano ne ha 89 perché l'italiano è la lingua di sviluppo e fa da testo di ripiego (la differenza è preesistente, da confermare che sia voluta). Accessibility labels localizzate con `String(localized:)` (non string interpolation italiana).

### Haptic Feedback

- Swipe "Modifica": haptic soft
- Swipe "Elimina": haptic medium
- Tutti i bottoni distruttivi: haptic medium

---

### Android (`03_CODICE/bucktrail-android`)

- Prima app Android in Kotlin, Jetpack Compose e Room (v3, con migrazione dalla prima build). Parità con iOS sulle schermate B0–B11: Home, Conti, Movimenti (filtri, trasferimenti, swipe, annulla), Pianifica, Statistiche, ricorrenze e impostazioni.
- Export PDF, CSV e JSON; notifiche; blocco app; cronologia; modalità demo; widget e scorciatoie.
- Login e sync Supabase: provati solo con un server finto. La build debug usa un URL finto e non tocca il cloud. La build release usa il Supabase reale (scelta voluta). La prova reale a due dispositivi è ancora da fare.
- Guardia anti-cancellazione del cloud: se il database locale è vuoto o cala in modo anomalo, la sync chiede conferma esplicita. Le righe remote non valide vengono ignorate senza bloccare il pull.
- Verifica: 247 test JVM verdi; collaudo 🟢 del 2026-11-23 (verbale in `.cantiere/`); stress test con 10 bug corretti.

### Protezione avanzata (cifratura end-to-end) — interruttore ACCESO in release (S-50p)

Cifratura end-to-end facoltativa della sync, costruita su iOS e Android (S-50). Progetto completo: `.cantiere/progetto-e2e-sync.md`.

- **Interruttore:** acceso in release dal 2026-11-26 (S-50p): `E2EFeature.isEnabled = true` (iOS) e `BuildConfig.E2E_ENABLED = true` (Android). Nelle build di debug resta spento salvo l'argomento `-E2EEnabled YES` (iOS) o `-Pe2e=true` (Android), così i test del caso «spento» continuano a girare. Una volta pubblicato acceso non si torna indietro: per fermare nuove attivazioni c'è `allowNewActivations`.
- **Dove si trova:** Impostazioni → sezione «Sicurezza», riga «Protezione avanzata» (nascosta in modalità demo, senza accesso o se il server non supporta la funzione). Testi con chiavi `e2e_*` identiche sulle due piattaforme, nelle 7 lingue.
- **Crittografia (solo primitive di sistema, nessuna dipendenza nuova):** AES-256-GCM per ogni riga; una chiave dati casuale (DEK) avvolta due volte: con la **frase di sicurezza** (PBKDF2-HMAC-SHA256, 600 000 iterazioni, almeno 10 caratteri, distinta dalla password dell'account) e con la **chiave di recupero** (160 bit casuali, 32 caratteri in 8 gruppi da 4, HKDF-SHA256). Ogni riga cifrata è legata a tipo, id e utente: se il server la sposta o la altera, viene rifiutata.
- **Chiave solo sul dispositivo:** la DEK sta nel Keychain iOS (`ThisDeviceOnly`, niente iCloud Keychain) o in Android Keystore. Frase e DEK non lasciano mai il telefono in chiaro; reset della password Supabase senza effetti sui dati.
- **Sul server (Supabase):** tabella `mt_vault` (una riga per record: `id`, `user_id`, `kind`, `key_id`, `payload` cifrato) e `mt_e2e` (stato e chiavi avvolte). Il server conserva solo dati illeggibili. Un trigger sulle 5 tabelle `mt_*` rifiuta le scritture in chiaro quando la protezione è attiva: una versione vecchia dell'app smette di sincronizzare, ma non può sovrascrivere né rimettere in chiaro i dati.
- **Attivazione verificata e reversibile:** sync completa e backup locale, poi copia cifrata nel vault. Prima di cancellare la copia in chiaro (che nel frattempo resta congelata), il vault si rilegge e si confronta riga per riga col dispositivo: contatori, id, campi, ricevuta SHA-256. Se la verifica fallisce due volte c'è il rollback automatico; finché lo stato è `migrating` c'è anche il pulsante «Annulla attivazione». Ogni passo riprende da dove si era interrotto.
- **Altri dispositivi:** dopo l'accesso compare «Sblocca la sincronizzazione». Si inserisce la frase o la chiave di recupero e la DEK viene salvata sul dispositivo. Finché non si sblocca, la sync è in pausa e le modifiche locali restano in attesa senza perdersi.
- **Gestione (con Face ID / codice del dispositivo):** cambio della frase, nuova chiave di recupero (la precedente smette di funzionare), disattivazione. La disattivazione rimette i dati in chiaro sul server, li verifica e solo dopo cancella il vault.
- **Frase e chiave perse:** i dati sul cloud non si possono recuperare (l'avviso compare prima dell'attivazione). «Ho perso frase e chiave» → «Ricomincia da questo dispositivo» cancella i dati cifrati sul server e riparte in chiaro con i dati del telefono. È irreversibile; se il telefono è vuoto, anche il cloud resta vuoto.
- **«Protezione avanzata disattivata»:** se la protezione sparisce dal server mentre il dispositivo ha ancora la chiave, l'app non torna in chiaro da sola. Si blocca e chiede: «Continua senza protezione» (se l'utente l'ha disattivata da un altro dispositivo) oppure «Esci dall'account» (se non è stato lui). Così chi ruba il token o amministra il database non può farsi ricaricare i dati in chiaro.
- **Eliminazione account:** la cancellazione di `mt_vault` e `mt_e2e` è garantita dal server (`on delete cascade` da `auth.users`). Al logout la chiave locale si cancella.
- **Limiti dichiarati:** il server vede l'account (id ed email), l'id e il tipo di ogni record (quindi **quanti** conti, movimenti, budget, obiettivi e ricorrenze ci sono), la dimensione approssimativa di ogni riga, quando si sincronizza e da quale IP. Può cancellare righe o rimettere una versione precedente della stessa riga, ma non creare dati falsi leggibili. Non protegge un telefono sbloccato in mano ad altri. Una frase debole resta un rischio.
- **Stato (26 novembre 2026):** completata e collaudata (S-50a…y). Accesa nelle build di rilascio iOS e Android (in debug resta spenta, salvo `-E2EEnabled YES` / `-Pe2e=true`); provata anche su APK release R8. FAQ e informativa privacy del sito aggiornate in italiano e inglese. Resta la prova reale di Matteo con un account di prova su due dispositivi.

---

## 7. Audit Qualità (Score: 7.2 / 10 — audit di giugno–luglio 2026, non rieseguito dopo il redesign «Sentiero»)

> **Aggiornamento 2026-11-24:** Commissione Suprema, giro 2: 10/10 su tutti i giudici dopo 4 correzioni (debug Android con URL finto, stringa demo, cache della proiezione Home, separatore dell'ultima riga). Verbale in `.cantiere/commissione-suprema-2026-11-24.md`.

> **Stato attuale (checkpoint del 2026-11-17):** build verde, **90 test unitari** e **45 UI test** verdi (run completo). Dopo il redesign la Commissione Suprema (6 giudici, 2026-11-17, su `main` @ dd473ca) ha dato **7,0 / 10** di media: Sicurezza 6 · Architettura 7 · Logica 8 · Performance 8 · Robustezza 7 · Lingua/UX 6. Rilievi principali: push di sync con `try?` che può svuotare il cloud, ~40 stringhe non tradotte, `parseAmount` permissivo (correzioni in coda nel piano). Il voto e i bug sotto restano come storico dell'audit originale.

| Area | Voto |
|---|---|
| Architettura | 7/10 |
| Qualità codice / Bug | 7.5/10 |
| Performance | 7/10 |
| Standards / Manutenibilità | 7.5/10 |
| Sicurezza | 8/10 |
| **Totale** | **7.2/10** |

### Cosa funziona bene

- Swift 6 strict concurrency rispettata ovunque — zero data races
- OSLog strutturato con subsystem/category separati
- `NSFileProtectionComplete` sul database SwiftData
- Formula injection prevention nel CSV export
- Design system coerente (`DS` namespace, `EmptyStateView`, componenti «Sentiero» in `Views/Components/`)
- `LazyVStack` per liste lunghe (no List con altezza fissa)
- Notifiche con ID idempotenti (remove-then-add)
- VoiceOver completo su tutti i componenti principali

### Bug risolti (sessioni precedenti)

| ID | Problema | Stato |
|---|---|---|
| BUG-01 | `DashboardView` List + frame fisso → testo troncato con Dynamic Type | ✅ Fixato → LazyVStack |
| BUG-02 | `GoalsView.load()` → "1000.0" invece di "1000" | ✅ Fixato → `truncatingRemainder` |
| BUG-03 | `CategoryStat.id` UUID instabile → rompeva diffing SwiftUI | ✅ Fixato → computed var stabile su `name` |
| BUG-04 | `print()` di debug in `TabBarFrameCapture` → console noise su layout hot-path | ✅ Fixato → rimossi 7 print |
| PERF-01 | Allocazione `NumberFormatter`/`DateFormatter` per ogni render | ✅ Fixato → `FormatterCache` singleton |
| SEC-01 | `try!` su `ModelContainer` in Shortcuts → crash dell'estensione | ✅ Fixato → `try?` + guard con errore user-visible |
| i18n-01 | Sezione Siri non tradotta in nessuna lingua | ✅ Fixato → 10 chiavi aggiunte a tutti i 6 file |
| i18n-02 | Accessibility labels in italiano hard-coded | ✅ Fixato → `String(localized:)` ovunque |
| PERF-02 | `€` hardcoded in `AddAccountView` e `AddTransferView` | ✅ Fixato → `Double.currencySymbol` |

### Issue residue (non critiche)

| ID | Problema | Priorità |
|---|---|---|
| PERF-R01 | `Account.currentBalance` O(n_tx) — scala male con >5000 tx | Alta — v2 |
| PERF-R02 | `@Query` senza fetchLimit in DashboardView | Media |
| SMELL-01 | `CategoryManagementView` sezione vuota → bare Text | Bassa |
| SMELL-02 | `AddGoalView`, `AddBudgetView` senza `@FocusState` | Media |
| SEC-02 | `NotificationManager.isEnabled` non verifica autorizzazione OS effettiva | Media |
| SEC-04 | `CheckBalanceIntent` biometric policy rimossa (API iOS 26 cambiata) | Bassa |

---

## 8. Roadmap

### Livello 2 — Necessario per essere competitivi

| Feature | Stato |
|---|---|
| Tour onboarding / discoverability | 🗄️ Archiviato (tag `tour-v1`, vedi «Tour archiviato») |
| Widget schermata Home e Lock Screen (WidgetKit + AppGroup) | ☐ |
| Ricorrenze automatiche | ✅ Implementato |
| Apple Watch App (watchOS target + WatchConnectivity) | ☐ |
| Face ID / Touch ID blocco app | ✅ Implementato (AppLockGate) |

### Livello 3 — Feature WOW (differenziazione totale)

| Feature | Descrizione |
|---|---|
| **Connessione bancaria automatica** | GoCardless/Nordigen API (gratuito EU) — Intesa, UniCredit, Fineco, BancoBPM, Poste |
| **"Me lo posso permettere?"** | Shortcut conversazionale on-device: "scarpe 150€" → risposta immediata con contesto budget |
| **AI Financial Coach** | Report mensile automatico il 1° del mese, on-device. Opzionale: sintesi via Claude Haiku API |
| **Tracker abbonamenti** | Rilevamento automatico pagamenti ricorrenti, alert per abbonamenti non usati |
| **Punteggio Salute Finanziaria** | Score 0–100 settimanale su 5 dimensioni (budget, obiettivi, fondo emergenza, spese fisse, risparmio) |
| **Sync cross-device (Supabase)** | iPhone + iPad, offline-first, TLS + AES-256, last-write-wins |
| **Modalità Coppia/Famiglia** | Database condiviso via CloudKit o Supabase |
| **Split spese** | Divisione conto con contatti iPhone + iMessage/WhatsApp automatico |
| **Calendario flusso di cassa** | Vista calendario con proiezione saldo giorno per giorno |
| **Tracciatore Patrimonio Netto** | Attivi – Passivi (banca + investimenti + immobili – mutuo + debiti) |
| **Feature fiscali italiane** | Bollette tracker, F24 tracker, Detrazioni fiscali 19%, 730 helper, TFR tracker |
| **Modalità "Stipendio → Zero"** | Zero-based budgeting guidato (metodologia YNAB) |

### Livello 4 — Futuro

Investimenti automatici (Directa/Fineco API), Crypto wallet tracker, FIRE Calculator, "Boomerang" confronto periodo anno scorso, Spesa emotiva, Marketplace partner opt-in, API pubblica.

---

## 9. Setup e Installazione

### Requisiti

- Mac con macOS 13+
- Xcode (gratuito dall'App Store del Mac, ~7 GB)
- iPhone con iOS 17+
- Cavo USB (prima volta)

### Installazione da sorgente

1. Apri `MoneyTracker.xcodeproj` in Xcode
2. Signing & Capabilities → seleziona il tuo Team (Apple ID)
3. Collega iPhone al Mac con cavo → "Autorizza" sul telefono
4. Seleziona il tuo iPhone come dispositivo target
5. Premi ▶ (Play)
6. Prima volta: Impostazioni iPhone → Privacy e sicurezza → App per sviluppatori → Autorizza il tuo Apple ID

### Configurare il banner Shortcuts

1. App Comandi sul iPhone → "+" → "Aggiungi azione" → cerca "Money Tracker"
2. Seleziona "Aggiungi spesa"
3. `···` → "Aggiungi a schermata Home" o "Aggiungi a schermata di blocco"
4. Tocca l'icona → banner in cima → inserisci nome e importo → salvato senza aprire l'app

### Note

- **Certificato:** con Apple ID gratuito scade ogni 7 giorni. Ricollegare il telefono e premere Play per rinnovarlo.
- **Dati al sicuro:** SwiftData non cancella i dati durante gli aggiornamenti.
- **Trasferimento:** richiede almeno 2 conti non archiviati.

### Errori comuni

| Problema | Soluzione |
|---|---|
| "Signing failed" | Xcode → Signing & Capabilities → Team → seleziona Apple ID |
| App non si apre | Impostazioni → Privacy → App per sviluppatori → Autorizza |
| Certificato scaduto (7 giorni) | Ricollega iPhone, premi Play in Xcode |
| "Personal teams do not support iCloud" | Non aggiungere iCloud/Push con Apple ID gratuito |

---

## 10. Changelog

> Nota: le versioni 3.1 e successive sono state assegnate retroattivamente il 2026-11-17, una per blocco di lavoro coerente, in ordine crescente nel tempo.

### v3.30 (27 novembre 2026) — Sync più robusta, Protezione avanzata sul telefono vero, campi segreti e ordine dei movimenti (S-51…S-56, S-50z, S-50g2)

- **S-51 (iOS):** niente più perdita di movimenti quando l'app si apre a telefono bloccato (archivio con protezione `completeUntilFirstUserAuthentication`, nessuna sync su archivio volatile); corretti un crash all'avvio su iOS 27.2 e un'intermittenza di test. Prova automatica a due dispositivi sul server vero 12/12.
- **S-52 (iOS, Android, server):** movimenti scollegati dal conto sull'account vero riparati (113 ricollegati); guardie sui conti, pull senza eco e ricollegamento automatico; sul server FK `NO ACTION DEFERRABLE` e colonna `account_link_cleared`.
- **S-53 (iOS):** l'attivazione della Protezione avanzata falliva sul telefono vero perché la copia di sicurezza appena scritta veniva cancellata (percorsi `/var` e `/private/var`): ora le copie si riconoscono dal nome del file. Prova reale di Matteo su iPhone e Android ok; **S-50 chiuso**.
- **S-54 (iOS e Android):** stesso ordine dei movimenti ovunque: giorno più recente prima e, nello stesso giorno, l'ultimo aggiunto in cima.
- **S-55 (iOS e Android):** occhio mostra/nascondi su password, frase di sicurezza e chiave di recupero; il campo torna nascosto in background; etichette in 7 lingue.
- **S-56 (iOS e Android):** trattini automatici ogni 4 caratteri e maiuscole solo nei campi della chiave di recupero.
- **S-50z / S-50g2:** script ripetibile per la prova della release Android minificata (solo server finto); il guardiano ignora in locale il solo beacon Cloudflare Insights.
- **Collaudi:** iOS 211 unitari, Android 343 JVM + lint; Commissione Suprema 6×10/10.

### v3.29 (26 novembre 2026) — Protezione avanzata: pulizia, release verificata, email, privacy e sito (S-50u…y)

- **S-50u (iOS e Android):** la pulizia delle chiavi morte legge solo le righe obsolete (`key_id` diverso dalla chiave viva). Le cancellazioni restano solo sulla chiave morta.
- **S-50w:** prova sull'APK release minificata (R8): attivazione, sync, sblocco dopo pulizia dei dati e disattivazione verificati. Nessun traffico in chiaro nel manifest di release.
- **S-50x (email dell'account):** conferma e recupero password inviati da Supabase tramite Brevo. Il blocco per IP sconosciuti è disattivato solo per le chiavi SMTP; l'API resta protetta.
- **S-50v (privacy dell'app, it/en):** informativa completa in `SOCIAL/landing/privacy.html` e `privacy-en.html`: app senza account, account e sincronizzazione, Protezione avanzata, destinatari e trasferimenti, email dell'account tramite Brevo.
- **S-50y (sito):** meta description e hreflang sulle pagine secondarie (chi-siamo/about, confermato/confirmed, privacy it/en).
- **Sito:** testi approvati da Matteo e pubblicati su Cloudflare Pages (2026-11-26, 18:23 e 18:54).
- **Collaudi:** iOS 187/187 unitari (2 UI instabili come in S-50r), Android 324/324 JVM + lint, server finto 19/19, bilingue 100/100.
- **Aperti (non bloccanti):** S-50z (script per ripetere la prova R8), S-50g2 (guardiano: errore CORS del beacon Cloudflare in locale). Prova reale con account di prova: a Matteo.

### v3.28 (26 novembre 2026) — Protezione avanzata accesa (S-50p)

- **Interruttore acceso in release** su iOS e Android: la riga «Protezione avanzata» compare in Impostazioni → Sicurezza per chi ha l'account. Debug invariato (spento salvo argomento di avvio).
- **Sito (`SOCIAL/landing`):** FAQ «Come so che i miei dati sono al sicuro?» aggiornata in italiano e inglese con la Protezione avanzata; nuova sezione nell'informativa privacy su cosa conserva il server con la protezione attiva. Testi in attesa di approvazione in `.cantiere/APPROVAZIONI.md`, pubblicazione a cura di Matteo.

### v3.27 (25–26 novembre 2026) — Protezione avanzata (cifratura end-to-end), interruttore spento

- **S-50 (Protezione avanzata, 2026-11-25/26):** cifratura end-to-end facoltativa della sync su iOS e Android (vedi §6, «Protezione avanzata»). Lavoro in S-50a…S-50l: crittografia e vettori di test condivisi, vault, migratore con verifica e rollback, interfaccia e testi nelle 7 lingue, logout, eliminazione account, cambio utente e stress test. Correzioni dei collaudi in S-50h2, S-50l.1, S-50l.2, S-50q, S-50q.1, S-50q.2 e S-50q.3: `key_id` su ogni riga del vault, A6 e rollback atomici via RPC, pull limitata alla chiave viva, eliminazione account garantita dalla cascata del server.
- **Server Supabase:** 3 script SQL additivi applicati da Matteo: schema e trigger (S-50n, 24/11), `key_id` e RPC di A6 (S-50q, §6.7, 26/11), rollback atomico (S-50q.1, §6.9, 26/11).
- **Commissione Suprema S-50m:** primo giro con voti da 6 a 9. Correzioni: nuovo blocco «Protezione avanzata disattivata» quando la protezione sparisce dal server, blocco `unsupported` se `mt_e2e` è irraggiungibile e c'è una chiave locale, ricevute di verifica nei log solo in debug, `FLAG_SECURE` e pulizia degli appunti dopo 120 s su Android, chiavi azzerate in memoria, accessibilità della chiave di recupero e nuove stringhe (`e2e_usa_frase`, `e2e_nuova_chiave_titolo`, `e2e_copiata`, `e2e_rimossa_*`). Rimandati S-50r e S-50s. Secondo giro (voti 8–9): primo accesso con pull prima del push allineato tra iOS e Android in ogni ritorno in chiaro, conferma prima di «Esci dall'account» nel blocco, cancellazione locale in blocco corretta (Account per primo) e provata da test, chiave `e2e_rimossa_esci`. Esito finale (terzo giro, 2026-11-26): **10/10 per tutti e 6 i giudici**. Test: iOS 184 unitari + 7 UI E2E, Android 321 JVM + lint.
- **Interruttore spento in release** su entrambe le piattaforme: per chi usa l'app non cambia nulla.
- Prossimi: S-50o (Matteo approva le schermate) e S-50p (accensione, FAQ e privacy del sito).

### v3.26 (24 novembre 2026) — Sicurezza dei dati, analytics della landing e rifiniture Android

- **S-44 (verifica sicurezza):** relazione sul codice in `.cantiere/sicurezza-dati-2026-11-24.md`. iOS: protezione file `.complete` sul database, sessione nel Keychain, blocco biometrico. Android: database nell'area privata con backup disattivato, sessione cifrata AES-GCM con chiave del Keystore, blocco biometrico. Cloud: HTTPS, cifratura a riposo di Supabase, RLS. Non è cifratura end-to-end. Nessuna falla trovata; Room non cifrato a livello app, scelta documentata di non aggiungere SQLCipher.
- **S-45:** nella FAQ della landing (it/en) la risposta «Come so che i miei dati sono al sicuro?», limitata a ciò che S-44 conferma.
- **S-46:** Cloudflare Web Analytics sulla landing (senza cookie): CSP in `_worker.js`, informativa privacy aggiornata, frammento nelle 5 pagine. Hreflang reciproci aggiunti a `index.html` e `en.html`.
- **S-47/S-48 (Android):** splash di sistema senza icona (solo fondo carta, chiaro e scuro); lucchetto e grafico a torta ridisegnati come su iPhone (disegno proprio, non i glifi Apple). Provati da Matteo su telefono vero.
- **S-49:** login e sincronizzazione Supabase su Android provati da Matteo con il cloud reale: funzionano.
- `main` portato al ramo `redesign-sentiero` (push `6d574da..2364d6e`).
- Strumento `bilingue.py`: abbinamento esplicito `en.html`↔`index.html` e `confirmed.html`↔`confermato.html` (voto Lingue 64 → 87; resta la privacy solo in italiano).

### v3.25 (24 novembre 2026) — Pacchetto A della Commissione, font scalabili, traduzioni e test

- **S-38:** i filtri avanzati (importo e periodo) valgono anche per le occorrenze virtuali dei mesi futuri; le date del periodo personalizzato restano salvate; «Salta mese», «Termina da qui» e «Termina dopo questa» chiedono conferma (dialogo ancorato: si annulla toccando fuori); il rilevamento delle serie ricorrenti è in cache e si rifà solo se cambiano i dati; tolti i force-unwrap di `RecurrenceControls` e `RecurringSeriesDetector`; `RecurringMaterializer` usa lo `snapshot` unico del editor; «•••• €» usa il simbolo della valuta.
- **S-40:** 239 `.font(.system(size:))` sostituiti da `.scaledFont(size:weight:)` (`@ScaledMetric`): stesso aspetto a dimensione standard, ora seguono Dynamic Type. Scelta: non mappati su `DS.Typo.*` per non cambiare l'aspetto di icone e numeri decorativi.
- **S-39:** 46 stringhe che comparivano in italiano tradotte in en/de/es/fr/ja/zh-Hans (Login, Registrazione, Impostazioni, Cronologia modifiche, blocco app, «Saldo/Atteso», «Periodo»); chiavi doppie «Fine»/«Tipo» tolte. 437 chiavi allineate nelle 6 lingue.
- **S-41 (passaggio di mese):** la condizione «spesa fissa singola nel mese di competenza» è la funzione pura `DashboardView.countsInProjection`, coperta da 3 test; la data di riferimento della Home si aggiorna anche allo scoccare della mezzanotte (`NSCalendarDayChanged`).
- **S-43:** il test UI `SentieroReviewFixUITests` verificava che la lista finisse sopra il pulsante +, ma la scheda Pianifica la fa scorrere sotto la barra per scelta: ora controlla che, a fine scorrimento, l'ultimo testo resti sopra il pulsante.
- **S-16:** SwiftData conserva circa 15 cifre significative di un `Decimal`: gli importi reali (tetto 1 miliardo, 2 decimali) tornano esatti, il caso estremo a 19 cifre perde ~3·10⁻¹³ e l'interfaccia non può produrlo. Documentato da `DecimalPersistenceTests`.
- Test: 99 unitari iOS, 49 UI (nuovo test su conferma «Salta mese»), tutti verdi; Android 247 JVM e 2 strumentati su emulatore. Guardiano notturno riconfigurato sulla landing (`SOCIAL/landing`): prima puntava a una cartella senza sito.

### v3.24 (24 novembre 2026) — Android a parità con iOS, Commissione Suprema e pulizia dei rami

- Android: parità con iOS sulle schermate B0–B11 (Room v3, export PDF/CSV/JSON, notifiche, blocco app, modalità demo, widget e scorciatoie). 247 test JVM verdi; collaudo del 2026-11-23 superato.
- Sync Android: guardia anti-cancellazione del cloud (database vuoto o calo anomalo: serve conferma esplicita). Login e sync provati solo con server finto; la prova con il Supabase reale è ancora da fare.
- Commissione Suprema, giro 2: 10/10 su tutti i giudici dopo 4 correzioni. La build debug Android usa un URL finto. Cache della proiezione Home: la curva si ricalcola solo quando cambiano i dati.
- iOS: S-41 (spesa fissa singola nel mese di competenza) e S-42 (annullamento eliminazione serie, sezione Ultimi movimenti) chiusi. Rami git vecchi cancellati; resta `fix/nightly-20260727-0411`.

### v3.23 (21 novembre 2026) — Prima build Android e pianificazione locale

- Android usa Kotlin, Jetpack Compose e Room. Le prime schermate sono Home, Conti e Movimenti. La build debug si esegue con Gradle da VS Code e si collauda sull’emulatore `Bucktrail_API_36`.
- I movimenti Android supportano data, pianificazione, modifica e registrazione come effettuati. Il saldo attuale include gli effettuati. La previsione di fine mese include i pianificati del solo mese corrente. La migrazione Room conserva conti e movimenti della prima build.
- Android lavora sui dati locali. Il login e la sincronizzazione Supabase sono rinviati su indicazione di Matteo. Il calendario e la pubblicazione social li gestisce Matteo.

### v3.22 (21 novembre 2026) — Competenza mensile, stabilità iOS e piano multipiattaforma

- **S-41.** Una spesa fissa singola con data futura entra nel mese di competenza. Il saldo attuale e le previsioni dei mesi precedenti tengono conto delle rispettive date.
- **S-42.** Verificati sul simulatore l’annullamento dell’eliminazione di una serie programmata e la visualizzazione di «Ultimi movimenti» in Home.
- **Lancio e social.** La landing italiana e inglese annuncia iPhone e Android e presenta il collegamento bancario facoltativo come funzione successiva al lancio. Il calendario e i pacchetti dei Post-3–42 sono pronti per la revisione e la programmazione.
- **Android e banca.** Il primo traguardo Android è una build Kotlin/Compose con la stessa esperienza iOS e una prova di sincronizzazione offline su Supabase di test. Per il collegamento bancario si valuteranno copertura, ritardo e costi del fornitore prima della prova pilota. Lo stato e le verifiche aperte sono in `.cantiere/CHECKPOINT.md`.

### v3.21 (novembre 2026) — Home: curva del saldo allineata (S-36) e progetto SOCIAL in formato «faceless»

- `TrailView`: il tratteggio ambra parte ora dal punto reale di oggi (il pallino verde) e usa solo i punti proiettati dei giorni successivi; con movimenti pianificati per oggi prima partiva più in basso e il cerchio vuoto si sovrapponeva al pallino. Il cerchio dei pianificati di oggi non è più disegnato. Se oggi è l'ultimo giorno del mese il tratteggio unisce al «Saldo atteso». Nessun calcolo, modello o test modificato; collaudo 10/10 (6 giudici), build e test verdi.
- Progetto SOCIAL (nessun codice dell'app): formato dei contenuti «faceless» (mani + telefono, caroselli puliti, musica TikTok, mai voce o volto), messaggio di brand in 5 temi (regole di progetto), primo post pronto (carosello «Ogni conto al suo posto. Ogni euro in chiaro.», 9 slide + copertina, generato da `SOCIAL/caroselli/presentazione-v1/build.py`), consegna dei post su Drive in «Da postare» con file di istruzioni `.txt` (`SOCIAL/esporta-post.py`). Dettagli in `.cantiere/DECISIONI.md`.

### v3.20 (novembre 2026) — Pianifica: lista non più tagliata (fix) e nuova landing

- `PianificaView`: il margine in basso per la fascia del pulsante + era un `.padding` sullo `ScrollView`, che accorciava la lista e la tagliava di netto sopra la barra (Budget e Obiettivi). Ora è `.contentMargins(.bottom, …, for: .scrollContent)`: la lista scorre fino alla barra. Solo layout, nessun calcolo toccato; build verde. Collaudo visivo a cura di Matteo.
- Progetto SOCIAL: nuova landing statica IT/EN (`SOCIAL/landing/`, struttura del mockup v1, screenshot reali dell'app in demo, nessuna dipendenza esterna, ~720 KB). Funzioni descritte dalla sezione 6; claim secondo manuale 1.3 e 12.

### v3.19 (novembre 2026) — Manutenzione test UI (S-32, S-33)

- S-32: `DemoShowcaseUITests.testShowcaseScreens` era rosso anche senza S-30 perché gli swipe saltavano la bolletta; ora apre la voce con la ricerca esistente e attende che sia tappabile (5 s). Asserzioni e catture invariate; nessun codice di produzione toccato.
- S-33: `RecurrenceFlowUITests.testCreateEditAndDeleteScheduledSeries` era rosso una volta alla riga 100 (voce «Ricorrenza» non trovata) ma non si riproduce: 4 run verdi, suite UI 45/45, 90 unit. Causa non accertata, nessuna modifica; resta in osservazione (se ricompare si salva l'`.xcresult` e si riapre il task).

### v3.18 (novembre 2026) — Categoria dall’ultima volta (S-30, D-011)

- In inserimento la cronologia ha priorità sulle parole chiave: nome esatto normalizzato, ultimo movimento per inserimento, solo effettuati e non trasferimenti. Categoria eliminata: ripiego sulle parole chiave.
- Etichetta «Ultima usata» in sette lingue (traduzioni approvate da Matteo il 2026-11-16). Nessun modello, tabella, sync o classifier modificato. Funzione pura `LastUsedCategory` e test dedicati.

### v3.17 (novembre 2026) — Rimozione del confronto mese su mese (S-31, D-012)

- Su richiesta di Matteo (2026-11-16) la card «Confronto mese su mese» (S-14) è rimossa: eliminati `SpendingComparisonCard`, `Domain/MonthlySpendingComparison` e i relativi test (unit e UI); da `StatisticsView` tolti card, cache, osservatori e notifica del cambio giorno dedicati.
- Rimosse le 12 chiavi esclusive della card in tutte e 7 le lingue; «Dati insufficienti.» e i `.stringsdict` (S-7p) restano. Grafici, 6M/12M, medie, confronto annuale e PDF invariati.
- Collaudo ok: build riuscita, 83 unit test e 4 UI test Statistiche verdi, screenshot light/dark/XL/tedesco senza vuoti. Il capitolo S-14 qui sotto resta come storico.

### v3.16 (novembre 2026) — Redesign «Sentiero» completo: Statistiche, Pianifica, Conti, confronto mese su mese (S-6…S-10, S-14)

- S-6 Statistiche, S-7 Pianifica, S-8 Conti ridisegnate dai mockup (stili letti dal sorgente HTML): grafico `BarMark` con `position(by:)`, hero con anello e badge di stato testuali, raggruppamento per tipo solo visivo. Soglie, progresso ponderato, PDF e archiviazione invariati. Righe archiviate leggibili (contrasto 5,60:1 light, 7,28:1 dark); spazio in fondo a Pianifica per il pulsante flottante.
- S-14: card «Confronto mese su mese» in Statistiche (`Domain/MonthlySpendingComparison`, puro, `Decimal`): stesso periodo di giorni, per categoria e totale, freccia + testo, percentuali ≥100 senza decimali, righe per variazione assoluta decrescente, snapshot calcolato fuori dal `body`.
- Plurale di «Mancano %lld giorni» (`Localizable.stringsdict` it/en/de/es/fr; ja/zh forma unica). Nuove traduzioni S-6/S-7/S-8/S-14 in 7 lingue, approvate da Matteo.
- S-28: tab bar leggibile con Dynamic Type XL. S-29: helper calendario senza `!`, un fetch per regola nel materializer, errori localizzati, test round-trip `Decimal`.
- Qualità: Commissione S-13h e S-10 senza difetti bloccanti. 92 unit test; UI 45 test (42 verdi nel run completo, i 3 falliti rilanciati singolarmente verdi: un test sbagliato corretto e due instabilità del simulatore).
- Aperti: controlli manuali S-24 e S-21, prova Supabase reale (S-13f), precisione Decimal elevata (S-16), `TransactionsView` ancora 864 righe. Prossima funzione: S-30 «categoria dall'ultima volta» (D-011).

### v3.15 (novembre 2026) — Ricorrenze: rifinitura, demo vetrina e chiusura Commissione S-13h (S-17…S-29)

- S-17: il pull non cancella più regole locali non ancora spedite. S-18/S-19: rifinitura grafica di virtuali e serie programmate, revisione di testi e traduzioni (de/es/zh).
- S-21/S-22: meno ricalcoli per riga in `TransactionsView`, che viene spezzata in componenti. S-23/S-25: editor di singola occorrenza e uniformità dei campi per ambito (il tap normale applica «Tutte» alla serie). S-24: eliminazione delle serie con confronto per giorno originale; «già effettuato» resta della singola copia.
- S-26: demo vetrina completa (`DemoDataSeeder`, `seedVersion` 6) con vere regole, override e occorrenza effettuata, 32 chiavi `demo.*` in 7 lingue. S-27: full run UI 16/16.
- S-28: tab bar leggibile con Dynamic Type XL (`lineLimit(1)` + `minimumScaleFactor(0.6)`; «Bewegungen» completo su una riga).
- S-29 (Commissione S-13h, ora 10/10): helper di calendario con fallback al posto dei `!`, `lastMonth` calcolato su `interval.end - 1`, un solo fetch per regola nel materializer, `errorDescription` localizzati, test round-trip `Decimal` SwiftData/DTO; test sull'estremo dell'intervallo e commento sul guard. 82 unit test verdi.
- Aperti: approvazione traduzioni (Matteo), prova manuale S-24 sul caso reale, prova reale Supabase (S-13f).

### v3.14 (novembre 2026) — Ricorrenze a serie virtuali (S-13) — cambio di schema, sync e modello dati

- Nuovo motore: `RecurrenceCalculator`, `RecurringMaterializer`, `RecurringSeriesEditor`, `RecurringRule` sincronizzata; sostituisce `RecurringTransactionActor` (rimosso, commenti obsoleti aggiornati).
- UI: creazione, editor a tre ambiti, salta/termina/elimina, serie programmate e virtuali esclusi dai totali, alert errori, avvii lifecycle. Rimosso «Interrompi ricorrenza» legacy.
- S-20: `RecurringSeriesEditor` permette di eliminare/modificare una serie terminata prima della prima occorrenza (test di regressione). 68 unit test + `RecurrenceFlowUITests`.
- Aperti: prova reale Supabase (S-13f), rifinitura grafica (S-18), revisione traduzioni (S-19).

### v3.13 (novembre 2026) — Redesign «Sentiero», step 2–12: componenti, tab bar, Home, Movimenti, Impostazioni (S-2…S-5, S-9, S-12)

- S-2 (2026-11-13): componenti base in `Views/Components/` — `Card`, `HeroCard`, `MovementRow`, `ProgressBar`, `BudgetStatus`, `SegmentedPill`, `FilterChip`, ciascuno con `#Preview` light/dark. Il collaudo ha chiesto S-2b: chiavi «Sforato» e «Soglia 80%» nelle 7 lingue, raggio hero 24 (senza toccare `cardRadius`), nome della riga su una riga e importo mai troncato, `ProgressBar` che annuncia il valore reale anche oltre il 100%. Ricollaudo ok alle 20:40; nessuna vista esistente modificata.
- S-3 (2026-11-13): `FloatingTabBar` e FAB 58×58 con la grafica Sentiero. La `TabView` resta con la barra nativa nascosta: stessi indici di tab, stesse azioni del FAB, stessi identificatori `fabButton`/`fabMenu_*`; gli UI test passano agli id `tab_*`. Etichetta accessibile del FAB per tab («Nuovo movimento/budget/obiettivo/conto»). Collaudo ok alle 22:08; da riguardare le taglie di accessibilità oltre XL (altezza riservata fissa).
- S-4 (2026-11-13): Home ridisegnata. Nuova funzione pura `Domain/BalanceTrail` (serie giornaliera cumulata + proiezione, `Decimal`, 6 test) calcolata fuori dal `body`; `TrailView` e `HomeHeroCard` (ultimo punto reale = «Saldo attuale», ultimo proiettato = «Saldo atteso», tratto ambra solo se ci sono pianificati); conti in scroll orizzontale, fissi del mese, ultimi movimenti con `MovementRow`. Collaudo ok alle 22:40.
- S-5 (2026-11-13): Movimenti dal mockup: header, ricerca, chip tipo, selettore categorie con `SegmentedPill`, `MovementRow`, sezione «In arrivo · pianificati» in cima e card giornaliere con subtotali solo visivi (trasferimenti esclusi). `@Query`, filtri, swipe e mutazioni invariati. Collaudo ok alle 23:16 (27 unit + 12 UI verdi); le riserve cosmetiche sono confluite in S-12.
- S-9 (2026-11-13): stessi token applicati a Impostazioni, sheet di inserimento (`AddTransactionView` e affini), gestione categorie e viste di login/registrazione; solo aspetto, nessuna logica di `Auth/`, sync o Face ID toccata. Collaudo ok alle 23:16, 7 lingue senza testi tagliati (tedesco incluso), light/dark.
- S-12 (2026-11-14): Movimenti a pagina unica — titolo, impostazioni, ricerca e chip fermi, cambia solo la lista (Tutti/Fisse/Trasf./Uscite/Entrate); sotto i chip la zona mese · categoria · filtri avanzati come nel mockup; solo «Ricorrenti» resta pagina a sé. Assorbe le riserve di S-11 (importo a XL, badge demo). Collaudo ok alle 01:30 con confronto a vista (light, dark, XL, tedesco, filtri, swipe, Ricorrenti); 27 unit + 12 UI verdi. La tab bar a XL passa a S-10/S-28.

### v3.12 (novembre 2026) — Redesign «Sentiero», step 1: token, font, dark mode

- Palette «Sentiero» integrata in `DS` (adattiva light/dark, contrasto AA verificato); `ink/paper/fog/smoke` cambiano valore, `positive/negative` diventano alias di `accent/danger`; aggiunti `surface`, `divider`, `accentSoft`, `planned*`, `danger*`, `transfer`, `hero*`.
- Font Space Grotesk e Inter nel bundle (`Resources/Fonts`, `UIAppFonts`, licenze OFL) e `DS.Typo` con Dynamic Type.
- `CategoryTint`: tinta categoria deterministica (test `CategoryTintTests`); `FontRegistrationTests` verifica i font registrati.

### v3.11 (novembre 2026) — Redesign «Sentiero», step 0: rimozione del tour

- Rimossi `OnboardingTour/`, `TourFlowUITests`, `.tourAnchor(...)` in Dashboard/Transactions/Statistics/Pianifica/Accounts/ContentView, avvio automatico del tour, hook `--forceTour`, voce «Rivedi tour» e banner hint in Impostazioni, flag UserDefaults del tour nell'init `--uitesting`, stringhe `tour.*`/`hint.*`/«Rivedi tour» in tutte e 7 le lingue.
- Nessuna funzione dell'app toccata oltre al tour; modalità demo invariata.
- Tour conservato nel tag `tour-v1` (vedi «Tour archiviato»).

### v3.10 (settembre 2026) — Tre bug critici: Tocco posteriore che "sparisce", perdita dati al login, ricorrenze arretrate

Tre segnalazioni indipendenti dell'utente, tutte con causa radice nella sincronizzazione locale↔cloud e nel motore ricorrenze.

**Bug fix — la spesa aggiunta da Tocco posteriore/Siri/Shortcuts non compariva mai nell'app:**
- **Bug**: `AddExpenseIntent`/`AddIncomeIntent` (`Intents/AddExpenseIntent.swift`) girano fuori-processo rispetto all'app (`openAppWhenRun = false`, necessario perché il Tocco posteriore non deve aprire l'app). Senza un App Group configurato, quel processo separato e l'app principale aprono due `ModelConfiguration` senza `url:` esplicito, che risolvono in due container sandbox **diversi** — l'entitlements file era completamente vuoto, nessun App Group presente. Il salvataggio riusciva davvero (da qui il banner "salvato!"), ma finiva in uno store che l'app non apre mai.
- **Fix**: nuovo `Persistence/SharedStore.swift` — App Group `group.com.matteo.moneytracker.shared` aggiunto a `MoneyTracker.entitlements`; sia `MoneyTrackerApp.init()` sia `IntentContainer` in `AddExpenseIntent.swift` ora aprono lo store tramite lo stesso `url:` nel container condiviso. Migrazione automatica una tantum (`migrateLegacyStoreIfNeeded`) che copia (non sposta) lo store dalla vecchia posizione a quella condivisa al primo lancio dopo l'attivazione — altrimenti il nuovo percorso risulterebbe vuoto e l'utente perderebbe tutto. Se la capability non è (ancora) attiva in Xcode, `mainStoreURL` è `nil` e si ripiega sul comportamento precedente: nessuna regressione, ma il bug resta finché il passo manuale in Xcode (Signing & Capabilities → App Groups) non viene fatto.

**Bug fix — apertura app con tutti i dati cancellati, sostituiti da uno snapshot vecchio di mesi:**
- **Bug**: `MoneyTrackerApp.swift` chiamava `SyncService.clearLocalData()` in automatico ogni volta che `auth.isLoggedIn` diventava `false` — ma quel cambio di stato scatta anche per una sessione persa **passivamente** (token di refresh scaduto/fallito, rete instabile: il SDK Supabase emette comunque un evento "signed out"), non solo per un logout intenzionale. Il risultato: al primo hiccup di rete l'app svuotava silenziosamente tutto lo store locale, poi al login successivo lo ripopolava con l'ultimo snapshot su Supabase — spesso vecchio di settimane/mesi se il push locale era rimasto indietro (es. proprio a causa del bug precedente sul Tocco posteriore).
- **Fix**: rimosso lo svuotamento automatico reattivo. Il logout esplicito (bottone "Esci" in `SettingsView`) ora chiama `clearLocalData()` da solo, dopo aver tentato un push delle modifiche pendenti — stesso pattern già usato per l'eliminazione account. L'isolamento multi-utente resta garantito da `syncOnLogin()`, che svuota il locale solo quando rileva davvero un login con un `userId` diverso dall'ultimo salvato.
- **Indurimento aggiuntivo** in `SyncService.pull()`: le transazioni locali ancora "sporche" (create/modificate ma non ancora confermate su Supabase — es. `markTransactionDirty` chiamato dall'Intent ma il push non ancora partito) non vengono più cancellate solo perché assenti dall'ultimo pull; prima venivano trattate come "cancellate su un altro dispositivo".

**Bug fix — le transazioni ricorrenti non comparivano automaticamente all'inizio del mese:**
- **Bug**: il fix precedente (v3.8, agosto 2026, "fix trigger ricorrenze") faceva ripartire `processRecurring()` ad ogni ritorno in foreground, ma generava solo l'occorrenza del periodo **corrente** — se l'app non veniva aperta esattamente a cavallo del cambio mese/settimana/anno, quell'occorrenza restava persa per sempre, non recuperata nei lanci successivi.
- **Fix**: `RecurringTransactionActor.processRecurring()` ora recupera tutte le occorrenze mancanti dall'ultima generata fino a oggi (backfill), non solo quella corrente — fino a un tetto di sicurezza di 60 per template (5 anni per le mensili) per evitare che un template dimenticato a lungo generi migliaia di righe in un colpo solo; oltre il tetto, il recupero prosegue nei run successivi. La ricerca dell'ultima occorrenza generata usa ora un fetch mirato per `templateId` invece di una finestra fissa di 2 mesi, che perdeva di vista le ricorrenze annuali e causava un duplicato ad ogni run. Coperto da `MoneyTrackerTests/RecurringTransactionEngineTests.swift` (backfill di mesi arretrati, non-duplicazione delle annuali dopo 2+ mesi, template appena creato).

**Correttezza — precisione degli importi migrati da Double a Decimal (`SchemaMigration.swift`):**
- **Bug**: la migrazione V1→V2 usava `Decimal(Double)`, che congela l'espansione binaria imprecisa del `Double` (es. 19.99 diventava 19.98999999999999488 per sempre).
- **Fix**: conversione tramite la rappresentazione testuale più breve del `Double` (`Decimal(string: String(value))`), che restituisce l'importo "pulito" effettivamente inserito dall'utente. Le closure di migrazione ora propagano gli errori invece di inghiottirli con `try?`, coerente con il fallback già esistente in `MoneyTrackerApp.init()` in caso di store non migrabile.

⚠️ **Passo manuale richiesto per il fix del Tocco posteriore**: in Xcode, target "MoneyTracker" → Signing & Capabilities → "+ Capability" → "App Groups" → verificare/aggiungere `group.com.matteo.moneytracker.shared`. Finché non viene fatto, il Tocco posteriore continua a comportarsi come prima (fix inattivo, nessuna regressione).

### v3.9 (agosto 2026) — Nuova icona, nuovo nome "Bucktrail", grafico trend a barre affiancate

**Identità visiva — nuova App Icon:**
- Sostituito il vecchio grafico bianco/nero (barre + linea spezzata con pallini) con un design più pulito: barre crescenti minimali con l'ultima colorata in oro/ambra come unico accento cromatico.
- Aggiunte le varianti `AppIcon_dark_1024.png` e `AppIcon_tinted_1024.png` (prima dichiarate in `Contents.json` ma mai popolate — l'icona non cambiava mai in dark mode o con temi icona personalizzati iOS 18+).

**Nome visualizzato → "Bucktrail":**
- Impostato `INFOPLIST_KEY_CFBundleDisplayName = Bucktrail` su entrambe le configurazioni Debug/Release del target `MoneyTracker` in `project.pbxproj`. Il nome tecnico del progetto (cartella, target, bundle id) non cambia — vedi nota in testa a questo documento.

**Statistiche — trend mensile da barre+linea a barre affiancate:**
- `StatisticsView.swift`: il grafico "Uscite" (barre) + "Entrate" (linea con pallini) è stato sostituito con due `BarMark` affiancate per mese (`.position(by:)`), una per entrate e una per uscite — più leggibile del confronto barra/linea, specialmente quando le entrate erano ricorrenti a importo simile.
- Rimosso il parametro `isDot` di `legendItem(color:label:)`, diventato morto dato che entrambe le serie sono ora barre (nessuna legenda "a pallino" residua).

### v3.8 (agosto 2026) — Rettifica saldo conto, fix trigger ricorrenze, interrompi ricorrenza

**Bug fix — modifica del saldo di un conto con storico produceva un risultato sbagliato:**
- **Bug**: il campo "Saldo attuale" in `AddAccountView` mostrava e sovrascriveva `Account.initialBalance`, che è solo l'ancora sommata a *tutte* le transazioni storiche (`AccountBalanceCache`). Su un conto con transazioni già registrate, scrivere un nuovo valore non produceva mai quel saldo: il risultato finale restava `nuovo_valore + storico`, non il numero digitato.
- **Fix**: il campo ora precompila e accetta il saldo *reale* (`currentBalance`). In salvataggio, se il conto ha già transazioni, viene creata una transazione di rettifica ("Rettifica saldo", nuova categoria di default) per la sola differenza, datata oggi, invece di toccare `initialBalance` — lo storico resta intatto e il saldo risultante coincide esattamente col valore inserito. Su un conto senza transazioni il comportamento resta identico a prima (aggiorna direttamente `initialBalance`).
- Nuova categoria di default "Rettifica saldo" (`Category.swift`), aggiunta anche retroattivamente ai profili già esistenti tramite la migrazione già presente in `seedIfNeeded`.

**Bug fix — le transazioni ricorrenti non venivano riportate al mese nuovo:**
- **Bug**: `RecurringTransactionActor.processRecurring()` (logica di generazione corretta e già presente) veniva invocato solo dentro un `.task` legato al primo montaggio di `ContentView`, cioè solo a un lancio "da zero" dell'app. Chi teneva l'app viva in background attraverso il cambio di mese non vedeva mai generare le nuove occorrenze finché non chiudeva e riapriva il processo.
- **Fix**: `processRecurring()` viene ora invocato anche a ogni ritorno in foreground (`scenePhase == .active`, `MoneyTrackerApp.swift`). La guardia giornaliera già esistente evita elaborazioni ridondanti nello stesso giorno.

**Nuova funzionalità — "Interrompi ricorrenza":**
- Nuova voce nel context menu (long press) di `TransactionsView`, disponibile sia sulla transazione template originale sia su una qualunque copia già generata (risale al template tramite `Transaction.templateId`) — così non serve risalire a una transazione creata magari mesi o anni fa. Svuota `recurringFrequency` sul template: nessuna transazione già esistente viene toccata, semplicemente non ne verranno generate di nuove nei mesi successivi.

**i18n:** aggiunte le chiavi "Rettifica saldo" e "Interrompi ricorrenza" a tutti i 6 file di traduzione non italiani (EN/FR/ES/DE/JA/ZH-Hans).

### v3.7 (luglio 2026) — Card "Fissi del mese" in Home + tour onboarding testato end-to-end

**Nuova funzionalità — totali spese/entrate fisse del mese in Home:**
- Nuova sezione "Fissi del mese" in `DashboardView` (tra "Saldo atteso" e "Ultimi movimenti"): due mini-card affiancate (`FixedTotalTile`, nuovo componente in `Theme.swift`) con il totale di tutte le transazioni `isFixed` del mese corrente, separate per Uscita/Entrata — a prescindere da `isDone`, così l'utente vede il totale dei fissi (affitto, auto, assicurazione, ecc.) indipendentemente dal fatto che siano già stati pagati.
- Ciascuna delle due card è mostrabile/nascondibile **indipendentemente** dall'altra da Impostazioni → nuova sezione "Home" (due `Toggle` separati), persistiti via `@AppStorage("showFixedExpensesTotal")`/`("showFixedIncomeTotal")`, default entrambi attivi.
- Rispetta "Nascondi saldo" (`hideBalance`): con l'occhio disattivato mostra "• • •" come il resto della Home.
- Testi tradotti nelle 6 lingue non italiane (riuso della chiave esistente "Fissi del mese" per il titolo sezione, nuove chiavi "Spese fisse"/"Entrate fisse" per le card e "Spese fisse mensili"/"Entrate fisse mensili" per i toggle in Impostazioni).

**QA — tour di onboarding verificato end-to-end prima del checkpoint:**
- Aggiunti `accessibilityIdentifier` (`tourModalCTA`, `tourNext`, `tourBack`, `tourHintGotIt`) ai bottoni di `TourOverlayView.swift`: il solo testo "Avanti" era ambiguo negli XCUITest perché iOS assegna automaticamente la stessa etichetta di accessibilità (in italiano) alla chevron "mese successivo" di `MonthBar`, un componente estraneo al tour presente su più tab.
- Nuovo `MoneyTrackerUITests/TourFlowUITests.swift`: percorre l'intera panoramica (17 step, incluse le due card modali iniziale/finale) con screenshot ad ogni passaggio, verificando titolo e presenza del testo atteso per ciascuno step. Utile come test di regressione per future modifiche al tour.
- Verificato manualmente, screenshot per screenshot, che ogni spotlight punti all'elemento corretto e che i cambi tab/segmento (Movimenti → Statistiche → Pianifica → Conti) avvengano senza artefatti; nessun problema riscontrato.

### v3.6 (luglio 2026) — Trasferimenti: fix eliminazione e nuova modalità di modifica

**Bug fix — eliminazione trasferimento non funzionava dentro la sezione "Trasf." (`TransactionsView.swift`):**
- **Bug**: il dialog di conferma "Elimina entrambi i movimenti" era agganciato solo alla vista hub (root della `NavigationStack`), non alla vista della sezione realmente in primo piano quando si è dentro "Trasferimenti". Un `.confirmationDialog`/`.alert` attaccato a una vista non in cima allo stack di navigazione resta "in sospeso": compariva solo tornando indietro all'hub, mai subito dopo lo swipe.
- **Fix**: il modificatore (estratto in `View.transferDeleteConfirmation(pending:onConfirm:)`) è ora agganciato sia all'hub sia a `subListContent(for:)` (la vista pushata per ciascuna sezione), così l'eliminazione funziona subito indipendentemente da dove viene avviata.

**Nuova funzionalità — modifica di un trasferimento esistente:**
- Prima, toccare un trasferimento mostrava solo un alert bloccante ("elimina e ricrea"): non era possibile modificarlo.
- `AddTransferView` ora accetta un parametro opzionale `editing: Transaction?` (una delle due gambe collegate). In modalità modifica, `save()` aggiorna **entrambe** le gambe esistenti in modo sincronizzato (importo, data, note, stato fatto/pianificato, conti "Da"/"A") invece di crearne di nuove — il ruolo (`.uscita`/`.entrata`) e il `transferGroupId` di ciascuna gamba non vengono mai alterati, solo il conto assegnato.
- `TransactionsView`: il tap su un trasferimento apre ora `AddTransferView(editing:)` in una sheet, al posto dell'alert bloccante rimosso.
- Aggiunta la traduzione di "Modifica trasferimento" nelle 6 lingue non italiane.

### v3.5 (luglio 2026) — Colori semantici positivo/negativo, fix ricorrenze, tour a due livelli riscritto

**Colori (verde/rosso), indipendenti dal tema attivo:**
- Nuovi `DS.positive`/`DS.negative` in `Theme.swift` (toni smorzati, adattivi chiaro/scuro) + `DS.signColor(_:)` come unica fonte di verità per "colora in base al segno"
- Saldi (Home, Conti) colorati per segno; uscite/entrate colorate ovunque appaiano come riga (Movimenti, Home, storico ricorrenze) tranne i trasferimenti (restano neutri: non sono un guadagno/perdita reale)
- Statistiche: "Uscite"/"Entrate" e relativi grafici (barre, linea, legenda, barre per categoria), confronto anno su anno colorato in base a miglioramento/peggioramento
- Budget: resta neutro entro il limite, rosso solo se sforato
- Rimosso un flag morto (`FixedExpenseRow.colorCoded`) mai attivato da nessuna parte che avrebbe dovuto occuparsi di questo

**Bug fix — motore ricorrenze automatiche (`RecurringTransactionEngine.swift`):**
- **Bug**: quando una transazione con `recurringFrequency` impostata (Settimanale/Mensile/Annuale) veniva creata, il motore che genera le occorrenze future non considerava che il template stesso copre già il proprio periodo (mensile/settimanale/annuale) — perché il template è escluso dal fetch delle transazioni "normali" (`recurringFrequency.isEmpty`). Risultato: al lancio successivo dell'app veniva generata una copia duplicata per lo stesso mese/settimana/anno del template.
- **Fix**: aggiunto un controllo esplicito che salta la generazione se la data del template ricade già nel periodo corrente.
- Verificato separatamente che il rilevamento passivo delle ricorrenze (`RecurringSeriesDetector`, tab "Ricorrenti") **non** esclude le transazioni da Tutti/Uscite/Entrate/Trasf. — sono due sistemi distinti, il secondo è solo di lettura/analisi.

**Tour onboarding — riscritto da "un'icona per tab" a step sui singoli elementi:**
- Livello 1 (panoramica) ora ha 16 step-elemento (Home ×4, Movimenti ×3, Statistiche ×3, Pianifica ×3, Conti ×1) invece di un semplice spotlight sull'icona della tab bar; motore di spotlight anchor-based condiviso col Livello 2
- Aggiunti campi di tuning per-step (`spotlightPadding`, `spotlightYOffset`, `secondaryAnchorID`, `cardAtTop`) per correggere ritagli troppo piccoli/grandi, margini asimmetrici e card che coprivano il contenuto spiegato
- Lo step "Tutti i movimenti" ora naviga davvero dentro la sezione e ne mostra il contenuto reale mentre lo spiega, richiudendola quando si avanza
- Fine tour: torna sempre alla Home (prima restava sull'ultima tab visitata)
- Rimossa la spiegazione del FAB "+" ovunque (sia il mini-tour post-tour sia lo step dedicato in Conti) e i mini-tour per barra di ricerca/spese ricorrenti — giudicati poco chiari
- Bug fix: bottone "Elimina" nello swipe (Movimenti) ereditava un tint ambientale pensato per altro, mostrando sfondo bianco/icona nera in tema scuro invece del rosso di sistema
- Bug fix: la tastiera della ricerca in Movimenti ricompariva da sola tornando all'hub dopo aver aperto una sezione — il focus non veniva mai resettato

### v3.4 (luglio 2026) — Fix mini-tour contestuali che non comparivano mai

- **Bug**: `MoneyTrackerApp` montava `TourOverlayView` solo quando `tourManager.isActive` era vero (panoramica in corso). I mini-tour contestuali di Livello 2 (`ContextualHint`, il tooltip "Ho capito" tab per tab) scattano invece **dopo** che la panoramica è finita — la view che li disegna non esisteva più in quel momento, quindi non comparivano mai.
- **Fix**: la condizione di montaggio ora è `tourManager.isActive || tourManager.activeHint != nil` (`MoneyTrackerApp.swift`).
- **Bug correlato**: al termine della panoramica l'utente resta sull'ultima tab visitata durante il tour; il trigger dei mini-tour in `ContentView` scattava solo su `onChange(of: selectedTab)`, quindi l'hint di quella tab non partiva mai finché non se ne usciva e vi si tornava. Aggiunto un secondo trigger su `onChange(of: tourManager.isActive)` che controlla subito la tab corrente a fine tour.
- **Contenuto**: aggiunto il mini-tour `hint.goalsList` (anchor `goalsList`, già presente in `PianificaView` ma orfano) per spiegare gli obiettivi di risparmio quando si passa al segmento "Obiettivi" — prima quella sezione non aveva alcuna spiegazione contestuale. Rifiniti alcuni testi italiani per un tono più professionale (`hint.tabStatistiche.body`, `hint.movimentiHub.body`, `hint.fab.body`).

### v3.3 (luglio 2026) — Fix tocco posteriore/Siri: transazioni che sparivano dopo il salvataggio

- **Bug**: `AddExpenseIntent`/`AddIncomeIntent` (App Intent usati dal tocco posteriore e da Siri/Comandi Rapidi) girano in un processo separato dall'app principale. Il salvataggio locale andava a buon fine (da qui il messaggio "salvato!"), ma il loro `ctx.save()` non generava la notifica `ModelContext.didSave` osservata da `SyncService.recordChanges()` nel processo principale — quindi la transazione non veniva mai marcata come "da sincronizzare". Alla riapertura dell'app, la sequenza push→pull di `SyncService` trattava la transazione (mai arrivata su Supabase) come cancellata da un altro dispositivo e la eliminava anche in locale.
- **Fix**: aggiunto `SyncService.markTransactionDirty(_:)`, chiamato esplicitamente da entrambi gli Intent subito dopo `ctx.save()`, per marcare la transazione come dirty a prescindere dal processo in cui è stata creata (vedi `Sync/SyncService.swift`, `Intents/AddExpenseIntent.swift`).

### v3.2 (luglio 2026) — XCUITest e automazione notturna

- Nuovo target **MoneyTrackerUITests** (XCUITest) nel progetto Xcode, creato via script Ruby (`xcodeproj` gem) sul `project.pbxproj`
- 12 test UI in 4 classi: flusso movimenti, conti, categorie, e uno stress test di navigazione (tab switching rapido, apertura/chiusura ripetuta di fogli, aggiunta/eliminazione multipla)
- Aggiunto hook `MoneyTrackerApp.isUITesting` (`--uitesting` come launch argument): bypassa login Supabase, Face ID e tour di onboarding, forza la modalità demo con dati deterministici — nessuna chiamata di rete durante i test
- Aggiunti `accessibilityIdentifier` su tutti gli elementi interattivi chiave (campi, bottoni, swipe actions) in AddTransactionView, AccountsView, CategoryManagementView, SettingsView, TransactionsView, ContentView (FAB), BudgetView, GoalsView
- `TestPlan.xctestplan` aggiornato per includere il nuovo target
- **Routine notturna**: script `run_nightly_tests.sh` + LaunchAgent `com.moneytracker.nightlytests.plist` (fuori dal repo, in `~/Desktop/NightTestApp/`) — esegue i test ogni notte alle 4:00, corregge automaticamente il codice con Claude Code headless in caso di fallimento (fino a 5 tentativi), scrive `report_notturno.md` e apre una PR

### v3.1 (luglio 2026) — Riorganizzazione e documentazione

- Riorganizzata struttura cartella: Views/, Domain/, Models/, Auth/, Export/, Intents/, Debug/, Persistence/, Formatting/, OnboardingTour/, Sync/
- Eliminati file residui (.Rhistory, worktree stantio)
- Tutta la documentazione consolidata in questo unico file

### v3 (giugno–luglio 2026) — Enterprise audit e bug fix

**43 miglioramenti su 6 aree:**

- **FormatterCache**: eliminata allocazione `NumberFormatter`/`DateFormatter` per ogni render (hot path)
- **DashboardView**: `List` fissa → `LazyVStack` (Dynamic Type fix)
- **GoalsView**: `EmptyStateView`, VoiceOver, bug `load()` con "1000.0"
- **BudgetView**: `EmptyStateView`, VoiceOver su `BudgetRow`
- **AddTransactionView**: keyboard navigation con `@FocusState`
- **AddTransferView**: `.submitLabel(.done)` su importo
- **AddExpenseIntent**: `try!` → `try?` safe init (SEC-01 critico)
- **StatisticsView**: `CategoryStat.id` stabile, `shortMonthFormatted` via FormatterCache
- **TransactionsView**: `filteredSnapshot` per accesso centralizzato
- **NotificationManager**: alert saldo basso per singolo conto
- **SettingsView**: loading indicator CSV/PDF, toggle report mensile, animazioni spring
- **i18n**: sezione Siri localizzata in 6 lingue, accessibility labels con `String(localized:)`
- **QA**: rimossi 7 `print()` di debug da TabBarFrameCapture e TourOverlayView

### v2 (primavera 2026) — Feature complete

- Conti multipli con saldo attuale / saldo atteso
- Trasferimenti tra conti (inclusi pianificati)
- Budget per categoria con filtro per conto
- Obiettivi di risparmio
- Shortcut Apple (banner senza aprire l'app)
- Multi-lingua 7 lingue
- Statistiche mensili con grafici
- Esportazione CSV e PDF
- Ricorrenze automatiche (`recurringFrequency`)
- Biometria (Face ID / Touch ID)
- Onboarding tour (in sviluppo)

### v1 (inverno 2025) — Base

- Progetto iniziale: transazioni, categorie, saldo singolo conto

---

## 11. Workflow Checkpoint

Ogni volta che si fa un checkpoint significativo:

1. **Aggiorna questo documento** (`docs/MoneyTracker.md`) con le modifiche apportate
2. **Rigenera il PDF**: `cd /Users/matteo/Desktop/MoneyTracker && pandoc docs/MoneyTracker.md -o docs/MoneyTracker.pdf --pdf-engine=weasyprint`
3. **Commit e push**: `git add -A && git commit -m "checkpoint: [descrizione]" && git push`
4. **Aggiorna il grafo**: `/graphify --update` in Claude per aggiornare `graphify-out/`

---

*Documento unico — aggiornato ad ogni checkpoint · Generato con Claude (Anthropic)*
