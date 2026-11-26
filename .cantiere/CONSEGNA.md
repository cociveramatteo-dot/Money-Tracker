# CONSEGNA — 2026-11-26 14:55 · Collaudatore (Claude Code · Sonnet)

**S-50r [x] · collaudo ok**

- Diff `c8e89c8`: `VaultRemote.select/upsert` decifrano/cifrano in `Task.detached` tramite `nonisolated static decodeRows/encodeRows`, con soli valori Sendable (VaultRecord, SymmetricKey, UUID, String, ArraySlice<Row: Sendable>). Nessun `@unchecked`. Logica, errori e batch sequenziali invariati. Test esistenti non toccati.
- Suite iOS completa (iPhone 18 Pro, iOS 27.2): 185 unitari verdi; UI 55/57 al primo giro. `E2EUITests/testActivationRetriesAfterNetworkLoss` (riga 208, conferma chiave, prima di qualsiasi upsert) e `SentieroAccountsUITests/testHiddenBalances` (perdita di testmanagerd) verdi in 2 riesecuzioni: instabilità del simulatore, non regressione.
- Nessun warning di concorrenza Swift nel log di build.

**Prossimo** · S-50p (accensione interruttore + FAQ e privacy), capocantiere/operaio.
