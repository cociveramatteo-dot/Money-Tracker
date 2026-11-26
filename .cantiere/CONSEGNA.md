# CONSEGNA — collaudo S-50q.2

Collaudatore (Claude Code · Sonnet), 2026-11-26 11:54 · ramo `redesign-sentiero` · diff 2322ed6 (Codex).

- **S-50q.2 [x] collaudo ok.** Pull normale iOS (`VaultRemote` con `scopeReads: true`) e Android (`VaultSupabaseApi` sempre con `key_id`) legge solo la chiave viva, e prima di applicare lo snapshot controlla che la chiave sia ancora `active` (iOS `hasActiveVaultKey`, Android `validatePull`). Pulizia `clearDeadVaultKeys` in `migrating` dopo A5: solo DELETE con `key_id=eq.<chiave morta>` (+ id, kind, user_id), salta la chiave viva; il guard §6.9 la ammette, `mt_e2e_activate` conta per key_id quindi un residuo non fa fallire A6. iOS: `wrongKey` = stato cambiato → ricalcolo del gate. Log dei digest backup rimossi su entrambi. Android: tolto `requireEmptyVaultWhileOff` (ora uguale a iOS). Nessun file Auth/. Interruttori spenti in release.
- **Test.** 175 unitari iOS verdi (timeout 180 s; E2EDeadVaultKeyTests 136 s, entrambe le varianti con pulizia riuscita/fallita), 6/6 UI E2EUITests (testActivationRetriesAfterNetworkLoss rosso due volte per simulatore lento, «no process ID» e focus tastiera, verde alla terza: load average ~60), 315 JVM + lintDebug, 19 test server finto.
- **Aperto S-50q.4** (BASSA, non blocca S-50p): se la pulizia fallisce le righe morte restano finché non si riattiva; proposto ritentativo in D7 o dopo una pull riuscita.
- Simulatori spenti, colima spento. Le modifiche locali di `graphify-out/` restano fuori dal commit.

**Prossimo** — S-50m (Commissione Suprema + manuale), capocantiere/operaio.
