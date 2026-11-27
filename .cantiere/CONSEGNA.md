# CONSEGNA — MoneyTracker

- **Ultimo turno:** impresa (Antigravity · Gemini 4 Hydrogen) · **2026-11-28 00:04** · ramo `redesign-sentiero`
- **Esito:** **S-70j → [~]** in `.cantiere/PIANO.md`.

## Cosa è stato fatto (S-70j)
- **`MoneyTracker/Intents/AddMovementIntent.swift`** (nuovo):
  - Nuovo intent unico `AddMovementIntent` («Aggiungi movimento») con ordine parametri: `movementType` (`MovementKind`: `Uscita`/`Entrata`) → `amount` (`Importo`) → `name` (`Descrizione`), più `accountName` (`Conto`, opzionale come oggi) e `category` (`IntentCategoryChoice?`, `AppEntity` opzionale).
  - Dentro `perform()`, dopo la validazione di importo e descrizione e la lettura del `ModelContext`, se `category` non è preimpostata chiede la categoria tramite `$category.requestDisambiguation(among: choices, dialog: "In quale categoria?")`, costruendo le scelte con nome e tipo già noti e salvando il `Transaction` (con `AccountBalanceCache.shared.invalidateAll()` e `SyncService.shared.markTransactionDirty(...)`).
- **`MoneyTracker/Intents/IntentCategoryMenu.swift`**:
  - Aggiunta la funzione condivisa `suggestLikeApp(for:history:available:)` / `suggestLikeApp(for:context:available:)` con la stessa priorità e distinzione di `AddTransactionView`: match da storico `LastUsedCategory.suggest` → sorgente `.history` (`"ultima usata"`), altrimenti `KeywordCategoryClassifier.shared.classify` per descrizioni `> 2` caratteri e diverse da `"Altro"` → sorgente `.keyword` (`"suggerita"`).
  - Aggiunto `movementChoices(...)`: se c'è un match `.history` sul nome lo mostra in cima come `"<Categoria> · ultima usata"`; altrimenti mostra prima l'ultima usata del tipo scelto (`lastUsed(type:)`) con `"ultima usata"` e poi il suggerimento keyword con `"suggerita"`, unificati su una sola riga `"ultima usata"` quando coincidono, senza duplicati nella lista sotto e troncando con `…` solo il nome categoria oltre 34 caratteri; il valore (`id`) resta sempre il nome grezzo della categoria.
- **`MoneyTracker/Intents/AddExpenseIntent.swift`**:
  - Lasciati invariati `AddExpenseIntent` e `AddIncomeIntent` (parametri e comportamento esistenti non modificati).
  - Reso interno `IntentContainer` (da `private`) e aggiunta la scorciatoia `AddMovementIntent()` a `MoneyTrackerShortcuts` con titolo `"Aggiungi movimento"` e frasi Siri dedicate.
- **`MoneyTracker/*.lproj/Localizable.strings`** (7 lingue: `it`, `en`, `de`, `es`, `fr`, `ja`, `zh-Hans`):
  - Aggiunte 10 chiavi nuove comprese le etichette in minuscolo `"ultima usata"` / `"suggerita"` e i testi del nuovo intent; verificate con `plutil -lint` (7/7 OK).
- **`MoneyTrackerTests/AddMovementIntentTests.swift`** (nuovo):
  - Aggiunti test per `suggestLikeApp` (distinzione storico vs keyword, input corto, `"Altro"`), `movementChoices` (caso `"pizza"` con storico vs keyword, deduplica, filtro per tipo `.uscita`/`.entrata`, troncamento solo sul nome mantenendo `id` integro), localizzazione nelle 7 lingue e persistenza `AddMovementIntent.saveMovement` su SwiftData in memoria.

## Verifiche eseguite
- `plutil -lint MoneyTracker/*.lproj/Localizable.strings`: **7/7 OK**.
- `xcodebuild -project MoneyTracker.xcodeproj -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' test -only-testing:MoneyTrackerTests` (intero target dopo tutte le modifiche): **247 test in 54 suite verdi** (`** TEST SUCCEEDED **`).

## Non provato / Aperto
- **Prova reale su iPhone in Comandi e rimappatura doppio tap (`S-70d`)**: `requestDisambiguation` in `perform()` con i passaggi interattivi Uscita/Entrata → Importo → Descrizione → Categoria va provata su dispositivo reale da Matteo.
- **Collaudo indipendente** di S-72 (b, a, d, c, e) e S-70j.
- **File lasciato fuori dal commit**: `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` (già sporco prima del turno).
