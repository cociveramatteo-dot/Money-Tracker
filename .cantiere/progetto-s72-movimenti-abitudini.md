# Progetto esecutivo S-72 · Movimenti, Ricorrenti, Abitudini, Statistiche

> Architetto (Claude Code · Opus), 2026-11-27. Per l'impresa (Antigravity). Ramo `redesign-sentiero`.
> **Specifica che vince su tutto:** `.cantiere/DECISIONI.md`, voce «2026-11-27 · Movimenti, Ricorrenti, Abitudini, Statistiche».
> **Sostituisce S-70f** (`a320bcf`, `nextMonthSummaryBlock`): il blocco «Mese successivo» sparisce.
> **Non toccare:** `MoneyTracker.xcscheme`, `MoneyTracker/Intents/` (S-70i in corso in parallelo), Models/Persistence, Sync/, Auth/,
> Export/ (anche Android `PdfReport.kt`), Formatting/, notifiche, `RecurringMaterializer`, `RecurrenceCalculator`, `RecurringSeriesEditor`.
> Domain/ si tocca SOLO in S-72d (`RecurringSeriesDetector`, autorizzato da Matteo).

## 0. Regole comuni a tutti i task

- **Ordine di esecuzione:** S-72b → S-72a → S-72d → S-72c → S-72e. Un commit per task, iOS e Android insieme:
  `git commit -m "[impresa] S-72x <titolo>"`. Dopo ogni task: build e test verdi su entrambe le piattaforme, poi `[~]` in PIANO.
- **Nessun calcolo nuovo sui dati di dominio:** le occorrenze vengono da `RecurrencePresentationCache` (iOS) / `RecurrenceCalculator`
  (Android) come oggi. Le somme sono somme di ciò che la lista mostra, in `Decimal` (iOS) / `BigDecimal` (Android). Mai `Double`.
- **Logica pura fuori dalle viste**, in file nuovi testabili (iOS in `MoneyTracker/Views/`, non in Domain/; Android in `ui/`).
  Il progetto Xcode usa cartelle sincronizzate: i file nuovi entrano da soli nel target.
- **Grafica:** token `DS` / `Bt.colors`, niente colori fissi, niente `preferredColorScheme`. Dynamic Type: a dimensioni
  di accessibilità due riquadri affiancati vanno in colonna.
- **Oscura importi** (`hideBalance` / `prefs.hideBalance`): tutti i totali nuovi mostrano «• • •» come `FixedTotalTile`.
- **Localizzazione:** chiavi nuove nelle 7 lingue iOS (`MoneyTracker/<lingua>.lproj/Localizable.strings`) e Android
  (`res/values*/strings.xml`: values, -en, -de, -es, -fr, -ja, -b+zh+Hans). Una chiave si rimuove solo se `grep` su tutto il
  repository (app, test, Export/PDF) non trova altri usi.
- **Test esistenti:** non si modificano, salvo quelli elencati per nome in questo documento (funzioni rimosse per decisione di
  Matteo). Ogni modifica a un test esistente si scrive in CONSEGNA con il motivo.
- **Verifiche per ogni task:**
  iOS `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=iPhone 18 Pro' build test` (oppure la
  suite `MoneyTrackerTests` + gli UI test indicati nel task);
  Android `./gradlew assembleDebug lintDebug testDebugUnitTest` in `03_CODICE/bucktrail-android`. Poi `graphify update .`.
- **Screenshot** (in origine in `.cantiere/tmp/s72/<task>/`: iOS in modalità demo, chiaro, scuro, tedesco con Dynamic Type AX-XL,
  oscura importi acceso; Android chiaro e scuro). Gli screenshot temporanei sono stati eliminati il 2026-11-28 (cartella rimossa): per l'approvazione grafica di Matteo (D-014, `APPROVAZIONI.md`) si rigenerano dai test o dal simulatore.

---

## S-72b · Occorrenze programmate come righe normali, gruppo «In arrivo» solo nei mesi futuri

