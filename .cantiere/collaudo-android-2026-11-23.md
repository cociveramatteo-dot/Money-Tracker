# Collaudo Android — 2026-11-23

Codice: `03_CODICE/bucktrail-android`, commit d934e5b..0ec9d96 (127 file, +13.002/-313). Collaudatore: Claude Code (Sonnet).

## Esito per blocco

| Blocco | Esito | Note |
|---|---|---|
| Gate (1) | OK | `assembleDebug assembleRelease lintDebug testDebugUnitTest` BUILD SUCCESSFUL; test rilanciati da zero (`cleanTestDebugUnitTest`): 247 test, 0 falliti, 0 saltati. Lint: 0 errori (219 segnalazioni già note, warning/hint). APK release 5,1 MB (non firmato, R8 attivo) |
| B0 fondamenta, B1 dati/dominio | OK | `Amounts.parse` identico a `Decimal.parseAmount` iOS (stessa regex, `,`→`.`, HALF_UP a 2 decimali); `Balance` identico a `AccountBalanceCache` (iniziale + fatti / + tutti, `signedAmount`); BalanceTrail, ricorrenze, materializer, editor serie, detector, classificatore: porting dei test iOS passano |
| B2–B3 conti, impostazioni, movimenti | OK | schermate prese in demo sull'emulatore; saldo, elenco, pianificati, totali giorno coerenti |
| B4 Home | OK | saldo 21.973,16 €, atteso 21.511,76 €, 4 pianificati −461,40 € (S-41), come nei verbali di parità |
| B5 ricorrenze, B6 Pianifica | OK | budget 74%, soglia 80%, sforato; test di dominio verdi |
| B7 Statistiche/Export | OK | Uscite 1.661,98 / Entrate 2.852,75 / Netto 1.190,77; CSV/JSON round-trip testati (`ExportRoundTripTest`, `ExportsTest`) |
| B8 notifiche, blocco, audit, demo | OK (codice+test) | modalità demo a schermo con pillola; notifiche/biometria non provate su dispositivo |
| B9 Auth/Sync | OK (test JVM) | 73+ test con Supabase finto; nessuna prova sul cloud reale |
| B10 widget/scorciatoie | OK (test JVM) | non riprovati a schermo |
| B11 i18n/accessibilità | OK | 512 chiavi in 7 lingue (verbale precedente); lint `HardcodedText` 0 |

## Emulatore `Bucktrail_API_36` (modalità aereo, nessun account)
APK debug installato, dati puliti (`pm clear`), permesso notifiche negato, demo attivata dalle Impostazioni. Provati: Home, Transazioni, Statistiche, Pianifica (Budget), Conti, Impostazioni, tema scuro (`cmd uimode night yes`) e font 1,6× su Home e Pianifica. Nessun crash né ANR nel logcat (`FATAL EXCEPTION`/`ANR in` = 0). Layout corretto anche a 1,6× (importi che vanno a capo, tab «Transacti…» abbreviata, nessun testo sovrapposto agli importi; il testo «Recent transactions» passa sotto la barra di navigazione di sistema nello scorrimento, comportamento normale). Stato dell'emulatore ripristinato (tema chiaro, font 1,0, rete attiva).

## Release e Supabase reale
- Nei test unitari le sole connessioni sono verso `127.0.0.1` (server locale in `HttpSupabaseApiTest`, `HttpHostileServerTest`): mai il cloud. `androidTest` non contiene URL.
- URL e chiave si leggono da `SupabaseConfig.swift` (iOS) **se non si passa** `-PsupabaseUrl/-PsupabaseKey`: quindi debug e release, per costruzione, puntano al Supabase reale. Le prove in questo collaudo sono state fatte senza account e in modalità aereo, quindi nessuna richiesta è partita. Il rischio resta per chi fa `installDebug` e poi accede con un account vero.
- Guardia anti-cancellazione (`DeletionGuard`, `SyncEngine.pushDetailed`): DB locale vuoto o sotto metà dell'ultimo stato sincronizzato (base ≥ 10) → nessuna scrittura né cancellazione, richiede conferma. `SyncGuardsTest` (9 test: DB vuoto, calo anomalo, cancellazioni normali non bloccate, login con sessione ripresa, righe remote assurde ignorate, conto assurdo, conteggio dopo il pull) tutti verdi. Controllo dal codice: il conteggio di cancellazioni si calcola prima di qualsiasi upsert/delete, quindi nessuna scrittura parziale.

## Difetti
Corretti: nessuno (nessun difetto piccolo trovato, nessun file Android modificato).

Aperti (piccoli, proposte, non toccati):
1. Il testo della demo nelle Impostazioni cita ancora «MoneyTracker» («Utile per mostrare MoneyTracker ad amici…»), mentre il resto dell'app dice Bucktrail. Da verificare nelle 7 lingue (stringa `settings_demo_*`).
2. Debug e release usano il Supabase reale se non si passa `-PsupabaseUrl`: proposta di far puntare il debug a un URL finto di default (cambia il flusso di lavoro, quindi proposta).
3. Non verificati a schermo: alert «Eliminare i dati dal cloud?», biometria/PIN, notifiche, widget e riquadro, TalkBack, due dispositivi, telefono vero, sync reale. Restano dalla lista già in STATO.

## Comandi e log
```
export JAVA_HOME="$(/usr/libexec/java_home -v 17)" ANDROID_HOME="$HOME/Library/Android/sdk"
cd 03_CODICE/bucktrail-android
./gradlew assembleDebug assembleRelease lintDebug testDebugUnitTest   # BUILD SUCCESSFUL
./gradlew cleanTestDebugUnitTest testDebugUnitTest                    # 247 test, 0 falliti
adb shell cmd connectivity airplane-mode enable; adb install -r app-debug.apk; adb shell pm clear com.bucktrail.android
adb shell cmd uimode night yes; adb shell settings put system font_scale 1.6
adb logcat -d | grep -c "FATAL EXCEPTION\|ANR in"                     # 0
```
Log completi in cartella temporanea della sessione (non conservati).
