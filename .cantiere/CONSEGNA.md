# CONSEGNA — 2026-11-26 16:37 · collaudatore (Claude Code · Sonnet)

- **S-50p [x] collaudo ok** (commit 36bf711). iOS: `E2EFeature.swift` ramo `#else` `isEnabled = true`; la configurazione Release non ha `DEBUG` e lo schema usa Release per Archive e Profile. Android: BuildConfig generato release `E2E_ENABLED = true`, debug `false`. Debug spento salvo `-E2EEnabled YES` / `-Pe2e=true`: scelta corretta (i test intoccabili `E2EGateTests`, `E2ECryptoTests` e `SyncServiceFlagOffTests` richiedono il caso spento; store e TestFlight sono Release). Nessun altro percorso cambiato.
- **Sito:** FAQ `#sicurezza` it/en identiche al §10.3, privacy conforme al §10.3, HTML ben formato, ancore ok. Non pubblicato.
- **Verifiche rilanciate:** iOS MoneyTrackerTests 186/186 su iPhone 18 Pro; Android `testDebugUnitTest --rerun-tasks` 323 JVM, 0 falliti (serve `ANDROID_HOME=~/Library/Android/sdk`: senza, gradle fallisce con «SDK location not found»).
- **Nota:** il commit 36bf711 include anche `.cantiere/progetto-s70-doppio-tap-simulazione.md` (non dell'operaio, innocuo).

**Aperto.** ✅ dei testi del sito e pubblicazione (Matteo, PER-MATTEO). Suggerito prima del ✅: nella privacy aggiungere «dimensione approssimativa dei dati e indirizzo IP» tra ciò che resta visibile (§1.3). Prova del flusso E2E su un APK release minificato (R8) mai eseguita. S-50v.
