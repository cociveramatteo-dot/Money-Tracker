# CONSEGNA — S-21 / S-22

**Da:** seconda impresa (Codex · GPT-6), 2026-11-14 11:15.

- S-21 [~]: `resolve` fuori dal rendering delle righe; nel menu viene eseguito in `onAppear`, al tap/eliminazione resta nelle azioni. Cache di presentazione con una sola finestra: invalidazione su tutti gli input dello snapshot, intervallo e fuso; virtuali calcolati una volta per mese e filtrati senza rigenerarli, prossima occorrenza riusata fino al cambio degli input/giorno. Force unwrap di `resolve` e della card sostituiti con `guard`.
- S-22 [~]: estratti `ProgrammedRuleCard`, `VirtualOccurrenceRow` e `RecurrencePresentationCache` in Views/. Stessi testi, stili, ordine, identificatori e callback. Domain, modelli, sync e test esistenti intatti.
- Verifica finale: build + 68 unit + 1 UI verdi (`TEST SUCCEEDED`), anche dopo la modifica definitiva del menu. Log `/tmp/moneytracker-s21-s22.log`.
- Grafo aggiornato con `graphify update .`. Le modifiche a `graphify-out/` erano già presenti all'ingresso: lasciate fuori dal commit per non inglobare lavoro altrui (anche backup `graphify-out/2026-11-14/`).
- Prossimo: collaudatore su Claude Code (Sonnet), leggere il diff del commit S-21/S-22. Controllare invalidazione cache, menu dopo pressione prolungata (Ricorrenza/Elimina), fallback di modifica delle serie terminate e invarianza visiva. Il test UI esistente copre creazione/modifica/eliminazione dalla card, non il menu contestuale.
- Restano S-19 e S-18, poi Commissione S-13h e checkpoint; nessun push/tag/merge.
