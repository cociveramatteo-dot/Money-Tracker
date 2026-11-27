# CONSEGNA — S-54, S-55, S-56 (iOS + Android)

## Cosa è stato fatto

1. **S-54 · Ordine movimenti uniforme (`04ed36b`)**
   - **Regola:** giorno di calendario dal più recente, poi `createdAt` dal più recente (l'ultimo aggiunto in cima), tie-break deterministico su `id`; nessuna modifica a `Models/`, `Domain/` o calcoli.
   - **iOS:** nuovo helper `MoneyTracker/Views/TransactionDisplayOrder.swift` (`sortedForDisplay(calendar:)`); aggiornati i `@Query` (con `SortDescriptor(\Transaction.date, order: .reverse)` + `SortDescriptor(\Transaction.createdAt, order: .reverse)`) e l'ordinamento di visualizzazione in `DashboardView`, `TransactionsView`, `StatisticsView` (export PDF), `PianificaView` e `RecurringSeriesDetailView`.
   - **Android:** `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/data/Dao.kt` aggiornato con `ORDER BY date(date / 1000, 'unixepoch', 'localtime') DESC, createdAt DESC, id` su `transactions()` e `observeTransactions()`; nuovo helper `ui/TransactionDisplayOrder.kt` (`sortedForDisplay(zone)`) applicato a `HomeScreen`, `MovementsScreen`, `RecurrenceScreens` (`RecurringSeriesDetailSheet`) e `AppViewModel.exportPdf`.
   - **Test:** `MoneyTrackerTests/TransactionDisplayOrderTests.swift` e `03_CODICE/bucktrail-android/app/src/test/java/com/bucktrail/android/ui/TransactionDisplayOrderTest.kt` (inclusa verifica SQLite in memoria della query `Dao.kt`).

2. **S-55 · Occhio mostra/nascondi (`0f12838`, `25073ed`)**
   - **iOS:** nuovo componente `MoneyTracker/Views/Components/RevealableSecureField.swift` in stile `DS` (`Theme.swift`), con icona `eye` / `eye.slash` (target 44×44), disattivazione correttore e suggerimenti (`.autocorrectionDisabled(true)`, `.textInputAutocapitalization(.never)`, `.textContentType(.none)`), ripristino automatico a nascosto su `scenePhase != .active`. Applicato a `LoginView`, `SignUpView` (password e conferma), `E2EActivationFlow` (`E2EPhraseFields`: frase, ripeti, cambio) e `E2EUnlockView` (frase e chiave di recupero, con `.id(useRecoveryKey)`).
   - **Android:** `AuthField` in `AuthScreens.kt` (con `Lifecycle.Event.ON_STOP` per nascondere in background e `KeyboardType.Text` + `autoCorrectEnabled = false` quando visibile) applicato a login, registrazione e a `SecretField`/`ProtectionPage.Unlock` in `AdvancedProtectionScreens.kt`.
   - **Accessibilità 7 lingue (it, en, de, es, fr, ja, zh-Hans):** chiavi `"Mostra"` / `"Nascondi"` in tutti i 7 `Localizable.strings` iOS e `mostra` / `nascondi` in tutti i 7 `strings.xml` Android.
   - **Test:** `MoneyTrackerTests/RevealableSecureFieldTests.swift`, `E2ELocalizationTests` e `plutil -lint` sui 7 `.strings`.

3. **S-56 · Formattatore chiave di recupero (`3af6702`, `25073ed`)**
   - **Regola:** trattini automatici ogni 4 caratteri (`XXXX-XXXX-...`), maiuscole automatiche, incolla normalizzato (spazi/trattini/a capo rimossi), cancellazione che supera il trattino senza bloccarsi, massimo 32 caratteri utili. Applicato **solo** ai campi della chiave di recupero (sblocco con chiave e conferma ultimi 4 caratteri), mai alle frasi di sicurezza; `RecoveryKey.parse` intatto.
   - **iOS:** `MoneyTracker/Views/E2E/RecoveryKeyInputFormatter.swift`, collegato via `.onChange` (per compatibilità `XCUITest.typeText`/SwiftUI) in `RevealableSecureField` (su `E2EUnlockView` quando `useRecoveryKey == true`) e `RecoveryKeyCard`.
   - **Android:** `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/ui/RecoveryKeyInputFormatter.kt` (`format` e `formatSelection` su `TextFieldValue` per mantenere la posizione del cursore), collegato in `AuthField` (`recoveryKeyFormatting = true`) su `ProtectionPage.Unlock` (solo `useRecovery == true`) e `RecoveryCard`.
   - **Test:** `MoneyTrackerTests/RecoveryKeyInputFormatterTests.swift` e `03_CODICE/bucktrail-android/app/src/test/java/com/bucktrail/android/ui/RecoveryKeyInputFormatterTest.kt`.

## Verifiche eseguite

- **iOS (dopo l'ultimo edit `25073ed`):**
  - Suite unitarie mirate (`TransactionDisplayOrderTests`, `RevealableSecureFieldTests`, `RecoveryKeyInputFormatterTests`, `E2ELocalizationTests`): **9/9 verdi**.
  - `E2EUITests`: **6/6 verdi** in light (`it-light`) e **2/2 verdi** in dark (`testActivationValidationAndDisableConfirmation`, `testUnlockRejectsWrongPhraseAndPromptsOnce`).
  - `DemoShowcaseUITests`: **verde** in light e dark (Home, Movimenti, Ricorrenze, Statistiche, Pianifica, Conti).
  - *Nota:* la suite completa `MoneyTrackerTests` (**211/211 verdi**) è stata eseguita su `3af6702` prima della piccola modifica reattiva `25073ed` (che tocca solo `RevealableSecureField.swift` e `RecoveryKeyCard.swift`, coperti dai test mirati + `E2EUITests` successivi).
- **Android (dopo l'ultima modifica Android `3af6702`):**
  - `./gradlew testDebugUnitTest assembleDebug lintDebug`: **BUILD SUCCESSFUL**, tutti gli unit test verdi (inclusi `TransactionDisplayOrderTest` e `RecoveryKeyInputFormatterTest`), `lintDebug` verde.
- **Screenshot in `.cantiere/tmp/` (esclusi da git):**
  - `.cantiere/tmp/s54/ios-light/` e `.cantiere/tmp/s54/ios-dark/` (DemoShowcase light/dark).
  - `.cantiere/tmp/s55-s56/ios-light/` e `.cantiere/tmp/s55-s56/ios-dark/` (E2E screenshots; nota: in `ios-dark/` la sheet modale E2E su iOS 27.2 è rimasta chiara sotto `XCUIDevice.shared.appearance = .dark`).

## Da verificare al collaudo

- Collaudo indipendente dei commit `04ed36b`, `0f12838`, `3af6702`, `25073ed` (verifica rispetto zone vietate: in `Auth/` toccate solo le viste UI `LoginView.swift` e `SignUpView.swift`, nessuna logica `Auth/` toccata).
- Controllo visivo e interattivo (occhio mostra/nascondi, auto-hide in background, formattatore chiave) su `LoginView`/`SignUpView`, E2E dark e su emulatore Android (`connectedDebugAndroidTest` / `E2EProtectionUiTest` non eseguiti in questo turno).
- Rilancio completo `MoneyTrackerTests` + suite UI completa iOS se richiesto prima del checkpoint.

## Prossimo turno

Collaudatore su S-54, S-55 e S-56.
