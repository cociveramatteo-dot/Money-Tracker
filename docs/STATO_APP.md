# MoneyTracker — Stato Completo dell'Applicazione
*Documento tecnico-funzionale · Aggiornato: giugno 2026*

> **Come leggere questo documento**
> - ✅ = Implementato e funzionante nella versione attuale
> - ☐ = Non ancora implementato, pianificato
> - Ogni voce è descritta nel dettaglio: cosa fa, come funziona, dove si trova nell'app

---

## 1. Panoramica

**MoneyTracker** è un'app iOS nativa di finanza personale per il mercato italiano, costruita interamente in SwiftUI con SwiftData come layer di persistenza locale. Non richiede account, non invia dati a server esterni, non ha pubblicità. Funziona completamente offline. Il modello di business è acquisto una tantum.

**Stack tecnico attuale:**
- Linguaggio: Swift 5.9+
- UI Framework: SwiftUI
- Persistenza: SwiftData (modello locale on-device)
- Supporto iOS: iOS 17+
- Localizzazione: 7 lingue (IT, EN, ES, FR, DE, ZH, JA)
- Architettura: MVVM implicita, computed properties SwiftUI-native

---

## 2. Struttura dei file

| File | Ruolo |
|------|-------|
| `MoneyTrackerApp.swift` | Entry point, configurazione SwiftData container, seed categorie default |
| `Models.swift` | Modelli dati: Account, Transaction, Budget, Goal, Category + FormatterCache |
| `Theme.swift` | Design system completo: colori, tipografia, spacing, componenti riutilizzabili |
| `ContentView.swift` | Tab bar principale, pulsante "+" flottante, routing tra tab |
| `DashboardView.swift` | Home: saldo attuale, saldo atteso, ultimi movimenti |
| `TransactionsView.swift` | Lista movimenti con filtri, spese fisse, swipe actions |
| `AccountsView.swift` | Gestione conti, ordinamento, archiviazione |
| `AddTransactionView.swift` | Aggiunta/modifica di spese e entrate |
| `AddTransferView.swift` | Trasferimento tra conti (inclusi trasferimenti pianificati) |
| `BudgetView.swift` | Budget per categoria, con opzione filtro per conto specifico |
| `GoalsView.swift` | Obiettivi di risparmio con emoji, target, deadline |
| `StatisticsView.swift` | Statistiche mensili, grafici, confronto annuale, esportazione |
| `SettingsView.swift` | Impostazioni: valuta, lingua, tema |
| `CategoryManagementView.swift` | Gestione categorie personalizzate con SF Symbol |
| `CategoryClassifier.swift` | Classificazione automatica on-device via keyword matching |
| `NotificationManager.swift` | Notifiche locali per alert budget |
| `AddExpenseIntent.swift` | Integrazione con Apple Shortcuts (banner rapido) |

---

## 3. Modelli Dati

### ✅ Account
Rappresenta un conto bancario, carta, portafoglio o investimento.
- `id: UUID` — identificatore univoco
- `name: String` — nome del conto (es. "Carta Unicredit")
- `type: String` — tipo (conto corrente, carta di credito, contanti, investimento, ecc.)
- `initialBalance: Double` — saldo iniziale inserito dall'utente
- `isArchived: Bool` — se archiviato, non appare nelle liste attive
- `isExcludedFromTotal: Bool` — se escluso, non concorre al saldo totale in home
- `colorHex: String` — colore personalizzato (futuro uso visivo)
- Relazione con `transactions: [Transaction]` (cascade delete)
- Relazione con `budgets: [Budget]` (cascade delete)
- **Computed:**
  - `currentBalance` — saldo attuale (solo transazioni `isDone == true`)
  - `futureBalance` — saldo atteso (tutte le transazioni, incluse pianificate)
  - `plannedDelta` — differenza tra futuro e attuale

### ✅ Transaction
- `id: UUID`
- `name: String` — descrizione (es. "Affitto", "Stipendio")
- `amount: Double` — importo
- `date: Date` — data della transazione
- `type: String` — "expense" | "income"
- `isFixed: Bool` — se è una spesa/entrata fissa ricorrente
- `isDone: Bool` — se già effettuata (true = reale, false = pianificata)
- `isTransfer: Bool` — se fa parte di un trasferimento tra conti
- `transferGroupId: String` — UUID condiviso che collega le due gambe di un trasferimento (uscita + entrata)
- `category: String` — categoria assegnata
- `recurringFrequency: String` — frequenza di ricorrenza (vuoto = non ricorrente)
- `account: Account?` — relazione con il conto di appartenenza

### ✅ Budget
- `id: UUID`
- `category: String` — categoria a cui si applica
- `limit: Double` — limite mensile in valuta
- `account: Account?` — opzionale: limita il budget a un conto specifico

