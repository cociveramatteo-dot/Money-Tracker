# CONSEGNA — ripresa esatta dopo lo stop di Matteo

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 02:20
**STOP ESPLICITO:** Matteo vuole fermare adesso, scriverà «riprendiamo» a Claude Code, che lo rimanderà a Codex. **Non avviare S-13d: completare prima la verifica UI di S-13c.**

## S-13c implementato [~]
- Nuovo `MoneyTracker/Domain/RecurringMaterializer.swift`, `@MainActor`: accetta solo `container.mainContext` (guardia e test), calendario gregoriano e mezzogiorno, Decimal, ID del calculator; intero mese corrente come pianificato `isDone=false`, `templateId=rule.id`, frequenza della copia vuota.
- Watermark per regola: nil = nuova, mai storico prima del mese corrente; futuro in attesa. Watermark esistente = recupero fino al corrente, massimo 36 mesi più recenti. ID già esistente: non tocca la copia. Watermark già passato: non ricrea copie cancellate né sovrascrive modifiche/fatte.
- Fetch preparatori prima delle mutazioni, un solo `safeSave` per giro con cambiamenti. Nessun rollback globale del contesto in errore; ripristino delle sole mutazioni proprie se safeSave restituisce false (in debug il safeSave esistente fa assertion).
- Nuovo `MoneyTrackerTests/RecurringMaterializerTests.swift`: 11 test verdi su mese completo, idempotenza, copie eliminate/modificate/fatte, tre mesi mancanti, limite 36, regole nuove/passate/future/terminate, skip/override Decimal, ID uguali su due container, rifiuto contesti secondari, virtuali senza effetti su conteggi/saldi/totali, V2→V3 su disco senza conversione legacy, watermark persistente dopo riapertura/copia cancellata.
- `MoneyTrackerApp.swift`: coda condivisa degli avvii per attendere sync prima di materializzare; prima sync login anche se l'evento active arriva prima del montaggio, controllo identità utente dopo await. Avvio da `.task` del container attivo, `.active`, notifica significantTimeChange; demo/offline comprese. Import esplicito `Auth` richiesto dalla build per leggere l'ID della sessione (dipendenza già presente).
- Rimossi SOLO il vecchio `Domain/RecurringTransactionEngine.swift` e `MoneyTrackerTests/RecurringTransactionEngineTests.swift` (3 test), autorizzati da D-009; esecuzione annotata in DECISIONI.
- Invariati Sync/, viste, modelli, dati legacy, altri test esistenti. Nessuna modifica a logica di conti o saldi.

## Verificato e non verificato
- **Build OK; 48 unit verdi** = 40 precedenti − 3 del vecchio motore + 11 nuovi.
- Unit-only completo riuscito: `/tmp/moneytracker-s13c-unit.log`, TEST SUCCEEDED.
- `build test` completo: `/tmp/moneytracker-s13c-build.log`, BUILD SUCCEEDED e nuovamente 48 unit verdi. **Suite UI interrotta su ordine di Matteo, non conclusa.**
- Prima dell'interruzione: 5 UI verdi (2 conti, 2 categorie, dashboard/statistiche), 1 fallito: NavigationStressUITests.testAddMultipleTransactionsThenDeleteAll:55 (stesso S-15). In corso open/cancel sheets; restanti UI non verificati in questo turno. Non assumere verde il test interrotto.
- S-15 resta aperto: nel turno a+b erano 10/12 verdi, con stress:55 e senza-categoria:68 falliti anche dopo reset del runner. Qui il secondo caso non è stato raggiunto. Non alterare test o viste per aggirarli.
- Interruzione inviata con `kill -INT` al processo xcodebuild PID 73681. Il log può contenere stack/assertion di annullamento di Xcode, non attribuirli al codice dell'app.
- Bundle della sessione interrotta: `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.14_02-14-50-+0100.xcresult` (può essere incompleto per annullamento).
- `git diff --check` OK. Nessuna chiamata/tipo del vecchio actor nel codice eseguibile. Restano **5 riferimenti nei soli commenti** di AccountBalanceCache, CurrencyFormatting e Logging: lasciati invariati per perimetro, nota in S-13h. Quindi una ricerca testuale grezza del nome non è vuota; non confonderla con motore ancora attivo.
- Grafo aggiornato `graphify update .` (AST, nessuna API); consueto avviso di 9 JSON metadati/asset senza nodi. Backup automatico fuori da git: `/tmp/moneytracker-s13c-graphify-backup`.
- Nessun collaudo indipendente, Commissione Suprema, merge o push eseguito. S-13a/b e c restano [~]. Verifica reale cloud degli avvii non effettuata; Sync delle regole è S-13f.

## Punto preciso da cui riprendere
Il codice non richiede altra implementazione nota. Completa **solo la verifica UI interrotta**, registra l'esito senza rifare i 48 unit già verdi se non cambi codice. Poi chiudi la verifica di S-13c per il collaudatore e passa a S-13d.

📍 Claude Code, stessa cartella: Matteo scriverà «riprendiamo». Il capocantiere deve indirizzarlo a Codex con questo prompt:

```text
Riprendi solo S-13c dal salvataggio richiesto da Matteo. Entra in turno secondo AGENTS.md §4 se STATO è libero, ramo redesign-sentiero. Leggi CONSEGNA.md, la scheda S-13 in PIANO, D-008/D-009 e piano-s13.md; graphify prima del codice. Implementazione già finita e committata: RecurringMaterializer @MainActor/mainContext, Decimal, UUIDv5, watermark e massimo 36 mesi più recenti, nessuno storico per regole nuove; vecchio motore e suoi tre test rimossi; avvii serializzati dopo sync login/foreground, active e significantTimeChange, anche demo/offline. Build e 48 unit già verdi, 11 nuovi test materializer inclusi. Non rifare il codice o ripetere unit senza una ragione nuova. Matteo ha interrotto la suite completa mentre giravano gli UI: completa la verifica UI sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48 (shutdown all + boot solo se runner bloccato). S-15 documenta due UI già falliti prima di questo turno: stress riga55 è fallito anche qui, senza-categoria riga68 non era ancora eseguito. Non cambiare UI/test per aggirarli, né Sync, viste o dati legacy. Verifica che non restino chiamate/tipo del vecchio actor: solo cinque commenti obsoleti in altri file, rimandati a S-13h. Chiudi la verifica con risultati onesti, documenti e commit mirato; S-13c resta [~] per il collaudatore, mai [x]. Solo dopo il completamento della verifica proponi S-13d.
```
