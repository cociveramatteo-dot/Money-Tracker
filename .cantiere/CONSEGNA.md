# CONSEGNA — 2026-11-27 12:53 · impresa (Codex · GPT-6)

## S-51f · Crash SwiftUI

`MoneyTrackerApp.body` costruisce `RootView` sul MainActor. La closure `@Sendable` del `WindowGroup` restituisce la vista già costruita. Il ciclo di vita e la coda delle ricorrenze mantengono lo stato condiviso tra le finestre.

Nei due rapporti precedenti, `AsyncRenderer` invocava la closure del `WindowGroup` e falliva il controllo del MainActor mentre XCTest attendeva sul thread principale. La sola estrazione di `RootView` ha superato una prima prova completa, ma l'ispezione del binario Debug mostrava ancora la chiamata a `swift_task_isCurrentExecutor`. Con `@Sendable` il controllo è assente nella closure compilata. Ho interrotto il tentativo intermedio prima dell'attivazione della protezione per verificare questa correzione. Supabase ha confermato protezione disattivata e ID preesistenti presenti anche dopo l'interruzione.

La prova finale è riuscita su iPhone 18 Pro con iOS 27.2 **24B8117**, il runtime dei crash precedenti. Nessun nuovo rapporto di crash MoneyTracker durante le prove.

## S-51b · Prova reale su Supabase

Eseguita sulla versione finale con `prova-due-dispositivi.py`, iPhone 18 Pro e Android API 36 isolati.

| Fase | iOS → Android | Android → iOS | Riapertura iOS | Protezione |
| --- | --- | --- | --- | --- |
| In chiaro, prima dell'attivazione | OK | OK | OK, entrambi i movimenti una sola volta | Disattivata |
| Protezione avanzata attiva | OK | OK | OK, entrambi i movimenti una sola volta | Attivazione iOS e sblocco Android OK |
| Dopo la disattivazione | OK | OK | OK, entrambi i movimenti una sola volta | Disattivazione iOS OK |

**12/12 controlli passati.** Le riaperture verificano un nuovo processo, un solo esemplare di ciascun movimento con il suo importo in SwiftData e la presenza di entrambi nella scheda Movimenti con XCUITest. Supabase conferma protezione finale disattivata e tutti gli ID preesistenti nelle cinque tabelle sincronizzate. L'account dedicato contiene i movimenti di prova delle due esecuzioni complete.

## Build e test

- Build Debug iOS, compresi XCTest e XCUITest, riuscita.
- iOS, 40/40 al rilancio con il solo simulatore di test. Suite: SyncBaseline, SyncServiceFlagOff, SyncLostTransaction, E2EMigrator e RecurringRuleSync. Nel giro in parallelo con la prova reale è fallito il conteggio delle chiamate al remoto finto in `t10OldClientPushIsBlockedAndEmptyPullKeepsLocalData` (95 anziché 87). Il push differito della fixture dopo l'attivazione è la pista registrata in S-51h.
- Android, 332/332 unitari con E2E abilitato e build Debug installata nella prova reale.

## Collaudo e file locali

S-51f e S-51b in [~] per il collaudo indipendente. Lo schema Xcode e `graphify-out/` avevano modifiche locali già all'apertura del turno e restano fuori dal commit. Aggiornamento del grafo verificato su una copia temporanea.