### Cosa cambia per l'utente
- Le occorrenze virtuali delle serie (oggi sezione «Serie programmate» con `VirtualOccurrenceRow` e la scritta «Virtuale · esclusa
  dai totali») diventano righe identiche a `MovementRow` in stato pianificato (`isPlanned: true`): stessa altezza (`compact: true`),
  stesso sfondo con angoli 18 sul primo e ultimo elemento del gruppo, icona tratteggiata, importo in `plannedText`, simbolo
  «repeat» (`isRecurring: true`), metadati «Fissa»/categoria · data come le righe non effettuate di oggi.
- **Mesi futuri** (mese scelto > mese corrente): in cima un unico gruppo «In arrivo · pianificati» con le occorrenze virtuali
  E i movimenti reali non effettuati (`!isDone`) del mese. Intestazione come oggi: titolo a sinistra, totale con segno a destra,
  entrambi `plannedText`; il totale esclude i trasferimenti (stessa regola di `groupHeader`). Ordine nel gruppo: data crescente
  (prima il più vicino), a parità `createdAt` decrescente, poi id.
- **Mese corrente e mesi passati:** nessun gruppo in cima. Le righe non effettuate (che nel mese corrente sono le occorrenze già
  materializzate dal `RecurringMaterializer`) stanno nei gruppi per giorno, mescolate alle altre, nell'ordine di sempre
  (`sortedForDisplay`). Vedi domanda **D3**.
- Tap su riga virtuale → `RecurrenceEditorView` come oggi. Righe virtuali senza swipe e senza menu contestuale (come oggi: non
  esistono ancora nel database).

### File da toccare
- iOS: `MoneyTracker/Views/TransactionsView.swift` (`movementList`, `virtualOccurrences` invariato nei filtri),
  nuovo `MoneyTracker/Views/MovementListLayout.swift`.
- Android: `ui/screens/MovementsScreen.kt` (blocchi `virtual`/`planned`/`groups`), nuovo `ui/MovementListLayout.kt`.
- `VirtualOccurrenceRow` (iOS in `ProgrammedRuleCard.swift`, Android in `RecurrenceScreens.kt`): dopo questo task non è più usato
  → rimuoverlo. Chiave «Virtuale · esclusa dai totali» / `virtuale_esclusa_dai_totali`: rimuovere se non ha altri usi.

### Decisioni tecniche
- Tipo unico di riga, puro: iOS `enum MovementListItem: Identifiable { case real(Transaction), virtual(Occurrence) }` con `date`,
  `signedAmount` (Decimal, 0 per i trasferimenti nel totale), `isPlanned`; Android `sealed interface MovementItem { Real(TransactionEntity), Virtual(RecurringRuleEntity, Occurrence) }`.
- Funzione pura `MovementListLayout.make(real:virtual:isFutureMonth:calendar|zone) -> (planned: [Item], days: [(day, [Item])])`.
  `isFutureMonth` = mese scelto > mese corrente (stessa condizione già usata per calcolare le virtuali). Le virtuali esistono solo nei
  mesi futuri: nel mese corrente l'elenco virtuale è vuoto per costruzione.
- **Parità Android sui filtri delle virtuali:** oggi Android non applica importo minimo/massimo né periodo personalizzato alle
  virtuali (iOS sì) e la ricerca usa `contains(ignoreCase)` invece di `KeywordCategoryClassifier.fold`. Allineare ad iOS e alle righe
  reali, altrimenti i totali di S-72a non coincidono con la lista.
- iOS: le righe del gruppo restano nella stessa `Section` del `List`, con `listRowBackground` `UnevenRoundedRectangle` calcolato su
  primo/ultimo del gruppo unito. Identificatore riga virtuale `virtualRow_<occurrence.id>`, `accessibilityValue("Pianificato")`.
  Android: `testTag("virtualRow_<id>")`.

### Localizzazione
Nessuna chiave nuova (riusa «In arrivo · pianificati», «Fissa», «Pianificato»).

