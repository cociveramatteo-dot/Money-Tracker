# CONSEGNA — S-50g2 e S-50z (Guardiano + Script release R8 Android)

## Cosa è stato fatto

1. **S-50g2 · Guardiano: ignorare il CORS locale del beacon Cloudflare Insights (`8c0b06e`)**
   - **Problema trovato:** il filtro aggiunto il 2026-11-26 in `.cantiere/strumenti/guardiano/giro.mjs` filtrava solo `p.on("console", ...)`, lasciando attivo `p.on("requestfailed", ...)` su `https://cloudflareinsights.com/cdn-cgi/rum` (`net::ERR_FAILED`), che continuava a far fallire il guardiano in rosso (`🔴`, 56 errori / 7 `errore-console`).
   - **Modifica minima in `.cantiere/strumenti/guardiano/giro.mjs`:**
     - Calcolato `inLocale = /^https?:\/\/(127\.0\.0\.1|localhost)(:\d+)?$/i.test(BASE)`.
     - In `p.on("console", ...)`: ignora i messaggi `cloudflareinsights.com` solo quando `inLocale` è vero e il testo contiene `CORS`.
     - In `p.on("requestfailed", ...)`: ignora `https://[*.]cloudflareinsights.com/cdn-cgi/rum` con `ERR_FAILED` solo quando `inLocale` è vero.
     - Nessun merge su `main` effettuato (serve l'ok di Matteo).

2. **S-50z · Script ripetibile per la prova E2E release Android R8 (`d0dd4e3`)**
   - Creato `03_CODICE/bucktrail-android/scripts/prova-release-r8.py` (eseguibile, stile `prova-due-dispositivi.py` / `test-fake-supabase-e2e.py`, zero chiavi vere e zero puntamenti al Supabase reale).
   - Lo script:
     1. avvia `scripts/fake-supabase.py` su porta libera con `FAKE_LATENCY=0.05` (log HTTP salvato nella cartella temporanea);
     2. copia `03_CODICE/bucktrail-android` in una directory temporanea (lasciando intatto `app/src/main` e senza lasciare `app/src/release` nel repo), abilita HTTP verso `10.0.2.2` solo nella copia temporanea, esegue `./gradlew assembleRelease -PsupabaseUrl=http://10.0.2.2:<porta> -PsupabaseKey=chiave-finta`, verifica la presenza di `mapping.txt` (R8) e firma/verifica l'APK con `~/.android/debug.keystore`;
     3. crea e avvia un AVD temporaneo isolato (`Bucktrail_S50z`, `system-images;android-36;default;arm64-v8a`), installa l'APK e imposta il PIN di sistema `2468`;
     4. esegue il flusso E2E completo di S-50w: login `demo@test.it`, creazione conto e prima spesa in chiaro, attivazione Protezione avanzata (`mt_e2e_activate` 204, vault `bt1.`), seconda spesa cifrata (`2` movimenti `bt1.`, tabelle in chiaro vuote, `GET` di pulizia `key_id=neq.`), `pm clear` + rilancio e sblocco (frase errata rifiutata, corretta accettata, entrambe le spese presenti), disattivazione con PIN `2468` (ripristino in chiaro, `mt_e2e`/`mt_vault` vuote) e controllo `logcat` (zero crash di `com.bucktrail.android`);
     5. nel blocco `finally` chiude sempre emulatore (`adb emu kill` + terminate/kill), server finto e directory temporanea.
   - Aggiunte le istruzioni d'uso in `03_CODICE/bucktrail-android/README.md`.

## Verifiche eseguite

- **S-50g2 (numeri prima e dopo in locale su `SOCIAL/landing`):**
  - *Baseline storico (`.cantiere/guardiano/ULTIMO.md`, 2026-11-26, senza filtri):* 4 pagine × 8 dispositivi · **64 errori**, 8 avvisi · 13 problemi distinti (**`errore-console` ×8**, `accessibilita` ×3, `link-dubbio` ×1, `link-irraggiungibile` ×1) · semaforo `🔴`.
  - *Prima della correzione di oggi (2026-11-27 19:00:34, solo filtro `console`):* 7 pagine × 8 dispositivi · **56 errori**, 7 avvisi · 11 problemi distinti (**`errore-console` ×7** per `richiesta fallita: https://cloudflareinsights.com/cdn-cgi/rum (net::ERR_FAILED)`, `accessibilita` ×3, `link-irraggiungibile` ×1) · semaforo `🔴`.
  - *Dopo la correzione (`8c0b06e`, 2026-11-27 19:06:30, comando `GUARDIANO_PRECEDENTE=/tmp/guardiano-prec bash .cantiere/strumenti/guardiano/esegui.sh`):* 7 pagine × 8 dispositivi · 57 link · 159 clic · monkey 20 giri · **0 errori**, 7 avvisi · 4 problemi distinti (`accessibilita` ×3 `heading-order`, `link-irraggiungibile` ×1 YouTube `Header overflow`) · **0 `errore-console`** · semaforo `🟡` (nota macOS: `esegui.sh:62` salta Lighthouse locale per bash 3.2 `PRESET[@]: unbound variable`, non toccato).
  - *Verifica errore console finto su copia temporanea (`console.error("S50G2_TEST_CONSOLE_ERROR")` in `index.html`, `--monkey 0`):* 7 pagine × 8 dispositivi · **16 errori**, 7 avvisi · 6 problemi distinti (**`errore-console` ×2** su `/` e `/index.html`) · `riassunto.mjs` exit code `1` · semaforo `🔴`.
- **S-50z (`python3 03_CODICE/bucktrail-android/scripts/prova-release-r8.py` su `d0dd4e3`):**
  - Eseguito per intero end-to-end: exit code `0`, output finale `PROVA R8 S-50z VERDE` (tutti i 6 controlli `OK`, 0 crash in `logcat`, zero residui su `adb devices` o `/tmp/bucktrail-r8-*`).
- **Zone vietate e stato locale:**
  - Nessuna modifica a codice iOS o `03_CODICE/bucktrail-android/app/src/main/`.
  - `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` era già modificato in locale prima del turno (non toccato né committato, come da `CHECKPOINT.md`).

## Prossimo turno

Collaudatore su S-50g2 (`8c0b06e`) e S-50z (`d0dd4e3`).
