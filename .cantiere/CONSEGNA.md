# CONSEGNA — MoneyTracker

- **Ultimo turno:** operaio (Claude Code · Sonnet) · **2026-11-28 12:18** · ramo `redesign-sentiero`
- **Task:** S-73h (icona categoria coerente nelle righe) + S-73j (test invalidazione cache)

## Fatto
1. **S-73h** (`d46c7fe`): `TransactionsView.transactionCell` e `DashboardView.movementRow` usano `OverduePlannedMovements.resolvedCategorySymbol(for:)`; su Android `screens/TransactionRow.kt` (usata da Home e Movimenti) usa `OverduePlannedMovements.resolvedCategoryIcon(t)`. Nessuna duplicazione, nessun altro cambio di aspetto. Le righe virtuali delle serie Android (`VirtualMovementRow`, non `TransactionEntity`) restano invariate.
2. **S-73j**: nuovo `MoneyTrackerTests/CacheInvalidationTests.swift`: (1) previsione 880 → 580 dopo la conferma di un pianificato di dicembre, ListCache 2 → 1 dopo una conferma; (2) FilteredCache con la stessa istanza: categoria, poi min/max, poi reset. Test esistenti intatti.

## Verifiche eseguite
- iOS: intero target MoneyTrackerTests, 267/267 in 61 suite (iPhone 18 Pro).
- Android: `assembleDebug lintDebug testDebugUnitTest` verdi, 370/370.
- Entrambi i task `[x]` in PIANO: chiusi senza collaudo su richiesta di Matteo.

## Fuori dal commit (lasciato intenzionalmente)
- `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme`. Grafo non aggiornato. Nessun push.

## Prossimo
- Matteo: merge di `redesign-sentiero` su `main` (sì o no). Poi S-80m (mockup) oppure S-71p (progetto import).
