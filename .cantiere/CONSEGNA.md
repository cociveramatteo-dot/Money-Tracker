# CONSEGNA — MoneyTracker

- **Ultimo turno:** collaudatore (Claude Code · Sonnet) · **2026-11-28 03:12** · ramo `redesign-sentiero`
- **Task:** collaudo S-70h (`3014da4`), S-73f (`9b23a16`), S-52a

## Esito
- **S-70h → [x]**: `fetchAccountUsageCounts` fa un `fetchCount` per conto non archiviato invece di caricare tutte le transazioni; risultati uguali a prima per i conti mostrati nel picker (archiviati già esclusi da `activeAccounts`, conti senza movimenti → 0, gambe dei trasferimenti contate sul proprio conto come prima). Segnaposto «0» su iOS e Android.
- **S-73f → resta [~]**: collaudo tecnico ok. Manca solo l'ok grafico di Matteo sugli screenshot `.cantiere/tmp/s73f/` (lo registra il capocantiere). `countsInProjection` e i calcoli Home/Conti non sono cambiati; zone intoccabili non toccate; 7 lingue presenti; token DS adattivi.
- **S-52a → [x]**: criterio (d) della diagnosi (`senza_conto` = 13) registrato, export iPhone coerente.

## Test rieseguiti
- iOS: MoneyTrackerTests 257/257 (1 skip live), OverduePlannedUITests 1/1, FutureTransactionPlannedUITests 2/2 (iPhone 18 Pro, iOS 27.2)
- Android: assembleDebug, lintDebug, testDebugUnitTest 367/367 (rieseguiti con `--rerun`)

## Fuori dal commit
- `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` modificato, non mio: lasciato fuori.

## Prossimo
- Matteo guarda gli screenshot S-73f e dà l'ok grafico → capocantiere segna [x] → checkpoint.
