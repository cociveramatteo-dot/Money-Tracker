# CONSEGNA — S-50h2 e client S-50q

Impresa (Codex · GPT-6), 2026-11-26 10:21 · ramo `redesign-sentiero`.

- **S-50h2 [~]** · Lo sblocco usa una PATCH condizionata alla generazione precedente. Il marcatore conserva la generazione acquisita. Una ripresa superata non può avanzare, annullare o scrivere usando la generazione vecchia.
- **S-50q [~]** · iOS e Android includono `key_id` negli upsert del vault e in ogni DELETE client. La cancellazione dell’account usa la cascata della RPC esistente. A6 invia generazione precedente, successiva e conteggi verificati per tipo a `mt_e2e_activate`. I cinque errori di transizione fanno ricalcolare la modalità. Il server finto emula i trigger e la RPC.
- **Verifiche** · 172 unitari iOS sul simulatore iPhone 18 Pro iOS 27.2, timeout 180 s per test. 312 test Android JVM e `lintDebug` verdi. 15 test HTTP del server finto verdi, inclusi i tre casi §6.7. Esiti in `/tmp/moneytracker-s50q.PKV1nm/`. I due interruttori sono spenti. Grafo aggiornato localmente.
- **S-50q.1 blocca S-50p** · Il test locale con PostgreSQL 16 ha eseguito lo SQL del §6.7 e usato un trigger di sola attesa per fermare A6 dopo i conteggi. In una seconda sessione un DELETE di rollback con la chiave viva ha rimosso la riga mentre la prima transazione teneva il lock sui metadati. Dopo entrambi i commit, `mt_e2e.state = active` e il vault aveva 0 righe. Traccia in `/tmp/moneytracker-s50q.PKV1nm/sql-race.log`. Lo SQL applicato da Matteo resta quello del commit `3b78ca7`. Il server finto copre il rollback prima dei conteggi, come richiesto dal §6.7.

➡️ Prossimo: **S-50q.1** → architetto/capocantiere. Concordare con Matteo la correzione SQL prima dell’applicazione su Supabase, poi collaudare client e concorrenza A6/rollback prima di S-50p.
