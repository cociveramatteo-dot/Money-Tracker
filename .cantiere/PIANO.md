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

### S-6 [x] Statistiche
- **A chi:** Antigravity col modello più forte (o Codex)
- **Obiettivo:** schermata come `Statistiche.dc.html`; grafico con Swift Charts `BarMark` + `position(by:)`
- **Blocco superato da Matteo 2026-11-16:** autorizzato confronto con sorgente HTML inline, strutture sc-for e handoff §4; nessun runtime o rendering richiesto. Screenshot originali PNG assenti; confronto visivo definitivo al collaudatore.
- **Leggere:** `DESIGN_HANDOFF.md` §4 Statistiche, `Views/StatisticsView.swift`
- **Toccare:** `StatisticsView.swift`
- **Fatto quando:** export PDF invariato, 6M/12M, media uscite e confronto anno precedente come prima; test verdi
- **Non fare:** cambiare calcoli o `Export/`
- **Collaudo 2026-11-16 11:34: [x] collaudo ok** (visivo da screenshot + diff). Differenze accettate: confronto annuale in sezione separata (invariante esistente), target 6M/12M 44pt (HIG), 12M con iniziali. Aperto non bloccante: titoli Andamento/Per categoria mostrano "[DA COMPLETARE]" in de (e nelle altre 5 lingue) finché Matteo non approva le traduzioni (⏳). Nessun colore non adattivo, BarMark+position(by:) presenti, zone intoccabili e test esistenti non toccati.

- **Eseguito Codex 2026-11-16 10:48:** tre tile, card Andamento/categorie, BarMark affiancati, 12M con iniziali leggibili a XL. Calcoli/cache/PDF invariati. Build + 82 unit + 3 UI TabBarAppearance + 4 nuovi UI S-6 verdi (dark separato). Dodici screenshot finali ispezionati, `.cantiere/tmp/s6/comparison.png`. Confronto con sorgente HTML, nessuna conformità dichiarata. Differenze: target 44 pt, impostazioni preservate, sezioni aggiuntive esistenti e confronto annuale anziché mensile nel footer; titoli Andamento/Per categoria da tradurre nelle sei lingue, ⏳.

### S-7 [x] Pianifica (Budget + Obiettivi)
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Pianifica.dc.html`
- **Leggere:** `DESIGN_HANDOFF.md` §4 Pianifica, `Views/PianificaView.swift`
- **Toccare:** `PianificaView.swift` e relative card
- **Fatto quando:** soglie 80/100% lette dalla logica esistente (non ricalcolate nella vista); badge testuale di stato; progresso complessivo ponderato invariato; test verdi
- **Non fare:** ricalcolare soglie, toccare modelli
- **Collaudo 2026-11-16 11:34: [x] collaudo ok.** Soglie via BudgetStatus/ProgressBar esistenti (nessuna soglia nelle viste), badge testuale (Soglia 80%/Sforato/%) sempre presente, + 44x44, XL e tedesco senza tagli. Differenze accettate: mese separato dalla hero (navigazione esistente), % hero 30 vs 28, icone tinta unica. Aperto non bloccante: "[DA COMPLETARE]" visibile in de (hero e sottotitoli obiettivi) fino ad approvazione traduzioni.

- **Eseguito Codex 2026-11-16 11:08:** segmented, hero budget/obiettivi con anello, card dedicate e + 44×44 verso editor esistente. Soglie delegate a BudgetStatus/ProgressBar invariati, progressi ponderati e speso invariati. Build senza warning, 82 unit e 7 UI mirati verdi tra run base e acquisizioni finali (dark separato); 16 screenshot finali ispezionati in `.cantiere/tmp/s7/comparison.png`. Primo run nuove prove rosso per ereditarietà identificatore SwiftUI, risolto con contenitore accessibile e selezione per etichetta senza togliere asserzioni. Sei chiavi nuove x7; traduzioni non fornite `[DA COMPLETARE]`, ⏳. Differenze sorgente: navigazione mese e azioni esistenti preservate, percentuale hero DS 30 anziché 28, importi con /, icone obiettivo tinta accent. Nessuna conformità dichiarata; collaudo definitivo pendente.

- **Correzione aggiuntiva richiesta da Matteo · 2026-11-16 11:48 · Codex:** padding esterno inferiore dello ScrollView di 76 pt (token DS), per riservare la fascia del FAB anche a inizio scroll, in Budget e Obiettivi. Aspetto delle card e logica invariati. UI light/dark/XL verificano frame scroll sopra FAB e screenshot iniziali/fondo. S-7 resta [x] dal collaudo precedente; il solo padding è da ricontrollare.

### S-8 [x] Conti (2026-11-16 11:52 · collaudo ok)
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Conti.dc.html`, raggruppamento per tipo solo visivo
- **Leggere:** `DESIGN_HANDOFF.md` §4 Conti, `Views/AccountsView.swift`
- **Toccare:** `AccountsView.swift`
- **Fatto quando:** swipe/long-press, archiviazione ed esclusione dal totale invariati; test verdi
- **Non fare:** cambiare il modello dei conti
- **Collaudo 2026-11-16 11:34: [!] NON PASSA per un punto.** Correggere (Codex): in `Views/AccountsView.swift:~183` le righe archiviate espanse usano `.opacity(0.35)` sull'intera riga: testo e importi quasi illeggibili (contrasto ~1,5:1, vedi `.cantiere/tmp/s8/states.png` riquadro 3, e dark). Sostituire con attenuazione leggibile (es. opacity 0.6-0.65 o colori DS.ink2 senza opacity sull'intera riga) mantenendo la distinzione visiva e la riga ripristinabile; ricontrollare light/dark/XL. Tutto il resto conforme: swipe/long-press, archiviazione, esclusione dal totale, hideBalance, hero/gruppi/icone 40/13, tratteggiata Archiviati con conteggio separato accettata. Dopo il fix basta ricollaudo del solo stato archivi espansi. Aperto non bloccante: "[DA COMPLETARE]" in de (hero, gruppo Liquidità/Risparmio).

- **Eseguito Codex 2026-11-16 11:31:** hero patrimonio, gruppi visivi per tipo, totali gruppo esclusi correttamente, icone tinta, avviso soglia da UserDefaults esistente, riga tratteggiata archiviati con apertura/ripristino. Totali globali, mutazioni e AddAccountView invariati. Build senza warning, 82 unit + 12 UI mirati con ultimi esiti verdi tra i run (non un singolo run completo). Corretto hit target Archiviati dopo primo test rosso, nessuna asserzione rimossa. 13 immagini finali ispezionate: light/dark/XL/de, escluso, archiviati chiusi/aperti, soglia lunga XL, saldi nascosti XL. `.cantiere/tmp/s8/`. Residui: traduzioni ⏳, Archiviati con conteggio separato, icone SF invece SVG, attenuazione preesistente righe archiviate da valutare al collaudo. Nessuna conformità dichiarata.

- **Correzione collaudo · 2026-11-16 11:48 · Codex [~]:** rimossa opacity 0.35 dalle righe archiviate; testi/importi/icone usano DS.smoke opaco nello stato archiviato. Contrasto token testo/sfondo 5,60:1 light e 7,28:1 dark; icone almeno 5,14:1 / 5,32:1 sui fondi tinta. Distinzione dagli attivi conservata, menu/ripristino invariati e verificati in light/dark/XL. Build senza warning, 82 unit e 3 UI mirati verdi; 15 screenshot ispezionati in `.cantiere/tmp/review-s7-s8/`, incluso prima/dopo del riquadro 3 precedente. Localizable.strings non toccati. Ricollaudo dello stato archiviati espansi e del padding S-7.

- **Ricollaudo 2026-11-16 11:52 · collaudatore:** ok. Opacity rimossa, DS.smoke opaco (ricalcolato 5,60:1 light / 7,28:1 dark), riga distinta da quelle attive (intestazione ARCHIVIATI, testi grigi), ripristino via contextMenu invariato; padding S-7 76 pt confermato. Solo AccountRow/PianificaView + nuovo test UI, nessun Localizable/zona intoccabile/test esistente toccato.

### S-9 [x] (collaudo ok 2026-11-13 23:16) Impostazioni, sheet di inserimento, categorie, login
- **A chi:** Antigravity
- **Obiettivo:** stessi token per coerenza (schermate non disegnate)
- **Leggere:** `Views/Theme.swift`, componenti di S-2, `SettingsView.swift`, `AddTransactionView`, viste Auth
- **Toccare:** solo aspetto di queste viste
- **Fatto quando:** tutte le funzioni presenti, 7 lingue senza testi tagliati (tedesco), light/dark; test verdi
- **Non fare:** toccare `Auth/` logica, Sync, Face ID
- **Collaudo 2026-11-13 23:16 (collaudatore):** [x] conforme. Runner ripristinato (shutdown/boot). 27 unit + 12 UI verdi sul 37445D1E; funzioni conservate (ricerca, filtri, swipe, trasferimenti, ricorrenti). Resa a vista hub: light, dark, XL, tedesco ok. Riserve cosmetiche → S-11.

### S-11 [x] Riserve da S-5 (XL e badge demo) — assorbito da S-12; resta solo tab bar XL in S-10
- **A chi:** Codex o operaio · piccolo
- **Obiettivo:** (1) a XL l'importo del totale in `groupHeader` va a capo (`€` su riga sola): `lineLimit(1)`/`fixedSize` sull'importo; (2) a XL `MonthBar` non scala; (3) il badge «MODALITÀ DEMO» (`MoneyTrackerApp.swift:272`, solo demo) copre il titolo grande; (4) tab bar con etichette troncate a XL (già in S-10). Le sezioni interne (Uscite ecc.) non sono state fotografate: verificarle a vista.
- **Non fare:** toccare domain/calcoli

### S-12 [x] Movimenti: pagina unica + zona sotto i chip + Ricorrenti (da mockup) — collaudo 2026-11-14 01:30 ok
- **A chi:** Codex (o Antigravity) · confronto col mockup OBBLIGATORIO a ogni passo
- **Obiettivo:** (1) Tutti/Fisse/Trasf./Uscite/Entrate nella STESSA pagina: titolo, impostazioni, filtri, ricerca e chip fermi, cambia solo la lista, niente pagine nuove; (2) sotto i chip mese, categorie e filtri esattamente come in `Movimenti.dc.html` (più pulito); (3) solo Ricorrenti resta pagina a sé, da rivedere; (4) elenco scritto delle altre differenze dal mockup; (5) riserve S-11.
- **Leggere:** `Movimenti.dc.html`, `DESIGN_HANDOFF.md` §4, `Views/TransactionsView.swift`; aggiornare l'helper `openTransactionsSection` dei UI test senza aggirarli
- **Fatto quando:** screenshot reali light/dark/XL/tedesco confrontati col mockup, 27 unit + 12 UI verdi
- **Non fare:** toccare calcoli o Domain/
- **Eseguito 2026-11-14 01:14 · Codex:** pagina unica, chip da mockup, Ricorrenti e storico, demo e XL; 27 unit + 12 UI verdi, catture finali light/dark/accessibility-XL/de confrontate a vista, test temporaneo rimosso. Differenze residue e prove in CONSEGNA. Solo il collaudatore o Matteo può passare a [x]. Riserva tab bar XL resta S-10.

### S-13 [x] (S-13f chiuso da Matteo 2026-11-16) Motore ricorrenze a serie virtuali (D-008)
- **A chi:** architetto (piano) poi Codex; collaudatore Claude
- **Obiettivo:** implementare D-008: serie unica, occorrenze virtuali visibili in ogni mese (anche tra un anno), attivazione il primo del mese, salta mese / termina da qui, scelta solo questa / successive / tutte; vecchio motore disattivato senza toccare i dati esistenti
- **Leggere:** `.cantiere/DECISIONI.md` D-008, `Domain/RecurringTransactionEngine.swift`, `Models/Transaction.swift`, `Domain/SchemaMigration.swift`, Sync
- **Fatto quando:** test nuovi (mese corto, 31, anno bisestile, salto, fine serie, 3 frequenze, saldo invariato dai virtuali), migrazione che non altera dati, build + test verdi, Commissione Suprema 10/10
- **Non fare:** convertire lo storico; far entrare i virtuali nei calcoli

