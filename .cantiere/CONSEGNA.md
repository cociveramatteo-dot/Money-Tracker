# CONSEGNA — S-29

**Da:** impresa (Codex · GPT-6), 2026-11-16 10:13. Ramo `redesign-sentiero`. Nessun push/merge.

## Perimetro autorizzato e modifiche
Matteo ha autorizzato in chat gli interventi mirati nei punti 1–4 di S-29, incluso RecurringSeriesEditor esplicitamente citato. S-29 creato in PIANO e turno occupato prima delle modifiche.
1. **Calendario:** RecurrenceCalculator espone adding/monthInterval/monthStart/daysInMonth; guard con fallback alla data originale (intervallo vuoto su errore, giorno originale se range indisponibile). noon usa guard; key usa componenti non opzionali. Rimpiazzati gli unwrap di calendario nei tre Domain, inclusi ancoraggio e ripianificazione editor. lastMonth usa il mese di `interval.end.addingTimeInterval(-1)` per evitare di iterare il mese successivo negli intervalli che terminano a inizio mese. Per calendario valido i calcoli restano gli stessi.
2. **Materializer:** un FetchDescriptor<Transaction> per regola con predicate templateId == ruleIdString, Set degli UUID esistenti, conservato pendingIDs globale. Fetch prima delle mutazioni, stessi ID/UUIDv5, copie esistenti non aggiornate, limite -35 mesi invariato. Se l'aggiunta del mese non avanza, ritorna 0 prima di qualsiasi mutazione: non entra in loop né avanza watermark senza aver generato copie. Rimosso il Calendar locale divenuto inutilizzato.
3. **i18n:** quattro EditorError.errorDescription ora usano String(localized:). RecurrenceOperationStatus.perform usava già NSLocalizedString ed è invariato. Verificate tutte le cinque chiavi: presenti esattamente una volta in ciascuna delle sette lingue, italiano invariato. Nessuna nuova traduzione, quindi nessuna nuova approvazione aggiunta: resta pendente l'approvazione S-19 già registrata in APPROVAZIONI. Nessun file Localizable.strings modificato, nessun termine inventato.
4. **Decimal:** nuovo RecurringDecimalRoundTripTests.swift prova 0.29, 1234.56 e 999999.99: salvataggio SwiftData su disco, riapertura dello store con un nuovo container, lettura importo, codifica SBRecurringRule in JSON ISO8601, decodifica e apply su una nuova regola. Tutte le uguaglianze esatte passano; nessuna discrepanza. SyncService invariato.

## Verifiche
- **BUILD + TEST SUCCEEDED: 81 unit (80 esistenti + nuovo test), 3 UI TabBarAppearance**, tutti verdi. UI 103,239 s; test unitari 1,673 s.
- Log `/tmp/moneytracker-s29.log`; risultato `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.16_10-09-41-+0100.xcresult`.
- Comando: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO -only-testing:MoneyTrackerTests -only-testing:MoneyTrackerUITests/TabBarAppearanceUITests build test`.
- Suite esistenti invariate: idempotenza, copie modificate/effettuate, UUIDv5, recupero 36 mesi e modifiche scope verdi. Nessun test esistente modificato.
- plutil -lint su tutte le sette Localizable.strings verde, cinque chiavi × sette lingue controllate. Nessun force-unwrap residuo nei tre file Domain coinvolti. git diff --check verde.
- Grafo AST aggiornato, senza LLM; avviso di 9 file JSON/configurazioni che non producono nodi, non errori Swift.

## Fuori perimetro e file esclusi
TransactionsView, blocco reale S-24, traduzioni S-19/S-28, Models/Persistence, Auth, Intents, Export, Formatting, notifiche e Sync invariati. Nessun cambio ai calcoli monetari o UUIDv5.
`graphify-out/` era già modificato/non tracciato all'ingresso: aggiornato ma escluso interamente dal commit. `.cantiere/PER-MATTEO.md` è stato modificato da lavoro esterno durante il turno: non toccato da me e lasciato fuori dal commit.

## Prossimo
Ricollaudo S-29 → collaudatore Claude Code (Sonnet): leggere solo il diff del commit S-29 e queste evidenze. Verificare perimetro autorizzato, fallback calendario, estremi intervallo, fetch per regola/idempotenza, chiavi i18n esistenti e test Decimal. Solo collaudatore o Matteo può portare S-29 a [x]. Poi nuova Commissione Suprema S-13h: nessuna nuova valutazione 10/10 dichiarata in questo turno. Approvazione traduzioni Matteo ancora pendente. Nessun push/merge.
