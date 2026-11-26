# CONSEGNA — S-50q.2

Impresa (Codex · GPT-6), 2026-11-26 11:28 · ramo `redesign-sentiero`.

- **S-50q.2 [~].** Il pull iOS e Android legge le righe della chiave viva. Prima di applicare lo snapshot cifrato, i client controllano che la chiave sia ancora attiva. Su iOS `wrongKey` rivaluta il gate.
- **Riattivazione.** Durante `migrating`, dopo la verifica della nuova copia, i client cancellano le righe obsolete con DELETE per singola chiave, tipo e ID. Un guasto alla pulizia lascia che sync e riattivazione proseguano. La pulizia si ripete alla riattivazione successiva.
- **Regressioni.** D7 interrotto, eliminazione in chiaro, riattivazione su un secondo dispositivo, rimozione del residuo e pull di nuovo operativo. Verificato anche il pull quando il residuo resta. Rimossi i log dei digest degli ID di backup nei due migratori.
- **Verifiche.** 175 unitari iOS con timeout di 180 s per test, incluso lo stress test da 20.000 movimenti. 315 unitari JVM Android e `lintDebug` (0 errori, 215 avvisi e 8 suggerimenti nel rapporto preesistente). 19 test HTTP del server finto verdi. Log in `.cantiere/tmp/s50q-2/`.
- Interruttori spenti su iOS e Android. S-50q.3 resta chiuso secondo DECISIONI. Le modifiche locali di `graphify-out/` sono fuori dal commit.

**Prossimo** — collaudatore su Claude Code (Sonnet), S-50q.2 prima di S-50p. Verificare il diff, il filtro in lettura e cancellazione, il ricalcolo iOS e le regressioni D7.
