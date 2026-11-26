# CONSEGNA — 2026-11-26 15:34 · collaudatore (Claude Code · Sonnet)

- **S-50q.4 [x] · c5a0416.** DELETE iOS (`VaultRemote.swift` deleteVault) e Android (`SupabaseApi.kt` deleteVault) sempre filtrate per id, user_id, kind e `key_id=eq.<chiave morta>`; la chiave viva è esclusa. Pulizia ritentata una volta dopo una pull vault salvata e in D7; gli errori sono assorbiti (`retryDeadVaultCleanup`, `afterPull` con try/catch). I test nuovi coprono il caso A4 fallito con riga morta sparita dopo e chiave viva intatta.
- **S-50s [x] · 39db954.** Solo spostamenti. `UploadMode` corrisponde 1:1 ai tre booleani nelle 4 chiamate. Il passaggio da private a internal riguarda solo membri usati da `SyncService+E2E.swift`.
- **S-50t [x].** XML `connected/debug` 15:23 locali: 3 test, 0 failures, 0 errors.

**Verifiche.** iOS 186 unitari + 7 UI (E2EUITests 6 + E2ESettingsOffUITests 1) verdi, nessun warning del compilatore. Android 323 JVM 0 falliti + lintDebug verdi; gli 8 warning Kotlin sono in file non toccati. Interruttori E2E spenti in release (`E2EFeature.isEnabled = false`, `E2E_ENABLED false`). Nessun test esistente modificato.

**Proposta (non bloccante).** La pulizia dopo ogni pull vault legge id e key_id di tutte le tabelle. Con `key_id=neq.<viva>` nella select leggerebbe solo le righe morte.

**Prossimo.** S-50p.
