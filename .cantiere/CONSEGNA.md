# CONSEGNA — MoneyTracker

- **Ultimo turno:** collaudatore (Claude Code · Sonnet) · **2026-11-27 21:43** · ramo `redesign-sentiero`
- **Esito:** collaudo ok, **S-70a, S-70a2, S-70b, S-70e, S-70f → [x]** in `.cantiere/PIANO.md`.

## Cosa è stato controllato (diff `0235a57..a320bcf`, commit `cfd818b`..`a320bcf`)
- **Zone intoccabili:** toccato solo `MoneyTracker/Intents/` (autorizzato e registrato in DECISIONI). Models, Persistence, Domain, Sync, Auth, Export, Formatting, notifiche e ricorrenze non sono stati toccati. I test sono **solo aggiunti** (8 file nuovi, nessuno modificato).
- **S-70a/a2:** la scelta dell'utente vince, poi la categoria suggerita, poi il ripiego («Altro» per le spese, «Lavoro»/prima categoria per le entrate). «Ultima usata» con `fetchLimit` 1 e senza doppioni. Provider separati con `@IntentParameterDependency` e gestione del `nil`. `parameterSummary` delle entrate come da §2.9.
- **S-70b:** `WhatIfView` non usa `@Query` né `modelContext` e non scrive nulla (legge soltanto `hideBalance`). Usa solo `Decimal` (BigDecimal su Android), con `parseAmount`, limite 1e9 e massimo 20 righe. Le basi vengono da `totalCurrent`, `trail.expectedBalance` e `plannedByAccount`; i conti esclusi usano `currentBalance`/`futureBalance`, gli archiviati non compaiono. Ordine dell'intestazione: calcolatrice, occhio, impostazioni. Colori DS, nessun `preferredColorScheme`, stringhe presenti nelle 7 lingue su iOS e Android. Con importi oscurati sono nascosti i valori «ora» e «con le ipotesi»; la «Differenza totale» resta visibile come previsto da §3.4.
- **S-70e:** cambia solo l'ordine di visualizzazione; a parità di uso resta l'ordine attuale (ordinamento stabile su iOS e Android).
- **S-70f:** stessi filtri del riepilogo «Fissi del mese» in Home, più le occorrenze virtuali dalla `RecurrencePresentationCache`/`RecurrenceCalculator` esistenti. I doppioni sono esclusi tramite `realIDs`, con lo stesso schema già usato nella lista. Logica uguale su iOS e Android.
- **Screenshot** `.cantiere/tmp/s70/`: AX-XL in tedesco con i 3 bottoni interi; bordo rosso visibile sull'importo non valido; tema scuro leggibile; importi oscurati corretti.

## Verifiche rieseguite
- iOS `-only-testing:MoneyTrackerTests` (target intero): **226 test in 50 suite verdi**.
- iOS `MoneyTrackerUITests/WhatIfUITests` su iPhone 18 Pro: **3/3 verdi**.
- Android `assembleDebug testDebugUnitTest` (JDK 17, `ANDROID_HOME=~/Library/Android/sdk`, perché `local.properties` manca) + `testDebugUnitTest --rerun`: **350/350 verdi**.

## Aperto
- **S-70d (Matteo):** prova del doppio tap su iPhone vero (spese ed entrate) e approvazione degli screenshot S-70b (D-014) prima del merge.
- **S-70h (Copilot, bassa priorità):** segnaposto «0,00» non localizzato (en/ja/zh); conteggio dei conti in `AddTransactionView.load()` con lettura completa delle transazioni sul main thread.
- File locale lasciato fuori: `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` (modifica preesistente, non toccata).
