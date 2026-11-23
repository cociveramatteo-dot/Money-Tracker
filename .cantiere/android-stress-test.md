# Stress test Android Bucktrail (2026-11-23)

Ambiente: emulatore `Bucktrail_API_36` (arm64, 1080x2400), debug + release R8 firmato con la chiave debug (solo prova), server finto `scripts/fake-supabase.py` (mai il Supabase reale). Dati caricati con `run-as` + `sqlite3` sul DB di debug. Script di prova e screenshot in cartella temporanea (fuori da git).

## Esiti e correzioni

| # | Scenario | Esito | Correzione / test |
|---|---|---|---|
| 1 | Saldo conto enorme (> 10^12) nel form Conto | **CRASH** (`ArithmeticException` in `Amounts.toCents`, dentro la coroutine di salvataggio) | `Amounts.isValidBalance` (|v| ≤ 10^12) abilita «Salva» solo se valido; stesso limite (≤ 1 mld) sul «+ progresso» dell'obiettivo. Test `AmountsLimitsTest` |
| 2 | Importo hero/righe che non entra (font 2,0×, 320 dp, 498 mld) | Cifre **tagliate in silenzio** (sembrava un altro numero) | `FitText` ora termina con «…» invece di tagliare |
| 3 | Titoli «Movimenti», «Statistiche» a 2,0× su 320 dp | Titolo spezzato a metà parola; «Upcoming» a una lettera per riga; totale gruppo conti sovrapposto | `PageHeader` impila titolo e azioni sopra 1,5× (anche Statistiche e Pianifica); titolo con `FitText`; importi di testata (in arrivo, giorno, gruppo conto, «Saldo netto») in `FitText` con peso |
| 4 | Ripristino dopo kill del processo con form aperto | Importo e descrizione ripristinati, **categoria suggerita persa** (le categorie arrivano dopo il nome) | `LaunchedEffect(name, categories.size, history.size)` |
| 5 | Client HTTP: risposte malformate (login, refresh, tabelle) | Eccezione grezza `SerializationException`/NPE fino alla UI | `parseSession` e `selectAll` sempre `ApiException(Server)`. Test `HttpHostileServerTest` |
| 6 | Server che ignora `Range` (stessa pagina piena) | **Ciclo infinito** con memoria che cresce | Controllo pagina ripetuta + tetto 2 milioni di righe (mai risultato parziale) |
| 7 | Risposta enorme (52 MB) | Lettura intera in memoria (rischio OOM) | Lettura con tetto 48 MB → `ApiException(Server)` |
| 8 | Migrazione v2→v3 con `entryDay` corrotto / `cents = Long.MIN_VALUE` | Crash all'apertura del DB (data impossibile, `abs` in overflow) | Ripiego su `recordedAt`, `abs` sicuro. Test `MigrationStressTest` (20.000 righe) |
| 9 | Release senza R8 (17 MB) | Nessuna minificazione né regole | `minify + shrinkResources`, `proguard-rules.pro`, `res/raw/keep.xml` (stringhe demo cercate per nome). APK release **5,1 MB**, avvio e schermate principali verificati, monkey 6.000 eventi senza crash |
| 10 | StrictMode | Non attivo | Attivo in debug (log): restano 4 letture disco brevi al primo avvio (`filesDir`, SharedPreferences, Keystore), nessuna violazione di rete o perdita |

## Scenari superati senza difetti