### Test da aggiungere
- iOS `MoneyTrackerTests/MovementListLayoutTests.swift`; Android `app/src/test/.../ui/MovementListLayoutTest.kt`. Casi:
  mese futuro → gruppo con virtuali + reali non effettuati, ordine crescente, totale con segno senza trasferimenti;
  mese corrente → gruppo vuoto, non effettuati nei gruppi per giorno nell'ordine di `sortedForDisplay`;
  mese passato con un non effettuato → nei gruppi per giorno; nessuna riga persa né duplicata (conteggio in = conteggio out).

### Fatto quando
- In un mese futuro della demo, in cima un solo gruppo «In arrivo · pianificati» con righe identiche alle `MovementRow` pianificate
  e totale a destra dello stesso colore; nessuna scritta «Virtuale».
- Nel mese corrente nessun gruppo in cima; le occorrenze non confermate compaiono al loro giorno.
- Test nuovi verdi, suite esistenti verdi, build Android e lint verdi.

### Rischi
- Angoli e separatori sbagliati se il gruppo è spezzato in più `Section` (controllare negli screenshot).
- UI test che cercano «In arrivo · pianificati» nel mese corrente: se uno fallisce, NON correggerlo, scriverlo in CONSEGNA (serve Matteo).

### Screenshot
Mese futuro con gruppo «In arrivo» (chiaro, scuro, de AX-XL, oscura importi); mese corrente con occorrenza non confermata in mezzo ai giorni.

---

## S-72a · Totali in fondo a ogni sezione di Movimenti

### Cosa cambia per l'utente
In fondo alla lista di ogni sezione, per qualsiasi mese, un blocco di riquadri in stile Home (`FixedTotalTile`), **senza titolo**
(niente «Mese successivo»; con la ricerca attiva la lista copre più mesi, quindi un titolo col mese sarebbe sbagliato):

| Sezione | Riquadri |
|---|---|
| Tutti | Uscite · Entrate |
| Fisse | Spese fisse · Entrate fisse |
| Uscite | Uscite |
| Entrate | Entrate |
| Trasf. | Trasferito |
| Ricorrenti (arriva con S-72c) | Uscite programmate · Entrate programmate |

### Regola di calcolo (una sola, pura)
Le somme si fanno **sulle stesse righe che la lista mostra** (output di `filtered(for:)` + virtuali filtrate di S-72b), quindi
seguono mese, categoria, ricerca, importo min/max e periodo personalizzato, ed includono effettuati, pianificati e virtuali.
- Uscite/Spese fisse = somma degli importi delle righe di tipo uscita **non trasferimento**; Entrate/Entrate fisse = idem entrata.
  In «Tutti» i trasferimenti sono nella lista ma non entrano in Uscite/Entrate (non sono spese né entrate: stessa regola dei
  subtotali per giorno). In «Fisse» un eventuale trasferimento fisso resta escluso per lo stesso motivo.
- Trasferito = ogni trasferimento contato **una volta**: la lista mostra entrambe le gambe, quindi si deduplica per
  `transferGroupId` (una gamba per gruppo); le gambe con `transferGroupId` vuoto contano singolarmente.
- Importi sempre positivi nei riquadri (come Home). Colori: Uscite `DS.negative`, Entrate `DS.positive`, Trasferito `DS.transfer`
  (Android: `c.negative`, `c.positive`, colore trasferimento esistente).
- Lista vuota → nessun blocco totali (resta solo lo stato vuoto).

### File da toccare
- iOS: `TransactionsView.swift` — togliere `NextMonthTotals`, `nextMonthTotals(...)`, `currentNextMonthTotals()`,
  `nextMonthSummaryBlock`, `nextMonthOccurrenceCache`, `nextMonthTarget`, `shouldShowNextMonthSummary` e i due punti d'uso;
  aggiungere il blocco come penultima `Section` di `movementList` (sfondo trasparente, senza separatori, come faceva S-70f).
  Nuovo `MoneyTracker/Views/MovementSectionTotals.swift` (funzione pura + piccola vista `MovementTotalsBlock` che usa `FixedTotalTile`).
  `FixedTotalTile` in `Theme.swift` non si modifica (accetta già `title`, `amount`, `color`, `hidden`).
