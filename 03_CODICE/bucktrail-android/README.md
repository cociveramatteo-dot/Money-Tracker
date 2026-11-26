# Bucktrail per Android

Apri questa cartella in VS Code. Il progetto usa Kotlin, Jetpack Compose e Room, con JDK 17 e Android SDK Platform 36. Per la compilazione servono anche Build Tools 35.0.0. Il Gradle Wrapper fissa la versione 8.13 e verifica l’hash della distribuzione.

Nel terminale di VS Code su macOS:

```zsh
export JAVA_HOME="$(/usr/libexec/java_home -v 17)"
export ANDROID_HOME="$HOME/Library/Android/sdk"
./gradlew assembleDebug lintDebug testDebugUnitTest
```

L’APK di prova è in `app/build/outputs/apk/debug/app-debug.apk`. Per riaprire l’emulatore già configurato su questo Mac, usa un secondo terminale:

```zsh
export ANDROID_HOME="$HOME/Library/Android/sdk"
"$ANDROID_HOME/emulator/emulator" -avd Bucktrail_API_36
```

Quando compare la schermata iniziale di Android, esegui `./gradlew installDebug` nel primo terminale e apri Bucktrail dall’elenco delle app. Lo stesso comando installa su un dispositivo Android collegato con debug USB attivo.

Prima prova con dati fittizi in modalità aereo: crea un conto da 100 €, aggiungi un’uscita da 24,50 € e un’entrata da 5 €. La Home deve mostrare 80,50 €. Chiudi e riapri Bucktrail per verificare che conto e movimenti siano ancora presenti.

Per una spesa futura, scegli la data nel modulo del movimento. Le date future restano pianificate. Ritrovi la voce sotto **Movimenti → In arrivo** e puoi toccarla per modificarla. Alla data della spesa puoi disattivare **Pianificato** per registrarla come effettuata. Il saldo attuale include gli effettuati. Il saldo atteso di fine mese tiene anche conto dei pianificati di quel mese.

Questa versione include Home, Movimenti, Conti e salvataggio locale. L’identificatore `com.bucktrail.android` è provvisorio. La parità con iOS prosegue dai flussi locali. Per lo stato del progetto vedi `../../.cantiere/PIANO.md`.

## Account, sync e prove senza toccare il cloud

L'account è facoltativo: senza accedere l'app resta locale e offline. L'indirizzo Supabase e la chiave pubblica si leggono al build da `MoneyTracker/Auth/SupabaseConfig.swift` (mai copiati qui). Per provare login, registrazione e sync **senza il cloud reale** usa il server finto:

```zsh
python3 scripts/fake-supabase.py 54321
./gradlew installDebug -PsupabaseUrl=http://10.0.2.2:54321 -PsupabaseKey=chiave-finta
```

Utenti di prova (password `password1`): `demo@test.it`, `unconfirmed@test.it` (email non confermata), `limit@test.it` (troppi tentativi). Senza le due opzioni, il build Debug usa un indirizzo fittizio.

## Prova S-51b su Supabase reale

Dalla radice di MoneyTracker, sul Mac con Xcode, iPhone 18 Pro, Java 17, SDK Android e immagine `system-images;android-36;default;arm64-v8a`.

```sh
./03_CODICE/bucktrail-android/scripts/prova-due-dispositivi.py
```

Il file locale `~/.config/moneytracker/test-account.env` deve contenere `MT_TEST_EMAIL` e `MT_TEST_PASSWORD` di un account di prova dedicato con Protezione avanzata disattivata. Racchiudi i valori tra apici se contengono spazi o caratteri speciali. Lo script genera `MT_TEST_PHRASE` nello stesso file se manca. Durante la prova tieni chiuse le altre istanze dell’app con lo stesso account.

Lo script avvia un iPhone 18 Pro e un emulatore Android temporanei. Usa XCTest ospitato nell’app iOS e la strumentazione Android con i servizi reali di autenticazione, salvataggio e sincronizzazione. Su iOS il test scavalca la sola autenticazione del dispositivo durante la migrazione. Le credenziali sono trasferite in memoria tramite un indirizzo locale temporaneo e non compaiono nelle schermate. Ogni scambio verifica i movimenti salvati dopo il riavvio effettivo del processo iOS, anche dalla scheda Movimenti tramite XCUITest. Lo script riusa un conto attivo, oppure ne crea uno se manca. Sul cloud rimangono fino a sei movimenti di prova riconoscibili dal prefisso `S51b`.

L’uscita elenca gli esiti dei singoli scenari. In caso di errore lo script prova a tornare allo stato con protezione disattivata e verifica lo stato su Supabase. Se il ripristino risulta KO durante la migrazione, lo script conserva il simulatore iOS. Usa quel simulatore per controllare la Protezione avanzata prima di rilanciare. La frase necessaria per lo sblocco è nel file locale.