### ✅ Goal (Obiettivo)
- `id: UUID`
- `name: String`
- `emoji: String` — emoji selezionata dall'utente
- `targetAmount: Double` — importo obiettivo
- `currentAmount: Double` — importo risparmiato finora
- `hasDeadline: Bool`
- `deadline: Date?`

### ✅ Category
- `id: UUID`
- `name: String`
- `iconName: String` — nome SF Symbol
- `isDefault: Bool` — le categorie default non sono eliminabili

### ✅ FormatterCache (performance)
Singleton centralizzato per formatter costosi:
- `currencyFormatter()` — `NumberFormatter` currency, ricreato solo al cambio codice valuta
- `monthYear` — `DateFormatter("MMMM yyyy")` singleton
- `dayMonth` — `DateFormatter("d MMM")` singleton
- `shortMonth` — `DateFormatter("MMM")` singleton per grafici

---

## 4. Design System (Theme.swift)

### ✅ Palette colori semantica
- `DS.ink` — testo principale (adattivo: nero in light, bianco in dark)
- `DS.paper` — sfondo principale (bianco/nero)
- `DS.fog` — sfondo secondario (grigio chiarissimo)
- `DS.smoke` — testo secondario, label, placeholder

### ✅ Spacing
`DS.Space.xs / s / m / l / xl / xxl` — sistema di spacing a scala fissa per coerenza visiva tra le schermate.

### ✅ Componenti riutilizzabili
- `HeroAmount(amount:size:hidden:)` — importo in grande. Quando `hidden == true` mostra "• • •" al posto del numero
- `SectionLabel(text:)` — intestazione sezione in uppercase, letterspacing allargato
- `PrimaryButton(title:action:)` — bottone principale nero/bianco
- `GhostButton(title:action:)` — bottone secondario testo-only
- `ThinDivider()` — separatore sottile in `DS.fog`
- `DSTransactionRow(transaction:)` — riga transazione standard usata in home e in lista movimenti
- `MonthBar` — barra grafico mensile (usa FormatterCache per la label)

### ✅ Temi personalizzati
Il design system supporta temi (colori alternativi). Il `ThemePickerButton` appare in ogni tab come scorciatoia per cambiare tema.

### ✅ Modalità chiara e scura
Full support Light/Dark mode nativo SwiftUI, senza override manuali.

---

## 5. Navigazione e struttura

### ✅ Tab bar (5 tab)
1. **Home** (`DashboardView`) — saldo attuale, saldo atteso, ultimi movimenti
2. **Movimenti** (`TransactionsView`) — lista completa con filtri
3. **Budget** (`BudgetView`) — budget per categoria
4. **Obiettivi** (`GoalsView`) — obiettivi di risparmio
5. **Conti** (`AccountsView`) — gestione conti

### ✅ Pulsante "+" flottante
Appare sopra la tab bar in tutte le schermate. Apre un action sheet con:
- Aggiungi spesa
- Aggiungi entrata
- Trasferimento tra conti

---

## 6. Home (DashboardView)

### ✅ Saldo Attuale — Hero
- Saldo totale di tutti i conti **inclusi** (non esclusi, non archiviati), mostrato in grande (HeroAmount, font ~56pt bold)
- Label "SALDO ATTUALE" sopra il numero

### ✅ Chips dei conti sotto il saldo
- Riga orizzontale con i conti selezionati dall'utente, ognuno mostra: nome + saldo attuale
- **Scrollabile orizzontalmente** se i conti sono più di 4-5: `ScrollView(.horizontal)` senza indicatori
- **Pulsante `⊟` fisso a destra** come "muro": i chip scorrono ma non vanno sopra il pulsante
- Il pulsante apre il pannello di selezione e ordinamento conti

### ✅ Nascondi saldo (Privacy Mode)
- Pulsante occhio `👁` nella toolbar in alto a destra
- Quando attivo: HeroAmount mostra "• • •", le chips dei conti mostrano "• • •", il saldo atteso mostra "• • •"
- Stato persistito via `@AppStorage("hideBalance")` — sopravvive ai riavvii dell'app

### ✅ Selezione e ordinamento conti in home
- Pulsante `⊟` apre un sheet (`HomeAccountOrderSheet`)
- Lista di tutti i conti inclusi: checkbox (cerchio vuoto / checkmark pieno) + trascinamento per riordinare
- **Spuntare un conto lo sposta automaticamente in cima** alla lista (sopra gli altri già selezionati)
- Ordine e selezione persistiti via `@AppStorage("homeAccountOrderedShown")` come stringa di UUID separati da virgola
- Fallback: se la stringa è vuota, mostra i top-3 conti per saldo
- **Nuovo conto creato = automaticamente visibile in home** (aggiunto in testa alla stringa)

