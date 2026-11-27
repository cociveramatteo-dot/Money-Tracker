# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 00:43** · ramo `redesign-sentiero`
- **Task:** `S-70k` → segnato `[~]` in `.cantiere/PIANO.md`

## Fatto
- **`MoneyTracker/Intents/IntentCategoryMenu.swift`:** aggiornato `movementChoices` per replicare esattamente `AddTransactionView.applySuggestion(for:)`:
  - rimosso `recentOfType` / `lastUsed(type:)` dal menu di `AddMovementIntent` (`collection` per `AddExpenseIntent`/`AddIncomeIntent` resta invariata);
  - se lo storico ha una voce con lo stesso nome → in cima solo quella categoria con `· ultima usata`;
  - altrimenti, se il classificatore suggerisce una categoria (≠ `Altro`, > 2 caratteri) → in cima solo quella con `· suggerita`;
  - altrimenti → nessuna etichetta in cima, tutte le categorie nell'ordine `sortOrder` dell'app senza duplicati.
- **`MoneyTracker/Intents/AddMovementIntent.swift`:**
  - in `IntentCategoryChoiceQuery` aggiunto `@IntentParameterDependency<AddMovementIntent>(\.$movementType, \.$name) var intent` ed estratto l'helper `choices(name:movementType:context:bundle:)`: quando Categoria è su «Chiedi ogni volta», legge `intent?.name` e `intent?.movementType` e applica la stessa regola `movementChoices`; se la descrizione non è disponibile (`intent == nil` o stringa vuota), restituisce l'elenco semplice in `sortOrder` senza etichette;
  - mantenuto invariato il ramo `requestDisambiguation` in `perform()` quando Categoria è lasciata vuota.
- **`MoneyTrackerTests/AddMovementIntentTests.swift`:** aggiornati i test di `movementChoices` rimuovendo `recentOfType` e aggiunti i test per (a) `pizza` in storico (`Cibo · ultima usata`), (b) `supermercato` senza storico (`Cibo · suggerita` senza `Svago · ultima usata`), (c) nome nuovo senza parole chiave (nessuna etichetta, puro `sortOrder`), 7 lingue per entrambe le etichette e `IntentCategoryChoiceQuery` con/senza descrizione.

## Verifiche eseguite dopo l'ultima modifica
- **iOS (`xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -parallel-testing-enabled NO -only-testing:MoneyTrackerTests test`):**
  - `MoneyTrackerTests`: **249/249** test Swift Testing passati in 54 suite (`TEST SUCCEEDED`), 1 XCTest (`TwoDeviceLiveSyncTests/testLiveSync`) skipped perché richiede lo script a due dispositivi.

## Aperto / note per il collaudo
- `MoneyTracker.xcscheme` era già modificato in locale prima del turno: lasciato fuori dal commit come richiesto.
- Resta la prova reale su iPhone `S-70d` (Matteo) per verificare in Comandi sia «Chiedi ogni volta» sia «Categoria vuota», oltre all'eventuale collaudo diff.
