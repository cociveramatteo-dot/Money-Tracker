# Progetto esecutivo S-70 — Doppio tap (categorie) + Simulazione «E se…?»

> Architetto (Claude Code · Opus) · 2026-11-26 · ramo `redesign-sentiero`.
> Esecutore: **Codex in UNA sessione** (`codex --yolo -C /Users/matteo/Desktop/APP/MoneyTracker`). Collaudo: capocantiere + `collaudatore`.
> Le due richieste sono di Matteo e vanno rispettate alla lettera (testo originale in §0).
> **Aggiornato 2026-11-26 con le risposte di Matteo:** autorizza Intents/ per S-70; stessa lista categorie anche per le ENTRATE
> (S-70a2); conti esclusi dal totale selezionabili nella simulazione.

---

## 0. Richieste di Matteo (testo vincolante)

**A — Doppio tap posteriore: categoria suggerita e ultima usata in cima alla lista.**
Quando aggiungo un movimento col doppio tap, nella lista delle categorie: (1) prima riga la categoria SUGGERITA dal nome che ho
scritto (se l'app la riconosce); (2) seconda riga l'ULTIMA categoria USATA (in assoluto, non per nome); (3) sotto, tutte le categorie
come sono ora, stesso ordine. Regole: suggerita = ultima usata → una riga sola; né suggerimento né storico → la lista parte da «tutte»;
**la categoria che scelgo io vince sempre su quella indovinata** (oggi è al contrario). Ripiego se iPhone non aggiorna la lista: domanda
di conferma con la suggerita già pronta.

**B — Simulazione «E se…?» (calcolatrice rapida).** Home, intestazione, nuovo quadratino con icona calcolatrice; ordine da destra:
impostazioni, occhio, calcolatrice. Scrivo ipotesi veloci (−150 € cena, +350 € lavoretto) e vedo subito l'effetto sui miei soldi veri.
Niente grafico. Menu conto in alto «Tutti» o un conto solo; lista di ipotesi (importo con − / +, nome, interruttore); «+ aggiungi
ipotesi»; in basso: saldo di OGGI e saldo atteso a FINE MESE, ognuno «ora → con le ipotesi», e differenza totale. Le ipotesi non hanno
data, spariscono alla chiusura, non toccano mai i dati veri. Rispetta «oscura importi», 7 lingue, chiaro/scuro, testo grande.
Fuori da questa sessione: «Trasforma in movimento».

**Risposte di Matteo (2026-11-26, vincolanti):**
1. Autorizza Codex a toccare `Intents/` per S-70 (Codex lo registra in DECISIONI come primo passo).
2. SÌ anche per le ENTRATE col doppio tap: `AddIncomeIntent` deve avere la stessa lista (Suggerita / Ultima usata = ultima ENTRATA /
   Tutte), stesse regole, la scelta dell'utente vince. Parametro aggiunto nel modo meno invasivo, comportamento attuale come ripiego
   (oggi «Lavoro» o la prima categoria).
3. SÌ, i conti ESCLUSI dal totale compaiono nel menu della simulazione (es. soldi messi da parte). «Tutti» resta il totale della Home
   (esclusi fuori); gli esclusi selezionabili singolarmente con saldo di oggi e atteso fine mese presi da dove l'app li calcola già.
   Gli archiviati restano fuori.

---

## 1. Sintesi e fattibilità

- **Fattibile in una sessione: sì.** Stima Codex: A spese ≈ 1 h, A entrate ≈ 45 min, B ≈ 2,5–3 h, test + screenshot + chiusura
  ≈ 45 min → **≈ 5–5,5 h**. Tre commit: S-70a (spese + helper comune), S-70a2 (entrate), S-70b (simulazione).
- **A** si fa tutto dentro `Intents/` (zona intoccabile sbloccata da Matteo solo per S-70a) riusando due funzioni pure già esistenti
  in `Domain/` (`LastUsedCategory.suggest`, `KeywordCategoryClassifier.classify`), che si **chiamano ma non si modificano**.
- **B** è una schermata nuova che riceve dalla Home i saldi **già calcolati** (stessi numeri di hero e schede conto): nessun calcolo
  nuovo sui dati, Domain/ intatto. L'unica aritmetica nuova (somma delle ipotesi, `Decimal`) sta in un tipo puro testabile.
- **Rischio principale (A):** non è garantito che Comandi rilegga il `name` appena scritto quando mostra «Chiedi ogni volta».
  Si verifica **solo sul telefono vero**; se fallisce, task condizionale **S-70c** (ripiego già specificato in §2.8).
- **D-014 (prima il mockup):** questa sezione §3.3 è la specifica visiva; Codex produce gli screenshot; **Matteo li approva prima del
  merge su `main`** (task **S-70d**). Stesso schema già usato per S-60 (DECISIONI 2026-11-24). Il codice resta sul ramo finché non c'è ✅.
- Parità Android: task futuro (non incluso).

---

## 2. FUNZIONE A — S-70a · Doppio tap: categoria scelta vince, suggerita e ultima usata in cima

### 2.1 Autorizzazione (primo passo della sessione)
Aggiungere in `.cantiere/DECISIONI.md` una voce:
`## 2026-11-2x · S-70 · Autorizzazione Intents/ e gestione D-014` — Matteo (2026-11-26) autorizza a modificare
`MoneyTracker/Intents/AddExpenseIntent.swift` (spese ed entrate) e ad aggiungere un file nuovo in `MoneyTracker/Intents/`, solo per S-70a/S-70a2.
D-014 per S-70b: specifica visiva in questo progetto + screenshot, approvazione di Matteo prima del merge (S-70d).
Più le decisioni §2.3 (definizione di «ultima usata» per tipo, fonte della suggerita, parametro nuovo per le entrate) e §3.2 (conti esclusi nel menu).

### 2.2 File
| File | Azione |
|---|---|
| `MoneyTracker/Intents/IntentCategoryMenu.swift` | **NUOVO** — tipo puro (enum, `nonisolated static`) + loader SwiftData |
| `MoneyTracker/Intents/AddExpenseIntent.swift` | S-70a: modificare SOLO `CategoryOptionsProvider`, il blocco «Smart category logic» di `AddExpenseIntent.perform()` e il commento sopra `categoryName`. S-70a2: in `AddIncomeIntent` aggiungere il parametro `categoryName` (§2.9), il suo provider, la voce nel `parameterSummary` e sostituire il blocco che sceglie `incCatName` |
| `MoneyTracker/*.lproj/Localizable.strings` (7) | 3 chiavi nuove (§2.6) |
| `MoneyTrackerTests/IntentCategoryMenuTests.swift` | **NUOVO** |

Non toccare: `CheckBalanceIntent`, `AccountOptionsProvider`, `MoneyTrackerShortcuts`, `IntentContainer`, nomi/titoli/tipi dei
parametri ESISTENTI di entrambi gli intent (cambiarli romperebbe i Comandi già creati da Matteo). Per le entrate si AGGIUNGE solo un
parametro opzionale.

### 2.3 Decisioni tecniche (motivate)
1. **Suggerita dal nome = stessa regola del modulo in app** (`AddTransactionView.swift` righe ~317–332): prima
   `LastUsedCategory.suggest(for: name, history:, availableCategories:)` (ultimo movimento con lo stesso nome), altrimenti
   `KeywordCategoryClassifier.shared.classify(name)` solo se `name` ha più di 2 caratteri e il risultato non è `"Altro"`.
   Valida solo se il nome è tra le categorie disponibili. Motivo: la stessa parola deve suggerire la stessa cosa in app e da Comandi.
2. **Ultima usata = l'ultimo movimento inserito** (ordine `createdAt` decrescente, NON `date`: un movimento retrodatato inserito
   adesso è comunque «l'ultimo usato»), con filtri: `type == TransactionType.uscita.rawValue`, `isDone == true`, `isTransfer == false`,
   `templateId` vuoto e `recurringFrequency` vuota (le occorrenze generate dalle ricorrenze non sono una scelta dell'utente),
   categoria ancora esistente (se è stata cancellata → nessuna «ultima usata», non si ripesca una più vecchia: stessa logica di
   `LastUsedCategory`). Il tipo segue l'azione: «Aggiungi spesa» → ultima USCITA; «Aggiungi entrata» → ultima ENTRATA
   (`TransactionType.entrata.rawValue`). Un helper solo, con il tipo come argomento.
3. **AddIncomeIntent incluso (risposta Matteo 2026-11-26)** — dettagli in §2.9, commit separato S-70a2.
4. **Lista = `ItemCollection<String>` con sezioni** (iOS 26.5 target: tutte le API disponibili):
   - sezione «Suggerita» con 1 voce (se c'è);
   - sezione «Ultima usata» con 1 voce (se c'è e diversa dalla suggerita);
   - sezione «Tutte le categorie»: **identica a oggi** (custom + default mancanti, stesso ordine) — le voci in cima restano anche qui,
     come chiesto («tutte le categorie come sono ora»).
   - Se le prime due sezioni sono vuote → una sola sezione «Tutte le categorie» (o lista piatta: Codex scelga quella che compila con
     l'API; il risultato visivo deve essere «parte da tutte»).
5. **Lettura del nome nel provider:** `@IntentParameterDependency<AddExpenseIntent>(\.$name) var intent` dentro
   `CategoryOptionsProvider`; `let typed = intent?.name ?? ""`. Senza nome (editor di Comandi, prima esecuzione) → niente
   «Suggerita», ma «Ultima usata» sì.
6. **Priorità in `perform()` (inversione richiesta):**
   `categoria scelta (trim, non vuota)` → altrimenti `suggerita dal nome` (regola 1) → altrimenti ripiego del tipo:
   spese `"Altro"`; entrate = comportamento attuale (categoria «Lavoro» se esiste, altrimenti la prima categoria, altrimenti `"Lavoro"`).
   La scelta dell'utente non viene validata contro la lista (comportamento attuale invariato: accetta la stringa).
7. **Prestazioni:** le query nel provider usano `FetchDescriptor` con `#Predicate` e `fetchLimit = 1` per l'ultima usata; per lo
   storico-per-nome replicare il pre-filtro sulla prima parola di `AddTransactionView` (`localizedStandardContains`). Se `#Predicate`
   non accetta `templateId.isEmpty`, usare `templateId == ""`.

### 2.4 Forma del tipo puro (indicativa, Codex può adattare i nomi)
```swift
enum IntentCategoryMenu {
    struct Movement: Sendable { let category: String; let type: String; let createdAt: Date
                                let isDone: Bool; let isTransfer: Bool; let isRecurring: Bool }
    nonisolated static func lastUsed(history: [Movement], type: String, available: Set<String>) -> String?
    nonisolated static func top(suggested: String?, lastUsed: String?) -> (suggested: String?, lastUsed: String?) // dedup
    nonisolated static func resolve(chosen: String?, suggested: String?, fallback: String) -> String // chosen > suggested > fallback
    nonisolated static func incomeFallback(categories: [String]) -> String          // «Lavoro» se c'è, poi la prima, poi "Lavoro"
    nonisolated static func allCategories(custom: [String]) -> [String]              // = logica attuale del provider, spostata qui
    @MainActor static func suggested(for name: String, context: ModelContext, available: Set<String>) -> String?
    @MainActor static func lastUsed(type: String, context: ModelContext, available: Set<String>) -> String?
    @MainActor static func collection(name: String, type: String) -> ItemCollection<String> // usata dai due provider
}
```
`perform()` dei due intent e i due provider usano gli stessi helper (una sola regola, quattro punti d'uso).

### 2.5 Casi limite
DB vuoto / store non disponibile (lista come oggi, nessuna eccezione) · nome vuoto o di 1–2 caratteri · nome con accenti/maiuscole ·
categoria suggerita = ultima usata · ultima usata cancellata · solo trasferimenti/entrate/pianificati nello storico · categoria
personalizzata con lo stesso nome di una default (nessun doppione nella sezione «Tutte») · utente sceglie «Altro» esplicitamente
(vince, non viene sostituito dal suggerimento) · categoria scelta con spazi intorno (trim).

### 2.6 Localizzazione (chiave = testo italiano, come da convenzione; aggiungere in tutti e 7 i `.lproj`, incluso `it`)
| Chiave | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|
| `Suggerita` | Suggested | Vorgeschlagen | Sugerida | Suggérée | おすすめ | 推荐 |
| `Ultima usata` | Last used | Zuletzt verwendet | Última usada | Dernière utilisée | 最近使用 | 最近使用 |
| `Tutte le categorie` | All categories | Alle Kategorien | Todas las categorías | Toutes les catégories | すべてのカテゴリ | 所有类别 |

Chiave in più per S-70a2 (descrizione del parametro nuovo delle entrate; `Categoria` esiste già, da riusare):
| Chiave | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|
| `Lascia vuoto per la scelta automatica` | Leave empty for automatic choice | Leer lassen für automatische Auswahl | Déjalo vacío para la elección automática | Laisser vide pour le choix automatique | 空欄で自動選択 | 留空以自动选择 |

Prima di aggiungere: `grep -n '^"Suggerita"' MoneyTracker/*.lproj/Localizable.strings` (se la chiave esiste già, non duplicarla).
I nomi delle categorie nella lista restano come oggi (fuori scope).

### 2.7 Test da AGGIUNGERE (Swift Testing, come `LastUsedCategoryTests`)
`MoneyTrackerTests/IntentCategoryMenuTests.swift`, almeno:
- `top`: suggerita ≠ ultima → 2 voci in ordine; uguali → 1; solo ultima → 1; nessuna → 0.
- `resolve`: scelta vince sul suggerimento (caso che oggi fallisce: nome «pizza», scelta «Svago» → «Svago»); scelta vuota/spazi →
  suggerita; nulla → «Altro»; scelta «Altro» esplicita vince.
- `lastUsed`: usa `createdAt` non la data; ignora trasferimenti, entrate, pianificati, ricorrenti; categoria cancellata → `nil`.
- `allCategories`: stesso ordine e contenuto della logica precedente (custom prima, default mancanti dopo, nessun doppione).
- Entrate (S-70a2): `lastUsed` con tipo entrata ignora le uscite e viceversa; `incomeFallback(["Cibo","Lavoro"]) == "Lavoro"`,
  `incomeFallback(["Cibo"]) == "Cibo"`, `incomeFallback([]) == "Lavoro"` (= comportamento di oggi); `resolve` con scelta vuota e senza
  suggerita restituisce il fallback; la scelta dell'utente vince anche sulle entrate.
- Facoltativo, se in `MoneyTrackerTests/Support` esiste un container in memoria: un test dei loader `@MainActor`.
Nessun test UI per A (Comandi non è automatizzabile da XCUITest).

### 2.8 Prove: simulatore vs telefono
- **Simulatore / Codex:** build, unit test sopra. Facoltativo: app Comandi del simulatore → azione «Aggiungi spesa» con Categoria
  «Chiedi ogni volta» → verificare le sezioni (se il simulatore non ha Comandi, saltare e scriverlo in CONSEGNA).
- **Solo telefono vero (Matteo, S-70d):** doppio tap posteriore (Impostazioni › Accessibilità › Tocco › Tocco posteriore) sul suo
  comando, con Categoria su «Chiedi ogni volta». Controlli: (1) scrivo «pizza» → in cima «Cibo»; (2) seconda riga = categoria dell'ultima
  spesa salvata; (3) scelgo un'altra categoria → il movimento salvato ha quella; (4) nome nuovo senza riscontro → solo «Ultima usata» + tutte.
- **S-70c (solo se la prova 1 fallisce, cioè la lista non vede il nome):** in `perform()`, quando `categoryName` è vuoto e c'è una
  suggerita → `requestConfirmation` «Salvo in «%@»?» (Sì = suggerita); se No o senza suggerita →
  `$categoryName.requestDisambiguation(among: suggerita + ultima + tutte, dialog: "In quale categoria?")`. Matteo poi imposta
  Categoria «vuota» invece di «Chiedi ogni volta». Chiavi nuove in 7 lingue in quel task. Vale per spese ed entrate.
  **Non implementarlo in S-70a/S-70a2.**
- Sul telefono Matteo ripete i 4 controlli anche con il comando «Aggiungi entrata» (es. «stipendio» → «Lavoro»; seconda riga = categoria
  dell'ultima ENTRATA). Per vedere il parametro nuovo deve aprire l'azione nel suo comando e impostare Categoria su «Chiedi ogni volta».

### 2.9 S-70a2 · Entrate: parametro categoria nel modo meno invasivo
- In `AddIncomeIntent` AGGIUNGERE, dopo `accountName`:
  `@Parameter(title: "Categoria", description: "Lascia vuoto per la scelta automatica", optionsProvider: IncomeCategoryOptionsProvider()) var categoryName: String?`
  Opzionale: i Comandi e le frasi Siri esistenti continuano a funzionare identici (valore `nil` → comportamento di oggi).
- `parameterSummary`: `Summary("Aggiungi entrata di \(\.$amount)€: \(\.$name) — \(\.$categoryName)")` (stesso schema delle spese,
  così il parametro è visibile nell'editor). Se la stringa del summary vecchia è tradotta nei `.strings`, aggiungere la nuova variante
  nelle 7 lingue ricalcandone la traduzione; se oggi non lo è, nessuna chiave (fuori scope).
- `IncomeCategoryOptionsProvider`: struct nuova nello stesso file, `@IntentParameterDependency<AddIncomeIntent>(\.$name)`, restituisce
  `IntentCategoryMenu.collection(name:, type: TransactionType.entrata.rawValue)`. Sezione «Tutte» = stessa lista delle spese.
- `perform()`: `incCatName = IntentCategoryMenu.resolve(chosen: categoryName, suggested: <suggerita per name>, fallback: IntentCategoryMenu.incomeFallback(categories:))`.
  La suggerita per le entrate usa la stessa regola delle spese (storico per nome, poi classificatore), come il modulo in app e come oggi.
- Nient'altro cambia in `AddIncomeIntent` (validazioni, salvataggio, sync, dialogo finale).

---

## 3. FUNZIONE B — S-70b · Simulazione «E se…?» dalla Home

### 3.1 File
| File | Azione |
|---|---|
| `MoneyTracker/Views/WhatIf/WhatIfScenario.swift` | **NUOVO** — tipo puro: ipotesi + risultati (`Decimal`) |
| `MoneyTracker/Views/WhatIf/WhatIfView.swift` | **NUOVO** — la schermata (sheet) |
| `MoneyTracker/Views/DashboardView.swift` | aggiungere: 1 bottone in `header`, 1 `@State showWhatIf`, 1 `.sheet`, 1 funzione privata che costruisce le basi (§3.2). Nient'altro |
| `MoneyTracker/*.lproj/Localizable.strings` (7) | chiavi §3.6 |
| `MoneyTrackerTests/WhatIfScenarioTests.swift` | **NUOVO** |
| `MoneyTrackerUITests/WhatIfUITests.swift` | **NUOVO** (flusso + screenshot) |

Il progetto usa gruppi sincronizzati con il file system (`PBXFileSystemSynchronizedRootGroup`): i file nuovi entrano nel target da
soli; **non modificare `project.pbxproj`** (se un file non compila nel target, fermarsi e scriverlo in CONSEGNA).

### 3.2 Dati: solo numeri che la Home calcola già
In `DashboardView` (dove i valori esistono già) costruire un array di basi al momento dell'apertura:
```swift
struct WhatIfBaseline: Identifiable, Equatable { let id: String; let name: String?; let today: Decimal; let endOfMonth: Decimal }
// name == nil → «Tutti»
```
- **Tutti:** `today = totalCurrent`, `endOfMonth = trail?.expectedBalance ?? totalCurrent` (= «Saldo atteso» della hero).
- **Un conto incluso nel totale:** per ogni conto di `includedAccounts` (stesso ordine di `HomeAccountOrderSheet`: saldo decrescente):
  `today = acc.currentBalance`, `endOfMonth = acc.currentBalance + projection.plannedByAccount[acc.persistentModelID, default: 0]`
  (= valore «→» della scheda conto in Home).
- **Un conto escluso dal totale (risposta Matteo):** la Home non ne calcola la previsione (`plannedByAccount` copre solo gli inclusi),
  quindi si usano le proprietà che l'app espone già e che la scheda Conti mostra: `today = acc.currentBalance`,
  `endOfMonth = acc.futureBalance` (`Models/Account.swift:64`, da `AccountBalanceCache`; è il valore «→» della riga del conto in
  `AccountsView`). Solo lettura: nessun calcolo nuovo, Domain/ e Models/ intatti. Filtro sul `@Query accounts` già presente:
  `accounts.filter { !$0.isArchived && $0.isExcludedFromTotal }`, saldo decrescente. Nel menu vanno dopo gli inclusi, in una
  `Section("Esclusi dal totale")` (chiave nuova, §3.6; esiste già il singolare `Escluso dal totale`, non riusarlo come titolo di sezione).
  Nota per il collaudo: per gli inclusi si usa il valore della Home e non `futureBalance`, perché la Home applica la regola S-41
  (`countsInProjection`) e la simulazione deve coincidere con ciò che si vede in Home.
- **«Tutti»:** invariato, = totale della Home (esclusi fuori).
- **Conti archiviati:** mai nel menu (conti chiusi: la Home e l'intent saldo li ignorano già, simularci sopra non ha senso).
  Nessun conto → solo «Tutti» con 0,00.
- La vista riceve `[WhatIfBaseline]` già pronte (istantanea all'apertura: la schermata dura pochi secondi). **Non** riceve modelli
  SwiftData, **non** ha `@Query`, **non** ha `modelContext`: impossibile toccare i dati veri per costruzione.
- Nessuna modifica a `buildMonthlyProjection`, `countsInProjection`, `BalanceTrail`, `AccountBalanceCache`.

### 3.3 Specifica visiva (sostituisce il mockup, D-014)
Componenti e token Sentiero esistenti: `DS.paper` sfondo, `Card` (Components/Card.swift) per i blocchi, `DS.Typo.*`, `DS.Space.*`,
`GhostButton`/stile toolbar come `HomeAccountOrderSheet`, colori solo `DS.*` adattivi (mai colori fissi, mai `preferredColorScheme`).
Riferimento di stile: `02_RISORSE/originali/bucktrail-redesign/DESIGN_HANDOFF.md` (leggere solo le sezioni su card, chip, toggle, tipografia).

**Quadratino in Home.** `headerButton(symbol: "plus.forwardslash.minus", label: "Simulazione")` stesso stile 44×44 degli altri; ordine
nell'`HStack`: **calcolatrice, occhio, impostazioni** (da destra: impostazioni, occhio, calcolatrice). Identificatore `home.whatIfButton`.
(SF Symbols non ha «calculator»: `plus.forwardslash.minus` è il simbolo calcolatrice standard. Se non esiste a runtime, ripiego
`function`, e scriverlo in CONSEGNA.)

**Sheet** `.presentationDetents([.large])`, `.presentationBackground(DS.paper)`, `NavigationStack`, titolo inline «E se…?»,
in alto a destra «Fine» (chiude). `.scrollDismissesKeyboard(.interactively)`. Dall'alto:
1. **Menu conto** — `Menu` con etichetta a chip (stile `FilterChip` primario: testo `DS.Typo.rowName` + `chevron.down`), voci
   «Tutti» + nomi dei conti inclusi + (sezione separata) conti esclusi dal totale, spunta sulla voce attiva. Default «Tutti». Se esiste già in app un menu conto «Tutti» (cercare in
   Statistiche/Movimenti), copiarne l'aspetto. Id `whatIf.accountMenu`.
2. **Card «ipotesi»** — una riga per ipotesi, separatori `DS.divider`:
   `[ − / + ]` cerchio 44×44 (− su `DS.dangerSoft` con simbolo `DS.danger`; + su `DS.accentSoft` con `DS.accent`), tocco = inverte segno ·
   campo importo (`.decimalPad`, `DS.Typo.rowAmount`, allineato a destra, larghezza minima ~90 pt, segnaposto «0,00») ·
   campo nome (`DS.Typo.rowName`, segnaposto «Nome (es. cena)») · `Toggle` senza etichetta visibile, `tint(DS.accent)`.
   Ipotesi spenta: importo e nome in `DS.smoke`. Eliminazione: `.contextMenu` «Elimina» + `accessibilityAction(named: "Elimina")`.
   Con **testo grande (accessibility sizes)**: riga su due livelli (sopra segno + importo + interruttore, sotto il nome a tutta larghezza).
   Nuova ipotesi: segno −, importo vuoto, accesa, fuoco sul campo importo. Stato vuoto: testo `DS.smoke` «Nessuna ipotesi: aggiungine una».
3. **«+ Aggiungi ipotesi»** — riga-bottone `DS.accent`, icona `plus`, min 44 pt. Massimo 20 ipotesi (poi disabilitato).
4. **Risultati** («in basso»): `Card` con
   - «Saldo di oggi» (`DS.Typo.secondary`, `DS.smoke`) e sotto `ora → con le ipotesi`: valore ora `DS.Typo.rowAmount` `DS.smoke`,
     freccia, valore con ipotesi `DS.Typo.sectionTitle` `DS.ink`;
   - «Saldo atteso a fine mese», stessa forma;
   - divisore, poi «Differenza totale» con valore firmato (`+` `DS.accent`, `−` `DS.danger`, zero `DS.smoke`).
   Con testo grande: «ora» e «con le ipotesi» uno sotto l'altro con le etichette «Ora» / «Con le ipotesi» invece della freccia.
   Posizione: fissata in fondo con `.safeAreaInset(edge: .bottom)` (resta visibile mentre si scrive); con accessibility sizes in coda
   allo scroll (non deve coprire metà schermo).
5. Nota finale `DS.Typo.caption` `DS.smoke`: «Le ipotesi non vengono salvate».

Niente grafici, niente animazioni oltre al default.

### 3.4 Regole di comportamento
- **Oscura importi** (`@AppStorage("hideBalance")`, lo stesso della Home): i valori «ora» e «con le ipotesi» mostrano
  `"•••• \(Double.currencySymbol)"` come `DashboardView.money`. La «Differenza totale» resta visibile (è solo la somma di ciò che
  l'utente ha appena scritto, non rivela i saldi). I campi importo delle ipotesi restano leggibili (si stanno scrivendo).
- Importi: `Decimal.parseAmount` (Formatting/, solo chiamata) sul testo del campo; valore valido se `> 0` e `≤ 1_000_000_000`;
  campo vuoto o non valido → l'ipotesi conta 0 e il campo ha bordo `DS.danger` solo se non vuoto e non valido. Il segno lo decide
  SOLO il tasto − / + (un «-» digitato nel campo rende il valore non valido).
- Le ipotesi vivono in `@State` della sheet: alla chiusura spariscono. Nessuna scrittura su SwiftData, `UserDefaults`, sync, log.
- Cambiare conto nel menu non cancella le ipotesi (cambiano solo le basi).
- Formattazione importi: `currencyFormatted` esistente.

### 3.5 Tipo puro `WhatIfScenario` (indicativo)
```swift
struct WhatIfHypothesis: Identifiable, Equatable { let id: UUID; var amountText: String; var isIncome: Bool; var name: String; var isOn: Bool }
enum WhatIfScenario {
    nonisolated static func amount(of text: String) -> Decimal?          // parseAmount + limiti (>0, ≤ 1e9)
    nonisolated static func delta(_ items: [WhatIfHypothesis]) -> Decimal // somma firmata delle accese valide
    nonisolated static func result(baseline: WhatIfBaseline, items: [WhatIfHypothesis])
        -> (todayNow: Decimal, todayWith: Decimal, endNow: Decimal, endWith: Decimal, delta: Decimal)
}
```
(`WhatIfBaseline` può stare in questo file.) Tutto `Decimal`, mai `Double`.

### 3.6 Localizzazione (chiave = testo italiano; 7 `.lproj` incluso `it`; prima `grep` per non duplicare. Già esistenti e da riusare: `Tutti`, `Elimina`, `Fine`, `Entrata`, `Importo`)
| Chiave | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|
| `Simulazione` | Simulation | Simulation | Simulación | Simulation | シミュレーション | 模拟 |
| `E se…?` | What if…? | Was wäre, wenn…? | ¿Y si…? | Et si… ? | もしも…？ | 如果…？ |
| `Aggiungi ipotesi` | Add scenario | Annahme hinzufügen | Añadir supuesto | Ajouter une hypothèse | 仮定を追加 | 添加假设 |
| `Nome (es. cena)` | Name (e.g. dinner) | Name (z. B. Abendessen) | Nombre (p. ej. cena) | Nom (ex. dîner) | 名前（例：夕食） | 名称（例如：晚餐） |
| `Nessuna ipotesi: aggiungine una` | No scenarios yet: add one | Noch keine Annahmen: füge eine hinzu | Aún no hay supuestos: añade uno | Aucune hypothèse : ajoutez-en une | 仮定はまだありません。追加してください | 暂无假设：添加一个 |
| `Saldo di oggi` | Today's balance | Kontostand heute | Saldo de hoy | Solde du jour | 今日の残高 | 今日余额 |
| `Saldo atteso a fine mese` | Expected end-of-month balance | Erwarteter Stand am Monatsende | Saldo previsto a fin de mes | Solde prévu en fin de mois | 月末の予想残高 | 预计月末余额 |
| `Ora` | Now | Jetzt | Ahora | Maintenant | 現在 | 现在 |
| `Con le ipotesi` | With scenarios | Mit Annahmen | Con supuestos | Avec hypothèses | 仮定込み | 含假设 |
| `Differenza totale` | Total difference | Differenz gesamt | Diferencia total | Écart total | 差額合計 | 总差额 |
| `Le ipotesi non vengono salvate` | Scenarios are not saved | Annahmen werden nicht gespeichert | Los supuestos no se guardan | Les hypothèses ne sont pas enregistrées | 仮定は保存されません | 假设不会被保存 |
| `Includi nel calcolo` | Include in calculation | In Berechnung einbeziehen | Incluir en el cálculo | Inclure dans le calcul | 計算に含める | 计入计算 |
| `Spesa` (se non esiste) | Expense | Ausgabe | Gasto | Dépense | 支出 | 支出 |
| `Esclusi dal totale` | Excluded from total | Nicht im Gesamtbetrag | Excluidas del total | Exclus du total | 合計から除外 | 不计入总额 |
| `Ipotesi senza nome` | Unnamed scenario | Unbenannte Annahme | Supuesto sin nombre | Hypothèse sans nom | 名前のない仮定 | 未命名假设 |

### 3.7 Accessibilità (identificatori ed etichette)
`home.whatIfButton` (label «Simulazione») · `whatIf.sheet` (contenitore) · `whatIf.done` · `whatIf.accountMenu` ·
`whatIf.addHypothesis` · per la riga i (0-based): `whatIf.row.i.sign` (label «Spesa»/«Entrata»), `whatIf.row.i.amount`,
`whatIf.row.i.name`, `whatIf.row.i.toggle` (label «Includi nel calcolo», value = nome o «Ipotesi senza nome») ·
`whatIf.result.today.now`, `whatIf.result.today.with`, `whatIf.result.end.now`, `whatIf.result.end.with`, `whatIf.result.delta`.
Ogni blocco risultato letto da VoiceOver come una frase: «Saldo di oggi, Ora X, Con le ipotesi Y».

### 3.8 Casi limite
Nessun conto · saldo negativo · un conto solo · solo conti esclusi dal totale («Tutti» = 0, esclusi selezionabili) · conto escluso con pianificati · conto con pianificati (fine mese ≠ oggi) · nessun pianificato (fine mese = oggi) ·
tutte le ipotesi spente (risultati = ora, differenza 0) · importo «0», «abc», «1.000.000.001», «12,345» (arrotondato a 2 cifre da
`parseAmount`) · 20 ipotesi · tedesco + testo accessibility XL (3 quadratini in Home e righe della sheet senza tagli/sovrapposizioni;
la data in Home può troncarsi con «…», i bottoni no) · modalità scura · oscura importi acceso · rotazione non richiesta.

### 3.9 Test da AGGIUNGERE
**Unit (`WhatIfScenarioTests`, Swift Testing):** vuoto → delta 0 · −150 cena +350 lavoretto → +200 · spenta esclusa · non valida o
vuota = 0 · `0.1 + 0.2 == 0.3` esatto in `Decimal` · `> 1e9` rifiutato · «12,345» → 12,35 (o quanto restituisce `parseAmount`) ·
`result` applica lo stesso delta a oggi e a fine mese · base negativa.
**UI (`WhatIfUITests`, parte da `UITestSupport`/`--uitesting`, dati demo):**
1. Home: esistono `home.whatIfButton`, eye e gear; il bottone simulazione ha x minore dell'occhio, l'occhio minore delle impostazioni.
2. Apri → aggiungi ipotesi → importo 150, nome «cena» → `whatIf.result.delta` contiene «150» → toggle spento → delta «0» →
   segno + e toggle acceso → delta contiene «+».
3. Chiudi e riapri → nessuna riga `whatIf.row.0.amount` (le ipotesi sono sparite).
3b. Se i dati demo hanno un conto escluso dal totale: compare nel menu e selezionandolo `whatIf.result.today.now` cambia; nessun conto
   archiviato nel menu. Se i dati demo non ne hanno, scriverlo in CONSEGNA (non modificare il seeder demo).
4. Il saldo hero della Home è identico prima e dopo la simulazione (confrontare il `label` del testo importo hero; se manca un modo
   stabile per trovarlo, confrontare `whatIf.result.today.now` prima/dopo, che legge lo stesso numero).
5. Screenshot (`XCTAttachment`, `lifetime = .keepAlways`): Home header, sheet con 2 ipotesi, sheet con importi oscurati;
   una seconda esecuzione con `-AppleLanguages (de) -AppleLocale de_DE -UIPreferredContentSizeCategoryName UICTContentSizeCategoryAccessibilityXL`
   (via `app.launchArguments` in un test dedicato) per Home header + sheet.

---

## 4. Ordine di lavoro (una sessione, due commit)

0. Inizio turno (AGENTS.md §4): `STATO.md` → se `In turno` non è `nessuno`, FERMATI. Scrivi turno Codex + ora. Leggi questo file,
   `.cantiere/REGOLE-PROGETTO.md`, le righe S-70 in `.cantiere/PIANO.md`. Per il codice: `graphify query "…"` prima di aprire file.
1. Voce in `DECISIONI.md` (§2.1).
2. **S-70a** (spese + helper comune): `IntentCategoryMenu.swift` → test → `CategoryOptionsProvider` e `AddExpenseIntent.perform()` →
   chiavi → build + test mirati → commit `[impresa] doppio tap spese: la categoria scelta vince, suggerita e ultima usata in cima (S-70a)`
   (solo: i 2 file Intents, il test nuovo, i 7 `Localizable.strings`, `.cantiere/DECISIONI.md`).
2b. **S-70a2** (entrate, §2.9): parametro + `IncomeCategoryOptionsProvider` + `perform()` di `AddIncomeIntent` → test aggiunti in
   `IntentCategoryMenuTests` → chiavi → build + test mirati →
   commit `[impresa] doppio tap entrate: parametro categoria con suggerita e ultima entrata (S-70a2)`.
3. **S-70b**: `WhatIfScenario.swift` → test → `WhatIfView.swift` → `DashboardView.swift` → chiavi → test UI e screenshot →
   build + intera suite → commit `[impresa] Home: simulazione «E se…?» (S-70b)`.
4. `graphify update .` (non committare `graphify-out/`: ha modifiche altrui, si sistema al checkpoint).
5. Fine turno (AGENTS.md §4): PIANO S-70a/S-70b `[~]` con esito, riga DIARIO, CONSEGNA riscritta, STATO `In turno: nessuno`,
   commit `[impresa] chiude il turno (S-70)` solo con `.cantiere/` + screenshot.

**Mai nei commit** (modificati da altri, vedi `git status` iniziale): `03_CODICE/bucktrail-android/…`, `MoneyTracker/Sync/E2E/E2EFeature.swift`,
`SOCIAL/…`, `docs/…`, `graphify-out/…`, `.cantiere/APPROVAZIONI.md`, `.cantiere/PER-MATTEO.md` (salvo righe proprie). Mai `git add -A`.

---

## 5. «Fatto quando» (verificabile)

Comandi:
```bash
cd /Users/matteo/Desktop/APP/MoneyTracker
# mirati, durante il lavoro
xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test \
  -only-testing:MoneyTrackerTests/IntentCategoryMenuTests -only-testing:MoneyTrackerTests/WhatIfScenarioTests \
  -only-testing:MoneyTrackerUITests/WhatIfUITests -resultBundlePath .cantiere/tmp/s70/whatif.xcresult
# finale, obbligatorio
xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build test
# screenshot dal result bundle
xcrun xcresulttool export attachments --path .cantiere/tmp/s70/whatif.xcresult --output-path .cantiere/tmp/s70/
# modalità scura: rilanciare solo il test screenshot dopo
xcrun simctl ui 'iPhone 18 Pro' appearance dark   # e poi tornare a light
```
- [ ] Build verde, **suite intera verde** (nessun test esistente modificato o disattivato).
- [ ] Test nuovi verdi: `IntentCategoryMenuTests` (spese + entrate), `WhatIfScenarioTests`, `WhatIfUITests`.
- [ ] `AddIncomeIntent`: parametri esistenti invariati, `categoryName` opzionale aggiunto; con `nil` e senza suggerimento la categoria è identica a prima.
- [ ] `git diff` di `AddExpenseIntent.swift` limitato a: provider spese + blocco categoria in `perform()` + commento (S-70a); parametro nuovo + provider entrate + summary + blocco `incCatName` (S-70a2).
- [ ] `git diff` di `DashboardView.swift` ≤ ~40 righe, solo aggiunte (bottone, stato, sheet, basi).
- [ ] Nessun file in Models/, Persistence/, Domain/, Sync/, Auth/, Export/, Formatting/, notifiche, ricorrenze, test esistenti, `project.pbxproj`.
- [ ] Le chiavi nuove esistono in tutti e 7 i `Localizable.strings` (`grep -c` = 7 per ciascuna) e i file restano validi
      (`plutil -lint MoneyTracker/*.lproj/Localizable.strings`).
- [ ] Screenshot in `.cantiere/tmp/s70/` con nomi `home-header-it-light.png`, `whatif-it-light.png`, `whatif-it-dark.png`,
      `whatif-oscurati.png`, `home-header-de-axxl.png`, `whatif-de-axxl.png` (rinominare gli export).
- [ ] CONSEGNA dice cosa NON è stato provato (doppio tap reale; Comandi su simulatore se assente).

---

## 6. Checklist di collaudo (capocantiere / collaudatore, solo diff)

**S-70a**
- Ordine in `perform()`: scelta utente (trim) → suggerita → «Altro». Nessun ramo in cui il classificatore batte la scelta.
- Suggerita = `LastUsedCategory` per nome, poi classificatore (>2 caratteri, ≠ «Altro»), solo se categoria disponibile: identica ad AddTransactionView.
- Ultima usata: `createdAt` desc, uscita, fatta, non trasferimento, non ricorrente, categoria esistente; `fetchLimit` 1.
- Sezioni: dedup suggerita/ultima; sezione «Tutte» uguale alla lista precedente (stesso ordine, nessun doppione custom/default).
- `@IntentParameterDependency` presente e gestito il caso `nil`. Nessun `try!`/force-unwrap; store `nil` → lista come oggi.
- Parametri esistenti, titoli, frasi di Siri invariati. Voce in DECISIONI presente.
**S-70a2**
- `categoryName` delle entrate opzionale; ultima usata filtrata su `entrata`; scelta vuota e nessun suggerimento → «Lavoro»/prima categoria come prima.
- Il provider entrate dipende da `AddIncomeIntent` (non da `AddExpenseIntent`); scelta dell'utente vince.
**S-70b**
- `WhatIfView` senza `@Query`, `modelContext`, `@Environment(\.modelContext)`, scritture su `UserDefaults` (solo lettura `hideBalance`).
- Basi prese da `totalCurrent`, `trail?.expectedBalance`, `plannedByAccount`: nessuna nuova somma su transazioni.
- Menu: «Tutti» = totale Home; inclusi con valori Home (`plannedByAccount`); esclusi dal totale presenti con `currentBalance`/`futureBalance`; archiviati assenti. Ordine header: calcolatrice, occhio, impostazioni.
- Solo `Decimal` (nessun `Double` nei conti), `parseAmount` usato, limite 1e9, massimo 20 righe.
- Solo colori `DS.*`, font `DS.Typo`/`scaledFont`, nessun `preferredColorScheme`, nessuna stringa visibile non localizzata.
- Oscura importi applicato a tutti i valori «ora»/«con le ipotesi».
- Screenshot: confronto con §3.3; in tedesco AX-XL i 3 bottoni sono interi e non sovrapposti; scuro leggibile; bordi e badge ingranditi controllati (memoria «occhio ai dettagli»).
- Nessun file fuori elenco §3.1 / §2.2 (+ `.cantiere/`).

---

## 7. Prompt per Codex (da incollare)

```
Sei l'impresa (Codex) del cantiere MoneyTracker, ramo redesign-sentiero. Leggi AGENTS.md e .cantiere/REGOLE-PROGETTO.md e rispettali.
Inizio turno come AGENTS.md §4: se in .cantiere/STATO.md «In turno» non è «nessuno», FERMATI e scrivilo; altrimenti segna il tuo turno con l'ora vera (date "+%Y-%m-%d %H:%M").

Il lavoro è S-70a (spese), S-70a2 (entrate) e S-70b (simulazione), descritti per intero in .cantiere/progetto-s70-doppio-tap-simulazione.md: leggilo tutto prima di iniziare e seguilo alla lettera (file ammessi, decisioni, testi nelle 7 lingue, identificatori, test, ordine di lavoro §4, criteri §5). Per il codice interroga prima il grafo (graphify query "…") e apri solo i file necessari.

Vincoli: Matteo autorizza modifiche a MoneyTracker/Intents/ SOLO per S-70a e S-70a2: registralo in .cantiere/DECISIONI.md come primo passo (§2.1). Non toccare Models/, Persistence/, Domain/ (puoi solo chiamare LastUsedCategory, KeywordCategoryClassifier, BalanceTrail), Sync/, Auth/, Export/, Formatting/ (solo chiamare parseAmount), notifiche, ricorrenze, project.pbxproj, test esistenti (aggiungi solo test nuovi). Niente S-70c (è condizionale) né «Trasforma in movimento». Solo Decimal per i soldi, solo colori DS.* adattivi, mai preferredColorScheme, nessuna stringa visibile senza le 7 traduzioni.

Tre commit separati, ciascuno solo con i suoi file (mai git add -A; non includere i file già modificati da altri elencati in §4):
  [impresa] doppio tap spese: la categoria scelta vince, suggerita e ultima usata in cima (S-70a)
  [impresa] doppio tap entrate: parametro categoria con suggerita e ultima entrata (S-70a2)
  [impresa] Home: simulazione «E se…?» (S-70b)
Prima di ogni commit: build e test mirati verdi; alla fine la suite intera verde:
  xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build test
Salva gli screenshot richiesti in .cantiere/tmp/s70/ con i nomi del §5. Poi graphify update . (senza committare graphify-out/).

Chiudi il turno come AGENTS.md §4: in .cantiere/PIANO.md metti S-70a, S-70a2 e S-70b a [~] con esito dei test; una riga in .cantiere/DIARIO.md; riscrivi .cantiere/CONSEGNA.md (cosa hai fatto, cosa NON hai potuto provare — il doppio tap sul telefono vero —, file toccati, eventuali scostamenti dal progetto e perché); STATO «In turno: nessuno»; commit finale solo di .cantiere/ e degli screenshot. Se qualcosa nel progetto non è fattibile come scritto, non improvvisare: scegli la soluzione più semplice coerente con il progetto e motivala in CONSEGNA. Se un vincolo ti blocca, segna [!] con il motivo e chiudi il turno.
```

---

## 8. Task da registrare in PIANO (a cura del capocantiere, prima di lanciare Codex)

- `[ ] S-70a · Doppio tap spese: categoria scelta vince, suggerita e ultima usata in cima` → Codex · progetto §2
- `[ ] S-70a2 · Doppio tap entrate: parametro categoria con suggerita e ultima entrata` → Codex · progetto §2.9
- `[ ] S-70b · Simulazione «E se…?» dalla Home (conti esclusi selezionabili)` → Codex · progetto §3
- `[ ] S-70c · (condizionale) Ripiego doppio tap con domanda di conferma, spese ed entrate` → Codex/Copilot · solo se S-70d prova 1 fallisce · §2.8
- `[?] S-70d · Matteo: prova del doppio tap sul telefono, spese ED entrate (4 controlli §2.8 ciascuno) + approvazione screenshot S-70b (D-014) prima del merge` → Matteo

## 9. Domande aperte per Matteo
Nessuna: entrate e conti esclusi sono stati decisi da Matteo il 2026-11-26 (vedi §0).
