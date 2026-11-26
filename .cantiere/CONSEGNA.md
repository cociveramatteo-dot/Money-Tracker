# CONSEGNA — 2026-11-26 17:09 · impresa (Codex · GPT-6)

- **S-50u [~]** · `2c313aa`. Il filtro `key_id=neq.<chiave viva>` limita la select della pulizia su iOS e Android. Le DELETE mantengono `key_id=eq.<chiave morta>`. Il server finto applica il filtro. Due nuovi test controllano le richieste HTTP.
- **S-50w [~]** · APK release minificato R8, firmato con chiave di debug, su AVD API 36. Attivazione completata, sync cifrata di un conto e due spese, frase errata rifiutata e sblocco con la frase corretta dopo `pm clear`. Le due spese sono ricomparse in UI. La disattivazione con PIN ha svuotato il vault e riportato conto e spese nelle tabelle ordinarie. L'accesso HTTP al server finto era configurato solo nella copia temporanea di build. Regole R8 esistenti sufficienti.
- **Verifiche** · iPhone 18 Pro, build e 187 unitari verdi. Su 8 UI selezionati, 6 verdi al primo giro e 2 ai rilanci isolati. Android debug, build, lint e 324 JVM verdi. Fake Supabase, 19 test verdi. Comandi ed esiti nel PIANO.
- **Perimetro** · La prova release ha usato emulatore, dati sintetici e server finto. Dispositivo fisico, Supabase reale e pubblicazione restano fuori dal perimetro. I due errori UI iOS del primo giro riguardavano l'abilitazione del pulsante di conferma della chiave e la chiusura del popover di uscita.
- **Grafo** · `graphify update .` riuscito. Il grafo ha 5.825 nodi, sopra il limite del visualizzatore HTML. Graphify ha segnalato 18 file senza nodi estratti. Output generato fuori dai commit.

## File del turno

- `MoneyTracker/Sync/E2E/VaultRemote.swift`
- `MoneyTrackerTests/E2EObsoleteVaultFilterTests.swift`
- `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/sync/SupabaseApi.kt`
- `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/sync/e2e/VaultApi.kt`
- `03_CODICE/bucktrail-android/app/src/test/java/com/bucktrail/android/sync/e2e/ObsoleteVaultFilterTest.kt`
- `03_CODICE/bucktrail-android/scripts/fake-supabase.py`
- `.cantiere/PIANO.md`, `.cantiere/DIARIO.md`, `.cantiere/CONSEGNA.md`, `.cantiere/STATO.md`

Modifiche SOCIAL già in lavorazione dal redattore all'inizio del turno escluse dai commit dell'impresa.

**Prossimo** · Collaudo S-50u e S-50w.
