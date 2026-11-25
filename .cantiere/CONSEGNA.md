# CONSEGNA — S-50k · Protezione avanzata Android

Turno chiuso il 2026-11-25 22:26 da impresa (Codex · GPT-6), ramo `redesign-sentiero`.

- S-50k [~]. Otto schermate Compose con tema Sentiero, riga in Sicurezza per l’account supportato e prompt di sblocco una volta per sessione. Il cablaggio esistente costruisce il controller solo con `BuildConfig.E2E_ENABLED`. Il debug standard e la release hanno il flag spento. Le prove E2E hanno usato solo `-Pe2e=true` e Supabase finto.
- T15: 49 chiavi `e2e_*` e testi identici a iOS in it, en, de, es, fr, ja e zh-Hans. `assembleDebug lintDebug testDebugUnitTest` verde con 301 JVM, zero errori lint e 215 avvisi. `connectedDebugAndroidTest` verde con 10 test eseguiti e quattro scenari E2E locali provati separatamente. Undici test Python del server finto verdi.
- T16: cinque giri Compose verdi su Bucktrail API 36, italiano e inglese chiaro/scuro e tedesco scuro al 135%. Verificati frase corta e diversa, conferma dell'ultimo gruppo, stato attivo, dialogo di disattivazione, frase di sblocco errata e prompt unico. Cinque prove mirate dell’avanzamento verdi. Sessantadue screenshot in `.cantiere/tmp/e2e-android/screenshots/` e `/tmp/e2e-android/`.
- T18: interruzione a `FAKE_FAIL_AFTER=5` subito dopo la creazione della migrazione, forza arresto e riavvio. Prima della ripresa un movimento in chiaro e zero movimenti nel vault. Dopo la ripresa e un nuovo movimento, nessuna riga nelle cinque tabelle in chiaro e due movimenti `bt1.` nel vault. Esito HTTP e log in `.cantiere/tmp/e2e-android/`.
- Il server finto ora rispetta i filtri di generazione e le risposte `return=representation` di PATCH/DELETE. La lettura di stato destinata alla UI dopo un errore conserva chiave e marcatore, come verificato dal test JVM di interruzione A2.
- Scelte da confermare: il contatore mostra le tappe del migratore. Android contrassegna come sensibile la copia della chiave quando il sistema lo supporta. Il ripristino distruttivo è disponibile soltanto per un account bloccato che richiede il segreto. I dialoghi sono stati provati sull’emulatore, l’autenticazione biometrica o PIN resta da verificare su dispositivo nel collaudo.
- Grafo aggiornato. I file del grafo già modificati, screenshot e log locali restano fuori dal commit. Nessun push. D-014: approvazione in S-50o prima dell’accensione. S-50h2 e S-50q restano obbligatori prima di S-50p.

➡️ Prossimo: S-50l · uscita, eliminazione account, cambio utente e stress → capocantiere/operaio Claude Code (Sonnet), secondo il piano. Poi serve il collaudo del blocco 3.
