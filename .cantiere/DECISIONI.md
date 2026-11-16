# REGISTRO DELLE DECISIONI

Le decisioni che non si devono ridiscutere ogni volta. Solo aggiunte.

## D-001 · 2026-11-13 · Adozione del modello Cantiere
- **Decisione:** il progetto segue il regolamento in AGENTS.md.
- **Perché:** stessa squadra e stesso metodo in ogni progetto, ripresa del lavoro a basso costo di token.
- **Chi ha deciso:** Matteo

## D-002 · 2026-11-13 · Rimosso il guardiano dei siti web
- **Decisione:** cancellato `.github/workflows/guardiano.yml` (Lighthouse/Playwright).
- **Perché:** è pensato per i siti web, inutile su un'app iOS, e girerebbe a ogni push su `main` e ogni notte consumando minuti GitHub. Un eventuale workflow `xcodebuild test` su runner macOS si valuta più avanti, solo con l'ok di Matteo.
- **Chi ha deciso:** brief del cantiere (Matteo)

## D-003 · 2026-11-13 · `@MainActor` su CurrencyFormattingTests
- **Decisione:** aggiunto `@MainActor` alla struct `CurrencyFormattingTests` (nessuna asserzione cambiata).
- **Perché:** il target app ha `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, quindi `Decimal.parseAmount` è isolato su MainActor e il test target (non isolato) non compilava: i test unitari erano rotti già prima del cantiere. Eccezione puntuale alla regola «test esistenti intoccabili», autorizzata da Matteo.
- **Chi ha deciso:** Matteo

## D-004 · 2026-11-13 · Simulatore di riferimento
- **Decisione:** i test si lanciano su **iPhone 18 Pro, iOS 27.2** (`id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`, su questo Mac).
- **Perché:** il runtime iOS 26.5 è stato rimosso; su iOS 27.1 c'era solo «iPhone Duo» e i 12 test UI fallivano (anche sul codice originale `tour-v1`: problema d'ambiente, non del cantiere). Su 27.2 tutto verde.
- **Chi ha deciso:** Matteo / Claude Code

## D-005 · 2026-11-13 · Token «Sentiero» e dark mode (S-1)
- **Decisione:** i token stanno nell'enum `DS` di `Views/Theme.swift`, adattivi con `Color(lightHex:darkHex:)`; **non** si usa `Color(hex:)` di `BucktrailTheme.swift` (colori fissi, cancellerebbe il dark mode). Un solo token per ruolo: i nomi storici restano e cambiano valore: `ink` (testo), `paper` (= `bg`), `fog` (= `border`), `smoke` (= `inkSecondary`), `positive` = alias di `accent`, `negative` = alias di `danger`. Nuovi: `surface`, `divider`, `accent`, `onAccent`, `accentSoft`, `planned`, `plannedText`, `plannedSoft`, `danger`, `dangerSoft`, `transfer`, `hero`, `heroText`, `heroSecondary`, `heroDivider`, `heroAccent`, `heroPlanned`.
- **Valori light:** tabella §2 dell'handoff. **Valori dark:** `bg #0E1210`, `surface #171C19`, testo `#F1F3EF`, `hero #1F2622` come proposto; in più `accent`/`heroAccent` `#5FD19B`, `planned`/`plannedText` `#F2A65A`, `danger #F26B5E`, `transfer #6FA8E0`, `inkSecondary #9AA39D`. **Scarto dall'handoff:** l'handoff teneva accent/planned «invariati» in dark, ma `#1F7A4D` su `#0E1210` ha contrasto ≈3.6:1 (sotto AA per il testo): le varianti schiarite superano 4.5:1 su bg e surface (calcolato). Per lo stesso motivo `onAccent` è quasi-nero in dark (testo su FAB verde chiaro).
- **Effetto visivo:** i nomi storici cambiano valore, quindi l'app prende subito una leggera tinta verde-grigia (paper, fog, smoke, ink); layout e componenti invariati finché non migrano gli step 3–9.
- **Font:** Space Grotesk (Medium, SemiBold, Bold) e Inter 18pt (Regular, Medium, SemiBold), statici, in `MoneyTracker/Resources/Fonts/` + `UIAppFonts` in `Info.plist` + licenze OFL accanto. `DS.Typo` usa `Font.custom(…, relativeTo:)` (Dynamic Type) con ripiego automatico su SF Pro; importi con `.monospacedDigit()`. Originali in `02_RISORSE/originali/font/`.
- **Chi ha deciso:** Claude Code (brief + handoff)

