# Test grafico di parità Android ↔ iOS (B11 + collaudo visivo)

Eseguito il 2026-11-23. iOS: simulatore iPhone 18 Pro, ramo `redesign-sentiero`, app con `--uitesting` (demo) tramite un test UI temporaneo (poi cancellato, nessuna modifica a `MoneyTracker/`). Android: emulatore `Bucktrail_API_36`, lingua italiana, modalità demo, dati ricreati prima di ogni scenario. Coppie di screenshot in `99_DA_SMISTARE/parita/` (fuori da git): `ios-light/`, `ios-dark/`, `and-light/`, `and-dark/`, `android-extra/` (font grandi, schermo piccolo, tablet, orizzontale, lingue). Gli stessi dati demo danno gli stessi numeri (saldo 21.973,16 €, atteso 21.511,76 €, Uscite 1.661,98 €, budget 74%, obiettivi 47%).

## Esito per schermata

| Schermata / foglio / stato | Esito | Correzioni fatte su Android |
|---|---|---|
| Home (hero, curva, conti, fissi, ultimi movimenti, nascondi importi, menu FAB, menu riga) | identica | data in maiuscolo («Lunedì…»), riga movimento «categoria · conto · data», niente icona ricorrenza in Home, divisori `fog` inset, menu a pressione lunga Modifica/Elimina |
| Ordine conti in Home | allineata (foglio, spunte, maniglie) | pulsanti della barra a capsula |
| Impostazioni (lingua, valuta, notifiche, sicurezza, cronologia, Home, export, demo) | identica salvo extra Android | titolo grande + «Chiudi» a capsula, interruttori `ink` (demo ambra), valuta «€ euro ⌃», icona ingranaggio su «Apri impostazioni» |
| Aggiungi movimento (vuoto, tipo, importo, categoria, conto, opzioni, ricorrenza, data, note) | identica | «Annulla» a capsula in alto (niente titolo né Annulla in basso), Uscita/Entrata a metà larghezza, chevron › sulla categoria, «Già effettuato» solo per le voci fisse, data in capsula `fog`, chip conto 13 pt, segnaposto più scuri, linee sotto le righe opzione |
| Trasferimento | identica | riepilogo «Da → A» centrato e in semibold, nota senza etichetta (segnaposto «Note (opzionale)») |
| Nuovo budget / Nuovo obiettivo / Nuovo conto (+ modifica) | identiche | «Annulla» a capsula, righe tipo conto con divisori, testo «Saldo attuale» sopra l'importo, tipo selezionato in semibold, chip categoria più bassi |
| Gestione categorie, selettore categoria, nuova categoria | identiche | indietro e «+» circolari, titolo grande |
| Movimenti (lista, ricerca, chip tipo, mese/categoria, filtri, vuoto) | identica | «Ricorrenti» ultimo chip, ingranaggio senza riquadro, totali di giorno in `smoke`, riga «categoria · conto» (fatti) o «Fissa/categoria · data» (pianificati), freccia ▾ come iOS, filtri avanzati a mezza altezza con maniglia |
| Righe: menu a pressione lunga, swipe elimina / conferma | identiche | menu ridotto a Ricorrenza/Elimina (le azioni dello swipe restano per TalkBack come azioni personalizzate) |
| Ricorrenti + editor ricorrenza | identica nel complesso | chip a capsula, freccia indietro circolare, «Serie programmate» centrato |
| Statistiche (6M, 12M, per categoria, medie, anno su anno) | identica | frecce mese a chevron ai lati |
| Pianifica: budget, hero, card, storico, obiettivi, anello, card, +progresso | identica | demo: nessun obiettivo marcato «raggiunto» (come iOS); icone `target`/`scope` disegnate come SF; icone `.fill` piene |
| Conti (hero, gruppi, righe, menu, archiviati) | identica | hero più compatto (padding 20/18), totale di gruppo in `smoke`, icone nel menu conto |
| Tema scuro (tutte le schermate sopra) | identico | interruttore spento con pollice bianco e traccia visibile |
| Importi 4 cifre | identici | `7662,00 €` senza punto come il formatter iOS (it, es, pt, pl) |

## Secondo giro (2026-11-23, sera): flussi che erano scoperti

Coppie iOS↔Android in `99_DA_SMISTARE/parita/ios2/` e `and2/` (fuori da git). iOS con un test UI temporaneo (poi cancellato), Android sull'emulatore con server finto per il login. Chiaro per tutte le coppie; scuro solo su Android (vedi limiti).