- Android: `MovementsScreen.kt` — togliere `NextMonthSummary`, `computeNextMonthSummary` e l'`item("nextMonthSummary")`; aggiungere
  `item("sectionTotals")`. Nuovo `ui/MovementSectionTotals.kt`. Riusa il composable `FixedTotalTile` già usato da S-70f.
- Calcolare le righe filtrate una sola volta per render e passarle sia alla lista sia ai totali (iOS: `body` già calcola
  `currentList` e `virtual`; Android: `remember` con le stesse chiavi di `filtered`/`virtual`).

### Localizzazione (nuove, 7 lingue iOS e Android)
| Chiave iOS | Android | it | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|---|---|
| `Trasferito` | `trasferito` | Trasferito | Transferred | Übertragen | Transferido | Transféré | 振替額 | 已转账 |
| `Uscite programmate` | `uscite_programmate` | Uscite programmate | Scheduled expenses | Geplante Ausgaben | Gastos programados | Dépenses programmées | 予定の支出 | 计划支出 |
| `Entrate programmate` | `entrate_programmate` | Entrate programmate | Scheduled income | Geplante Einnahmen | Ingresos programados | Revenus programmés | 予定の収入 | 计划收入 |

(«Uscite programmate»/«Entrate programmate» si usano in S-72c: aggiungerle qui insieme.) Riusa «Uscite», «Entrate», «Spese fisse»,
«Entrate fisse». La chiave «Mese successivo» **resta**: è usata anche dal selettore del mese.

### Test
- Nuovi: iOS `MoneyTrackerTests/MovementSectionTotalsTests.swift`, Android `.../ui/MovementSectionTotalsTest.kt`. Casi:
  Tutti esclude i trasferimenti e include pianificati e virtuali; Fisse; Uscite; Entrate; Trasferito con due gambe = una volta,
  gamba orfana contata; filtro categoria/importo riflesso (si passano le righe già filtrate); lista vuota = zero;
  precisione decimale (`0.10 + 0.20 == 0.30` esatto, importi con centesimi su 100 righe).
- **Da eliminare (test della funzione S-70f rimossa per decisione di Matteo):** `MoneyTrackerTests/NextMonthSummaryTests.swift`,
  `03_CODICE/bucktrail-android/app/src/test/java/com/bucktrail/android/ui/NextMonthSummaryTest.kt`. Vedi domanda **D4**.

### Fatto quando
- In ogni sezione e in qualsiasi mese i riquadri compaiono in fondo con i nomi della tabella; la somma a mano delle righe visibili
  (demo, mese corrente e uno futuro, con un filtro categoria e con una ricerca) coincide con i riquadri.
- Nessuna traccia di «Mese successivo» in Movimenti (`grep nextMonthSummary` vuoto su iOS e Android).
- Oscura importi → «• • •». Test nuovi e suite verdi.

### Rischi
- Doppio conteggio dei trasferimenti in «Trasf.» (coperto dal test). Ricalcolo pesante a ogni render: una sola passata sulle righe.
- AX-XL: due riquadri affiancati illeggibili → colonna.

### Screenshot
Tutti, Fisse, Trasf. in un mese corrente e uno futuro (chiaro/scuro, de AX-XL, oscura importi).

---

## S-72d · Pagina «Abitudini» da Statistiche, criterio più severo

### Cosa cambia per l'utente
- La parte «movimenti che si ripetono» dell'attuale pagina Ricorrenti (ricerca, chip categorie, `RecurringSeriesCard`, tap →
  `RecurringSeriesDetailView` con lo storico) diventa la pagina **«Abitudini»**, aperta da un tasto in fondo a Statistiche
  (riga a tutta larghezza su `surface`, raggio 18, bordo `fog`, icona `arrow.triangle.2.circlepath`, testo «Abitudini», chevron; min 44 pt).
- Una serie è un'abitudine solo se: movimento effettuato, **non trasferimento, non «Rettifica saldo»**, **almeno 3 occorrenze in
  almeno 3 mesi diversi** (oggi 2 e 2).
