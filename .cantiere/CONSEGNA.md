# CONSEGNA — impresa (Codex · GPT-6) · 2026-11-25 09:07

- S-50a è `[~]`, pronto per il collaudo del blocco 1 dopo S-50d. Il server finto implementa PK, filtri e proiezione, 409 sui duplicati, PATCH, guardia P0001, tabelle assenti e interruzione pilotata. Il payload è restituito intatto.
- `python3 -I 03_CODICE/bucktrail-android/scripts/test-fake-supabase-e2e.py`: 11 prove HTTP verdi, comprese scritture concorrenti, rifiuto atomico dei batch, payload lungo e migrazione interrotta.
- `ANDROID_HOME="$HOME/Library/Android/sdk" ./gradlew testDebugUnitTest`: verde dalla cartella Android. Ripetuto con `--rerun`: 247 test, zero errori, fallimenti o salti.
- Scelte da confermare (§6.6): `FAKE_FAIL_AFTER` conta le richieste REST di scrittura riuscite, compresa la cancellazione account. A soglia raggiunta risponde 503 anche alle letture. La PATCH conserva la PK; la DELETE richiede un filtro supportato e, per i nuovi filtri o le nuove tabelle, opera sulle righe dell'utente autenticato.
- `graphify update .` eseguito. Il grafo e il relativo backup generato in `graphify-out/` restano locali, fuori dal commit S-50a. Nessun file di altri lavori era modificato all'apertura del turno.
- Prossimo **S-50b · Crittografia iOS + vettori condivisi**, operaio su Claude Code (Sonnet). Prompt completo in `progetto-e2e-sync.md`, §10.3.