- **Sotto-task (piano architetto, D-008/D-009):**
  - S-13a [x] (2026-11-14, collaudo ok) Calcolo puro + UUIDv5 + codec eccezioni → Codex · nuovi `Domain/RecurrenceCalculator.swift`, `MoneyTrackerTests/RecurrenceCalculatorTests.swift`
  - S-13b [x] (2026-11-14, collaudo ok) Modello `RecurringRule` + SchemaV3 → Codex (eseguito dopo a) · `Models/RecurringRule.swift`, `Persistence/SchemaMigration.swift`, `MoneyTrackerApp.swift`, `Intents/AddExpenseIntent.swift`, `SchemaMigrationTests.swift`
  - Verifica a+b (Codex, 2026-11-14 02:05): build OK; 40 unit verdi (27 esistenti + 13 nuovi), migrazioni V1→V2, V2→V3 e V1→V3 su disco OK; UI 10/12, due fallimenti riprodotti dopo shutdown all + boot → S-15. Da collaudare; nessun test esistente modificato salvo aggiunte a SchemaMigrationTests.
  - S-13c [x] (2026-11-14 09:55, collaudo ok) Materializer + spegnimento vecchio motore → Codex · implementato; verifica completata 2026-11-14 09:29: build e 48 unit verdi, UI 10/12 sullo stesso codice (due sessioni, stop intermedio richiesto da Matteo). I due fallimenti sono gli stessi S-15. Nessun codice cambiato alla ripresa; da collaudare prima di d.
  - S-13d [x] collaudato 2026-11-14 10:20 (ok, 60 unit verdi; note in CONSEGNA) · Editor (solo questa / successive / tutte, salta, termina) → Codex · implementato 2026-11-14 09:56: Domain + 12 nuovi test; build e 60 unit verdi. Da collaudare. Stato errore osservabile pronto; alert effettivo e collegamento degli avvii del materializer obbligatori in S-13g (UI intoccabile in d).
  - S-13e [x] fatto da Matteo 2026-11-14 10:27 (rls_attiva = true, numero_policy = 4; isolamento tra utenti da provare col Sync) · Creare tabella `mt_recurring_rules` su Supabase → **Matteo** (SQL e istruzioni li prepara S-13f)
  - S-13f [x] (chiuso da Matteo 2026-11-16: prova reale Supabase fatta e OK) Sync → Codex · parte Swift **collaudata ok 2026-11-14 10:40** (diff cff65f7); resta [~] FUORI DAL RESTYLING: manca manca la prova reale su Supabase (due dispositivi, due utenti) — vedi S-17 e S-13g
    - 2026-11-14 10:17 · Codex: preparata **solo la parte SQL**, su richiesta di Matteo, in `PER-MATTEO.md` (tabella, indice user_id, grant CRUD e 4 policy RLS). Da collaudare; non eseguita su Supabase. S-13e resta a Matteo; DTO/push/pull/clearLocalData e test Sync ancora da implementare in S-13f.
    - 2026-11-14 10:33 · Codex: DTO, upsert/deleteOrphans, pull max watermark, logout e 4 nuovi test; build + 64 unit verdi (`/tmp/moneytracker-s13f-recheck.log`). Prova reale e collaudo da fare; scoperta S-16 separata.
    - 2026-11-14 10:40 · collaudatore: DTO 16 colonne = SQL, CHECK frequency coerente coi valori del calcolatore, NULL espliciti, push/deleteOrphans filtrati per user_id con fetch throwing, pull max watermark (9 combinazioni), logout ok, 64 unit verdi (log riletto). Nessun difetto bloccante; un rischio di pull → S-17.
  - S-13g [x] UI funzionale → Codex · implementata 2026-11-14: creazione regole/ID deterministici, editor ambiti/salta/termina, serie programmate e virtuali futuri esclusi dai totali, alert errori e avvii lifecycle già presenti verificati. Models/Domain/Sync intatti. Build + 67 unit + 1 nuovo UI verdi (2026-11-14 10:59, `/tmp/moneytracker-s13g-final.log`). Collaudo indipendente da fare. Traduzioni provvisorie nelle 7 lingue → S-19. Rifinitura grafica → S-18. · **collaudato 2026-11-14 11:15** (be6ceb0): ambiti/salta/termina/alert/avvii ok, virtuali fuori dai totali, build+67 unit+1 UI verdi, Domain/Models/Sync intatti. Note: doppio safeSave ridondante in AddTransactionView; il 3° tentativo UI è stato aggiustato solo nel test.
  - S-13h [x] (Commissione 10/10 il 2026-11-16 dopo S-29) Documento + collaudo + Commissione Suprema → collaudatore · aggiornare anche i soli commenti obsoleti sul vecchio actor in AccountBalanceCache, CurrencyFormatting e Logging (nessun riferimento eseguibile residuo). · 2026-11-14 11:08: commenti obsoleti sistemati (0 riferimenti a RecurringTransactionActor), docs/MoneyTracker.md+PDF aggiornati, 68 unit verdi. **Commissione Suprema NON a 10/10** → checkpoint (push) bloccato fino a S-21/S-22/S-19/S-18.
  - Ogni passo con confronto mockup dove c'è grafica. Piano completo: `.cantiere/piano-s13.md`

### S-34 [x] (collaudo ok 2026-11-17, 2 difetti corretti) Libro: versioni vere nel changelog (D-013)
- **Chi:** redattore, dopo il riallineo del libro (S-2…S-12 + sezione 6). Mappare le voci «v3.x» su versioni 3.1, 3.2…; S-13 rilascio a sé. Solo `docs/MoneyTracker.md`; criterio da confermare con Matteo se ambiguo.

### S-35 [x] Spezzare TransactionsView (864 righe)
- **Chi:** Codex (Antigravity sospeso). Refactor puro, nessuna modifica visiva né di logica; collaudatore sul diff.
- **Collaudo 2026-11-17 11:48 (collaudatore):** [x] collaudo ok. Spostamento identico riga per riga (modificatori, chiavi, accessibilityIdentifier), Binding corretti, file nuovi coperti dal gruppo sincronizzato del target, TransactionsView 579 righe, `git diff --check` pulito, nessuna zona protetta/test toccati. Suite completa su iPhone 18 Pro: 135/135 verdi (90 unit + 45 UI), 0 falliti.
- **Esecuzione 2026-11-17 11:10:** ramo `refactor-transactionsview` da main; 4 sotto-viste estratte, TransactionsView 864 → 579 righe. Build clean verde, 90 unit + 45 UI verdi; S-33 non riprodotto. Nessun test o zona protetta modificati; nessun push/merge. Dettagli e log in CONSEGNA.md.

### S-36 [x] Potare i rami vecchi — chiuso 2026-11-24 per decisione di Matteo: gruppo A cancellato 2026-11-17 11:56; rami nightly vecchi e `tmp-stash-inspect` cancellati (tag `archivio/tmp-stash-inspect`); tenuto solo `fix/nightly-20260727-0411` (tocca `Auth/`). Collaudo: `.cantiere/collaudo-ios-2026-11-24.md`
- **Chi:** pulizie (Haiku) elenca i rami già mergiati; Matteo approva la cancellazione. S-16 (precisione Decimal) resta [?] su decisione di Matteo.

### S-37 [x] Commissione 2026-11-17 — integrità sync e parsing (autorizzato da Matteo) — chiuso 2026-11-17 13:35, collaudo ok
- (1) `Sync/SyncService.swift:584-587` fetch con `try?`→`?? []` prima di `deleteOrphans` (alta: può svuotare il cloud): usare `try context.fetch` come per le regole. (2) `Formatting/CurrencyFormatting.swift:65-66` `parseAmount` accetta input letti a metà («12abc»→12). (3) `MoneyTrackerApp.swift:85-93` store in memoria con push attivo: flag `usingVolatileStore`. S-16 esplicitamente escluso.

- **Collaudo 2026-11-17 13:35 (collaudatore):** [x] collaudo ok. Fetch tutti throwing, nessun try?/?? [] nel push; unica delete remota in deleteOrphans con guardia volatile; flag impostato nel catch; parseAmount regex completa, test esistenti invariati. Suite su iPhone 18 Pro: 94 unit + 45 UI verdi, 0 falliti. `git diff --check` pulito. S-16 non toccato.
- **Eseguito Codex 2026-11-17 12:52:** ramo `fix-sync-integrita` da main; quattro fetch throwing prima delle scritture remote, flag volatile con blocco push/debounce/retry/delete remoto, parsing completo degli importi e degli override ricorrenze (unica modifica Domain autorizzata in chat). Quattro nuovi test, nessun test esistente modificato. Build pulita e suite completa verdi: 94 unit + 45 UI. S-33 non riprodotto. S-16 invariato. Nessun push/merge. Dettagli in CONSEGNA.md.

## Progetto SOCIAL (avviato 2026-11-17)

Leggere `SOCIAL/direttive-social.md` prima di ogni lavoro social.

### SC-0 [x] Calendario approvato in blocco da Matteo il 2026-11-20, a condizione di coprire tutta l’app. Post-3–42, con mappa di copertura. Post-12 approvato in otto slide. Restano produzione e date effettive.
### SC-9 [x] Post-3–42 prodotti per Instagram e TikTok e verificati in Drive «Da postare». Seconda metà: 120 slide per canale, 103 con catture reali, 260 file. Post-39 e 41 in revisione prima della pubblicazione. Calendario e pubblicazione gestiti direttamente da Matteo.
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** Post 5–15 presenti in Drive «Da postare» (9 cartelle visibili, 84 file); gli esportatori sono in `SOCIAL/caroselli/v2` e `esporta-post.py`. La pubblicazione la fa Matteo (PER-MATTEO).

