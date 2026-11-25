# CONSEGNA — impresa (Codex · GPT-6) · 2026-11-25 11:40

- **S-50e [~].** Vault cifrato in blocchi da 200 con AAD, verifica dell'ID interno e richieste circoscritte a utente e kind. DEK nel Keychain per utente con `AfterFirstUnlockThisDeviceOnly`. CRUD `mt_e2e` e risoluzione del gate per operazione. Il trigger di scrittura in chiaro fa rivalutare il gate.
- **Verifica iOS completa.** iPhone 18 Pro con iOS 27.2, due worker Xcode, 137 test unitari e 49 UI verdi, zero fallimenti e zero saltati. T5, T6, T12 e T14 iOS verdi. Il test aggiuntivo conferma `E2EFeature.isEnabled == false` in assenza dell'argomento `-E2EEnabled`.
- **Casi limite verificati.** Vault con 401 righe, payload rilocato, ID interno errato, riga corrotta nell'ultima parte del pull, 404 con e senza JSON, PGRST205, 42P01, 5xx, rete assente, trigger attivato fra lettura e scrittura, cambio utente e modifica locale durante la pausa. Supabase simulato con remoto in memoria o URLProtocol.
- **Scelta da confermare al collaudo.** Con il gate attivo il pull legge tutte le tabelle prima di aggiornare SwiftData, così una riga illeggibile blocca l'intera applicazione del pull. Il cambio utente interrompe la sync protetta se la pulizia lascia dati locali. La correzione della pulizia SwiftData rimane in S-50l.1.
- **Aperto.** Il gate espone la direzione di ripresa al migratore di S-50h. Collaudo del blocco 2 dopo S-50i.
- **Git.** Grafo aggiornato in locale. Le modifiche preesistenti e l'aggiornamento sotto `graphify-out/` restano fuori dal commit.
- **Prossimo.** S-50f Android, VaultApi, decoratore, Keystore e gate, secondo il §10.3 di `.cantiere/progetto-e2e-sync.md`.