### ✅ Saldo Atteso (condizionale)
- Appare **solo se** `abs(totalFuture - totalCurrent) > 0.001`, cioè solo quando ci sono movimenti pianificati
- Mostra: saldo futuro totale (HeroAmount, font 48pt), delta (▲/▼ + importo + "in entrata/uscite pianificate")
- Se ci sono più conti: mostra per ogni conto il saldo futuro (solo quelli con delta > 0.001)
- Quando hideBalance è attivo: tutti gli importi diventano "• • •"

### ✅ Ultimi Movimenti (collassabile)
- Header "ULTIMI MOVIMENTI" con chevron su/giù: toccare l'header espande/collassa la sezione
- Default: **aperta**
- Animazione: `.spring()` sul toggle, `.opacity` sul contenuto (no slide per evitare overlap con le sezioni saldo)
- Mostra le **ultime 4 transazioni** non fisse, non trasferimento, non ricorrenti
- Implementata come `List` con `.scrollDisabled(true)` e `.frame(height: n * 62)` dentro la ScrollView principale
- **Swipe verso destra** → bottone "Modifica" (apre `AddTransactionView` in modalità edit)
- **Swipe verso sinistra** → bottone "Elimina" (elimina la transazione con haptic feedback)
- Stato vuoto: testo "Nessun movimento ancora. Premi + per aggiungere una spesa."

### ✅ Toolbar home
- **Sinistra**: pulsante tema (ThemePickerButton, eredita dal design system)
- **Destra**: pulsante occhio (hideBalance) + pulsante ingranaggio (SettingsView)

---

## 7. Movimenti (TransactionsView)

### ✅ Lista completa transazioni
- Tutte le transazioni ordinate per data (più recenti in cima)
- Ogni riga mostra: nome, categoria, data, importo, stato (✓ effettuato / grigio = pianificato)

