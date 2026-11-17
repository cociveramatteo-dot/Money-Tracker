# CONSEGNA — S-37 · impresa (Codex · GPT-6) · 2026-11-17 12:52

Ramo `fix-sync-integrita` creato da main, nessun push/merge. Autorizzazione Matteo in chat del 2026-11-17 per Sync/, Formatting/, MoneyTrackerApp.swift e, con risposta esplicita successiva, la sola validazione dell'importo override in Domain/RecurrenceCalculator.swift. S-16 ESCLUSO e invariato.

## Interventi
1. SyncService.push: Account, Transaction, Budget e Goal usano `try context.fetch`, come RecurringRule. Tutte e cinque le letture avvengono nel do/catch prima di qualunque upsert o deleteOrphans; al primo errore il push ritorna false senza scrivere sul cloud. Nessun altro `try?` nel corpo del push. I `try?` del pull non sono stati modificati.
2. Decimal.parseAmount: dopo la normalizzazione virgola→punto richiede che l'intera stringa sia numerica. Conserva segni +/−, forme .5/5., virgola/punto decimali e arrotondamento a due cifre esistente. I separatori delle migliaia NON erano gestiti dal vecchio helper: input misti come 1.234,56 erano letti parzialmente e ora restituiscono nil, come richiesto. Nessuna nuova normalizzazione ambigua.
3. MoneyTrackerApp.usingVolatileStore (static private(set), false iniziale) viene impostato true prima di creare il fallback reale in memoria. SyncService blocca immediatamente push, pushResilient, schedulePush e scheduleRetry; guardia anche su deleteOrphans, unico punto di cancellazione remota. Nessuna UI/stringa visibile nuova. Il flag resta true per la vita del processo dopo il fallback.
4. RecurrenceCalculator NON usava parseAmount: validazione completa aggiunta solo alla conversione dell'override, autorizzata separatamente. Conversione POSIX originale mantenuta, senza arrotondare né normalizzare: input malformati usano il fallback rule.amount già previsto; tutta la precisione valida resta invariata.

## Verifica
- Build pulita definitiva: `/tmp/mt-s37-final-build.log`, BUILD SUCCEEDED.
- Suite definitiva: `/tmp/mt-s37-final-full.log`, TEST SUCCEEDED; **94 unit in 20 suite + 45 UI**, zero fallimenti; UI 1881.605 secondi. Risultato `/tmp/mt-s37-final-full.xcresult`.
- Comandi: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' clean build`; poi stessa destinazione con `-parallel-testing-enabled NO -resultBundlePath /tmp/mt-s37-final-full.xcresult test`.
- Tre test nuovi in StrictAmountParsingTests: rifiuto numeri parziali/misti/vuoti/segni soli, preservazione formati validi e arrotondamenti; include 12abc, 1.234,56, stringa vuota, -5,5.
- Un test nuovo in StrictRecurrenceAmountTests: override malformati ricadono sull'importo regola, override validi conservano anche 19 cifre decimali. Nessun test esistente modificato o cancellato. Nuovi file inclusi automaticamente dal gruppo sincronizzato del target MoneyTrackerTests.
- Punti 1 e 3 verificati tramite ispezione del percorso e controllo statico: tutte le letture throwing prima delle scritture; nessun try? nel push; guardie come prima istruzione dei cinque ingressi; unica delete remota in deleteOrphans; flag true prima del fallback. Non simulati errori fetch/store o chiamate Supabase con mock: queste condizioni richiederebbero introdurre infrastruttura oltre la modifica chirurgica. La suite UI lavora in demo e non dimostra la protezione cloud in esercizio.
- Tutti e tre RecurrenceFlowUITests verdi, S-33 non riprodotto e resta in osservazione.
- Primo run `/tmp/mt-s37-full.*` interrotto intenzionalmente con SIGINT per includere l'autorizzazione Domain sopraggiunta; non è l'esito finale e non è un rosso S-33. Prima della ripartenza era verde sui 93 unit.
- `git diff --check` verde. Grafo aggiornato AST; avviso preesistente su nove file JSON di metadati senza nodi. Backup automatico storico del grafo ripristinato al contenuto originale per non alterare lo storico.

## Aperto / prossimo
S-37 [~]: collaudo indipendente sul diff rispetto a main, con particolare attenzione a propagazione errori prima delle scritture, protezione dello store volatile e conservazione dei formati/precisione validi. Nessuna modifica estranea presente all'inizio o lasciata fuori dal commit; codice, test nuovi, grafo generato e file di cantiere sono tutti del lavoro S-37.

Prompt: «Leggi AGENTS.md e STATO.md e apri turno se libero. Collauda S-37 sul ramo fix-sync-integrita leggendo diff rispetto a main e CONSEGNA.md. Autorizzati soltanto fetch throwing nel push, parsing rigoroso, flag volatile e validazione override in RecurrenceCalculator; S-16 escluso. Verifica assenza scritture remote dopo fetch fallito o fallback volatile, input validi e precisione ricorrenze invariati. Build pulita e suite 94 unit + 45 UI verdi, log /tmp/mt-s37-final-*. Nessun push/merge, test esistenti intoccabili. Se passa metti S-37 [x], poi chiudi turno secondo AGENTS.md §4.»