## D-006 · 2026-11-13 · Tinte categoria
- **Regola:** `CategoryTint.tint(for: nome)` (`Views/CategoryTint.swift`): mappa fissa per le 14 categorie predefinite (verde: Salute, Lavoro, Risparmio, Altro; ambra: Cibo, Shopping, Regali; blu: Trasporti, Casa, Viaggi, Giroconto; viola: Svago, Abbonamenti, Istruzione); per le personalizzate hash **FNV-1a 32 bit** del nome in UTF-8 modulo 4 (non `hashValue`, instabile tra avvii). Nessuna modifica al modello SwiftData; varianti dark per ogni tinta. Test in `CategoryTintTests`.
- **Chi ha deciso:** Claude Code (brief)

## D-007 · 2026-11-13 · Serie del saldo per la TrailView
- **Regola:** `Domain/BalanceTrail.swift`, funzione pura `BalanceTrail.make(currentBalance:entries:now:)`, nessuna modifica alle funzioni esistenti. Parte dal saldo attuale e va all'indietro togliendo i movimenti fatti (serie reale, giorno 1 → oggi); la proiezione aggiunge i non fatti in avanti (oggi → fine mese). Pianificati scaduti ancorati a oggi, oltre fine mese all'ultimo giorno, così l'ultimo punto proiettato = «Saldo atteso» (`futureBalance`) sempre, anche con date anomale. Fatti con data futura → oggi, precedenti al mese → giorno 1. Senza pianificati nessuna proiezione.
- **Perché:** coerenza obbligatoria con i saldi di `AccountBalanceCache` senza ricalcolarli a modo nostro. `Decimal` esatto; test in `BalanceTrailTests` (6 casi).
- **Nella vista:** la serie sta in `@State`, ricalcolata con `onChange` su firma (n. movimenti, saldo attuale, saldo atteso, giorno), mai nel `body`. Limite noto: cambiare solo la data di un pianificato senza toccare saldi o conteggio aggiorna la curva alla chiusura della modifica o al rientro nella schermata.
- **Chi ha deciso:** Claude Code (brief)

## D-008 · 2026-11-13 · Nuovo motore delle ricorrenze (serie virtuali) — ok scritto di Matteo
- **Autorizzazione:** Matteo ha autorizzato per iscritto di agire su logica e dati (deroga a «solo visivo» e alle zone intoccabili Domain/, Models/Persistence, Sync/ limitatamente a questo lavoro).
- **Regole decise:** (1) la serie è un solo oggetto (inizio, frequenza mensile/settimanale/annuale, fine opzionale); (2) le occorrenze future sono **virtuali** (solo visualizzazione, mai in saldi, spese, entrate, statistiche); (3) il **primo del mese** tutte le occorrenze di quel mese diventano transazioni vere **pianificate**; (4) saltare **solo questo mese**; (5) disattivare **per sempre** = la serie finisce da quella data, il passato resta; (6) modifica/eliminazione con scelta **solo questa / questa e le successive / tutte**; valido per tutte le frequenze.
- **Dati esistenti:** NESSUNA migrazione automatica delle ricorrenti attuali: le sistema Matteo a mano (lo storico è inattendibile perché il vecchio motore non funzionava). Il nuovo schema non deve alterare né cancellare le transazioni esistenti.
- **Vincoli:** nuova versione schema SwiftData con migrazione leggera che non tocca i dati; Decimal; test nuovi; allineamento Sync/Supabase; Commissione Suprema prima del merge.
- **Alternative scartate:** generazione nel giorno esatto (comportamento attuale); conversione automatica dello storico.
- **Chi ha deciso:** Matteo

