# S-44 · Sicurezza dei dati — verifica sul codice (2026-11-24)

Solo lettura. Ogni riga indica dove si verifica. Niente è dato per vero senza il file.

## iOS
| Cosa | Esito | Dove |
|---|---|---|
| Database locale | Protezione file `.complete` su SQLite, WAL e SHM: cifrato con chiave legata al codice, illeggibile a telefono bloccato | `MoneyTracker/MoneyTrackerApp.swift:79` e `:355` |
| Primo avvio | La protezione si applica solo ai file già presenti; al primo avvio vale il livello predefinito di iOS (`completeUntilFirstUserAuthentication`), poi `.complete` dal lancio successivo | `MoneyTrackerApp.swift:355-361` — accettato, non è una falla |
| Sessione di accesso | Nel Keychain (gestito dall'SDK Supabase) | `Auth/SupabaseManager.swift:44` |
| Blocco app | Face ID / Touch ID / codice (`deviceOwnerAuthentication`) | `Auth/BiometricAuthenticating.swift:22-26`, `Auth/AppLockGate.swift` |
| PDF e registro | PDF `completeUntilFirstUserAuthentication`, registro audit `.complete` | `Export/PDFReportGenerator.swift:99`, `Domain/AuditLogger.swift:99` |
| Tracker / analytics nell'app | Nessuno (nessun SDK di analytics, crash o pubblicità nel sorgente) | ricerca su `MoneyTracker/` |

## Android
| Cosa | Esito | Dove |
|---|---|---|
| Database locale (Room) | **Non cifrato dall'app** (SQLite normale): sta nell'area privata dell'app, protetta dalla cifratura dei file di Android (obbligatoria dall'Android 10; l'app richiede minSdk 26, quindi sui telefoni 8/9 dipende dal produttore) | `BucktrailApplication.kt:37` |
| Backup | Disattivato: `allowBackup="false"`, database esclusi da backup cloud e trasferimento | `AndroidManifest.xml:9`, `res/xml/data_extraction_rules.xml` |
| Sessione di accesso | Cifrata AES-256-GCM con chiave dell'Android Keystore, non esportabile; se manomessa si rifà il login | `sync/KeystoreSessionStore.kt` |
| Blocco app | BiometricPrompt (impronta/volto/PIN) | `security/Authenticator.kt` |
| Traffico in chiaro | Vietato nel release; consentito solo nel build debug verso il server finto | `src/debug/AndroidManifest.xml` |
| Tracker | Nessuno | `app/build.gradle.kts` |

## Cloud (Supabase, comune a iOS e Android)
- Trasporto: HTTPS (`https://…supabase.co`, `MoneyTracker/Auth/SupabaseConfig.swift:15`).
- A riposo: cifrato dal fornitore (Supabase, AES-256). Dichiarazione del fornitore, non verificabile dal nostro codice.
- Isolamento tra utenti: RLS attiva con 4 policy per tabella (PIANO S-13e, verificato da Matteo il 2026-11-14 con prova reale).
- **Non è cifratura end-to-end**: chi amministra il progetto Supabase (cioè Matteo) può tecnicamente leggere le righe. Va detto sul sito.
- L'account è facoltativo: senza accedere l'app resta solo locale.

## Lacune e decisione
1. **Room non cifrato a livello app (Android).** Decisione del capocantiere (2026-11-24): non si aggiunge SQLCipher. Motivi: i dati sono nell'area privata con backup disattivati e cifratura di sistema; SQLCipher richiede migrazione dei dati esistenti (rischio di perdita) e non protegge da chi ha il telefono sbloccato, già coperto dal blocco biometrico. Sul sito si scrive la cosa vera, senza prometterne di più.
2. Nessuna falla di sicurezza trovata. Nessuna correzione al codice necessaria.
