# CONSEGNA — S-24 / S-25: diagnosi, attesa autorizzazione Domain

**Da:** impresa (Codex · GPT-6), 2026-11-15 11:08. Ramo `redesign-sentiero`. Task creati in PIANO, entrambi [!]. Nessuna modifica al codice dell'app, nessun push/merge/checkpoint. Il turno è iniziato il 14 novembre ed è proseguito dopo la sospensione per autorizzazione al campionamento.

## S-24 — cosa è riprodotto
- Nuovo UI `testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes`: crea mensile spesa fissa pianificata in Movimenti, pressione prolungata → Elimina → Tutte → conferma. La riga scompare e i tocchi Home/Movimenti funzionano. Poi menu Ricorrenza → Solo questa: passa. Terzo giro Elimina → Questa e le successive: la riga rimane, test rosso.
- **Il blocco segnalato con Tutte non è stato riprodotto.** Non identificati crash, deadlock o loop in quel caso, nessuna correzione ipotetica applicata. I dati dei test sono demo in memoria, non il database reale di Matteo: non escludono un problema specifico dei suoi dati o del debugger.
- **Difetto distinto dimostrato:** `RecurringSeriesEditor.swift` normalizza originalDate a mezzogiorno (inizio apply); delete following usa `remove { $0.date >= original }`. Una copia reale dello stesso giorno alle 08:00 è precedente e rimane. UI fallisce proprio su successive; nuovo unit `deleteFollowingIncludesSelectedCopyBeforeNoon` imposta le 08:00 e fallisce su `copies(context).isEmpty`, riga 68. Copia a mezzogiorno: i tre scope passano.
- Correzione necessaria: confronto per giorno civile/originale, senza escludere la copia selezionata del mattino; da valutare anche copie spostate e terminate/following per evitare altri effetti. È una modifica di Domain, non una pura aggiunta: **mi sono fermato come chiesto da Matteo**. Nessuna normalizzazione artificiale dei dati nella UI.
- `deleteMonthlyFixedSeriesAllScopes` verifica copie di gennaio–aprile, transazione estranea conservata, rimozione regola con Tutte e mancata ricreazione dopo nuova materializzazione. Verde.

## Breakpoint e trap
- Ricerca comprendente file nascosti/ignorati nel progetto: nessun file Breakpoints/LLDB trovato, incluso xcuserdata locale (contiene solo xcschemes). Non modificata la configurazione personale del debugger.
- In tutti i .swift dell'app: `fatalError` solo nel fallback di creazione ModelContainer (`MoneyTrackerApp.swift:89`); `assertionFailure` in `Persistence/ModelContextSaving.swift:21` in caso di safeSave fallito; nessun precondition trovato. Nessun log prova che questi trap siano stati colpiti durante l'eliminazione testata.
- Campionamento richiesto del processo app: non eseguito perché, all'arrivo dell'autorizzazione, il PID non era più attivo. Non c'è una stack trace da attribuire al blocco originale.

## S-25 — impossibile con Domain invariato
- `RecurringSeriesEditor` è esplicitamente incompatibile con la nuova regola: reconcile aggiorna solo il mese di now; salta isDone; all conserva le eccezioni se frequenza/ancora non cambiano. Anche un precedente override nome/importo/note può quindi prevalere sui valori di Tutte.
- onlyThis serializza soltanto importo/data/nome/note: `RecurrenceException` non ha categoria/icona, conto, tipo, fissa. Non basta mostrare i controlli nella UI per propagare questi campi ai virtuali futuri.
- Per ottenere passato e futuro uniformi, incluse copie effettuate e precedenti override, bisogna cambiare l'editor e il codec/calcolatore in Domain. Aggiungere un servizio parallelo nelle viste aggirerebbe il vincolo e duplicherebbe il motore: non fatto.
- **Nessuna semantica nuova parzialmente applicata.** Rimane il comportamento corrente S-23 (editor normale modifica copia; Tutte conserva effettuate ed eccezioni come sopra). I test S-23 non sono stati ribaltati senza la relativa implementazione. Alla ripresa autorizzata, Tutte dovrà rendere uniformi i campi anche dopo un precedente onlyThis; definire insieme nel motore come conservare salti e date spostate senza riattivare cancellazioni.

## Prove e limiti
- `/tmp/moneytracker-s24-baseline.log`: 70 unit verdi; 2 UI esistenti verdi, nuovo UI fallito inizialmente perché il test marcava erroneamente la voce effettuata (corretto: Fissa imposta già isDone=false).
- `/tmp/moneytracker-s24-repro.log`: **71 unit verdi**, incluso nuovo test serie e scope a mezzogiorno; UI nuovo rosso su successive, UI esistente timeout snapshot su elenco Ricorrenti, non ricorrente verde.
- `/tmp/moneytracker-s24-isolated.log`: UI isolato, Tutte e Solo questa completati con scomparsa e navigazione; successive fallisce dopo attesa 5 secondi sulla riga ancora presente. XCResult `Test-MoneyTracker-2026.11.15_11-03-11-+0100.xcresult` (percorso esatto autorevole nel log).
- `/tmp/moneytracker-s24-boundary.log`: suite editor **15 verdi / 1 rosso** (nuovo reproducer mattino); nessuna asserzione indebolita. I test rossi sono mantenuti come prova del difetto, non disabilitati né marcati expected failure. **La suite finale NON è verde**, nessuna pretesa di completamento S-24/S-25.
- `git diff --check` pulito. Grafo aggiornato AST (`/tmp/moneytracker-s24-graph.log`); tutto graphify-out, già sporco prima del turno, escluso dal commit. Nessun altro file estraneo modificato.

## Prossimo
Matteo: autorizzare le modifiche Domain necessarie (testo completo in PER-MATTEO). Poi Codex riprende S-24/S-25, ottiene unit/UI verdi, quindi collaudatore indipendente. Per il blocco originale Tutte servono dettagli del caso reale (stato effettuata/pianificata, data iniziale della serie, dispositivo e avvio da Xcode o icona). Restano S-18/S-19 e Commissione S-13h prima di checkpoint/push; S-15 preesistente non affrontato.