## D-009 · 2026-11-14 · Dettagli S-13 (risposte di Matteo, integrano D-008)
- **Via il vecchio motore:** `RecurringTransactionEngine.swift` e `RecurringTransactionEngineTests.swift` si cancellano (conferma di Matteo: deroga alla zona «test esistenti intoccabili», limitata a questo file). Gli altri test restano intoccabili.
- **«Elimina tutte»:** toglie le occorrenze pianificate non ancora fatte; quelle già fatte (isDone) restano sempre.
- **«Disattiva da qui in poi»:** la serie termina da quella occorrenza compresa; se l'occorrenza di oggi è ancora pianificata sparisce, se già fatta resta. Nel menu anche una voce «Termina dopo questa» per l'altro caso.
- **Regola generale:** le copie già fatte non si toccano mai.
- **Fuori da S-13 (Matteo non li vuole):** lista «vecchie ricorrenti da sistemare», ricorrenze sui trasferimenti, card «Prossime scadenze» in Home. Le vecchie ricorrenti le rifà Matteo a mano.
- **Piano tecnico:** architetto (RecurringRule, SchemaV3, UUIDv5 deterministico, materializzazione il primo del mese dal contesto principale, tabella `mt_recurring_rules` su Supabase). Causa individuata: le copie del vecchio motore, salvate su un contesto in background, non risultano «sporche» per il sync e il pull le cancella (`SyncService.swift` ~651).
- **Chi ha deciso:** Matteo

### Nota di esecuzione D-009 · 2026-11-14 02:20 · Codex
- S-13c: eliminati `Domain/RecurringTransactionEngine.swift` e i suoi tre test in `RecurringTransactionEngineTests.swift`, come autorizzato. Nessun dato legacy convertito/cancellato e nessun altro test esistente modificato.
- Dettaglio operativo del limite del piano: massimo **36 mesi più recenti**, incluso quello corrente; il watermark avanza al mese corrente. `nil` è una regola nuova e parte solo dal mese corrente (o dal mese di inizio futuro), evitando storico inventato. Test dedicati verdi.
- Stop esplicito di Matteo durante la suite UI: salvare tutto e riprendere da Claude Code, poi Codex, senza rifare l'implementazione. Nessun merge/push e nessuna dichiarazione di collaudo completo.

## D-010 · 2026-11-15 · Campi ricorrenti uniformi per scope (S-25, sostituisce S-23 e parte di D-009)
- **Chi decide:** Matteo: autorizzazione esplicita a modificare Domain per S-24/S-25; autorizzati anche i test S-15 per ottenere suite UI verde senza cambiare comportamento dell'app.
- **Editor normale:** modifica tutti i campi della serie, passato/futuro e copie effettuate comprese, tramite lo stesso RecurringSeriesEditor con scope Tutte. Frequenza/fine restano fuori dall'editor normale.
- **Scope:** Solo questa memorizza tutti i campi editabili nel codec dell'eccezione, incluso il conto esplicitamente vuoto; successive aggiorna dalla data originale selezionata e ricollega le copie alla nuova serie; Tutte aggiorna tutte le copie esistenti e la regola dei virtuali futuri.
- **Già effettuato:** Matteo ha precisato che resta uno stato della singola copia. Non viene propagato dal motore; l'editor normale può ancora modificarlo sulla sola copia scelta.
- **Override precedenti:** Tutte sostituisce gli override di valori e date con i valori salvati per la serie. I salti espliciti restano saltati se la cadenza non cambia; con nuova cadenza si applica il reset già previsto dal motore. Nessuna copia viene creata per inventare lo storico mancante.
- **Cambio date/frequenza:** le copie esistenti in scope seguono la stessa posizione nella nuova cadenza (giorno limitato all'ultimo del mese nei mesi corti), con ID deterministici riallineati per evitare duplicati. La materializzazione resta pianificata per le nuove copie.
- **Eliminazione:** invariata la protezione delle copie effettuate e dei dati legacy. Da qui in poi confronta il giorno originale dell'occorrenza, non il timestamp (che escludeva erroneamente il mattino) né la data eventualmente spostata.
- **Alternative scartate:** duplicare il motore nelle viste; lasciare eccezioni di valori che contraddicono Tutte; propagare lo stato effettuato e alterare i saldi delle altre copie senza volontà di Matteo.

## 2026-11-16 · Riferimenti S-6/S-7/S-8 (Matteo)
Autorizzata lettura diretta del sorgente HTML inline dei mockup, comprese le strutture ripetute sc-for/hint-placeholder-count, senza rendering/support.js. DESIGN_HANDOFF §4 prevale in caso di conflitto. PNG originali assenti: confrontare screenshot simulatore light/dark/XL/de con misure, token e struttura del sorgente; dichiarare differenze residue, senza dichiarare conformità. Confronto visivo definitivo al collaudatore. Nessun push/merge.
