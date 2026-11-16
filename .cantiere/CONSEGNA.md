# CONSEGNA — correzioni collaudo S-7/S-8

**Impresa (Codex · GPT-6), 2026-11-16 11:48.** Turno trovato libero e occupato alle 11:36; ramo `redesign-sentiero`. Nessun push/merge.

## Solo le due correzioni richieste
1. **S-8 AccountsView:** eliminata `.opacity(0.35)` sulla riga archiviata. AccountRow usa `DS.smoke` opaco per nome, importi, sottotitolo e simbolo quando `account.isArchived`; attivi invariati. Resta la sezione Archiviati, con icona neutra e testi secondari per distinguere lo stato. Nessuna mutazione o azione cambiata: archiviazione/menu/ripristino restano quelli precedenti. AddAccountView, totali, modelli, soglie, query e zone intoccabili invariati.
2. **S-7 PianificaView:** 76 pt di padding inferiore esterno allo ScrollView (`DS.Space.xxl + DS.Space.xl + DS.Space.l`), così la fascia occupata dal FAB resta fuori dall’area scorrevole anche all’inizio, sia Budget sia Obiettivi. Spacer interno esistente conservato; card, azioni, soglie, progressi e calcoli invariati.

## Contrasto degli archiviati
Calcolo di luminanza relativa sRGB sui token opachi di Theme, senza composizione alpha:

| Modo | Testo DS.smoke | Sfondo DS.paper | Contrasto testo |
|---|---|---|---|
| light | #5B635E | #F3F4EF | 5,60:1 |
| dark | #9AA39D | #0E1210 | 7,28:1 |

Minimo per le icone neutre sui quattro fondi CategoryTint: 5,14:1 light / 5,32:1 dark. Testi piccoli sopra 4,5:1; riga ancora distinta dagli attivi con nome/importi ink. Verifica visiva eseguita su light L, dark L e light XL; confronto prima/dopo del riquadro 3 di `.cantiere/tmp/s8/states.png` in `archived-before-after-xl.png`.

## Verifiche e screenshot
- **Build verde, 0 warning/0 errori** dal riepilogo Xcode.
- `/tmp/moneytracker-review-fixes-light.xcresult`: 82 unit logici + 2 nuovi UI (light e XL), tutti passati, 0 saltati. Riepilogo: 84 test logici, 88 esecuzioni inclusi parametri.
- `/tmp/moneytracker-review-fixes-dark.xcresult`: 1 UI dark reale passato, 0 saltati.
- Nuovo `SentieroReviewFixUITests.swift`: ogni variante verifica che il frame inferiore dello ScrollView sia sopra il FAB in Budget e Obiettivi, fotografa inizio/fondo delle due sezioni, archivia un conto demo, apre Archiviati, fotografa la riga, esegue Ripristina e verifica la scomparsa della sezione vuota. Nessun test esistente modificato.
- **15 acquisizioni ispezionate**, cinque per variante. Conti: testi/importi leggibili, niente tagli di layout; ripristino eseguito in tutti i modi. Pianifica: niente sovrapposizione FAB/scroll, ultima card leggibile al fondo; il normale ritaglio delle righe al bordo del viewport resta durante lo scroll.
- Tavole in `.cantiere/tmp/review-s7-s8/`: `archived-light-dark-xl.png`, `archived-before-after-xl.png`, `budget-light-xl.png`, `goals-light-xl.png`, `planning-dark.png`. Originali esportati in `/tmp/moneytracker-review-fixes-images-light` e `-dark`.
- Diff-check verde. Localizable.strings non modificati né inclusi; traduzioni in carico al redattore. Solo due viste e nuovo test UI oltre ai quattro registri di turno. Grafo aggiornato AST, escluso dal commit come le modifiche graphify-out già presenti all’ingresso.

Comando light/XL (dopo `xcrun simctl ui 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48 appearance light`):
```sh
xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -quiet -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/SentieroReviewFixUITests/testLight -only-testing:MoneyTrackerUITests/SentieroReviewFixUITests/testXL build test
```
Dark: stessa destinazione, appearance dark reale, `-only-testing:MoneyTrackerUITests/SentieroReviewFixUITests/testDark test`.

## Prossimo
S-6 [x] e S-7 [x] ereditati dal collaudatore 11:34, nessun nuovo [x] assegnato dall’impresa. S-8 portato da [!] a [~], come richiesto. Ricollaudo indipendente limitato agli archiviati espansi S-8 e al padding aggiuntivo S-7: leggere solo diff del commit corrente e queste evidenze. Traduzioni al redattore, senza interferenze di questo turno. Commissione S-13h preesistente resta aperta. Turno libero; nessun push/merge.
