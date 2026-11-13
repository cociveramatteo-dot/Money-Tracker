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

### S-2 [~] Componenti base
- **A chi:** Codex
- **Obiettivo:** `Card`, `HeroCard`, `MovementRow`, `ProgressBar`, `BudgetStatus`, `SegmentedPill`, `FilterChip`, ciascuno con `#Preview` (light/dark)
- **Leggere:** `DESIGN_HANDOFF.md` §3, `Views/Theme.swift` (token di S-1), `BucktrailTheme.swift`
- **Toccare:** solo file nuovi (es. `MoneyTracker/Views/Components/`)
- **Fatto quando:** componenti compilano e hanno preview; nessuna vista esistente modificata; test verdi
- **Non fare:** toccare viste esistenti, introdurre colori fuori da `DS`
- **Eseguito 2026-11-13 20:15 (Codex):** sette nuovi componenti in `Views/Components/`, 14 preview light/dark; build e 21 test unitari + 12 UI verdi sul simulatore richiesto. Da collaudare; nessuna vista o test esistente modificato.

### S-3 [ ] FloatingTabBar + FAB
- **A chi:** Claude Code
- **Obiettivo:** nuova tab bar flottante e FAB con la grafica Sentiero
- **Leggere:** `DESIGN_HANDOFF.md` §3 (icone tab §3), `Views/ContentView.swift`
- **Toccare:** `ContentView.swift`, componenti tab bar
- **Fatto quando:** stessi indici di tab, stesse azioni FAB per tab, stessi `accessibilityIdentifier` (se cambiano si aggiornano i UI test, non si tolgono); `accessibilityLabel` FAB «Nuovo movimento/budget/obiettivo/conto»; test verdi
- **Non fare:** cambiare la navigazione

### S-4 [ ] Home con TrailView
- **A chi:** Claude Code
- **Obiettivo:** Home come `Main.dc.html`: header, HeroCard con TrailView, conti in scroll orizzontale, ultimi movimenti
- **Leggere:** `DESIGN_HANDOFF.md` §4 Home, BRIEF «TrailView», `Views/DashboardView.swift`, `Domain/` (calcoli saldo)
- **Toccare:** `DashboardView.swift`, nuova funzione **pura** in `Domain/` per la serie giornaliera cumulata + proiezione (con test in `MoneyTrackerTests/`), `DECISIONI.md`
- **Fatto quando:** ultimo punto reale = «Saldo attuale», ultimo proiettato = «Saldo atteso»; senza pianificati niente tratto ambra né riga attesa; serie calcolata una volta per cambio dati (non nel `body`); `accessibilityHidden(true)`; oscura importi `•••• €`; test verdi
- **Non fare:** modificare le funzioni esistenti di `Domain/`, ricalcolare saldi nella vista

### S-5 [ ] Movimenti
- **A chi:** Antigravity (o Codex)
- **Obiettivo:** schermata come `Movimenti.dc.html`, sezione «In arrivo · pianificati» in cima
- **Leggere:** `DESIGN_HANDOFF.md` §4 Movimenti, `Views/TransactionsView.swift`, `docs/MoneyTracker.md` §6
- **Toccare:** `TransactionsView.swift` e componenti di S-2
- **Fatto quando:** filtri, ricerca, swipe, conferma trasferimenti, filtri avanzati, sezione ricorrenti invariati; test verdi
- **Non fare:** toccare `@Query`, logica o calcoli (Gemini Flash: stare lontano da SwiftData)

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

### S-10 [ ] Verifica finale + Commissione Suprema
- **A chi:** Claude Code (collaudatore)
- **Obiettivo:** collaudo dell'intero ramo
- **Leggere:** diff del ramo, BRIEF §6–7
- **Toccare:** correzioni minime
- **Fatto quando:** build e test verdi; Dynamic Type XL, VoiceOver, 7 lingue, oscura importi su tutte le schermate, demo, sync, export CSV/PDF, Siri; Commissione Suprema 10/10; **ok di Matteo sull'iPhone** prima del merge su `main`
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