| Schermata / flusso | Esito | Correzioni fatte su Android |
|---|---|---|
| Alert «Elimina conto» (con numero movimenti) | identico nel contenuto («Eliminare "X"?», «Elimina (108 movimenti)», Annulla); layout Material (bottoni affiancati) ammesso | azione distruttiva ora in rosso `danger` (prima nera) in tutti gli alert distruttivi |
| Cronologia modifiche | vuota: stesso titolo, icona, testi; riga voce identica **per codice** (icona 20, 14/11 pt, «Azione · data»). Con voci reali non confrontata a schermo | — |
| Storico budget (foglio) | stessi mesi, righe, percentuali, rosso oltre il 100%; ordine delle righe nel mese casuale su iOS | titolo grande a sinistra come iOS (prima centrato in barra) |
| Flussi categorie (selettore, Gestione, Nuova categoria, vuoto) | struttura identica; iOS ha il foglio con maniglia, Android a pagina intera | riga: nome 15 medium, icona 15, chevron 11, etichetta «predefinita» in capsula `fog` 11 pt |
| Dettaglio serie rilevata (storico occorrenze) | scheda e testate identiche | le righe ora mostrano «categoria · conto · data» (prima senza data) |
| Stati vuoti reali (Home, Movimenti, Statistiche, Conti, Pianifica, Obiettivi) | testi e struttura identici; iOS Pianifica non è svuotabile dalla UI (budget senza conto e obiettivi restano), qui confrontato sul codice (`EmptyStateView`) | `EmptyState`: icona→testi 16 pt, titolo→sottotitolo 8 pt, CTA a 16 pt (prima 8 ovunque) |
| Login / Crea account | stessi campi, bottone disabilitato, testi, link; su iOS il logo/nome sono ancora «MoneyTracker» (Android: Bucktrail); la X di chiusura è un extra Android (l'accesso è facoltativo) | pulsante indietro di «Crea account» circolare con bordo `fog` come iOS |
| Errori login/registrazione | messaggi identici **per codice** (mappe `authError`/`signUpError`) e verificati su Android col server finto: «Email o password non corretti.» ecc. Su iOS gli errori del server non sono stati provocati: avrebbero toccato il Supabase reale | — |

Quirk iOS lasciati: nella Statistiche vuota la card «Per categoria» è larga solo quanto il testo (anomalia di layout iOS), su Android è a tutta larghezza.

Limiti di questo giro: il simulatore iOS non ha dato il tema scuro (le coppie «dark» iOS risultano chiare; `simctl ui appearance dark` non è stato rispettato tra i lanci del test), quindi il tema scuro dei flussi nuovi è verificato solo su Android; «Cronologia modifiche» con voci reali e «Crea account» con errore di password diverse su iOS non catturati (campo senza focus nel test).

## Differenze residue (decise o di piattaforma)

- Menu a tendina, selettore data, dialoghi e permessi usano i componenti Material (decisione di piattaforma); il menu mese/categoria mostra gli stessi voci ma senza icone.
- Ordine di conti, budget e obiettivi: su iOS è casuale (query SwiftData senza ordinamento, cambia a ogni avvio), su Android è deterministico (data di creazione).
- Barre di stato, tasti di sistema, notch/isola dinamica e glass del tab bar iOS 26: non replicabili.
- Icone: Material al posto di SF Symbols (stesso significato, tratto diverso; qualche glifo pieno/vuoto differisce, es. `chart.bar`, documento PDF).
- Extra Android voluti: sezione «Scorciatoie», widget, riquadro Impostazioni rapide, blocco con PIN, accesso facoltativo.
- Login/registrazione: confrontati nel secondo giro (vedi sopra); Android parte offline senza account.
- I chip a 34–36 dp (tipo movimento, categorie del budget) sono sotto i 48 dp raccomandati: tenuti uguali a iOS (32–34 pt) perché ingrandirli cambia il disegno; sono comunque distanziati di 8 dp.

## Compito B11

- Localizzazione: nessuna stringa fissa nelle schermate (grep + lint `HardcodedText` = 0; unico esempio nell'anteprima del widget con `tools:ignore`), 512 chiavi identiche nelle 7 lingue, segnaposto coerenti, `MissingQuantity` risolto (es/fr). Verificate a schermo italiano, tedesco, francese e giapponese (nessuna voce tagliata nelle tab, hero, budget).
- Font grandi (1,3× e 2,0×): tab bar con altezza fissa e testo limitato a 1,2×, card conto della Home più larghe con importo che si riduce, riga movimento in colonna oltre 1,6× (come `isAccessibilitySize` iOS), intestazioni di gruppo che vanno a capo senza coprire l'importo.
- Accessibilità: area toccabile 48 dp per pulsanti icona (disegnati 44 come iOS), frecce mese, cancella ricerca, spunte ordine conti; selettori icona con descrizione e stato; azioni TalkBack «Conferma/Pianificato/Elimina» sulle righe; titoli segnati come intestazione nei fogli.
- Schermi piccoli (320 dp), tablet (570 dp) e orizzontale: il contenuto è una colonna centrata di massimo 640 dp (anche nei fogli a pagina intera); rotazione verificata su Home e form (solo layout).
- Contrasti: stessi token di iOS (chiaro/scuro), controllati sugli screenshot a coppie.

Gate finale: `./gradlew assembleDebug assembleRelease lintDebug testDebugUnitTest` verde.
