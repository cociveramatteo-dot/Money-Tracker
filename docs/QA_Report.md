# QA Report — MoneyTracker
**Data**: 30 giugno 2026  
**Scope**: Performance, bug silenti, i18n — nessuna modifica grafica o funzionale  
**File analizzati**: 25 Swift, 7 file .strings (it/en/de/fr/es/ja/zh-Hans)

---

## REPORT A — Performance & Bug Fix

### BUG-01 · `CategoryStat.id` genera un UUID nuovo ad ogni render  
**File**: `StatisticsView.swift:545`  
**Gravità**: 🔴 Alta — rompe il diffing di SwiftUI

`let id: String = UUID().uuidString` viene eseguito ogni volta che SwiftUI ricostruisce un `CategoryStat` (ad ogni aggiornamento del grafico). `ForEach` riceve ID completamente nuovi e non può distinguere righe inserite/rimosse da righe esistenti: tutte le animazioni saltano, VoiceOver perde il focus ad ogni refresh.

```swift
// PRIMA (bug)
struct CategoryStat: Identifiable {
    let id: String = UUID().uuidString   // nuovo UUID ad ogni istanza

// DOPO (fix applicato)
struct CategoryStat: Identifiable {
    var id: String { name }   // stabile: i nomi categoria sono unici nel dataset
```
✅ **Fix applicato.**

---

### BUG-02 · `print()` di debug in produzione  
**File**: `OnboardingTour/TabBarFrameCapture.swift` (5 print), `OnboardingTour/TourOverlayView.swift` (2 print)  
**Gravità**: 🟡 Media — console noise, minimo overhead su hot-path layout

`TabBarFrameCapture.capture()` viene chiamato ad ogni `layoutSubviews()`, ovvero ad ogni resize / rotazione. Stampare a console in questo metodo aggiunge latenza misurabile su dispositivi A-series datati.

```swift
// Rimossi tutti i print() e la funzione helper printSubviews(of:depth:win:)
// — nessuna modifica alla logica di cattura frame
```
✅ **Fix applicato.** Rimossi 7 `print()` e la funzione `printSubviews` da TabBarFrameCapture.

---

### PERF-01 · `@Query` senza limite in DashboardView carica tutto in memoria  
**File**: `DashboardView.swift:8`  
**Gravità**: 🟡 Media — latenza percepibile con dataset grandi (>1000 tx)

```swift
// ATTUALE — carica TUTTE le transazioni, poi .prefix(4) lato client
@Query(sort: \Transaction.date, order: .reverse) private var transactions: [Transaction]

// RACCOMANDATO — limit a 20, più che sufficiente per recentNormal (prefix 4) e filtri aggiuntivi
@Query(FetchDescriptor<Transaction>(
    sortBy: [SortDescriptor(\Transaction.date, order: .reverse)],
    fetchLimit: 20
)) private var transactions: [Transaction]
```
⚠️ **Non applicato** — questo refactoring richiede di tipizzare `@Query` con `FetchDescriptor` esplicito e di verificare che nessun'altra computed var della view (oltre a `recentNormal`) dipenda dall'array completo. Da applicare come task separato dopo una verifica.

---

### PERF-02 · `AccountsView.partitioned` calcolato due volte per render  
**File**: `AccountsView.swift`  
**Gravità**: 🟢 Bassa — max ~50 account realistici, impatto trascurabile

```swift
// Le computed var active e archived chiamano entrambe partitioned,
// che itera tutti gli account due volte per render.
private var active:   [Account] { partitioned.active }   // chiama partitioned
private var archived: [Account] { partitioned.archived } // chiama partitioned di nuovo
```

Fix futuro (opzionale):
```swift
// Aggiungere una sola property che calcola entrambi in un passaggio:
private var split: (active: [Account], archived: [Account]) { partitioned }
// oppure usare @State + onChange per caching esplicito
```
⚠️ **Non applicato** — impatto minimo, nessuna urgenza.

---

## REPORT B — i18n Refactoring

### Architettura confermata corretta ✅

Prima di elencare i bug, confermo che l'architettura i18n è solida:

| Componente | Status |
|---|---|
| `SectionLabel(text: LocalizedStringKey)` | ✅ parametro è `LocalizedStringKey` |
| `Text("literal")` in SwiftUI | ✅ automaticamente `LocalizedStringKey` |
| `.navigationTitle("literal")` | ✅ prende overload `LocalizedStringKey` |
| `Text(LocalizedStringKey(rawValue))` nei segmenti | ✅ corretto |
| Tema rawValue → `Text(LocalizedStringKey(theme.rawValue))` | ✅ corretto |
| Parità chiavi de/fr/es/ja/zh-Hans ↔ en | ✅ 329/329 chiavi (prima del fix) |
| it.lproj (lingua sviluppo, chiave = stringa) | ✅ design corretto |

---

### i18n BUG-01 · Sezione Siri in SettingsView — 5 stringhe mancanti da tutti i file .strings  
**File**: `SettingsView.swift`, tutti i file `.lproj`  
**Gravità**: 🔴 Alta — la sezione Siri non viene mai tradotta in nessuna lingua

La sezione Siri & Shortcut è stata aggiunta di recente ma le chiavi non sono mai state aggiunte ai file di localizzazione. Per gli utenti in inglese/tedesco/francese/etc. vedono testo italiano fisso.

