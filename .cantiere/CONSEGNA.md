# CONSEGNA — collaudo blocco 3 (S-50j, S-50k, S-50l, S-50l.1)

Collaudatore (Claude Code · Sonnet), 2026-11-26 00:47. Esito: tutto [x].

- Flag spento: iOS `E2EFeature.isEnabled` è `false` in release, harness e fixture solo DEBUG; Android `E2E_ENABLED` è falso senza `-Pe2e`. Nei percorsi a flag spento restano modifiche volute: isolamento utente nel push/pull (`ownsPlainStore`) e cancellazione locale per istanze (S-50l.1).
- Test rieseguiti: iOS unitari 165 verdi (33 suite); UI generali iOS 49 eseguite, 45 verdi al primo giro, 4 cadute per perdita di connessione col simulatore (testHiddenBalances, testItalian, testThresholdPresentation, SentieroPlanningUITests/testDark) verdi alla riprova; Android 311 JVM e lint verdi (rieseguiti con cleanTest). Prove UI E2E (6): fidato il log di Codex.
- S-50l.1: il test (4 varianti) fallisce prima del fix (batch delete rifiutato su Transaction/account) e passa dopo.
- i18n: 49 chiavi `e2e_*` uguali in 7 lingue su iOS e Android e tra le due piattaforme, placeholder coerenti.
- Difetti: S-50l.2 (bassa) log dei digest in E2EVerifier. Estetico: titolo DE a font XL spezzato a metà parola su Android (per S-50o).
- Prerequisiti di S-50p: S-50h2, S-50q, S-50l.2, S-50n, S-50o. Scelta di Codex sull'errore di trasporto della RPC (si conservano i dati locali): condivisa, nessuna modifica.

➡️ Prossimo: S-50h2 → Codex (difetti blocco 2), poi S-50l.2.
