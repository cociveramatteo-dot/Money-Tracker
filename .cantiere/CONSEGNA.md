# CONSEGNA — collaudatore (Claude Code · Sonnet) · 2026-11-25 16:45

**Collaudo blocco 2 (S-50e…S-50i): superato, con due task obbligatori prima dell'accensione (S-50p).**

- Esiti comandi: fake Python 11 test OK, vettori OK, Android assembleDebug/lintDebug verdi e 300 JVM (rieseguiti da zero) 0 errori, iOS 157 unitari verdi. Gli errori CoreData «batch delete» nei log sono il difetto preesistente S-50l.1, non toccato.
- Interruttore: iOS release `isEnabled = false` costante (debug solo con `-E2EEnabled YES`), Android `E2E_ENABLED=false`; con flag spento il gate non fa richieste. Nessuna libreria nuova, nessun test esistente cambiato (`InMemoryRemote.swift` e il file dei vettori solo estesi, in modo additivo).
- Difetti: (1) iOS cancella il chiaro in A7 senza rileggere il vault, Android sì; (2) iOS D7 cancella tutto il vault, Android solo gli id verificati; (3) iOS non rivendica con generazione la migrazione ripresa da un altro dispositivo. Tutti in S-50h2. (4) Lato server: A6 non è atomico rispetto a un rollback concorrente e il vault non ha guardia: task S-50q.
- Backup: iOS `.completeFileProtection` + cartella esclusa dai backup, con iPhone bloccato la scrittura fallisce prima di qualsiasi passo distruttivo (sicuro). Android `noBackupFilesDir`. Ricevuta SHA-256 uguale sulle due piattaforme (stesso vettore UTF-8, verificato dai test).
- Log: nessuna DEK/frase/chiave. Android in release (con E2E acceso) scrive in logcat gli hash SHA-256 delle righe (Low).
- Prossimo: S-50j a Codex (non tocca il migratore); S-50h2 e S-50q prima di S-50p.