**Stringhe aggiunte a tutti e 6 i file di traduzione (en/de/fr/es/ja/zh-Hans):**

| Chiave italiana | EN | DE |
|---|---|---|
| `"Siri & Shortcut"` | "Siri & Shortcuts" | "Siri & Kurzbefehle" |
| `"Aggiungi spese senza aprire l'app..."` | "Add expenses without opening the app..." | "Ausgaben hinzufügen ohne die App zu öffnen..." |
| `"Apri Shortcut"` | "Open Shortcuts" | "Kurzbefehle öffnen" |
| `"Configura tocco sul retro"` | "Set up Back Tap" | "Tippen auf Rückseite einrichten" |
| `"Crea una Shortcut in Shortcut, poi vai in..."` | "Create a Shortcut in the Shortcuts app, then go to..." | "Erstelle einen Kurzbefehl in der Kurzbefehle-App, dann..." |

✅ **Fix applicato.** Aggiunte 10 chiavi (5 Siri + 5 accessibility) a tutti i 6 file traduzione. Tutti i locale ora a 340 chiavi.

---

### i18n BUG-02 · Accessibility labels costruite con string interpolation italiana  
**File**: `Theme.swift`  
**Gravità**: 🔴 Alta — VoiceOver parla sempre in italiano indipendentemente dalla lingua del device

Il modificatore `.accessibilityLabel({ ... }())` che riceve una closure che ritorna `String` usa l'overload `<S: StringProtocol>` — non viene mai localizzato. Le parole italiane hard-coded dentro la closure non passano per il sistema di traduzione.

#### DSTransactionRow (fix applicato)
```swift
// PRIMA (non localizzato)
.accessibilityLabel({
    let dir = transaction.transactionType == .uscita ? "Uscita" : "Entrata"
    let amt = (transaction.transactionType == .uscita ? "meno " : "più ") + ...
    let status = transaction.isDone ? "" : ", pianificato"
    return "\(name), \(dir), \(amt), \(category), \(date)\(status)"
}())

// DOPO (fix applicato)
.accessibilityLabel({
    let dir    = transaction.transactionType == .uscita
        ? String(localized: "Uscita")
        : String(localized: "Entrata")
    let prefix = transaction.transactionType == .uscita
        ? String(localized: "meno ")
        : String(localized: "più ")
    let amt    = prefix + transaction.amount.currencyFormatted
    let status = transaction.isDone ? "" : ", \(String(localized: "pianificato"))"
    return "\(transaction.name), \(dir), \(amt), \(transaction.category), \(transaction.date.dayMonthFormatted)\(status)"
}())
```

#### FixedExpenseRow (fix applicato)
```swift
// PRIMA
let dir = isIncome ? "entrata fissa" : "spesa fissa"

// DOPO
let dir = isIncome
    ? String(localized: "Entrata fissa")
    : String(localized: "Spesa fissa")
```

#### AccountRow (fix applicato in AccountsView.swift)
```swift
// PRIMA
let excluded = account.isExcludedFromTotal ? ", escluso dal totale" : ""
return "\(account.name), \(account.accountType.localizedName), saldo \(...)..."

// DOPO
let excluded = account.isExcludedFromTotal
    ? ", \(String(localized: "escluso dal totale"))"
    : ""
return "\(account.name), \(account.accountType.localizedName), \(String(localized: "saldo")) \(...)..."
```

#### HeroAmount.accessibilityLabel (fix applicato in Theme.swift)
```swift
// PRIMA — il ternario produce String, non LocalizedStringKey
.accessibilityLabel(hidden ? "Saldo nascosto" : amount.currencyFormatted)

// DOPO — forza la ricerca in .strings
.accessibilityLabel(hidden ? String(localized: "Saldo nascosto") : amount.currencyFormatted)
```

✅ **Fix applicato** a tutti e 4 i punti in Theme.swift e AccountsView.swift.

---

## Riepilogo modifiche applicate

| File | Modifica |
|---|---|
| `StatisticsView.swift` | BUG-01: `CategoryStat.id` → computed var stabile |
| `TabBarFrameCapture.swift` | BUG-02: rimossi 5 `print()` + funzione `printSubviews` |
| `TourOverlayView.swift` | BUG-02: rimossi 2 `print()` |
| `Theme.swift` | i18n: 3 accessibility labels localizzate + HeroAmount |
| `AccountsView.swift` | i18n: AccountRow accessibility label localizzata |
| `en.lproj/Localizable.strings` | +10 chiavi (Siri + accessibility) |
| `de.lproj/Localizable.strings` | +10 chiavi tradotte in tedesco |
| `fr.lproj/Localizable.strings` | +10 chiavi tradotte in francese |
| `es.lproj/Localizable.strings` | +10 chiavi tradotte in spagnolo |
| `ja.lproj/Localizable.strings` | +10 chiavi tradotte in giapponese |
| `zh-Hans.lproj/Localizable.strings` | +10 chiavi tradotte in cinese semplificato |

**Non applicato (richiede verifica separata):**
- PERF-01: `@Query` con `FetchDescriptor` + `fetchLimit: 20` in DashboardView
- PERF-02: deduplication di `AccountsView.partitioned` (impatto trascurabile)
