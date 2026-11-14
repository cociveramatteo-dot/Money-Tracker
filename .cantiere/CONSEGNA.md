# CONSEGNA — S-13c: verifica UI completata, da collaudare

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 09:29
**Ripresa completata:** Matteo ha scritto «riprendiamo» e «-- yolo». In questo turno nessun codice o test modificato: eseguiti solo i sei UI rimasti interrotti, poi aggiornati i documenti. **S-13c resta [~], non [x].**

## S-13c implementato [~]
- Nuovo `MoneyTracker/Domain/RecurringMaterializer.swift`, `@MainActor`: accetta solo `container.mainContext` (guardia e test), calendario gregoriano e mezzogiorno, Decimal, ID del calculator; intero mese corrente come pianificato `isDone=false`, `templateId=rule.id`, frequenza della copia vuota.
- Watermark per regola: nil = nuova, mai storico prima del mese corrente; futuro in attesa. Watermark esistente = recupero fino al corrente, massimo 36 mesi più recenti. ID già esistente: non tocca la copia. Watermark già passato: non ricrea copie cancellate né sovrascrive modifiche/fatte.
- Fetch preparatori prima delle mutazioni, un solo `safeSave` per giro con cambiamenti. Nessun rollback globale del contesto in errore; ripristino delle sole mutazioni proprie se safeSave restituisce false (in debug il safeSave esistente fa assertion).
- Nuovo `MoneyTrackerTests/RecurringMaterializerTests.swift`: 11 test verdi su mese completo, idempotenza, copie eliminate/modificate/fatte, tre mesi mancanti, limite 36, regole nuove/passate/future/terminate, skip/override Decimal, ID uguali su due container, rifiuto contesti secondari, virtuali senza effetti su conteggi/saldi/totali, V2→V3 su disco senza conversione legacy, watermark persistente dopo riapertura/copia cancellata.
- `MoneyTrackerApp.swift`: coda condivisa degli avvii per attendere sync prima di materializzare; prima sync login anche se l'evento active arriva prima del montaggio, controllo identità utente dopo await. Avvio da `.task` del container attivo, `.active`, notifica significantTimeChange; demo/offline comprese. Import esplicito `Auth` richiesto dalla build per leggere l'ID della sessione (dipendenza già presente).
- Rimossi SOLO il vecchio `Domain/RecurringTransactionEngine.swift` e `MoneyTrackerTests/RecurringTransactionEngineTests.swift` (3 test), autorizzati da D-009; esecuzione annotata in DECISIONI.
- Invariati Sync/, viste, modelli, dati legacy, altri test esistenti. Nessuna modifica a logica di conti o saldi.

