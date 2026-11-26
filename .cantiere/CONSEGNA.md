# CONSEGNA — S-50h2 e S-50l.2

Impresa (Codex · GPT-6), 2026-11-26 09:39 · ramo `redesign-sentiero`.

- S-50h2 [!] · A7 e rollback rileggono e verificano il vault prima di cancellare in chiaro. D7 ammette solo gli ID del vault verificati contro il backup e può riprendere dopo una pulizia parziale.
- S-50h2 punto 3 · `E2EServer.swift` filtra oggi per utente, chiave e stato. La PATCH atomica richiede anche la generazione `updated_at`. `E2EGate.swift` serve per conservarla nel marcatore e riconoscere una ripresa superata. In attesa dell'autorizzazione per entrambi i file.
- S-50l.2 [~] · rimossi i due log di `E2EVerifier.swift`. Nessuna ricevuta di verifica nei log della suite.
- Collaudo sul simulatore iPhone 18 Pro, iOS 27.2 · 168 unitari e 7 UI verdi (6 E2E e 1 con interruttore spento), timeout massimo 180 s per test. Tre nuove regressioni: vault vuoto dopo A6, ID comparso dopo la verifica D7, ripresa D7 con pulizia parziale. Suite stress esistente con 20.000 movimenti verde. Risultato Xcode: `/tmp/moneytracker-s50h2.wwh6S6/final.xcresult`.
- Interruttore spento. Fuori commit: modifiche concorrenti di S-50q in `PIANO.md`, `DIARIO.md`, `PER-MATTEO.md` e `progetto-e2e-sync.md`. Grafo aggiornato localmente.

➡️ Prossimo: Matteo autorizza i due file per il punto 3, poi Codex completa S-50h2. Collaudo separato per i due task prima di S-50p.