### SC-8 [x] Direttive unificate, archivio schermate, indice guide, revisione visiva post 1 e 2 e riordino locale · pronto per verifica di Matteo.
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** `SOCIAL/direttive-social.md`, `schermate-app/`, `guida/` e `calendario-v2.md` presenti e collegati dalle regole del progetto; nessun rinvio rotto.
### SC-1 [x] chiuso 2026-11-18 14:30 (Matteo: bio, link con UTM, foto su IG/TikTok/YouTube, banner YouTube v1; resta solo il nome TikTok dal 24/11). Account social creati 2026-11-17 (Gmail, IG Creator+2FA, TikTok personale+2FA, YouTube; @bucktrailapp). Restano: bio e foto su IG/TikTok, foto e descrizione YouTube, nome TikTok il 24/11 (Matteo): vedi PER-MATTEO. **Apple Developer Program NON pagato per scelta di Matteo (2026-11-17):** prima si cerca un segnale di interesse sui social; link in bio = landing con email (waitlist), non pre-order.
### SC-1b [x] chiuso 2026-11-17: Matteo ha confermato le soglie in DECISIONI.md Soglia di decisione per pagare Apple (Matteo): [DA COMPLETARE] quali numeri contano come «segnale» (es. iscritti alla waitlist, follower, tempo medio sopra la mediana) e entro quando. Il manuale non dà benchmark: la soglia è sua.
### SC-2 [?] Materiale per i contenuti faceless: registrazioni schermo, video delle mani col telefono, screenshot (Matteo): lista in PER-MATTEO.
### SC-3 [x] fatto dal redattore, approvazione Matteo ⏳ in APPROVAZIONI.md Testi di base (redattore): bio, caption, nome/sottotitolo/keyword/descrizione App Store IT+EN, hook dei primi format. Solo claim ammessi (manuale §1.1–1.3). Poi approvazione Matteo in APPROVAZIONI.md.
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** testi approvati e bio aggiornate da Matteo (STATO 2026-11-24); righe aggiornate in APPROVAZIONI. La scheda App Store si ricontrolla solo prima dell'invio ad Apple, che non parte senza Matteo.
### SC-7 [x] (post 1 pronto e approvato da Matteo 2026-11-19; resta la pubblicazione e i post successivi) Riscrivere i contenuti in formato faceless (redattore, poi capocantiere) — decisione 2026-11-19
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** contenuti riscritti in formato faceless: post 1 e 2 pubblicati da Matteo, post 5–15 prodotti. Restano le sole pubblicazioni (PER-MATTEO).
Aggiornato 2026-11-19 01:38 (segretario): post 1 pubblicazione gio 19/11 ore 13:00 a cura di Matteo; S-35 fatto (curva Home verificata da Matteo). Hook scelto: «Ogni conto al suo posto. Ogni euro in chiaro.» («Arrivi a fine mese?» scartata; «Chiudi Excel. I tuoi conti sono già qui.» tenuta per altri post). Post 2 = ven 20/11 18:30, F13 sulle spese fisse scelto da Matteo. Carosello di 8 slide con schermate Home, Ricorrenti e Budget, grafici esplicativi e chiusura con MacBook esportato su Drive (slide 04 Instagram verificata anche nel ritaglio quadrato). [Pubblicato su Instagram il 20/11](https://www.instagram.com/p/Df-MToYEZoR/); [TikTok pubblicato](https://www.tiktok.com/@bucktrailapp/photo/7710312019425217824). F1 resta disponibile per una pubblicazione successiva. Adattare `SOCIAL/testi-v1.md` e i primi format (F1, F8 rifatto, sondaggio storie) al formato mani+telefono / carosello bianco con titolo grande, niente parlato, musica TikTok. Output per ogni contenuto: titolo a schermo, testo slide, caption, lista materiale richiesto a Matteo (SC-2). Riferimento: memoria `project-social-formato-faceless`, DECISIONI 2026-11-19.
### SC-4 [x] Landing **online** su bucktrailapp.com (2026-11-18): IT/EN, lista d'attesa con double opt-in (Brevo), privacy approvata, logo email. Restano: approvazione grafica (APPROVAZIONI), collaudo nel browser reale, immagini Higgsfield (opzionali).
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** landing online verificata: `/`, `/en.html`, `/privacy.html`, pagine di conferma e `www` rispondono 200 in meno di 0,5 s; il contenuto online coincide con `SOCIAL/landing` (differenze: solo 4 righe dell'offuscamento email di Cloudflare). Modulo non provato con un invio reale per non creare contatti veri in Brevo. Il guardiano ora controlla questa cartella (accessibilità, Lighthouse, link).
### SC-4c [x] Landing IT/EN · lancio iPhone e Android, collegamento bancario facoltativo in arrivo. Anteprima locale verificata in Chrome. Matteo ha approvato i contenuti e chiesto correzioni a tab bar nei mockup e messaggio del modulo locale, entrambe implementate. Rimossi anche i bordi chiari nei mockup Aggiungi, Ricorrenza e Comandi. Pubblicato 2026-11-20 su Cloudflare Pages con approvazione di Matteo; verificati dominio IT/EN e validazione del Worker.
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** come SC-4: landing IT/EN online e uguale al locale, `hreflang` presente in entrambe le pagine.

### SC-3c [x] Bio e chiusura dei prossimi post approvate da Matteo il 2026-11-20. Matteo ha comunicato l’aggiornamento dei profili; dicitura iPhone e Android verificata in YouTube Studio. Post fissato di presentazione e banner YouTube aggiornati da Matteo. Email di lancio rimandata a quando saranno disponibili i link App Store e Google Play.

### SC-5 [x] Script FFmpeg e modello ASS pronti per il collaudo. Test di fumo ASS/SRT e conversione HDR sintetica superati.
**Chiuso 2026-11-24 (capocantiere, collaudo tecnico in autonomia):** `SOCIAL/montaggio/test-fumo.sh` superato (ASS, SRT, safe zone, tagli, 2x, specifiche master); ffmpeg presente.
### SC-6 [x] Diario delle metriche (Copilot: task piccolo e già descritto): foglio come manuale §9.7. Creati `SOCIAL/diario-metriche.csv` e `SOCIAL/diario-metriche.md`; una riga ESEMPIO vuota, nessun dato reale; da collaudare.
**Collaudo 2026-11-24 (capocantiere):** ok. `SOCIAL/diario-metriche.csv` (15 colonne come manuale §9.7) già popolato con le righe reali del 19/11 (Instagram e TikTok); `diario-metriche.md` riporta mediana, soglie di promozione e abbandono, formula dell'engagement rate. Nessun dato inventato.
Primo rilevamento reale registrato il 2026-11-20: post 1 su Instagram e TikTok, con link e metriche nel diario.


### S-38 [x] Commissione — pacchetto A (Codex): virtuali che ignorano filtri avanzati, date filtro personalizzato non salvate, conferma per «Salta mese/Termina…», «•••• €» fisso, detector ricalcolato a ogni render, set di ID regole in `movementList`, force-unwrap (RecurrenceControls:69, RecurringSeriesDetector:58-66), `RecurringMaterializer` duplica `snapshot`, tipo/selected ridondanti in `typeChips`.
**Eseguito 2026-11-24 (capocantiere, su richiesta di Matteo, Domain toccato solo per Detector e Materializer):** virtuali con filtri importo e periodo; date del periodo salvate (AppStorage); conferma per «Salta mese/Termina…» (chiavi esistenti, nessuna stringa nuova); «•••• €» usa il simbolo valuta; rilevamento serie in cache con impronta; set ID regole calcolato una volta; force-unwrap tolti (RecurrenceControls, Detector); Materializer usa `RecurringSeriesEditor.snapshot`; chip tipo senza `selected` ridondante. Verifica: build ok, 94/94 unit, 13/13 UI (ricorrenze, appearance, transazioni). Da collaudare.
**Collaudo 2026-11-24 13:25 (capocantiere su richiesta di Matteo, non indipendente):** ok. Diff nel perimetro (Domain: solo Detector e Materializer, comportamento invariato); build ok, 94/94 unit, 13/13 UI su ricorrenze e transazioni, suite UI 45/48 (3 rossi = S-43 preesistente). Limite: filtri sui virtuali e date salvate non coperti da test UI, verificati solo a codice. Dettagli in `collaudo-ios-s38-s39-s40-2026-11-24.md`.

### S-39 [x] Commissione — traduzioni (redattore): ~40 stringhe visibili in italiano in tutte le lingue (Settings, notifiche, Login/SignUp, AuditLog, Budget, filtri…), frasi composte a pezzi, chiavi doppie «Fine»/«Tipo». Poi approvazione Matteo.
**Eseguito 2026-11-24 (capocantiere):** 44 chiavi aggiunte in en/de/es/fr/ja/zh-Hans (Login, SignUp, Settings, AuditLog, blocco app, HeroCard «Saldo/Atteso», Periodo, ecc.); chiavi doppie «Fine»/«Tipo» tolte (valori identici). plutil ok, nessun duplicato, 94/94 unit. Proposte in APPROVAZIONI (S-39 ⏳). Escluse di proposito: «MoneyTracker», «Bucktrail», «MONEYTRACKER», «Card» e l'anteprima «+20 € oltre». «ELIMINA» resta tale (il codice lo confronta). Da fare: controllo visivo in tedesco e approvazione di Matteo.
**Collaudo tecnico 2026-11-24 13:25 (capocantiere):** ok (plutil x6, nessuna chiave doppia, 44 chiavi per lingua, segnaposto non toccati). Resta l'approvazione di Matteo (APPROVAZIONI S-39 ⏳): per questo resta `[~]`.
**Chiuso 2026-11-24 13:40:** traduzioni approvate da Matteo in chat (senza madrelingua); collaudo tecnico già ok.

### S-40 [x] Commissione — font fissi (Codex): ~200 `.font(.system(size:))` → token `DS.Typo.*` (Dynamic Type), `SectionLabel` incluso.
**Eseguito 2026-11-24 (capocantiere):** 239 `.font(.system(size:))` → `.scaledFont(size:weight:)` (modificatore in `Theme.swift`, `@ScaledMetric`, aspetto identico a dimensione standard, segue Dynamic Type). Scelta: non mappati su `DS.Typo.*` perché Inter/Grotesk cambierebbero l'aspetto di icone e numeri decorativi (restyling solo visivo). Resta un `.system(size:design:.monospaced)` di debug in `MoneyTrackerApp.swift:295`. Verifica: build ok, 94/94 unit, suite UI 45/48 (3 rossi = S-43, preesistente). Da collaudare a vista con testo grande (XL/accessibilità) e in tedesco.
**Collaudo 2026-11-24 13:25 (capocantiere su richiesta di Matteo, non indipendente):** ok. 239 sostituzioni meccaniche, nessun cambio di aspetto a dimensione standard; Appearance XL e tedesco verdi nella suite; controllo a vista in simulatore: Home in tedesco a corpo accessibilità L e in italiano a XXXL leggibili. Nota: a XXXL tab bar e testi lunghi si troncano (già noto da S-3, non causato da S-40).

### S-43 [x] Test UI `SentieroReviewFixUITests` rosso (testLight/testDark/testXL)
- **A chi:** Codex (o collaudatore per la diagnosi)
- **Scoperto:** 2026-11-24, suite UI completa. L'asserzione `collection.frame.maxY <= fab.frame.minY` (riga 41) fallisce con 746 > 682, identico in L e XL.
- **Preesistente:** fallisce uguale su a4131c2 (prima di S-38 e S-40), quindi non causato da questi lavori. Da capire se è il test a essere superato (la lista scorre sotto il FAB per scelta del redesign) o la schermata Pianificazione a sbordare.
- **Non fare:** indebolire l'asserzione senza aver capito la causa.
**Diagnosi 2026-11-24:** causa individuata, test superato dal progetto. `PianificaView` fa scorrere la lista sotto la barra di proposito (`contentMargins(.bottom)`, commento alle righe 118-120), quindi `collection.frame.maxY <= fab.frame.minY` è falso per progetto (746 > 682). Correzione proposta: dopo 3 swipe verso l'alto verificare che il testo più basso nella scroll view sia sopra il FAB (`lowestText <= fab.frame.minY`). **Non applicata:** la modifica al test è stata bloccata dal controllo automatico dei permessi; serve l'ok esplicito di Matteo o di Codex.
**Chiuso 2026-11-24 13:40:** Matteo ha autorizzato la correzione in chat. Asserzione sostituita come proposto (testo più basso della lista sopra il FAB dopo 3 swipe). SentieroReviewFixUITests 3/3 verdi (testLight, testDark, testXL). Nessun codice dell'app toccato.

### S-41 [x] Home — spesa fissa singola nel mese di competenza (Matteo, 2026-11-20)
Il saldo atteso, la curva e le carte dei conti in Home considerano la spesa fissa pianificata senza ricorrenza solo nel mese della sua data. La spesa resta visibile nel suo mese in Movimenti. Il totale «A conti fatti» nella tab Conti ha orizzonte complessivo. Da verificare il passaggio di mese nell’interfaccia durante il collaudo.
**Collaudo 2026-11-24:** collaudo ok (94 unit, UI mirati, visivo chiaro/scuro/XL, nessuna zona intoccabile). Riserva: passaggio di mese non provato in UI. Dettagli in `.cantiere/collaudo-ios-2026-11-24.md`.

### S-42 [x] Annullamento eliminazione serie e layout Ultimi movimenti (Matteo, 2026-11-20)
L’azione swipe che apre l’editor di una ricorrenza non rimuove più la riga in anticipo. La lista Ultimi movimenti usa l’altezza reale del contenuto mantenendo le azioni swipe native. Verifica demo su iPhone 18 Pro con screenshot e test UI dedicati.
**Collaudo 2026-11-24:** collaudo ok (3 test UI verdi). Difetto estetico minore: filo separatore sotto l'ultima riga di Ultimi movimenti.



### S-15 [x] Diagnosticare due test UI che non trovano il movimento appena salvato
- **Collaudo 2026-11-15 11:55 (collaudatore):** [x] collaudo ok — test UI corretti (filtro persistente ≥20€ azzerato da UI), 2/2 verdi nei log; nessun codice app cambiato. 78 unit riverificate in locale (78 passed, Swift Testing). UI non rilanciati: log di Codex coerenti (full 13/15 prima del fix, S-15 2/2 verdi in rilancio mirato; nessun full run unico 15/15). Riserva: blocco reale su Tutte non riprodotto in demo, NON dichiarato risolto; serve prova di Matteo su dati reali (PER-MATTEO).
- **Collaudo 2026-11-14:** i due test falliscono IDENTICI (righe 55 e 68) anche sul commit 0a76000, prima di S-13: indipendenti da S-13, regressione precedente (probabile S-12 o prima).
- **A chi:** collaudatore (Claude Code · Sonnet)
- **Scoperto:** verifica S-13a+b, 2026-11-14 02:05. Non attribuito al nuovo schema: causa da verificare.
- **Casi:** `NavigationStressUITests.testAddMultipleTransactionsThenDeleteAll` (riga 55) e `TransactionFlowUITests.testAddTransactionWithoutCategoryDefaultsToAltro` (riga 68).
- **Prove:** suite completa 10 UI verdi / 2 falliti; entrambi ancora falliti dopo `simctl shutdown all` e boot. 40 unit verdi. Log `/tmp/moneytracker-s13-build.log` e `/tmp/moneytracker-s13-recheck.log`; xcresult nei rispettivi log. Nessuno screenshot di fallimento esportabile dal risultato.
- **Aggiornamento S-13c (2026-11-14 09:29):** completati i sei UI sospesi (5 verdi, senza-categoria:68 fallito); aggregato con la sessione interrotta: 10/12, stessi due S-15. Nessun altro fallimento. Codice/test invariati; log `/tmp/moneytracker-s13c-ui-resume.log` e `/tmp/moneytracker-s13c-build.log`.
- **Fatto quando:** causa dimostrata e 12 UI verdi; distinguere persistenza, visibilità/accessibilità e automazione. Nessuna asserzione indebolita.
- **Vincoli:** non cambiare viste/test esistenti senza assegnazione e autorizzazione specifica; eventuale correzione oltre il perimetro va prima proposta a Matteo.

- **Eseguito Codex 2026-11-15 (autorizzazione Matteo in chat):** causa dimostrata nella gerarchia del fallimento: filtro avanzato persistente ≥20€, non azzerato dal chip Tutti, nasconde i movimenti 10–15€ dei due test. Test corretti azzerando i filtri dalla UI; aggiunte attese del focus e chiusura form (osservato anche un errore XCUITest di digitazione senza focus), ricerca riga accessibile con nome e metadati, attesa reale della cancellazione. Nessun codice app cambiato per S-15. Entrambi verdi nel rilancio finale `/tmp/moneytracker-s25-s15-fixed.log` (TEST SUCCEEDED), da collaudare.

### S-7p [x] Plurale dei giorni rimanenti
- **A chi:** Codex, assegnato da Matteo in chat.
- **Eseguito 2026-11-16 12:14:** sette Localizable.stringsdict; singolare in it/en/de/es/fr, sola forma other in ja/zh-Hans. Plurali italiani e testi plurali esistenti invariati. Pianifica usa localizedStringWithFormat. Verifica runtime di 0/1/2 in tutte sette lingue (21 casi), build + 83 unit e 1 UI Pianifica verdi. Nuove forme singolari ⏳ in APPROVAZIONI. Nessun test esistente modificato, nessuna zona intoccabile. Collaudo ok 2026-11-16 14:37 (plutil ok, 0/1/2+ coerenti con le chiavi approvate; traduzioni singolari ⏳ Matteo).

### S-14 [x] Statistiche: confronto mese su mese — rimosso su richiesta di Matteo 2026-11-16
- **A chi:** Codex (o Antigravity) · dopo S-6 (stessa schermata)
- **Obiettivo:** frase/card tipo «Questo mese hai speso il 12% in più per Cibo»: per categoria e totale, mese corrente vs mese precedente, stesso periodo di giorni; colori neutri/«danger» da Theme, mai solo colore (anche testo/freccia)
- **Leggere:** `Statistiche.dc.html` (se il mockup non lo prevede, chiedere a Matteo dove metterlo), `Views/StatisticsView.swift`
- **Fatto quando:** funzione pura in `Domain/` con `Decimal` + test (mese precedente vuoto, divisione per zero, categoria nuova, mese corrente a metà); resa confrontata col mockup in light/dark/XL/tedesco; testi nelle 7 lingue

- **Eseguito Codex 2026-11-16:** confronto puro `Decimal` su periodi di uguale durata, card totale/per categoria, aggiornamento cache al cambio dati/giorno; 7 test Domain + 4 UI mirati. Build + 90 unit + 4 UI verdi; screenshot light/dark/XL/de in `.cantiere/tmp/s14/`. 12 nuove chiavi × 7 lingue ⏳ in APPROVAZIONI. Calcoli statistiche precedenti e Export invariati. Collaudo ok 2026-11-16 14:37 (diff + screenshot light/dark/XL/de; build/test non rilanciati, dichiarati verdi). Nota: percentuali >=1000% arrotondate a 3 cifre significative (1234 -> 1230), minore. Traduzioni ⏳ Matteo.
- **Non fare:** cambiare i calcoli esistenti delle statistiche

### S-10 [x] (2026-11-16: Commissione S-10, nessun difetto bloccante; 92 unit verdi; UI 42/45 nel run completo, i 3 falliti rilanciati singolarmente verdi; 2 voti 9 per commento obsoleto e sentence() lunga, corretti in 1748ef5 senza nuova valutazione) Verifica finale + Commissione Suprema
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

- S-13f/SQL collaudato 2026-11-14 10:30 (ok, solo diff documentale; SQL non eseguito). Resta [ ] il Sync Swift. S-13e: tocca a Matteo (PER-MATTEO).

### S-16 [x] FUORI DAL RESTYLING (test su precisione Decimal elevata) Verificare precisione Decimal elevata nella persistenza RecurringRule
**Chiuso 2026-11-24 (capocantiere, in autonomia):** misurato con `DecimalPersistenceTests`: gli importi reali (fino a 1.000.000.000,00) tornano esatti; `123.4567890123456789` torna `123.456789012346` (differenza 3,2·10⁻¹³). SwiftData tiene ~15 cifre significative: nessun rischio per importi con 2 decimali. Nessuna modifica a Models/Persistence.
- Scoperto durante S-13f: il DTO conserva esattamente `123.4567890123456789` nel round-trip JSON, ma il confronto dell'importo dopo inserimento/fetch SwiftData ha fallito nel test nuovo di merge (prima esecuzione: `/tmp/moneytracker-s13f.log`, riga 928). Il test comprendeva anche exceptionsJSON: isolare e misurare la differenza prima di attribuire la causa.
- Il test finale di merge usa `0.2`; il DTO mantiene la prova ad alta precisione. Nessun modello o test preesistente modificato.
- A chi: collaudatore per diagnosi; eventuale correzione Models/Persistence richiede assegnazione specifica. Non dichiarare risolto in S-13f.
- **Diagnosi preliminare (collaudatore 2026-11-14 10:40, da log, nessuna esecuzione nuova):** il confronto fallito era `inserted.amount == added.amount` (importo), non exceptionsJSON (nel log risulta «not evaluated»). `added` non era inserito nel context, `inserted` è l'oggetto persistito: il valore a 19 cifre non torna uguale dopo il passaggio dal modello SwiftData. Ipotesi (NON verificata): SwiftData salva `Decimal` con precisione ridotta. Impatto pratico basso: gli importi reali hanno ≤ 2–4 decimali (il test con `0.2` passa). Il DTO/JSON è esatto (provato). Per chiudere: un test diagnostico che stampi `amount` dopo save+fetch per 0.2, 1234.56, 12 cifre, 19 cifre. Nessuna correzione al modello finché non è misurato.

### S-17 [x] (collaudo ok 2026-11-14) Pull: non cancellare regole locali non ancora spedite
- Trovato nel collaudo S-13f. `mergeRecurringRules` cancella ogni regola locale assente dal remoto. Via `syncOnForeground` è sicuro (push riuscito prima del pull), ma `syncOnLogin` con stesso utente e account già remoti chiama `pull` senza push: una regola creata offline/prima del primo sync verrebbe cancellata. Stesso comportamento dei budget (rischio già accettato lì), ma una regola porta con sé watermark ed eccezioni.
- Proposta: come per gli account, saltare la cancellazione orfani se il remoto è vuoto e il locale no (o proteggere le regole non ancora pushate). Assegnare a Codex, toccando solo SyncService + un test; da decidere con Matteo se accettare il rischio.

- **S-17 · 2026-11-14 10:42 · Codex:** implementata protezione remoto vuoto/locale popolato in mergeRecurringRules; nuovo test conserva ID, watermark ed eccezioni. Adeguata la vecchia asserzione di cancellazione su remoto vuoto; orfani con remoto popolato ancora verificati. Build + 5/5 RecurringRuleSyncTests verdi (`/tmp/moneytracker-s17-verified.log`). Da collaudare. Remoto parzialmente popolato: comportamento invariato.

- S-17 collaudo: la guardia `rows.isEmpty && !locals.isEmpty` è nel punto giusto (prima di qualsiasi modifica), il test verifica id, watermark ed eccezioni conservati; la cancellazione orfani con remoto popolato resta coperta da `pullInsertsUpdatesAndDeletesOrphans` (il test ora non più svuota con `[]`). Eseguita solo la suite da 5 test (log /tmp/moneytracker-s17-verified.log), non i 64. **Limite accettato:** se l'ultima regola viene cancellata da un altro dispositivo, qui resta e il push successivo la ricarica (risorge). Con remoto parzialmente popolato nessun cambiamento.

### S-18 [x] Rifinitura grafica dei virtuali e delle serie programmate
- **A chi:** Codex (Antigravity sospeso fino al 2026-11-20, deciso da Matteo 2026-11-14 11:09); mockup da concordare con Matteo prima di inventare grafica.
- **Perimetro:** presentazione introdotta in S-13g, Theme.swift; nessun cambiamento a logica, saldi o totali. Verifica light/dark/XL/tedesco.
- **Eseguito Codex 2026-11-16:** proposta approvata da Matteo in chat e registrata in APPROVAZIONI. ProgrammedRuleCard e VirtualOccurrenceRow allineati alla proposta Sentiero, layout adattabile, colori esistenti. Build + 80 unit + 7 UI verdi; verifica dark reale separata verde. Otto screenshot validi ispezionati, evidenze in CONSEGNA. Da collaudare.
- **Collaudo 2026-11-16 09:43: collaudo ok.** Diff solo ProgrammedRuleCard.swift + nuovo UI test; nessuna zona intoccabile, logica/callback invariati, solo token Theme adattivi, nessuna nuova stringa. Otto immagini valide (light/dark/XL/tedesco) coerenti con proposta Sentiero; 80 unit verdi riverificate. Nota: S-28 (tab bar XL) separato.

### S-19 [x] Revisione testi e traduzioni S-13g · collaudato 2026-11-16 09:47: collaudo ok (solo 7 strings + .cantiere, plutil ok, 380 chiavi allineate, nessuna chiave persa, 0 marker). Approvazione Matteo in APPROVAZIONI.md ancora ⏳. Note: de "Keine" per "Conto" (neutro) → "Keines"; es "Ninguno" per "Conto" (cuenta) → "Ninguna"; de riga 103 resta "Vorkommen"; zh riga 103 "记录" per occorrenze (vs 项目). · **chiuso 2026-11-16 09:48: collaudo ok** (5ca721e): de «Keines»/«Termine», es «Ninguna», zh «项目» applicati, chiavi invariate, plutil ok, nessun altro «Vorkommen»/«记录» residuo (99 «历史记录» = Storico ok). Approvazione Matteo in APPROVAZIONI.md resta ⏳; «Termin» (de) e i termini segnalati vanno riletti da un madrelingua.
- **A chi:** redattore (Claude Code · Sonnet).
- **Perimetro:** blocchi `S-13g — DA RIVEDERE DAL REDATTORE` in tutte le 7 Localizable.strings; etichette, ambiti e messaggi di errore. Sono traduzioni provvisorie, non approvate.

### S-20 [x] collaudato 2026-11-14 11:06 (bf9727e: guard ok, regressione ok, 68 unit verdi) CONFERMATO Verificare editor di una serie terminata prima della prima occorrenza

- **Riprodotto 2026-11-14 11:12 (collaudatore, test temporaneo poi rimosso, Domain intatto):** serie mensile, `terminate(afterThis:false)` dalla prima occorrenza → `endDate < startDate`; poi `delete(.all)` e `edit(.all)` falliscono entrambi con `invalidOccurrence`. Causa: in `apply` il guard usa `base` con `endDate` ancora impostato, quindi nessuna occorrenza. La serie resta bloccata, non eliminabile dall'UI. Fix proposto (Domain, da assegnare a Codex): nel guard azzerare `base.endDate = nil` come per `exceptions`, o impedire `terminate(afterThis:false)` sulla prima occorrenza (usare delete(.all)). Aggiungere test.
- **A chi:** collaudatore, diagnosi; eventuale correzione Domain da assegnare separatamente con autorizzazione di Matteo.
- **Scoperto S-13g:** `terminate(afterThis: false)` sull'ancora imposta endDate prima di startDate; il guard `invalidOccurrence` di S-13d sembra poi impedire anche `delete(.all)` e la modifica della serie dalla lista. Analisi statica, da riprodurre con test dedicato.
- **Vincolo:** Domain non modificato in S-13g; l'interfaccia mostra l'errore, non aggira la validazione.

- S-20 · 2026-11-14 11:05 · Codex: guard con base.endDate nil; regressione terminate prima → delete all; 68 unit verdi (67 esistenti + 1). Da collaudare.

### S-21 [x] Performance: ricalcoli per riga in TransactionsView (Commissione S-13h, giudice 4: 8/10)
- `RecurrenceSelection.resolve` è chiamata per ogni riga in `.contextMenu`/tap e ricalcola le occorrenze dall'ancora fino alla copia (serie settimanali lunghe = centinaia di occorrenze per riga a ogni render); `virtualOccurrences` e `programmedRule` ricalcolano a ogni body. Soluzione: calcolare solo al tap/apertura menu o memoizzare per (regola, mese). Nessun cambio di logica. → Codex.
- Implementato da Codex: risoluzione al tap/apertura menu, cache delle occorrenze invalidata su input/intervallo/fuso, guard al posto dei force unwrap di presentazione.
  - Collaudo 2026-11-14 11:37: cache (chiave su tutti gli input snapshot + intervallo + fuso), fallback serie terminate e guard OK. DA CORREGGERE: `RecurrenceContextMenu` (RecurrenceControls.swift ~riga 160) risolve in `.onAppear` + `@State` dentro un `.contextMenu`: su iOS il menu è reso da UIKit, onAppear/State possono non scattare o non aggiornare il menu → voce «Ricorrenza» potrebbe non comparire mai (regressione funzionale, non coperta dal test UI). Fix: calcolare `RecurrenceSelection.resolve` direttamente nel `body` di RecurrenceContextMenu (il body è valutato solo alla presentazione del menu), togliere onAppear/onDisappear/@State; poi verificare a mano sul simulatore (pressione prolungata su movimento di una serie → compare «Ricorrenza»). → Codex.
- 2026-11-14 11:45 Codex: fix resolve nel body senza State/onAppear/onDisappear; Domain intatto. Test cache regola/intervallo/fuso (parametro fuso con default .current), UI esteso con pressione prolungata → Ricorrenza → editor. Build + 69 unit + 1 UI verdi; log completo `.cantiere/tmp/s21-fix-test.log`. Verifica manuale non eseguita: CUA non accede a Simulator. Da collaudare.
  - Collaudo 2026-11-14 11:47: collaudo ok. resolve nel body senza State/onAppear, test cache (regola/intervallo/fuso) verde, log coerente (69 unit + 1 UI, TEST SUCCEEDED), Domain/zone intoccabili intatti, nessun cambio visivo. Resta a Matteo il controllo manuale (PER-MATTEO.md).
### S-22 [x] Architettura: spezzare TransactionsView (giudice 2: 8/10)
- `programmedRule` (~35 righe con logica di fallback ancora) e `virtualOccurrences` stanno inline in `TransactionsView` già molto lunga; estrarre in sottoview/file `ProgrammedRuleCard` in Views/. Nessun cambio visivo. → Codex (prima di S-18).
- Implementato da Codex. 2026-11-14 11:37 collaudo ok (diff visivamente invariato, Domain/Models/Sync/Auth intatti).
### Commissione Suprema S-13h (2026-11-14 11:08)
1 Sicurezza 10 · 2 Architettura 8 (S-22) · 3 Logica 10 · 4 Performance 8 (S-21) · 5 Robustezza 9 (`!` su calendar.date in resolve/programmedRule: sicuri ma da sostituire con guard in S-21) · 6 Lingua/UX 8 (traduzioni provvisorie S-19, grafica S-18). Esito: non approvato, nessun push.

### S-23 [x] (2026-11-14 12:55, collaudo ok) Editor singola occorrenza e indicatore ricorrenza
- **A chi:** Codex, assegnato da Matteo 2026-11-14.
- **Obiettivo:** tap in Movimenti apre editor normale; salva solo la copia, senza cambiare regola. Ricorrenza solo dal menu prolungato esistente. Selettore nascosto in modifica; icona repeat nelle righe. Verifica categorie nella copia e con Tutte.
- **Perimetro:** viste e test; mantenere e committare modifiche preesistenti ProgrammedRuleCard/RecurrenceControls. Domain intatto; graphify-out escluso dal commit.
- **Fatto quando:** unit e UI verdi, verifiche riportate in CONSEGNA; poi collaudo indipendente.
- **Eseguito 2026-11-14 12:45 · Codex:** due reindirizzamenti rimossi; editor normale salva solo Transaction, selettore nascosto e frequenza non assegnata in modifica; icona repeat adattiva/accessibile in Movimenti. Categoria copia e Tutte verificate, nessun bug logico trovato. Domain intatto. Build + 70 unit + 2 UI S-23 verdi (`/tmp/moneytracker-s23-final.log`). Suite completa eseguita: restano i due fallimenti preesistenti S-15; nuovi test corretti e verificati verdi separatamente. Da collaudare; dettagli in CONSEGNA.

- **S-23 superato da S-25:** il tap normale resta AddTransactionView, ma il salvataggio ora applica Tutte alla serie. L'icona repeat e il menu lungo restano invariati.

### S-24 [x] Eliminazione ricorrenze: regressioni e confronto per giorno originale
- **Collaudo 2026-11-15 11:55 (collaudatore):** [x] collaudo ok — eliminazione per giorno originale, 3 scope, copie del mattino/spostate. 78 unit riverificate in locale (78 passed, Swift Testing). UI non rilanciati: log di Codex coerenti (full 13/15 prima del fix, S-15 2/2 verdi in rilancio mirato; nessun full run unico 15/15). Riserva: blocco reale su Tutte non riprodotto in demo, NON dichiarato risolto; serve prova di Matteo su dati reali (PER-MATTEO).
- **A chi:** Codex, assegnato da Matteo; Domain autorizzato esplicitamente il 2026-11-15. Collaudo indipendente da fare.
- **Fatto:** corretto il difetto dimostrato su successive: il confronto con mezzogiorno lasciava la copia del mattino. Ora si usa il giorno originale ricavato dall'ID anche per copie spostate; stessa correzione per termina. Tutte non genera la mappa delle date originali quando non serve.
- **Prove:** test unit serie mensile fissa gennaio–aprile, copia delle 08:00, copia spostata, conservazione effettuate/legacy, mancata ricreazione; UI da Movimenti con pressione prolungata → Elimina/Ricorrenza → tre scope, scomparsa e navigazione successive verdi.
- **Riserva:** il blocco originario su Tutte non riprodotto in demo; nessuna causa crash/deadlock dimostrata, nessun breakpoint progetto trovato. Non dichiararlo risolto sul database reale senza verifica di Matteo/collaudatore.

### S-25 [x] Uniformità campi ricorrenti secondo scope (sostituisce S-23)
- **Collaudo 2026-11-15 11:55 (collaudatore):** [x] collaudo ok — propagazione per scope, effettuato locale (D-010), override→Tutte, date/ID/rollback. 78 unit riverificate in locale (78 passed, Swift Testing). UI non rilanciati: log di Codex coerenti (full 13/15 prima del fix, S-15 2/2 verdi in rilancio mirato; nessun full run unico 15/15). Riserva: blocco reale su Tutte non riprodotto in demo, NON dichiarato risolto; serve prova di Matteo su dati reali (PER-MATTEO).
- **A chi:** Codex, assegnato e Domain autorizzato da Matteo; collaudo indipendente da fare.
- **Fatto:** editor normale usa RecurringSeriesEditor/Tutte per nome, importo, categoria/icona, conto, tipo, note, fissa e data; frequenza/fine restano solo nell'editor ricorrenza. Quest'ultimo applica tutti i campi del form secondo scope, anche alle copie effettuate. Eccezioni complete per Solo questa, incluso conto esplicitamente vuoto. Storico e futuro uniformi; nessuno storico mancante inventato.
- **Decisione D-010:** Tutte sostituisce override precedenti di valori/date; salti mantenuti a cadenza invariata. Date/frequenza riallineano le copie per posizione e i loro ID; mesi corti gestiti. Già effettuato resta locale alla singola copia, come precisato da Matteo. Ripristino di valori/date/ID/template verificato su errore di salvataggio.
- **Prove:** 78 unit verdi; test UI normale → serie/categoria, Solo questa categoria, successivo Tutte e rilettura dei valori verde. Tutti i 15 UI hanno ultimo esito verde tra suite completa e rilanci mirati (dettaglio in CONSEGNA, non un unico full run verde).
- **Perimetro:** Domain/RecurrenceCalculator.swift e RecurringSeriesEditor.swift; viste e test. Models/Persistence/Sync/Auth e grafica intatti. Corretto anche il tag del selettore Tipo (rawValue del modello).
- **Da fare:** collaudo S-24/S-25/S-15; poi S-18/S-19 e Commissione S-13h. Nessun push/merge/checkpoint.

### S-26 [x] Demo vetrina completa (DemoDataSeeder) — 2026-11-16 01:22 collaudo ok
- **A chi:** Codex (Antigravity sospeso fino al 2026-11-20). Richiesto da Matteo 2026-11-15.
- **Perché:** la demo serve a mostrare l'app ad altri senza i soldi veri di Matteo: oggi è poco completa (poche spese fisse, nessuna `RecurringRule`, ~30 movimenti su 3 mesi, grafico Home povero e piatto).
- **Da fare:** riscrivere `MoneyTracker/Debug/DemoDataSeeder.swift` (alzare `seedVersion`): 6+ mesi di storia con andamento realistico e picchi; molte spese fisse come vere `RecurringRule` (affitto, bollette, abbonamenti, palestra, assicurazione, rata…) con occorrenze passate/oggi/future; almeno una serie con override singolo e una con «già effettuato»; entrata ricorrente e giroconto; tutte le categorie principali; budget a vari livelli (sotto/a rischio/sforato); obiettivi a vari stadi; conti diversi con saldi credibili; pianificati futuri (saldo atteso ≠ attuale); nomi localizzati nelle 7 lingue (chiavi `demo.*`).
- **Vincoli:** zone intoccabili invariate (Domain, Models, Sync…), solo API esistenti; nessuna stringa hardcoded nuova.
- **Verifica:** simulatore con demo attiva (Home/grafico, Movimenti, Ricorrenze, Budget, Obiettivi), confronto col mockup, test verdi. Poi collaudo indipendente.
- **Nota:** nessun push/merge.
- **Eseguito Codex:** seed v6, otto mesi, nove regole vere, override/effettuato oggi, futuro virtuale dal mese successivo, quattro conti/obiettivi, budget di otto mesi, sette lingue. Build e 79 unit + 4 UI finali verdi; dieci screenshot ispezionati. Evidenze e limiti in CONSEGNA. Da collaudare indipendentemente; S-6/S-7/S-8/S-18 restano lavori grafici aperti.

### S-27 [x] Migliorie dal collaudo di S-24/S-25/S-15 (suggerite 2026-11-15)
- **A chi:** Codex, dopo S-26. Non urgenti, da fare prima del checkpoint.
- **a)** Un full run UI unico 16/16 verde (15 esistenti + showcase S-26), per sostituire la somma di full e rilanci mirati.
- **b)** Gli UI test partono con i filtri avanzati azzerati (reset dell'AppStorage all'avvio), così non servono workaround via UI (causa dei 2 rossi S-15).
- **c)** Test unit: due copie che finiscono sullo stesso giorno dopo una modifica di data non devono generare ID duplicati.
- **Vincoli:** nessun cambio al codice app salvo l'hook di reset test; Domain/Models/Sync intatti; nessun push/merge.
- **Esito collaudo (2026-11-16 03:55):** chiuso, collaudo ok. Diff 35ea8d4 letto; fallback seeder equivalenti (Decimal(275)/100 = 2,75), reset filtri solo dentro `isUITesting`, nuovo test non banale (ID distinti + stabilità dopo materializzazione + calendario virtuale); zone intoccabili intatte; build e 80 unit verdi (rilanciati). UI 16/16 dalla CONSEGNA.

