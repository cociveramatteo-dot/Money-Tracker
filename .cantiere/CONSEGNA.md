# CONSEGNA — S-12 pronto per il collaudo

**Da:** seconda impresa (Codex · GPT-6), 2026-11-14 01:14. Ramo `redesign-sentiero`.
Riprese e riviste le modifiche non committate di Antigravity; conservata l'implementazione corretta, senza ripartire da zero.

## Cosa è cambiato e confronto eseguito

Riferimenti: `02_RISORSE/originali/bucktrail-redesign/reference/Movimenti.dc.html` e `DESIGN_HANDOFF.md` §4. Il percorso senza `reference/` non esiste. Il pacchetto manca di `support.js`: renderizzata una copia in `/tmp/moneytracker-s12-reference.png`, espandendo staticamente solo i chip secondo lo script del mockup; originali intatti.

| Differenza trovata | Correzione e controllo |
|---|---|
| I tipi aprivano nuove pagine | Tutti/Fisse/Trasf./Uscite/Entrate aggiornano la lista inline. Test temporaneo sulle coordinate di ricerca e mese per tutti i tipi: nessuno spostamento; impostazioni sempre presenti. Solo Ricorrenti fa push. |
| Mese e categorie occupavano due righe | Un'unica riga scorrevole: menu mese, menu categoria e chip dei filtri attivi con rimozione. Altezza base 32, raggio 10, gap 6, margine 16, bordo tratteggiato adattivo con light `#B9BFB6`, sfondo trasparente. |
| Chip tipo a capsula, grandi | Base 34, raggio 12, font secondario 13, gap 6, come nel markup. Altezza adattiva alle taglie di accessibilità. |
| Placeholder troppo chiaro; righe dense di dettagli | Placeholder `DS.smoke`; pianificati con Fissa/categoria + data, completati con categoria + conto. Righe compatte, card raggio esplicito 18, separatori interni e margini riallineati; rimossi i separatori esterni delle sezioni. |
| Swipe dei pianificati grigio | Azione nativa verde «Conferma», fotografata; stessa funzione di conferma preesistente. |
| Demo sopra il titolo | Altezza riservata nel layout e banner visibile in overlay sopra le barre native: niente sovrapposizioni. Verificate presenza e posizione con asserzioni nelle catture, anche su Ricorrenti dark/XL. Colori DS adattivi. |
| Totale pianificati spezzato a XL; MonthBar non scalava | Importo su una sola riga; intestazione può occupare due righe senza ellissi. MonthBar con font scalabile e label non tagliata. |
| Righe schiacciate a XL | Nome, dettagli e importo disposti verticalmente alle taglie di accessibilità, senza troncare il nome. |
| Ricorrenti poco coerente e filtri condivisi | Card surface raggio 18 e icone categoria; frequenza separata a XL, scroll inferiore libero, storico con MovementRow. Ricerca/categoria locali; il ritorno conserva il filtro di Movimenti. La ricerca principale non nasconde più il FAB di Ricorrenti. |
| Testi nuovi non tradotti | Aggiunte le stringhe nelle sette lingue, inclusi placeholder, Fissa, risultati vuoti e rimozione filtri. |

La ricerca principale continua a trovare nomi anche fuori dal mese corrente. Nessun calcolo modificato; nessun file di Domain/, Models/Persistence, Sync/, Auth/, Intents/, Export/, Formatting/, notifiche o ricorrenze modificato.

## Screenshot reali finali, confrontati a vista

Simulatore richiesto `37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`, 402×874 pt. XL = `UICTContentSizeCategoryAccessibilityXL`.

| Variante | Movimenti | Ricorrenti |
|---|---|---|
| Light | [screenshot](tmp/final_movimenti_light.png) | [screenshot](tmp/final_ricorrenti_light.png) |
| Dark | [screenshot](tmp/final_movimenti_dark.png) | [screenshot](tmp/final_ricorrenti_dark.png) |
| Accessibility extra large | [screenshot](tmp/final_movimenti_xl.png) | [screenshot](tmp/final_ricorrenti_xl.png) |
| Tedesco | [screenshot](tmp/final_movimenti_de.png) | [screenshot](tmp/final_ricorrenti_de.png) |

Controlli aggiuntivi: [filtri attivi](tmp/final_movimenti_active_filters.png), [swipe Conferma](tmp/final_movimenti_swipe.png), [storico serie](tmp/final_ricorrenti_detail.png), [MonthBar XL](tmp/final_monthbar_xl.png). Le cinque catture `tmp/inline_{Fisse,Trasf.,Uscite,Entrate,Tutti}.png` documentano i tipi nella stessa pagina.
Screenshot locali ignorati da Git; presenti anche come allegati nei risultati Xcode. Nessun file pesante nel commit.

