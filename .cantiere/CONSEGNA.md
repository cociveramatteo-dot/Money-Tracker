# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-27 22:38** · ramo `redesign-sentiero`
- **Esito:** **S-70i → [~]** in `.cantiere/PIANO.md`.

## Cosa è stato fatto (S-70i)
- **`MoneyTracker/Intents/IntentCategoryMenu.swift`**:
  - Ordine e deduplica in `top(suggested:lastUsed:)`: prima `lastUsed` poi `suggested`; quando coincidono resta una sola riga sotto `lastUsed` (`· Ultima usata`).
  - Etichette sulla stessa riga nel titolo dell'`IntentItem` (`"<Nome> · Ultima usata"`, `"<Nome> · Suggerita"`, `subtitle: nil`) riusando le chiavi esistenti in tutte e 7 le lingue (`it`, `en`, `de`, `es`, `fr`, `ja`, `zh-Hans`), localizzando anche i nomi delle categorie predefinite e lasciando intatti i nomi custom (inclusi caratteri `%`).
  - Se `nome + etichetta` supera `maxRowTitleLength` (`34` caratteri), `formattedTitle` accorcia solo il nome categoria con `…` mantenendo l'etichetta intera.
  - Il valore salvato di ogni `IntentItem` resta esclusivamente il nome grezzo della categoria (`IntentItem(category, title: ...)`), quindi `AddExpenseIntent` e `AddIncomeIntent` continuano a salvare il solo nome categoria senza bisogno di modificare `AddExpenseIntent.swift`.
  - Le categorie mostrate in cima (in una sezione senza titolo, se presenti) vengono escluse da `remainingCategories` nella sezione `"Tutte le categorie"` sotto, evitando ripetizioni.
- **`MoneyTrackerTests/IntentCategoryMenuTests.swift`**:
  - Aggiornati i test esistenti alla nuova specifica (ordine, deduplica, assenza di ripetizioni, `subtitle == nil`, `value` invariato) e aggiunti test per `remainingCategories`, `formattedTitle` con nomi lunghi (anche in tedesco), localizzazione in tutte e 7 le lingue, caratteri `%` nei nomi custom, solo suggerita e storico vuoto.

## Verifiche eseguite
- `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,name=iPhone 18 Pro' test -only-testing:MoneyTrackerTests` (intero target): **230 test Swift Testing in 50 suite verdi** (`** TEST SUCCEEDED **`); `TwoDeviceLiveSyncTests.testLiveSync` (XCTest) skipped come previsto (`Richiede lo script della prova a due dispositivi`).

## Non provato / Aperto
- **Prova reale su iPhone in Comandi (`S-70d`):** il comportamento visivo del menu di Comandi al doppio tap (e che Comandi mostri effettivamente il `title` personalizzato dell'`IntentItem` invece del solo `value`) va verificato sul telefono vero da Matteo. Se Comandi non mostrasse il titolo personalizzato, si valuta con Matteo se tornare alla versione precedente.
- **File lasciati fuori dal commit:** `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` e `.cantiere/progetto-s72-movimenti-abitudini.md` (modifiche/file altrui preesistenti).