- **S-27 eseguito Codex (2026-11-16):** fallback seeder senza force-unwrap; reset txFilterMin/Max/UseDates solo --uitesting; nuovo RecurringCollisionTests (due copie nello stesso giorno, ID distinti anche dopo materializzazione e nel virtuale). Build + 80 unit + 16/16 UI in un unico run sequenziale verdi. Showcase 52,870 s; testNonRecurringEditCannotCreateSeries 22,802 s; nessun timeout idle riprodotto. Da collaudare; dettagli in CONSEGNA.

### S-28 [x] Tab bar affollata con Dynamic Type XL
- **Scoperto in S-18:** nello screenshot XL le etichette Movimenti/Statistiche della tab bar si avvicinano eccessivamente. Fuori dal perimetro S-18, non corretto. Verificare ContentView e layout accessibile senza cambiare funzioni. Evidenza: `/tmp/moneytracker-s18-images/series-sheet.png`, colonna testExtraLarge. → Codex dopo assegnazione.

- **S-28 eseguito Codex 2026-11-16:** FloatingTabBar celle uguali (minWidth 0), margine testo 4 pt per lato, fino a due righe centrate per nomi lunghi. Indici/identificatori/callback e ContentView invariati. Build + 80 unit + 3 UI verdi (italiano L/XL, tedesco XL); screenshot finali ispezionati. Da collaudare, evidenze in CONSEGNA.
- **Collaudo 2026-11-16 09:58: NON passa.** Etichette separate in it L/XL, 80 unit verdi, nessuna zona intoccabile, solo token DS. Difetto in de XL: «Bewegungen» spezzato a metà parola in «Bewegunge / n» (n orfana), non è un nome completo leggibile. Correggere in FloatingTabBar.swift ~riga 28-30: per parole singole lunghe evitare l'a-capo mid-word (es. lineLimit(1) + minimumScaleFactor più basso ~0.6, oppure ridurre il padding), poi ri-screenshot de XL.

