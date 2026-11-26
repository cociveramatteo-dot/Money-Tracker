# CONSEGNA — S-50q.1 client

Impresa (Codex · GPT-6), 2026-11-26 10:50 · ramo `redesign-sentiero`.

- **S-50q.1 [~]** · Annullamento esplicito, ripresa del rollback e rollback automatico su iOS e Android passano da `POST /rest/v1/rpc/mt_e2e_rollback` con `p_key_id` e `p_generation`. Il percorso di rollback usa la sola RPC per le mutazioni remote. `bt_e2e_state_changed` e `bt_e2e_use_rollback` fanno ricalcolare la modalità con il gestore esistente. Se A6 vince, il ramo di rollback si arresta prima di rimuovere la chiave locale.
- **Gara nel server finto** · A6 seguito da rollback conserva stato attivo e vault. Rollback seguito da A6 lascia assenti stato e righe della chiave, preservando altre chiavi e utenti. Le richieste HTTP simultanee ammettono un solo vincitore. Una DELETE diretta di `mt_e2e` in `migrating` restituisce 400 `bt_e2e_use_rollback`. I test client verificano anche payload esatto e ripresa dopo un errore della RPC.
- **Verifiche** · 173 unitari iOS sul simulatore iOS 27.2 con timeout di 180 s per test, 313 JVM Android e `lintDebug`, 19 HTTP del server finto. Log e risultato iOS in `/tmp/moneytracker-s50q1.lfWt3s/`. Interruttori spenti. Il grafo aggiornato e le modifiche preesistenti in `graphify-out/` restano fuori dal commit.
- **Aperto** · Collaudo indipendente del diff client prima di S-50p. Lo SQL §6.9 era già stato applicato da Matteo alle 10:40.

➡️ **Prossimo: S-50q.1** → collaudatore su Claude Code (Sonnet). Verificare nel diff entrambi i migratori, il ricalcolo quando A6 vince e gli esiti dei due ordini di gara rispetto al §6.9, poi registrare l'esito in PIANO. Lasciare spenti gli interruttori.