## Tutte le differenze residue dal mockup

1. **Contenuti e dispositivo:** il mockup illustrativo è 390×844; il simulatore 402×874, con safe area di sistema. Nomi, importi, date, numero/ordine delle righe, badge dei filtri e presenza di Oggi/Ieri dipendono dai dati reali demo: non sono stati sostituiti con numeri finti del mockup. Il filtro mese esistente resta invariato.
2. **Controlli richiesti:** restano impostazioni, chip Ricorrenti e abbreviazione Trasf.; il mockup non li disegna. Il banner demo occupa una riga aggiuntiva sopra il titolo. Sono funzioni da mantenere, non controlli eliminati per copiare il disegno.
3. **Icone e sistema iOS:** conservati i simboli di categoria scelti nell'app invece delle iniziali illustrative. Swipe verde nativo: iOS disegna una pillola con icona/testo affiancati anziché il rettangolo HTML con icona sopra. Menu, back e sheet mantengono la presentazione nativa. Nessuna gesture esistente sostituita.
4. **Varianti:** dark usa i token adattivi; tedesco usa i testi/locali tradotti. A XL chip più alti/scorrevoli, intestazioni su più righe e righe verticali sostituiscono il layout compatto normale. Il totale dei pianificati resta su una riga e la MonthBar è intera.
5. **Difetto ancora aperto, già in S-10:** etichette della tab bar troncate a XL e spazio riservato fisso. Visibile negli screenshot, NON dichiarato risolto con S-12. È la riserva S-11 punto 4 già assegnata al collaudo finale.
6. **Ricorrenti:** non esiste un mockup dedicato. Confrontata la coerenza di token, card, ricerca e storico con Movimenti; resta una pagina autonoma con riepiloghi di serie. Il rilevamento all-time e i limiti del motore, comprese le occorrenze virtuali future, restano S-13. Nessun intervento al motore.

## Verifiche

- Build + **27 unit verdi e 12 UI esistenti verdi**, più 4 test temporanei di cattura, zero errori. Giro completo concluso 2026-11-14 01:01:59. Log: `/tmp/moneytracker-s12-build.log`; risultato: `~/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.14_00-49-09-+0100.xcresult`.
- Dopo gli ultimi soli ritocchi a banner, separatori e raggio card Ricorrenti: nuova compilazione e **4 catture UI verdi**, incluse asserzioni presenza/non sovrapposizione del banner, coordinate dei filtri inline, apertura/chiusura storico e swipe Conferma. Log `/tmp/moneytracker-s12-capture-final.log`; risultato `Test-MoneyTracker-2026.11.14_01-02-44-+0100.xcresult` nella stessa cartella Xcode.
- Il controllo a vista ha scartato una cattura Movimenti dark durante la transizione del tema: ricattura con avvio diretto dark riuscita, test aggiuntivo verde e due screenshot ricontrollati a vista (`/tmp/moneytracker-s12-dark-final.log`, risultato `Test-MoneyTracker-2026.11.14_01-07-17-+0100.xcresult`).
- Prima esecuzione sandbox bloccata da cache/simulatore: ripetuta con autorizzazione, nessun test aggirato. Non è stato necessario spegnere tutti i simulatori.
- Nessuna asserzione dei 12 UI esistenti rimossa. Solo helper `openTransactionsSection` aggiornato per lo scroll reale dei chip.

## Passaggio al collaudatore

S-12 va a [~], mai [x] da parte dell'impresa. Prossimo: collaudatore su Claude Code (Sonnet), solo diff del commit S-12 + questo rapporto e screenshot. Verificare le differenze residue dichiarate, poi decidere l'esito; S-13 resta separato.

`CaptureComparisonUITests.swift` rimosso prima del commit; nessun nuovo test temporaneo lasciato nel target. Grafo aggiornato senza LLM: il rebuild AST automatico sostituiva la parte curata; eseguito quindi il merge incrementale previsto dalla skill sui soli 6 Swift modificati, conservando tutti i 286 nodi documentali precedenti e le etichette. Esito: 1624 nodi, 2983 archi, nessun arco pendente. Avviso del tool: 9 JSON di configurazione/asset non producono nodi AST; nessun errore Swift. Backup automatico del grafo precedente conservato in `/tmp/moneytracker-s12-graphify-backup-2026-11-14`, escluso dal commit. Nessun file estraneo rilevato. Nessun push, merge o pubblicazione eseguito.