- **DB vuoto**: Home, Movimenti, Statistiche, Pianifica, Conti, widget/scorciatoie («Nessun conto») senza crash, stati vuoti presenti.
- **12.000 movimenti** (≈ 3 anni): apertura a freddo 0,85–1,0 s, scroll 150 frame con 9% di frame lenti (99° percentile 500 ms solo al primo disegno), Statistiche immediate, PSS 179 MB, nessun ANR/«Skipped frames».
- **Dati estremi** (0, 0,01, 999.999.999,99, saldo −5·10^13, importo negativo, nomi di 300 caratteri, emoji ZWJ, RTL/ebraico/arabo, HTML/SQL, Zalgo, 1970, 2100, 29 feb, cambio ora, serie al 31, annuale 29 feb, settimanale dal 1970): nessun crash in nessuna schermata.
- **Fuzz con seme fisso** (`LedgerFuzzTest`, 5 fusi, 29 sequenze da 500 operazioni: movimenti, trasferimenti, rettifiche, archiviazione, eliminazione conto a cascata, serie con eccezioni, materializzazione): saldo = iniziale + somma dei fatti dopo ogni passo, gambe dei trasferimenti coerenti, id univoci, materializzazione idempotente.
- **Export** (`ExportRoundTripTest`): CSV e JSON riletti con parser indipendente su testi/importi estremi; saldi ricostruiti dal file = saldi dell'app.
- **Migrazioni su dispositivo**: DB reali v1 e v2 con 3.000 movimenti (importi fino a 999.999.999,99): conteggio e somme identici, planned→isDone, v3 aperto dopo.
- **Monkey**: 38.000 eventi sul debug (DB da 12.000) e 6.000 sul release (con modalità aereo attivata dal monkey), nessun crash/ANR.
- **Robustezza**: rotazione su tutte le schermate, kill del processo, cambio tema e lingua a runtime (it/ja/de/zh/en), permesso notifiche negato, biometria assente (interruttore disattivato con spiegazione), font 2,0× + 320 dp.
- **Account (server finto)**: credenziali errate, email non confermata, troppi tentativi, server spento → messaggi corretti («Incorrect email or password», «Confirm your email…», «Too many attempts…», «No connection…»). Sync: 73 test esistenti (rete, 401 con rinnovo, 500, conflitti campo per campo, due dispositivi, nessun push prima del primo scambio) + nuovi `HttpHostileServerTest` (12.000 righe in 12 pagine, timeout lento, 401/403/500/502).

## Non completato / rischi residui

- **Confronto con iOS (punto 1)**: login/registrazione, alert «Elimina conto», Cronologia modifiche, Storico budget, flussi categorie e dettaglio serie rilevata **non** confrontati a coppie col simulatore iOS (tempo/quota esaurita). Le schermate di login con errori sono state catturate su Android. Da fare: test UI iOS temporaneo + coppie di screenshot.
- Tabella di `android-parita-test.md`: verificata, ogni riga ha 3 colonne (4 separatori); non ho trovato righe sfalsate, nessuna modifica.
- Lingue RTL non supportate (ar, he) come lingua di sistema: i numeri compaiono con il segno in coda (formattazione del locale con testo it/en). Non selezionabile dall'app (7 lingue).
- ~~Dati remoti avvelenati~~ **risolto (2026-11-23 sera)**: una riga cloud illeggibile o con importo > 10^12 viene ignorata (conteggio in `SyncEngine.lastIgnoredRows` / `SyncService.ignoredRows`), la copia locale resta e il pull prosegue. Test `SyncGuardsTest` (movimento, conto, movimento di conto ignorato).
- ~~Push con DB locale vuoto cancella il cloud~~ **risolto**: guardia `DeletionGuard` in `SyncEngine.pushDetailed`: se il push cancellerebbe record dal cloud con DB locale vuoto, o con meno della metà dei record dell'ultimo stato sincronizzato (base ≥ 10), non scrive né cancella nulla e chiede conferma (alert «Eliminare i dati dal cloud?» → «Elimina dal cloud» oppure «Ripristina dal cloud», che fa un pull). Test JVM in `SyncGuardsTest`; l'alert non è stato provato a schermo con un server finto.
- Non provati: TalkBack interattivo (solo etichette nel codice), due dispositivi reali, memoria bassa vera (`send-trim-memory` rifiutato su processo in primo piano), `lint` ha 204 warning/8 hint già presenti (0 errori), UI test strumentati: aggiunti `androidTest/.../LayoutRegressionTest` (difetti 2 e 3: `FitText` termina con «…», `PageHeader` impila titolo e azioni a 2,0×), eseguiti sull'emulatore (`./gradlew connectedDebugAndroidTest`, 2/2 verdi, ~10 s dopo il build). Il difetto 4 (ripristino della categoria suggerita dopo kill del processo) resta solo manuale: richiede un `ActivityScenario` con ViewModel e DB, non un setup breve.
- Il build release punta al Supabase reale se compilato senza `-PsupabaseUrl`: nelle prove non è stato mai fatto accesso.
