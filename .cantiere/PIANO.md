# PIANO DEI LAVORI

Stato: `[ ]` da fare · `[~]` fatto, da collaudare · `[x]` chiuso (collaudatore o Matteo) · `[!]` bloccato · `[?]` serve Matteo
Lo scrive l'architetto o il capocantiere. Ogni task è AUTOSUFFICIENTE: chi lo esegue legge solo
il task e i file indicati.

## In corso / prossimi

> **Redesign «Sentiero»** — brief: `02_RISORSE/originali/bucktrail-redesign/BRIEF_CANTIERE.md` · specifica: `02_RISORSE/originali/bucktrail-redesign/DESIGN_HANDOFF.md` · mockup: `02_RISORSE/originali/bucktrail-redesign/reference/*.dc.html`.
> Ramo: `redesign-sentiero` (mai `main`). Un'IA alla volta sul codice; ogni step chiude con commit, build e test verdi, poi passa la mano.
> **Collaudo di ogni step:** `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=<iPhone>' build test` (schema reale: `MoneyTracker`), nessun warning nuovo, funzioni della schermata tutte presenti (elenco fatto a inizio step da `docs/MoneyTracker.md`), light+dark, Dynamic Type XL, tedesco, oscura importi, modalità demo, screenshot prima/dopo in `.cantiere/tmp/`.
> **Mai toccare:** Models/Persistence, Domain/ (salvo step 4), Sync/, Auth/, Intents/, Export/, Formatting/, classificatore categorie, notifiche, ricorrenze, test esistenti (salvo identificatori UI). Vedi AGENTS.md.

### S-0 [x] Rimozione del tour
- **A chi:** Claude Code
- **Obiettivo:** togliere il tour (tag `tour-v1` lo conserva), tenere la modalità demo
- **Leggere:** BRIEF §4
- **Toccare:** OnboardingTour/, viste, SettingsView, TourFlowUITests, 7 Localizable.strings, docs
- **Fatto quando:** build e tutti i test verdi; `grep` di `Tour|tourAnchor|ContextualHint` vuoto. *Chiuso 2026-11-13: build verde, 17 test unitari + 12 test UI verdi su iPhone 18 Pro (iOS 27.2); commit 95c0afb, 620419d.*
- **Non fare:** toccare la modalità demo

### S-1 [x] Token, font, dark mode
- **A chi:** Claude Code
- **Obiettivo:** integrare i token «Sentiero» nell'enum `DS` di `MoneyTracker/Views/Theme.swift`, adattivi light/dark, senza cambiare ancora nessuna schermata
- **Leggere:** `DESIGN_HANDOFF.md` §2 e §3, `BucktrailTheme.swift`, BRIEF «Token e dark mode»
- **Toccare:** `Views/Theme.swift`, `MoneyTracker/Resources/Fonts/`, `Info.plist` (UIAppFonts), `DECISIONI.md`
- **Fatto quando:** token light da §2, dark `bg #0E1210 / surface #171C19 / testo #F1F3EF / hero #1F2622`; costruttore `Color(lightHex:darkHex:)`; **niente** `Color(hex:)` di `BucktrailTheme.swift`; font Space Grotesk e Inter nel target con `Font.custom(…, relativeTo:)` e fallback SF Pro, licenze OFL incluse; `.monospacedDigit()` sugli importi; regola delle 4 tinte categoria (deterministica, senza toccare SwiftData) in `DECISIONI.md`; test verdi
- **Non fare:** `preferredColorScheme`, colori fissi, doppioni con `DS`
- **Chiuso 2026-11-13:** collaudo ok (collaudatore): token, font, tinte, contrasti WCAG verificati; commit 46399d4. Nota: `fog` e `heroDivider` in dark senza regola di contrasto (bordi, non testo): ricontrollare se usati come testo/icone.
- **Serve Matteo:** scaricare i font in `02_RISORSE/originali/font/` (istruzioni quando si parte)

