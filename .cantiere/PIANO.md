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

### S-8 [!] Conti
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Conti.dc.html`, raggruppamento per tipo solo visivo
- **Leggere:** `DESIGN_HANDOFF.md` §4 Conti, `Views/AccountsView.swift`
- **Toccare:** `AccountsView.swift`
- **Fatto quando:** swipe/long-press, archiviazione ed esclusione dal totale invariati; test verdi
- **Non fare:** cambiare il modello dei conti
- **Collaudo 2026-11-16 11:34: [!] NON PASSA per un punto.** Correggere (Codex): in `Views/AccountsView.swift:~183` le righe archiviate espanse usano `.opacity(0.35)` sull'intera riga: testo e importi quasi illeggibili (contrasto ~1,5:1, vedi `.cantiere/tmp/s8/states.png` riquadro 3, e dark). Sostituire con attenuazione leggibile (es. opacity 0.6-0.65 o colori DS.ink2 senza opacity sull'intera riga) mantenendo la distinzione visiva e la riga ripristinabile; ricontrollare light/dark/XL. Tutto il resto conforme: swipe/long-press, archiviazione, esclusione dal totale, hideBalance, hero/gruppi/icone 40/13, tratteggiata Archiviati con conteggio separato accettata. Dopo il fix basta ricollaudo del solo stato archivi espansi. Aperto non bloccante: "[DA COMPLETARE]" in de (hero, gruppo Liquidità/Risparmio).

- **Eseguito Codex 2026-11-16 11:31:** hero patrimonio, gruppi visivi per tipo, totali gruppo esclusi correttamente, icone tinta, avviso soglia da UserDefaults esistente, riga tratteggiata archiviati con apertura/ripristino. Totali globali, mutazioni e AddAccountView invariati. Build senza warning, 82 unit + 12 UI mirati con ultimi esiti verdi tra i run (non un singolo run completo). Corretto hit target Archiviati dopo primo test rosso, nessuna asserzione rimossa. 13 immagini finali ispezionate: light/dark/XL/de, escluso, archiviati chiusi/aperti, soglia lunga XL, saldi nascosti XL. `.cantiere/tmp/s8/`. Residui: traduzioni ⏳, Archiviati con conteggio separato, icone SF invece SVG, attenuazione preesistente righe archiviate da valutare al collaudo. Nessuna conformità dichiarata.

### S-9 [ ] Impostazioni, sheet di inserimento, categorie, login
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

### S-13 [ ] Motore ricorrenze a serie virtuali (D-008)
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
  - S-13f [~] Sync → Codex · parte Swift **collaudata ok 2026-11-14 10:40** (diff cff65f7); resta [~] solo perché manca la prova reale su Supabase (due dispositivi, due utenti) — vedi S-17 e S-13g
    - 2026-11-14 10:17 · Codex: preparata **solo la parte SQL**, su richiesta di Matteo, in `PER-MATTEO.md` (tabella, indice user_id, grant CRUD e 4 policy RLS). Da collaudare; non eseguita su Supabase. S-13e resta a Matteo; DTO/push/pull/clearLocalData e test Sync ancora da implementare in S-13f.
    - 2026-11-14 10:33 · Codex: DTO, upsert/deleteOrphans, pull max watermark, logout e 4 nuovi test; build + 64 unit verdi (`/tmp/moneytracker-s13f-recheck.log`). Prova reale e collaudo da fare; scoperta S-16 separata.
    - 2026-11-14 10:40 · collaudatore: DTO 16 colonne = SQL, CHECK frequency coerente coi valori del calcolatore, NULL espliciti, push/deleteOrphans filtrati per user_id con fetch throwing, pull max watermark (9 combinazioni), logout ok, 64 unit verdi (log riletto). Nessun difetto bloccante; un rischio di pull → S-17.
  - S-13g [x] UI funzionale → Codex · implementata 2026-11-14: creazione regole/ID deterministici, editor ambiti/salta/termina, serie programmate e virtuali futuri esclusi dai totali, alert errori e avvii lifecycle già presenti verificati. Models/Domain/Sync intatti. Build + 67 unit + 1 nuovo UI verdi (2026-11-14 10:59, `/tmp/moneytracker-s13g-final.log`). Collaudo indipendente da fare. Traduzioni provvisorie nelle 7 lingue → S-19. Rifinitura grafica → S-18. · **collaudato 2026-11-14 11:15** (be6ceb0): ambiti/salta/termina/alert/avvii ok, virtuali fuori dai totali, build+67 unit+1 UI verdi, Domain/Models/Sync intatti. Note: doppio safeSave ridondante in AddTransactionView; il 3° tentativo UI è stato aggiustato solo nel test.
  - S-13h [!] Documento + collaudo + Commissione Suprema → collaudatore · aggiornare anche i soli commenti obsoleti sul vecchio actor in AccountBalanceCache, CurrencyFormatting e Logging (nessun riferimento eseguibile residuo). · 2026-11-14 11:08: commenti obsoleti sistemati (0 riferimenti a RecurringTransactionActor), docs/MoneyTracker.md+PDF aggiornati, 68 unit verdi. **Commissione Suprema NON a 10/10** → checkpoint (push) bloccato fino a S-21/S-22/S-19/S-18.
  - Ogni passo con confronto mockup dove c'è grafica. Piano completo: `.cantiere/piano-s13.md`

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

- S-13f/SQL collaudato 2026-11-14 10:30 (ok, solo diff documentale; SQL non eseguito). Resta [ ] il Sync Swift. S-13e: tocca a Matteo (PER-MATTEO).

### S-16 [ ] Verificare precisione Decimal elevata nella persistenza RecurringRule
- Scoperto durante S-13f: il DTO conserva esattamente `123.4567890123456789` nel round-trip JSON, ma il confronto dell'importo dopo inserimento/fetch SwiftData ha fallito nel test nuovo di merge (prima esecuzione: `/tmp/moneytracker-s13f.log`, riga 928). Il test comprendeva anche exceptionsJSON: isolare e misurare la differenza prima di attribuire la causa.
- Il test finale di merge usa `0.2`; il DTO mantiene la prova ad alta precisione. Nessun modello o test preesistente modificato.
- A chi: collaudatore per diagnosi; eventuale correzione Models/Persistence richiede assegnazione specifica. Non dichiarare risolto in S-13f.
- **Diagnosi preliminare (collaudatore 2026-11-14 10:40, da log, nessuna esecuzione nuova):** il confronto fallito era `inserted.amount == added.amount` (importo), non exceptionsJSON (nel log risulta «not evaluated»). `added` non era inserito nel context, `inserted` è l'oggetto persistito: il valore a 19 cifre non torna uguale dopo il passaggio dal modello SwiftData. Ipotesi (NON verificata): SwiftData salva `Decimal` con precisione ridotta. Impatto pratico basso: gli importi reali hanno ≤ 2–4 decimali (il test con `0.2` passa). Il DTO/JSON è esatto (provato). Per chiudere: un test diagnostico che stampi `amount` dopo save+fetch per 0.2, 1234.56, 12 cifre, 19 cifre. Nessuna correzione al modello finché non è misurato.

### S-17 [~] Pull: non cancellare regole locali non ancora spedite
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
