# PROGETTO ESECUTIVO S-50 · «Protezione avanzata» (cifratura end-to-end della sync)

> Autore: architetto (Claude Code · Opus), 2026-11-24. Stato: progetto approvato da eseguire in autonomia da Claude Code
> (Sonnet) secondo il piano del §10. Nessun codice di produzione è stato scritto con questo documento.
> Vincolo supremo (Matteo, 2026-11-24): **«mantenere tutto intatto, non rompere nulla»**. Chi non attiva l'opzione
> non vede alcun cambiamento; i dati già sincronizzati non si perdono; iPhone e Android continuano a sincronizzarsi tra loro.
> Autorizzazione di Matteo riferita dal capocantiere il 2026-11-24 (solo per S-50 e dentro questo progetto): si possono modificare `MoneyTracker/Sync/` e
> `MoneyTracker/Auth/` e i punti minimi di Persistence/Models indicati al §8. Restano intoccabili: calcoli, `Domain/`, test esistenti
> (si possono solo AGGIUNGERE test).

## Indice
0. [Sintesi in 12 righe](#0-sintesi)
1. [Modello di minaccia](#1-modello-di-minaccia)
2. [Cosa si cifra, cosa resta in chiaro](#2-cosa-si-cifra)
3. [Crittografia: primitive, chiavi, formato, vettori](#3-crittografia)
4. [Custodia delle chiavi e casi di vita](#4-custodia-delle-chiavi)
5. [Interfaccia e testi nelle 7 lingue](#5-interfaccia)
6. [Schema server (unico passo manuale di Matteo)](#6-schema-server)
7. [Migrazione: attivazione, disattivazione, ripresa, rollback](#7-migrazione)
8. [Compatibilità e rischio di regressione](#8-compatibilita)
9. [Piano di prova](#9-piano-di-prova)
10. [Piano di lavoro esecutivo (S-50a…S-50p) con prompt](#10-piano-di-lavoro)
11. [Rischi residui, decisioni, stima, cosa NON fare](#11-rischi-e-decisioni)

---

## 0. Sintesi
- **Architettura:** i dati cifrati NON vanno nelle tabelle esistenti `mt_*`, ma in una **tabella nuova `mt_vault`** (una riga per record:
  `id`, `user_id`, `kind`, `payload` cifrato). Le chiavi avvolte stanno in una **tabella nuova `mt_e2e`** (una riga per utente).
- **Il contenuto cifrato è esattamente la riga JSON che oggi va in `mt_*`** (stesso DTO iOS / stesso `SyncMapper` Android): la logica di
  sync (push, pull, orfani, guardie, dirty tracking) resta quella di oggi; cambia solo il «trasporto» (`SyncRemote` iOS, decoratore
  `VaultSupabaseApi` Android).
- **Primitive native, zero dipendenze nuove:** AES-256-GCM (CryptoKit / `javax.crypto`), PBKDF2-HMAC-SHA256 600 000 iterazioni
  (CommonCrypto / `SecretKeyFactory`), HKDF-SHA256 per la chiave di recupero, Base64url senza padding, chiave di recupero Crockford Base32.
- **Chiave dati (DEK) casuale**, avvolta due volte: con la **frase di sicurezza** (separata dalla password Supabase) e con la **chiave di recupero**.
  Reset della password Supabase = nessun effetto sui dati.
- **Client vecchi protetti dal server:** un trigger additivo sulle 5 tabelle `mt_*` rifiuta le scritture in chiaro quando l'utente ha la
  protezione attiva (errore `bt_e2e_active`). Un client vecchio non può né sovrascrivere né rimettere in chiaro i dati: smette solo di sincronizzare.
- **Migrazione riprendibile e verificata:** la copia in chiaro sul server resta **congelata** (trigger) finché la copia cifrata non è
  verificata riga per riga; solo dopo si cancella. Rollback possibile fino a quel punto.
- **Interruttore:** `E2EFeature.isEnabled = false` su iOS e `BuildConfig.E2E_ENABLED = false` su Android. Spento = nessuna richiesta nuova,
  nessuna schermata nuova, codice di sync identico. Si accende solo nel task finale S-50p, dopo SQL applicato, collaudo e ok di Matteo.
- **Unico passo manuale di Matteo:** incollare lo script SQL del §6 nel SQL Editor di Supabase (additivo, idempotente, reversibile).

---

## 1. Modello di minaccia

### 1.1 Cosa protegge
Il **contenuto** dei dati finanziari sincronizzati (importi, nomi, note, categorie, conti, date, budget, obiettivi, ricorrenze, eccezioni).

### 1.2 Da chi
| Avversario | Protetto? | Perché |
|---|---|---|
| Chi amministra il progetto Supabase (anche Matteo) | **Sì** | sul server ci sono solo `payload` AES-GCM e chiavi avvolte; la DEK non lascia mai il dispositivo in chiaro |
| Fornitore Supabase, suoi backup, dump del database trapelati, richieste legali al fornitore | **Sì** | stesso motivo |
| Chi ruba il token di sessione Supabase | **Sì** (contenuto) | può leggere/cancellare righe, ma non decifrarle |
| Server che altera, scambia o sposta righe tra record/utenti | **Rilevato** | AAD lega ogni payload a `kind`, `id`, `user_id`: decifratura fallita, la riga viene rifiutata |
| Attacco a forza bruta sulla frase, a partire da `mt_e2e` | **Mitigato** | PBKDF2 600 000 iterazioni + frase ≥ 10 caratteri; una frase debole resta un rischio (§11) |

### 1.3 Cosa NON protegge (va detto all'utente e sul sito)
- **Metadati visibili al server:** `user_id` ed email dell'account, `id` di ogni record, `kind` (quindi **quanti** conti, movimenti,
  budget, obiettivi, ricorrenze), dimensione approssimativa di ogni payload (≈ lunghezza dei testi), **quando** si sincronizza e da quale IP,
  quando una riga viene creata o cancellata, i parametri KDF e lo stato in `mt_e2e`.
- **Disponibilità e integrità «storica»:** il server può cancellare righe, o rimettere una versione **precedente** dello stesso record
  (rollback di una riga: l'AAD non contiene una versione). Non può creare contenuti falsi leggibili.
- **Il dispositivo:** telefono sbloccato in mano ad altri, malware, backup del telefono. Lì valgono le protezioni già esistenti
  (protezione file iOS `.complete`, area privata Android, blocco biometrico dell'app).
- **Utenti che non attivano l'opzione:** per loro nulla cambia (cifratura a riposo del fornitore + RLS, come oggi).
- **Durante la disattivazione** i dati tornano volontariamente in chiaro sul server.

---

## 2. Cosa si cifra

Le tabelle sincronizzate sono 5, identiche su iOS (`SyncService.swift`) e Android (`SyncMapper.kt`). Categorie e registro modifiche
**non** si sincronizzano (né oggi né dopo).

| Tabella oggi | `kind` nel vault | Colonne che finiscono **dentro** il payload cifrato |
|---|---|---|
| `mt_accounts` | `account` | id*, user_id*, name, type, initial_balance, color_hex, created_at, is_archived, is_excluded_from_total |
| `mt_transactions` | `transaction` | id*, user_id*, account_id, name, amount, type, category, category_icon, date, is_done, is_fixed, is_transfer, transfer_group_id, notes, recurring_frequency, template_id, created_at |
| `mt_budgets` | `budget` | id*, user_id*, account_id, category, category_icon, monthly_limit, month, year, created_at |
| `mt_goals` | `goal` | id*, user_id*, name, emoji, target_amount, current_amount, deadline, is_completed, created_at |
| `mt_recurring_rules` | `rule` | id*, user_id*, name, type, category, category_icon, notes, amount, is_fixed, account_id, frequency, start_date, end_date, exceptions, materialized_through, created_at |

\* `id` e `user_id` stanno **anche** dentro il payload (così i decoder esistenti funzionano senza modifiche), oltre che in chiaro.

**Restano in chiaro in `mt_vault`, e perché**
- `id` — chiave di upsert e del confronto «orfani» (push e pull lavorano per id); senza id servirebbe riscrivere tutta la logica di sync.
- `user_id` — l'isolamento tra utenti è fatto dalla RLS di Postgres, che deve poterlo leggere.
- `kind` — per leggere/cancellare una tabella logica alla volta come oggi. Rivela il numero di record per tipo (metadato già dichiarato).
- **Non esistono** `updated_at`, `deleted` o tombstone: la sync attuale è a istantanea completa (cancellazione = riga assente). Il vault
  conserva la stessa semantica; non si aggiungono colonne di tempo (meno metadati).

---

## 3. Crittografia

### 3.1 Primitive (decisioni)
| Cosa | Scelta | Motivo (2 righe) | Scartate |
|---|---|---|---|
| Cifratura autenticata | **AES-256-GCM**, nonce 96 bit casuale, tag 128 bit | nativa su iOS (`CryptoKit.AES.GCM`) e Android API 26+ (`AES/GCM/NoPadding`), già usata in `KeystoreSessionStore.kt` | ChaCha20-Poly1305 (Android solo API 28+, minSdk è 26); XChaCha20 (non nativa: servirebbe libsodium) |
| Derivazione dalla frase | **PBKDF2-HMAC-SHA256, 600 000 iterazioni**, salt 16 byte | nativa su entrambi (CommonCrypto `CCKeyDerivationPBKDF`, `SecretKeyFactory("PBKDF2WithHmacSHA256")` API 26+); 600k = raccomandazione OWASP 2023 | Argon2id e scrypt (nessuna implementazione di sistema: dipendenza nativa nuova = rischio e peso) |
| Derivazione dalla chiave di recupero | **HKDF-SHA256** (RFC 5869), senza salt, info fissa | la chiave di recupero ha 160 bit casuali: non serve un KDF lento; CryptoKit ha `HKDF`, su Android sono ~15 righe con `Mac("HmacSHA256")` verificate coi vettori RFC 5869 | PBKDF2 anche qui (lento senza motivo); SHA-256 semplice (meno ortodosso) |
| Identificativo chiave | `key_id` = primi 8 byte di HMAC-SHA256(DEK, "bucktrail/e2e/v1/key-id"), esadecimale minuscolo (16 caratteri) | permette a un dispositivo di capire se la chiave che custodisce è ancora quella del server, senza rivelare nulla | hash della DEK (sconsigliato usare la chiave stessa come input di un hash pubblico) |
| Codifica binari | **Base64url senza padding** | iOS: 3 sostituzioni; Android: `java.util.Base64.getUrlEncoder().withoutPadding()` (API 26) | Base64 standard (`+ /` scomodi negli URL e nei log) |
| Chiave di recupero | **20 byte casuali → Crockford Base32 → 32 caratteri in 8 gruppi da 4** (`XXXX-XXXX-…`) | leggibile e trascrivibile, niente caratteri ambigui (no I, L, O, U); in lettura `O→0`, `I/L→1`, minuscole accettate, trattini e spazi ignorati | BIP-39 a 24 parole (lista di 2048 parole da includere e localizzare); 256 bit (troppo lunga da trascrivere) |
| Casualità | `SecRandomCopyBytes` / `SymmetricKey(size:)` su iOS; `SecureRandom()` su Android | di sistema | qualsiasi PRNG non crittografico |

### 3.2 Gerarchia delle chiavi
```
DEK (32 byte casuali, generata una volta all'attivazione)  ── cifra ogni payload del vault
 ├─ wrapped_key_passphrase = AES-GCM( KEK_pw , DEK )   KEK_pw = PBKDF2-HMAC-SHA256( NFC(frase) UTF-8 , salt16 , 600000 , 32 )
 └─ wrapped_key_recovery   = AES-GCM( KEK_rk , DEK )   KEK_rk = HKDF-SHA256( ikm = 20 byte recupero , salt = vuoto , info = "bucktrail/e2e/v1/recovery" , L = 32 )
```
- La **frase di sicurezza** NON è la password Supabase: la password di login viaggia fino a Supabase (GoTrue la vede), quindi una chiave
  derivata da lei non proteggerebbe dall'amministratore. La frase non lascia mai il dispositivo.
- Normalizzazione della frase: Unicode **NFC** (iOS `precomposedStringWithCanonicalMapping`, Android `Normalizer.Form.NFC`), poi UTF-8.
  Nessun trim. Lunghezza minima 10 caratteri (conteggio della piattaforma).
- Cambio frase: nuovo salt + nuovo `wrapped_key_passphrase`; `wrapped_key_recovery` invariato (HKDF senza salt: indipendente).
- Nuova chiave di recupero: nuovi 20 byte + nuovo `wrapped_key_recovery`; la vecchia smette di funzionare.
- Rotazione della DEK: **non** in v1 (equivale a disattiva + riattiva).

### 3.3 Formato dell'involucro (identico per payload e chiavi avvolte)
```
"bt1." + base64url_nopad( nonce[12] || ciphertext[n] || tag[16] )
```
- `bt1` = versione del protocollo. Un client che legge un prefisso diverso **rifiuta** la riga (mai «indovina»).
- Lettura rigorosa: prefisso esatto `bt1.`, Base64url valido, lunghezza decodificata ≥ 28 byte, altrimenti errore `malformed`.
- iOS: `AES.GCM.seal(pt, using: key, nonce: n, authenticating: aad).combined` dà già `nonce||ct||tag`. Android: `iv + cipher.doFinal()`
  con `GCMParameterSpec(128, nonce)` e `updateAAD(aad)`.

### 3.4 AAD (dati associati, in UTF-8, tutto minuscolo)
| Uso | AAD |
|---|---|
| payload di una riga | `bucktrail/e2e/v1/row/<kind>/<id minuscolo>/<user_id minuscolo>` |
| DEK avvolta con la frase | `bucktrail/e2e/v1/wrap/passphrase/<user_id minuscolo>` |
| DEK avvolta col recupero | `bucktrail/e2e/v1/wrap/recovery/<user_id minuscolo>` |

iOS invia gli UUID in MAIUSCOLO (`uuidString`): nell'AAD vanno **sempre** `lowercased()`. Dopo la decifratura si controlla anche
che `id` dentro il JSON coincida (senza distinzione di maiuscole) con l'`id` della riga; se no, riga rifiutata.

### 3.5 Contenuto in chiaro del payload
- È l'oggetto JSON della riga, con **le stesse chiavi snake_case** delle tabelle `mt_*`.
- **iOS:** codificato con un encoder dedicato `VaultJSON.encoder` (NON quello dell'SDK, per non dipendere dai suoi dettagli):
  `JSONEncoder` con `outputFormatting = [.sortedKeys]`, date in ISO-8601 UTC con millisecondi e `Z` (`yyyy-MM-dd'T'HH:mm:ss.SSS'Z'`,
  `ISO8601DateFormatter` con `.withInternetDateTime, .withFractionalSeconds`, fuso UTC), `Decimal` come numero JSON. Il decoder
  `VaultJSON.decoder` accetta date con e senza frazioni e con `Z` o `+00:00`.
- **Android:** esattamente la `JsonObject` prodotta da `SyncMapper.*Row(...)` (`toString()` compatto). Le date sono già nel formato sopra.
- Interoperabilità garantita dai vettori del §3.7 (ogni piattaforma decifra e decodifica le righe prodotte dall'altra).
- Dimensione massima del payload: 64 KiB (controllo anche nel database).

### 3.6 Riga `mt_e2e` (una per utente)
| Colonna | Contenuto |
|---|---|
| `user_id` | uuid (PK) |
| `state` | `migrating` · `active` · `disabling` (assenza della riga = protezione spenta) |
| `version` | 1 |
| `kdf` | `pbkdf2-sha256` |
| `kdf_iterations` | 600000 (il client accetta 100 000…10 000 000; fuori intervallo = rifiuto) |
| `salt` | base64url 16 byte |
| `wrapped_key_passphrase`, `wrapped_key_recovery` | involucri `bt1.` |
| `key_id` | 16 caratteri esadecimali |
| `updated_at` | `now()` (solo diagnostica) |

### 3.7 Vettori di test condivisi
File unico: `MoneyTrackerTests/Fixtures/e2e-vectors-v1.json` (la cartella è sincronizzata da Xcode: entra da sola nel bundle di test;
Android lo legge tramite `systemProperty("e2eVectors", …)` impostata in `build.gradle.kts`, percorso `rootProject.file("../../MoneyTrackerTests/Fixtures/e2e-vectors-v1.json")`).
Contenuto (generato da `03_CODICE/bucktrail-android/scripts/e2e-vectors.py`, che calcola PBKDF2/HKDF/Base32/Base64 con la sola libreria
standard di Python come **terza implementazione indipendente**; gli involucri AES-GCM a nonce fisso vengono prodotti la prima volta dal test iOS
in modalità «stampa» e poi verificati da Android, più l'ancora NIST sotto):
1. `aes_gcm_kat`: caso di test 16 di McGrew–Viega (AES-256, IV 96 bit, con AAD), valori ufficiali: ancora indipendente da entrambe le piattaforme.
2. `hkdf_rfc5869`: caso di test 1 dell'RFC 5869 (SHA-256).
3. `pbkdf2`: 3 casi — frase ASCII, frase con accenti e kanji ed emoji (`"Pässwörd 日本 🔑 è"` in forma NFD in input, per provare la NFC), iterazioni 1000 e 600000.
4. `crockford`: 4 casi byte↔stringa, inclusi input con minuscole, `O`, `I`, `L`, trattini e spazi.
5. `envelope`: DEK fissa, nonce fisso, AAD, plaintext → stringa `bt1.` attesa (seal con nonce iniettato: **solo nei test**).
6. `wrap`: frase + salt + DEK → `wrapped_key_passphrase` atteso; recupero → `wrapped_key_recovery` atteso; `key_id` atteso.
7. `rows`: per ciascun `kind`, una riga **prodotta da iOS** e una **prodotta da Android** (JSON in chiaro + involucro), con i valori attesi
   in forma neutra (importi come stringa decimale, date in epoch ms, booleani) per i confronti di ciascuna piattaforma.
8. `negative`: involucro con un bit del tag alterato, prefisso `bt2.`, Base64 rotto, AAD con id diverso, frase sbagliata → tutti devono fallire.

Il nonce iniettabile esiste solo come parametro `internal`/`@VisibleForTesting` con valore predefinito casuale; il codice di produzione
non lo passa mai (un test lo verifica cercando le chiamate).

---

## 4. Custodia delle chiavi

### 4.1 Dove sta la DEK sul dispositivo
- **iOS:** Keychain, `kSecClassGenericPassword`, service `com.bucktrail.e2e.dek`, account = `user_id` minuscolo, valore JSON
  `{"dek":"<b64url>","key_id":"…","user_id":"…"}`, accessibilità **`kSecAttrAccessibleAfterFirstUnlockThisDeviceOnly`**: la sync gira anche
  quando l'app passa in background; `ThisDeviceOnly` = niente iCloud Keychain, niente ripristino su un altro telefono.
- **Android:** SharedPreferences private `bucktrail_e2e`, valore = AES-GCM con chiave **Android Keystore** alias `bucktrail_e2e_key`
  (256 bit, non esportabile, senza richiesta di autenticazione utente per non bloccare la sync in background), stesso schema di
  `KeystoreSessionStore.kt`. Il backup è già disattivato (`allowBackup=false`).
- **Biometria:** NON a ogni uso della DEK (la sync è automatica). Serve invece l'autenticazione del dispositivo (`LAContextAuthenticator` iOS,
  `security/Authenticator.kt` Android) per: mostrare/creare una nuova chiave di recupero, cambiare la frase, disattivare, «ricomincia».
  Il blocco app esistente resta com'è.

### 4.2 Casi di vita
| Evento | Cosa succede |
|---|---|
| **Logout** | la DEK si cancella insieme ai dati locali (in `clearLocalData` iOS e `SyncEngine.clearLocalData` Android). Al nuovo accesso: «Sincronizzazione in pausa: inserisci la frase». |
| **Cambio utente sullo stesso telefono** | come sopra (stesso punto di codice). |
| **Reset password Supabase / cambio email** | nessun effetto: la DEK è avvolta con frase e recupero, non con la password. |
| **Secondo dispositivo / cambio telefono** | accesso → lo stato `active` viene letto da `mt_e2e` → schermata di sblocco → frase (o chiave di recupero) → la DEK si apre e si salva nel Keychain/Keystore → sync normale (prima scaricando). |
| **Frase dimenticata** | «Usa la chiave di recupero» → DEK → si sceglie subito una nuova frase. |
| **Chiave di recupero persa, frase nota** | da un dispositivo sbloccato: «Crea una nuova chiave di recupero». |
| **Ho un dispositivo sbloccato ma ho dimenticato tutto** | dal dispositivo (con autenticazione del telefono) si può cambiare la frase e creare una nuova chiave di recupero: la DEK è già lì. |
| **Persi tutti i dispositivi + frase + chiave** | i dati sul cloud sono **irrecuperabili** (lo dice il testo K07 prima dell'attivazione). Opzione «Ho perso frase e chiave» → «Ricomincia da questo dispositivo»: cancella vault e `mt_e2e`, poi la sync riparte in chiaro con i dati del dispositivo (se vuoto, cloud vuoto: avviso K40). |
| **Disattivata o riattivata da un altro dispositivo** | il `key_id` del server non coincide più, o la riga non esiste più: la DEK locale si cancella; se la protezione è ancora attiva → sblocco; se è spenta → sync in chiaro ripartendo **col percorso di primo accesso** della piattaforma (§7.6). |
| **Eliminazione account** | come oggi: prima la RPC `delete_own_account` (se fallisce non si tocca nulla); poi, con il token ancora valido, cancellazione «al meglio» di `mt_vault` e `mt_e2e`; in più le due tabelle hanno `on delete cascade` su `auth.users`. Poi DEK cancellata. |
| **Modalità demo / store volatile** | protezione invisibile e inattiva (la demo non sincronizza). |

---

## 5. Interfaccia

### 5.1 Dove e come (design «Sentiero»)
- **iOS:** `SettingsView` → sezione «Sicurezza», nuova riga tra «Blocco con Face ID» e «Cronologia modifiche», visibile solo se
  `E2EFeature.isEnabled && auth.isLoggedIn && !demoModeEnabled && E2EController.shared.serverSupported`. Stile identico alle righe vicine:
  titolo `.scaledFont(size: 15)` `DS.ink`, sottotitolo `.scaledFont(size: 11)` `DS.smoke`, a destra lo stato (`DS.accent` se attiva,
  `DS.smoke` se no) e `chevron.right`; separatori `ThinDivider()`. In stato «bloccato» il sottotitolo è K31 in `DS.plannedText`.
  Apre `AdvancedProtectionView` (push o sheet come le altre sotto-schermate; seguire lo schema usato per `AuditLogView`).
- **Android:** `SettingsSheets.kt`, sotto `SectionLabel(stringResource(R.string.sicurezza))`, riga equivalente con i colori del tema Sentiero
  già usati nella stessa sezione.
- **Mai** `preferredColorScheme`, mai colori fissi: solo token `DS.*` (iOS) e colori del tema (Android). Font scalabili (`.scaledFont`).
  Chiave di recupero in un riquadro `DS.surface` con bordo `DS.border`, carattere monospaziato (`.monospaced()` / `FontFamily.Monospace`),
  selezionabile, 2 righe da 4 gruppi.
- **Prompt automatico di sblocco:** quando lo stato diventa «bloccato», il foglio di sblocco si apre da solo **una volta per sessione**
  (modificatore sulla radice `ContentView` iOS / `BucktrailApp` Android, attivo solo con l'interruttore acceso). Poi resta la riga in Impostazioni.

### 5.2 Schermate
1. **Protezione avanzata (spenta):** K01 titolo, K05, K06, K07 (in `DS.danger` tenue: `DS.dangerSoft` di sfondo), K08, pulsante K09.
2. **Attivazione — frase:** K10, K11, campi sicuri K12 e K13, errori K14/K15, pulsante «Continua» (chiave esistente). La derivazione PBKDF2
   gira fuori dal main thread con indicatore.
3. **Attivazione — chiave di recupero:** K16, chiave in 8 gruppi, pulsanti K18 e K19 (share sheet / `Intent.ACTION_SEND` con testo semplice),
   K17, campo K20 (deve coincidere con l'ultimo gruppo, senza distinzione di maiuscole), pulsante K21 abilitato solo se coincide.
4. **Attivazione — avanzamento:** K22 con contatore «n / N» (numeri, senza testo da tradurre) → K23. In errore: K43 + K45 e K44.
   Se un altro dispositivo sta già attivando: K46. Senza rete: K47.
5. **Protezione avanzata (attiva):** stato K23, righe K24, K25 (con nota K26), K27 (in rosso come «Esci dall'account»).
   Ogni azione chiede prima l'autenticazione del dispositivo (motivo K48). K27 apre il dialogo K28/K29 → avanzamento K30.
6. **Sblocco:** K32, K33, campo K12, pulsante K34, link K35 (campo K36), errore K37, link K38. Se lo stato del server è di transizione: K42.
7. **Ricomincia:** dialogo distruttivo K39/K40, pulsante K41 (rosso), poi autenticazione del dispositivo (K48).
8. **Cambio frase:** come la schermata 2, conferma K49.

### 5.3 Testi (chiavi e 7 lingue)
**Convenzione:** per S-50 le chiavi sono **identiche sulle due piattaforme**: Android `R.string.e2e_xxx`, iOS chiave `"e2e_xxx"` con il testo
italiano **anche** in `it.lproj/Localizable.strings` (eccezione voluta alla convenzione «chiave = testo italiano»: evita collisioni con chiavi
italiane già esistenti come «Attiva» e tiene la corrispondenza 1:1). Un test (§9) verifica che ogni chiave `e2e_*` esista in tutte e 7 le
lingue su entrambe le piattaforme. Nei file Android gli apostrofi vanno scritti `\'`. Il tono segue i file esistenti: tedesco «du», francese «vous».

| # | chiave | it |
|---|---|---|
| K01 | e2e_titolo | Protezione avanzata |
| K02 | e2e_sottotitolo | Cifratura end-to-end della sincronizzazione |
| K03 | e2e_stato_attiva | Attiva |
| K04 | e2e_stato_disattivata | Disattivata |
| K05 | e2e_intro | Con la Protezione avanzata i tuoi dati vengono cifrati su questo dispositivo prima della sincronizzazione. Sul cloud restano solo dati illeggibili: nessuno, nemmeno chi gestisce Bucktrail, può leggerli senza la tua frase di sicurezza o la chiave di recupero. |
| K06 | e2e_metadati | Il server vede solo informazioni tecniche: il tuo account, quante voci hai e quando sincronizzi. |
| K07 | e2e_avviso_perdita | Se perdi sia la frase di sicurezza sia la chiave di recupero, i dati sul cloud non si possono più recuperare. Nessuno può farlo al posto tuo. |
| K08 | e2e_avviso_aggiorna | Prima di attivarla, aggiorna Bucktrail su tutti i dispositivi collegati a questo account: le versioni precedenti smetteranno di sincronizzare. |
| K09 | e2e_attiva | Attiva Protezione avanzata |
| K10 | e2e_frase_titolo | Scegli una frase di sicurezza |
| K11 | e2e_frase_aiuto | Almeno 10 caratteri: meglio quattro o più parole. Non usare la password dell'account. La frase non lascia mai il dispositivo. |
| K12 | e2e_frase_campo | Frase di sicurezza |
| K13 | e2e_frase_ripeti | Ripeti la frase |
| K14 | e2e_frase_corta | La frase deve avere almeno 10 caratteri. |
| K15 | e2e_frase_diverse | Le due frasi non coincidono. |
| K16 | e2e_chiave_titolo | La tua chiave di recupero |
| K17 | e2e_chiave_testo | Conservala fuori da questo telefono, su carta o in un gestore di password. Serve se dimentichi la frase di sicurezza. Non verrà più mostrata. |
| K18 | e2e_copia | Copia |
| K19 | e2e_condividi | Salva o condividi |
| K20 | e2e_chiave_conferma | Per confermare, scrivi l'ultimo gruppo della chiave |
| K21 | e2e_chiave_salvata | Ho salvato la chiave |
| K22 | e2e_in_corso | Cifratura dei dati in corso… Tieni l'app aperta. |
| K23 | e2e_fatto | Protezione avanzata attiva |
| K24 | e2e_cambia_frase | Cambia frase di sicurezza |
| K25 | e2e_nuova_chiave | Crea una nuova chiave di recupero |
| K26 | e2e_nuova_chiave_nota | La chiave di recupero precedente smetterà di funzionare. |
| K27 | e2e_disattiva | Disattiva Protezione avanzata |
| K28 | e2e_disattiva_titolo | Disattivare la Protezione avanzata? |
| K29 | e2e_disattiva_testo | I dati torneranno a sincronizzarsi senza cifratura end-to-end: protetti come prima, ma non con una chiave solo tua. |
| K30 | e2e_disattivazione_in_corso | Disattivazione in corso… Tieni l'app aperta. |
| K31 | e2e_pausa | Sincronizzazione in pausa: inserisci la frase di sicurezza |
| K32 | e2e_sblocca_titolo | Sblocca la sincronizzazione |
| K33 | e2e_sblocca_testo | La Protezione avanzata è attiva su questo account. Inserisci la frase di sicurezza per leggere i dati del cloud su questo dispositivo. |
| K34 | e2e_sblocca | Sblocca |
| K35 | e2e_usa_chiave | Usa la chiave di recupero |
| K36 | e2e_chiave_campo | Chiave di recupero |
| K37 | e2e_errata | Frase o chiave non corretta. |
| K38 | e2e_perse_entrambe | Ho perso frase e chiave |
| K39 | e2e_ricomincia_titolo | Ricominciare da questo dispositivo? |
| K40 | e2e_ricomincia_testo | Senza frase di sicurezza e chiave di recupero i dati cifrati sul cloud non si possono leggere. Puoi cancellarli e ripartire con i dati di questo dispositivo. L'operazione è irreversibile. |
| K41 | e2e_ricomincia | Cancella i dati cifrati e ricomincia |
| K42 | e2e_altro_dispositivo | La Protezione avanzata si sta attivando o disattivando su un altro dispositivo. Completa lì l'operazione, oppure inserisci qui la frase di sicurezza per proseguire. |
| K43 | e2e_errore | Operazione non completata. I tuoi dati sono al sicuro: riprova. |
| K44 | e2e_annulla_attivazione | Annulla attivazione |
| K45 | e2e_riprova | Riprova |
| K46 | e2e_gia_in_corso | Un altro dispositivo sta già attivando la Protezione avanzata. |
| K47 | e2e_serve_rete | Serve una connessione a Internet. |
| K48 | e2e_motivo_biometria | Conferma la tua identità per gestire la Protezione avanzata |
| K49 | e2e_frase_cambiata | Frase di sicurezza aggiornata |

**en**
K01 Advanced Protection · K02 End-to-end encryption for sync · K03 On · K04 Off ·
K05 With Advanced Protection your data is encrypted on this device before it syncs. The cloud only holds unreadable data: no one, not even the people who run Bucktrail, can read it without your security phrase or recovery key. ·
K06 The server only sees technical information: your account, how many items you have and when you sync. ·
K07 If you lose both your security phrase and your recovery key, your cloud data can no longer be recovered. No one can do it for you. ·
K08 Before turning it on, update Bucktrail on every device signed in to this account: older versions will stop syncing. ·
K09 Turn on Advanced Protection · K10 Choose a security phrase ·
K11 At least 10 characters: four or more words work best. Don't use your account password. The phrase never leaves your device. ·
K12 Security phrase · K13 Repeat the phrase · K14 The phrase must be at least 10 characters long. · K15 The two phrases don't match. ·
K16 Your recovery key · K17 Keep it somewhere other than this phone, on paper or in a password manager. You'll need it if you forget your security phrase. It won't be shown again. ·
K18 Copy · K19 Save or share · K20 To confirm, type the last group of the key · K21 I've saved the key ·
K22 Encrypting your data… Keep the app open. · K23 Advanced Protection is on · K24 Change security phrase · K25 Create a new recovery key ·
K26 Your previous recovery key will stop working. · K27 Turn off Advanced Protection · K28 Turn off Advanced Protection? ·
K29 Your data will sync without end-to-end encryption again: protected as before, but not with a key only you hold. ·
K30 Turning off… Keep the app open. · K31 Sync paused: enter your security phrase · K32 Unlock sync ·
K33 Advanced Protection is on for this account. Enter your security phrase to read your cloud data on this device. ·
K34 Unlock · K35 Use recovery key · K36 Recovery key · K37 Incorrect phrase or key. · K38 I've lost both phrase and key ·
K39 Start over from this device? · K40 Without your security phrase and recovery key, the encrypted cloud data can't be read. You can delete it and start over with the data on this device. This can't be undone. ·
K41 Delete encrypted data and start over · K42 Advanced Protection is being turned on or off on another device. Finish there, or enter your security phrase here to continue. ·
K43 The operation didn't complete. Your data is safe: please try again. · K44 Cancel setup · K45 Try again ·
K46 Another device is already turning on Advanced Protection. · K47 An internet connection is required. ·
K48 Confirm your identity to manage Advanced Protection · K49 Security phrase updated

**de**
K01 Erweiterter Schutz · K02 Ende-zu-Ende-Verschlüsselung der Synchronisierung · K03 Aktiv · K04 Aus ·
K05 Mit dem erweiterten Schutz werden deine Daten auf diesem Gerät verschlüsselt, bevor sie synchronisiert werden. In der Cloud liegen nur unlesbare Daten: Niemand, auch nicht das Bucktrail-Team, kann sie ohne deine Sicherheitsphrase oder deinen Wiederherstellungsschlüssel lesen. ·
K06 Der Server sieht nur technische Informationen: dein Konto, wie viele Einträge du hast und wann du synchronisierst. ·
K07 Wenn du sowohl die Sicherheitsphrase als auch den Wiederherstellungsschlüssel verlierst, lassen sich die Daten in der Cloud nicht mehr wiederherstellen. Niemand kann das für dich tun. ·
K08 Aktualisiere Bucktrail vor dem Aktivieren auf allen Geräten, die mit diesem Konto verbunden sind: Ältere Versionen synchronisieren danach nicht mehr. ·
K09 Erweiterten Schutz aktivieren · K10 Wähle eine Sicherheitsphrase ·
K11 Mindestens 10 Zeichen, am besten vier oder mehr Wörter. Verwende nicht dein Kontopasswort. Die Phrase verlässt nie dein Gerät. ·
K12 Sicherheitsphrase · K13 Phrase wiederholen · K14 Die Phrase muss mindestens 10 Zeichen lang sein. · K15 Die beiden Phrasen stimmen nicht überein. ·
K16 Dein Wiederherstellungsschlüssel · K17 Bewahre ihn außerhalb dieses Telefons auf, auf Papier oder in einem Passwortmanager. Du brauchst ihn, wenn du die Sicherheitsphrase vergisst. Er wird nicht noch einmal angezeigt. ·
K18 Kopieren · K19 Sichern oder teilen · K20 Gib zur Bestätigung die letzte Gruppe des Schlüssels ein · K21 Ich habe den Schlüssel gesichert ·
K22 Daten werden verschlüsselt … Lass die App geöffnet. · K23 Erweiterter Schutz ist aktiv · K24 Sicherheitsphrase ändern ·
K25 Neuen Wiederherstellungsschlüssel erstellen · K26 Der bisherige Wiederherstellungsschlüssel funktioniert dann nicht mehr. ·
K27 Erweiterten Schutz deaktivieren · K28 Erweiterten Schutz deaktivieren? ·
K29 Deine Daten werden wieder ohne Ende-zu-Ende-Verschlüsselung synchronisiert: geschützt wie zuvor, aber nicht mit einem Schlüssel, den nur du hast. ·
K30 Wird deaktiviert … Lass die App geöffnet. · K31 Synchronisierung pausiert: Gib deine Sicherheitsphrase ein · K32 Synchronisierung entsperren ·
K33 Für dieses Konto ist der erweiterte Schutz aktiv. Gib deine Sicherheitsphrase ein, um deine Cloud-Daten auf diesem Gerät zu lesen. ·
K34 Entsperren · K35 Wiederherstellungsschlüssel verwenden · K36 Wiederherstellungsschlüssel · K37 Phrase oder Schlüssel falsch. ·
K38 Ich habe Phrase und Schlüssel verloren · K39 Mit diesem Gerät neu beginnen? ·
K40 Ohne Sicherheitsphrase und Wiederherstellungsschlüssel können die verschlüsselten Cloud-Daten nicht gelesen werden. Du kannst sie löschen und mit den Daten dieses Geräts neu beginnen. Das lässt sich nicht rückgängig machen. ·
K41 Verschlüsselte Daten löschen und neu beginnen ·
K42 Der erweiterte Schutz wird gerade auf einem anderen Gerät aktiviert oder deaktiviert. Schließe den Vorgang dort ab oder gib hier deine Sicherheitsphrase ein, um fortzufahren. ·
K43 Der Vorgang wurde nicht abgeschlossen. Deine Daten sind sicher: Versuche es erneut. · K44 Aktivierung abbrechen · K45 Erneut versuchen ·
K46 Ein anderes Gerät aktiviert bereits den erweiterten Schutz. · K47 Eine Internetverbindung ist erforderlich. ·
K48 Bestätige deine Identität, um den erweiterten Schutz zu verwalten · K49 Sicherheitsphrase aktualisiert

**es**
K01 Protección avanzada · K02 Cifrado de extremo a extremo de la sincronización · K03 Activada · K04 Desactivada ·
K05 Con la Protección avanzada tus datos se cifran en este dispositivo antes de sincronizarse. En la nube solo quedan datos ilegibles: nadie, ni siquiera quien gestiona Bucktrail, puede leerlos sin tu frase de seguridad o tu clave de recuperación. ·
K06 El servidor solo ve información técnica: tu cuenta, cuántos elementos tienes y cuándo sincronizas. ·
K07 Si pierdes la frase de seguridad y también la clave de recuperación, los datos de la nube ya no se podrán recuperar. Nadie puede hacerlo por ti. ·
K08 Antes de activarla, actualiza Bucktrail en todos los dispositivos conectados a esta cuenta: las versiones anteriores dejarán de sincronizar. ·
K09 Activar Protección avanzada · K10 Elige una frase de seguridad ·
K11 Al menos 10 caracteres: mejor cuatro palabras o más. No uses la contraseña de la cuenta. La frase nunca sale del dispositivo. ·
K12 Frase de seguridad · K13 Repite la frase · K14 La frase debe tener al menos 10 caracteres. · K15 Las dos frases no coinciden. ·
K16 Tu clave de recuperación · K17 Guárdala fuera de este teléfono, en papel o en un gestor de contraseñas. La necesitarás si olvidas la frase de seguridad. No se volverá a mostrar. ·
K18 Copiar · K19 Guardar o compartir · K20 Para confirmar, escribe el último grupo de la clave · K21 He guardado la clave ·
K22 Cifrando los datos… Mantén la app abierta. · K23 Protección avanzada activada · K24 Cambiar frase de seguridad ·
K25 Crear una nueva clave de recuperación · K26 La clave de recuperación anterior dejará de funcionar. · K27 Desactivar Protección avanzada ·
K28 ¿Desactivar la Protección avanzada? · K29 Los datos volverán a sincronizarse sin cifrado de extremo a extremo: protegidos como antes, pero no con una clave solo tuya. ·
K30 Desactivando… Mantén la app abierta. · K31 Sincronización en pausa: introduce la frase de seguridad · K32 Desbloquear la sincronización ·
K33 La Protección avanzada está activada en esta cuenta. Introduce la frase de seguridad para leer los datos de la nube en este dispositivo. ·
K34 Desbloquear · K35 Usar la clave de recuperación · K36 Clave de recuperación · K37 Frase o clave incorrecta. · K38 He perdido la frase y la clave ·
K39 ¿Empezar de nuevo desde este dispositivo? · K40 Sin la frase de seguridad y la clave de recuperación, los datos cifrados de la nube no se pueden leer. Puedes borrarlos y empezar de nuevo con los datos de este dispositivo. Esta acción es irreversible. ·
K41 Borrar los datos cifrados y empezar de nuevo · K42 La Protección avanzada se está activando o desactivando en otro dispositivo. Termina allí la operación o introduce aquí la frase de seguridad para continuar. ·
K43 La operación no se completó. Tus datos están a salvo: inténtalo de nuevo. · K44 Cancelar activación · K45 Reintentar ·
K46 Otro dispositivo ya está activando la Protección avanzada. · K47 Se necesita conexión a internet. ·
K48 Confirma tu identidad para gestionar la Protección avanzada · K49 Frase de seguridad actualizada

**fr**
K01 Protection avancée · K02 Chiffrement de bout en bout de la synchronisation · K03 Activée · K04 Désactivée ·
K05 Avec la Protection avancée, vos données sont chiffrées sur cet appareil avant d'être synchronisées. Le cloud ne contient que des données illisibles : personne, pas même l'équipe de Bucktrail, ne peut les lire sans votre phrase de sécurité ou votre clé de récupération. ·
K06 Le serveur ne voit que des informations techniques : votre compte, le nombre d'éléments et le moment des synchronisations. ·
K07 Si vous perdez à la fois la phrase de sécurité et la clé de récupération, les données du cloud ne pourront plus être récupérées. Personne ne peut le faire à votre place. ·
K08 Avant de l'activer, mettez à jour Bucktrail sur tous les appareils connectés à ce compte : les versions précédentes ne synchroniseront plus. ·
K09 Activer la Protection avancée · K10 Choisissez une phrase de sécurité ·
K11 Au moins 10 caractères : idéalement quatre mots ou plus. N'utilisez pas le mot de passe du compte. La phrase ne quitte jamais l'appareil. ·
K12 Phrase de sécurité · K13 Répétez la phrase · K14 La phrase doit contenir au moins 10 caractères. · K15 Les deux phrases ne correspondent pas. ·
K16 Votre clé de récupération · K17 Conservez-la ailleurs que sur ce téléphone, sur papier ou dans un gestionnaire de mots de passe. Elle sert si vous oubliez la phrase de sécurité. Elle ne sera plus affichée. ·
K18 Copier · K19 Enregistrer ou partager · K20 Pour confirmer, saisissez le dernier groupe de la clé · K21 J'ai enregistré la clé ·
K22 Chiffrement des données… Gardez l'app ouverte. · K23 Protection avancée activée · K24 Changer la phrase de sécurité ·
K25 Créer une nouvelle clé de récupération · K26 L'ancienne clé de récupération ne fonctionnera plus. · K27 Désactiver la Protection avancée ·
K28 Désactiver la Protection avancée ? · K29 Vos données seront de nouveau synchronisées sans chiffrement de bout en bout : protégées comme avant, mais pas avec une clé que vous seul détenez. ·
K30 Désactivation… Gardez l'app ouverte. · K31 Synchronisation en pause : saisissez votre phrase de sécurité · K32 Déverrouiller la synchronisation ·
K33 La Protection avancée est activée sur ce compte. Saisissez votre phrase de sécurité pour lire les données du cloud sur cet appareil. ·
K34 Déverrouiller · K35 Utiliser la clé de récupération · K36 Clé de récupération · K37 Phrase ou clé incorrecte. · K38 J'ai perdu la phrase et la clé ·
K39 Recommencer depuis cet appareil ? · K40 Sans la phrase de sécurité ni la clé de récupération, les données chiffrées du cloud ne peuvent pas être lues. Vous pouvez les supprimer et repartir avec les données de cet appareil. Cette action est irréversible. ·
K41 Supprimer les données chiffrées et recommencer · K42 La Protection avancée est en cours d'activation ou de désactivation sur un autre appareil. Terminez l'opération là-bas, ou saisissez ici votre phrase de sécurité pour continuer. ·
K43 L'opération n'a pas abouti. Vos données sont en sécurité : réessayez. · K44 Annuler l'activation · K45 Réessayer ·
K46 Un autre appareil active déjà la Protection avancée. · K47 Une connexion Internet est nécessaire. ·
K48 Confirmez votre identité pour gérer la Protection avancée · K49 Phrase de sécurité mise à jour

**ja**
K01 高度な保護 · K02 同期のエンドツーエンド暗号化 · K03 オン · K04 オフ ·
K05 高度な保護をオンにすると、データは同期の前にこのデバイス上で暗号化されます。クラウドに残るのは読み取れないデータだけです。セキュリティフレーズまたは復旧キーがなければ、Bucktrailの運営者を含め誰も読むことはできません。 ·
K06 サーバーに見えるのは技術的な情報だけです：アカウント、項目の数、同期した時刻。 ·
K07 セキュリティフレーズと復旧キーの両方をなくすと、クラウドのデータは二度と復元できません。誰にも代わりに復元することはできません。 ·
K08 オンにする前に、このアカウントにつながっているすべてのデバイスでBucktrailをアップデートしてください。古いバージョンは同期できなくなります。 ·
K09 高度な保護をオンにする · K10 セキュリティフレーズを決めてください ·
K11 10文字以上。4語以上がおすすめです。アカウントのパスワードは使わないでください。フレーズがデバイスの外に出ることはありません。 ·
K12 セキュリティフレーズ · K13 もう一度入力 · K14 フレーズは10文字以上にしてください。 · K15 2つのフレーズが一致しません。 ·
K16 あなたの復旧キー · K17 この電話以外の場所（紙やパスワード管理アプリ）に保管してください。セキュリティフレーズを忘れたときに必要です。今後は表示されません。 ·
K18 コピー · K19 保存または共有 · K20 確認のため、キーの最後のグループを入力してください · K21 キーを保存しました ·
K22 データを暗号化しています… アプリを開いたままにしてください。 · K23 高度な保護はオンです · K24 セキュリティフレーズを変更 ·
K25 新しい復旧キーを作成 · K26 以前の復旧キーは使えなくなります。 · K27 高度な保護をオフにする · K28 高度な保護をオフにしますか？ ·
K29 データは再びエンドツーエンド暗号化なしで同期されます。これまでどおり保護されますが、あなただけが持つキーによる保護ではなくなります。 ·
K30 オフにしています… アプリを開いたままにしてください。 · K31 同期を一時停止中：セキュリティフレーズを入力してください · K32 同期のロックを解除 ·
K33 このアカウントでは高度な保護がオンになっています。このデバイスでクラウドのデータを読むには、セキュリティフレーズを入力してください。 ·
K34 ロックを解除 · K35 復旧キーを使う · K36 復旧キー · K37 フレーズまたはキーが正しくありません。 · K38 フレーズとキーの両方をなくした ·
K39 このデバイスからやり直しますか？ · K40 セキュリティフレーズと復旧キーがなければ、クラウドの暗号化データは読めません。削除して、このデバイスのデータでやり直すことができます。この操作は取り消せません。 ·
K41 暗号化データを削除してやり直す · K42 別のデバイスで高度な保護のオン／オフを処理中です。そちらで完了させるか、ここでセキュリティフレーズを入力して続行してください。 ·
K43 操作を完了できませんでした。データは安全です。もう一度お試しください。 · K44 設定をキャンセル · K45 再試行 ·
K46 別のデバイスがすでに高度な保護をオンにしています。 · K47 インターネット接続が必要です。 ·
K48 高度な保護を管理するため本人確認をしてください · K49 セキュリティフレーズを更新しました

**zh-Hans** (Android: `values-b+zh+Hans`)
K01 高级保护 · K02 同步的端到端加密 · K03 已开启 · K04 已关闭 ·
K05 开启高级保护后，你的数据会先在此设备上加密，再进行同步。云端只保存无法读取的数据：没有你的安全短语或恢复密钥，任何人（包括 Bucktrail 的运营者）都无法读取。 ·
K06 服务器只能看到技术信息：你的账户、条目数量以及同步时间。 ·
K07 如果同时丢失安全短语和恢复密钥，云端数据将无法恢复。任何人都无法替你恢复。 ·
K08 开启前，请在登录此账户的所有设备上更新 Bucktrail：旧版本将停止同步。 ·
K09 开启高级保护 · K10 设置安全短语 · K11 至少 10 个字符，最好使用四个或更多单词。不要使用账户密码。安全短语永远不会离开你的设备。 ·
K12 安全短语 · K13 再次输入 · K14 安全短语至少需要 10 个字符。 · K15 两次输入的短语不一致。 ·
K16 你的恢复密钥 · K17 请将它保存在此手机以外的地方，例如纸上或密码管理器中。忘记安全短语时需要用到它。它不会再次显示。 ·
K18 复制 · K19 保存或分享 · K20 请输入密钥的最后一组以确认 · K21 我已保存密钥 ·
K22 正在加密数据…请保持应用打开。 · K23 高级保护已开启 · K24 更改安全短语 · K25 创建新的恢复密钥 · K26 之前的恢复密钥将失效。 ·
K27 关闭高级保护 · K28 要关闭高级保护吗？ · K29 数据将重新以非端到端加密的方式同步：保护方式与之前相同，但不再使用只有你持有的密钥。 ·
K30 正在关闭…请保持应用打开。 · K31 同步已暂停：请输入安全短语 · K32 解锁同步 ·
K33 此账户已开启高级保护。请输入安全短语，以在此设备上读取云端数据。 ·
K34 解锁 · K35 使用恢复密钥 · K36 恢复密钥 · K37 安全短语或密钥不正确。 · K38 安全短语和密钥都丢失了 ·
K39 要从此设备重新开始吗？ · K40 没有安全短语和恢复密钥，就无法读取云端的加密数据。你可以删除这些数据，并用此设备上的数据重新开始。此操作无法撤销。 ·
K41 删除加密数据并重新开始 · K42 另一台设备正在开启或关闭高级保护。请在那台设备上完成，或在此输入安全短语继续。 ·
K43 操作未完成。你的数据是安全的，请重试。 · K44 取消开启 · K45 重试 · K46 另一台设备已在开启高级保护。 · K47 需要互联网连接。 ·
K48 请验证身份以管理高级保护 · K49 安全短语已更新

### 5.4 D-014 (prima il mockup)
D-014 chiede l'approvazione di Matteo prima del codice di una funzione nuova. Qui la funzione è già decisa da Matteo e il codice resta
**dietro l'interruttore spento**: l'approvazione visiva avviene nel task S-50o (screenshot di tutte le schermate in chiaro e scuro, it+en)
**prima** dell'accensione. Se Matteo chiede cambi, si correggono prima di S-50p.

---

## 6. Schema server

### 6.1 Perché una modifica SQL è inevitabile (e perché è sicura)
Senza toccare il database ci sono due sole strade: mettere il cifrato dentro colonne esistenti (es. `name`) o aggiungere colonne.
Entrambe falliscono sullo stesso punto: **un client vecchio** (non aggiornato) continua a fare upsert in chiaro su `mt_*` a ogni push
(iOS carica sempre tutti i conti/budget/obiettivi/regole). Risultato: o sovrascrive il cifrato con dati segnaposto (perdita di dati), o
rimette i dati in chiaro sul server (protezione annullata). L'unico modo affidabile di fermare un client che non possiamo aggiornare è che
**il server rifiuti** le sue scritture. Quindi: due tabelle nuove + un trigger di guardia. Tutto **additivo** (nessuna colonna esistente
cambia, nessuna policy esistente viene toccata), **idempotente** (si può rieseguire), **reversibile** (§6.4), e **inerte** per chi non
attiva l'opzione: il trigger controlla solo se esiste una riga in `mt_e2e` per quell'utente, e nessun client la crea finché l'interruttore è spento.

**Scelta del trigger invece di una policy RLS restrittiva:** una violazione RLS restituisce HTTP 403, che il client Android vecchio
tratta come «sessione scaduta» (rinnova il token a ogni tentativo). Il trigger solleva `P0001` con messaggio `bt_e2e_active` → HTTP 400:
i client vecchi registrano un errore e riprovano con il loro backoff (max 60 s), senza uscire dall'account e senza cancellare nulla; i client
nuovi riconoscono il messaggio.

### 6.2 Lo script (da incollare UNA volta; rieseguirlo non fa danni)
```sql
-- Bucktrail · S-50 · Protezione avanzata (E2E) · schema v1
-- Additivo, idempotente, reversibile. Non modifica colonne né policy esistenti.
begin;

create table if not exists public.mt_e2e (
  user_id                 uuid primary key references auth.users(id) on delete cascade,
  state                   text not null check (state in ('migrating','active','disabling')),
  version                 int  not null default 1 check (version = 1),
  kdf                     text not null default 'pbkdf2-sha256' check (kdf = 'pbkdf2-sha256'),
  kdf_iterations          int  not null check (kdf_iterations between 100000 and 10000000),
  salt                    text not null check (length(salt) between 16 and 64),
  wrapped_key_passphrase  text not null check (wrapped_key_passphrase like 'bt1.%' and length(wrapped_key_passphrase) < 512),
  wrapped_key_recovery    text not null check (wrapped_key_recovery  like 'bt1.%' and length(wrapped_key_recovery)  < 512),
  key_id                  text not null check (key_id ~ '^[0-9a-f]{16}$'),
  updated_at              timestamptz not null default now()
);

create table if not exists public.mt_vault (
  id       uuid primary key,
  user_id  uuid not null references auth.users(id) on delete cascade,
  kind     text not null check (kind in ('account','transaction','budget','goal','rule')),
  payload  text not null check (payload like 'bt1.%' and length(payload) < 65536)
);
create index if not exists mt_vault_user_kind_idx on public.mt_vault (user_id, kind, id);

alter table public.mt_e2e   enable row level security;
alter table public.mt_vault enable row level security;

-- Policy solo sulle due tabelle NUOVE (drop+create = idempotente; le policy di mt_* non si toccano)
drop policy if exists mt_e2e_select on public.mt_e2e;
drop policy if exists mt_e2e_insert on public.mt_e2e;
drop policy if exists mt_e2e_update on public.mt_e2e;
drop policy if exists mt_e2e_delete on public.mt_e2e;
create policy mt_e2e_select on public.mt_e2e for select to authenticated using (user_id = (select auth.uid()));
create policy mt_e2e_insert on public.mt_e2e for insert to authenticated with check (user_id = (select auth.uid()));
create policy mt_e2e_update on public.mt_e2e for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy mt_e2e_delete on public.mt_e2e for delete to authenticated using (user_id = (select auth.uid()));

drop policy if exists mt_vault_select on public.mt_vault;
drop policy if exists mt_vault_insert on public.mt_vault;
drop policy if exists mt_vault_update on public.mt_vault;
drop policy if exists mt_vault_delete on public.mt_vault;
create policy mt_vault_select on public.mt_vault for select to authenticated using (user_id = (select auth.uid()));
create policy mt_vault_insert on public.mt_vault for insert to authenticated with check (user_id = (select auth.uid()));
create policy mt_vault_update on public.mt_vault for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()));
create policy mt_vault_delete on public.mt_vault for delete to authenticated using (user_id = (select auth.uid()));

-- Guardia: con la protezione attiva (o in attivazione) le tabelle in chiaro non accettano scritture;
-- durante l'attivazione non accettano nemmeno cancellazioni (la copia in chiaro è il punto di ritorno).
create or replace function public.mt_e2e_guard() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  -- Solo le richieste dell'app (ruolo authenticated). Funzioni di sistema e security definer
  -- (es. delete_own_account) e le cancellazioni a cascata non vengono mai bloccate.
  if current_user <> 'authenticated' then
    return coalesce(new, old);
  end if;
  if tg_op = 'DELETE' then
    if exists (select 1 from public.mt_e2e k where k.user_id = old.user_id and k.state = 'migrating') then
      raise exception 'bt_e2e_migrating' using errcode = 'P0001';
    end if;
    return old;
  end if;
  if exists (select 1 from public.mt_e2e k where k.user_id = new.user_id and k.state in ('migrating','active')) then
    raise exception 'bt_e2e_active' using errcode = 'P0001';
  end if;
  return new;
end $$;

do $$
declare t text;
begin
  foreach t in array array['mt_accounts','mt_transactions','mt_budgets','mt_goals','mt_recurring_rules'] loop
    execute format('drop trigger if exists mt_e2e_guard on public.%I', t);
    execute format('create trigger mt_e2e_guard before insert or update or delete on public.%I for each row execute function public.mt_e2e_guard()', t);
  end loop;
end $$;

notify pgrst, 'reload schema';
commit;

-- Verifica (deve restituire 13 righe: 8 policy nuove + 5 trigger)
select 'policy' as tipo, tablename as tabella, policyname as nome from pg_policies where tablename in ('mt_e2e','mt_vault')
union all
select 'trigger', event_object_table, trigger_name from information_schema.triggers where trigger_name = 'mt_e2e_guard' and event_manipulation = 'INSERT'
order by 1, 2, 3;
```

### 6.3 Istruzioni per Matteo (AGENTS.md §6.13) — passo S-50n
📍 **Dove:** browser → supabase.com → il progetto di Bucktrail → menu a sinistra **SQL Editor** → **New query**.
▶️ **Cosa:** incolla tutto il blocco SQL del §6.2 (da `-- Bucktrail` fino all'ultima riga `order by 1, 2, 3;`) e premi **Run**.
↩️ **Riportami:** il numero di righe della tabella che compare in basso (devono essere **13**) oppure il testo dell'errore, se compare.
Nota per Matteo: lo script non cambia nulla per l'app attuale; è inerte finché nessuno attiva la Protezione avanzata.

### 6.4 Script di ritorno (SOLO se Matteo lo chiede; cancella i dati cifrati di chi ha attivato la protezione)
```sql
begin;
do $$ declare t text; begin
  foreach t in array array['mt_accounts','mt_transactions','mt_budgets','mt_goals','mt_recurring_rules'] loop
    execute format('drop trigger if exists mt_e2e_guard on public.%I', t);
  end loop; end $$;
drop function if exists public.mt_e2e_guard();
drop table if exists public.mt_vault;
drop table if exists public.mt_e2e;
notify pgrst, 'reload schema';
commit;
```

### 6.5 Cosa vede un client vecchio
| Situazione | iOS vecchio | Android vecchio | Esito |
|---|---|---|---|
| Protezione mai attivata | nulla cambia | nulla cambia | identico a oggi |
| `migrating` | push: l'upsert fallisce (`bt_e2e_active`) → retry col backoff; pull: legge le righe in chiaro congelate | push `Failed` → retry; pull normale | nessuna perdita, la copia in chiaro resta intatta |
| `active` (tabelle in chiaro vuote) | push fallisce sempre (retry ≤ 60 s); pull: remoto vuoto + locale pieno → «pull skipped» | push `Failed`; pull: nessun conto remoto → `Skipped` | il vecchio client smette di sincronizzare, **non cancella e non scrive nulla**; i suoi dati locali restano |
| `disabling` | scritture di nuovo permesse | idem | rischio accettato (§11 R4) |
| Riga cifrata | non la vede mai (sta in `mt_vault`, che i vecchi client non leggono) | idem | nessuna corruzione possibile |

Protocollo versionato: `bt1.` nei payload, `version = 1` in `mt_e2e`. Un client nuovo che trova `version` ≠ 1 o un prefisso ignoto
mette la sync in pausa (stato «bloccato», messaggio K43) e **non scrive**.

### 6.6 Server finto (`03_CODICE/bucktrail-android/scripts/fake-supabase.py`) — estensioni richieste
- Chiave primaria per tabella: `mt_e2e` → `user_id`; tutte le altre → `id`.
- Filtri su GET e DELETE: `kind=eq.<x>` e `user_id=eq.<x>`; `select=` con più colonne; `on_conflict=` ignorato (upsert per PK).
- `POST` senza `Prefer: resolution=merge-duplicates` su `mt_e2e` con riga già esistente → **409** `{"code":"23505","message":"duplicate key value violates unique constraint"}`.
- `PATCH /rest/v1/mt_e2e?user_id=eq.X` (aggiornamento di `state`, chiavi) → 204.
- Emulazione del trigger: scrittura su `mt_accounts|mt_transactions|mt_budgets|mt_goals|mt_recurring_rules` con stato `migrating|active`
  → **400** `{"code":"P0001","message":"bt_e2e_active"}`; DELETE su quelle tabelle con stato `migrating` → 400 `bt_e2e_migrating`.
- `FAKE_NO_E2E=1` → GET/POST su `mt_e2e`/`mt_vault` rispondono **404** `{"code":"PGRST205","message":"Could not find the table"}` (SQL non applicato).
- `FAKE_FAIL_AFTER=N` → dopo N richieste di scrittura riuscite risponde 503 a tutte (interruzione a metà migrazione).
- Il payload non va MAI trasformato (nessun lowercase su `payload`).
- Prova automatica: `03_CODICE/bucktrail-android/scripts/test-fake-supabase-e2e.py` (solo libreria standard: avvia il server su una porta libera,
  prova ogni regola sopra con `urllib`, lo spegne). Comando: `python3 -I 03_CODICE/bucktrail-android/scripts/test-fake-supabase-e2e.py`.

### 6.7 S-50q · Guardia atomica sul vault (secondo script, dopo il §6.2)
**Problemi che chiude** (collaudo blocco 2):
1. `mt_vault` non ha guardia. Una cancellazione o una scrittura ritardata di un'attivazione vecchia (D7, rollback, upsert in ritardo) può
   toccare il vault di un'attivazione nuova, perché gli id delle righe (uuid delle entità) sono gli stessi a ogni attivazione.
2. A6 (`migrating→active`) non è atomico rispetto a un rollback concorrente: un secondo dispositivo con la DEK può svuotare il vault
   fra A5 e A6, e A6 passa lo stesso.

**Soluzione:**
- (a) colonna `key_id` in `mt_vault` e trigger `mt_vault_guard`. Le scritture dell'app (insert/update) passano solo se
  `new.key_id` è la chiave viva (`mt_e2e.key_id`) e lo stato è `migrating`/`active`. Le cancellazioni di righe della chiave viva sono
  vietate in `disabling` (il vault è il punto di ritorno se D5 fallisce). Le righe di chiavi morte, o senza riga `mt_e2e`, si possono
  cancellare (D7 avviene dopo D6, quindi senza riga). Un D7 ritardato non tocca il vault nuovo perché **i client filtrano ogni DELETE
  su `mt_vault` con `key_id=eq.<chiave>`**, e il trigger impedisce che una riga venga riscritta con la chiave vecchia.
- (b) funzione `mt_e2e_activate`: blocca la riga `mt_e2e` (`for update`), controlla stato, `key_id` e generazione (`updated_at`),
  conta le righe del vault per `kind` con quella chiave e passa ad `active` solo se i conteggi coincidono. Il trigger
  `mt_e2e_state_guard` vieta il passaggio diretto `migrating→active` via PATCH, così A6 passa per forza dalla funzione. Il rollback resta
  la DELETE condizionata già usata (`user_id`+`key_id`+`state=migrating`+`updated_at`): stesso lock di riga, vince uno solo.
- Tutto inerte finché l'interruttore è spento (nessun client scrive `mt_e2e`/`mt_vault`). `mt_vault` oggi è vuota.

```sql
-- Bucktrail · S-50q · Guardia atomica sul vault · schema v1.1 (dopo lo script S-50n)
-- Additivo, idempotente, reversibile (§6.4 bis). Non tocca tabelle mt_* in chiaro né policy esistenti.
begin;

-- (a) Chiave di appartenenza delle righe del vault
alter table public.mt_vault add column if not exists key_id text;
alter table public.mt_vault drop constraint if exists mt_vault_key_id_format;
alter table public.mt_vault add constraint mt_vault_key_id_format check (key_id is null or key_id ~ '^[0-9a-f]{16}$');
create index if not exists mt_vault_user_key_kind_idx on public.mt_vault (user_id, key_id, kind);

create or replace function public.mt_vault_guard() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare k record;
begin
  -- Solo le richieste dell'app. Cascate, delete_own_account e funzioni di sistema passano.
  if current_user <> 'authenticated' then
    return coalesce(new, old);
  end if;
  select e.state, e.key_id into k from public.mt_e2e e where e.user_id = coalesce(new.user_id, old.user_id);
  if tg_op = 'DELETE' then
    -- Righe della chiave viva: intoccabili durante la disattivazione (punto di ritorno se D5 fallisce).
    if found and old.key_id is not distinct from k.key_id and k.state = 'disabling' then
      raise exception 'bt_e2e_vault_locked' using errcode = 'P0001';
    end if;
    return old; -- righe di chiavi morte o senza protezione: pulizia ammessa
  end if;
  if not found or k.state not in ('migrating','active') or new.key_id is distinct from k.key_id then
    raise exception 'bt_e2e_key_mismatch' using errcode = 'P0001';
  end if;
  return new;
end $$;

drop trigger if exists mt_vault_guard on public.mt_vault;
create trigger mt_vault_guard before insert or update or delete on public.mt_vault
  for each row execute function public.mt_vault_guard();

-- (b) A6 atomico: migrating -> active solo con il vault completo
create or replace function public.mt_e2e_state_guard() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated'
     and old.state = 'migrating' and new.state = 'active'
     and coalesce(current_setting('bt.e2e_activate', true), '') <> 'on' then
    raise exception 'bt_e2e_use_activate' using errcode = 'P0001';
  end if;
  return new;
end $$;

drop trigger if exists mt_e2e_state_guard on public.mt_e2e;
create trigger mt_e2e_state_guard before update on public.mt_e2e
  for each row execute function public.mt_e2e_state_guard();

create or replace function public.mt_e2e_activate(
  p_key_id text, p_from_generation timestamptz, p_to_generation timestamptz, p_counts jsonb
) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  k public.mt_e2e%rowtype;
  kinds text[] := array['account','transaction','budget','goal','rule'];
  kd text;
  expected bigint;
  actual bigint;
begin
  select * into k from public.mt_e2e where user_id = (select auth.uid()) for update;
  if not found or k.state <> 'migrating' or k.key_id <> p_key_id
     or k.updated_at is distinct from p_from_generation then
    raise exception 'bt_e2e_state_changed' using errcode = 'P0001';
  end if;
  foreach kd in array kinds loop
    expected := coalesce((p_counts ->> kd)::bigint, 0);
    select count(*) into actual from public.mt_vault v
      where v.user_id = k.user_id and v.key_id = p_key_id and v.kind = kd;
    if actual <> expected then
      raise exception 'bt_e2e_counts' using errcode = 'P0001', detail = kd || ': ' || actual || ' <> ' || expected;
    end if;
  end loop;
  perform set_config('bt.e2e_activate', 'on', true);
  update public.mt_e2e set state = 'active', updated_at = p_to_generation where user_id = k.user_id;
  perform set_config('bt.e2e_activate', '', true);
end $$;

revoke all on function public.mt_e2e_activate(text, timestamptz, timestamptz, jsonb) from public, anon;
grant execute on function public.mt_e2e_activate(text, timestamptz, timestamptz, jsonb) to authenticated;

notify pgrst, 'reload schema';
commit;

-- Verifica (deve restituire 4 righe: colonna, 2 trigger, funzione)
select 'colonna' as tipo, column_name as nome from information_schema.columns
  where table_schema = 'public' and table_name = 'mt_vault' and column_name = 'key_id'
union all
select 'trigger', trigger_name from information_schema.triggers
  where trigger_name in ('mt_vault_guard','mt_e2e_state_guard') and event_manipulation in ('INSERT','UPDATE')
  group by trigger_name
union all
select 'funzione', proname from pg_proc where proname = 'mt_e2e_activate'
order by 1, 2;
```

**Ritorno di S-50q (§6.4 bis, solo se Matteo lo chiede):**
```sql
begin;
drop function if exists public.mt_e2e_activate(text, timestamptz, timestamptz, jsonb);
drop trigger if exists mt_e2e_state_guard on public.mt_e2e;
drop function if exists public.mt_e2e_state_guard();
drop trigger if exists mt_vault_guard on public.mt_vault;
drop function if exists public.mt_vault_guard();
drop index if exists public.mt_vault_user_key_kind_idx;
alter table public.mt_vault drop constraint if exists mt_vault_key_id_format;
alter table public.mt_vault drop column if exists key_id;
notify pgrst, 'reload schema';
commit;
```
Va eseguito **prima** del §6.4 se si vuole togliere tutto.

**Cosa cambia nei client (S-50q, parte Codex, dopo che Matteo ha eseguito lo script):**
| Punto | iOS e Android |
|---|---|
| Upsert nel vault (A4, push in modalità vault) | ogni riga porta `key_id` = chiave viva |
| Ogni DELETE su `mt_vault` (orfani, rollback, D7, «Ricomincia») | filtro obbligatorio `key_id=eq.<chiave dell'operazione>` |
| A6 | `POST /rest/v1/rpc/mt_e2e_activate` con `{p_key_id, p_from_generation, p_to_generation, p_counts}` (conteggi del locale verificato in A5). Errori `bt_e2e_state_changed`/`bt_e2e_counts` → come «stato cambiato» oggi (ricalcolo, nessun passo distruttivo) |
| Nuovi messaggi da riconoscere | `bt_e2e_key_mismatch`, `bt_e2e_vault_locked`, `bt_e2e_use_activate` → stato cambiato, ricalcolo della modalità |
| Server finto | colonna `key_id`, emulazione dei due trigger e della RPC con gli stessi messaggi; test: D7 ritardato dopo una nuova attivazione non cancella nulla; rollback fra A5 e A6 → `bt_e2e_counts`; PATCH diretta `migrating→active` → 400 |

### 6.8 Istruzioni per Matteo — passo S-50q
📍 **Dove:** browser → supabase.com → progetto Bucktrail → **SQL Editor** → **New query**.
▶️ **Cosa:** incolla il blocco SQL del §6.7 (da `-- Bucktrail · S-50q` fino a `order by 1, 2;`) e premi **Run**.
↩️ **Riportami:** il numero di righe in basso (devono essere **4**) oppure il testo dell'errore.
Lo script non cambia nulla per l'app attuale: è inerte finché la Protezione avanzata è spenta.

### 6.9 S-50q.1 · Rollback atomico (terzo script, dopo il §6.7)
**Difetto trovato da Codex (2026-11-26):** `mt_e2e_activate` blocca la riga `mt_e2e`, ma le DELETE sul vault non la leggevano con un lock.
Un rollback che cancellava il vault mentre A6 era a metà poteva chiudersi dopo i conteggi, e il risultato era `active` con il vault vuoto.
Inoltre il rollback dei client cancellava prima il vault e solo dopo la riga di stato.

**Correzione:**
1. `mt_vault_guard` legge la riga `mt_e2e` con `for share`. Ogni scrittura o cancellazione dell'app nel vault aspetta che
   `mt_e2e_activate`/`mt_e2e_rollback` abbiano finito, e poi rilegge lo stato aggiornato.
2. Nuova funzione `mt_e2e_rollback(p_key_id, p_generation)`: in un'unica transazione blocca la riga, controlla `migrating`, chiave e
   generazione, cancella la riga di stato e poi le righe del vault di quella chiave.
3. `mt_e2e_state_guard` ora vale anche sulle DELETE: da `migrating` si esce solo tramite le due funzioni (`bt_e2e_use_rollback` per
   una DELETE diretta, `bt_e2e_use_activate` per una PATCH ad `active`).

**Provato su PostgreSQL 16 (2026-11-26 10:37, due sessioni concorrenti):** rollback durante A6 → `bt_e2e_state_changed`, stato `active`, vault intatto ·
A6 durante il rollback → `bt_e2e_state_changed`, niente riga, vault vuoto · cancellazione di un orfano durante A6 → `bt_e2e_counts` ·
DELETE diretta in `migrating` → `bt_e2e_use_rollback` · disattivazione D6/D7 invariata · `anon` escluso · script rieseguibile.

```sql
-- Bucktrail · S-50q.1 · Rollback atomico e lock sul vault · schema v1.2 (dopo S-50q)
-- Additivo, idempotente, reversibile (§6.4 ter). Sostituisce solo funzioni create da S-50q.
begin;

-- (1) Ogni scrittura o cancellazione dell'app nel vault prende un lock condiviso sulla riga mt_e2e:
--     non può più chiudersi mentre mt_e2e_activate / mt_e2e_rollback tengono la riga.
create or replace function public.mt_vault_guard() returns trigger
language plpgsql security invoker set search_path = '' as $$
declare k record;
begin
  if current_user <> 'authenticated' then
    return coalesce(new, old);
  end if;
  select e.state, e.key_id into k from public.mt_e2e e
    where e.user_id = coalesce(new.user_id, old.user_id) for share;
  if tg_op = 'DELETE' then
    if found and old.key_id is not distinct from k.key_id and k.state = 'disabling' then
      raise exception 'bt_e2e_vault_locked' using errcode = 'P0001';
    end if;
    return old;
  end if;
  if not found or k.state not in ('migrating','active') or new.key_id is distinct from k.key_id then
    raise exception 'bt_e2e_key_mismatch' using errcode = 'P0001';
  end if;
  return new;
end $$;

-- (2) Uscire da 'migrating' si può solo con le due funzioni: niente PATCH ad active, niente DELETE diretta.
create or replace function public.mt_e2e_state_guard() returns trigger
language plpgsql security invoker set search_path = '' as $$
begin
  if current_user = 'authenticated' and old.state = 'migrating'
     and coalesce(current_setting('bt.e2e_transition', true), '') <> 'on' then
    if tg_op = 'DELETE' then
      raise exception 'bt_e2e_use_rollback' using errcode = 'P0001';
    elsif new.state = 'active' then
      raise exception 'bt_e2e_use_activate' using errcode = 'P0001';
    end if;
  end if;
  return coalesce(new, old);
end $$;

drop trigger if exists mt_e2e_state_guard on public.mt_e2e;
create trigger mt_e2e_state_guard before update or delete on public.mt_e2e
  for each row execute function public.mt_e2e_state_guard();

create or replace function public.mt_e2e_activate(
  p_key_id text, p_from_generation timestamptz, p_to_generation timestamptz, p_counts jsonb
) returns void
language plpgsql security invoker set search_path = '' as $$
declare
  k public.mt_e2e%rowtype;
  kd text;
  expected bigint;
  actual bigint;
begin
  select * into k from public.mt_e2e where user_id = (select auth.uid()) for update;
  if not found or k.state <> 'migrating' or k.key_id <> p_key_id
     or k.updated_at is distinct from p_from_generation then
    raise exception 'bt_e2e_state_changed' using errcode = 'P0001';
  end if;
  foreach kd in array array['account','transaction','budget','goal','rule'] loop
    expected := coalesce((p_counts ->> kd)::bigint, 0);
    select count(*) into actual from public.mt_vault v
      where v.user_id = k.user_id and v.key_id = p_key_id and v.kind = kd;
    if actual <> expected then
      raise exception 'bt_e2e_counts' using errcode = 'P0001', detail = kd || ': ' || actual || ' <> ' || expected;
    end if;
  end loop;
  perform set_config('bt.e2e_transition', 'on', true);
  update public.mt_e2e set state = 'active', updated_at = p_to_generation where user_id = k.user_id;
  perform set_config('bt.e2e_transition', '', true);
end $$;

-- (3) Rollback dell'attivazione in un'unica transazione: riga di stato e vault insieme, o niente.
create or replace function public.mt_e2e_rollback(p_key_id text, p_generation timestamptz) returns void
language plpgsql security invoker set search_path = '' as $$
declare k public.mt_e2e%rowtype;
begin
  select * into k from public.mt_e2e where user_id = (select auth.uid()) for update;
  if not found or k.state <> 'migrating' or k.key_id <> p_key_id
     or k.updated_at is distinct from p_generation then
    raise exception 'bt_e2e_state_changed' using errcode = 'P0001';
  end if;
  perform set_config('bt.e2e_transition', 'on', true);
  delete from public.mt_e2e where user_id = k.user_id;
  perform set_config('bt.e2e_transition', '', true);
  delete from public.mt_vault where user_id = k.user_id and key_id = p_key_id;
end $$;

revoke all on function public.mt_e2e_activate(text, timestamptz, timestamptz, jsonb) from public, anon;
grant execute on function public.mt_e2e_activate(text, timestamptz, timestamptz, jsonb) to authenticated;
revoke all on function public.mt_e2e_rollback(text, timestamptz) from public, anon;
grant execute on function public.mt_e2e_rollback(text, timestamptz) to authenticated;

notify pgrst, 'reload schema';
commit;

-- Verifica (deve restituire 3 righe: funzione mt_e2e_rollback, trigger mt_e2e_state_guard su DELETE, lock nel guard)
select 'funzione' as tipo, proname as nome from pg_proc where proname = 'mt_e2e_rollback'
union all
select 'trigger su delete', trigger_name from information_schema.triggers
  where trigger_name = 'mt_e2e_state_guard' and event_manipulation = 'DELETE'
union all
select 'lock nel vault', proname from pg_proc where proname = 'mt_vault_guard' and prosrc like '%for share%'
order by 1, 2;
```

**Ritorno di S-50q.1 (§6.4 ter, solo se Matteo lo chiede):** rieseguire il blocco SQL del §6.7, poi `drop function if exists public.mt_e2e_rollback(text, timestamptz);`.

**Cosa cambia nei client (Codex):**
| Punto | iOS e Android |
|---|---|
| Rollback dell'attivazione (§7.7, K44, automatico dopo 2 verifiche fallite) | una sola chiamata `POST /rest/v1/rpc/mt_e2e_rollback` con `{p_key_id, p_generation}`, al posto di «svuota il vault, poi DELETE condizionata». **Mai** cancellare righe del vault della chiave viva con la REST durante un rollback. `bt_e2e_state_changed` → ricalcolo (A6 ha vinto: niente rollback) |
| `mt_e2e_activate` | invariata (stessa firma) |
| Nuovo messaggio | `bt_e2e_use_rollback` → stato cambiato, ricalcolo |
| Server finto e test | RPC `mt_e2e_rollback`, DELETE diretta in `migrating` → 400 `bt_e2e_use_rollback`; i test di gara A6/rollback in entrambi gli ordini |

### 6.10 Istruzioni per Matteo — passo S-50q.1
📍 supabase.com → progetto Bucktrail → **SQL Editor** → **New query**.
▶️ Incolla il blocco SQL del §6.9 e premi **Run**.
↩️ In basso devono comparire **3 righe**: funzione `mt_e2e_rollback`, lock nel vault `mt_vault_guard`, trigger su delete `mt_e2e_state_guard`.

---

## 7. Migrazione

### 7.1 Stati
Server (`mt_e2e.state`, autorevole): *(nessuna riga)* → `migrating` → `active` → `disabling` → *(nessuna riga)*.
Locale (marcatore di ripresa, iOS `UserDefaults` chiave `e2e.migration`, Android prefs `bucktrail_e2e` chiave `migration`):
`{"direction":"enable|disable","user_id":"…","key_id":"…","started_at":ms}`. Il marcatore dice «questo dispositivo sta guidando l'operazione».

### 7.2 Modalità decisa a ogni operazione di sync — `E2EGate.resolve()`
Con l'interruttore **spento**: ritorna subito `.plain` senza alcuna richiesta (codice identico a oggi).
Con l'interruttore acceso, una GET `mt_e2e?user_id=eq.<uid>&select=*` (una sola per operazione: `syncOnForeground`, `manualRefresh`,
`syncOnLogin`, push con debounce, retry):
| Risposta | Modalità |
|---|---|
| 404 / `PGRST205` / `42P01` | `.plain`, `serverSupported = false` (riga di Impostazioni nascosta) |
| `[]` | `.plain`; se c'è una DEK locale per questo utente → si cancella e la prossima operazione usa il **percorso di primo accesso** (§7.6) |
| `active`, DEK locale con stesso `key_id` | `.vault(dek)` |
| `active`, nessuna DEK o `key_id` diverso | `.locked(.needsSecret)` (DEK locale eventualmente cancellata) |
| `migrating`/`disabling` + marcatore locale con stessa direzione e `key_id` + DEK | `.resume(direction)` → riprende la migrazione |
| `migrating`/`disabling` senza marcatore | `.locked(.transition)` (testo K42; con la frase si può riprendere qui) |
| `version` ≠ 1 o parametri fuori intervallo | `.locked(.unsupported)` (K43), nessuna scrittura |
| errore di rete / 5xx | l'operazione fallisce come un push fallito oggi (retry esistente) |

In `.locked` push e pull **non partono**, non contano come fallimenti (nessun backoff, nessun «waitingForRetry»), `hasPendingChanges`
resta vero e il dirty tracking continua: le modifiche locali non si perdono e partono dopo lo sblocco.
Se un push in chiaro riceve `bt_e2e_active`, la modalità si ricalcola subito (un altro dispositivo ha attivato).

### 7.3 Attivazione (dispositivo A)
Precondizioni (tutte, altrimenti pulsante disabilitato o errore K47/K43): accesso fatto, rete, non demo, `serverSupported`, nessuna riga
in `mt_e2e`, frase valida, chiave di recupero confermata.
| Passo | Azione | Se si interrompe qui |
|---|---|---|
| A0 | Sync completa in chiaro (push **riuscito** e poi pull riuscito, come `manualRefresh`). Poi controllo di allineamento: per ogni tabella, gli id in chiaro sul server ⊆ id locali; se no → stop (K43), nulla è cambiato. | nulla da fare |
| A1 | **Backup locale**: istantanea JSON (righe nel formato del §3.5, per `kind`) in `Application Support/E2EBackup/backup-<ms>.json` (protezione `.complete`) / `noBackupFilesDir/e2e/backup-<ms>.json`. Se ne tiene una sola; si cancella al logout. Contatori per `kind` e SHA-256 degli id ordinati scritti nel log. | nulla da fare |
| A2 | Genera DEK, salt, chiave di recupero; deriva KEK (fuori dal main thread); avvolge; calcola `key_id`; **salva la DEK nel Keychain/Keystore**; scrive il marcatore locale `enable`. | alla ripresa: nessuna riga server → marcatore e DEK si cancellano, si riparte da capo |
| A3 | `POST mt_e2e` (insert puro, senza merge) con `state = migrating`. 409 → un altro dispositivo sta attivando: cancella DEK e marcatore, K46. Da qui il trigger congela le tabelle in chiaro. | ripresa automatica (`.resume(enable)`) |
| A4 | Upload nel vault: si marcano «sporchi» tutti i movimenti locali e si esegue il **push normale con il trasporto vault** (upsert a blocchi di 200, poi cancellazione degli orfani nel vault). Idempotente. | ripresa da A4 |
| A5 | **Verifica**: lettura di tutto il vault, decifratura, decodifica con i decoder esistenti, confronto con il locale (§7.5). Se fallisce: un secondo giro A4+A5; se fallisce ancora → rollback (§7.7) + K43. | ripresa da A4 |
| A6 | `PATCH mt_e2e set state = active`. | ripresa: vede `active` + marcatore → prosegue da A7 |
| A7 | Cancellazione delle righe in chiaro, tabella per tabella (per id, a blocchi di 100), poi verifica che `select id` restituisca 0 righe per ognuna. | ripresa da A7 (idempotente) |
| A8 | Cancella marcatore, modalità `.vault`, K23. | — |

Durante A0–A8 la sync automatica di quel dispositivo è sospesa (flag `isMigrating`): iOS non lancia push/pull concorrenti; Android esegue
tutto dentro la coda `ops`. Le modifiche fatte dall'utente nel frattempo restano «sporche» e partono al primo push in modalità vault.

### 7.4 Disattivazione (dispositivo con DEK)
| Passo | Azione | Se si interrompe |
|---|---|---|
| D0 | Autenticazione del dispositivo (K48), dialogo K28/K29. | — |
| D1 | Sync completa in modalità vault (push riuscito + pull riuscito). | nulla è cambiato |
| D2 | Backup locale come A1. Marcatore `disable`. | si cancella il marcatore |
| D3 | `PATCH mt_e2e set state = disabling` (il trigger riapre le tabelle in chiaro). | ripresa da D4 |
| D4 | Push normale in chiaro con **tutti** i movimenti marcati sporchi (stesso codice di oggi, compresi gli orfani). | ripresa da D4 |
| D5 | Verifica: lettura delle tabelle in chiaro e confronto col locale (§7.5). Due tentativi; poi rollback della disattivazione: cancella le righe in chiaro, `state = active`, K43. | ripresa da D4 |
| D6 | `DELETE mt_e2e` (riga eliminata: protezione spenta per tutti). | ripresa: nessuna riga + marcatore `disable` → D7 |
| D7 | Cancellazione di tutte le righe del vault e verifica che siano 0. Cancella DEK e marcatore. Modalità `.plain`. | ripresa da D7 |

### 7.5 Prova che nessuna riga si perde (verifica)
Per ogni `kind`: (1) **contatore** locale = contatore remoto; (2) **insieme degli id** uguale; (3) **confronto campo per campo** riga per riga
dopo decodifica con i decoder esistenti (iOS: DTO `SB*`; Android: entità di `SyncMapper`), con queste regole di normalizzazione:
UUID minuscoli; date confrontate al millisecondo con tolleranza ≤ 1 ms; importi confrontati arrotondati a 2 decimali «half-up»
(`NSDecimalRound .plain` / `RoundingMode.HALF_UP`: è la semantica che il server garantisce già oggi); stringhe identiche; `nil` = `null`.
(4) **Ricevuta**: SHA-256 esadecimale delle righe normalizzate ordinate per `kind|id` (stesso algoritmo su entrambe le piattaforme), scritta
nel log prima e dopo: deve coincidere. Qualsiasi differenza = verifica fallita → nessun passo distruttivo.
Le righe del server che non si decifrano o non si decodificano fanno fallire la verifica (mai ignorate in questa fase).

### 7.6 Cambi di modalità e conflitti
- La sync resta quella di oggi: **istantanea completa, vince il remoto al pull, cancellazione = riga assente** (nessun `updated_at`,
  nessun tombstone, nessun last-write-wins per campo). Il vault non cambia questa semantica, quindi non introduce conflitti nuovi.
- Dopo **ogni** cambio di modalità su un dispositivo (sblocco riuscito; protezione spenta altrove) si esegue il **percorso di primo
  accesso** già esistente della piattaforma, nella nuova modalità: iOS `syncOnLogin` (remoto vuoto → push, altrimenti pull); Android
  `initialSync` (se il primo scambio era già avvenuto: push poi pull, con la guardia «cancellazioni anomale»). Nessuna logica nuova di merge.
- Due dispositivi che attivano insieme: vince il primo `POST mt_e2e` (A3); l'altro riceve 409 → K46.
- Un dispositivo in chiaro durante `migrating`: il suo push riceve `bt_e2e_active` → ricalcola → `.locked(.transition)`.

### 7.7 Rollback dell'attivazione (automatico dopo 2 verifiche fallite, o pulsante K44 finché lo stato è `migrating`)
1. Cancella tutte le righe del vault dell'utente; 2. `DELETE mt_e2e` (il trigger torna inerte); 3. cancella DEK, marcatore;
4. modalità `.plain`. Le righe in chiaro non sono mai state toccate (congelate dal trigger), quindi tutti i client — vecchi e nuovi — ripartono come prima.
Il rollback è idempotente. **Dopo A6 non si fa rollback**: i dati sono verificati nel vault, si completa soltanto A7.

### 7.8 «Ricomincia da questo dispositivo» (frase e chiave perse)
Solo da `.locked(.needsSecret)`: dialogo K39/K40 → autenticazione del dispositivo → cancella vault e `mt_e2e` → cancella DEK → modalità
`.plain` → percorso di primo accesso (il cloud è vuoto, quindi push dei dati del dispositivo). Se il dispositivo è vuoto il cloud resta vuoto
(il testo lo dice).

---

## 8. Compatibilità

### 8.1 Interruttore
- iOS: `MoneyTracker/Sync/E2E/E2EFeature.swift` → `enum E2EFeature { static let isEnabled = false; static let allowNewActivations = true }`
  più, **solo in `#if DEBUG`**, l'argomento di avvio `-E2EEnabled YES` che lo forza acceso (test e simulatore).
- Android: `buildConfigField("boolean", "E2E_ENABLED", "false")` in debug e release; in debug `-Pe2e=true` lo accende.
- **Regola:** una volta pubblicata una versione con l'interruttore acceso, NON si torna a spento (gli utenti protetti resterebbero senza sync,
  senza perdite). Per fermare nuove attivazioni si usa `allowNewActivations = false` (nasconde solo K09).

### 8.2 Percorsi esistenti toccati e come restano identici a interruttore spento
| File | Modifica | Garanzia a interruttore spento |
|---|---|---|
| `MoneyTracker/Sync/SyncService.swift` | `private struct SB*` → `struct SB*` (interne) + conformità `SyncRow` (`id`); le chiamate `client.from(...)` spostate dietro il protocollo `SyncRemote` (`PlainRemote` = le stesse chiamate, nello stesso ordine); inizializzatore di test (remoto e userId iniettati, senza `NWPathMonitor`); ingresso `E2EGate` solo `if E2EFeature.isEnabled`; ramo `.locked` in `pushResilient`; in `clearLocalData` cancellazione della DEK (no-op se assente) | test «richieste d'oro» su `PlainRemote` (metodo, percorso, query, corpo JSON identici a oggi); test che con interruttore spento non parte nessuna richiesta a `mt_e2e`/`mt_vault`; suite completa verde |
| `MoneyTracker/Auth/SupabaseManager.swift` | `deleteAccount`: dopo la RPC riuscita, cancellazione al meglio di vault/`mt_e2e` solo se interruttore acceso | ramo inattivo |
| `MoneyTracker/Views/SettingsView.swift` | una riga nella sezione Sicurezza dentro `if E2EFeature.isEnabled …` | non compilata nel percorso visibile; UI test esistenti verdi |
| `MoneyTracker/ContentView.swift` (radice) | modificatore del prompt di sblocco, interno `if E2EFeature.isEnabled` | inattivo |
| `MoneyTracker/*.lproj/Localizable.strings` (7) | solo chiavi `e2e_*` aggiunte in fondo | nessuna chiave esistente cambia |
| Android `sync/SupabaseApi.kt` | `HttpSupabaseApi` implementa anche la nuova interfaccia `VaultApi`; la paginazione di `selectAll` estratta in un helper privato con filtro extra opzionale | `HttpSupabaseApiTest` esistente verde + nuovo test d'oro sugli URL di `selectAll` |
| Android `sync/SyncService.kt` | nuovo parametro finale `e2e: E2EController? = null` | `null` = codice di oggi (i test esistenti lo costruiscono senza) |
| Android `sync/SyncEngine.kt` | nuovo parametro finale `onClear: () -> Unit = {}` chiamato in `clearLocalData` | predefinito no-op |
| Android `BucktrailApplication.kt` | cablaggio di controller/keystore solo `if (BuildConfig.E2E_ENABLED)` | ramo inattivo |
| Android `ui/screens/SettingsSheets.kt`, `ui/BucktrailApp.kt` | riga e prompt dentro `if (BuildConfig.E2E_ENABLED …)` | inattivi |
| Android `res/values*/strings.xml` (7) | solo `e2e_*` aggiunte | — |
| Android `app/build.gradle.kts` | `E2E_ENABLED`, `systemProperty("e2eVectors", …)` per i test | release invariata a parte la costante `false` |
| `fake-supabase.py` | estensioni del §6.6 | i comportamenti esistenti restano (nuovo test python + test Android esistenti) |

**Persistence/Models:** nessuna modifica. Non serve: la DEK sta nel Keychain/Keystore e il marcatore nelle preferenze. `Domain/`, calcoli,
`Export/`, `Intents/`, notifiche e ricorrenze: **non si toccano**.

### 8.3 File nuovi
iOS `MoneyTracker/Sync/E2E/`: `E2EFeature.swift`, `VaultCrypto.swift` (AES-GCM, PBKDF2, HKDF, involucro, key_id), `RecoveryKey.swift`
(Crockford), `VaultJSON.swift`, `E2EKeyStore.swift` (Keychain), `SyncRemote.swift` (protocollo + `SyncTable` + `PlainRemote`),
`VaultRemote.swift`, `E2EServer.swift` (riga `mt_e2e`), `E2EGate.swift`, `E2EVerifier.swift`, `E2EMigrator.swift`, `E2EController.swift`.
iOS `MoneyTracker/Views/E2E/`: `AdvancedProtectionView.swift`, `E2EActivationFlow.swift`, `E2EUnlockView.swift`, `RecoveryKeyCard.swift`.
Test iOS: `MoneyTrackerTests/E2E*Tests.swift`, `MoneyTrackerTests/Fixtures/e2e-vectors-v1.json`, `MoneyTrackerTests/Support/InMemoryRemote.swift`,
`MoneyTrackerUITests/E2EUITests.swift`.
Android `sync/e2e/`: `VaultCrypto.kt`, `RecoveryKey.kt`, `E2EKeyStore.kt`, `VaultApi.kt`, `VaultSupabaseApi.kt`, `E2EGate.kt`,
`E2EVerifier.kt`, `E2EMigrator.kt`, `E2EController.kt`; `ui/screens/AdvancedProtectionScreens.kt`; test in `app/src/test/.../sync/e2e/`
(con un `FakeVaultSupabase` nuovo: **i fake esistenti non si modificano**) e `app/src/androidTest/.../E2EVectorsInstrumentedTest.kt`.

---

## 9. Piano di prova
Tutto automatico, **senza cloud reale**. Comandi (dalla cartella del cantiere):
```bash
# iOS — una suite
xcodebuild test -project MoneyTracker.xcodeproj -scheme MoneyTracker \
  -destination 'id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -only-testing:MoneyTrackerTests/E2ECryptoTests 2>&1 | tail -40
# iOS — tutto (unit + UI), prima di ogni collaudo di blocco
xcodebuild test -project MoneyTracker.xcodeproj -scheme MoneyTracker \
  -destination 'id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' 2>&1 | tail -60
# Android
cd 03_CODICE/bucktrail-android && ./gradlew testDebugUnitTest --tests 'com.bucktrail.android.sync.e2e.*'
cd 03_CODICE/bucktrail-android && ./gradlew assembleDebug lintDebug testDebugUnitTest
cd 03_CODICE/bucktrail-android && ./gradlew connectedDebugAndroidTest   # serve un emulatore acceso (vettori su provider Android reale)
# Server finto
python3 -I 03_CODICE/bucktrail-android/scripts/test-fake-supabase-e2e.py
python3 -I 03_CODICE/bucktrail-android/scripts/e2e-vectors.py --check MoneyTrackerTests/Fixtures/e2e-vectors-v1.json
```
Simulatore di riferimento D-004 (iPhone 18 Pro, iOS 27.2). Se `xcodebuild` resta bloccato: `xcrun simctl shutdown all`, poi riprovare una volta.

| # | Test | Dove | Cosa dimostra |
|---|---|---|---|
| T1 | Vettori §3.7 (tutti i gruppi) | `E2ECryptoTests` (iOS), `VaultCryptoVectorsTest` (JVM), `E2EVectorsInstrumentedTest` (emulatore) | stesse chiavi/involucri sulle due piattaforme; PBKDF2 Unicode identico anche col provider Android vero |
| T2 | Righe incrociate (`rows`): iOS apre le righe prodotte da Android e viceversa, valori attesi uguali | `E2ERowInteropTests` / `RowInteropTest` | iPhone e Android si leggono a vicenda |
| T3 | Negativi: tag alterato, `bt2.`, Base64 rotto, AAD di un altro id/kind/utente, frase sbagliata, chiave di recupero con un carattere errato | come T1 | rifiuto sicuro, nessun crash |
| T4 | Nonce: 10 000 sigilli → nessun nonce ripetuto; nessuna chiamata di produzione passa un nonce | entrambi | uso corretto di GCM |
| T5 | «Richieste d'oro» `PlainRemote` (URLProtocol finto) e `HttpSupabaseApi.selectAll` | iOS / JVM | zero regressioni del trasporto in chiaro |
| T6 | Interruttore spento: push/pull/syncOnLogin su remoto in memoria → nessuna richiesta a `mt_e2e`/`mt_vault`, chiamate identiche a prima | `SyncServiceFlagOffTests` / `E2EFlagOffTest` | chi non attiva non vede differenze |
| T7 | Attivazione completa su remoto in memoria con trigger emulato: contatori, id, campi, ricevuta; tabelle in chiaro vuote alla fine | migratore iOS/Android | nessuna riga persa |
| T8 | Interruzione a ogni passo A2…A7 e D3…D7 (eccezione iniettata), poi ripresa → stesso risultato finale; doppia ripresa idempotente | idem | riprendibile e idempotente |
| T9 | Verifica che fallisce (payload manomesso nel remoto) → secondo giro → rollback; tabelle in chiaro intatte, `mt_e2e` assente | idem | rollback sicuro |
| T10 | Client vecchio: motore di sync **non modificato** (Android: `SyncEngine` con `FakeVaultSupabase` in modalità trigger; iOS: `PlainRemote`) con stato `active` → push fallisce, pull salta, nulla cancellato né scritto | idem | i vecchi client non corrompono |
| T11 | Due dispositivi: A attiva, B (in chiaro) riceve `bt_e2e_active` → `.locked`; B si sblocca con la frase → pull dal vault → stessi dati di A; B disattiva → A torna in chiaro col percorso di primo accesso | remoto in memoria condiviso tra due istanze | secondo dispositivo, cambio telefono |
| T12 | Logout cancella la DEK; cambio utente; `key_id` cambiato altrove; riga `mt_e2e` sparita; `version` = 2 → `.locked(.unsupported)` senza scritture | entrambi | custodia chiavi |
| T13 | Frase dimenticata → chiave di recupero → nuova frase; nuova chiave di recupero invalida la vecchia; «ricomincia» | entrambi | recupero |
| T14 | `.locked`: push non conta come fallimento (nessun backoff), le modifiche locali restano sporche e partono dopo lo sblocco | entrambi | nessuna perdita durante la pausa |
| T15 | Chiavi `e2e_*` presenti in 7 lingue su entrambe le piattaforme, nessuna vuota, segnaposto coerenti | `E2ELocalizationTests` / `E2EStringsTest` | i18n |
| T16 | UI di base: attivazione (frase corta → K14; frasi diverse → K15; chiave mostrata; conferma ultimo gruppo; K23), sblocco con frase sbagliata (K37), dialogo di disattivazione | `E2EUITests` (iOS, con `-E2EEnabled YES -E2EUITestHarness YES`, che in DEBUG apre `AdvancedProtectionView` con un controller su remoto in memoria) / Compose test strumentato | flusso utente |
| T17 | Server finto: tutte le regole del §6.6 | `test-fake-supabase-e2e.py` | il banco di prova è affidabile |
| T18 | Prova d'insieme Android su emulatore col server finto (`-PsupabaseUrl=http://10.0.2.2:54321 -PsupabaseKey=chiave-finta -Pe2e=true`): attiva, crea movimenti, chiudi l'app a metà attivazione con `FAKE_FAIL_AFTER`, riapri e completa; controlla con `curl` che `mt_vault` contenga solo `bt1.` e le tabelle in chiaro siano vuote | manuale-automatizzabile (adb + curl) | flusso reale end-to-end |
| T19 | Suite esistenti: iOS 99 unit + 49 UI, Android 247 JVM + 2 strumentati, tutte verdi e **non modificate** (`git diff --stat` sui file di test esistenti = vuoto) | — | non regressione |

**Prova con Supabase vero (NON autonoma):** passo opzionale S-50o, solo con Matteo e un **account di prova** suo, mai sul suo account reale,
mai senza di lui. Checklist in S-50o.

---

## 10. Piano di lavoro

### 10.1 Regole comuni a tutti i task (R1–R10) — valgono come parte di ogni prompt
- **R1 Turno:** AGENTS.md §4 (STATO «In turno», riga in DIARIO con `date "+%Y-%m-%d %H:%M"`, CONSEGNA riscritta, PIANO con `[~]`,
  STATO «nessuno»). Ruolo: `operaio (Claude Code · Sonnet)`.
- **R2 Commit:** solo i file del task + `.cantiere`: `git add <file> .cantiere && git commit -m "[operaio] <cosa> (S-50x)"`; mai `git add -A`;
  niente push; ramo `redesign-sentiero`. Ultima riga del messaggio: `Co-Authored-By: Claude <noreply@anthropic.com>` (o quella indicata dal sistema).
- **R3 Zone:** autorizzate solo quelle del §8 per questo task. Vietato toccare `Domain/`, calcoli, `Models/`, `Persistence/`, `Export/`,
  `Intents/`, notifiche, ricorrenze e i **test esistenti** (si aggiungono file di test nuovi). Vietati `preferredColorScheme` e colori fissi.
- **R4 Interruttore:** resta **spento** in tutti i task tranne S-50p. Nei test si accende solo con gli strumenti DEBUG del §8.1.
- **R5 Niente cloud reale:** mai usare l'URL Supabase vero, mai la chiave `service_role`. Solo remoti in memoria, URLProtocol finti o `fake-supabase.py`.
- **R6 Orientamento:** prima `graphify query "<domanda>"`, poi solo i file necessari; dopo le modifiche `graphify update .`.
- **R7 Verifica:** i comandi del task devono essere verdi; incolla in CONSEGNA il riassunto (numero di test, esito). Se un test esistente diventa
  rosso: fermati, ripristina, scrivi `[!]` in PIANO con la causa.
- **R8 Dubbi:** se il progetto non copre un caso, scegli l'opzione più conservativa (nessuna scrittura distruttiva) e annotala in CONSEGNA
  come «scelta da confermare»; non inventare testi per l'utente fuori dal §5.3.
- **R9 Semplicità:** solo ciò che il task chiede (AGENTS.md §6.9); niente refactor estranei.
- **R10 Fine task:** proponi il prossimo task con `➡️ Prossimo: S-50y → …`. Dopo S-50d, S-50i, S-50l: collaudo di blocco (subagente
  `collaudatore`, legge solo il diff del blocco, mette `[x]` o riapre).

### 10.2 Ordine e dipendenze
```
S-50a (server finto) ─┐
S-50b (crypto iOS) ───┼─> S-50c (crypto Android) ─> S-50d (SyncRemote iOS) ─> [COLLAUDO BLOCCO 1]
                      │
                      └─> S-50e (vault iOS) ─> S-50f (vault Android) ─> S-50g (righe incrociate)
                           ─> S-50h (migratore iOS) ─> S-50i (migratore Android) ─> [COLLAUDO BLOCCO 2]
                           ─> S-50j (UI iOS) ─> S-50k (UI Android) ─> S-50l (logout/elimina/stress) ─> [COLLAUDO BLOCCO 3]
                           ─> S-50m (Commissione Suprema + manuale) ─> S-50n [Matteo: SQL] ─> S-50o [Matteo: schermate + prova reale]
                           ─> S-50p (accensione + sito)
```
S-50n (SQL) si può fare in qualunque momento dopo S-50a: è inerte.

### 10.3 Task

#### S-50a · Server finto e test del server finto (≈ 1 h)
- **File:** `03_CODICE/bucktrail-android/scripts/fake-supabase.py`, nuovo `scripts/test-fake-supabase-e2e.py`.
- **Accettazione:** tutte le regole del §6.6 implementate; i comportamenti esistenti invariati; `python3 -I …/test-fake-supabase-e2e.py` verde;
  `./gradlew testDebugUnitTest` verde (non usa il server, ma conferma che nulla si è rotto).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md,
  `.cantiere/REGOLE-PROGETTO.md` e in `.cantiere/progetto-e2e-sync.md` i §6.2, §6.6 e §10.1 (regole R1–R10, vincolanti). Task S-50a: estendi
  `03_CODICE/bucktrail-android/scripts/fake-supabase.py` con tutte le regole del §6.6 (tabelle `mt_e2e` con PK `user_id` e `mt_vault`,
  filtri `kind`/`user_id`, 409 su doppio insert, PATCH, emulazione del trigger `bt_e2e_active`/`bt_e2e_migrating` con HTTP 400 e codice P0001,
  `FAKE_NO_E2E`, `FAKE_FAIL_AFTER`, payload mai trasformato) senza cambiare i comportamenti esistenti. Scrivi
  `scripts/test-fake-supabase-e2e.py` (solo libreria standard, porta libera, avvia e spegne il server, una prova per regola). Verifica:
  `python3 -I 03_CODICE/bucktrail-android/scripts/test-fake-supabase-e2e.py` e `cd 03_CODICE/bucktrail-android && ./gradlew testDebugUnitTest`.
  Chiudi il turno secondo R1–R2.»

#### S-50b · Nucleo crittografico iOS + vettori (≈ 2 h)
- **File:** `MoneyTracker/Sync/E2E/E2EFeature.swift`, `VaultCrypto.swift`, `RecoveryKey.swift`, `VaultJSON.swift`;
  `MoneyTrackerTests/E2ECryptoTests.swift`; `MoneyTrackerTests/Fixtures/e2e-vectors-v1.json`; `03_CODICE/bucktrail-android/scripts/e2e-vectors.py`.
- **Accettazione:** API pure (niente rete, niente Keychain): `VaultCrypto.seal(_:key:aad:)`, `open(_:key:aad:)`, `deriveKEK(passphrase:salt:iterations:)`
  (CommonCrypto, fuori dal main thread nel chiamante), `recoveryKEK(_:)` (HKDF CryptoKit), `wrap/unwrap`, `keyId(dek:)`, `RecoveryKey.generate/format/parse`,
  `VaultJSON.encoder/decoder` (§3.5); errori tipizzati (`malformed`, `unsupportedVersion`, `authenticationFailed`). Il file dei vettori contiene
  i gruppi 1–6 e 8 del §3.7 (il gruppo 7 arriva in S-50g); `e2e-vectors.py --check` conferma PBKDF2/HKDF/Base32/Base64 con la libreria standard;
  il test iOS verifica tutto, compreso il KAT NIST di AES-GCM. T1, T3, T4 verdi su iOS. Suite completa iOS verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md,
  `.cantiere/REGOLE-PROGETTO.md`, poi in `.cantiere/progetto-e2e-sync.md` i §3 (tutto), §8.1, §8.3, §9 (T1, T3, T4) e §10.1 (R1–R10 vincolanti).
  Task S-50b: crea in `MoneyTracker/Sync/E2E/` i file `E2EFeature.swift` (interruttore spento + override DEBUG `-E2EEnabled`), `VaultCrypto.swift`,
  `RecoveryKey.swift`, `VaultJSON.swift` esattamente come specificato (AES-256-GCM CryptoKit, PBKDF2-HMAC-SHA256 CommonCrypto 600 000, HKDF-SHA256
  CryptoKit, involucro `bt1.`+base64url, AAD del §3.4, Crockford Base32, key_id). Nessuna dipendenza nuova. Il nonce iniettabile è solo un
  parametro `internal` per i test. Scrivi `03_CODICE/bucktrail-android/scripts/e2e-vectors.py` (solo libreria standard: genera/controlla PBKDF2,
  HKDF, Base32, Base64) e `MoneyTrackerTests/Fixtures/e2e-vectors-v1.json` con i gruppi 1–6 e 8 del §3.7 (per gli involucri AES-GCM a nonce fisso
  ricava i valori attesi dal test iOS e verificali col KAT NIST del gruppo 1). Scrivi `MoneyTrackerTests/E2ECryptoTests.swift` (Swift Testing,
  come gli altri test) per T1, T3, T4. Verifica: test mirato e poi suite completa con i comandi del §9; `python3 -I …/e2e-vectors.py --check …`.
  Chiudi il turno secondo R1–R2.»

#### S-50c · Nucleo crittografico Android + vettori (≈ 1,5 h)
- **File:** `app/src/main/java/com/bucktrail/android/sync/e2e/VaultCrypto.kt`, `RecoveryKey.kt`; `app/build.gradle.kts` (solo `E2E_ENABLED` e
  `systemProperty("e2eVectors", …)` in `testOptions.unitTests.all`); test `app/src/test/.../sync/e2e/VaultCryptoVectorsTest.kt`;
  `app/src/androidTest/.../E2EVectorsInstrumentedTest.kt`.
- **Accettazione:** stesse API e stessi errori di S-50b; HKDF scritto con `Mac("HmacSHA256")` e verificato col caso RFC 5869; legge lo **stesso**
  file dei vettori; T1, T3, T4 verdi in JVM; test strumentato verde su emulatore (se l'emulatore non è disponibile: segnalarlo in CONSEGNA e lasciare
  la voce aperta per S-50l). `./gradlew assembleDebug lintDebug testDebugUnitTest` verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §3, §8.1, §8.3, §9 (T1, T3, T4) e §10.1 (R1–R10). Guarda come S-50b ha fatto la versione iOS
  (`MoneyTracker/Sync/E2E/VaultCrypto.swift`, `RecoveryKey.swift`) e replicala in Kotlin in `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/sync/e2e/`
  (javax.crypto AES/GCM/NoPadding, `SecretKeyFactory("PBKDF2WithHmacSHA256")` con la frase normalizzata NFC, HKDF manuale con HmacSHA256,
  `java.util.Base64` url senza padding, Crockford). Nessuna dipendenza nuova. In `app/build.gradle.kts` aggiungi solo `buildConfigField("boolean","E2E_ENABLED", …)`
  (false; in debug true solo con `-Pe2e=true`) e la `systemProperty("e2eVectors", rootProject.file("../../MoneyTrackerTests/Fixtures/e2e-vectors-v1.json").absolutePath)`
  per i test JVM. Scrivi `VaultCryptoVectorsTest.kt` (JVM) e `E2EVectorsInstrumentedTest.kt` (androidTest: legge il JSON copiato come asset di test o incorporato
  in una costante generata, a tua scelta motivata in CONSEGNA). Se `SecretKeyFactory` su Android dà un risultato diverso dal vettore Unicode, sostituiscilo
  con PBKDF2 scritto a mano su `Mac("HmacSHA256")` e scrivilo in CONSEGNA. Verifica: `./gradlew testDebugUnitTest --tests 'com.bucktrail.android.sync.e2e.*'`,
  `./gradlew assembleDebug lintDebug testDebugUnitTest`, `./gradlew connectedDebugAndroidTest` se c'è un emulatore. Chiudi il turno secondo R1–R2.»

#### S-50d · iOS: trasporto `SyncRemote` senza cambiare comportamento (≈ 2 h) → poi COLLAUDO BLOCCO 1
- **File:** `MoneyTracker/Sync/SyncService.swift`, nuovo `MoneyTracker/Sync/E2E/SyncRemote.swift`; test `MoneyTrackerTests/SyncRemoteGoldenTests.swift`,
  `MoneyTrackerTests/Support/InMemoryRemote.swift`, `MoneyTrackerTests/SyncServiceFlagOffTests.swift`.
- **Accettazione:** protocollo `SyncRemote` (`fetchIds`, `select`, `upsert`, `delete` per `SyncTable`); `PlainRemote` fa **le stesse chiamate SDK** di
  oggi (stesso ordine in `push`/`pull`/`syncOnLogin`/`deleteOrphans`); `SB*` interne + `SyncRow`; inizializzatore di test che inietta remoto e userId
  e non avvia `NWPathMonitor` né dipende da `usingVolatileStore`. T5 (URLProtocol finto su `SupabaseClient(options: .init(global: .init(session:)))`) e T6 verdi.
  Nessun `E2EGate` ancora. Suite iOS completa verde (99 unit + 49 UI più i nuovi).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §2, §8.2 (riga SyncService), §9 (T5, T6) e §10.1 (R1–R10). Matteo ha autorizzato la modifica di `MoneyTracker/Sync/`
  solo per S-50. Task S-50d, **solo refactor a comportamento identico**: in `MoneyTracker/Sync/E2E/SyncRemote.swift` crea `enum SyncTable` (5 tabelle e il loro `kind`),
  il protocollo `SyncRemote` e `PlainRemote(client:)`; in `SyncService.swift` sposta le chiamate `client.from(...)` dietro `remote` senza cambiare ordine,
  filtri, corpi, guardie, commenti utili; rendi interne le `SB*` e falle conformi a `SyncRow { var id: UUID { get } }`; aggiungi un inizializzatore di test
  (remoto, userId, nessun monitor di rete). Scrivi `SyncRemoteGoldenTests` (URLProtocol finto: metodo, percorso, query e JSON del corpo uguali a quelli
  attuali; ricava gli attesi leggendo il codice PRIMA della modifica e annotali nel test), `Support/InMemoryRemote.swift` (tabelle in chiaro in memoria, per i test futuri)
  e `SyncServiceFlagOffTests` (push/pull/syncOnLogin con InMemoryRemote: nessuna richiesta a `mt_e2e`/`mt_vault`). Verifica con la suite completa del §9.
  Chiudi il turno secondo R1–R2 e indica in CONSEGNA «serve collaudo di blocco 1 (S-50a…d)».»
- **Collaudo blocco 1** (subagente `collaudatore`): «Collauda S-50a…S-50d leggendo solo `git diff <commit prima di S-50a>..HEAD` e `.cantiere/progetto-e2e-sync.md`
  §3, §6.6, §8, §9. Controlla: nessun file vietato toccato (R3), test esistenti non modificati, interruttore spento, `PlainRemote` fa le stesse richieste
  di prima (confronta col diff), vettori identici usati da iOS e Android, nessun nonce fisso in produzione. Riesegui i comandi del §9 (iOS completo, Android completo,
  test python). Esito in PIANO (`[x]` con data o riapertura con difetti precisi).»

#### S-50e · iOS: vault, Keychain, server `mt_e2e`, gate (≈ 2 h)
- **File:** `MoneyTracker/Sync/E2E/VaultRemote.swift`, `E2EKeyStore.swift`, `E2EServer.swift`, `E2EGate.swift`; `SyncService.swift` (uso del gate
  solo `if E2EFeature.isEnabled`, ramo `.locked` in `pushResilient` senza backoff, DEK cancellata in `clearLocalData`, ricalcolo su `bt_e2e_active`);
  `InMemoryRemote.swift` esteso (vault, `mt_e2e`, emulazione trigger); test `E2EVaultRemoteTests.swift`, `E2EGateTests.swift`.
- **Accettazione:** `VaultRemote` cifra/decifra come §3.4–3.5, upsert a blocchi di 200, verifica `id` interno; tabella di decisione del §7.2
  implementata e testata riga per riga; T12 (parte iOS) e T14 verdi; T5/T6 ancora verdi; suite completa verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §3.4–3.6, §4, §7.2, §8, §9 (T12, T14) e §10.1 (R1–R10). Task S-50e: implementa in `MoneyTracker/Sync/E2E/`
  `VaultRemote` (conforme a `SyncRemote`, tabella `mt_vault`, `kind` dal `SyncTable`, payload con `VaultJSON` e `VaultCrypto`, blocchi da 200, rifiuto se l'id
  interno non coincide), `E2EKeyStore` (Keychain come §4.1, per utente), `E2EServer` (lettura/insert/patch/delete della riga `mt_e2e`, riconoscimento di
  404/PGRST205/42P01 e di `bt_e2e_active`), `E2EGate` (tabella del §7.2). In `SyncService.swift` collega il gate **solo** dentro `if E2EFeature.isEnabled`;
  con l'interruttore spento il codice percorso deve restare quello di S-50d. Estendi `InMemoryRemote` con vault, `mt_e2e` e trigger emulato. Test: ogni riga
  della tabella §7.2, T12 (iOS), T14, cifratura effettiva nel vault (nessun testo in chiaro dei nomi nel payload). Verifica con la suite completa del §9.
  Chiudi il turno secondo R1–R2.»

#### S-50f · Android: `VaultApi`, decoratore, Keystore, gate (≈ 2 h)
- **File:** `sync/SupabaseApi.kt` (`HttpSupabaseApi` implementa anche `VaultApi`; helper privato di paginazione con filtro), `sync/e2e/VaultApi.kt`,
  `VaultSupabaseApi.kt`, `E2EKeyStore.kt`, `E2EGate.kt`, `E2EController.kt` (solo lo scheletro di stato), `sync/SyncService.kt` (`e2e: E2EController? = null`),
  `sync/SyncEngine.kt` (`onClear`), test `sync/e2e/FakeVaultSupabase.kt`, `VaultSupabaseApiTest.kt`, `E2EGateTest.kt`, `E2EFlagOffTest.kt`, `HttpSupabaseApiGoldenTest.kt`.
- **Accettazione:** `SyncEngine` **non cambia logica**: riceve il decoratore come `SupabaseApi`; riga illeggibile → oggetto con solo `id` (il motore la
  ignora e non cancella la copia locale, come oggi); tabella §7.2 testata; T5 (Android), T6, T12, T14 verdi; `./gradlew assembleDebug lintDebug testDebugUnitTest` verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §3.4–3.6, §4, §7.2, §8, §9 (T5, T6, T12, T14) e §10.1 (R1–R10). Guarda la versione iOS di S-50e per coerenza.
  Task S-50f in `03_CODICE/bucktrail-android`: crea l'interfaccia `VaultApi` (select/upsert/delete su `mt_vault` per `kind`, get/insert/patch/delete di `mt_e2e`)
  e falla implementare a `HttpSupabaseApi` riusando la paginazione di `selectAll` tramite un helper privato (l'URL di `selectAll` deve restare identico:
  scrivi prima `HttpSupabaseApiGoldenTest`). Crea `VaultSupabaseApi(plain, vault, dek, userId) : SupabaseApi` che instrada `mt_*` sul vault cifrando le
  `JsonObject` di `SyncMapper` (§3.5) e delega auth e rpc. Crea `E2EKeyStore` (Keystore come §4.1, schema di `KeystoreSessionStore`), `E2EGate` (§7.2),
  lo scheletro di `E2EController`; aggiungi a `SyncService` il parametro finale `e2e: E2EController? = null` e a `SyncEngine` `onClear: () -> Unit = {}`.
  **Non modificare** `SyncFakes.kt` né altri test esistenti: crea `FakeVaultSupabase` nuovo con trigger emulato. Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest`.
  Chiudi il turno secondo R1–R2.»

#### S-50g · Interoperabilità delle righe iOS↔Android (≈ 1 h)
- **File:** vettori gruppo 7 in `MoneyTrackerTests/Fixtures/e2e-vectors-v1.json`; `MoneyTrackerTests/E2ERowInteropTests.swift`; `app/src/test/.../sync/e2e/RowInteropTest.kt`.
- **Accettazione:** per ogni `kind` una riga iOS e una Android (con casi limite: `nil`/null, importo negativo, importo con 2 decimali, emoji e kanji
  nei testi, `exceptions` non vuote, `account_id` null) sigillate a nonce fisso; ciascuna piattaforma apre e decodifica **entrambe** con i decoder di
  sync esistenti e ottiene i valori attesi neutri. T2 verde da entrambe le parti. Se un formato non è letto dall'altra piattaforma, la correzione va
  **solo** in `VaultJSON` (iOS) o nel decoratore (Android), mai nei decoder di sync.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §3.5, §3.7 (gruppo 7), §9 (T2) e §10.1 (R1–R10). Task S-50g: aggiungi il gruppo `rows` al file dei vettori
  (una riga prodotta dal DTO iOS e una da `SyncMapper` Android per ogni kind, con i casi limite elencati nel §10.3 S-50g, sigillate con DEK e nonce fissi;
  produci ciascuna riga con il codice della sua piattaforma, in un test che la stampa, e incollala nel JSON), poi scrivi `E2ERowInteropTests.swift` e
  `RowInteropTest.kt` che aprono e decodificano entrambe le righe con i decoder di sync esistenti e confrontano i valori attesi neutri. Correzioni di formato
  solo in `VaultJSON` o nel decoratore. Verifica iOS completo e Android completo (§9). Chiudi il turno secondo R1–R2.»

#### S-50h · iOS: migratore e verifica (≈ 2 h)
- **File:** `MoneyTracker/Sync/E2E/E2EVerifier.swift`, `E2EMigrator.swift`; `SyncService.swift` (solo: flag `isMigrating` che sospende push/pull,
  funzione «marca tutti i movimenti sporchi», push con remoto passato come parametro); test `E2EMigratorTests.swift`.
- **Accettazione:** passi A0–A8, D0–D7, rollback §7.7, ricomincia §7.8, backup §7.3 A1, verifica §7.5 con ricevuta; T7, T8 (interruzione iniettata
  a ogni passo + doppia ripresa), T9, T10 (iOS), T11 (due istanze su remoto condiviso), T13 verdi. Suite completa verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §4.2, §7 (tutto), §9 (T7–T11, T13) e §10.1 (R1–R10). Task S-50h: implementa `E2EVerifier` (§7.5: contatori,
  id, confronto campo per campo normalizzato, ricevuta SHA-256 per kind) e `E2EMigrator` (attivazione A0–A8, disattivazione D0–D7, ripresa dal marcatore
  locale + stato server, rollback §7.7, ricomincia §7.8, backup locale A1/D2) riusando `SyncService.push`/`pull` col remoto giusto: non scrivere un secondo
  algoritmo di sync. In `SyncService.swift` aggiungi solo il minimo (flag `isMigrating`, «marca tutti sporchi», remoto come parametro). Ogni passo deve
  avere un punto di iniezione d'errore per i test (protocollo o closure `internal`, mai attivo in produzione). Test T7, T8, T9, T10, T11, T13 con
  `InMemoryRemote`. Verifica con la suite completa del §9. Chiudi il turno secondo R1–R2.»

#### S-50i · Android: migratore e verifica (≈ 2 h) → poi COLLAUDO BLOCCO 2
- **File:** `sync/e2e/E2EVerifier.kt`, `E2EMigrator.kt`, `E2EController.kt` (completo); `sync/SyncService.kt` (solo cablaggio dentro `e2e != null`);
  test `E2EMigratorTest.kt`, `OldClientTest.kt`, `TwoDevicesTest.kt`.
- **Accettazione:** stessi passi e stessi test di S-50h su Android, tutto dentro la coda `ops`; il motore usato per la migrazione è un `SyncEngine`
  costruito col decoratore vault (nessun algoritmo di sync nuovo); T7–T11, T13 verdi; `./gradlew assembleDebug lintDebug testDebugUnitTest` verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §4.2, §7, §9 (T7–T11, T13) e §10.1 (R1–R10). Replica in Kotlin il migratore iOS di S-50h
  (`MoneyTracker/Sync/E2E/E2EMigrator.swift`, `E2EVerifier.swift`) in `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/sync/e2e/`,
  completa `E2EController` (stati per la UI: unavailable, off, activating(n,N), on, locked(reason), disabling(n,N), error) e collegalo a `SyncService` solo quando
  `e2e != null`, sempre dentro `ops.withLock`. Per l'upload usa un `SyncEngine` costruito con `VaultSupabaseApi` (stessa logica di push, compresa la guardia
  delle cancellazioni con `allowDestructive` solo dove serve e motivato). Test T7–T11, T13 con `FakeVaultSupabase`; T10 usa un `SyncEngine` normale come
  «client vecchio». Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest`. Chiudi il turno secondo R1–R2 e indica «serve collaudo di blocco 2 (S-50e…i)».»
- **Collaudo blocco 2** (subagente `collaudatore`, con skill `stress-test`): «Collauda S-50e…S-50i leggendo solo il diff del blocco e `.cantiere/progetto-e2e-sync.md`
  §4, §7, §8, §9. Cerca in particolare: un qualunque percorso in cui una riga in chiaro sul server venga cancellata prima della verifica superata; scritture con
  `.locked`; DEK scritta fuori da Keychain/Keystore o nei log; differenze di comportamento a interruttore spento; test esistenti modificati. Riesegui i comandi del §9.
  Esito in PIANO.»

#### S-50j · iOS: interfaccia e testi (≈ 2 h)
- **File:** `MoneyTracker/Views/E2E/*` (4 file), `MoneyTracker/Sync/E2E/E2EController.swift`, `MoneyTracker/Views/SettingsView.swift` (una riga),
  `MoneyTracker/ContentView.swift` (prompt di sblocco), `MoneyTracker/*.lproj/Localizable.strings` (7), test `E2ELocalizationTests.swift`,
  `MoneyTrackerUITests/E2EUITests.swift`.
- **Accettazione:** schermate del §5.2 coi token Sentiero, chiaro e scuro; testi del §5.3 in 7 lingue; harness DEBUG `-E2EUITestHarness`; T15 e T16 verdi;
  screenshot di ogni schermata (it ed en, chiaro e scuro) salvati in `/tmp/e2e-ios/` e citati in CONSEGNA per S-50o; con interruttore spento la sezione
  Sicurezza è identica (UI test esistenti verdi).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §5 (tutto), §8.1, §9 (T15, T16) e §10.1 (R1–R10); per lo stile guarda la sezione «Sicurezza» di
  `MoneyTracker/Views/SettingsView.swift` e `MoneyTracker/Views/Theme.swift` (token `DS`, `.scaledFont`, `SectionLabel`, `ThinDivider`). Task S-50j: completa
  `E2EController` (stato osservabile per la UI, azioni che chiamano il migratore e lo sblocco) e crea in `MoneyTracker/Views/E2E/` le schermate 1–8 del §5.2.
  Aggiungi la riga in Impostazioni → Sicurezza e il prompt di sblocco in `ContentView`, entrambi solo con `E2EFeature.isEnabled`. Aggiungi le 49 chiavi
  `e2e_*` del §5.3 in tutti e 7 i `Localizable.strings` (anche `it`). Mai `preferredColorScheme`, solo token `DS`. Harness DEBUG `-E2EUITestHarness` che apre
  `AdvancedProtectionView` su un controller con remoto in memoria. Test: `E2ELocalizationTests` (T15) e `E2EUITests` (T16). Fai gli screenshot richiesti in `/tmp/e2e-ios/`.
  Verifica con la suite completa del §9. Chiudi il turno secondo R1–R2.»

#### S-50k · Android: interfaccia e testi (≈ 2 h)
- **File:** `ui/screens/AdvancedProtectionScreens.kt`, `ui/screens/SettingsSheets.kt` (una riga), `ui/BucktrailApp.kt` (prompt), `BucktrailApplication.kt`
  (cablaggio se `BuildConfig.E2E_ENABLED`), `res/values*/strings.xml` (7), test `E2EStringsTest.kt` (JVM: legge gli XML) e Compose test strumentato.
- **Accettazione:** come S-50j sul tema Android; screenshot in `/tmp/e2e-android/` con emulatore e server finto (`-Pe2e=true`); T15, T16 verdi;
  lint verde (nessuna stringa hardcoded).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §5, §8.1, §9 (T15, T16, T18) e §10.1 (R1–R10). Replica in Compose le schermate iOS di S-50j
  (`MoneyTracker/Views/E2E/`) in `03_CODICE/bucktrail-android/app/src/main/java/com/bucktrail/android/ui/screens/AdvancedProtectionScreens.kt`, con lo stile
  della sezione Sicurezza di `SettingsSheets.kt` e del tema in `ui/theme/`. Riga in Impostazioni e prompt di sblocco solo se `BuildConfig.E2E_ENABLED`; cablaggio
  in `BucktrailApplication.kt` solo in quel caso. Aggiungi le 49 stringhe `e2e_*` del §5.3 nei 7 `strings.xml` (apostrofi `\'`). Autenticazione con
  `security/Authenticator.kt`. Test `E2EStringsTest` (JVM) e un Compose test strumentato del flusso di attivazione. Prova d'insieme T18 su emulatore col
  server finto (comandi in §9) e screenshot in `/tmp/e2e-android/`. Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest` (+ `connectedDebugAndroidTest`
  se c'è un emulatore). Chiudi il turno secondo R1–R2.»

#### S-50l · Uscita, eliminazione account, cambio utente, stress (≈ 1,5 h) → poi COLLAUDO BLOCCO 3
- **File:** `MoneyTracker/Auth/SupabaseManager.swift` (`deleteAccount`: pulizia al meglio dopo la RPC, solo con interruttore), cablaggi già presenti
  (verifica), test `E2ELifecycleTests.swift` / `E2ELifecycleTest.kt`; se mancano, voce strumentata di S-50c.
- **Accettazione:** logout e cambio utente cancellano la DEK e il backup; eliminazione account: RPC prima, poi vault/`mt_e2e` al meglio, poi DEK;
  se la RPC fallisce nulla cambia; skill `stress-test` eseguita (dati grandi: 20 000 movimenti nel remoto in memoria con tempi registrati; nomi lunghi;
  `exceptions` vicina a 64 KiB; rete che cade a ogni passo; due dispositivi che attivano insieme → uno riceve K46); risultati in CONSEGNA.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §4.2, §8.2, §9 e §10.1 (R1–R10). Task S-50l: completa e prova i casi di vita delle chiavi su iOS e Android
  (logout, cambio utente, eliminazione account con RPC prima e pulizia al meglio dopo, solo a interruttore acceso; se la RPC fallisce non si tocca nulla).
  Scrivi `E2ELifecycleTests.swift` e `E2ELifecycleTest.kt`. Poi esegui la skill `stress-test` (`.agents/skills/stress-test/SKILL.md`) sui casi elencati nel
  §10.3 S-50l e registra numeri e tempi in CONSEGNA. Se il test strumentato dei vettori di S-50c era rimasto aperto, eseguilo ora. Verifica: suite complete
  iOS e Android del §9. Chiudi il turno secondo R1–R2 e indica «serve collaudo di blocco 3 (S-50j…l)».»
- **Collaudo blocco 3** (subagente `collaudatore`): «Collauda S-50j…S-50l leggendo solo il diff del blocco, `.cantiere/progetto-e2e-sync.md` §4, §5, §8, e
  gli screenshot in `/tmp/e2e-ios/` e `/tmp/e2e-android/`. Controlla: testi uguali al §5.3 nelle 7 lingue, niente stringhe hardcoded, token del tema, bordi e
  badge ingranditi a posto, nessun `preferredColorScheme`, interruttore spento, Impostazioni identiche a interruttore spento. Esito in PIANO.»

#### S-50m · Commissione Suprema e manuale (≈ 1,5 h)
- **File:** correzioni richieste dai giudici (solo nei file S-50), `docs/MoneyTracker.md` (sezione «Protezione avanzata (dietro interruttore, spenta)»
  + Changelog), `docs/MoneyTracker.pdf` rigenerato.
- **Accettazione:** 6 giudici di REGOLE-PROGETTO (sicurezza, architettura, logica, performance, robustezza, i18n) a 10/10 sull'intero diff S-50; per la
  sicurezza il giudice usa anche OWASP MASVS-CRYPTO e MASVS-STORAGE come lista di controllo; suite complete verdi; PDF rigenerato col comando di REGOLE-PROGETTO.
  **Niente push** (il checkpoint con push lo decide il capocantiere con Matteo).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`
  (sezione Commissione Suprema), poi `.cantiere/progetto-e2e-sync.md` §1, §3, §7, §8, §11 e §10.1 (R1–R10). Task S-50m: convoca la Commissione Suprema
  sul diff completo di S-50 (dal commit precedente a S-50a fino a HEAD): 6 giudici, voto 1–10, diagnosi file+riga e correzione per ogni voto sotto 10;
  il giudice della sicurezza usa anche OWASP MASVS-CRYPTO/STORAGE. Correggi e ripeti finché tutti danno 10/10, toccando solo file di S-50. Poi aggiorna
  `docs/MoneyTracker.md` (nuova sezione «Protezione avanzata» che descrive ciò che è stato costruito, dichiarando che è dietro interruttore spento, + riga di
  Changelog) e rigenera il PDF col comando di REGOLE-PROGETTO. Verifica: suite complete del §9. Nessun push. Chiudi il turno secondo R1–R2.»

#### S-50n · [?] Matteo · applicare lo SQL (2 minuti)
Istruzioni complete nel §6.3. Dopo la risposta di Matteo («13 righe»), il capocantiere segna `[x]`.

#### S-50o · [?] Matteo · approvare le schermate + prova reale facoltativa con account di prova
1. Il capocantiere mostra a Matteo gli screenshot di `/tmp/e2e-ios/` e `/tmp/e2e-android/` (D-014). Matteo approva o chiede cambi (→ task correttivi).
2. **Facoltativa, solo con Matteo presente e con un account di prova** (mai il suo account reale): build DEBUG con interruttore acceso
   (iOS `-E2EEnabled YES` da Xcode, Android `./gradlew installDebug -Pe2e=true -PsupabaseUrl=<url vero> -PsupabaseKey=<anon>`), poi:
   accesso con l'account di prova su iPhone e Android → crea 3 movimenti → attiva su iPhone → su Supabase (Table Editor) `mt_vault` mostra solo `bt1.…`
   e le tabelle `mt_*` sono vuote per quell'utente → Android mostra la pausa → sblocco con la frase → stessi dati → disattiva da Android → iPhone torna normale →
   elimina l'account di prova. ↩️ Matteo riporta «ok» o lo screenshot dell'errore.

#### S-50p · Accensione, sito e privacy (≈ 1 h) — SOLO dopo S-50n e S-50o ✅
- **File:** `E2EFeature.swift` (`isEnabled = true`), `app/build.gradle.kts` (`E2E_ENABLED` true in release), `SOCIAL/landing/index.html` e `en.html`
  (FAQ `#sicurezza`), `SOCIAL/landing/privacy.html`, `docs/MoneyTracker.md` + PDF, `.cantiere/APPROVAZIONI.md` (testi del sito da approvare).
- **Testi del sito (sostituiscono il 3° paragrafo della FAQ «Come so che i miei dati sono al sicuro?»):**
  - it: «Con la Protezione avanzata, facoltativa (Impostazioni → Sicurezza), i dati vengono cifrati sul telefono con una chiave che hai solo tu, prima
    della sincronizzazione: sul cloud restano illeggibili, anche per noi. Il server vede solo informazioni tecniche, come il tuo account, quante voci hai e
    quando sincronizzi. Se perdi sia la frase di sicurezza sia la chiave di recupero, i dati sul cloud non si possono recuperare. Senza Protezione avanzata la
    sincronizzazione non usa la cifratura end-to-end. L'app non contiene pubblicità né tracker.»
  - en: «With Advanced Protection, which is optional (Settings → Security), your data is encrypted on your phone with a key only you hold, before it syncs:
    in the cloud it stays unreadable, even to us. The server only sees technical information, such as your account, how many items you have and when you
    sync. If you lose both your security phrase and your recovery key, your cloud data can't be recovered. Without Advanced Protection, sync does not use
    end-to-end encryption. The app contains no ads and no trackers.»
  - privacy.html: nella parte sulla sincronizzazione, un paragrafo it/en che dice: con la Protezione avanzata il server conserva i dati solo cifrati
    (AES-256-GCM) più le chiavi avvolte (non utilizzabili senza frase o chiave di recupero) e i parametri tecnici; restano visibili account, identificativi,
    numero e tipo dei record, date di sincronizzazione; nessuno, nemmeno il gestore, può decifrarli.
- **Accettazione:** testi in `APPROVAZIONI.md` con ✅ di Matteo prima della pubblicazione; suite complete verdi; nessun push del sito senza Matteo.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-e2e-sync.md` i §8.1, §10.3 S-50p e §10.1 (R1–R10, con l'eccezione che QUI R4 non vale). Controlla in PIANO che S-50n e S-50o siano
  `[x]`: se no, fermati. Task S-50p: accendi l'interruttore (iOS `E2EFeature.isEnabled = true`, Android `E2E_ENABLED = true` anche in release), aggiorna
  la FAQ `#sicurezza` di `SOCIAL/landing/index.html` e `en.html` e `SOCIAL/landing/privacy.html` con i testi del §10.3 S-50p (adattati alla struttura
  esistente, niente di più di ciò che è costruito), aggiorna `docs/MoneyTracker.md` (la funzione non è più dietro interruttore) e rigenera il PDF, scrivi i testi del
  sito in `.cantiere/APPROVAZIONI.md` in attesa di ✅. Verifica: suite complete del §9. Non pubblicare il sito, non fare push. Chiudi il turno secondo R1–R2.»

---

## 11. Rischi e decisioni

### 11.1 Rischi residui
| # | Rischio | Gravità | Mitigazione |
|---|---|---|---|
| R1 | Utente perde frase, chiave e tutti i dispositivi | alta per lui | avvisi K07/K17, conferma dell'ultimo gruppo, «ricomincia» |
| R2 | Frase debole → forza bruta offline su `mt_e2e` da chi ha il database | media | PBKDF2 600k, minimo 10 caratteri, consiglio «4 parole»; Argon2 non disponibile senza dipendenze |
| R3 | Client vecchi smettono di sincronizzare dopo l'attivazione | media (voluta) | K08 prima di attivare; nessuna perdita di dati: si fermano soltanto |
| R4 | Un client vecchio scrive in chiaro durante `disabling` o subito dopo con dati vecchi (e cancella orfani) | bassa | finestra di pochi secondi; è la stessa semantica di oggi per un dispositivo rimasto indietro; K08 |
| R5 | Il server rimette una versione precedente di una riga (rollback per riga) o cancella righe | bassa | dichiarato nel §1.3; si potrà aggiungere una versione nell'AAD in un `bt2` |
| R6 | Metadati (conteggi, dimensioni, orari) | bassa | dichiarati in app (K06) e sul sito |
| R7 | Provider PBKDF2 di Android diverso dal JVM | media | test strumentato coi vettori Unicode (S-50c); ripiego a PBKDF2 manuale |
| R8 | iOS: una riga del vault illeggibile blocca tutto il pull (come oggi una riga malformata) | bassa | comportamento identico a quello attuale; Android la ignora come oggi |
| R9 | `delete_own_account` non cancella `auth.users` (codice SQL non nel repository) | bassa | pulizia al meglio dal client col token ancora valido + `on delete cascade`; il trigger non blocca mai funzioni che girano con un ruolo diverso da `authenticated` (quindi neanche la RPC durante `migrating`) |
| R10 | Una richiesta GET in più a ogni sync per tutti gli utenti, a interruttore acceso | trascurabile | una riga, indicizzata; nessuna a interruttore spento |
| R11 | Interruttore spento dopo essere stato acceso in produzione | media | vietato (§8.1); si usa `allowNewActivations` |
| R12 | Nonce casuale GCM: limite teorico 2^32 cifrature per chiave | trascurabile | una persona fa migliaia di scritture, non miliardi |

### 11.2 Decisioni (riportate in `.cantiere/DECISIONI.md`)
Tabella vault separata (non colonne esistenti) · trigger di guardia lato server (non RLS restrittiva, non «solo client») · AES-256-GCM ·
PBKDF2-SHA256 600k · HKDF per il recupero · DEK casuale avvolta due volte · frase separata dalla password Supabase · chiave di recupero
Crockford 160 bit · payload = riga JSON esistente · migrazione con copia in chiaro congelata fino alla verifica · biometria solo per le azioni
sensibili · chiavi `e2e_*` uguali sulle due piattaforme · interruttore spento fino a S-50p · D-014 rispettata con approvazione prima dell'accensione.

### 11.3 Stima di tempo e quota
13 task di Claude Code (S-50a…m, p) da 1–2 ore ciascuno ≈ **18–22 ore di lavoro dell'agente**, più 3 collaudi di blocco (≈ 30 min ciascuno) e la
Commissione. Con sessioni corte (una per task, `/clear` tra l'una e l'altra) sono **circa 15–17 sessioni**, ragionevolmente **5–7 giorni** di quota Claude.
I task più pesanti di contesto: S-50d, S-50h, S-50j (SyncService e SettingsView sono file lunghi: leggere solo le parti necessarie).
Matteo: ~2 minuti (SQL) + ~15 minuti (schermate) + ~20 minuti facoltativi (prova reale).

### 11.4 Cosa NON fare
- Non derivare chiavi dalla password Supabase; non salvare mai frase, DEK o chiave di recupero sul server o nei log (nemmeno in DEBUG).
- Non mettere il cifrato nelle colonne di `mt_*`; non modificare colonne o policy esistenti; non toccare `delete_own_account`.
- Non cancellare righe in chiaro prima che la verifica §7.5 sia superata e lo stato sia `active`.
- Non aggiungere librerie (libsodium, SQLCipher, Tink, Argon2…).
- Non riscrivere la logica di merge: il vault è solo un trasporto.
- Non modificare i test esistenti né i fake esistenti (`SyncFakes.kt`): solo file di test nuovi.
- Non accendere l'interruttore prima di S-50p; non spegnerlo dopo una pubblicazione con utenti protetti.
- Non usare il Supabase vero né la chiave `service_role` in nessun task autonomo; non fare push del codice o del sito senza Matteo.
- Non promettere sul sito più di ciò che è costruito e acceso.
