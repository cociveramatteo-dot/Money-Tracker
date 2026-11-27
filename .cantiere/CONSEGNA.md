# CONSEGNA — MoneyTracker

- **Ultimo turno:** collaudatore (Claude Code · Sonnet) · **2026-11-28 00:15** · ramo `redesign-sentiero`
- **Esito:** S-72b, S-72a, S-72d, S-72c, S-72e e S-70j → **[x] collaudo ok** in `.cantiere/PIANO.md`. Nuovo task **S-72f**.

## Controlli
- Zone intoccabili: Domain/ toccato solo in `RecurringSeriesDetector` (iOS + Android, soglia 3×3, esclusa «Rettifica saldo», autorizzato). Intents/ solo per S-70j. Models, Sync, Auth, Export e Formatting non toccati.
- Test: eliminati solo `NextMonthSummaryTests.swift` e `NextMonthSummaryTest.kt` (D4). Nei test UI cambia solo la navigazione (`tf_searchTransactions`, `.firstMatch`, tolto `navigateBack()`). Gli altri test sono solo aggiunti.
- 7 lingue: `plutil -lint` e `xmllint` ok, chiavi nuove presenti in tutte le lingue, chiavi rimosse non più usate né in iOS né in Android. Nessuna stringa nuova scritta a mano fuori dalle traduzioni.
- Nessun `preferredColorScheme` e nessun colore non adattivo.
- iOS: intero target `MoneyTrackerTests` **247/247** (54 suite), più `HabitsUITests` e `RecurrenceCancelAndHomeUITests` verdi. Android: `assembleDebug` e `testDebugUnitTest --rerun` **361/361**.
- Screenshot `.cantiere/tmp/s72/` (chiaro, scuro, de-axxl): totali in fondo alle sezioni, badge non tagliato, testate su una riga. Gli screenshot «corrente-ricorrenti-top» sono scorsi in fondo (la lista mantiene lo scorrimento quando si cambia filtro), quindi la somma 1182,38 € corrisponde alle 8 righe del mese anche se ne vedi solo 2.
- S-70j: c'è un solo intent nuovo. Le categorie seguono `sortOrder` come `AddTransactionView`, con «ultima usata» e «suggerita» in minuscolo sulla stessa riga e senza ripetizioni. `AddExpenseIntent` e `AddIncomeIntent` funzionano come prima: cambiano solo `IntentContainer`, ora non più `private`, e la nuova voce in `MoneyTrackerShortcuts`.

## Correzione del collaudatore
- `MoneyTracker/Intents/IntentCategoryMenu.swift:272`: `collection(...)` leggeva le categorie senza ordinamento. Il test S-70i `swiftDataCollectionHandlesSuggestedOnlyEmptyHistoryAndLongCustomName` falliva **2 volte su 2**, contrariamente al 247/247 dichiarato dall'impresa. Aggiunto `sortBy: sortOrder`, come in `AddTransactionView` e `movementChoices`. Dopo la correzione il risultato è 247/247.

## Aperto
- **S-72f**: in Statistiche ad AX-XL i nomi delle categorie si spezzano a metà parola. Il difetto c'era già prima di questo lavoro.
- **S-70d**: prova reale di Matteo sull'iPhone (Comandi «Aggiungi movimento» e rimappatura del doppio tap).
- `MoneyTracker.xcscheme` modificato in locale apposta e lasciato fuori dal commit.
