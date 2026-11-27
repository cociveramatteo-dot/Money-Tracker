# CONSEGNA — 2026-11-27 13:00 · collaudatore (Claude Code · Sonnet)

## Collaudo c0ca6b8 (S-51f, S-51b): ok, entrambi [x]

- **S-51f:** `MoneyTracker/MoneyTrackerApp.swift` è un refactor senza cambi di comportamento. Modificatori, `onChange(scenePhase)`, `task(id: demoModeEnabled)`, `onReceive` (cambio orario, didSave), animazioni, banner dell'archivio volatile e ordine sync → ricorrenze sono invariati. `scenePhase`, `recurrenceRefreshTask` e `recurrenceSyncedUserID` restano a livello App come prima, quindi la coda delle ricorrenze è unica e serializzata anche con più finestre. `RecurrenceOperationStatus` è una classe e viene passata per riferimento. RootView viene costruita in `App.body` (MainActor); la closure `@Sendable` si limita a restituirla. Nessun nuovo force-unwrap e nessun warning sul file.
- **Test:** build Debug, 73/73 verdi (SyncBaseline, SyncServiceFlagOff, SyncLostTransaction, E2EMigrator, RecurringRuleSync, RecurringMaterializer, RecurringSeriesEditor, RecurringCollision). In questo giro t10 è passato (S-51h resta aperto).
- **Avvio:** iPhone 18 Pro. Senza sessione compare il login; con `--uitesting` la Home demo è normale. Nessun nuovo rapporto di crash.
- **S-51b:** la tabella 12/12 è coerente con PIANO e DIARIO. I log dello script non sono conservati (cartella temporanea): la prova non è stata rilanciata.

## File locali
Lo schema Xcode e `graphify-out/` hanno modifiche locali precedenti al turno e restano fuori dal commit.

## Prossimo
S-51g (conto cancellato altrove che ricompare) → Codex; poi S-51h, S-51e.
