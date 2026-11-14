# CONSEGNA — collaudo S-23

**Da:** collaudatore, 2026-11-14 12:55. S-23 [x] collaudo ok (solo lettura diff e log, nessun test rilanciato). Manuale a Matteo in PER-MATTEO.md. Restano S-18/S-19, poi Commissione S-13h; checkpoint/push bloccato.

---

**Da:** impresa (Codex · GPT-6), 2026-11-14 12:45. Ramo `redesign-sentiero`.

## Fatto
- Tap su una copia di serie in Movimenti → AddTransactionView normale. Rimosso il reindirizzamento sia in TransactionsView sia in AddTransactionView. Pressione prolungata → Ricorrenza/Elimina conservata.
- Editor normale: selettore ricorrenza già nascosto quando editing != nil; salvataggio non assegna più recurringFrequency. Nessuna conversione di un movimento normale in serie.
- Piccolo SF repeat accanto al titolo, nelle due disposizioni Dynamic Type di MovementRow; attivato solo in Movimenti per copie appartenenti a una regola presente. DS.smoke e DS.Typo.caption, etichetta accessibile localizzata Ricorrenza.
- Incluse le modifiche preesistenti richieste: Text(verbatim: String(localized: ...)) in ProgrammedRuleCard e Label Ricorrenza/repeat nel menu.

## Eccezioni e categorie
- Letti Domain/RecurringSeriesEditor.swift, RecurringMaterializer.swift e codec tramite snapshot. Le eccezioni onlyThis della regola gestiscono importo/data/nome/note; la categoria della singola copia si salva direttamente in Transaction. Il materializer lascia intatte le copie esistenti, anche spostate/modificate. Non serve cambiare Domain: nessun file Domain/Models/Persistence/Sync/Auth modificato.
- Nuovo unit categoryEditsOnCopyAndAllSeries: categoria/icona Casa sulla copia persistite; materializzazione del mese successivo non cambia la copia né categoria/eccezioni della regola; altre copie conservano categoria della regola. Poi Tutte aggiorna categoria/icona della regola e copie pianificate del mese; copia effettuata conserva Casa.
- UI: crea serie mensile, tap normale, selettore assente, categoria Casa salvata e riletta; menu lungo Ricorrenza con Elimina; categoria della regola ancora diversa da Casa; Tutte salva Salute e la rilegge riaprendo l'editor. Test aggiuntivo su movimento non ricorrente: modifica normale senza selettore/scope. Controllo etichetta accessibile repeat.
- Nessuna correzione alla logica categoria: non dimostrato alcun bug. Primo tentativo UI fallito per tap XCUITest su Trasporti fuori area (hit point {-1,-1}); video esportato in /tmp/moneytracker-s23-attachments dimostra selezione involontaria Salute. Test corretto scegliendo esplicitamente Salute visibile, con verifica immediata prima di salvare e dopo riapertura.

## Verifiche
- **Finale verde:** build + 70 unit + 2/2 RecurrenceFlowUITests, TEST SUCCEEDED, `/tmp/moneytracker-s23-final.log`; risultato `Test-MoneyTracker-2026.11.14_12-42-20-+0100.xcresult` nella cartella Xcode Logs/Test. Test serie 108,832 s; movimento non ricorrente 24,708 s.
- **Suite completa eseguita:** `/tmp/moneytracker-s23-full.log`, 70 unit verdi, 10/14 UI verdi prima delle correzioni ai nuovi test. Due fallimenti sono quelli preesistenti S-15: NavigationStressUITests:55 e TransactionFlowUITests:68. Gli altri due erano nei nuovi test S-23 e sono risolti nella verifica mirata finale. Nessun test S-15 modificato; non si dichiara l'intera suite verde.
- Automazione finale: menu categoria selezionato in `collectionViews` per escludere elementi omonimi sottostanti; categoria portata sopra la tastiera, verifica Salute prima del salvataggio e dopo riapertura. Il caso non ricorrente usa Supermercato del seed demo: evita di dipendere dalla creazione già oggetto di S-15. Gli ulteriori tentativi hanno mostrato menu omonimi e pulsante Salva fuori vista, senza dimostrare un difetto di salvataggio categoria.
- Prima esecuzione mirata: 70 unit verdi, UI fermato dall'errore di automazione descritto sopra. Log intermedi in /tmp/moneytracker-s23-first.log, -second.log, -third.log; quello finale è il riferimento autorevole.
- git diff --check pulito. Grafo aggiornato AST; graphify-out preesistente modificato e lasciato interamente fuori dal commit.

## Prossimo
S-23 [~] resta da collaudare indipendentemente. Non effettuati push, merge o checkpoint. Restano S-18/S-19 prima della Commissione S-13h; controllo manuale S-21 ancora a Matteo come da PER-MATTEO.md.
