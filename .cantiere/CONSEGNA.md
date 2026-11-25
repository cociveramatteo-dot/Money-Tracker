# CONSEGNA — collaudatore (Claude Code · Sonnet) · 2026-11-25 11:10

- **Collaudo blocco 1 (S-50a…d): PASSA.** S-50a…d segnati `[x]` in PIANO.
- Perimetro: nessun test o fake esistente modificato (solo `fake-supabase.py` estero a S-50a, `build.gradle.kts`, `SyncService.swift` come previsto). Il resto è nuovo.
- `PlainRemote`: stesse richieste SDK, filtri e corpi del codice precedente, stesso ordine in push/pull/login/orfani. E2E spento (iOS: solo DEBUG con `-E2EEnabled YES`; Android: `E2E_ENABLED` false in release, true in debug solo con `-Pe2e=true`).
- Fixture `e2e-vectors-v1.json` identica byte per byte (Android è un link simbolico). Nonce casuali in produzione (SecureRandom / AES.GCM.Nonce()), fissi solo nelle API di test. Nessuna libreria nuova, nessun log nei file E2E.
- Rieseguiti: python fake (11 ok), vettori `--check` ok, Android `testDebugUnitTest lint` ok, iOS unit `-only-testing:MoneyTrackerTests` ok. UI test non rieseguiti (già verdi in CONSEGNA di S-50d).
- Nota: il commit f4bfd7a e le modifiche ad AGENTS.md / skill assegna non fanno parte del blocco.
- Prossimo: S-50e a Codex.
