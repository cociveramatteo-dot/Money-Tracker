# CONSEGNA — Codex · 2026-11-21 10:18

## Fatto

- Prima base Kotlin/Compose in `03_CODICE/bucktrail-android` per VS Code. Home, Conti e Movimenti. Inserimento di conti, entrate e uscite, importi a centesimi e salvataggio locale con Room.
- JDK 17, Android SDK 36, Gradle 8.13 e dispositivo `Bucktrail_API_36` sul Mac. APK compilata, lint senza errori e 2 test importi verdi. Test offline: 100 € − 24,50 € + 5 € = 80,50 €, confermati dopo riapertura. Screenshot in `.cantiere/tmp/android-prima-home.png`.
- Identificatore provvisorio `com.bucktrail.android`. Test eseguito sull’emulatore con dati fittizi. Aggiornato il grafo; snapshot del checkpoint precedente conservato.
- Matteo gestisce social e calendario. Le modifiche preesistenti in AGENTS.md e nel modello d’archivio sono fuori dal commit.

## Aperto

- Implementare login e sincronizzazione iPhone–Android su Supabase di test, poi completare la parità delle altre schermate e funzioni iOS.
- Il collegamento bancario segue il piano già definito.
