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

Questa prima versione include Home, Movimenti, Conti e salvataggio locale. L’identificatore `com.bucktrail.android` è provvisorio. La parità con iOS e la sincronizzazione Supabase sono i passi successivi. Per lo stato del progetto vedi `../../.cantiere/PIANO.md`.