### ✅ Filtri a due righe
- **Riga 1**: Tutti · Fisse · Trasf. · Uscite · Entrate
- **Riga 2**: tutte le categorie (predefinite + personalizzate dell'utente)
- I filtri si combinano (es. "Uscite" + "Cibo" = solo spese alimentari)

### ✅ Swipe actions — Spese fisse e Trasferimenti
- **Swipe destra**: bottone "Fatto" (se pianificata) o "Pianificato" (se già fatta) → toggle `isDone`
- Per i **trasferimenti**: il toggle aggiorna entrambe le gambe (uscita + entrata) che condividono `transferGroupId`
- **Swipe sinistra**: Elimina
- Per i **trasferimenti**: elimina entrambe le gambe

### ✅ Swipe actions — Spese/Entrate non fisse
- **Swipe destra**: bottone "Modifica" → apre `AddTransactionView` in modalità edit
- **Swipe sinistra**: Elimina
- **Tap sulla riga**: apre `AddTransactionView` in modalità edit

### ✅ Statistiche mensili rapide in header
- Totale entrate e uscite del mese corrente (filtrate per `isDone`)
- Cambio mese con frecce avanti/indietro

---

## 8. Aggiunta Transazione (AddTransactionView)

### ✅ Campi principali
- Nome/descrizione (con categorizzazione automatica on-device al cambio nome)
- Importo (tastierino numerico)
- Tipo: Uscita / Entrata
- Categoria (picker con tutte le categorie, accesso rapido a "Gestisci categorie")
- Conto (picker con tutti i conti attivi)
- Data (DatePicker)

### ✅ Toggle "Già effettuato"
- Se attivo → `isDone = true` → contribuisce al saldo attuale
- Se disattivo → `isDone = false` → contribuisce solo al saldo atteso
- Attivando "Spesa fissa", si disattiva automaticamente "Già effettuato"

### ✅ Toggle "Spesa fissa"
- Segna la transazione come `isFixed = true`
- Appare nella sezione spese fisse in `TransactionsView`

### ✅ Categorizzazione automatica (CategoryClassifier)
- Keyword matching on-device: analizza il nome inserito e suggerisce una categoria
- Nessuna rete, nessun dato inviato
- L'utente può sovrascrivere manualmente; se lo fa, il suggerimento non viene più applicato per quella transazione

### ✅ Reset form al riutilizzo
- Bug fix: aprire il form una seconda volta non porta valori residui dalla sessione precedente (`load()` resetta tutti i campi quando `editing == nil`)

---

## 9. Trasferimenti (AddTransferView)

### ✅ Trasferimento immediato
- Seleziona conto di origine ("Da") e destinazione ("A")
- Inserisci importo
- Genera due transazioni collegate: una uscita + una entrata, stessa data, stesso `transferGroupId`

### ✅ Trasferimento pianificato
- Toggle "Già effettuato" (default: attivo)
- Se disattivato: entrambe le gambe hanno `isDone = false` → appaiono in grigio nella lista, non influenzano il saldo attuale
- Bottone dinamico: "Trasferisci" (se effettuato) o "Pianifica" (se pianificato)
- `transferGroupId: String` — UUID generato al salvataggio, condiviso tra le due transazioni — permette di trovarle e aggiornare/eliminare insieme

---

## 10. Conti (AccountsView)

### ✅ Lista conti attivi
- Prima i conti **inclusi nel totale**, poi i conti **esclusi** (con badge "escluso")
- Ogni riga: nome, tipo, saldo attuale, freccia verso saldo futuro (se diverso)
- Implementata come `List` con `.scrollDisabled(true)` per abilitare swipe actions dentro una ScrollView

### ✅ Swipe actions
- **Swipe destra**: bottone "Modifica" → apre `AddAccountView` in edit
- **Swipe sinistra**: bottone "Elimina" (distruttivo, con haptic)

### ✅ Tap sulla riga
- Apre `AddAccountView` in modalità modifica

### ✅ Context menu (long press)
- Modifica
- Escludi/Includi dal totale (toggle)
- Archivia
- Elimina

### ✅ Conti archiviati
- Sezione separata in fondo, opacità ridotta al 35%
- Context menu: Ripristina / Elimina definitivamente

### ✅ Totale in hero
- Saldo attuale e "A conti fatti" (futuro) della somma dei conti inclusi

### ✅ Aggiunta/modifica conto (AddAccountView)
- Campo tipo (conto corrente, carta, contanti, investimento...)
- Nome
- Saldo iniziale
- Toggle "Escludi dal totale"
- Se conto nuovo e non escluso: viene aggiunto automaticamente alla home

---

## 11. Budget (BudgetView)

### ✅ Budget per categoria
- Limite mensile in valuta per ciascuna categoria
- Barra di avanzamento che mostra speso / totale
- Colore: verde se sotto soglia, rosso se superata

### ✅ Filtro per conto specifico
- Opzionale: il budget può essere limitato a un conto specifico invece di tutti i conti
- Utile per gestire spese per carta di credito separatamente

### ✅ Storico budget
- Sheet con storico degli ultimi mesi per ogni budget

### ✅ Notifiche alert
- `NotificationManager` invia notifiche locali quando si avvicina o si supera il limite di un budget

---

## 12. Obiettivi (GoalsView)

### ✅ Obiettivo di risparmio
- Nome + emoji (picker SF Symbol / emoji personalizzata)
- Importo target
- Importo attuale (con opzione "Aggiungi risparmio")
- Deadline opzionale
- Barra di avanzamento
- Percentuale completamento

### ✅ Reset form
- Bug fix: aprire il form per un nuovo obiettivo non porta valori dall'obiettivo precedente

---

## 13. Statistiche (StatisticsView)

### ✅ Grafico a torta per categoria
- Distribuzione delle uscite del mese per categoria
- Solo transazioni `isDone == true`

### ✅ Trend mensile (grafico a barre)
- Entrate vs uscite degli ultimi 6 mesi
- `MonthBar` con FormatterCache per le label

### ✅ Confronto annuale
- Spesa mese corrente vs stesso mese anno scorso
- Bug fix: non genera più percentuale doppio-negativa

### ✅ Esportazione PDF mensile
- Genera un PDF con il riepilogo del mese: transazioni, categorie, totali
- Bug fix: il PDF filtra correttamente solo le transazioni `isDone == true`
- Condivisibile via share sheet iOS

### ✅ Esportazione CSV
- Esporta tutte le transazioni del mese in formato CSV
- Apribile in Excel, Numbers, Google Sheets

---

## 14. Impostazioni (SettingsView)

### ✅ Valuta
- Cambio valuta (€, $, £, ¥, ecc.)
- Bug fix: il picker si aggiorna correttamente quando la valuta cambia dall'esterno (`onChange` su `savedCurrency`)
- `Double.currencySymbol` e `Double.currencyFormatted` usano dinamicamente la valuta selezionata (non più hardcoded "€")

### ✅ Lingua
- Cambio lingua in-app (7 lingue supportate)

### ✅ Tema
- Selezione tema colore (ThemePicker disponibile anche da ogni tab)

---

## 15. Shortcut / Widget rapido (AddExpenseIntent)

### ✅ Integrazione Apple Shortcuts
- Azione "Aggiungi spesa" disponibile nell'app Comandi di iOS
- Aggiungibile come widget su schermata home o schermata di blocco
- Inserisci nome e importo → salvato direttamente nel database senza aprire l'app
- Stessa UX di "Quanto: Expense Tracker"

---

## 16. Performance e qualità del codice

### ✅ FormatterCache — eliminazione allocazioni costose
- Prima: ogni chiamata a `.currencyFormatted` o `.monthYearFormatted` allocava un nuovo `NumberFormatter`/`DateFormatter`
- Ora: singleton condivisi, ricreati solo quando cambia la valuta o la locale

### ✅ Ordinamento account: esclusi in fondo
- Prima: `ForEach(active)` mescolava inclusi ed esclusi in ordine arbitrario
- Ora: `ForEach(included + excluded)` — esclusi sempre in fondo

### ✅ Dead code rimosso
- `CategoryClassifier.suggestions(for:max:)` — funzione identica a `classify(_:)`, mai chiamata, eliminata

### ✅ Bug fix AddTransactionView — categoria
- `categoryManuallyOverridden` e `suggestedCat` ora si resettano correttamente all'apertura del form vuoto

### ✅ Bug fix GoalsView — form reset
- Aprire "Nuovo obiettivo" dopo averne modificato uno non porta i vecchi valori

### ✅ Bug fix StatisticsView — PDF e percentuale
- Il PDF includeva transazioni non ancora effettuate (pianificate). Ora filtrate.
- La percentuale di confronto annuale non produceva più doppio segno negativo

### ✅ Bug fix SettingsView — picker valuta
- Il picker non si aggiornava se il valore cambiava via `@AppStorage` da un'altra schermata

---

## 17. UX / Interaction Design

### ✅ Haptic feedback
- Swipe "Modifica": haptic soft
- Swipe "Elimina": haptic medium
- Tutti i bottoni distruttivi: haptic medium

### ✅ Swipe actions uniformi su tutta l'app
| Contesto | Swipe destra | Swipe sinistra | Tap |
|----------|-------------|----------------|-----|
| Home – ultimi movimenti | Modifica | Elimina | — |
| Movimenti – spese fisse/trasferimenti | Fatto / Pianificato | Elimina | Modifica |
| Movimenti – spese/entrate normali | Modifica | Elimina | Modifica |
| Conti | Modifica | Elimina | Modifica |

### ✅ Animazioni
- Collapse "Ultimi movimenti": `.spring(response: 0.35, dampingFraction: 0.8)` sul toggle, `.opacity` sul contenuto (no slide: evita overlap con le sezioni saldo)
- Chevron: ruota animato con `.animation(.spring(...), value: showRecentMovements)`
- Hide balance: `.easeInOut(duration: 0.2)`

---

## 18. Localizzazione

### ✅ 7 lingue
- Italiano (primario)
- Inglese
- Spagnolo
- Francese
- Tedesco
- Cinese
- Giapponese

Tutte le stringhe UI sono localizzate. Le categorie di default hanno nomi localizzati.

---

---

# PARTE II — FEATURE DA IMPLEMENTARE

*Le sezioni seguenti descrivono tutto ciò che è stato pianificato ma non ancora sviluppato. Ordinate per priorità strategica.*

---

## LIVELLO 2 — Necessario per essere competitivi

---

### ☐ Tour di onboarding / Discoverability

**Problema:** un utente che apre l'app per la prima volta non sa dove iniziare, non capisce la differenza tra saldo attuale e saldo atteso, non trova le funzioni avanzate (es. spese fisse, trasferimenti pianificati).

**Cosa serve:**
- **Schermata di benvenuto** (prima apertura): 3-4 slide che spiegano il concetto chiave ("saldo attuale vs saldo atteso"), come aggiungere un conto, come funzionano le spese fisse.
- **Tooltip contestuali** (prima volta in ogni sezione): una freccia con testo che punta al componente rilevante. Appare una sola volta, poi scompare. Flag per sezione salvato in `@AppStorage`.
- **Note:** una versione del tour è stata progettata e poi cancellata perché causava errori di compilazione. Va rifatta in modo più stabile, senza `ObservableObject` separato, usando un `@State` o `@AppStorage` semplice.

---

### ☐ Widget schermata Home e Lock Screen

**Problema:** l'utente deve aprire l'app per vedere il saldo. Le app concorrenti (Wallet, Revolut) mostrano il saldo in un colpo d'occhio dalla schermata home.

**Cosa serve (WidgetKit):**
- **Widget piccolo (schermata home):** saldo attuale totale. Si aggiorna ogni volta che si apre l'app.
- **Widget medio:** saldo attuale + quanto resta del budget oggi (o questo mese).
- **Widget schermata di blocco (Lock Screen):** ultima spesa inserita, o saldo attuale in formato compatto.
- **Tecnica:** `AppGroup` condiviso tra app e widget extension per accedere al database SwiftData (o a uno snapshot UserDefaults aggiornato dall'app).

---

### ✅ Ricorrenze automatiche

- Campo "Ripeti ogni" in `AddTransactionView`: mai / giornaliero / settimanale / mensile / annuale
- `Transaction.recurringFrequency: String` nel modello dati
- `processRecurring()` in `Models.swift`: al lancio dell'app scorre tutte le transazioni ricorrenti, genera automaticamente la nuova occorrenza se la data di prossima ricorrenza è passata
- La nuova transazione viene creata come `isDone = false` (pianificata) fino a conferma dell'utente

---


### ☐ Apple Watch App

**Problema:** aggiungere una spesa richiede di sbloccare il telefono, aprire l'app, navigare al form.

**Cosa serve (watchOS target):**
- Schermata principale: saldo attuale (grande)
- Pulsante "+": 3 step — nome (dettatura o lista recenti), importo (rotella digitale), conferma
- Sincronizzazione via `WatchConnectivity` (sessione WCSession)
- Design: massima semplicità, nessun grafico

---

---

## LIVELLO 3 — Feature WOW (differenziazione totale)

---

### ☐ Connessione Bancaria Automatica (Open Banking / PSD2)

**Problema:** il motivo principale per cui gli utenti abbandonano le app di finanza dopo 2 settimane è l'inserimento manuale delle transazioni. Zero attrito = zero abbandono.

**Soluzione tecnica:**
- **GoCardless / Nordigen API** (ex Nordigen, ora GoCardless Bank Account Data): gratuito per uso personale, copre oltre 2.300 banche europee incluse Intesa Sanpaolo, UniCredit, Fineco, BancoBPM, ING Direct, Poste Italiane, Banca Mediolanum, Widiba
- Flusso: l'utente seleziona la propria banca → viene reindirizzato alla pagina di consenso della banca (OAuth) → autorizza → il token viene salvato in modo sicuro (Keychain) → le transazioni vengono scaricate automaticamente
- Le transazioni importate vengono categorizzate automaticamente via `CategoryClassifier`
- L'utente può correggere manualmente la categoria
- Sincronizzazione: ogni apertura dell'app (o in background se si attiva Background App Refresh)
- **Privacy:** i dati bancari non transitano sui server di MoneyTracker. Il token è memorizzato nel Keychain del dispositivo.

---

### ☐ "Me lo posso permettere?" — Shortcut Conversazionale

**Problema:** ogni volta che si vuole fare un acquisto bisogna aprire l'app, guardare il budget, guardare il saldo, fare conti a mente.

**Soluzione:**
- L'utente scrive (o detta via Siri) "scarpe 150 euro" in una barra di ricerca rapida
- L'app risponde in 2 secondi con una card:
  - ✅ "Sì. Ti resterebbero €634 questo mese, il budget Shopping è ancora ok, raggiungeresti comunque l'obiettivo Vacanze."
  - ❌ "No. Andresti €43 sopra il budget Shopping. Se aspetti venerdì (dopo lo stipendio) puoi permettertele."
- La risposta tiene conto di: saldo attuale, budget di categoria, movimenti pianificati per il mese, obiettivi di risparmio
- Implementazione: motore di regole locale (nessun AI esterno necessario per la versione base)

---

### ☐ AI Financial Coach — Report Mensile Automatico

**Soluzione:**
- Il 1° di ogni mese (notifica locale) l'app genera una card-riepilogo:
  - Totale speso vs mese precedente (delta %, trend emoji)
  - Categoria più costosa (e variazione percentuale)
  - Momento della settimana statisticamente più costoso
  - Proiezione: "Al ritmo attuale, raggiungerai l'obiettivo X a [data]"
  - Abbonamenti non usati: "Hai pagato [servizio] ma non l'hai usato da N giorni"
- Tutto calcolato on-device, nessun server
- Opzionalmente: `askClaude()` (Claude Haiku via API) per una sintesi in linguaggio naturale personalizzata

---

### ☐ Tracker Abbonamenti Intelligente

**Problema:** gli abbonamenti si accumulano invisibilmente. È una delle ricerche più frequenti su App Store italiano.

**Soluzione:**
- Sezione dedicata (tab o sotto-sezione in Movimenti) che mostra tutti i pagamenti ricorrenti rilevati automaticamente
- Rilevamento: transazioni con stesso nome e importo che si ripetono ogni 30±2 giorni (o 7, o 365)
- Per ogni abbonamento: nome, importo mensile, costo annuale, data prossimo addebito, icona brand (se riconosciuta)
- Alert: "Non hai usato questa app da N giorni — stai pagando €X/mese" (basato su dati di utilizzo device, se autorizzato)
- Totale mensile e annuale di tutti gli abbonamenti

---

### ☐ Punteggio Salute Finanziaria (Financial Health Score)

**Soluzione:**
- Un numero da 0 a 100, aggiornato ogni settimana, basato su:
  - **Rispetto budget** (25 pt): quante categorie sono sotto la soglia questo mese?
  - **Avanzamento obiettivi** (25 pt): stai avanzando a ritmo sufficiente verso i tuoi obiettivi?
  - **Fondo emergenza** (20 pt): hai almeno 3 mesi di spese medie come riserva?
  - **Controllo spese fisse** (15 pt): le spese fisse sono sotto il 50% del reddito?
  - **Tasso di risparmio** (15 pt): stai risparmiando almeno il 10% delle entrate?
- Widget dedicato in home che mostra il punteggio con colore (rosso/giallo/verde) e trend (↑↓)
- Spiegazione dettagliata di ogni componente

---

### ☐ Modalità Coppia / Famiglia

**Problema:** le coppie non hanno un modo semplice di gestire le finanze condivise senza usare un foglio Excel o un'app separata.

**Soluzione:**
- Due account (iPhone distinti) che condividono lo stesso database
- Sincronizzazione via iCloud (CloudKit) o Supabase
- Vista "Chi ha speso cosa": attribuisce ogni transazione all'utente che l'ha inserita
- Budget condivisi: es. "Budget Vacanze di Coppia"
- Obiettivi condivisi: "Casa" con contributi di entrambi
- Notifica: "Mario ha appena speso €34 al supermercato"

---

### ☐ Split Spese Integrato

**Problema:** le uscite in gruppo (ristorante, vacanze, regali) generano crediti/debiti informali che si perdono.

**Soluzione:**
- Inserisci una spesa → attiva "Dividi con" → selezioni i partecipanti (da Contatti iOS)
- L'app calcola la quota per ciascuno
- Invia automaticamente un messaggio via iMessage/WhatsApp con il resoconto (es. "Mario ti deve €22,50 per cena sabato")
- Dashboard "Saldo con amici": chi ti deve cosa, a chi devi cosa
- Quando ricevi un rimborso: segna come "Saldato" → aggiorna il saldo

---

### ☐ Calendario Flusso di Cassa

**Soluzione:**
- Vista calendario mensile (stile iOS Calendar)
- Ogni giorno mostra: icona rossa (uscite pianificate) e/o verde (entrate pianificate)
- Tocca un giorno: vedi la lista di movimenti previsti per quel giorno
- Proiezione saldo giorno-per-giorno: se il saldo scende sotto zero in un giorno futuro, il giorno diventa rosso con alert

---

### ☐ Tracciatore Patrimonio Netto (Net Worth)

**Soluzione:**
- Sezione separata o tab aggiuntiva
- **Attivi:** conti bancari (sincronizzati automaticamente dall'app) + investimenti (inseriti manualmente o via API broker) + immobili (valore stimato inserito manualmente)
- **Passivi:** mutuo (saldo residuo), prestito auto, carte di credito
- **Patrimonio Netto = Attivi - Passivi**
- Grafico crescita nel tempo (mensile)
- Primo obiettivo: patrimonio netto positivo. Secondo: 6 mesi di spese. Terzo: 1 anno.

---

### ☐ Feature Fiscali Italiane (Unicità assoluta)

Nessuna app straniera le implementa. Nessuna app italiana le fa correttamente.

**☐ Bollette Tracker**
- Sezione dedicata per luce, gas, acqua, internet
- Per ogni bolletta: storico importi, media degli ultimi 12 mesi, previsione prossima bolletta (media mobile)
- Alert: "Questa bolletta è il 40% più alta della media"

**☐ F24 Tracker**
- Scadenze fiscali italiane (IRPEF acconto/saldo, INPS autonomi, IMU, TARI) precaricate
- Promemoria N giorni prima della scadenza (notifica locale)
- Inserimento importo stimato per ogni scadenza

**☐ Detrazioni Fiscali**
- Categorie contrassegnate come "detraibile" (farmacia, medico specialista, palestra under 26, asilo nido, veterinario, ecc.)
- Totale detraibile accumulato nell'anno fiscale
- Stima rimborso (19% per la maggior parte delle detrazioni)
- Export dedicato per il CAF / commercialista

**☐ 730 Helper**
- A fine anno: "Hai €X di spese detraibili. Stima rimborso: €Y. Documenti da conservare: [lista]"
- Reminder: "Hai inserito spese mediche per €340 — ricordati di tenere le ricevute"

**☐ TFR Tracker**
- Per dipendenti: stima del TFR maturato (basata su RAL inserita dall'utente)
- Aggiornamento annuale automatico
- Confronto: TFR in azienda vs TFR in fondo pensione (simulazione)

---

### ☐ Modalità "Stipendio → Zero" (Zero-Based Budgeting)

**Problema:** la maggior parte delle persone non sa dove va a finire il proprio stipendio.

**Soluzione:**
- Attivabile come modalità alternativa al budget classico
- Al momento del primo stipendio del mese: wizard guidato che assegna ogni euro a una categoria
- Schermata: "Hai €2.000 da assegnare. Quanto metti per [categoria]?" con slider o input numerico
- Il totale assegnato deve raggiungere €0 non assegnati
- Dashboard: barra per categoria con quanto assegnato vs quanto già speso
- Metodologia: identica a YNAB (You Need A Budget) ma gratuita e in italiano

---

### ☐ Sync Cross-Device (Supabase)

**Problema:** l'app funziona solo su un iPhone. Se si cambia dispositivo, si perdono tutti i dati. iPad non è supportato.

**Soluzione:**
- Backend: Supabase (PostgreSQL hosted, open source, GDPR compliant, server EU)
- Account: login con Apple ID o email
- Sync automatico in background: ogni modifica → push immediato al server
- Modalità offline completa: tutte le operazioni funzionano senza rete, con sync alla ricezione della connessione
- Conflitti: last-write-wins con timestamp lato server
- Crittografia: dati cifrati in transito (TLS) e a riposo (AES-256)
- Multi-device: iPhone + iPad + eventuali altri dispositivi con lo stesso account
- Privacy: i dati non vengono usati per training o analisi. Politica esplicita.

---

---

## LIVELLO 4 — Futuro

### ☐ Investimenti automatici
Collegamento a broker italiani (Directa, Fineco trading) via API per importare automaticamente il valore del portafoglio azionario/ETF. Aggiornamento giornaliero del valore nel Tracciatore Patrimonio Netto.

### ☐ Crypto Wallet Tracker
Inserimento indirizzi wallet (o API exchange) per monitorare il valore del portafoglio crypto in tempo reale. Incluso nel calcolo del patrimonio netto.

### ☐ FIRE Calculator
"Quando posso andare in pensione anticipata?" — basato su: patrimonio attuale, tasso di risparmio mensile, rendimento atteso, spesa annuale prevista in pensione (regola del 4%). Grafico interattivo con scenario ottimista/realistico/pessimista.

### ☐ "Boomerang" — Confronto stesso periodo anno scorso
Già presente una versione base in StatisticsView. La feature completa prevede: confronto settimana, mese, trimestre vs stesso periodo anno precedente, con delta percentuale e trend per categoria.

### ☐ Spesa Emotiva
Campo facoltativo "Come ti senti?" al momento dell'inserimento spesa (5 emoji: 😔😐😊😁🤩). Report mensile: "Spendi di più quando sei stressato (±23% rispetto alla media)". Completamente privato, mai inviato.

### ☐ Marketplace Partner
Offerte personalizzate da banche e assicurazioni italiane basate sul profilo finanziario anonimizzato dell'utente. Entrata pubblicitaria opzionale e non invasiva. L'utente sceglie se partecipare.

### ☐ API Pubblica
Per sviluppatori: endpoint REST per leggere i propri dati da app terze (es. dashboard custom, integrazione con strumenti di produttività). OAuth 2.0.

---

---

## 19. Modello di Business

### Attuale
- Distribuzione: **App Store** (TestFlight durante sviluppo)
- Costo: sviluppo personale, nessun costo operativo (nessun server, nessun backend)
- Distribuzione con Apple ID personale: certificato valido 7 giorni, va rinnovato manualmente

### Pianificato al lancio
- **Acquisto una tantum: €4,99**
- Accesso completo a tutte le funzionalità base
- Nessun abbonamento, nessuna pubblicità, nessun dato venduto
- Posizionamento: "Paghi una pizza, gestisci i soldi per sempre"

### Futuro (monetizzazione aggiuntiva)
- **Piano Premium opzionale: €1,99/mese**
  - Connessione bancaria automatica (costo API GoCardless incluso)
  - AI Financial Coach con sintesi Claude Haiku
  - Sync cross-device Supabase
  - Modalità Coppia/Famiglia
- **Marketplace Partner**: opt-in, non invasivo

---

## 20. Roadmap di Sviluppo

| Fase | Durata stimata | Contenuto |
|------|---------------|-----------|
| **Fase 1 — Stabile** | ✅ Completata | Design system, CRUD completo, swipe actions, statistiche, export, bug fix, performance |
| **Fase 2 — Competitiva** | 4-6 settimane | Tour onboarding, ricorrenze automatiche, widget, Face ID, Apple Watch |
| **Fase 3 — WOW** | 2-3 mesi | Open Banking, "Me lo posso permettere?", tracker abbonamenti, calendario flusso cassa, sync Supabase |
| **Fase 4 — Dominante** | 3-6 mesi | AI coach, modalità coppia, split spese, patrimonio netto, feature fiscali italiane, zero-based budgeting |
| **Fase 5 — Pubblicazione** | 1 mese | App Store submission, campagna TikTok/Instagram, contenuti finanza personale |

---

## 21. Posizionamento

> *"L'unica app italiana che conosce le tue banche, capisce le tue abitudini, e ti dice esattamente cosa puoi permetterti — adesso."*

**Differenziatori chiave:**
- **Italiana di design e cultura**: non una traduzione di un'app americana. Pensata per conti italiani, banche italiane, fisco italiano.
- **Completamente offline** (oggi): zero dipendenza da server, zero rischio di shutdown.
- **Una tantum**: in un mercato dominato da abbonamenti, il pagamento unico è un messaggio di fiducia.
- **Privacy radicale**: nessun dato condiviso, nessuna pubblicità, nessun tracking.
- **Design minimale**: non caotica, non spaventosa. Funziona anche per chi non ha mai usato un'app di finanza.

---

*Documento generato e mantenuto in collaborazione con Claude (Anthropic) · Aggiornato progressivamente a ogni sessione di sviluppo*