- **Correzione Codex 2026-11-16:** lineLimit(1), minimumScaleFactor(0.6), rimosso allineamento multilinea. Padding/celle/target/selezione invariati. Build + 80 unit + 3 UI verdi. Screenshot de XL: Bewegungen intero su una riga, senza ellissi né lettera orfana; it L/XL confermati. Da ricollaudare; nuove evidenze in CONSEGNA.
- **Ricollaudo 2026-11-16 10:05: collaudo ok, chiuso [x].** Diff dd2d0a5 solo FloatingTabBar.swift (lineLimit(1), minimumScaleFactor 0.6): target touch, selezione, identificatori, callback invariati; nessuna zona intoccabile né test toccato. Screenshot: de XL «Bewegungen» intero su una riga, niente ellissi/lettere isolate, separato da Startseite/Statistiken; it L e XL nomi completi e separati.

### S-29 [x] Correzioni Commissione Suprema S-13h (autorizzate da Matteo 2026-11-16) — 2026-11-16 collaudo ok (diff a1c6c89; build+81 unit+3 UI dichiarati dall impresa, non rilanciati)
- Helper calendario con guard/fallback nei tre componenti Domain, lastMonth da interval.end - 1.
- Materializer: un fetch per regola e Set UUID, idempotenza/copie fatte/UUIDv5/36 mesi invariati.
- Errori editor/status localizzati in 7 lingue, italiano invariato; nuove traduzioni da approvare.
- Nuovo test Decimal 2 decimali: round-trip SwiftData e SBRecurringRule JSON. Eventuali discrepanze solo da riportare.
- Autorizzati interventi mirati Domain (incluso RecurringSeriesEditor citato nel task) e Sync solo se necessario al test. Fuori perimetro TransactionsView, testi S-19/S-28, blocco reale S-24. Nessun test esistente modificato per farlo passare.
- Verifica build + 80 unit esistenti e nuovo test + 3 UI TabBarAppearance. Nessun push/merge. Poi ricollaudo e nuova Commissione.

