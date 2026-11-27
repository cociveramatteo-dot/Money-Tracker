# CONSEGNA — 2026-11-27 13:34 · collaudatore (Claude Code · Sonnet)

## Collaudo completato [x]

- **S-51g** · `8aa349e` ok. Con remoto senza conti, il pull resta saltato se nessun conto locale è nella base: il primo login, il ripristino e il cambio di utente sono protetti. Altrimenti cancella i conti noti e conserva quelli in attesa del primo push, con i loro movimenti e budget. iOS e Android sono simmetrici.
- **S-51e** · `dd09649` ok. Il preflight della disattivazione usa la base del vault. Senza base non cancella nulla e carica le righe locali mancanti. Nessun file SQL né migrazione cambiati.
- **S-51h** · `d0f1aab` ok. Quattro righe prima del conteggio, con asserzioni e valore atteso invariati.

## Verifiche ripetute

- Build Debug iOS e 46/46 test mirati in sei suite: SyncBaseline, SyncServiceFlagOff, SyncLostTransaction, E2EMigrator, RecurringRuleSync, E2EStress. Test t10 verde in tre ripetizioni consecutive, due con Gradle in parallelo.
- Android `testDebugUnitTest --rerun-tasks` (Java 17): 334/334, risultati freschi delle 13:32.
- Prova reale non rilanciata. Il riassunto 12/12 in `/tmp/mt-s51-verify/live.log` coincide con CONSEGNA (exit 0).

## Rischio residuo (accettato, nessun task)

Se il server restituisse per errore zero conti con una risposta valida, iOS e Android cancellerebbero in locale i conti noti. La base diventa vuota, quindi il push non cancella nulla sul server e il pull successivo li riporta.

## Fuori dal commit

Lo schema Xcode e `graphify-out/` contengono modifiche locali precedenti al turno.

## Prossimo

S-70 → Codex (progetto `.cantiere/progetto-s70-doppio-tap-simulazione.md`).