### S-2 [x] Componenti base (chiuso 2026-11-13 20:40, collaudatore)
- **A chi:** Codex
- **Obiettivo:** `Card`, `HeroCard`, `MovementRow`, `ProgressBar`, `BudgetStatus`, `SegmentedPill`, `FilterChip`, ciascuno con `#Preview` (light/dark)
- **Leggere:** `DESIGN_HANDOFF.md` §3, `Views/Theme.swift` (token di S-1), `BucktrailTheme.swift`
- **Toccare:** solo file nuovi (es. `MoneyTracker/Views/Components/`)
- **Fatto quando:** componenti compilano e hanno preview; nessuna vista esistente modificata; test verdi
- **Non fare:** toccare viste esistenti, introdurre colori fuori da `DS`
- **Eseguito 2026-11-13 20:15 (Codex):** sette nuovi componenti in `Views/Components/`, 14 preview light/dark; build e 21 test unitari + 12 UI verdi sul simulatore richiesto. Da collaudare; nessuna vista o test esistente modificato.
- **Collaudo 2026-11-13 20:20 (collaudatore): ❌ NON CONFORME, rilavorazione S-2b.** Requisiti strutturali ok (7 componenti, 14 preview, solo file nuovi, solo token DS, nessun `preferredColorScheme`, tap target 44, font `relativeTo:`). Difetti: (1) chiavi `"Sforato"` e `"Soglia 80%"` (`BudgetStatus.swift:24-25`) assenti da tutti i 7 `Localizable.strings`: in tedesco/inglese/ecc. compaiono in italiano; aggiungere le chiavi nelle 7 lingue (de: «Überschritten», «Schwelle 80 %»). (2) `HeroCard.swift:24` usa `cardRadius` 16, l'handoff chiede raggio hero 24–26: aggiungere token/raggio hero. (3) minori: `MovementRow` importo senza `lineLimit`/priorità di layout (a XL con tedesco può comprimere nome); `ProgressBar` accessibilityValue limitato al 100% con progress>1. Preview non ispezionate visivamente (nessun renderer disponibile al collaudo): controllo statico dei token, contrasti ereditati da S-1.
- **Ricollaudo 2026-11-13 20:40 (collaudatore): ✅ CONFORME, S-2 e S-2b chiusi.** Le quattro correzioni (commit 535ccc1) verificate sul diff: chiavi «Sforato»/«Soglia 80%» presenti una volta in ciascuno dei 7 file, `plutil -lint` ok, de «Überschritten»/«Schwelle 80 %»; hero raggio 24 con `cardRadius` invariato; nome `lineLimit(1)` e importo `fixedSize`+`layoutPriority(1)` (a XL/tedesco si tronca il nome, mai l'importo); accessibilityValue col progresso reale. Nota: il 24 della hero è un letterale, da portare in token se riusato in S-4. Resa a vista (light/dark, XL, de) da confermare da Matteo nelle preview di Xcode.

### S-2b [x] Correzioni componenti base
- **A chi:** Codex
- **Obiettivo:** correggere i quattro rilievi del collaudo S-2.
- **Eseguito 2026-11-13 20:35:** chiavi «Sforato» e «Soglia 80%» in tutte le 7 lingue (de: «Überschritten», «Schwelle 80 %»); HeroCard raggio 24 senza cambiare cardRadius; nome MovementRow su una riga e importo con fixedSize/layoutPriority; ProgressBar annuncia il valore reale anche oltre 100%.
- **Verificato:** plutil sui 7 Localizable.strings, diff pulito, build e 21 test unitari + 12 UI verdi sul simulatore richiesto. Nessun crash del runner.
- **Aperto:** ricollaudo indipendente, inclusa verifica visiva light/dark, XL e tedesco; S-2 resta in attesa del collaudatore.

### S-3 [x] FloatingTabBar + FAB (2026-11-13 22:08 collaudo ok)
- **A chi:** Claude Code
- **Obiettivo:** nuova tab bar flottante e FAB con la grafica Sentiero
- **Leggere:** `DESIGN_HANDOFF.md` §3 (icone tab §3), `Views/ContentView.swift`
- **Toccare:** `ContentView.swift`, componenti tab bar
- **Fatto quando:** stessi indici di tab, stesse azioni FAB per tab, stessi `accessibilityIdentifier` (se cambiano si aggiornano i UI test, non si tolgono); `accessibilityLabel` FAB «Nuovo movimento/budget/obiettivo/conto»; test verdi
- **Non fare:** cambiare la navigazione
- **Eseguito 2026-11-13 21:52 (capocantiere):** `FloatingTabBar` nuova; `TabView` tenuta con barra nativa nascosta (stati e navigazione invariati), FAB 58×58 raggio 20 `accent`, label accessibilità per tab (nuova chiave «Nuovo movimento» in 7 lingue). UI test aggiornati agli id `tab_*` (erano `tabBars.buttons`). Build + test verdi (12 UI). Da collaudare.
- **Collaudo 2026-11-13 22:08:** ok. Tag 0-4 e navigazione invariati, id fabButton/fabMenu_* e label FAB ok, «Nuovo movimento» 1 volta x7 lingue (plutil ok), toolbar nascosta su ogni tab + striscia riservata, solo token DS, nessun preferredColorScheme, UI test aggiornati senza toglierne. Note non bloccanti: con Dynamic Type accessibilità la barra può superare `reservedHeight` (66+20+8, fisso) e tedesco «Startseite/Statistiken» a XL scala fino a 0.7 (ok a XL, tagli possibili agli accessibility size); fix FAB ombra/alette non verificabile da qui: Matteo riprova a vista.

### S-4 [x] Home con TrailView (2026-11-13 22:40, collaudo ok)
- **A chi:** Claude Code
- **Obiettivo:** Home come `Main.dc.html`: header, HeroCard con TrailView, conti in scroll orizzontale, ultimi movimenti
- **Leggere:** `DESIGN_HANDOFF.md` §4 Home, BRIEF «TrailView», `Views/DashboardView.swift`, `Domain/` (calcoli saldo)
- **Toccare:** `DashboardView.swift`, nuova funzione **pura** in `Domain/` per la serie giornaliera cumulata + proiezione (con test in `MoneyTrackerTests/`), `DECISIONI.md`
- **Fatto quando:** ultimo punto reale = «Saldo attuale», ultimo proiettato = «Saldo atteso»; senza pianificati niente tratto ambra né riga attesa; serie calcolata una volta per cambio dati (non nel `body`); `accessibilityHidden(true)`; oscura importi `•••• €`; test verdi
- **Non fare:** modificare le funzioni esistenti di `Domain/`, ricalcolare saldi nella vista
- **Eseguito 2026-11-13 22:30 (capocantiere):** `Domain/BalanceTrail.swift` + 6 test; `TrailView`, `HomeHeroCard` in `Views/Components/`; `DashboardView` riscritta (header con occhio/impostazioni, hero con TrailView, conti in scroll orizzontale, fissi del mese, ultimi movimenti con `MovementRow`); `goToTab` per «Gestisci»/«Vedi tutti». Build + 27 unit + 12 UI verdi. Da collaudare.

### S-5 [x] Movimenti
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Movimenti.dc.html`, sezione «In arrivo · pianificati» in cima
- **Leggere:** `DESIGN_HANDOFF.md` §4 Movimenti, `Views/TransactionsView.swift`, `docs/MoneyTracker.md` §6
- **Toccare:** `TransactionsView.swift` e componenti di S-2
- **Fatto quando:** filtri, ricerca, swipe, conferma trasferimenti, filtri avanzati, sezione ricorrenti invariati; test verdi
- **Non fare:** toccare `@Query`, logica o calcoli (Gemini Flash: stare lontano da SwiftData)

- **Eseguito 2026-11-13 (Codex):** header Sentiero, ricerca h 46/raggio DS 16, chip tipo con gli stessi identificatori e percorsi, selettore categorie con SegmentedPill, MovementRow, pianificati in cima e card giornaliere con subtotali visivi (trasferimenti esclusi). Nuova intestazione in 7 lingue. Query, filtri, ricerca, sheet avanzato, ricorrenti, swipe e mutazioni dati invariati; nessun test modificato.
- **Build separata:** BUILD SUCCEEDED, exit 0 (22:54), nessun errore o warning nuovo nel log finale.
- **Verifica aperta:** i test non hanno prodotto un esito: il simulatore resta all'avvio e Xcode segnala il servizio `com.apple.instruments.deviceservice.lockdown` / `DTServiceHubClient` non disponibile. Tentati riavvio e rilancio. NON dichiarare test verdi. Richiesti collaudo indipendente e resa a vista light/dark, XL, tedesco (nessuno screenshot utile della schermata ottenuto).

### S-6 [ ] Statistiche
- **A chi:** Antigravity col modello più forte (o Codex)
- **Obiettivo:** schermata come `Statistiche.dc.html`; grafico con Swift Charts `BarMark` + `position(by:)`
- **Leggere:** `DESIGN_HANDOFF.md` §4 Statistiche, `Views/StatisticsView.swift`
- **Toccare:** `StatisticsView.swift`
- **Fatto quando:** export PDF invariato, 6M/12M, media uscite e confronto anno precedente come prima; test verdi
- **Non fare:** cambiare calcoli o `Export/`

### S-7 [ ] Pianifica (Budget + Obiettivi)
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Pianifica.dc.html`
- **Leggere:** `DESIGN_HANDOFF.md` §4 Pianifica, `Views/PianificaView.swift`
- **Toccare:** `PianificaView.swift` e relative card
- **Fatto quando:** soglie 80/100% lette dalla logica esistente (non ricalcolate nella vista); badge testuale di stato; progresso complessivo ponderato invariato; test verdi
- **Non fare:** ricalcolare soglie, toccare modelli

### S-8 [ ] Conti
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Conti.dc.html`, raggruppamento per tipo solo visivo
- **Leggere:** `DESIGN_HANDOFF.md` §4 Conti, `Views/AccountsView.swift`
- **Toccare:** `AccountsView.swift`
- **Fatto quando:** swipe/long-press, archiviazione ed esclusione dal totale invariati; test verdi
- **Non fare:** cambiare il modello dei conti

### S-9 [ ] Impostazioni, sheet di inserimento, categorie, login
- **A chi:** Antigravity
- **Obiettivo:** stessi token per coerenza (schermate non disegnate)
- **Leggere:** `Views/Theme.swift`, componenti di S-2, `SettingsView.swift`, `AddTransactionView`, viste Auth
- **Toccare:** solo aspetto di queste viste
- **Fatto quando:** tutte le funzioni presenti, 7 lingue senza testi tagliati (tedesco), light/dark; test verdi
- **Non fare:** toccare `Auth/` logica, Sync, Face ID
- **Collaudo 2026-11-13 23:16 (collaudatore):** [x] conforme. Runner ripristinato (shutdown/boot). 27 unit + 12 UI verdi sul 37445D1E; funzioni conservate (ricerca, filtri, swipe, trasferimenti, ricorrenti). Resa a vista hub: light, dark, XL, tedesco ok. Riserve cosmetiche → S-11.

### S-11 [ ] Riserve da S-5 (XL e badge demo)
- **A chi:** Codex o operaio · piccolo
- **Obiettivo:** (1) a XL l'importo del totale in `groupHeader` va a capo (`€` su riga sola): `lineLimit(1)`/`fixedSize` sull'importo; (2) a XL `MonthBar` non scala; (3) il badge «MODALITÀ DEMO» (`MoneyTrackerApp.swift:272`, solo demo) copre il titolo grande; (4) tab bar con etichette troncate a XL (già in S-10). Le sezioni interne (Uscite ecc.) non sono state fotografate: verificarle a vista.
- **Non fare:** toccare domain/calcoli

### S-12 [~] Movimenti: pagina unica + zona sotto i chip + Ricorrenti (da mockup)
- **A chi:** Codex (o Antigravity) · confronto col mockup OBBLIGATORIO a ogni passo
- **Obiettivo:** (1) Tutti/Fisse/Trasf./Uscite/Entrate nella STESSA pagina: titolo, impostazioni, filtri, ricerca e chip fermi, cambia solo la lista, niente pagine nuove; (2) sotto i chip mese, categorie e filtri esattamente come in `Movimenti.dc.html` (più pulito); (3) solo Ricorrenti resta pagina a sé, da rivedere; (4) elenco scritto delle altre differenze dal mockup; (5) riserve S-11.
- **Leggere:** `Movimenti.dc.html`, `DESIGN_HANDOFF.md` §4, `Views/TransactionsView.swift`; aggiornare l'helper `openTransactionsSection` dei UI test senza aggirarli
- **Fatto quando:** screenshot reali light/dark/XL/tedesco confrontati col mockup, 27 unit + 12 UI verdi
- **Non fare:** toccare calcoli o Domain/
- **Eseguito 2026-11-14 01:14 · Codex:** pagina unica, chip da mockup, Ricorrenti e storico, demo e XL; 27 unit + 12 UI verdi, catture finali light/dark/accessibility-XL/de confrontate a vista, test temporaneo rimosso. Differenze residue e prove in CONSEGNA. Solo il collaudatore o Matteo può passare a [x]. Riserva tab bar XL resta S-10.

### S-13 [ ] Motore ricorrenze a serie virtuali (D-008)
- **A chi:** architetto (piano) poi Codex; collaudatore Claude
- **Obiettivo:** implementare D-008: serie unica, occorrenze virtuali visibili in ogni mese (anche tra un anno), attivazione il primo del mese, salta mese / termina da qui, scelta solo questa / successive / tutte; vecchio motore disattivato senza toccare i dati esistenti
- **Leggere:** `.cantiere/DECISIONI.md` D-008, `Domain/RecurringTransactionEngine.swift`, `Models/Transaction.swift`, `Domain/SchemaMigration.swift`, Sync
- **Fatto quando:** test nuovi (mese corto, 31, anno bisestile, salto, fine serie, 3 frequenze, saldo invariato dai virtuali), migrazione che non altera dati, build + test verdi, Commissione Suprema 10/10
- **Non fare:** convertire lo storico; far entrare i virtuali nei calcoli

- **Sotto-task (piano architetto, D-008/D-009):**
  - S-13a [ ] Calcolo puro + UUIDv5 + codec eccezioni → Codex · nuovi `Domain/RecurrenceCalculator.swift`, `MoneyTrackerTests/RecurrenceCalculatorTests.swift`
  - S-13b [ ] Modello `RecurringRule` + SchemaV3 → Codex (in parallelo ad a) · `Models/RecurringRule.swift`, `Persistence/SchemaMigration.swift`, `MoneyTrackerApp.swift`, `Intents/AddExpenseIntent.swift`, `SchemaMigrationTests.swift`
  - S-13c [ ] Materializer + spegnimento vecchio motore → Codex · richiede a+b
  - S-13d [ ] Editor (solo questa / successive / tutte, salta, termina) → Codex · richiede c
  - S-13e [?] Creare tabella `mt_recurring_rules` su Supabase → **Matteo** (SQL e istruzioni li prepara S-13f)
  - S-13f [ ] Sync → Codex · richiede b; prova in app solo dopo e
  - S-13g [ ] UI → Codex, DOPO che Antigravity chiude S-12 su `TransactionsView`
  - S-13h [ ] Documento + collaudo + Commissione Suprema → collaudatore
  - Ogni passo con confronto mockup dove c'è grafica. Piano completo: `.cantiere/piano-s13.md`

### S-14 [ ] Statistiche: confronto mese su mese
- **A chi:** Codex (o Antigravity) · dopo S-6 (stessa schermata)
- **Obiettivo:** frase/card tipo «Questo mese hai speso il 12% in più per Cibo»: per categoria e totale, mese corrente vs mese precedente, stesso periodo di giorni; colori neutri/«danger» da Theme, mai solo colore (anche testo/freccia)
- **Leggere:** `Statistiche.dc.html` (se il mockup non lo prevede, chiedere a Matteo dove metterlo), `Views/StatisticsView.swift`
- **Fatto quando:** funzione pura in `Domain/` con `Decimal` + test (mese precedente vuoto, divisione per zero, categoria nuova, mese corrente a metà); resa confrontata col mockup in light/dark/XL/tedesco; testi nelle 7 lingue
- **Non fare:** cambiare i calcoli esistenti delle statistiche

### S-10 [ ] Verifica finale + Commissione Suprema
- **A chi:** Claude Code (collaudatore)
- **Obiettivo:** collaudo dell'intero ramo
- **Leggere:** diff del ramo, BRIEF §6–7
- **Toccare:** correzioni minime
- **Fatto quando:** build e test verdi; Dynamic Type XL, VoiceOver, 7 lingue, oscura importi su tutte le schermate, demo, sync, export CSV/PDF, Siri; Commissione Suprema 10/10; **ok di Matteo sull'iPhone** prima del merge su `main`
- **Da S-3 (ok di Matteo, rimandato qui):** taglie di accessibilità oltre XL: la `FloatingTabBar` può superare `reservedHeight` (94 pt fisso) e tagliare le etichette; renderla adattiva. Controllare a vista anche il FAB (ombra e alette azzurre al tocco).
- **Non fare:** merge su `main` senza l'ok di Matteo

## Fatti
<!-- i task chiusi si spostano qui, con data e chi li ha fatti -->
- T-001 [x] Impianto: AGENTS.md §1 compilato, MAPPA.md aggiornata, schede S-0…S-10 scritte (2026-11-13, Claude Code)
- T-000 [x] Trasloco: pacchetto di design già in `02_RISORSE/originali/bucktrail-redesign/`, `catalogo.py` lanciato, gitignore/guardiano/regole uniti (2026-11-13, Claude Code)

---
Modello di task:
```
### T-000 [ ] Titolo
- **A chi:** architetto / operaio / impresa / collaudatore / magazziniere / pulizie / Matteo
- **Obiettivo:**
- **Leggere:**
- **Toccare:**
- **Fatto quando:** (criteri verificabili)
- **Non fare:**
```