- **S-29 eseguito Codex 2026-11-16:** helper calendario senza unwrap nei tre Domain, ultimo mese da end−1 s, fetch transazioni unico per regola e Set ID. Quattro errorDescription localizzati; messaggio status già NSLocalizedString, cinque chiavi verificate in tutte le 7 lingue senza nuovi testi. Nuovo test Decimal su store riaperto + DTO JSON + apply: 0.29/1234.56/999999.99 esatti. Build + 81 unit + 3 UI verdi. Da ricollaudare; poi nuova Commissione, non attribuiti voti.

### S-30 [x] Categoria dall'ultima volta (nuova funzione) — 2026-11-16 collaudo ok (traduzioni ancora ⏳ per Matteo)
- **Quando:** dopo S-14, S-10, checkpoint finale e merge/ok di Matteo sul restyling. Matteo lo avvia lui («partiamo con l'altro lavoro»). Non è restyling: tocca la logica dell'inserimento.
- **A chi:** Codex (Antigravity sospeso fino al 2026-11-20) · collaudo indipendente + Commissione.
- **Obiettivo:** se il nome di un movimento non ha categoria dalle parole chiave (`KeywordCategoryClassifier`), usare la categoria dell'ultimo movimento con lo stesso nome (D-011). Es.: «Mc» → ultima categoria scelta per «Mc».
- **Leggere:** `Views/AddTransactionView.swift` (righe ~97-103, 124, 274-276: `suggestedCat`), `Domain/` classifier, `docs/MoneyTracker.md` §6
- **Regole (D-011):** (1) nessuna nuova tabella né sync: si guarda la cronologia dei movimenti; (2) priorità: cronologia dell'utente, poi parole chiave fisse; (3) confronto nome senza maiuscole/accenti/spazi in eccesso, corrispondenza esatta (al massimo per prefisso, mai somiglianza «a occhio»); (4) due categorie per lo stesso nome → vince l'ultima; (5) preselezionata come oggi; se l'utente la cambia, il salvataggio aggiorna di fatto la «prossima volta»; (6) etichetta «Ultima usata» invece di «Suggerita» quando viene dalla cronologia (7 lingue, nuove traduzioni ⏳ in APPROVAZIONI.md); (7) contano solo i movimenti normali, non pianificati né trasferimenti.
- **Fatto quando:** funzione pura in `Domain/` (nuovo file) con test: nome nuovo, maiuscole/accenti, due categorie diverse (vince l'ultima), movimento pianificato/trasferimento ignorati, categoria eliminata, DB vuoto; resa dell'etichetta in light/dark/XL/tedesco; test esistenti invariati.
- **Non fare:** modificare modelli/Persistence/Sync, cambiare il classifier a parole chiave, suggerimenti per somiglianza.

- **Eseguito Codex 2026-11-16:** avvio autorizzato da Matteo dopo chiusura restyling e merge su main; ramo `categoria-ultima-volta` da `489154b`. Funzione pura `LastUsedCategory`, priorità cronologia → keyword, nomi esatti normalizzati, solo effettuati/non trasferimenti, ultimo per `createdAt`, categoria eliminata → fallback. Etichetta in 7 lingue, traduzioni ⏳. Nessun modello/sync/classifier o test esistente modificato.
- **Verifiche:** build e 90 unit (83 esistenti + 7 nuovi) verdi; 4 UI S-6 verdi; 4 nuovi UI S-30 verificano anche correzione manuale → prossimo suggerimento. Screenshot light/dark/XL/de e dettagli in CONSEGNA. Nessun push/merge. Prossimo: collaudo indipendente Claude Code · Sonnet.

### S-31 [x] Rimozione confronto mese su mese — 2026-11-16 collaudo ok
- **A chi:** Codex, autorizzato da Matteo 2026-11-16 sul ramo rimuovi-confronto-mese.
- **Obiettivo:** eliminare interamente S-14 preservando le altre statistiche, verificare lingue, build, unit e UI S-6 con screenshot light/dark/XL/de. Nessun push o merge.
- **Eseguito Codex 2026-11-16 21:40:** eliminati i quattro file S-14, card/cache/eventi dedicati in StatisticsView e 12 chiavi esclusive × 7 lingue, previo controllo riferimenti con rg. «Dati insufficienti.» conservata perché condivisa. Nessun altro calcolo/test/Export/plurale S-7p modificato. S-14 segnato rimosso, approvazioni ritirate, decisione D-012.
- **Verifica:** build riuscita; 83 unit in 17 suite verdi (92 meno 9 test S-14); 4 UI S-6 verdi; 12 screenshot light/dark/XL/de ispezionati senza vuoti. Tutti i .strings validi, sei lingue non italiane allineate a 392 chiavi. 541 warning Swift già riscontrati identici nei log precedenti, nessuno nuovo; secondo build dark senza warning. Dettagli/evidenze in CONSEGNA.
- **Aperto:** niente (collaudo ok 2026-11-16); nessun push/merge.

- **Collaudo 2026-11-16 22:40 (Claude Code · Sonnet):** conforme a D-011. Solo Domain/LastUsedCategory.swift nuovo + AddTransactionView; nessun Models/Persistence/Sync/Auth/Export/classifier toccato. Confronto esatto normalizzato, vince l'ultimo per createdAt, solo isDone && !isTransfer, categoria eliminata → nil, nessun force-unwrap. 7 .strings validi, 395 chiavi uguali nelle 6 lingue non it. Unit 90/90; UI nuovi 4/4; S-6 Sentiero verdi; screenshot dark/de ok; diff --check ok. Fetch dopo debounce 280 ms, non a ogni render. Note: (a) `DemoShowcaseUITests.testShowcaseScreens` fallisce (riga 29, bolletta Enel non hittable in S-26): file non toccato da S-30, da verificare su main → T aperto sotto; (b) il fetch carica tutta la cronologia a ogni pausa di digitazione (ok ora, da rivedere con molti movimenti).

### S-32 [x] Manutenzione: DemoShowcaseUITests.testShowcaseScreens rosso (anche su main)
- **Collaudo 2026-11-16 23:46: [x] collaudo ok** (collaudatore). Diff limitato al solo DemoShowcaseUITests; asserzioni e catture preservate, ricerca esistente + attesa hittable 5 s; test demo isolato verde, 90 unit verdi, diff --check pulito. Suite UI completa non rieseguita (32 min): 44/45 per evidenza dell'impresa; rosso residuo = S-33.
- **A chi:** Codex (Antigravity sospeso fino al 2026-11-20) · collaudo indipendente.
- **Trovato da:** collaudo S-30 (2026-11-16 22:40); verificato dal capocantiere il 2026-11-16 22:43 che fallisce anche su `main` (489154b, senza S-30): non dipende da S-30. Probabile causa riferita dal collaudatore, non confermata: riga 29 del test, bolletta Enel non tappabile nella schermata demo S-26.
- **Obiettivo:** capire la causa reale (test fragile o difetto della demo) e sistemarla con la modifica minima. Se il difetto è nella vista, niente restyling; se serve toccare zone protette, fermarsi e chiedere a Matteo.
- **Fatto quando:** il test passa da solo e nel run UI completo; nessun altro test modificato o indebolito.
- **Prompt:** da preparare quando Matteo avvia il lavoro.
- **Eseguito Codex 2026-11-16 23:39:** ramo `fix-demo-showcase-test` da `ca9d50c`. Riprodotto il rosso nella suite originale: gli swipe ampi saltano il bottone della bolletta (video xcresult verificato); il vecchio bundle main invece riporta SIGKILL nel setup. Solo test demo corretto con ricerca per nome e attesa hittable 5 s, asserzioni conservate. Test isolato e demo nel run completo verdi, 90 unit e 4/4 UI S-6 verdi. Suite UI 44/45: unico rosso estraneo S-33, non modificato; requisito suite tutta verde non soddisfatto. Dettaglio in CONSEGNA. Nessun push/merge; collaudo indipendente richiesto.

### S-33 [x] Verificare RecurrenceFlowUITests.testCreateEditAndDeleteScheduledSeries
- **Trovato da:** run completo S-32, 2026-11-16, `/tmp/mt-s32-full-fixed.log`.
- **Evidenza:** riga 100, `recurrence.waitForExistence(timeout: 5)` fallisce: voce «Ricorrenza» non trovata dopo long press sul movimento. Test non modificato da S-32; causa e preesistenza da verificare, non attribuite.
- **Autorizzazione:** task separato autorizzato da Matteo il 2026-11-16; correggere solo se dimostrato problema del test, fermarsi se app o zone protette/altri test.
- **Accertamento Codex 2026-11-17 00:24:** ramo `fix-recurrence-ui-test` da main `4fb666a`. PRIMA di modificare codice: test isolato due volte verde (102,700 s e 100,202 s), poi verde anche nella suite completa (91,866 s). Build, 90 unit e 45/45 UI verdi, inclusi 4 UI S-6 e DemoShowcaseUITests. Nessun file app/test modificato. Il menu compare e l'editor si apre nei tre run; non dimostrati identificatore errato, timeout insufficiente o difetto app.
- **Esito [?]:** rosso intermittente non riprodotto; causa precisa NON accertata. Il vecchio bundle S-32 non è più disponibile in DerivedData. Nessuna correzione speculativa. Dossier in CONSEGNA; nuovi log `/tmp/mt-s33-main-1.log`, `/tmp/mt-s33-main-2.log`, `/tmp/mt-s33-full-main.log`, bundle finale `/tmp/mt-s33-full-main.xcresult`. Diff --check pulito, nessun push/merge. Serve Matteo: decidere se mantenerlo in osservazione; non dichiararlo corretto o chiuso.
- **Collaudo dossier 2026-11-17 00:40:** dossier coerente, nessun codice/test cambiato; quarto run isolato verde (101,716 s, `/tmp/mt-s33-collaudo.log`). Resta [?] in osservazione. **Criterio di riapertura:** se il rosso riga 100 ricompare (in CI, notturno o run locale), conservare subito il bundle .xcresult in /tmp prima di altri run e riaprire come [ ] con quell'evidenza; senza nuova ricomparsa non si interviene.
- **Chiuso 2026-11-24 (capocantiere, in autonomia su delega di Matteo):** nessuna campagna di riproduzione. `testCreateEditAndDeleteScheduledSeries` è verde in tutti i giri completi di oggi (suite UI 48/48 due volte, più il giro mirato); si chiude in osservazione senza dichiarare accertata una causa. Criterio di riapertura invariato (se il rosso riga 100 ricompare: conservare subito il bundle, video e gerarchia).

### S-34 [x] Pianifica: lista tagliata sopra la barra (capocantiere, 2026-11-18): `PianificaView` usa `.contentMargins` invece di `.padding` sullo ScrollView. Build verde; il collaudo lo fa Matteo.
**chiuso 2026-11-24 (capocantiere): il test `SentieroReviewFixUITests` (S-43) verifica ora che, a fine scorrimento, l'ultimo testo di Pianifica resti sopra il pulsante +; 3/3 verdi nella suite completa.**

### S-36 [x] fix in TrailView.swift (capocantiere, 2026-11-19): tratteggio parte dal punto reale di oggi, niente cerchio per i pianificati di oggi; build ok e BalanceTrailTests senza errori; controllo visivo su iPhone fatto da Matteo (screenshot Home 2026-11-19 01:07: curva continua); da chiudere dal collaudatore o da Matteo. -- Home: curva del saldo, tratto ambra e pallino «oggi» non allineati al tratto verde (Matteo 2026-11-19, diagnosi capocantiere)
**chiuso 2026-11-24 (capocantiere): controllo visivo di Matteo del 2026-11-19 (curva continua) e `BalanceTrailTests` verdi nella suite (97 test); rami S-36 già chiusi nel collaudo del 24/11.**
**Sintomo:** quando c'è un movimento pianificato per OGGI (es. «Corso di lingue · Oggi»), il tratteggiato ambra parte più in basso del pallino verde e un cerchietto ambra vuoto si sovrappone al pallino «oggi».
**Causa (letta nel codice, da confermare col simulatore):** `BalanceTrail.make` costruisce `projected` partendo da `today` con `cumulative += plannedByDay[today]`, quindi il primo punto proiettato NON è `currentBalance` (il commento dice di sì) ma già abbassato dal pianificato di oggi; `TrailView.draw` disegna il tratteggio da quel punto (salto verticale sotto il pallino) e `plannedMarks` con `day == today` mette un cerchio vuoto a quel livello.
**Fix proposto (solo vista, `Views/Components/TrailView.swift`, zona Domain intoccata):** far partire il tratteggio dal punto reale di oggi (`trail.actual.last`) e collegarlo ai punti proiettati con `day > today`; non disegnare il cerchio vuoto dei pianificati con `day == today` (sarebbe sotto il pallino). Saldo atteso e numeri invariati. Controllare sia con pianificati oggi sia senza, chiaro/scuro, 7 lingue non toccate. Test esistenti `BalanceTrailTests` devono restare verdi.
**Perché ora:** la Home è la prima slide/schermata dei social (SC-7): gli screenshot del carosello vanno rifatti dopo il fix. Assegnare a: operaio (piccolo) o Codex.

(Nota: i commit 829c6a0 ed e19a39d citano «S-35» per questo fix: il numero giusto è S-36, perché S-35 era già «Spezzare TransactionsView».)

## Proposte prodotto · Android e collegamento bancario

- [x] **Prima base Android.** Progetto Kotlin/Compose in `03_CODICE/bucktrail-android`, con Home, Conti e Movimenti, persistenza Room e modalità chiara/scura. JDK 17, SDK 36 ed emulatore configurati per VS Code. APK debug, lint, 2 test importi e prova di riapertura offline riusciti.
- [x] **Date, modifica e pianificazione Android.** Separati pianificati ed effettuati, con previsione limitata al mese di competenza. Migrazione Room verificata su emulatore.
- [x] **Parità Android con iOS (2026-11-23).** B0–B11 completi, test di parità e stress test fatti; collaudata 2026-11-24 (capocantiere): build debug ok, 247 test JVM e 2 strumentati su emulatore Bucktrail_API_36 verdi; collaudo del 2026-11-23 🟢. (storico:) Continuare da categorie e filtri di Movimenti. Poi trasferimenti, ricorrenze, Pianifica e Statistiche.
- [x] (Matteo, 2026-11-24 22:16: prova reale fatta, funziona) **Login e sincronizzazione Supabase su Android.** Fatti, provati solo con server finto (test JVM verdi); la prova reale a due dispositivi richiede l'account di prova di Matteo (PER-MATTEO). (storico:) Rinviati su indicazione di Matteo. Alla ripresa usare un ambiente di test e verificare dati, profilo e duplicati su iOS e Android.
- [?] **S-60t/S-61 · Modello economico del collegamento bancario — decisioni di Matteo 2026-11-25, tutto in `.cantiere/banca-modello-economico.md`.** Abbonamento facoltativo a parte (l'app resta 4,99 € una tantum): due livelli (fino a 2 e fino a 6 banche), mensile o annuale con sconto (≈ 2 mesi gratis), pagamento solo via Apple/Google, prezzi da fissare DOPO il preventivo di Enable Banking (costo per conto `c` e fattura minima ignoti). Matteo: (1) tipo di account Apple Developer, (2) inviare la mail del §9 a Enable Banking e incollare la risposta, (3) domande §8 al professionista (incluse P.IVA per vendere via store e per essere cliente di Enable). Poi: rifare le tabelle, aggiornare `progetto-banca.md` §12.2 e DECISIONI.md, scrivere il progetto esecutivo S-61 (acquisti in-app + verifica lato server su Supabase). Nessun codice prima. Non passa davanti a S-50.
- [ ] **Collegamento bancario facoltativo (S-60) — progetto esecutivo pronto: `.cantiere/progetto-banca.md` (architetto, 2026-11-24).** Resta DOPO il lancio e DOPO S-50 (prerequisito: S-50a…m `[x]`), salvo diversa decisione di Matteo. Fornitore Enable Banking (piano B Salt Edge; GoCardless chiuso alle iscrizioni). Autorizzazione di Matteo a toccare Sync/, Auth/ e i punti minimi di Models/Persistence solo per S-60 (riferita dal capocantiere). Interruttori spenti fino a S-60v. Task sotto, in ordine (§11 del progetto).
  - [ ] **S-60a · Contratto e vettori condivisi (Python)** → capocantiere/operaio Claude Code · progetto §3.4, §4.3–4.4, §5, §10.2, §11.3
  - [ ] **S-60b · Edge Function `bank` (TypeScript, test Node)** → capocantiere/operaio Claude Code · §3, §10.3 T2–T4 · dopo S-60a
  - [ ] **S-60c · SQL S-60 + server finto bank** → capocantiere/operaio Claude Code · §4.5, §10.2 · dopo S-60b · poi COLLAUDO BLOCCO 1 (collaudatore + stress-test sicurezza, S-60a…c)
  - [ ] **S-60d · Dominio puro iOS (`Domain/Bank/`, solo file nuovi)** → capocantiere/operaio Claude Code · §4.7, §10.2 · dopo collaudo 1
  - [ ] **S-60e · Dominio puro Android** → capocantiere/operaio Claude Code · §4.7 · dopo S-60d
  - [ ] **S-60f · Modelli iOS + SchemaV4** → capocantiere/operaio Claude Code · §4.2, §4.6 · dopo S-60e
  - [ ] **S-60g · Room 3→4** → capocantiere/operaio Claude Code · §4.2, §4.6 · dopo S-60f · poi COLLAUDO BLOCCO 2 (S-60d…g)
  - [ ] **S-60h · iOS: client e importatore** → capocantiere/operaio Claude Code · §3.4, §4.3–4.4, §5 · dopo collaudo 2
  - [ ] **S-60i · Android: client e importatore** → capocantiere/operaio Claude Code · idem · dopo S-60h
  - [ ] **S-60j · iOS: sync entità bancarie (chiaro + vault)** → capocantiere/operaio Claude Code · §4.8, §6 · dopo S-60i
  - [ ] **S-60k · Android: sync entità bancarie** → capocantiere/operaio Claude Code · §4.8, §6 · dopo S-60j
  - [ ] **S-60l · Interoperabilità + prova d'insieme col server finto** → capocantiere/operaio Claude Code · §10.3 T13, T17 · dopo S-60k · poi COLLAUDO BLOCCO 3 (collaudatore + stress-test, S-60h…l)
  - [ ] **S-60m · Link di ritorno (Universal/App Link, PKCE) + pagine landing + script sandbox** → capocantiere/operaio Claude Code · §3.5 · dopo collaudo 3
  - [ ] **S-60n · Interfaccia iOS + testi 7 lingue + screenshot** → capocantiere/operaio Claude Code · §7 · dopo S-60m
  - [ ] **S-60o · Interfaccia Android + testi + screenshot** → capocantiere/operaio Claude Code · §7 · dopo S-60n
  - [ ] **S-60p · Ciclo di vita (scollega, rinnovo, logout, elimina account) + stress-test** → capocantiere/operaio Claude Code · §3.6, §8.3 · dopo S-60o · poi COLLAUDO BLOCCO 4 (S-60m…p)
  - [ ] **S-60q · Commissione Suprema 10/10 + docs/MoneyTracker.md** → capocantiere/operaio Claude Code · §11.3 · dopo collaudo 4
  - [?] **S-60r · Matteo: banco di prova tecnico + prova guidata in sandbox (~40 min, una seduta)** → Matteo · istruzioni 📍▶️↩️ §11.4 · dopo S-60m (meglio dopo S-60q)
  - [ ] **S-60s · Analisi delle risposte reali della sandbox** → capocantiere/operaio Claude Code · §10.4, §11.3 · dopo S-60r
  - [?] **S-60t · Matteo: verifiche commerciali e legali (tipo account Apple, Enable Banking, professionista)** → Matteo · §9, §11.4 · si può fare SUBITO, blocca solo l'accensione
  - [?] **S-60u · Matteo: produzione, impronta release, dichiarazioni store, ok testi sito** → Matteo · §8.5, §11.4 · dopo S-60q, S-60s, S-60t
  - [ ] **S-60v · Accensione interruttori + privacy e FAQ del sito** → capocantiere/operaio Claude Code · §8.4, §11.3 · SOLO dopo S-60q, S-60s, S-60t, S-60u `[x]`

## Richieste di Matteo · 2026-11-24 sera

- [~] **S-44 · Verifica sicurezza dei dati (come sono cifrati?)** → Codex (sola lettura + relazione `.cantiere/sicurezza-dati-2026-11-24.md`). Per iOS e Android dire, con file e riga: dati locali (SwiftData / Room: protezione file, backup), Keychain / sessione, trasporto verso Supabase (TLS), dati a riposo su Supabase, RLS, export, log. Niente affermazioni non verificate nel codice. Se c'è una lacuna (es. Room non cifrato, backup Android attivo) elencarla come nuovo task, senza correggere. Prima di S-45.
- [x] (2026-11-24 22:28: verificato online it+en, collaudo capocantiere) **S-45 · Sul sito: sezione «I miei dati sono al sicuro?»** → Codex (o redattore) dopo S-44. Solo ciò che S-44 conferma; italiano e inglese (`index.html`, `en.html`), coerente con `privacy.html`. Poi la landing va ricaricata a mano su Cloudflare (PER-MATTEO).
- [~] **S-46 · Analytics della landing** → Codex. Proposta: **Cloudflare Web Analytics** (gratis, senza cookie, già sul dominio) così non serve banner cookie; aggiornare `privacy.html` (it/en). Mantiene gli `utm_source` già usati nei link social. Serve l'ok di Matteo sullo strumento (APPROVAZIONI).
- [x] (Matteo, 2026-11-24 22:14: provato sul telefono, ok) **S-47 · Android: avvio come iPhone (niente icona per ~1 s)** → Codex o operaio. Splash di sistema Android 12+: sfondo del tema Sentiero (chiaro/scuro) senza icona, poi subito la prima schermata. File: tema in `app/src/main/res/values*/` e `MainActivity.kt`.
- [x] (Matteo, 2026-11-24 22:14: provato sul telefono, ok) **S-48 · Android: icone di login e schermata di sblocco uguali a iPhone** → Codex. Confrontare `MoneyTracker/Auth/*` e la vista di blocco iOS con le schermate Android (`ui/`), riprodurre gli stessi simboli (SF Symbols → vettori) in chiaro e scuro. Confronto col mockup/iOS obbligatorio.
- [x] (Matteo, 2026-11-24 22:16: sync reale provato su Android, funziona) **S-49 · Android: prova reale Supabase** (già in lista sopra, serve l'account di prova di Matteo). Provata solo con server finto.

  - 2026-11-24 21:32 · capocantiere (su richiesta di Matteo, autonomia piena): S-44 relazione in `.cantiere/sicurezza-dati-2026-11-24.md` (nessuna falla; Room non cifrato dall'app: decisione di NON aggiungere SQLCipher, motivata lì). S-45 voce FAQ «Come so che i miei dati sono al sicuro?» in index.html e en.html. S-46 scelto Cloudflare Web Analytics: CSP in `_worker.js` aggiornata, `privacy.html` riscritta (it); resta da attivarlo nel pannello (PER-MATTEO). S-47 splash senza icona (res/values-v31 e values-night-v31 + drawable/splash_vuoto.xml), verificato sull'emulatore API 36. S-48 lock.fill e chart.pie.fill ridisegnati in SfIcons.kt (disegno proprio: i glifi SF Symbols non si copiano su Android per licenza Apple). Build, lint e 247 test JVM verdi. Da collaudare.

- [ ] **S-50 · Cifratura end-to-end della sync (opzione «Protezione avanzata»)** → prima **architetto** (solo progetto, nessun codice): generazione e custodia della chiave, chiave di recupero, reset password, migrazione delle righe già sincronizzate, formato identico su iOS e Android, piano di prova con migrazione e recupero finti. Poi implementazione dopo il lancio, opzionale per l'utente così chi non la attiva non cambia. Richiesta di Matteo 2026-11-24 22:37: «se e solo se manteniamo tutto intatto, senza rompere nulla». Zone intoccabili (Sync/, Auth/): serve l'ok di Matteo sul progetto prima di toccarle.
  **Progetto esecutivo pronto (architetto, 2026-11-24 22:51):** `.cantiere/progetto-e2e-sync.md`. Autorizzazione di Matteo a toccare Sync/ e Auth/ solo per S-50 (riferita dal capocantiere, 2026-11-24). Esecuzione dal 2026-11-25 con i task qui sotto, in ordine, assegnati da Matteo a Codex (non più per forza Claude Code);  interruttore spento fino a S-50p.
  - [x] (2026-11-25 11:10, collaudo ok blocco 1) **S-50a · Server finto E2E** (fake-supabase.py + test python) → **Codex** (decisione di Matteo 2026-11-25 09:01: «partiamo con S-50 e partiamo con codex»; Codex ha quota resettata, Antigravity preferito no) · progetto §6.6, §10.3
  - [x] (2026-11-25 11:10, collaudo ok blocco 1) **S-50b · Crittografia iOS + vettori condivisi** → capocantiere/operaio Claude Code · §3, §10.3 · dopo S-50a
  - [x] (2026-11-25 11:10, collaudo ok blocco 1) **S-50c · Crittografia Android sugli stessi vettori** → impresa (Codex) · T1/T3/T4, 256 JVM, build/lint e 7 strumentati API 36 verdi · collaudo del blocco 1 dopo S-50d
  - [x] (2026-11-25 11:10, collaudo ok blocco 1) **S-50d · iOS: trasporto SyncRemote a comportamento identico** → impresa (Codex) · T5/T6 e suite iOS completa verdi (117 unitari, 49 UI) · prossimo COLLAUDO BLOCCO 1 (collaudatore, S-50a…d)
  - [x] (2026-11-25 16:45, collaudo ok blocco 2) **S-50e · iOS: vault, Keychain, mt_e2e, gate** · 2026-11-25 Codex, 137 unitari e 49 UI verdi, T5/T6/T12/T14 iOS coperti, da collaudare nel blocco 2
  - [x] (2026-11-25 16:45, collaudo ok blocco 2) **S-50f · Android: VaultApi, decoratore, Keystore, gate** · 2026-11-25 Codex, build/lint verdi, 276 JVM e 2 strumentati verdi, T5/T6/T12/T14 Android coperti. Da collaudare nel blocco 2
  - [x] (2026-11-25 16:45, collaudo ok blocco 2) **S-50g · Interoperabilità righe iOS↔Android (vettori rows)** · 2026-11-25 Codex, T2 verde su entrambe le piattaforme, 139 unitari e 49 UI iOS, 278 JVM Android, build/lint e verifica Python verdi. Da collaudare nel blocco 2
  - [x] (2026-11-25 16:45, collaudo ok blocco 2 con 3 correzioni obbligatorie prima di S-50p (S-50h2)) **S-50h · iOS: migratore, verifica, rollback** · 2026-11-25 Codex. T7–T11 e T13 con remoti finti, 157 unitari e 49 UI con retry mirati. Interruttore spento. Da collaudare nel blocco 2.
  - [x] (2026-11-25 16:45, collaudo ok blocco 2) **S-50i · Android: migratore, verifica, rollback** · 2026-11-25 Codex. T7–T11 e T13 con fake, 300 JVM, build/lint e 1 strumentato HTTP verdi. Interruttore spento. Prossimo COLLAUDO BLOCCO 2 (S-50e…i) → capocantiere con collaudatore + stress-test, incluse le gare tra dispositivi e il confine di atomicità lato server.
  - [x] (2026-11-26, collaudo ok: punti 1–3 verificati nel diff 8a5020b/1492143, rilettura+verifica vault prima del DELETE in chiaro, D7 solo id verificati con key_id, PATCH condizionata a updated_at; parsing generazioni Z/+00:00 al microsecondo provato) **S-50h2 · iOS: allineare il migratore ad Android (difetti collaudo blocco 2)** → impresa Codex · BLOCCA S-50p, non S-50j/k/l · (1) `E2EMigrator.swift` `finishEnable`/`clearPlain` (righe ~317-319, 365-394): prima di ogni cancellazione in chiaro rileggere il vault (`read(encryptedRemote(dek))`), verificarlo (`E2EVerifier.verify(local: vault, remote: vault)`) e richiedere che gli id in chiaro siano ⊆ id del vault, come Android (`E2EMigrator.kt` 320-331, 382-385); test: vault svuotato dopo A6 → nessun DELETE in chiaro. (2) `finishDisable`/`clearVault(whileCurrent: nil)` (righe ~350-354, 406-428): cancellare solo gli id verificati (come Android `clearVault(null, verified)`), mai «tutto ciò che c'è». (3) `unlock` con marcatore creato (righe ~207-212): rivendicare la migrazione con una PATCH condizionata a una generazione (come Android `newGeneration`/`patch(row, emptyMap(), generation)`), invece di far pilotare la stessa migrazione a due dispositivi. R3: solo file nuovi di test. **2026-11-26 Codex:** punti 1–2 implementati e verificati con tre nuove regressioni. Punto 3 completato: PATCH condizionata a `updated_at`, generazione persistita nel marcatore, verifiche di proprietà prima di scritture e pulizia. Test di subentro e precisione a microsecondi verdi.
  - [x] (2026-11-26, collaudo ok parte client: key_id su ogni upsert e DELETE di mt_vault, A6 solo via RPC con conteggi, 6 messaggi bt_e2e_* → stato cambiato; server finto fedele a §6.7/§6.9; difetti a parte in S-50q.2 e S-50q.3) **S-50q · Client iOS e Android, server finto e SQL §6.7** · SQL applicato da Matteo il 2026-11-26 alle 10:11, 4 righe ok. Client adeguati con `key_id`, RPC A6 con conteggi e interpretazione degli errori. 172 unitari iOS, 312 JVM Android, lint e 15 test del server finto verdi. Parte client da collaudare. Accensione bloccata anche da S-50q.1.
  - [x] **S-50j · iOS: interfaccia e testi 7 lingue** → impresa Codex · 2026-11-25, suite completa 158 unitari e 55 UI verdi, 6 UI E2E verdi sulla build finale · screenshot in `.cantiere/tmp/e2e-ios/screenshots/` · collaudo blocco 3 dopo S-50l, approvazione Matteo in S-50o · **2026-11-26 collaudo ok blocco 3**: 165 unitari iOS e 49 UI generali (4 flaky per connessione al simulatore, verdi alla riprova) + 6 UI E2E (Codex)
  - [x] **S-50k · Android: interfaccia e testi 7 lingue** → impresa Codex · 2026-11-25, 301 JVM, lint, build debug, 10 strumentati generali e T15/T16/T18 verdi · 62 screenshot in `.cantiere/tmp/e2e-android/screenshots/` · dopo S-50l collaudo blocco 3, poi approvazione in S-50o · **2026-11-26 collaudo ok blocco 3**: 311 JVM + lint verdi rieseguiti; 49 chiavi `e2e_*` identiche in 7 lingue; riserva: titolo DE schiaccia «Wiederherstellungsschlüs-sel» a font XL (estetico, per S-50o)
  - [x] **S-50l · Logout, elimina account, cambio utente, stress-test** → impresa Codex · 2026-11-25, lifecycle e stress su entrambe le piattaforme, 165 unitari iOS e 311 JVM Android verdi · il collaudatore completa la suite UI generale iOS nel COLLAUDO BLOCCO 3 (S-50j…l) · **2026-11-26 collaudo ok blocco 3**
  - [x] **S-50l.1 · iOS: isolamento dei movimenti al cambio utente** · 2026-11-25, test scritto prima della correzione e riprodotto su SwiftData in memoria e su disco. Dopo la correzione entrambe le righe vengono cancellate e nessuna passa al secondo utente, con E2E spento e acceso. Da verificare nel collaudo del blocco 3. · **2026-11-26 collaudo ok**: log `isolamento-prima` mostra il test rosso sul bug, `isolamento-dopo` verde; 165 unitari verdi
  - [x] (2026-11-26, collaudo ok: rollbackEnable iOS e Android usa solo la RPC mt_e2e_rollback, nessuna DELETE REST del vault della chiave viva; gare nei due ordini nel server finto verdi) **S-50q.1 · Rollback atomico A6/rollback** · BLOCCA S-50p. SQL §6.9 verificato su PostgreSQL 16 in entrambi gli ordini e applicato da Matteo su Supabase il 2026-11-26 alle 10:40 (3 righe ok). Client iOS e Android: rollback esclusivo via `mt_e2e_rollback` con chiave e generazione attese, ricalcolo su `bt_e2e_state_changed` e `bt_e2e_use_rollback`. Server finto: entrambi gli ordini e richieste HTTP simultanee. Da collaudare.
  - [x] (2026-11-26, collaudo ok: i due log dei digest rimossi da E2EVerifier.swift) **S-50l.2 · iOS: niente ricevute di verifica nei log** → impresa Codex · severità BASSA · BLOCCA S-50p · `Sync/E2E/E2EVerifier.swift` righe 90 e 93 scrivono con `Logger.persistence.info` i digest di verifica (`privacy: .private`, quindi oscurati in release ma visibili in debug/simulatore: li ho visti in chiaro nel log dei test). Rimuovere i due log o lasciarli sotto `#if DEBUG` senza i valori; il resto (file non toccato dal blocco 3, scoperto nel collaudo). **2026-11-26 Codex:** rimossi entrambi i log. Suite iOS: 168 unitari e 7 UI verdi, incluso il caso con interruttore spento.
  - [x] (2026-11-26, collaudo ok: pull iOS/Android filtrato per chiave viva + controllo chiave attiva prima di applicare lo snapshot; pulizia solo DELETE con key_id=eq.<chiave morta> in migrating, ammessa da mt_vault_guard §6.9, conteggi A6 per key_id; wrongKey iOS → ricalcolo; regressione D7 interrotto su due dispositivi anche con pulizia fallita; log digest backup rimossi; interruttori spenti in release; residuo non bloccante in S-50q.4) **S-50q.2 · Righe del vault di una chiave morta bloccano la sync** → impresa Codex · severità MEDIA · BLOCCA S-50p (consigliato) · La pull normale legge il vault senza filtro `key_id` (`VaultRemote.swift` `scopeReads=false` riga ~95, `VaultSupabaseApi.kt` riga ~26) e fallisce se trova una riga di un'altra chiave (iOS `Failure.wrongKey`, Android `bt_e2e_key_mismatch`). Le righe di una chiave morta restano per sempre se D7 si interrompe e un altro dispositivo riattiva con una chiave nuova prima della ripresa (il marcatore viene scartato perché non possiede la riga nuova, `SyncService.swift` ~1385); A4 non le tocca (orfani letti solo con la chiave viva). Risultato: sync bloccata su tutti i dispositivi, senza rimedio dall'app. Inoltre su iOS `wrongKey` non porta al ricalcolo (Android sì, tramite `E2EWriteGuard`). Correzione proposta: in A4 (stato `migrating`) cancellare le righe di chiavi diverse dalla viva con `key_id=eq.<chiave morta>` (il trigger lo permette), e su iOS trattare `wrongKey` come stato cambiato. Test: riga con chiave vecchia + nuova attivazione → pull ok, righe vecchie sparite. **2026-11-26 Codex:** pull per chiave viva, pulizia per singolo `key_id` prima di A6, ricalcolo iOS su `wrongKey`, log dei digest backup rimossi. Regressioni su due dispositivi simulati e sul pull con residui. Da collaudare.
  - [ ] **S-50q.4 · Ritentare la pulizia delle righe di chiavi morte anche fuori dalla riattivazione** → Copilot o Codex · severità BASSA · NON blocca S-50p · Se in A4 la pulizia di S-50q.2 fallisce (rete), le righe della chiave morta restano su mt_vault finché l'utente non disattiva e riattiva (può non succedere mai): sono cifrate con una chiave scartata e non bloccano la sync (letture e conteggi filtrati per key_id), ma sono dati che l'utente può aver eliminato. Proposta minima: in D7 (disattivazione) e/o dopo una pull riuscita in modalità vault, cancellare le righe con key_id diverso dalla chiave viva usando sempre DELETE con `key_id=eq.<chiave morta>` (stesso codice di `clearDeadVaultKeys` iOS/Android). Test: pulizia fallita in A4 → riga morta sparita al passaggio successivo, righe della chiave viva intatte.
  - [x] (2026-11-26 11:06, chiuso da Matteo con verifica SQL su Supabase: `delete_own_account` è security definer e fa `delete from auth.users`; tutte le 7 tabelle mt_* comprese mt_e2e e mt_vault hanno FK `on delete cascade` → nessuna pulizia lato client necessaria, R9 chiuso; vedi DECISIONI) **S-50q.3 · Eliminazione account: tolta la pulizia «al meglio» di mt_vault/mt_e2e** → Matteo (verifica) poi Codex se serve · severità MEDIA (privacy) · BLOCCA S-50p · 1492143 toglie da `Auth/SupabaseManager.swift` (righe ~114-119) e da Android `SyncService.kt` (~275) / `E2EController.eraseRemoteAccountData` le DELETE dopo `delete_own_account`, contando solo sulla cascata da `auth.users`. Il progetto (§ riga 213 e rischio R9) le prevedeva proprio perché il codice di `delete_own_account` non è nel repository. La modifica è minima e inerte a interruttore spento, ma cambia il progetto senza una decisione. Matteo: in Supabase → SQL Editor eseguire `select prosecdef, prosrc from pg_proc where proname = 'delete_own_account';` e riportare il testo. Se cancella `auth.users` → registrare in DECISIONI e chiudere R9; altrimenti Codex ripristina la pulizia con `key_id=eq.<chiave>` su mt_vault e `mt_e2e_rollback` se la riga è `migrating`.
  - [ ] **S-50m · Commissione Suprema 10/10 + manuale docs/MoneyTracker.md** → capocantiere/operaio Claude Code · §10.3 · dopo collaudo blocco 3
  - [x] (Matteo, 2026-11-24 23:22: eseguito, 13 righe) **S-50n · Matteo: incollare lo SQL in Supabase (2 minuti)** → Matteo · istruzioni 📍▶️↩️ nel progetto §6.3 · inerte, si può fare anche subito
  - [?] **S-50o · Matteo: approvare le schermate (D-014) + prova reale facoltativa con account di prova** → Matteo · §10.3 S-50o · dopo S-50m
  - [ ] **S-50p · Accensione interruttore + FAQ e privacy del sito** → capocantiere/operaio Claude Code · §10.3 S-50p · SOLO dopo S-50n e S-50o [x] · (S-50h2, S-50q, S-50q.1, S-50q.2, S-50q.3, S-50l.2 chiusi il 2026-11-26)
