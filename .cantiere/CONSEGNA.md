# CONSEGNA — 2026-11-26 16:32 · operaio (Claude Code · Sonnet)

- **S-50p [~].** Interruttore acceso **solo in release**: iOS `E2EFeature.swift` ramo `#else` `isEnabled = true`; Android `build.gradle.kts` release `E2E_ENABLED "true"`. Debug invariato (spento salvo `-E2EEnabled YES` / `-Pe2e=true`). **Scelta da confermare (R8):** il §10.3 dice «isEnabled = true»; tenere il debug spento era necessario perché `E2EGateTests`, `E2ECryptoTests` e `SyncServiceFlagOffTests` (test esistenti, intoccabili) verificano il caso spento in debug.
- **Sito (non pubblicato):** FAQ `#sicurezza` di `SOCIAL/landing/index.html` e `en.html`, 3° paragrafo sostituito col testo del §10.3. `privacy.html` non aveva una parte sulla sincronizzazione ed esiste solo in italiano: aggiunta una sezione «Sincronizzazione dell'app e Protezione avanzata» (solo it) e data al 26/11. Testi in `.cantiere/APPROVAZIONI.md` (⏳), istruzioni di pubblicazione in `PER-MATTEO.md`.
- **Documento:** `docs/MoneyTracker.md` v3.28 (§6 interruttore acceso, Changelog) + PDF rigenerato. Grafo aggiornato.

**Verifiche.** iOS `build test` su iPhone 18 Pro: 186 unitari (39 suite) + 57 UI, 0 fallimenti, TEST SUCCEEDED (UI ~51 min, nessuna instabilità al primo giro). Build iOS Release ok. Android `assembleDebug testDebugUnitTest lintDebug`: 323 JVM, 0 falliti, lint ok; `assembleRelease` ok con `E2E_ENABLED = true` nel BuildConfig release. Nessun test esistente toccato.

**Aperto.** Approvazione ✅ dei testi del sito e caricamento su Cloudflare (Matteo). Informativa privacy dell'app (Supabase come destinatario, versione EN) mancante: nuovo task S-50v in PIANO. Collaudo S-50p. Nessun push.