- Le card «Serie programmate» (`ProgrammedRuleCard`) NON vanno in Abitudini: le serie programmate stanno nella sezione Ricorrenti (S-72c). Vedi **D2**.

### File da toccare
- Domain (autorizzato): `MoneyTracker/Domain/RecurringSeriesDetector.swift` — filtro candidati
  `isDone && !isTransfer && category != "Rettifica saldo"`, soglie `items.count >= 3` e `distinctMonths.count >= 3`; aggiornare i
  commenti. Costante privata per il nome categoria (lo stesso letterale usato da `AccountsView.applyBalanceAdjustment` e dal seed in
  `Category.swift`; non toccare quei file). Android `domain/RecurringSeriesDetector.kt` — stesso filtro con `Categories.ADJUSTMENT`, stesse soglie.
- iOS: nuovo `MoneyTracker/Views/HabitsView.swift` (contenuto spostato da `TransactionsView.subListContent`: ricerca, chip,
  card, cache del rilevamento `SeriesCache`/`detectedSeries`, foglio `RecurringSeriesDetailView`); `StatisticsView.swift` — tasto in
  fondo prima di `Spacer(minLength: 100)` e `.navigationDestination(isPresented:)` dentro la `NavigationStack` esistente; la pagina mostra
  la barra di navigazione con titolo «Abitudini». `TransactionsView` in questo task NON si tocca (la vecchia pagina sparisce in S-72c).
- Android: in `RecurrenceScreens.kt` nuovo `HabitsPage` (copia ridotta di `RecurringPage`: senza regole programmate, titolo
  «Abitudini», back `btn_backHabits`); `StatisticsScreen.kt` — tasto in fondo e stato `showHabits` con lo stesso schema
  `if (show) { Page(...); return }` usato oggi da Movimenti. `RecurringPage` resta finché S-72c non lo elimina.
- `RecurringSeriesDetailView` / `RecurringSeriesDetailSheet`: invariati (usano lo stesso rilevatore, quindi seguono il criterio nuovo).

### Localizzazione (nuove)
| iOS | Android | it | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|---|---|
| `Abitudini` | `abitudini` | Abitudini | Habits | Gewohnheiten | Hábitos | Habitudes | 習慣 | 习惯 |
| `Nessuna abitudine` | `nessuna_abitudine` | Nessuna abitudine | No habits yet | Noch keine Gewohnheiten | Sin hábitos | Aucune habitude | 習慣はまだありません | 暂无习惯 |
| `I movimenti che si ripetono almeno 3 volte in 3 mesi diversi appariranno qui.` | `abitudini_vuoto` | (uguale) | Transactions repeated at least 3 times in 3 different months will appear here. | Buchungen, die sich mindestens 3-mal in 3 verschiedenen Monaten wiederholen, erscheinen hier. | Los movimientos que se repiten al menos 3 veces en 3 meses distintos aparecerán aquí. | Les opérations répétées au moins 3 fois sur 3 mois différents apparaîtront ici. | 3か月以上にわたり3回以上繰り返された取引がここに表示されます。 | 在 3 个不同月份中重复至少 3 次的交易将显示在这里。 |

Le traduzioni sono proposte dell'architetto: l'impresa le verifica con il redattore se ha dubbi. Le chiavi vecchie «Nessuna serie
ricorrente» e «I pagamenti che si ripetono per almeno 2 mesi…» si rimuovono in S-72c, quando la vecchia pagina sparisce.

### Test
- Nuovi: iOS `MoneyTrackerTests/RecurringSeriesDetectorTests.swift`, Android `.../domain/RecurringSeriesDetectorTest.kt`
  (oggi non esistono test del rilevatore). Casi: 3 volte in 3 mesi → serie; 3 volte in 2 mesi → no; 2 volte in 2 mesi → no;
  trasferimenti esclusi; «Rettifica saldo» esclusa anche se 5 volte in 5 mesi; non effettuati esclusi; frequenza e totale invariati
  per una serie valida (totale in Decimal esatto).
