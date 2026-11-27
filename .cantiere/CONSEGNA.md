# CONSEGNA — 2026-11-27 12:13 · collaudatore (Claude Code · Sonnet)

## Esito collaudo
- **S-51** (`e462c34`) [x]: protezione `.completeUntilFirstUserAuthentication` su db, -wal e -shm; archivio volatile blocca push, pull, login, retry e percorsi E2E; banner localizzato.
- **S-51d** (`53d62d9` iOS, `9d58e4e` Android) e **S-51c** [x]: merge a tre vie con base per utente e tabella; cancellazioni remote solo per ID della base; remoto nuovo preservato; cancellazione remota vince sul sporco anche in due push consecutivi (`deletedElsewhere`). Test esistenti cambiati solo nell'ordine delle chiamate e nella base preimpostata, nessuna asserzione tolta.
- Test ripetuti: iOS 40/40 (SyncBaseline, SyncServiceFlagOff, SyncLostTransaction, E2EMigrator, RecurringRuleSync), Android 332/332 (`ANDROID_HOME=~/Library/Android/sdk` e Java 17 servono per gradle da terminale).

## S-51f · non risolto, diagnosi
Crash nei .ips `~/Library/Logs/DiagnosticReports/MoneyTracker-2026-11-27-114438.ips` e `-115008.ips`: il thread `com.apple.SwiftUI.AsyncRenderer` esegue la closure del `WindowGroup` (`MoneyTracker/MoneyTrackerApp.swift:144`) e il controllo MainActor di Swift 6 fallisce; il main thread è fermo nell'XCTWaiter del test ospitato. La pista e462c34 è smentita: la prova del 2026-11-26 20:50 (175ccb0, già con e462c34) ha passato iOS → Android nelle tre fasi. Crash dipendente dai tempi, nessuna correzione certa: proposta a Codex in PIANO (contenuto del WindowGroup in una `struct RootView: View`, poi prova reale).

## S-51b
Non ripetuta: S-51f non risolto. Resta [!].

## Fuori dai commit
Schema Xcode e `graphify-out/` erano già modificati a inizio turno: non toccati.