## Prove e risultati effettivi
- Codice dei commit `25b1b6e` (a+b) e `dc58891` (c). Nessuna differenza in MoneyTracker/, MoneyTrackerTests/ o MoneyTrackerUITests/ rispetto a `dc58891` durante questa ripresa.
- **Build OK; 48 unit verdi** = 40 precedenti − 3 del vecchio motore + 11 nuovi. Prove già completate sullo stesso codice: `/tmp/moneytracker-s13c-unit.log` (TEST SUCCEEDED), `/tmp/moneytracker-s13c-build.log` (BUILD SUCCEEDED e ancora 48 unit verdi). Non ripetute senza cambi di codice.
- La sessione `build test` delle 02:14 era stata interrotta da Matteo dopo **5 UI verdi e 1 fallito** (stress S-15); restavano sei test.
- Ora eseguiti tutti e sei i rimanenti sul simulatore `37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`: **5 verdi, 1 fallito**. Passano open/cancel sheets, rapid tab switching, ricerca, aggiunta/modifica/eliminazione movimento e annullamento. Fallisce `TransactionFlowUITests.testAddTransactionWithoutCategoryDefaultsToAltro` a riga 68, stesso S-15.
- **Totale UI sul codice invariato, aggregato delle due sessioni: 10/12 verdi, 2 falliti.** La verifica è stata completata, ma non è tutta verde. Casi falliti: `NavigationStressUITests.testAddMultipleTransactionsThenDeleteAll:55` e `TransactionFlowUITests.testAddTransactionWithoutCategoryDefaultsToAltro:68`; entrambi cercano senza trovarla la riga del movimento appena salvato. Causa non dimostrata; non attribuita al nuovo schema/materializer. Nessun nuovo fallimento osservato.
- Log della ripresa: `/tmp/moneytracker-s13c-ui-resume.log` (6 test, 1 failure, exit 65 atteso per quel fallimento); percorso xcresult nelle ultime righe. Log precedenti a+b: `/tmp/moneytracker-s13-build.log` e `/tmp/moneytracker-s13-recheck.log` (stessi due UI fallivano già, anche dopo shutdown all + boot).
- `git diff --check` OK. Non sono stati cambiati test, viste, Sync, modelli o dati legacy durante questa ripresa. Nessun collaudo indipendente, Commissione Suprema, merge o push eseguito.
- Nessun tipo/chiamata del vecchio actor nel codice eseguibile; restano 5 riferimenti nei soli commenti di AccountBalanceCache, CurrencyFormatting e Logging, fuori perimetro e annotati in S-13h. Una ricerca testuale grezza quindi non è vuota.
- Grafo già aggiornato nel commit `dc58891`, codice invariato: non rigenerato in questa ripresa. Avviso precedente: 9 JSON metadati/asset senza nodi; backup in `/tmp/moneytracker-s13c-graphify-backup`.

## Aperto e prossimo passo
- S-13a/b/c [~]: serve il collaudatore; S-15 ancora aperto per i due UI. Non indebolire asserzioni o modificare viste per aggirarli.
- Dopo il collaudo, S-13d (editor ambiti, salta/termina e riconciliazione) → Codex. Nessuna implementazione di S-13d iniziata.
- Gli avvii reali con cloud non sono stati provati end-to-end: Sync delle regole e tabella Supabase sono S-13e/f. Nessuna pubblicazione autorizzata.

📍 Claude Code nella cartella `/Users/matteo/Desktop/APP/MoneyTracker`, modello Sonnet. ▶️ Prompt completo:

```text
Entra in turno secondo AGENTS.md §4 solo se STATO è libero. Sul ramo redesign-sentiero collauda S-13a/b/c, senza iniziare S-13d: leggi CONSEGNA, schede S-13/S-15, piano-s13.md e D-008/D-009; per il codice leggi solo il diff dei commit 25b1b6e e dc58891 (git diff 0a76000..dc58891 -- MoneyTracker MoneyTrackerTests). Controlla calculator/UUIDv5/Decimal, migrazioni V1→V2→V3 senza conversioni legacy, mainContext/watermark/limite 36 mesi, idempotenza e copie fatte invariate, avvii dopo sync e spegnimento del vecchio motore. Le prove registrate sono build e 48 unit verdi; tutti i 12 UI sono stati eseguiti sullo stesso codice in due sessioni, 10 verdi e due falliti già noti S-15 (stress riga55 e senza-categoria riga68). Nuovo log dei sei UI ripresi: /tmp/moneytracker-s13c-ui-resume.log; gli altri log sono in CONSEGNA. Nessuna asserzione o vista è stata modificata per aggirare i difetti; diagnostica S-15 senza correzioni fuori perimetro. Rimangono solo cinque riferimenti al vecchio actor nei commenti di file fuori perimetro, rimandati a S-13h. Segna [x] solo se il tuo collaudo lo giustifica, altrimenti registra difetti precisi e lascia [~]. Chiudi con documenti, commit mirato e STATO libero. Dopo il collaudo, prossimo sviluppo: S-13d (editor degli ambiti) a Codex.
```
↩️ Riportare cartellino del collaudatore ed eventuali difetti; poi assegnare S-13d.