- UI iOS facoltativo nuovo `MoneyTrackerUITests/HabitsUITests.swift`: Statistiche → `btn_openHabits` → titolo «Abitudini» visibile (demo).

### Fatto quando
- In Statistiche, in fondo, il tasto «Abitudini» apre la pagina con lo storico; tap su una card apre il dettaglio come oggi.
- In demo una serie con 2 sole occorrenze non compare più; trasferimenti e rettifiche mai.
- Test nuovi verdi; suite esistenti verdi.

### Rischi
- Nessun test esistente verifica la soglia 2 (verificato con grep): se un test o un UI test della demo si basava su una serie con
  2 occorrenze, scriverlo in CONSEGNA senza modificarlo.
- Dati demo: controllare che resti almeno un'abitudine visibile per gli screenshot (non modificare i dati demo senza dirlo).

### Screenshot
Fondo di Statistiche con il tasto; pagina Abitudini piena e vuota; dettaglio di un'abitudine (chiaro/scuro, de AX-XL).

---

## S-72c · «Ricorrenti» come sezione inline di Movimenti

> **Bloccato da D1 (e D2)**: non partire prima delle risposte di Matteo. Il resto è pronto.

### Cosa cambia per l'utente
- Il chip «Ricorrenti» seleziona una sezione come gli altri (resta l'ultimo chip, si evidenzia). Niente pagina separata, niente
  ricerca e chip categorie propri: valgono quelli in alto di Movimenti.
- La sezione mostra **solo le occorrenze delle serie programmate del mese scelto**: righe reali con `templateId` di una regola
  esistente (materializzate) + occorrenze virtuali (mesi futuri). Nessuna serie rilevata, nessuno storico. Cosa si intende per
  «passato» → **D1**.
- In Ricorrenti la ricerca filtra **dentro il mese scelto** (non apre tutto lo storico come nelle altre sezioni): segue la regola
  «solo il mese, niente passato».
- Layout come S-72b (gruppo «In arrivo» nei mesi futuri, giorni nel mese corrente); totali S-72a «Uscite programmate · Entrate programmate».
- **Tap su qualsiasi riga → gestione della serie** (`RecurrenceEditorView` / `RecurrenceEditorSheet`): reale con
  `RecurrenceSelection.resolve(t, rules:)` (Android: `actions.onRecurrence(t)`), virtuale con `RecurrenceSelection(rule:occurrence:)`
  (Android: `onSelectRule`). Swipe e menu contestuale delle righe reali restano quelli di oggi: l'eliminazione apre l'editor senza
  togliere la riga in anticipo (S-42), quindi modifica, elimina e annulla eliminazione non si perdono.

### File da toccare
- iOS: `TransactionsView.swift` — `filtered(for: .ricorrenti)` restituisce le righe con `templateId` in `ruleIDs` del mese scelto
  (mese sempre applicato, anche con ricerca); le virtuali passano il filtro anche per `.ricorrenti`; tap specifico per la sezione;
  rimuovere `navPath` e `NavigationStack(path:)` se non resta altro uso, `navigationDestination`, `subListContent`,
  `recurringSeries`, `SeriesCache`/`detectedSeries`, `sectionSearch`, `recurringCategory`, `selectedSeries` e il suo foglio (ora in
  `HabitsView`). `TransactionsTypeChips.swift` — il chip «Ricorrenti» imposta `selectedType` come gli altri; via il binding `navPath`.
  Conservare la logica di `isSearchActive` (senza `navPath`). Eliminare `ProgrammedRuleCard.swift` se dopo S-72b/S-72d non ha più usi (dipende da **D2**).
- Android: `MovementsScreen.kt` — aggiungere `Recurring` a `TransactionFiltering.TypeFilter`? **No**: `TransactionFiltering` è in
  `domain/` e ha test propri. Tenere un filtro di sezione locale alla schermata (`enum class MovementSection { All, Fixed, Transfer, Expense, Income, Recurring }`)
  che per `Recurring` filtra `templateId.lowercase() in ruleIds` sulle righe del mese, e per gli altri delega a `TransactionFiltering` com'è.
  Via `showRecurring`/`RecurringPage`; rimuovere `RecurringPage` e `ProgrammedRuleCard` da `RecurrenceScreens.kt` se non più usati.
- Chiavi da rimuovere se senza altri usi: «Nessuna serie ricorrente», «I pagamenti che si ripetono per almeno 2 mesi appariranno qui.»,
  «Serie programmate», «Prossima occorrenza», «Termina il», «Terminata», «Attiva» (attenzione: alcune sono probabilmente usate
  dall'editor delle ricorrenze o dalla Home → grep prima).

### Localizzazione (nuove)
| iOS | Android | it | en | de | es | fr | ja | zh-Hans |
|---|---|---|---|---|---|---|---|---|
| `Nessuna serie programmata in questo mese.` | `nessuna_serie_programmata_mese` | (uguale) | No scheduled series this month. | Keine geplanten Serien in diesem Monat. | No hay series programadas este mes. | Aucune série programmée ce mois-ci. | 今月の予定シリーズはありません。 | 本月没有计划的系列。 |

(stato vuoto della sezione, titolo «Nessun movimento» esistente + questo sottotitolo).

### Test
- Nuovo iOS `MoneyTrackerTests/RecurringSectionFilterTests.swift` e Android `.../ui/MovementSectionTest.kt` (funzione pura
  di filtro della sezione): solo righe con regola esistente; regola eliminata → riga esclusa; mese diverso escluso anche con ricerca;
  virtuali incluse nei mesi futuri; categoria e importo applicati.
- **Test UI esistenti da adattare (navigazione verso la pagina rimossa per decisione di Matteo) → D4:**
  `MoneyTrackerUITests/DemoShowcaseUITests.swift` (righe ~22-27), `MoneyTrackerUITests/RecurrenceAppearanceUITests.swift` (~14-15),
  `MoneyTrackerUITests/RecurrenceCancelAndHomeUITests.swift` (~7-9). Si cambiano SOLO i passi per arrivare alla serie
  (`tf_sectionSearch` → `tf_searchTransactions`, `app.buttons["editRecurrence_…"]` → `.firstMatch`), le asserzioni restano identiche.
  Per questo le righe della sezione Ricorrenti espongono `accessibilityIdentifier("editRecurrence_<nome>")` e il tratto `.isButton`
  (Android `testTag` uguale). `openTransactionsSection("Ricorrenti")` in `UITestSupport.swift` funziona ancora (tocca il chip).
  Se Bolletta Enel della demo non ha occorrenze nel mese corrente, dirlo in CONSEGNA invece di cambiare i dati demo.

### Fatto quando
- Il chip Ricorrenti non apre più una pagina; mostra solo le occorrenze programmate del mese (secondo D1), con i due totali in fondo.
- Tap su una riga apre l'editor della serie; modifica di una occorrenza, «Salta mese», «Termina…», elimina e annulla funzionano come
  prima (prova a mano in demo + i 3 UI test sopra verdi).
- `grep -n "subListContent\|tf_sectionSearch\|RecurringPage" ` vuoto nel codice app.

### Rischi
- Le serie terminate, annuali fuori mese o senza occorrenze future non sono più raggiungibili dalla sezione (solo dal menu
  contestuale «Ricorrenza» su una loro occorrenza reale) → **D2**.
- Rimozione di `navPath`: controllare che la tastiera e `isSearchActive` (nascondono la tab bar) si comportino come prima.

### Screenshot
Ricorrenti nel mese corrente e in uno futuro, stato vuoto, editor aperto da una riga (chiaro/scuro, de AX-XL, oscura importi).

---

## S-72e · Statistiche: togliere confronto mese scorso, media 12 mesi, anno vs anno

### Cosa cambia per l'utente
Spariscono «↑/↓ … rispetto al mese scorso», il blocco «Media mensile — ultimi 12 mesi» (Uscite medie / Entrate medie) e
«Anno 2026 vs 2025». Resta tutto il resto (riepilogo, categorie, andamento, PDF). Il tasto Abitudini (S-72d) resta in fondo.

### File da toccare
- iOS `StatisticsView.swift`: togliere il blocco «rispetto al mese scorso», i blocchi media e anno, `last12Stats`,
  `avgMonthlyExpenses`, `avgMonthlyIncome`, `yearTotals`, `currentYear` (se senza altri usi), `yearCompareRow`, il `ThinDivider`
  che li separava e le variabili `l12/avgExp/avgInc/curYear/prevYear` nel `body`.
  **`prevMonthSpent` RESTA**: lo usa `generatePDF()` per il PDF (Export/, intoccabile).
- Android `StatisticsScreen.kt`: togliere i blocchi equivalenti, `AverageTile`, `YearRow`, le variabili `avgExp/avgInc/prevSpent/curYear/prevYear`
  e gli import inutili. **`Statistics.kt` (domain) NON si tocca:** `prevMonthSpent` e `deltaPercent` li usa il PDF;
  `averageExpenses/averageIncome/yearTotals` restano, perché sono coperti da `StatisticsTest.kt` e il confronto annuale potrebbe tornare
  (decisione dell'architetto, registrata in DECISIONI; zero test esistenti modificati).
- Chiavi da rimuovere solo se senza altri usi (grep, compreso Export/PDF): «rispetto al mese scorso»/`rispetto_al_mese_scorso`,
  «Media mensile — ultimi 12 mesi»/`media_mensile_ultimi_12_mesi`, «Uscite medie», «Entrate medie», «Anno %lld vs %lld»/`anno_lld_vs_lld`,
  «Dati insufficienti.»/`dati_insufficienti`. `rispetto_al_mese_precedente` probabilmente è del PDF: lasciarla.

### Test
Nessun test nuovo obbligatorio (rimozione di vista). Verificare che nessun UI test cerchi i testi rimossi; se succede, scriverlo in
CONSEGNA senza modificarlo. Nessun test esistente da cambiare.

### Fatto quando
I tre blocchi non compaiono più su iOS e Android; il PDF continua a mostrare il confronto col mese precedente come prima
(generare un PDF in demo e controllarlo); build, lint e test verdi; nessun warning nuovo di codice inutilizzato.

### Screenshot
Statistiche intera (scroll fino al tasto Abitudini), chiaro/scuro, de AX-XL.

---

## Domande per Matteo (non decise dall'architetto)

- **D1 (blocca S-72c) · Cosa vuol dire «niente passato» nella sezione Ricorrenti?**
  (a) nel mese scelto tutte le occorrenze delle serie, anche quelle già confermate; nei mesi passati si vedono quelle di quel mese;
  (b) solo le occorrenze non ancora confermate (da fare), in qualsiasi mese;
  (c) solo dal giorno di oggi in avanti: mesi passati sempre vuoti, nel mese corrente solo da oggi.
  Proposta dell'architetto: (a), è la più semplice e coerente con le altre sezioni.
- **D2 (blocca S-72c) · Serie senza occorrenze nel mese** (annuali, terminate, tutte saltate): con la sezione inline non avranno più
  una card propria; si gestiscono tenendo premuta una loro occorrenza → «Ricorrenza». Va bene così, oppure in Abitudini mettiamo in
  cima anche le card «Serie programmate» di oggi? Proposta: va bene così (meno doppioni).
- **D3 (S-72b, non blocca: si parte con la proposta) · Movimenti pianificati a mano** (non da serie) nel mese corrente: anche loro
  escono dal gruppo in cima e vanno al loro giorno? Proposta: sì, una regola sola (gruppo in cima solo nei mesi futuri, per tutti i pianificati).
- **D4 (S-72a e S-72c) · Ok a toccare test esistenti:** eliminare `NextMonthSummaryTests.swift` e `NextMonthSummaryTest.kt` (testano S-70f,
  che togli tu) e cambiare solo i passi di navigazione dei 3 UI test elencati in S-72c (asserzioni identiche).
