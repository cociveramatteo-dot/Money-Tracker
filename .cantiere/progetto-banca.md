# PROGETTO ESECUTIVO S-60 · Collegamento bancario facoltativo (lettura saldi e movimenti, PSD2 AIS)

> Autore: architetto (Claude Code · Opus), 2026-11-24. Stato: progetto da eseguire in autonomia da Claude Code (Sonnet) secondo il §11.
> Nessun codice di produzione è stato scritto con questo documento.
> Vincoli supremi di Matteo: **«mantenere tutto intatto, non rompere nulla»**. Chi non collega nessuna banca non vede cambiamenti di
> comportamento, dati o calcoli (l'unica aggiunta visibile, a interruttore acceso, è una riga «Conti collegati» nelle Impostazioni).
> Niente abbonamenti per l'utente se evitabili. Redesign «Sentiero», 7 lingue, mai `preferredColorScheme`, mai colori non adattivi.
> **Autorizzazione di Matteo** (riferita dal capocantiere il 2026-11-24, solo per S-60 e dentro questo progetto): si possono modificare
> `MoneyTracker/Sync/`, `MoneyTracker/Auth/` e i punti minimi di `Models/` e `Persistence/` indicati al §4.6. Restano intoccabili: i calcoli
> esistenti, `Domain/` (si AGGIUNGONO solo file puri nuovi in `Domain/Bank/`, §4.7), i test esistenti (si possono solo aggiungere test).
> **Prerequisito:** S-50a…S-50m chiusi `[x]` (questo progetto usa `SyncRemote`/`VaultRemote` iOS e `VaultApi` Android introdotti da S-50).

## Indice
1. [Sintesi e perimetro](#1-sintesi-e-perimetro)
2. [Scelta del fornitore](#2-scelta-del-fornitore)
3. [Architettura tecnica (backend, flusso, segreti, link di ritorno)](#3-architettura-tecnica)
4. [Modello dati, riconciliazione, migrazioni, SQL](#4-modello-dati)
5. [Categorizzazione e nomi puliti](#5-categorizzazione)
6. [Coerenza con S-50 (Protezione avanzata)](#6-coerenza-con-s-50)
7. [Interfaccia, stati e testi nelle 7 lingue](#7-interfaccia)
8. [Sicurezza e privacy](#8-sicurezza-e-privacy)
9. [Aspetti legali e commerciali](#9-legale-e-commerciale)
10. [Piano di prova](#10-piano-di-prova)
11. [Piano di lavoro esecutivo S-60a…S-60v con prompt](#11-piano-di-lavoro)
12. [Rischi, costi, decisioni, stima, cosa NON fare](#12-rischi-costi-decisioni)

---

## 1. Sintesi e perimetro

### 1.1 In 12 righe
- **Fornitore:** **Enable Banking** (Enable Banking Oy, AISP registrato presso la FIN-FSA finlandese, opera in Italia in libera prestazione).
  Piano B: **Salt Edge** (Partner Program per chi non ha licenza). GoCardless Bank Account Data è escluso: iscrizioni chiuse (verificato il 2026-11-24).
- **Solo lettura (AIS):** saldi e movimenti dei conti che l'utente sceglie. Nessun pagamento (PIS), nessuna disposizione, nessun dato di login della banca.
- **Backend minimo:** una sola **Supabase Edge Function `bank`** (Deno/TypeScript, già nello stack) fa da proxy: custodisce la chiave privata del
  fornitore, firma le richieste, normalizza le risposte e **non salva mai dati bancari**. Nessun server nuovo da mantenere.
- **I movimenti importati diventano normali `Transaction`** con ID deterministico (UUID v5): calcoli, Home, statistiche, sync e Protezione
  avanzata funzionano senza modifiche. I metadati del collegamento stanno in 3 entità nuove sincronizzate + 1 locale.
- **Doppioni:** se un movimento bancario somiglia a uno inserito a mano (stesso conto, stesso segno, stesso importo, data vicina) **non si importa**:
  va in «Da confermare» e decide l'utente. Mai fusioni automatiche.
- **Protezione avanzata (S-50):** il server non conserva nulla di bancario in chiaro; le entità bancarie viaggiano cifrate nel vault come le altre;
  i movimenti transitano dalla funzione solo in memoria. Le due funzioni convivono senza rinunce (§6).
- **Interruttori:** `BankFeature.isEnabled = false` (iOS) / `BuildConfig.BANK_ENABLED = false` (Android) fino a S-60v; in più un interruttore
  **lato server** (`bank_config.connect_enabled`) che può solo SPEGNERE i nuovi collegamenti senza nuova versione dell'app.
- **Passi di Matteo:** 3 in tutto (§11.4): S-60t commerciale/legale (subito, in parallelo), S-60r banco di prova tecnico (40 min), S-60u produzione.

### 1.2 Cosa fa
1. Impostazioni → **Conti collegati** → «Collega una banca» → scelta della banca → spiegazione di cosa si legge e per quanto → sito/app della banca
   (autenticazione forte SCA fatta dall'utente con la sua banca) → ritorno automatico in Bucktrail.
2. L'utente sceglie quali conti importare e dove: in un **nuovo conto** Bucktrail o in un **conto esistente**; e da quando: «Da oggi» o «Ultimi 90 giorni».
3. Bucktrail scarica i movimenti **contabilizzati** e li inserisce come movimenti normali, con nome pulito e categoria suggerita; i possibili doppioni
   e i possibili giroconti vanno in «Da confermare»; i movimenti **in attesa** (non contabilizzati) si mostrano soltanto, senza toccare i saldi.
4. Aggiornamento all'apertura dell'app (al massimo ogni 6 ore per collegamento) e con «Aggiorna ora».
5. Mostra «Saldo in banca» accanto a «Saldo in Bucktrail» per i conti collegati; se differiscono, l'utente può **allineare** con una «Rettifica saldo»
   (meccanismo già esistente), solo con il suo tocco.
6. Rinnovo del consenso (di norma ogni 180 giorni, avviso 7 giorni prima), scollegamento in qualsiasi momento.

### 1.3 Cosa NON fa (v1)
- Pagamenti, bonifici, PIS, verifica identità, lettura del nome del titolare, conti aziendali (`psu_type = personal` soltanto).
- Conversioni di valuta: si collegano solo conti nella **valuta scelta nell'app**; gli altri appaiono come «Valuta diversa: per ora non si può importare».
- Aggiornamento in background (BGTask/WorkManager): no. Solo all'apertura e a mano (meno consumo, meno limiti della banca, meno codice).
- Modifica automatica di movimenti già importati o inseriti a mano; cancellazione automatica di movimenti; modifica dei saldi iniziali di conti esistenti.
- Modalità demo: invisibile. Android senza account: la riga c'è ma chiede l'accesso (il backend richiede un utente autenticato).
- Webhook del fornitore: non usati (Enable Banking AIS non li richiede; meno superficie d'attacco).

---

## 2. Scelta del fornitore

### 2.1 Confronto (verificato sul web il 2026-11-24; dove la fonte è di terzi è scritto)
| Fornitore | Licenza / chi può usarlo senza licenza AISP | Italia (banche richieste) | Prezzo e piano gratuito | Consenso e storico | Note |
|---|---|---|---|---|---|
| **Enable Banking** | AISP registrato FIN-FSA (ID 2988499-7), in LPS anche fuori dalla Finlandia; i clienti senza licenza usano la licenza di Enable Banking ([Termini](https://enablebanking.com/terms), [FAQ](https://enablebanking.com/docs/faq)) | Pagina Italia ufficiale: Intesa Sanpaolo, UniCredit, Poste (BancoPosta/Postepay via CBI Globe), BPER, MPS, ING, BNL, Mediolanum, Widiba, Banco BPM; Fineco, N26, Revolut, Hype **non citati nella pagina** → [DA VERIFICARE in sandbox con `GET /aspsps?country=IT`] ([fonte](https://enablebanking.com/docs/markets/it/)) | Listino non pubblico: «volume based», **fattura minima mensile**, preventivo da aprile 2026 ([FAQ](https://enablebanking.com/docs/faq), [changelog 03/2026](https://enablebanking.com/blog/2026/04/08/enable-banking-changelogmarch-2026)). **Gratis:** sandbox e **modalità ristretta** in produzione per i propri conti ([doc](https://enablebanking.com/docs/api/linked-accounts/)) | `valid_until` scelto dal cliente, massimo per banca «per la maggior parte 180 giorni»; banche CBI Globe chiedono una SCA in più oltre 90 giorni (Enable la gestisce con due consensi); limite tipico **4 letture/giorno senza utente presente** | API REST semplice (JWT RS256 firmato con la nostra chiave, 24 h max), nessun SDK; dichiara di non conservare i dati |
| **Salt Edge** | AISP; **Partner Program** «senza licenza PSD2 propria» ([fonte](https://saltedge.com/products/spectre)) | Fineco, MPS, Intesa, Credem citati (2021) ([blog](https://blog.saltedge.com/supernovaelabs-partnership-italian-financial-landscape-open-banking/)); UniCredit Italia non confermato | Prezzi su preventivo; un risultato di ricerca sul loro sito cita un piano «Basic, Free, 100 live connections» ma la pagina letta non lo mostra → [DA VERIFICARE] | n.d. | Categorie e riconoscimento esercente inclusi |
| **Tink (Visa)** | Piano Standard «Tink's license» ([pricing](https://tink.com/pricing)) | n.d. nelle fonti lette | Prezzi nascosti; fonti di terzi: ~0,50 €/utente/mese (transazioni) ([finexer](https://blog.finexer.com/tink-pricing/)) | n.d. | Spesso rimanda ai partner per i piccoli |
| **Yapily** | Yapily Connect fornisce la licenza AISP ([doc](https://docs.yapily.com/tools-and-services/yapily-connect/overview)) | UniCredit, Intesa, BancoPosta, Banco BPM, BNL (dichiarazione 2021) ([blog](https://www.yapily.com/blog/the-yapily-platform-is-live-in-italy)) | Su preventivo; terzi: 200–500 £/mese di ingresso ([dev.to, 08/2026](https://dev.to/johnfrandsen/the-cheapest-open-banking-apis-for-small-businesses-and-indie-builders-in-2026-5cab)) | n.d. | Troppo caro per un'app da 4,99 € |
| **TrueLayer** | Regolamentata (dettagli non verificati) | Lancio Italia 2020: UniCredit, Intesa, Poste ([blog](https://truelayer.com/blog/italy-launch)) | Pagina prezzi 404 ad agosto 2026; terzi: 150–300 £/mese storici | n.d. | Centrata sul Regno Unito |
| **GoCardless Bank Account Data** (ex Nordigen) | — | — | **«New signups for Bank Account Data are currently disabled»** ([pagina ufficiale, letta 2026-11-24](https://bankaccountdata.gocardless.com/new-signups-disabled)) | 720 giorni dichiarati | **Escluso**: non ci si può iscrivere |
| Plaid | — | UE presente | minimi mensili 500–2000 USD (terzi) | — | Escluso per i minimi |
| open-banking.io | dichiara di avere il certificato | n.d. | 3 €/mese primo conto (articolo scritto dall'autore del servizio) | — | **Escluso**: fonte autopromozionale, non verificabile |

Copertura nel dettaglio richiesta (Intesa, UniCredit, Poste, Fineco, N26, Revolut, Hype, BPER, MPS, ING): Enable Banking ne conferma 6 su 10 nella
pagina ufficiale; per le altre 4 (Fineco, N26, Revolut, Hype) la verifica è automatica nel task S-60s (elenco `aspsps` della sandbox/produzione).
Note dalla pagina Italia: UniCredit non espone le carte di credito (prepagate solo con IBAN); Mediolanum niente carte di credito; molte banche
italiane accettano **un solo consenso attivo per TPP e utente** (un nuovo consenso annulla il precedente) → il progetto usa **un solo consenso per
banca per utente, condiviso tra i dispositivi** (§3.6).

### 2.2 Raccomandazione
**Enable Banking.** Motivi: (1) è l'unico con documentazione ufficiale specifica e aggiornata sull'Italia (CBI Globe, SCA extra oltre 90 giorni, un
consenso per TPP); (2) licenza AISP propria utilizzabile da chi non ce l'ha; (3) **modalità ristretta gratuita** in produzione con i conti di Matteo:
si può costruire e provare tutto con una banca vera senza contratto e senza spendere; (4) API minimale (JWT RS256, 6 chiamate) che sta in una Edge
Function senza librerie; (5) società UE (Finlandia) → GDPR senza trasferimenti extra-UE dichiarati.
**Piano B: Salt Edge** (Partner Program, categorie incluse, possibile piano gratuito 100 connessioni da verificare). Il backend ha un'interfaccia
`BankProvider` (§3.3): cambiare fornitore = un adattatore nuovo e un nuovo valore `provider`, senza toccare le app (il contratto JSON verso le app è nostro).
**Scartati:** GoCardless (iscrizioni chiuse), Yapily/TrueLayer/Plaid (minimi mensili incompatibili con 4,99 € una tantum), Tink (prezzi non
accessibili e orientato a grandi clienti), open-banking.io (non verificabile).

### 2.3 Uscita dal fornitore (lock-in)
- Le app parlano solo con la nostra funzione (contratto v1 del §3.4). I dati importati sono `Transaction` dell'app: restano anche cambiando fornitore.
- Gli ID deterministici dipendono da `account_ref` (hash dell'IBAN, nostro) e da `tx_key` (ID del movimento della banca): con un altro fornitore
  `tx_key` potrebbe cambiare → al cambio si importa «Da oggi» per evitare doppioni (regola scritta nel task del cambio, non in v1).
- Il consenso è del fornitore: cambiando fornitore ogni utente deve ricollegare la banca (inevitabile in PSD2).

---

## 3. Architettura tecnica

### 3.1 Componenti
```
App iOS / Android ──HTTPS + JWT Supabase──> Edge Function `bank` (Supabase, Deno) ──HTTPS + JWT RS256──> api.enablebanking.com ──> banca
        │                                         │ legge/scrive SOLO: bank_links, bank_auth_states, bank_usage, bank_config (service role)
        └──── sync esistente (mt_* o mt_vault) ───┘ nessun dato bancario salvato sul server dalla funzione
```
- Codice della funzione: `03_CODICE/bucktrail-backend/supabase/functions/bank/` (la radice del progetto non ammette cartelle nuove; `03_CODICE` sì).
  - `index.ts` — solo l'ingresso Deno (`Deno.serve`, `Deno.env`), 30 righe.
  - `core.ts` — router, validazione, autenticazione, limiti, sigilli: **puro TypeScript con Web Crypto e `fetch` iniettato**, eseguibile anche in Node 26.
  - `providers/provider.ts` (interfaccia `BankProvider`), `providers/enablebanking.ts` (adattatore), `normalize.ts` (risposta del fornitore → contratto v1).
  - `03_CODICE/bucktrail-backend/tests/*.test.ts` con `node --test` (Node 26 esegue TypeScript con type stripping; **niente Deno né CLI Supabase
    necessari sul Mac per i test**). Fixture in `tests/fixtures/`.
  - `03_CODICE/bucktrail-backend/sql/s60-bank-v1.sql` e `s60-bank-v1-rollback.sql` (copie esatte del §4.5).
  - `03_CODICE/bucktrail-backend/scripts/sandbox-smoke.mjs` (prova guidata con la sandbox vera, §10.4).
- Deploy: `npx supabase functions deploy bank --project-ref <ref>` (fatto da Matteo in S-60r: richiede il suo login Supabase). `verify_jwt` resta attivo.

### 3.2 Segreti (mai nell'app, mai nel repository, mai nei log)
| Segreto (Supabase → Edge Functions → Secrets) | Contenuto |
|---|---|
| `ENABLEBANKING_APP_ID` | ID applicazione (il `kid` del JWT) |
| `ENABLEBANKING_PRIVATE_KEY` | chiave privata RSA PEM (PKCS#8) generata nel pannello Enable Banking |
| `ENABLEBANKING_ENV` | `sandbox` oppure `production` (cambia solo il controllo dei limiti e il registro; l'URL API è lo stesso `https://api.enablebanking.com`) |
| `BANK_SERVER_SECRET` | 32 byte casuali esadecimali (`openssl rand -hex 32`): da qui, con HKDF-SHA256, la funzione deriva `K_seal` (info `bucktrail/bank/v1/seal`) e `K_hash` (info `bucktrail/bank/v1/hash`) |
| `BANK_REDIRECT_URL` | `https://bucktrailapp.com/banca/ritorno` |
Variabili fornite da Supabase: `SUPABASE_URL`, `SUPABASE_ANON_KEY`, `SUPABASE_SERVICE_ROLE_KEY` [DA VERIFICARE in S-60r: con le nuove chiavi API il nome
può essere diverso; la funzione legge `SUPABASE_SERVICE_ROLE_KEY` e, se assente, `SUPABASE_SECRET_KEY`].
La chiave privata si importa con `crypto.subtle.importKey("pkcs8", …, {name:"RSASSA-PKCS1-v1_5", hash:"SHA-256"})`; il JWT del fornitore dura **1 ora**
(massimo consentito 24 h) ed è tenuto in memoria nell'istanza.

### 3.3 Interfaccia interna `BankProvider`
`listAspsps(country)`, `startAuth({aspsp, validUntil, state, redirectUrl, psuType, language})` → `{url}`, `createSession(code)` →
`{sessionId, validUntil, accounts[]}`, `balances(sessionId, accountUid)`, `transactions(sessionId, accountUid, dateFrom, continuationKey, psuHeaders)`,
`deleteSession(sessionId)`. Errori del fornitore mappati su un insieme chiuso (§3.4.3).

### 3.4 Contratto v1 tra app e funzione (unico, uguale per iOS e Android)
Base: `POST {SUPABASE_URL}/functions/v1/bank/<azione>`; intestazioni `Authorization: Bearer <access token Supabase>`, `apikey: <anon>`,
`Content-Type: application/json`, `X-Bucktrail-Client: ios/<versione>` o `android/<versione>`. Corpo ≤ 16 KiB. Solo `POST` (anche le letture:
niente dati nei query string, che finiscono nei log dei proxy). Risposte con `Cache-Control: no-store`. Nessun CORS (solo app native: `OPTIONS` → 405).

#### 3.4.1 Azioni
| Azione | Richiesta | Risposta 200 | Controlli |
|---|---|---|---|
| `status` | `{}` | `{"v":1,"connect_enabled":bool,"max_links_per_user":2,"active_links":n}` | utente autenticato |
| `aspsps` | `{"country":"IT"}` (ISO 3166 alfa-2, regex `^[A-Z]{2}$`) | `{"aspsps":[{"name","country","max_consent_days","beta":bool}]}` ordinati per nome | cache in memoria 24 h per paese; niente loghi (si eviterebbe di far scaricare immagini da terzi) |
| `start` | `{"aspsp":{"name","country"},"verifier_hash":"<b64url SHA-256 di 32 byte casuali>","language":"it"}` | `{"url":"https://…","state":"<b64url 32 byte>","expires_at":"…"}` | `connect_enabled`; collegamenti attivi utente < `max_links_per_user`; globali < `max_active_links`; `bank_usage.starts` ≤ 10/giorno; salva `bank_auth_states` (hash dello state, hash del verificatore, scadenza 15 min); `valid_until` = ora + min(180, `max_consent_days`) giorni |
| `finish` | `{"state","code","verifier"}` | `{"connection":{"session_token","valid_until","aspsp":{"name","country"}},"accounts":[{"account_token","account_ref","name","iban_masked","currency","cash_account_type"}]}` | state esistente, non scaduto, dello stesso utente, **monouso** (cancellato subito); `SHA-256(verifier)` = `verifier_hash`; poi `createSession`; inserisce `bank_links` |
| `balances` | `{"session_token","account_token"}` | `{"balances":[{"type":"CLBD|ITBD|ITAV|CLAV|XPCD|OTHR","amount":"-12.30","currency":"EUR","reference_date":"2026-11-20"|null}]}` | sigilli validi per questo utente; `bank_links.status = active` |
| `transactions` | `{"session_token","account_token","date_from":"YYYY-MM-DD","continuation_key":null|"…","attended":bool}` | `{"transactions":[TX…],"continuation_key":null|"…"}` | come sopra; se `attended=false`: `now - last_unattended_at ≥ 6 h` altrimenti 429 `too_soon` (aggiornato solo alla prima pagina); `date_from` ≥ oggi − 92 giorni |
| `disconnect` | `{"session_token"}` | `{"ok":true}` | `deleteSession` presso il fornitore (al meglio: un errore del fornitore non blocca) + `bank_links` cancellata |

`TX` (movimento normalizzato, tutte le chiavi sempre presenti):
```json
{"tx_key":"e:…|t:…|h:<32 hex>","status":"booked|pending","amount":"-12.50","currency":"EUR",
 "booking_date":"2026-11-20"|null,"value_date":"2026-11-20"|null,"tx_date":"2026-11-19"|null,
 "description":"PAGAMENTO POS ESSELUNGA …","counterparty":"ESSELUNGA SPA"|null,"counterparty_ref":"a:<64 hex>"|null,
 "mcc":"5411"|null,"bank_code":"PMNT-CCRD-POSD"|null,"fx":false}
```
Regole di normalizzazione (in `normalize.ts`, coperte dai vettori):
- `amount`: stringa decimale con segno, **`-` se `credit_debit_indicator = DBIT`**, nessun segno se `CRDT`; parte numerica dal campo `transaction_amount.amount`
  del fornitore (valore assoluto). Validazione `^-?\d{1,12}(\.\d{1,4})?$`; altrimenti il movimento è scartato e contato in `skipped` (mai indovinare).
- `status`: `BOOK` → `booked`; `PDNG` → `pending`; altro → scartato. [DA VERIFICARE in S-60s i valori reali della sandbox].
- `tx_key`: `"e:" + entry_reference` se non vuoto; altrimenti `"t:" + transaction_id`; altrimenti `"h:" + primi 32 hex di
  SHA-256(booking_date|amount_canonico|currency|NORM(description)|NORM(counterparty))`. `NORM` = maiuscolo, spazi multipli → uno, trim.
  `amount_canonico` = decimale senza `+`, senza zeri iniziali, senza zeri finali dopo la virgola, senza punto se intero, `-0` → `0` (es. `-12.50` → `-12.5`).
  Per i movimenti `pending` il `tx_key` serve solo alla visualizzazione (non si importano).
- `description`: `remittance_information` unito con spazio, max 500 caratteri; `counterparty`: per i DBIT `creditor.name`, per i CRDT `debtor.name`.
- `counterparty_ref`: se il fornitore fornisce l'IBAN della controparte, `"a:" + SHA-256hex("bucktrail/bank/v1/acct|" + IBAN maiuscolo senza spazi)`; altrimenti `null`.
  **L'IBAN della controparte non esce mai dalla funzione.**
- `mcc`: `merchant_category_code` se presente [DA VERIFICARE in S-60s], altrimenti `null`. `fx` = `true` se c'è `exchange_rate` o la valuta
  dell'importo originale è diversa.
- Account: `account_ref` = `"a:" + SHA-256hex("bucktrail/bank/v1/acct|" + IBAN)` se c'è l'IBAN; altrimenti `"p:" + identification_hash` del
  fornitore se presente; altrimenti `"u:" + SHA-256hex(uid)` (instabile: al rinnovo il conto va riabbinato a mano, §4.3). `iban_masked` =
  primi 4 caratteri + `•••• ` + ultimi 4. `name` = nome del prodotto/conto fornito dalla banca, max 60 caratteri.

#### 3.4.2 Sigilli (`session_token`, `account_token`)
L'app non vede mai l'ID di sessione del fornitore né l'`uid` del conto: riceve **sigilli opachi**.
`session_token = "bs1." + b64url(nonce12 || AES-256-GCM(K_seal, session_id, aad = "bucktrail/bank/v1/session|" + user_id))`,
`account_token = "ba1." + b64url(nonce12 || AES-256-GCM(K_seal, account_uid, aad = "bucktrail/bank/v1/account|" + user_id + "|" + session_hash))`,
`session_hash = HMAC-SHA256(K_hash, session_id)` in esadecimale.
Effetti: un sigillo rubato non funziona con un altro utente (AAD); un dump del database o del vault non dà accesso alla banca senza `BANK_SERVER_SECRET`;
la funzione non deve cercare tabelle per sapere di chi è una sessione (l'AAD lo dimostra), ma controlla comunque `bank_links` per stato e limiti.

#### 3.4.3 Errori (HTTP + `{"error":"<codice>"}`, nient'altro)
`unauthorized` 401 · `bad_request` 400 · `disabled` 403 (connect spento) · `limit_reached` 403 · `not_found` 404 (state sconosciuto/scaduto) ·
`revoked` 410 (riga `bank_links` assente/revocata, o il fornitore dice sessione chiusa) · `expired` 410 (consenso scaduto: `EXPIRED_SESSION`) ·
`too_soon` 429 · `rate_limited` 429 (limite nostro o `ASPSP_RATE_LIMIT_EXCEEDED`: l'app attende 6 h) · `bank_unavailable` 502 · `provider_error` 502 ·
`not_supported` 422 (tipo di conto non leggibile). Le app mappano i codici sugli stati del §7.3.

### 3.5 Flusso di collegamento (con protezione tipo PKCE)
1. L'app genera `verifier` (32 byte casuali) e salva in modo sicuro `{verifier, aspsp, started_at}` (iOS Keychain `com.bucktrail.bank.pending`,
   accessibilità `AfterFirstUnlockThisDeviceOnly`; Android SharedPreferences cifrate con chiave Keystore, stesso schema di `KeystoreSessionStore.kt`); scade dopo 15 min.
2. `start` → l'app apre `url` nel **browser di sistema** (iOS `UIApplication.open` / Android Custom Tab). Scelta: niente WebView (le banche le bloccano e
   l'utente deve poter usare l'app della banca); niente `ASWebAuthenticationSession` (con il passaggio all'app della banca il ritorno arriva comunque in Safari).
3. La banca rimanda a `https://bucktrailapp.com/banca/ritorno?code=…&state=…` (oppure `?error=…&error_description=…`).
   - Se l'app è installata, **Universal Link** (iOS) / **App Link verificato** (Android) apre direttamente l'app.
   - Altrimenti la pagina di ritorno (statica, sulla landing) toglie subito la query dalla barra (`history.replaceState`) e apre
     `bucktrail://banca/ritorno?<stessa query>`, con un pulsante «Torna a Bucktrail» se il browser blocca l'apertura automatica.
4. L'app riceve l'URL (`onOpenURL` / `onNewIntent`), confronta `state` con quello in attesa (se manca o è diverso: ignora, nessuna chiamata), chiama
   `finish` con `code`, `state`, `verifier`; cancella lo stato in attesa in ogni caso.
5. Un'app malevola che intercettasse lo schema `bucktrail://` non può completare: le manca il `verifier` (resta nel portachiavi del telefono) e il JWT dell'utente.

**Schemi esatti**
- iOS `Info.plist`: `CFBundleURLTypes` con `CFBundleURLSchemes = [bucktrail]` (oggi iOS non ne ha; Android usa già `bucktrail://home|add|balance`).
  Entitlement `com.apple.developer.associated-domains = ["applinks:bucktrailapp.com"]` in `MoneyTracker/MoneyTracker.entitlements`.
- `SOCIAL/landing/.well-known/apple-app-site-association` (senza estensione, servito come `application/json` da `_worker.js`):
  `{"applinks":{"details":[{"appIDs":["KWX3UQA25F.com.matteo.moneytracker.MoneyTracker"],"components":[{"/":"/banca/ritorno*"}]}]}}`
  (Team ID e bundle letti da `project.pbxproj`).
- Android `AndroidManifest.xml`, sulla `MainActivity`: `<intent-filter android:autoVerify="true">` con `VIEW`, `DEFAULT`, `BROWSABLE`, `scheme https`,
  `host bucktrailapp.com`, `pathPrefix /banca/ritorno`; e un secondo filtro `scheme bucktrail`, `host banca`.
  `SOCIAL/landing/.well-known/assetlinks.json` con `package_name com.bucktrail.android` e le impronte SHA-256 del certificato **debug** (S-60m la
  ricava con `keytool -list -v -keystore ~/.android/debug.keystore -storepass android`) e **release/Play App Signing** ([DA COMPLETARE] da Matteo in S-60u).
- Pagina `SOCIAL/landing/banca/ritorno.html` (servita su `/banca/ritorno`): HTML minimo it/en secondo `navigator.language`, `<meta name="referrer"
  content="no-referrer">`, **nessuno script di analytics** (lo script di Cloudflare Web Analytics NON va incluso: vedrebbe l'URL con il `code`),
  `_worker.js` aggiunge `Cache-Control: no-store` e `Referrer-Policy: no-referrer` per `/banca/*`.

### 3.6 Più dispositivi e rinnovo
- **Un consenso per banca e per utente**, condiviso: il `session_token` sta nell'entità sincronizzata `BankConnection` (§4.2), cifrata nel vault se la
  Protezione avanzata è attiva. Ogni dispositivo dell'utente può aggiornare. Le banche italiane annullano il consenso precedente se se ne crea un
  altro: per questo non si crea mai un consenso per dispositivo.
- Due dispositivi che aggiornano insieme: il server limita gli aggiornamenti non presidiati (6 h per collegamento); gli ID deterministici rendono
  l'importazione idempotente (§4.3); le decisioni sono righe con lo stesso ID su tutti i dispositivi.
- **Rinnovo**: 7 giorni prima di `valid_until` compare l'avviso; «Rinnova accesso» ripete il flusso del §3.5 sulla stessa banca; al `finish` l'app
  abbina i conti nuovi a quelli già collegati **per `account_ref`** (stesso IBAN = stesso conto: cursore e destinazione restano); poi `disconnect`
  del vecchio `session_token` (se la banca non l'ha già chiuso). I conti con `account_ref` `u:` vanno riabbinati a mano (schermata di scelta conti).

### 3.7 Limiti e registro
- `bank_usage` per utente e giorno UTC: `calls` ≤ 300, `starts` ≤ 10 (funzione SQL atomica `bank_hit`, §4.5). Oltre: 429 `rate_limited`.
- `bank_config` (una riga): `connect_enabled` (default **false**), `max_links_per_user` (2), `max_active_links` (50, tetto globale dei costi).
- Registro: una riga JSON per richiesta con `azione`, `esito`, `ms`, `err` (codice nostro o del fornitore) e i primi 8 caratteri di SHA-256(user_id).
  **Mai**: corpi, token, sigilli, `session_id`, `uid`, IBAN, nomi, importi, descrizioni, `code`, `state`, intestazioni `Authorization`.
  Un test (S-60b) intercetta `console.*` e verifica che nessuno di questi valori di prova compaia.

---

## 4. Modello dati

### 4.1 Principio
- **Movimento importato = `Transaction` normale.** Nessun campo nuovo su `Transaction`/`Account`, nessuna colonna nuova su `mt_transactions`:
  i client vecchi lo vedono e lo sincronizzano come un movimento qualsiasi; saldi, Home, statistiche, budget, export e PDF lo trattano come oggi.
- **Riconoscibile senza campi nuovi:** l'`id` di un movimento importato è un **UUID versione 5** deterministico; i movimenti creati a mano hanno UUID
  versione 4 (`UUID()` / `UUID.randomUUID()`). `isBankImported(id) = (id.version == 5)` su entrambe le piattaforme.
- I metadati stanno in entità nuove, **senza relazioni SwiftData/Room** verso i modelli esistenti (solo UUID): nessun effetto sulle cancellazioni a cascata esistenti.

### 4.2 Entità nuove
| Entità (iOS `@Model` / Room `@Entity`) | Campi (tipo) | Sincronizzata? |
|---|---|---|
| `BankConnection` / `bank_connections` | `id` UUID · `provider` String (`enablebanking`) · `aspspName` String · `aspspCountry` String · `sessionToken` String (`bs1.`) · `validUntil` Date · `status` String (`active`/`expired`/`revoked`/`error`) · `createdAt` Date · `lastRefreshAt` Date? | sì: `mt_bank_connections` / kind `bank_connection` |
| `BankAccountLink` / `bank_account_links` | `id` UUID · `connectionId` UUID · `accountId` UUID? (conto Bucktrail di destinazione; `nil` = non importare) · `accountRef` String · `accountToken` String (`ba1.`) · `displayName` String · `ibanMasked` String · `currency` String · `importFrom` Date (inizio giornata locale) · `cursorDate` Date? · `lastBalance` Decimal? (Android centesimi `Long?`) · `lastBalanceAt` Date? · `createdAt` Date | sì: `mt_bank_accounts` / kind `bank_account` |
| `BankDecision` / `bank_decisions` | `id` UUID (= ID deterministico del movimento bancario) · `linkId` UUID · `decision` String (`imported`/`matched`/`ignored`/`transfer`) · `transactionId` UUID? · `bookingDate` Date · `createdAt` Date | sì: `mt_bank_decisions` / kind `bank_decision` |
| `BankInboxItem` / `bank_inbox` | `id` UUID (= ID deterministico) · `linkId` UUID · `kind` String (`duplicate`/`transfer`/`pending`) · `txJSON` String (TX normalizzato) · `candidateIds` String (UUID separati da virgola) · `createdAt` Date | **no**, solo locale (si ricalcola a ogni aggiornamento) |

### 4.3 Identificativi stabili e deduplica idempotente
- Spazio dei nomi fisso: `NS_BANK = 2b7d6c1e-8f3a-4e59-a0c4-6d1f9e3b5a72`.
- `importId = UUIDv5(NS_BANK, UTF8("bucktrail/bank/v1|" + accountRef + "|" + txKey))` (RFC 4122 §4.3, SHA-1). iOS: `Insecure.SHA1` di CryptoKit;
  Android: `MessageDigest("SHA-1")` (attenzione: `UUID.nameUUIDFromBytes` è la versione 3, **non** va usata); Python `uuid.uuid5` è il riferimento dei vettori.
- Movimenti `h:` identici nello stesso giorno: dopo aver raccolto **tutte** le pagine della finestra, l'app aggiunge `#2`, `#3`… al `txKey`
  dal secondo in poi, nell'ordine restituito (il primo resta senza suffisso).
- **Ordine delle verifiche per ogni movimento `booked`** (pura, `BankMatcher.plan`):
  1. esiste `BankDecision(id)` → salta;
  2. esiste `Transaction(id)` → crea `BankDecision(imported)` (riparazione dopo un'interruzione) e salta;
  3. `currency ≠ link.currency` → salta (conteggio `skippedCurrency`);
  4. data del movimento < `link.importFrom` → salta;
  5. candidati doppione (§4.4) non vuoti → `BankInboxItem(duplicate)`;
  6. possibile giroconto (§4.4) → `BankInboxItem(transfer)`;
  7. altrimenti **importa**: `Transaction` con `id = importId` + `BankDecision(imported)`.
- Interruzione a metà: tutto è idempotente (stessi ID); `cursorDate` si aggiorna **solo** dopo il salvataggio riuscito dell'intera finestra.
- Finestra di lettura: `date_from = max(importFrom, cursorDate − 7 giorni)` (le banche contabilizzano in ritardo); `cursorDate` = data massima
  `booking_date` vista. Massimo 50 pagine e 5 000 movimenti per aggiornamento (oltre: si ferma, salva quanto fatto, riprende al prossimo).
- Potatura: le `BankDecision` con `bookingDate < cursorDate − 35 giorni` si cancellano a fine aggiornamento (non possono più tornare nella finestra):
  le tabelle restano piccole (~1 mese di movimenti per conto).
- Movimento importato che l'utente **cancella**: la `BankDecision(imported)` resta → non rinasce. Movimento modificato dall'utente: mai toccato di nuovo.

### 4.4 Riconciliazione con i movimenti manuali (soglie esatte)
**Data del movimento bancario** `d = tx_date ?? booking_date` (data di acquisto se la banca la dà); diventa `Transaction.date` = `d` alle **12:00 ora locale**
(evita salti di giorno coi fusi). Confronti per giorno di calendario locale.

| Regola | Valore |
|---|---|
| Conto | il movimento manuale è nel conto Bucktrail di destinazione del collegamento |
| Origine | `id.version ≠ 5` e il suo ID non è `transactionId` di nessuna `BankDecision` |
| Segno | `amount < 0` ↔ `type = Uscita`; `amount > 0` ↔ `Entrata` (anche le gambe di giroconto manuali sono candidate) |
| Importo | **uguale al centesimo** (`abs(amount)` arrotondato HALF_UP a 2 decimali = `Transaction.amount`); solo se `fx = true`: differenza ≤ 3 % |
| Data, movimento manuale effettuato (`isDone = true`) | giorno manuale ∈ [min(tx_date, booking_date) − 5 giorni, booking_date + 3 giorni] |
| Data, movimento manuale pianificato (`isDone = false`) | giorno manuale ∈ [booking_date − 7, booking_date + 7] |
| Ordine dei candidati | distanza in giorni crescente, poi somiglianza del nome (token in comune dopo `MerchantNameCleaner`), poi `createdAt` |
| Massimo candidati mostrati | 3 |

Azioni dell'utente su un `duplicate`:
- **«Sì, è lo stesso»** → `BankDecision(matched, transactionId = scelto)`; il movimento manuale **non cambia** (nome, categoria, data, note restano
  dell'utente) tranne: se era pianificato, `isDone = true` (è ciò che l'utente farebbe a mano; la data resta la sua).
- **«No, è nuovo»** → importa come al §4.3 punto 7.
- **«Ignora»** → `BankDecision(ignored)`.

**Giroconti tra i propri conti** (`transfer`): il movimento ha `counterparty_ref` uguale all'`accountRef` di un altro conto collegato
**oppure** esiste nell'altro conto collegato un movimento bancario di segno opposto, stesso importo assoluto, `booking_date` a ≤ 2 giorni.
Proposta «È un giroconto tra i tuoi conti?»: **«Sì»** → crea le due gambe come fa `AddTransferView` (stessi campi: `isTransfer = true`,
`transferGroupId` comune, categoria «Giroconto», icona `arrow.left.arrow.right`; leggere il file per i nomi delle gambe); la gamba nel conto collegato
ha `id = importId`, l'altra `id = importId` dell'altro movimento bancario se esiste, altrimenti UUID v4; `BankDecision(transfer)` per entrambi.
Se l'altra gamba esiste già a mano, vale la regola dei doppioni (precede). **«No»** → importa normalmente.

**Pendenti → contabilizzati:** i `pending` non si importano mai; si mostrano in «In attesa dalla banca» (sola lettura) e si sostituiscono a ogni
aggiornamento. Quando la banca li contabilizza arrivano come `booked` con il loro `tx_key` e seguono le regole sopra.
**Rettifiche della banca** (storni, correzioni): sono movimenti nuovi con segno opposto → si importano come tali. Un movimento già importato che
sparisce o cambia presso la banca: **nessuna azione** (v1 non cancella né modifica mai).

**Saldi:**
- Conto **nuovo** creato dal collegamento: `Account(type: .conto, o .carta se cash_account_type = CARD)`, nome = `displayName`, colore predefinito
  dell'app; `initialBalance = saldoBanca − Σ(importi con segno dei movimenti booked importati nella finestra iniziale)`, dove `saldoBanca` è il primo
  disponibile tra `CLBD`, `ITBD`, `XPCD`, `ITAV`, `CLAV` (Decimal, arrotondato HALF_UP a 2). È la stessa operazione che l'utente farebbe inserendo il saldo
  di partenza: nessun calcolo esistente cambia. Funzione pura `OpeningBalance.compute`.
- Conto **esistente**: `initialBalance` **mai** toccato. In dettaglio collegamento: «Saldo in banca» vs «Saldo in Bucktrail» (`currentBalance`);
  se diversi, «Allinea il saldo» crea una «Rettifica saldo» con lo stesso percorso già usato in `AccountsView.swift` (~riga 515) / `Dao.kt`
  (salvataggio conto con rettifica), importo = differenza, solo su tocco dell'utente.

### 4.5 Schema server (SQL completo, idempotente, additivo, reversibile)
Da incollare UNA volta nel SQL Editor (passo S-60r). Non modifica colonne, policy o funzioni esistenti; estende solo il controllo `kind` di
`mt_vault` (S-50) e aggiunge la guardia E2E alle 3 tabelle nuove.
```sql
-- Bucktrail · S-60 · Collegamento bancario · schema v1
-- Additivo, idempotente, reversibile (vedi s60-bank-v1-rollback.sql). Richiede lo schema S-50 già applicato.
begin;

-- 1) Tabelle sincronizzate dall'app (stessa forma delle mt_* esistenti: una riga per record, RLS per utente)
create table if not exists public.mt_bank_connections (
  id              uuid primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  provider        text not null check (provider in ('enablebanking')),
  aspsp_name      text not null check (length(aspsp_name) between 1 and 200),
  aspsp_country   text not null check (aspsp_country ~ '^[A-Z]{2}$'),
  session_token   text not null check (session_token like 'bs1.%' and length(session_token) < 1024),
  valid_until     timestamptz not null,
  status          text not null check (status in ('active','expired','revoked','error')),
  created_at      timestamptz not null,
  last_refresh_at timestamptz
);
create table if not exists public.mt_bank_accounts (
  id              uuid primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  connection_id   uuid not null,
  account_id      uuid,
  account_ref     text not null check (account_ref ~ '^[apu]:\S{1,200}$'),
  account_token   text not null check (account_token like 'ba1.%' and length(account_token) < 1024),
  display_name    text not null check (length(display_name) <= 200),
  iban_masked     text not null check (length(iban_masked) <= 40),
  currency        text not null check (currency ~ '^[A-Z]{3}$'),
  import_from     timestamptz not null,
  cursor_date     timestamptz,
  last_balance    numeric(18,2),
  last_balance_at timestamptz,
  created_at      timestamptz not null
);
create table if not exists public.mt_bank_decisions (
  id              uuid primary key,
  user_id         uuid not null references auth.users(id) on delete cascade,
  link_id         uuid not null,
  decision        text not null check (decision in ('imported','matched','ignored','transfer')),
  transaction_id  uuid,
  booking_date    timestamptz not null,
  created_at      timestamptz not null
);
create index if not exists mt_bank_accounts_user_idx  on public.mt_bank_accounts  (user_id);
create index if not exists mt_bank_decisions_user_idx on public.mt_bank_decisions (user_id);

do $$
declare t text;
begin
  foreach t in array array['mt_bank_connections','mt_bank_accounts','mt_bank_decisions'] loop
    execute format('alter table public.%I enable row level security', t);
    execute format('drop policy if exists %I on public.%I', t || '_select', t);
    execute format('drop policy if exists %I on public.%I', t || '_insert', t);
    execute format('drop policy if exists %I on public.%I', t || '_update', t);
    execute format('drop policy if exists %I on public.%I', t || '_delete', t);
    execute format('create policy %I on public.%I for select to authenticated using (user_id = (select auth.uid()))', t || '_select', t);
    execute format('create policy %I on public.%I for insert to authenticated with check (user_id = (select auth.uid()))', t || '_insert', t);
    execute format('create policy %I on public.%I for update to authenticated using (user_id = (select auth.uid())) with check (user_id = (select auth.uid()))', t || '_update', t);
    execute format('create policy %I on public.%I for delete to authenticated using (user_id = (select auth.uid()))', t || '_delete', t);
    -- guardia E2E di S-50 anche sulle tabelle nuove
    execute format('drop trigger if exists mt_e2e_guard on public.%I', t);
    execute format('create trigger mt_e2e_guard before insert or update or delete on public.%I for each row execute function public.mt_e2e_guard()', t);
  end loop;
end $$;

-- 2) Vault S-50: nuovi kind (il vincolo è ricreato con l'elenco esteso; nessuna riga esistente lo viola)
alter table public.mt_vault drop constraint if exists mt_vault_kind_check;
alter table public.mt_vault add constraint mt_vault_kind_check
  check (kind in ('account','transaction','budget','goal','rule','bank_connection','bank_account','bank_decision'));

-- 3) Tabelle SOLO del server (nessuna policy: authenticated/anon non le leggono né scrivono; le usa la funzione con la service role)
create table if not exists public.bank_links (
  id                 uuid primary key default gen_random_uuid(),
  user_id            uuid not null references auth.users(id) on delete cascade,
  provider           text not null check (provider in ('enablebanking')),
  session_hash       text not null unique check (session_hash ~ '^[0-9a-f]{64}$'),
  valid_until        timestamptz not null,
  status             text not null default 'active' check (status in ('active','revoked')),
  created_at         timestamptz not null default now(),
  last_unattended_at timestamptz
);
create index if not exists bank_links_user_idx on public.bank_links (user_id, status);
create table if not exists public.bank_auth_states (
  state_hash     text primary key check (state_hash ~ '^[0-9a-f]{64}$'),
  user_id        uuid not null references auth.users(id) on delete cascade,
  verifier_hash  text not null check (length(verifier_hash) between 40 and 64),
  aspsp_name     text not null,
  aspsp_country  text not null,
  valid_until    timestamptz not null,
  expires_at     timestamptz not null
);
create table if not exists public.bank_usage (
  user_id  uuid not null references auth.users(id) on delete cascade,
  day      date not null,
  calls    int  not null default 0,
  starts   int  not null default 0,
  primary key (user_id, day)
);
create table if not exists public.bank_config (
  id                  int primary key check (id = 1),
  connect_enabled     boolean not null default false,
  max_links_per_user  int not null default 2 check (max_links_per_user between 0 and 10),
  max_active_links    int not null default 50 check (max_active_links >= 0)
);
insert into public.bank_config (id) values (1) on conflict (id) do nothing;

alter table public.bank_links       enable row level security;
alter table public.bank_auth_states enable row level security;
alter table public.bank_usage       enable row level security;
alter table public.bank_config      enable row level security;
revoke all on public.bank_links, public.bank_auth_states, public.bank_usage, public.bank_config from anon, authenticated;

-- 4) Contatore atomico per i limiti (chiamato dalla funzione con la service role)
create or replace function public.bank_hit(p_user uuid, p_kind text, p_limit int) returns boolean
language plpgsql security definer set search_path = '' as $$
declare n int;
begin
  if p_kind = 'start' then
    insert into public.bank_usage (user_id, day, starts) values (p_user, current_date, 1)
      on conflict (user_id, day) do update set starts = public.bank_usage.starts + 1 returning starts into n;
  else
    insert into public.bank_usage (user_id, day, calls) values (p_user, current_date, 1)
      on conflict (user_id, day) do update set calls = public.bank_usage.calls + 1 returning calls into n;
  end if;
  delete from public.bank_auth_states where expires_at < now() - interval '1 day';
  delete from public.bank_usage where day < current_date - 7;
  return n <= p_limit;
end $$;
revoke all on function public.bank_hit(uuid, text, int) from public, anon, authenticated;

notify pgrst, 'reload schema';
commit;

-- Verifica (deve restituire 19 righe: 12 policy + 3 trigger + 4 tabelle server)
select 'policy' as tipo, tablename as nome from pg_policies where tablename like 'mt_bank_%'
union all
select 'trigger', event_object_table from information_schema.triggers
 where trigger_name = 'mt_e2e_guard' and event_manipulation = 'INSERT' and event_object_table like 'mt_bank_%'
union all
select 'server', table_name from information_schema.tables
 where table_schema = 'public' and table_name in ('bank_links','bank_auth_states','bank_usage','bank_config')
order by 1, 2;
```
[DA VERIFICARE in S-60c]: che il vincolo `kind` di `mt_vault` creato dallo script S-50 si chiami davvero `mt_vault_kind_check` (nome automatico di
Postgres per un `check` di colonna). Lo script S-60c, prima di scrivere il file definitivo, lo conferma nel server finto e aggiunge al blocco SQL una
riga di controllo: `select conname from pg_constraint where conrelid = 'public.mt_vault'::regclass and contype = 'c';` (va mostrata a Matteo nel ↩️).

**Ritorno indietro** (`s60-bank-v1-rollback.sql`, solo se Matteo lo chiede; cancella i metadati bancari sincronizzati, NON i movimenti importati):
```sql
begin;
delete from public.mt_vault where kind in ('bank_connection','bank_account','bank_decision');
alter table public.mt_vault drop constraint if exists mt_vault_kind_check;
alter table public.mt_vault add constraint mt_vault_kind_check check (kind in ('account','transaction','budget','goal','rule'));
drop function if exists public.bank_hit(uuid, text, int);
drop table if exists public.bank_config, public.bank_usage, public.bank_auth_states, public.bank_links;
drop table if exists public.mt_bank_decisions, public.mt_bank_accounts, public.mt_bank_connections;
notify pgrst, 'reload schema';
commit;
```
Accensione lato server (in S-60u, una riga): `update public.bank_config set connect_enabled = true where id = 1;`
Spegnimento d'emergenza dei NUOVI collegamenti: stessa riga con `false` (i collegamenti esistenti continuano a leggere).

### 4.6 Migrazioni locali (senza perdita di dati, retrocompatibili)
**iOS — `Persistence/SchemaMigration.swift`** (unico punto di Persistence toccato, motivo: SwiftData richiede di dichiarare i modelli nuovi):
- `enum SchemaV4: VersionedSchema` versione `4.0.0`, modelli = quelli di V3 + `BankConnection`, `BankAccountLink`, `BankDecision`, `BankInboxItem`.
- `MoneyTrackerMigrationPlan.schemas` += `SchemaV4`; `stages` += `MigrationStage.lightweight(fromVersion: SchemaV3.self, toVersion: SchemaV4.self)`
  (solo entità nuove: è il caso più semplice di migrazione leggera, come V2→V3).
- `MoneyTrackerApp.swift`: `Schema(versionedSchema: SchemaV4.self)`; cercare ogni altro uso di `SchemaV3` (es. `SharedStore.swift`, estensioni,
  Intents) e allinearlo: **tutti** i contenitori che aprono lo stesso store devono conoscere V4, altrimenti l'apertura fallisce.
- Modelli nuovi in file nuovi `MoneyTracker/Models/Bank*.swift` (Models toccato solo con file aggiunti).
- Test nuovo `MoneyTrackerTests/SchemaV4MigrationTests.swift`: crea uno store V3 su disco con conti/movimenti/budget/obiettivi/regole, lo riapre con
  il piano V4, verifica conteggi, importi `Decimal` identici, relazioni, e che le tabelle nuove siano vuote. Il test esistente `SchemaMigrationTests` resta invariato e verde.
**Android — Room 3 → 4** (`BucktrailDatabase.kt` versione 4 + entità; `data/Migrations.kt` nuova `Migration(3, 4)` con soli `CREATE TABLE IF NOT EXISTS`
per le 4 tabelle, nessun `ALTER` su quelle esistenti; nuove entità in `data/BankEntities.kt`, DAO in `data/BankDao.kt`).
Test: `MigrationTestHelper` (strumentato) 3→4 con dati e test JVM che la SQL della migrazione crei esattamente lo schema esportato da Room
(`exportSchema` se già attivo; altrimenti confronto dei `CREATE` con quelli generati).
**Retrocompatibilità:** una versione vecchia dell'app non apre più uno store V4? SwiftData/Room non fanno downgrade: è lo stesso vincolo delle
migrazioni passate (nessun utente torna a una versione vecchia dall'App Store). Accettato, come per V3.

### 4.7 Codice puro aggiunto (Domain, solo file nuovi, motivati: logica testabile senza UI né rete, condivisa nei vettori)
iOS `MoneyTracker/Domain/Bank/`: `BankIds.swift` (UUIDv5, `isBankImported`), `BankAmount.swift` (stringa → `Decimal` rigoroso, POSIX, HALF_UP 2),
`MerchantNameCleaner.swift`, `BankCategorySuggester.swift`, `BankMatcher.swift` (piano per movimento: §4.3–4.4), `TransferDetector.swift`,
`OpeningBalance.swift`. Android `domain/bank/` con gli stessi nomi in Kotlin (`BigDecimal`, centesimi `Long` solo all'ingresso in Room).
Nessun file esistente di `Domain/` viene modificato.

### 4.8 Sincronizzazione delle entità nuove
- Usa il livello di trasporto di S-50: nuove voci `SyncTable.bankConnections/bankAccounts/bankDecisions` (iOS) e righe `SyncMapper.bank*Row` (Android).
  In chiaro → `mt_bank_*`; con Protezione avanzata → `mt_vault` con `kind` `bank_connection`/`bank_account`/`bank_decision` (payload = la riga JSON,
  AAD come §3.4 di S-50).
- Semantica identica alle tabelle «piccole» di oggi (conti/budget): **istantanea completa**, upsert a blocchi di 200, cancellazione degli orfani,
  al pull vince il remoto. `BankInboxItem` non si sincronizza.
- **Isolamento:** il passo «banca» gira **dopo** il push/pull esistenti, in un `do/catch` proprio: un suo errore viene registrato e non cambia lo stato
  della sync principale (`SyncStatus`, retry, backoff restano quelli di oggi). A interruttore spento il passo non esiste (nessuna richiesta).
- Tabelle assenti sul server (404 `PGRST205`): passo saltato e collegamento bancario nascosto (`serverSupported = false`), come S-50.
- Migratore E2E di S-50 (`E2EMigrator` iOS/Android, passi A4/A5/A7 e D4/D5/D7) e verificatore (§7.5 di S-50): elenco dei `kind` esteso con i 3 nuovi,
  **solo se `BankFeature.isEnabled`** (a interruttore spento il migratore è identico a quello collaudato in S-50).
- Ordine: push di `bank_connections` → `bank_accounts` → `bank_decisions` (dopo i movimenti, così una decisione non punta a un movimento non ancora caricato).

---

## 5. Categorizzazione

Ordine (funzione pura `BankCategorySuggester.suggest`), il primo che risponde vince; il risultato è sempre una categoria **esistente** dell'utente:
1. **Storico dell'utente:** `LastUsedCategory.suggest(for: nomePulito, history:, availableCategories:)` (regola già dell'app: l'ultima scelta
   dell'utente per quel nome).
2. **Parole chiave dell'app:** `KeywordCategoryClassifier.classify(nomePulito + " " + description)` (dizionario esistente `CategoryKeywords.json`), se ≠ «Altro».
3. **Indizio del fornitore:** `mcc` → tabella fissa (solo se la categoria esiste): 5411, 5412, 5422, 5441, 5451, 5462, 5499, 5812, 5813, 5814 → «Cibo»;
   4111, 4121, 4131, 4784, 5541, 5542, 7523 → «Trasporti»; 3000–3299, 3501–3999, 4411, 4511, 4722, 7011 → «Viaggi»; 5912, 8011–8099 → «Salute»;
   4812, 4814, 4899, 5968 → «Abbonamenti»; 4900 → «Casa»; 5311, 5611–5699, 5732, 5942, 5945 → «Shopping»; 7832, 7841, 7991–7999 → «Svago»;
   8211–8299 → «Istruzione». Se `bank_code` indica stipendio/pensione [DA VERIFICARE i codici reali in S-60s] → «Lavoro».
4. Altrimenti «Altro». Icona = icona della categoria scelta dalla tabella `Category` dell'utente.
- **Mai sovrascrivere:** la categoria si decide una sola volta, alla creazione. Gli aggiornamenti successivi non toccano movimenti esistenti.
- I giroconti confermati usano «Giroconto»; i doppioni confermati tengono la categoria dell'utente.

**Nomi puliti** (`MerchantNameCleaner.clean(counterparty:description:)`, pura, vettori condivisi):
1. Sorgente: `counterparty` se non vuoto, altrimenti `description`.
2. Togli (senza distinzione di maiuscole) i prefissi bancari: `PAGAMENTO POS`, `PAG. POS`, `PAGAMENTO CARTA`, `PAGAMENTO TRAMITE POS`, `OPERAZIONE CARTA`,
   `ACQUISTO CARTA`, `ADDEBITO SDD`, `ADDEBITO DIRETTO`, `DISPOSIZIONE DI BONIFICO`, `BONIFICO A VOSTRO FAVORE`, `BONIFICO DA`, `BONIFICO A`, `VS.DISP.`,
   `CARD PAYMENT`, `POS`, `SEPA DD`, `SDD`.
3. Togli: date (`\b\d{1,2}[/.-]\d{1,2}([/.-]\d{2,4})?\b`), ore (`\b\d{1,2}[.:]\d{2}\b`), carte mascherate (`[*X]{2,}\d{2,4}`), riferimenti numerici
   ≥ 6 cifre, `CRO …`, `TRN …`, `ID …`, `RIF …`, codici paese finali (`\b(ITA|IT|IRL|NLD|LUX|DEU|FRA|ESP|GBR)\b$`).
4. Spazi multipli → uno, trim, punteggiatura ai bordi tolta; **Prima Lettera Maiuscola** per parola (parole ≤ 3 lettere tutte maiuscole restano tali, es. «IKEA» → «Ikea», «BNL» resta «BNL»).
5. Massimo 40 caratteri (taglio sulla parola). Se vuoto → testo localizzato `bank_movimento_banca`.
- La descrizione originale va in `Transaction.notes` (max 500 caratteri), così l'utente può sempre leggerla; il campo era vuoto alla creazione,
  quindi non si sovrascrive nulla.

---

## 6. Coerenza con S-50

### 6.1 Decisione
**Un solo percorso per tutti gli utenti, con o senza Protezione avanzata.** Il pull dal fornitore parte **dal dispositivo** e passa dalla funzione
`bank` **solo in transito** (memoria, nessun salvataggio, nessun corpo nei log). Il server conserva soltanto: hash della sessione, stato, scadenza,
contatori e configurazione (`bank_links`, `bank_usage`, `bank_auth_states` temporanei, `bank_config`) — **nessun dato bancario**, né in chiaro né cifrato.
Tutto ciò che è bancario e persistente sta sul dispositivo e viaggia con la sync dell'utente: in chiaro nelle `mt_bank_*` senza Protezione avanzata,
**cifrato nel vault** con la Protezione avanzata.
**Scartate:** (a) pull lato server con salvataggio cifrato (il server dovrebbe avere la chiave: contraddice S-50); (b) pull diretto dal dispositivo verso
Enable Banking con un JWT del fornitore consegnato all'app (quel JWT vale per **tutte** le sessioni dell'applicazione: dare una credenziale globale a ogni
telefono è un rischio OWASP inaccettabile); (c) percorso diverso per gli utenti E2E (il doppio del codice e dei test).

### 6.2 Dove stanno i segreti e cosa vede chi
| Cosa | Dove | Senza Protezione avanzata | Con Protezione avanzata |
|---|---|---|---|
| Chiave privata Enable Banking, `BANK_SERVER_SECRET` | segreti Supabase | solo la funzione (e chi amministra il progetto) | idem |
| `session_token`, `account_token` (sigilli) | `BankConnection`/`BankAccountLink` sul telefono + sync | leggibili da chi amministra il database, ma **inutili senza `BANK_SERVER_SECRET`** | cifrati nel vault (illeggibili sul server) |
| `session_id` vero del fornitore | **solo** dentro i sigilli; in chiaro solo nella memoria della funzione | — | — |
| Movimenti, saldi, nomi dei conti, IBAN mascherato | telefono + sync | come gli altri dati: in chiaro su Supabase (cifrati a riposo dal fornitore) | **cifrati nel vault** |
| IBAN completi (propri e delle controparti) | mai fuori dalla funzione (solo hash `a:`) | — | — |
| Movimenti durante il download | memoria della funzione, pochi millisecondi | visibili alla funzione | **visibili alla funzione** (limite dichiarato, §6.4) |

### 6.3 Più dispositivi con Protezione avanzata
- Il dispositivo B sbloccato (DEK presente) riceve `BankConnection` dal vault → ha il `session_token` → può aggiornare. Stesse regole di idempotenza del §4.3.
- Dispositivo in `.locked` (frase non inserita): nessun `session_token` leggibile → la riga «Conti collegati» mostra `bank_bloccato_e2e`
  («Sblocca la sincronizzazione per aggiornare i conti collegati»); niente aggiornamenti; nessun dato perso.
- Attivazione della Protezione avanzata **dopo** aver collegato una banca: il migratore S-50 (esteso, §4.8) sposta anche i 3 kind bancari nel vault,
  con verifica e rollback come per gli altri. Disattivazione: il percorso inverso li rimette in `mt_bank_*`.
- Collegamento creato **mentre** la protezione è attiva: le righe nascono direttamente nel vault (il trigger rifiuta `mt_bank_*` in chiaro).

### 6.4 Cosa si promette (e cosa no)
- Si può dire: «Con la Protezione avanzata anche i dati dei conti collegati restano cifrati sul cloud. Per scaricarli, i movimenti passano dal nostro
  servizio solo in transito, senza essere salvati.»
- **Non** si può dire che nessuno, mai, può vedere i movimenti bancari: la funzione li vede in transito; Enable Banking (AISP autorizzato) li legge
  per definizione; chi possiede la chiave privata dell'applicazione e un `session_id` valido può leggere quella sessione finché il consenso è valido.
  [DA VERIFICARE in S-60s]: se l'API di Enable Banking permette di **elencare** le sessioni di un'applicazione. Se sì, il gestore potrebbe tecnicamente
  leggere i conti collegati durante il consenso anche con Protezione avanzata: va scritto nella privacy (testo §8.4 già prudente).

---

## 7. Interfaccia

### 7.1 Dove (design «Sentiero», stessi componenti delle righe vicine)
- **iOS** `SettingsView`: nuova sezione `SectionLabel(text: "bank_titolo")` **subito dopo «Sicurezza»**, una riga «Conti collegati» (titolo
  `.scaledFont(size: 15)` `DS.ink`, sottotitolo `.scaledFont(size: 11)` `DS.smoke`, `chevron.right`, `ThinDivider()`), visibile solo se
  `BankFeature.isEnabled && !demoModeEnabled && BankController.shared.serverSupported`. Apre `BankConnectionsView` con lo stesso schema di `AuditLogView`.
- **Movimenti** (`TransactionsView`): **solo se ci sono elementi da confermare**, una striscia in alto `bank_da_confermare` (sfondo `DS.accentSoft`,
  testo `DS.ink`, icona `tray.and.arrow.down`) che apre `BankInboxView`. Nessun cambiamento alle righe dei movimenti.
- **Conti** (`AccountsView`): **solo per i conti collegati**, sotto il nome una riga `.scaledFont(size: 11)` `DS.smoke` con icona `building.columns`
  e `bank_collegato` · `bank_aggiornato`. Nessun cambiamento agli altri conti.
- **Modifica movimento** (`AddTransactionView` in modifica): se `isBankImported(id)`, una riga informativa `bank_importato_da` (sola lettura) sopra le note.
- **Android:** stessi punti (`SettingsSheets.kt` dopo la sezione Sicurezza, schermata Movimenti, Conti, modifica movimento), colori del tema Sentiero già usati.
- Mai `preferredColorScheme`, mai colori fissi: solo `DS.*` e colori del tema Android; font scalabili; icone SF Symbols su iOS e i vettori già usati
  su Android (per `building.columns` e `tray.and.arrow.down` disegnare un vettore proprio in `SfIcons.kt`, come deciso in S-48).

### 7.2 Schermate e flusso passo passo
1. **Conti collegati — vuota:** icona `building.columns` in `DS.accent`, B04, elenco puntato B05, B06, B07 in `DS.smoke`, pulsante primario B08.
   Se `connect_enabled = false`: pulsante disabilitato + B42. Android senza account: B40 + pulsante «Accedi» esistente.
2. **Scegli la banca:** campo di ricerca B10, elenco nomi (paese predefinito dalla regione del telefono, IT in testa), nessun logo; in fondo B11.
3. **Prima di continuare:** titolo B12, B13 con il nome della banca, ripasso B05/B06/B07, pulsante B14, link «Annulla» (chiave esistente «Annulla»).
4. **In attesa:** indicatore + B15, pulsante «Annulla». Se l'app viene riaperta senza ritorno entro 15 minuti → stato pulito, schermata 1.
5. **Scegli i conti:** B17; per ogni conto: nome, `iban_masked`, valuta; interruttore «Importa»; B18 → menu «Nuovo conto» (B19) / conti esistenti;
   B20 → «Da oggi» (B21, predefinito per conto esistente) / «Ultimi 90 giorni» (B22, predefinito per conto nuovo). Conto in altra valuta: disabilitato con B23;
   tipo non leggibile: B59. Pulsante B24.
6. **Riuscito:** B25 + avanzamento del primo aggiornamento + B26.
7. **Dettaglio collegamento:** nome banca, B29, elenco conti con B53/B54 e B55 se diversi (dialogo con B56), B27, pulsanti B28, B32, B33 (rosso come «Esci dall'account»).
8. **Scollega:** dialogo B34/B35, interruttore B36 (spento di default), pulsante B33 distruttivo.
9. **Da confermare:** titolo B45; elementi `duplicate` (movimento banca in alto, candidati sotto, B46, pulsanti B47/B48/B49), `transfer` (B50, B51/B48),
   sezione `pending` con titolo B52 (sola lettura).

### 7.3 Stati (ogni stato ha una schermata o una riga; nessun dialogo bloccante)
| Stato | Dove si vede | Testo |
|---|---|---|
| nessuna banca | schermata 1 | B02, B04… |
| in collegamento | schermata 4 | B15 |
| riuscito | schermata 6 | B25, B26 |
| consenso in scadenza (≤ 7 giorni) | dettaglio + sottotitolo della riga Impostazioni in `DS.plannedText` | B30 |
| consenso scaduto / `expired` | idem | B31 + B32 |
| errore banca `bank_unavailable`/`provider_error` | dettaglio, riga sotto il nome | B37 |
| annullato dall'utente (`error=access_denied`) | schermata 1 | B38 |
| offline | qualsiasi azione di rete | B39 |
| banca non trovata | schermata 2 | B11 |
| tipo di conto non leggibile / `not_supported` | schermata 5 | B59 |
| limite raggiunto | schermata 1 | B41 |
| servizio spento lato server | schermata 1 | B42 |
| revocato dalla banca (`revoked`) | dettaglio | B31 (stesso trattamento: rinnovare) |
| Protezione avanzata bloccata | riga Impostazioni | B43 |

### 7.4 Testi (chiavi `bank_*` identiche su iOS e Android, come `e2e_*` di S-50; in iOS anche in `it.lproj`)
Segnaposto: iOS `%@`/`%d`, Android `%1$s`/`%1$d`; apostrofi Android `\'`. Tono: tedesco «du», francese «vous».

| # | chiave | it |
|---|---|---|
| B01 | bank_titolo | Conti collegati |
| B02 | bank_nessuna | Nessuna banca collegata |
| B03 | bank_n_banche | Banche collegate: %d |
| B04 | bank_intro | Collega la tua banca per importare saldo e movimenti in automatico. È facoltativo, conto per conto: i conti che gestisci a mano restano come sono. |
| B05 | bank_cosa_leggiamo | Bucktrail legge solo saldi e movimenti dei conti che scegli. Non può fare pagamenti né spostare denaro. |
| B06 | bank_durata | L'accesso dura fino a 180 giorni, poi la banca ti chiede di rinnovarlo. Puoi scollegare quando vuoi. |
| B07 | bank_fornitore | Il collegamento passa da Enable Banking, istituto autorizzato ai servizi di informazione sui conti. I movimenti transitano dal nostro server senza essere salvati lì. |
| B08 | bank_collega | Collega una banca |
| B09 | bank_scegli_banca | Scegli la tua banca |
| B10 | bank_cerca | Cerca la banca |
| B11 | bank_non_trovi | Non trovi la tua banca? Per ora non è supportata: puoi continuare a gestire quel conto a mano. |
| B12 | bank_consenso_titolo | Prima di continuare |
| B13 | bank_consenso_testo | Ti portiamo sul sito o nell'app di %@ per autorizzare l'accesso. Bucktrail non vede mai le tue credenziali. |
| B14 | bank_continua_banca | Continua sulla banca |
| B15 | bank_in_attesa | Completa l'accesso sul sito o nell'app della banca, poi torna qui. |
| B17 | bank_scegli_conti | Quali conti vuoi importare? |
| B18 | bank_destinazione | Importa in |
| B19 | bank_nuovo_conto | Nuovo conto |
| B20 | bank_da_quando | Da quando |
| B21 | bank_da_oggi | Da oggi |
| B22 | bank_ultimi_90 | Ultimi 90 giorni |
| B23 | bank_valuta_diversa | Valuta diversa da quella dell'app: per ora non si può importare. |
| B24 | bank_fatto | Fatto |
| B25 | bank_riuscito | Banca collegata |
| B26 | bank_importati | Movimenti importati: %d |
| B27 | bank_aggiornato | Aggiornato: %@ |
| B28 | bank_aggiorna | Aggiorna ora |
| B29 | bank_valido_fino | Accesso valido fino al %@ |
| B30 | bank_in_scadenza | L'accesso a %@ scade tra pochi giorni. Rinnovalo per continuare a importare. |
| B31 | bank_scaduto | L'accesso a %@ è scaduto. Rinnovalo per riprendere l'importazione. |
| B32 | bank_rinnova | Rinnova accesso |
| B33 | bank_scollega | Scollega |
| B34 | bank_scollega_titolo | Scollegare %@? |
| B35 | bank_scollega_testo | Bucktrail smetterà di leggere questi conti e chiederà alla banca di chiudere l'accesso. I movimenti già importati restano, a meno che tu non scelga di eliminarli. |
| B36 | bank_elimina_importati | Elimina anche i movimenti importati (%d) |
| B37 | bank_errore | La banca non risponde in questo momento. Riprova più tardi. |
| B38 | bank_annullato | Collegamento annullato. Nessun dato è stato letto. |
| B39 | bank_offline | Serve una connessione a Internet. |
| B40 | bank_serve_account | Per collegare una banca serve un account Bucktrail. |
| B41 | bank_limite | Hai raggiunto il numero massimo di banche collegabili. |
| B42 | bank_non_disponibile | Il collegamento di nuove banche non è disponibile ora. Riprova più tardi. |
| B43 | bank_bloccato_e2e | Sblocca la sincronizzazione per aggiornare i conti collegati. |
| B44 | bank_da_confermare | Da confermare: %d |
| B45 | bank_inbox_titolo | Movimenti da confermare |
| B46 | bank_doppione_domanda | È lo stesso movimento che hai inserito a mano? |
| B47 | bank_stesso | Sì, è lo stesso |
| B48 | bank_nuovo | No, è nuovo |
| B49 | bank_ignora | Ignora |
| B50 | bank_giroconto_domanda | È un giroconto tra i tuoi conti? |
| B51 | bank_giroconto_si | Sì, è un giroconto |
| B52 | bank_in_attesa_banca | In attesa dalla banca |
| B53 | bank_saldo_banca | Saldo in banca |
| B54 | bank_saldo_app | Saldo in Bucktrail |
| B55 | bank_allinea | Allinea il saldo |
| B56 | bank_allinea_testo | Aggiunge una rettifica di %@ per far coincidere il saldo con quello della banca. |
| B57 | bank_importato_da | Importato da %@ |
| B58 | bank_collegato | Collegato |
| B59 | bank_tipo_non_supportato | Questa banca non permette di leggere questo tipo di conto. |
| B60 | bank_movimento_banca | Movimento bancario |
| B61 | bank_motivo_biometria | Conferma la tua identità per scollegare la banca |

(B16 non esiste: «Annulla» usa la chiave esistente.)

**en**
B01 Linked accounts · B02 No bank linked · B03 Linked banks: %d ·
B04 Link your bank to import your balance and transactions automatically. It's optional, account by account: the accounts you manage by hand stay as they are. ·
B05 Bucktrail only reads balances and transactions of the accounts you choose. It can't make payments or move money. ·
B06 Access lasts up to 180 days, then your bank asks you to renew it. You can unlink at any time. ·
B07 The link goes through Enable Banking, an institution authorised to provide account information services. Transactions pass through our server without being stored there. ·
B08 Link a bank · B09 Choose your bank · B10 Search for your bank ·
B11 Can't find your bank? It isn't supported yet: you can keep managing that account by hand. ·
B12 Before you continue · B13 We'll take you to the %@ website or app to authorise access. Bucktrail never sees your credentials. ·
B14 Continue to your bank · B15 Finish signing in on your bank's website or app, then come back here. ·
B17 Which accounts do you want to import? · B18 Import into · B19 New account · B20 Starting from · B21 Today · B22 Last 90 days ·
B23 Different currency from the app's: it can't be imported yet. · B24 Done · B25 Bank linked · B26 Transactions imported: %d ·
B27 Updated: %@ · B28 Update now · B29 Access valid until %@ ·
B30 Access to %@ expires in a few days. Renew it to keep importing. · B31 Access to %@ has expired. Renew it to resume importing. ·
B32 Renew access · B33 Unlink · B34 Unlink %@? ·
B35 Bucktrail will stop reading these accounts and ask your bank to close access. Transactions already imported stay, unless you choose to delete them. ·
B36 Also delete imported transactions (%d) · B37 The bank isn't responding right now. Please try again later. ·
B38 Linking cancelled. No data was read. · B39 An internet connection is required. · B40 You need a Bucktrail account to link a bank. ·
B41 You've reached the maximum number of banks you can link. · B42 Linking new banks isn't available right now. Please try again later. ·
B43 Unlock sync to update your linked accounts. · B44 To review: %d · B45 Transactions to review ·
B46 Is this the same transaction you entered by hand? · B47 Yes, it's the same · B48 No, it's new · B49 Ignore ·
B50 Is this a transfer between your accounts? · B51 Yes, it's a transfer · B52 Pending at the bank · B53 Bank balance ·
B54 Bucktrail balance · B55 Match balance · B56 Adds an adjustment of %@ so the balance matches your bank's. · B57 Imported from %@ ·
B58 Linked · B59 This bank doesn't allow reading this type of account. · B60 Bank transaction · B61 Confirm your identity to unlink the bank

**de**
B01 Verknüpfte Konten · B02 Keine Bank verknüpft · B03 Verknüpfte Banken: %d ·
B04 Verknüpfe deine Bank, um Kontostand und Umsätze automatisch zu importieren. Das ist freiwillig, Konto für Konto: Konten, die du von Hand führst, bleiben, wie sie sind. ·
B05 Bucktrail liest nur Kontostände und Umsätze der Konten, die du auswählst. Es kann keine Zahlungen ausführen und kein Geld bewegen. ·
B06 Der Zugriff gilt bis zu 180 Tage, danach bittet dich deine Bank, ihn zu erneuern. Du kannst die Verknüpfung jederzeit trennen. ·
B07 Die Verknüpfung läuft über Enable Banking, ein für Kontoinformationsdienste zugelassenes Institut. Die Umsätze laufen durch unseren Server, ohne dort gespeichert zu werden. ·
B08 Bank verknüpfen · B09 Wähle deine Bank · B10 Bank suchen ·
B11 Deine Bank ist nicht dabei? Sie wird noch nicht unterstützt: Du kannst dieses Konto weiter von Hand führen. ·
B12 Bevor du fortfährst · B13 Wir leiten dich zur Website oder App von %@ weiter, um den Zugriff zu erlauben. Bucktrail sieht deine Zugangsdaten nie. ·
B14 Weiter zur Bank · B15 Schließe die Anmeldung auf der Website oder in der App deiner Bank ab und kehre dann hierher zurück. ·
B17 Welche Konten möchtest du importieren? · B18 Importieren in · B19 Neues Konto · B20 Ab wann · B21 Ab heute · B22 Letzte 90 Tage ·
B23 Andere Währung als in der App: kann noch nicht importiert werden. · B24 Fertig · B25 Bank verknüpft · B26 Importierte Umsätze: %d ·
B27 Aktualisiert: %@ · B28 Jetzt aktualisieren · B29 Zugriff gültig bis %@ ·
B30 Der Zugriff auf %@ läuft in wenigen Tagen ab. Erneuere ihn, um weiter zu importieren. · B31 Der Zugriff auf %@ ist abgelaufen. Erneuere ihn, um den Import fortzusetzen. ·
B32 Zugriff erneuern · B33 Trennen · B34 %@ trennen? ·
B35 Bucktrail liest diese Konten nicht mehr und bittet deine Bank, den Zugriff zu schließen. Bereits importierte Umsätze bleiben erhalten, außer du entscheidest dich, sie zu löschen. ·
B36 Auch importierte Umsätze löschen (%d) · B37 Die Bank antwortet gerade nicht. Versuche es später erneut. ·
B38 Verknüpfung abgebrochen. Es wurden keine Daten gelesen. · B39 Eine Internetverbindung ist erforderlich. · B40 Um eine Bank zu verknüpfen, brauchst du ein Bucktrail-Konto. ·
B41 Du hast die maximale Anzahl verknüpfbarer Banken erreicht. · B42 Neue Banken können gerade nicht verknüpft werden. Versuche es später erneut. ·
B43 Entsperre die Synchronisierung, um deine verknüpften Konten zu aktualisieren. · B44 Zu bestätigen: %d · B45 Umsätze bestätigen ·
B46 Ist das derselbe Umsatz, den du von Hand eingetragen hast? · B47 Ja, derselbe · B48 Nein, neu · B49 Ignorieren ·
B50 Ist das eine Umbuchung zwischen deinen Konten? · B51 Ja, eine Umbuchung · B52 Bei der Bank vorgemerkt · B53 Kontostand bei der Bank ·
B54 Kontostand in Bucktrail · B55 Kontostand abgleichen · B56 Fügt eine Korrektur von %@ hinzu, damit der Kontostand mit dem der Bank übereinstimmt. · B57 Importiert von %@ ·
B58 Verknüpft · B59 Diese Bank erlaubt nicht, diese Kontoart zu lesen. · B60 Bankumsatz · B61 Bestätige deine Identität, um die Bank zu trennen

**es**
B01 Cuentas vinculadas · B02 Ningún banco vinculado · B03 Bancos vinculados: %d ·
B04 Vincula tu banco para importar el saldo y los movimientos automáticamente. Es opcional, cuenta por cuenta: las cuentas que gestionas a mano se quedan como están. ·
B05 Bucktrail solo lee saldos y movimientos de las cuentas que elijas. No puede hacer pagos ni mover dinero. ·
B06 El acceso dura hasta 180 días; después tu banco te pedirá renovarlo. Puedes desvincularlo cuando quieras. ·
B07 La conexión pasa por Enable Banking, entidad autorizada para servicios de información sobre cuentas. Los movimientos pasan por nuestro servidor sin guardarse en él. ·
B08 Vincular un banco · B09 Elige tu banco · B10 Buscar banco ·
B11 ¿No encuentras tu banco? Todavía no es compatible: puedes seguir gestionando esa cuenta a mano. ·
B12 Antes de continuar · B13 Te llevaremos a la web o la app de %@ para autorizar el acceso. Bucktrail nunca ve tus credenciales. ·
B14 Continuar en el banco · B15 Completa el acceso en la web o la app del banco y luego vuelve aquí. ·
B17 ¿Qué cuentas quieres importar? · B18 Importar en · B19 Cuenta nueva · B20 Desde cuándo · B21 Desde hoy · B22 Últimos 90 días ·
B23 Moneda distinta de la de la app: todavía no se puede importar. · B24 Hecho · B25 Banco vinculado · B26 Movimientos importados: %d ·
B27 Actualizado: %@ · B28 Actualizar ahora · B29 Acceso válido hasta el %@ ·
B30 El acceso a %@ caduca en pocos días. Renuévalo para seguir importando. · B31 El acceso a %@ ha caducado. Renuévalo para reanudar la importación. ·
B32 Renovar acceso · B33 Desvincular · B34 ¿Desvincular %@? ·
B35 Bucktrail dejará de leer estas cuentas y pedirá al banco que cierre el acceso. Los movimientos ya importados se quedan, salvo que elijas eliminarlos. ·
B36 Eliminar también los movimientos importados (%d) · B37 El banco no responde en este momento. Inténtalo más tarde. ·
B38 Vinculación cancelada. No se ha leído ningún dato. · B39 Se necesita conexión a internet. · B40 Para vincular un banco necesitas una cuenta de Bucktrail. ·
B41 Has alcanzado el número máximo de bancos que puedes vincular. · B42 Ahora no se pueden vincular bancos nuevos. Inténtalo más tarde. ·
B43 Desbloquea la sincronización para actualizar las cuentas vinculadas. · B44 Por confirmar: %d · B45 Movimientos por confirmar ·
B46 ¿Es el mismo movimiento que introdujiste a mano? · B47 Sí, es el mismo · B48 No, es nuevo · B49 Ignorar ·
B50 ¿Es una transferencia entre tus cuentas? · B51 Sí, es una transferencia · B52 Pendientes en el banco · B53 Saldo en el banco ·
B54 Saldo en Bucktrail · B55 Ajustar el saldo · B56 Añade un ajuste de %@ para que el saldo coincida con el del banco. · B57 Importado de %@ ·
B58 Vinculada · B59 Este banco no permite leer este tipo de cuenta. · B60 Movimiento bancario · B61 Confirma tu identidad para desvincular el banco

**fr**
B01 Comptes liés · B02 Aucune banque liée · B03 Banques liées : %d ·
B04 Liez votre banque pour importer automatiquement le solde et les opérations. C'est facultatif, compte par compte : les comptes que vous gérez à la main restent tels quels. ·
B05 Bucktrail lit uniquement les soldes et les opérations des comptes que vous choisissez. Il ne peut ni effectuer de paiements ni déplacer d'argent. ·
B06 L'accès dure jusqu'à 180 jours, puis votre banque vous demande de le renouveler. Vous pouvez délier à tout moment. ·
B07 La liaison passe par Enable Banking, établissement agréé pour les services d'information sur les comptes. Les opérations transitent par notre serveur sans y être enregistrées. ·
B08 Lier une banque · B09 Choisissez votre banque · B10 Rechercher une banque ·
B11 Vous ne trouvez pas votre banque ? Elle n'est pas encore prise en charge : vous pouvez continuer à gérer ce compte à la main. ·
B12 Avant de continuer · B13 Nous vous redirigeons vers le site ou l'app de %@ pour autoriser l'accès. Bucktrail ne voit jamais vos identifiants. ·
B14 Continuer vers la banque · B15 Terminez la connexion sur le site ou l'app de votre banque, puis revenez ici. ·
B17 Quels comptes voulez-vous importer ? · B18 Importer dans · B19 Nouveau compte · B20 À partir de · B21 Aujourd'hui · B22 90 derniers jours ·
B23 Devise différente de celle de l'app : import pas encore possible. · B24 Terminé · B25 Banque liée · B26 Opérations importées : %d ·
B27 Mis à jour : %@ · B28 Mettre à jour · B29 Accès valable jusqu'au %@ ·
B30 L'accès à %@ expire dans quelques jours. Renouvelez-le pour continuer l'import. · B31 L'accès à %@ a expiré. Renouvelez-le pour reprendre l'import. ·
B32 Renouveler l'accès · B33 Délier · B34 Délier %@ ? ·
B35 Bucktrail cessera de lire ces comptes et demandera à votre banque de fermer l'accès. Les opérations déjà importées sont conservées, sauf si vous choisissez de les supprimer. ·
B36 Supprimer aussi les opérations importées (%d) · B37 La banque ne répond pas pour le moment. Réessayez plus tard. ·
B38 Liaison annulée. Aucune donnée n'a été lue. · B39 Une connexion Internet est nécessaire. · B40 Pour lier une banque, il faut un compte Bucktrail. ·
B41 Vous avez atteint le nombre maximal de banques liées. · B42 La liaison de nouvelles banques n'est pas disponible pour le moment. Réessayez plus tard. ·
B43 Déverrouillez la synchronisation pour mettre à jour les comptes liés. · B44 À confirmer : %d · B45 Opérations à confirmer ·
B46 Est-ce la même opération que vous avez saisie à la main ? · B47 Oui, c'est la même · B48 Non, elle est nouvelle · B49 Ignorer ·
B50 Est-ce un virement entre vos comptes ? · B51 Oui, c'est un virement · B52 En attente à la banque · B53 Solde à la banque ·
B54 Solde dans Bucktrail · B55 Aligner le solde · B56 Ajoute un ajustement de %@ pour que le solde corresponde à celui de la banque. · B57 Importé de %@ ·
B58 Lié · B59 Cette banque ne permet pas de lire ce type de compte. · B60 Opération bancaire · B61 Confirmez votre identité pour délier la banque

**ja**
B01 連携口座 · B02 連携している銀行はありません · B03 連携銀行：%d ·
B04 銀行を連携すると、残高と取引を自動で取り込めます。口座ごとに選べる任意の機能で、手動で管理している口座はそのままです。 ·
B05 Bucktrailが読み取るのは、選んだ口座の残高と取引だけです。支払いや送金はできません。 ·
B06 アクセスの有効期間は最長180日で、その後は銀行から更新を求められます。連携はいつでも解除できます。 ·
B07 連携にはEnable Banking（口座情報サービスの認可機関）を使います。取引データは当社のサーバーを通過しますが、保存されません。 ·
B08 銀行を連携 · B09 銀行を選択 · B10 銀行を検索 ·
B11 銀行が見つかりませんか？まだ対応していません。その口座は引き続き手動で管理できます。 ·
B12 続ける前に · B13 アクセスを許可するため、%@ のサイトまたはアプリに移動します。Bucktrailがあなたのログイン情報を見ることはありません。 ·
B14 銀行で続ける · B15 銀行のサイトまたはアプリでログインを完了してから、ここに戻ってください。 ·
B17 取り込む口座を選んでください · B18 取り込み先 · B19 新しい口座 · B20 取り込み開始日 · B21 今日から · B22 過去90日 ·
B23 アプリの通貨と異なるため、まだ取り込めません。 · B24 完了 · B25 銀行を連携しました · B26 取り込んだ取引：%d ·
B27 更新：%@ · B28 今すぐ更新 · B29 アクセス有効期限：%@ ·
B30 %@ へのアクセスはまもなく期限切れになります。取り込みを続けるには更新してください。 · B31 %@ へのアクセスは期限切れです。取り込みを再開するには更新してください。 ·
B32 アクセスを更新 · B33 連携を解除 · B34 %@ の連携を解除しますか？ ·
B35 Bucktrailはこれらの口座の読み取りを停止し、銀行にアクセスの終了を依頼します。取り込み済みの取引は、削除を選ばない限り残ります。 ·
B36 取り込んだ取引も削除する（%d） · B37 現在、銀行が応答していません。しばらくしてからもう一度お試しください。 ·
B38 連携をキャンセルしました。データは読み取られていません。 · B39 インターネット接続が必要です。 · B40 銀行を連携するにはBucktrailアカウントが必要です。 ·
B41 連携できる銀行の上限に達しました。 · B42 現在、新しい銀行は連携できません。しばらくしてからもう一度お試しください。 ·
B43 連携口座を更新するには同期のロックを解除してください。 · B44 確認待ち：%d · B45 確認が必要な取引 ·
B46 手動で入力した取引と同じですか？ · B47 はい、同じです · B48 いいえ、新しい取引です · B49 無視 ·
B50 自分の口座間の振替ですか？ · B51 はい、振替です · B52 銀行で処理中 · B53 銀行の残高 ·
B54 Bucktrailの残高 · B55 残高を合わせる · B56 残高を銀行と一致させるため、%@ の調整を追加します。 · B57 %@ から取り込み ·
B58 連携済み · B59 この銀行では、この種類の口座は読み取れません。 · B60 銀行取引 · B61 銀行の連携を解除するには本人確認をしてください

**zh-Hans**
B01 关联账户 · B02 未关联银行 · B03 已关联银行：%d ·
B04 关联你的银行，即可自动导入余额和交易。此功能为可选，可按账户选择：你手动管理的账户保持不变。 ·
B05 Bucktrail 只读取你所选账户的余额和交易，无法付款或转移资金。 ·
B06 访问权限最长 180 天，之后银行会要求你续期。你可以随时解除关联。 ·
B07 关联通过 Enable Banking（获准提供账户信息服务的机构）进行。交易数据会经过我们的服务器，但不会保存在那里。 ·
B08 关联银行 · B09 选择你的银行 · B10 搜索银行 ·
B11 找不到你的银行？目前尚不支持：你可以继续手动管理该账户。 ·
B12 继续之前 · B13 我们将带你前往 %@ 的网站或应用以授权访问。Bucktrail 永远看不到你的登录凭据。 ·
B14 前往银行继续 · B15 请在银行网站或应用中完成登录，然后返回此处。 ·
B17 你想导入哪些账户？ · B18 导入到 · B19 新账户 · B20 起始时间 · B21 从今天起 · B22 最近 90 天 ·
B23 币种与应用不同：暂时无法导入。 · B24 完成 · B25 银行已关联 · B26 已导入交易：%d ·
B27 已更新：%@ · B28 立即更新 · B29 访问有效期至 %@ ·
B30 对 %@ 的访问将在几天后到期。请续期以继续导入。 · B31 对 %@ 的访问已到期。请续期以恢复导入。 ·
B32 续期访问 · B33 解除关联 · B34 解除与 %@ 的关联？ ·
B35 Bucktrail 将停止读取这些账户，并请求银行关闭访问。已导入的交易会保留，除非你选择删除。 ·
B36 同时删除已导入的交易（%d） · B37 银行目前无响应，请稍后再试。 ·
B38 已取消关联，未读取任何数据。 · B39 需要互联网连接。 · B40 关联银行需要 Bucktrail 账户。 ·
B41 你已达到可关联银行的数量上限。 · B42 目前无法关联新银行，请稍后再试。 ·
B43 请解锁同步以更新关联账户。 · B44 待确认：%d · B45 待确认的交易 ·
B46 这是你手动输入的同一笔交易吗？ · B47 是的，是同一笔 · B48 不，是新交易 · B49 忽略 ·
B50 这是你自己账户之间的转账吗？ · B51 是的，是转账 · B52 银行处理中 · B53 银行余额 ·
B54 Bucktrail 余额 · B55 校准余额 · B56 添加一笔 %@ 的调整，使余额与银行一致。 · B57 从 %@ 导入 ·
B58 已关联 · B59 该银行不允许读取此类账户。 · B60 银行交易 · B61 请验证身份以解除银行关联

### 7.5 Verifica visiva senza l'ok di Matteo (libertà data da Matteo)
D-014 chiederebbe l'approvazione delle schermate: Matteo ha dato libertà per questo progetto, quindi l'approvazione è sostituita da: (1) test UI che
attraversano tutti gli stati del §7.3 con un fornitore finto (argomento DEBUG `-BankUITestHarness YES`, che inietta un `BankAPI` in memoria);
(2) **screenshot** di ogni schermata in chiaro e scuro, it/en/de (de = testi più lunghi) e una a corpo XXXL, salvati in `/tmp/bank-ios/` e
`/tmp/bank-android/` con `xcrun simctl io booted screenshot` / `adb exec-out screencap -p`; (3) controllo a vista del collaudatore contro le schermate
Sentiero vicine (Impostazioni, Conti, Movimenti), con attenzione a bordi e badge ingranditi (memoria «occhio ai dettagli»). Matteo li vede solo se vuole.

---

## 8. Sicurezza e privacy

### 8.1 Modello di minaccia
| Minaccia | Contromisura |
|---|---|
| Furto della chiave privata del fornitore dall'app | non c'è: sta solo nei segreti Supabase |
| Un utente legge i conti di un altro (BOLA, OWASP API1) | sigilli AES-GCM con AAD = `user_id`; controllo `bank_links` per stato; JWT verificato con `GET /auth/v1/user` a ogni chiamata |
| Intercettazione del ritorno (`bucktrail://`) | `state` monouso legato all'utente + `verifier` tipo PKCE che non lascia il telefono |
| Furto del `code` dalla pagina di ritorno (referrer, analytics, cronologia) | `no-referrer`, nessun analytics su `/banca/*`, `history.replaceState` immediato, `code` inutile senza `verifier` |
| Dump del database Supabase | nessun dato bancario nelle tabelle del server; sigilli inutili senza `BANK_SERVER_SECRET`; con E2E tutto cifrato |
| Abuso di costi (molti collegamenti) | `connect_enabled`, `max_links_per_user = 2`, `max_active_links`, `bank_hit` (300 chiamate e 10 avvii al giorno) |
| Limiti della banca (4 letture non presidiate/giorno) | 6 h tra aggiornamenti automatici per collegamento; «Aggiorna ora» = presidiato |
| Iniezione / SSRF | URL del fornitore costante; nessuna SQL composta a mano (solo PostgREST e `bank_hit` con parametri); validazione rigorosa di ogni campo |
| Dati sensibili nei log | registro minimo del §3.7 + test che lo verifica |
| Dispositivo perso | protezioni esistenti (file `.complete`, area privata, blocco biometrico); l'utente scollega da un altro dispositivo (il consenso si chiude dal fornitore) |
| Consenso dimenticato | scade da solo (≤ 180 giorni) |

### 8.2 Cosa si conserva e per quanto
| Dato | Dove | Durata |
|---|---|---|
| Movimenti importati | `Transaction` sul telefono (+ sync) | finché l'utente non li cancella (sono suoi dati come quelli manuali) |
| `BankDecision` | telefono (+ sync) | ~35 giorni dietro il cursore |
| `BankInboxItem` | solo telefono | fino alla decisione / al prossimo aggiornamento |
| `BankConnection`, `BankAccountLink` | telefono (+ sync) | fino allo scollegamento |
| `bank_links` | server | fino allo scollegamento o all'eliminazione dell'account (cascade) |
| `bank_auth_states` | server | 15 minuti (pulizia entro 1 giorno) |
| `bank_usage` | server | 7 giorni |
| Movimenti in transito | memoria della funzione | durata della richiesta |

### 8.3 Cancellazione
- **Scollega** = `disconnect` (sessione chiusa presso il fornitore + `bank_links` cancellata) + cancellazione locale (e quindi remota alla sync) di
  `BankConnection`, dei suoi `BankAccountLink`, `BankDecision` e `BankInboxItem`. **I movimenti importati restano** (scelta motivata: sono ormai la
  contabilità dell'utente, toglierli cambierebbe saldi e statistiche senza che lo chieda); l'interruttore B36 li elimina tutti (ID v5 di quei conti),
  con autenticazione del dispositivo (B61).
- **Eliminazione dell'account:** prima `disconnect` di ogni collegamento (al meglio), poi la RPC `delete_own_account` esistente; `on delete cascade`
  pulisce `mt_bank_*`, `bank_links`, `bank_usage`, `bank_auth_states`. Se un `disconnect` fallisce, il consenso scade da solo.
- **Logout:** come per S-50, i dati locali si cancellano (percorso esistente `clearLocalData`), incluse le entità bancarie e lo stato in attesa.

### 8.4 Testi per il sito (da inserire in S-60v; l'approvazione dei testi del sito resta di Matteo, AGENTS §6.6)
**`SOCIAL/landing/privacy.html` — nuovo paragrafo in «Dati raccolti, finalità e base giuridica» (it):**
«Collegamento bancario (facoltativo). Se colleghi una banca, Bucktrail legge saldi e movimenti dei conti che scegli tramite Enable Banking Oy
(Finlandia), istituto autorizzato ai servizi di informazione sui conti, con il consenso che dai direttamente alla tua banca, per un massimo di
180 giorni e revocabile in ogni momento. Base giuridica: esecuzione del servizio che richiedi. I movimenti passano dal nostro server (Supabase)
solo per essere consegnati alla tua app e non vengono salvati lì; il server conserva soltanto informazioni tecniche sul collegamento (un
identificativo cifrato, la scadenza, contatori di utilizzo). Saldi e movimenti importati restano sul tuo telefono e, se usi la sincronizzazione,
nel tuo spazio cloud come gli altri dati; con la Protezione avanzata sono cifrati con una chiave solo tua. Non leggiamo le tue credenziali
bancarie e non possiamo disporre pagamenti. Scollegando la banca chiudiamo l'accesso e cancelliamo le informazioni del collegamento; i movimenti
già importati restano finché non li elimini.»
In «Destinatari e trasferimenti»: aggiungere «Enable Banking Oy (Finlandia), per il collegamento bancario facoltativo».
**en:** «Bank connection (optional). If you link a bank, Bucktrail reads the balances and transactions of the accounts you choose through Enable
Banking Oy (Finland), an institution authorised to provide account information services, with the consent you give directly to your bank, for up
to 180 days and revocable at any time. Legal basis: performance of the service you request. Transactions pass through our server (Supabase) only
to be delivered to your app and are not stored there; the server keeps only technical information about the connection (an encrypted identifier,
the expiry date, usage counters). Imported balances and transactions stay on your phone and, if you use sync, in your cloud space like your other
data; with Advanced Protection they are encrypted with a key only you hold. We never read your bank credentials and cannot make payments. When you
unlink the bank we close access and delete the connection information; transactions already imported stay until you delete them.»
**FAQ** `index.html`/`en.html`: sostituire la risposta di «Devo collegare il mio conto bancario?» con: it «No. Puoi gestire tutti i conti a mano.
Il collegamento bancario è facoltativo, conto per conto: legge solo saldi e movimenti, non può fare pagamenti, e lo scolleghi quando vuoi.» /
en «No. You can manage every account by hand. Bank linking is optional, account by account: it only reads balances and transactions, can't make
payments, and you can unlink it whenever you want.» Aggiornare la sezione `#in-arrivo` togliendo «in arrivo» **solo** all'accensione.
**Cosa NON promettere sul sito:** «nessuno può vedere i tuoi movimenti» (la funzione e il fornitore li vedono in transito); «tutte le banche» (solo
quelle supportate); «in tempo reale» (al massimo ogni 6 ore in automatico); «gratis per sempre» finché il modello di costo non è deciso (§12.2);
nomi di banche specifiche non verificate in produzione; «certificato/approvato da Banca d'Italia».

### 8.5 Store
- **App Store — Privacy nutrition label** (App Store Connect → App Privacy): «Financial Info» → «Other Financial Info» (saldi e movimenti) — raccolta
  solo se l'utente usa sync o collegamento; scopo **App Functionality**; **collegato all'identità** (account); **non usato per tracciamento**.
  Se la sync è già dichiarata con «Financial Info», aggiungere solo che i dati provengono anche dal collegamento bancario (nessuna nuova categoria).
- **Google Play — Data safety:** «Financial info» → «Other financial info»: raccolto, **non condiviso** (Enable Banking e Supabase sono fornitori di
  servizi), cifrato in transito, l'utente può chiederne la cancellazione, facoltativo. [DA VERIFICARE nella console] se la consegna in transito dalla
  funzione si possa indicare come «elaborazione temporanea». Play Console → «Funzionalità finanziarie»: dichiarare un'app di gestione delle finanze
  personali con aggregazione dei conti (lettura) [DA VERIFICARE la voce esatta].
- **App Review:** nelle note di revisione spiegare che il servizio regolato è fornito da Enable Banking (AISP autorizzato) e allegare un video del
  flusso (il revisore non può collegare una banca vera); l'interruttore compilato acceso = funzione visibile alla revisione (Linea guida 2.3.1:
  niente funzioni nascoste attivate dopo). L'interruttore server serve **solo a spegnere**, mai ad accendere qualcosa non visto dalla revisione.

---

## 9. Legale e commerciale

Ruoli: Matteo è **titolare del trattamento** dei dati dell'app; Supabase è responsabile (DPA già da verificare per la sync); Enable Banking è il
prestatore del servizio di informazione sui conti verso l'utente (l'utente accetta i suoi termini nel flusso) e consegna i dati all'app.

| # | Punto | Stato | Cosa chiedere esattamente |
|---|---|---|---|
| L1 | **Linea guida App Store 5.1.1(ix)**: le app che offrono servizi in campi fortemente regolati («banking and financial services») o che richiedono informazioni sensibili «should be submitted by a legal entity… and not by an individual developer»; 3.2.1(viii) «money management» ([linee guida](https://developer.apple.com/app-store/review/guidelines/)). Apple: ditte individuali si iscrivono come **individuali** ([Apple](https://developer.apple.com/help/account/membership/program-enrollment/)) | **[DA VERIFICARE]** — rischio n. 1 del progetto | Matteo: che tipo di account Developer ha (Individual / Organization). Se Individual: chiedere ad Apple (App Review → Contact Us, prima dell'invio) se un'app di finanza personale che legge i conti **tramite un AISP autorizzato terzo** può essere pubblicata da un account individuale; in alternativa valutare una società (srl semplificata) come titolare dell'account |
| L2 | Serve una registrazione presso Banca d'Italia (AISP o agente) se si usa la licenza di Enable Banking? | **[DA VERIFICARE con un professionista]** (avvocato/consulente fintech) | «Un'app di finanza personale di una persona fisica [o ditta individuale] riceve saldi e movimenti tramite Enable Banking Oy, AISP registrato FIN-FSA operante in Italia in libera prestazione; l'utente presta il consenso a Enable Banking nel suo flusso. L'editore dell'app deve iscriversi come AISP, come agente o in altri elenchi (OAM/Banca d'Italia)? Quali obblighi informativi e contrattuali verso l'utente?» |
| L3 | Enable Banking richiede contratto e **KYB «for your company»** per la produzione ([FAQ](https://enablebanking.com/docs/faq)) | **[DA VERIFICARE con Enable Banking]** | «Accettate come cliente una persona fisica / ditta individuale italiana? Qual è la fattura minima mensile e il prezzo per conto collegato? Ruolo GDPR (titolare autonomo o responsabile) e DPA disponibile? Dove sono trattati i dati? L'API permette di elencare le sessioni dell'applicazione?» |
| L4 | GDPR | da fare da Matteo con il professionista | registro dei trattamenti: nuova voce «collegamento bancario facoltativo» (finalità, base giuridica contratto, categorie: dati finanziari, destinatari: Enable Banking, Supabase; conservazione §8.2); valutazione se serve una DPIA (dati finanziari, scala piccola: probabilmente non obbligatoria, **[DA VERIFICARE]**); DPA con Supabase e con Enable Banking se responsabile |
| L5 | Regione del progetto Supabase (dove passano i dati in transito) | **[DA VERIFICARE]** in S-60r (Supabase → Project Settings → General → Region) | — |
| L6 | Partita IVA / fatturazione verso il fornitore | **[DA VERIFICARE]** | se serve una partita IVA per contratto e fatture del fornitore |

Nessuna di queste domande blocca il lavoro di Claude: bloccano **solo l'accensione** (S-60v). Se L1 o L3 hanno esito negativo, il codice resta
dietro l'interruttore spento (nessun danno) e si decide con Matteo.

---

## 10. Piano di prova

### 10.1 Principi
Tutto automatico e **senza banche vere né Supabase vero** fino a S-60r. Ogni regola di dominio ha vettori condivisi, verificati da **tre**
implementazioni indipendenti (Python libreria standard, Swift, Kotlin), come in S-50.

### 10.2 Strumenti
- **Vettori condivisi** `MoneyTrackerTests/Fixtures/bank-vectors-v1.json` (Android li legge con `systemProperty("bankVectors", …)` come i vettori E2E),
  generati e verificati da `03_CODICE/bucktrail-android/scripts/bank-vectors.py --check`. Gruppi:
  1. `uuid5`: 6 casi (`accountRef`, `txKey`) → UUID atteso, versione 5; un caso con caratteri non ASCII.
  2. `amount`: stringhe valide/invalide → decimale atteso o errore (`"-12.50"`, `"0.005"`→`0.01` HALF_UP, `"1e3"` invalida, `"12,50"` invalida, `"-0.00"`→`0`, 12 cifre intere, 13 cifre invalida).
  3. `txkey`: input normalizzati → `tx_key` atteso (e:/t:/h:), canonico dell'importo, suffissi `#2/#3` per duplicati.
  4. `clean`: 30 descrizioni reali tipo italiane → nome atteso (POS, SDD, bonifici, Amazon, carburante, pedaggi, stipendio, PayPal, Satispay, estero).
  5. `category`: (nome, descrizione, mcc, storico, categorie disponibili) → categoria attesa (ordine §5).
  6. `match`: scenari con movimenti manuali e bancari → piano atteso (`import`/`inbox duplicate` con candidati ordinati/`inbox transfer`/`skip …`), incluse
     tutte le soglie ai bordi (−5/+3 giorni, ±7 pianificati, ±3 % solo con `fx`, segno diverso, conto diverso, ID v5 escluso, già deciso).
  7. `opening`: saldo banca + movimenti → `initialBalance` atteso; scelta del tipo di saldo.
  8. `rows`: una riga per ciascuno dei 3 `kind` bancari prodotta da iOS e una da Android (JSON in chiaro) con valori attesi neutri (interop sync/vault).
- **Backend:** `node --test 03_CODICE/bucktrail-backend/tests/` con `fetch` finto (fornitore e Supabase in memoria). Fixture del fornitore in
  `tests/fixtures/eb-*.json` (risposte realistiche scritte a mano secondo la documentazione: `aspsps`, `auth`, `sessions`, `balances`, 3 pagine di
  `transactions` con `continuation_key`, errori `EXPIRED_SESSION`, `ASPSP_RATE_LIMIT_EXCEEDED`, risposta malformata) e `tests/fixtures/normalized-*.json`
  (uscita attesa del contratto v1).
- **Server finto per le app:** `03_CODICE/bucktrail-android/scripts/fake-supabase.py` esteso con `POST /functions/v1/bank/<azione>` che serve le stesse
  `normalized-*.json` (stessa verità del backend) + tabelle `mt_bank_*` (PK `id`, filtro `user_id`, guardia E2E emulata come per S-50). Variabili:
  `FAKE_BANK_SCENARIO=ok|expired|revoked|down|ratelimited|malformed|slow|dupes|fx|transfer`, `FAKE_BANK_FAIL_AFTER=N` (interruzione a metà paginazione).
  Prova: `python3 -I 03_CODICE/bucktrail-android/scripts/test-fake-supabase-bank.py`.
- **iOS:** `BankAPI` dietro protocollo `BankAPIClient`; nei test `InMemoryBankAPI` e `URLProtocol` finto per il client reale. **Android:** `FakeBankApi` nuovo (i fake esistenti non si toccano).

### 10.3 Test
| # | Test | Dove | Cosa dimostra |
|---|---|---|---|
| T1 | Vettori 1–7 | `BankDomainTests` (iOS), `BankDomainVectorsTest` (JVM), `bank-vectors.py --check` | stessa logica sulle 3 implementazioni |
| T2 | Backend: ogni azione, ogni errore §3.4.3, sigilli (utente diverso → 401/404, sigillo alterato, versione `bs2.`), state monouso/scaduto, verifier sbagliato, limiti `bank_hit`, `too_soon`, `connect_enabled=false`, limite collegamenti, input fuori schema, corpo > 16 KiB, metodo GET → 405 | `node --test` | backend corretto e chiuso (OWASP API Top 10) |
| T3 | Registro senza segreti: con valori-sentinella (`SENTINEL-IBAN`, `SENTINEL-SESSION`…) nessuna riga di `console.*` li contiene | `node --test` | log puliti |
| T4 | Normalizzazione: fixture `eb-*` → `normalized-*` identico; movimenti malformati scartati e contati | `node --test` | contratto stabile |
| T5 | Server finto: tutte le rotte e gli scenari | `test-fake-supabase-bank.py` | banco di prova affidabile |
| T6 | Migrazione SwiftData V3→V4 con dati; Room 3→4 con dati (strumentato) | `SchemaV4MigrationTests`, `Migration3To4Test` | nessuna perdita |
| T7 | Importatore: primo import 90 giorni su conto nuovo (saldo iniziale), import «da oggi» su conto esistente (saldo invariato), 3 pagine, doppioni → inbox, giroconto → inbox, pendenti non importati, valuta diversa saltata, rete che cade alla pagina 2 (`FAKE_BANK_FAIL_AFTER`) → nulla di parziale nel cursore, ripetizione identica = zero nuovi movimenti | `BankImporterTests` / `BankImporterTest` | idempotenza e correttezza |
| T8 | Decisioni: stesso/nuovo/ignora/giroconto; movimento importato cancellato non rinasce; modifica dell'utente mai sovrascritta; potatura a 35 giorni | idem | rispetto delle scelte dell'utente |
| T9 | Errori: `expired` → stato scaduto; `revoked`; `bank_unavailable`; `rate_limited` (attesa 6 h); risposta malformata; offline | idem + UI | stati corretti, nessun crash |
| T10 | Interruttore spento: nessuna richiesta a `/functions/v1/bank` né a `mt_bank_*`; Impostazioni identiche (UI test esistenti verdi); sync principale con richieste «d'oro» identiche a S-50 | `BankFlagOffTests` / `BankFlagOffTest` | chi non usa la funzione non vede differenze |
| T11 | Sync: push/pull delle 3 tabelle in chiaro; con vault (kind nuovi, AAD); errore del passo banca non cambia `SyncStatus`; tabelle assenti → nascosto | `BankSyncTests` / `BankSyncTest` | isolamento |
| T12 | E2E: attivazione con dati bancari presenti → migrati e verificati nel vault; disattivazione → tornano in `mt_bank_*`; dispositivo `.locked` → niente aggiornamenti, B43 | estensione dei test del migratore (file nuovi) | coerenza S-50 |
| T13 | Interop: righe `rows` iOS↔Android; stessi `importId` dagli stessi input; due «dispositivi» su remoto in memoria condiviso aggiornano lo stesso collegamento → zero doppioni | `BankInteropTests` / `BankInteropTest` | più dispositivi |
| T14 | Ritorno: URL con `state` sbagliato ignorato; senza stato in attesa ignorato; `error=access_denied` → B38; stato in attesa scaduto (15 min) | unit iOS/Android | sicurezza del ritorno |
| T15 | Chiavi `bank_*` presenti in 7 lingue su entrambe le piattaforme, segnaposto coerenti (`%@`↔`%1$s`, `%d`↔`%1$d`) | `BankLocalizationTests` / `BankStringsTest` | i18n |
| T16 | UI: tutti gli stati del §7.3 con `-BankUITestHarness YES`; screenshot §7.5 | `BankUITests` / test Compose strumentato | flusso utente |
| T17 | Prova d'insieme su emulatore e simulatore col server finto (`-PsupabaseUrl=http://10.0.2.2:54321 -Pbank=true`; iOS con URL finto in DEBUG): collega → scegli conti → importa → doppione confermato → scollega; `curl` sul server finto: nessun IBAN completo, nessun `session_id` | manuale-automatizzabile | flusso reale end-to-end |
| T18 | Suite esistenti: iOS unit + UI, Android JVM + strumentati, test E2E di S-50: tutte verdi e **non modificate** (`git diff --stat` sui file di test esistenti vuoto) | — | non regressione |

### 10.4 Sandbox vera e banca vera (mai senza Matteo)
- **Sandbox Enable Banking (S-60r, guidata):** `node 03_CODICE/bucktrail-backend/scripts/sandbox-smoke.mjs --key ~/.bucktrail/eb-sandbox.pem --app <id>`
  (la chiave sandbox sta FUORI dal repository). Lo script elenca le banche IT, avvia l'autorizzazione su una banca di prova della sandbox, stampa l'URL;
  Matteo lo apre, completa con le credenziali di prova mostrate dalla sandbox e incolla l'URL di ritorno nel terminale; lo script crea la sessione,
  legge conti/saldi/movimenti, salva le risposte grezze (dati finti) in `03_CODICE/bucktrail-backend/tests/fixtures/sandbox-*.json` e chiude la sessione.
- **Banca reale di Matteo (facoltativa, S-60r punto 6):** applicazione di **produzione in modalità ristretta** collegata ai suoi conti nel pannello Enable
  Banking; build DEBUG con interruttore acceso sul suo telefono con un **account Bucktrail di prova** (mai l'account reale); Matteo collega, controlla,
  scollega. Nessun dato reale viene salvato nel repository.

### 10.5 Comandi
```bash
# Backend
node --test 03_CODICE/bucktrail-backend/tests/
# Server finto e vettori
python3 -I 03_CODICE/bucktrail-android/scripts/test-fake-supabase-bank.py
python3 -I 03_CODICE/bucktrail-android/scripts/bank-vectors.py --check MoneyTrackerTests/Fixtures/bank-vectors-v1.json
# iOS (simulatore di riferimento D-004)
xcodebuild test -project MoneyTracker.xcodeproj -scheme MoneyTracker \
  -destination 'id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -only-testing:MoneyTrackerTests/BankDomainTests 2>&1 | tail -40
xcodebuild test -project MoneyTracker.xcodeproj -scheme MoneyTracker \
  -destination 'id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' 2>&1 | tail -60
# Android
cd 03_CODICE/bucktrail-android && ./gradlew testDebugUnitTest --tests 'com.bucktrail.android.bank.*' --tests 'com.bucktrail.android.domain.bank.*'
cd 03_CODICE/bucktrail-android && ./gradlew assembleDebug lintDebug testDebugUnitTest
cd 03_CODICE/bucktrail-android && ./gradlew connectedDebugAndroidTest   # emulatore Bucktrail_API_36 acceso
```
Se `xcodebuild` resta bloccato: `xcrun simctl shutdown all`, poi riprovare una volta.

---

## 11. Piano di lavoro

### 11.1 Regole comuni (R1–R12) — fanno parte di ogni prompt
- **R1 Turno:** AGENTS.md §4 (STATO «In turno», riga in DIARIO con `date "+%Y-%m-%d %H:%M"`, CONSEGNA riscritta, PIANO con `[~]`, STATO «nessuno»).
  Ruolo: `operaio (Claude Code · Sonnet)`.
- **R2 Commit:** solo i file del task + `.cantiere`: `git add <file> .cantiere && git commit -m "[operaio] <cosa> (S-60x)"`; mai `git add -A`; niente push;
  ramo `redesign-sentiero`; ultima riga del messaggio quella di attribuzione indicata dal sistema.
- **R3 Zone:** autorizzate solo quelle elencate nel task. Vietato modificare file esistenti di `Domain/`, i calcoli, `Export/`, `Intents/`, notifiche,
  ricorrenze, i **test esistenti** e i fake esistenti (si aggiungono file nuovi). Vietati `preferredColorScheme` e colori fissi.
- **R4 Interruttori:** `BankFeature.isEnabled = false` / `BANK_ENABLED = false` in tutti i task tranne S-60v; nei test si accendono solo con gli
  strumenti DEBUG (`-BankEnabled YES`, `-Pbank=true`). `bank_config.connect_enabled` non si tocca mai (lo fa Matteo).
- **R5 Niente servizi reali:** mai il Supabase vero, mai la service role, mai Enable Banking vero (tranne lo script guidato di S-60r, eseguito da Matteo).
- **R6 Orientamento:** prima `graphify query "<domanda>"`, poi solo i file necessari; dopo le modifiche `graphify update .`.
- **R7 Verifica:** i comandi del task devono essere verdi; riassunto in CONSEGNA (numero di test, esito). Se un test esistente diventa rosso:
  fermati, ripristina, `[!]` in PIANO con la causa.
- **R8 Dubbi:** se il progetto non copre un caso, scegli l'opzione più conservativa (nessuna scrittura, nessuna cancellazione, nessun import) e annotala
  in CONSEGNA come «scelta da confermare»; testi per l'utente solo dal §7.4.
- **R9 Semplicità:** solo ciò che il task chiede (AGENTS §6.9).
- **R10 Fine:** `➡️ Prossimo: S-60y → …`. Dopo S-60c, S-60g, S-60l, S-60p: collaudo di blocco (subagente `collaudatore`, legge solo il diff del blocco).
- **R11 Importi:** mai `Double`/`Float` per importi (iOS `Decimal`, Android `BigDecimal` → centesimi `Long` solo in Room). Parsing solo dal §4.7 `BankAmount`.
- **R12 Segreti:** nessuna chiave, token, IBAN reale o `session_id` in codice, test, fixture, log o documenti. Valori di prova evidentemente finti.

### 11.2 Ordine e dipendenze
```
[prerequisito: S-50a…S-50m chiusi]
S-60a (contratto+vettori Python) ─> S-60b (funzione TS) ─> S-60c (SQL + server finto) ─> [COLLAUDO 1 + stress-test sicurezza backend]
 ─> S-60d (dominio iOS) ─> S-60e (dominio Android) ─> S-60f (modelli iOS + V4) ─> S-60g (Room 3→4) ─> [COLLAUDO 2]
 ─> S-60h (client+importatore iOS) ─> S-60i (client+importatore Android) ─> S-60j (sync iOS + vault) ─> S-60k (sync Android + vault)
 ─> S-60l (interop + prova d'insieme col server finto) ─> [COLLAUDO 3 + stress-test dati/rete]
 ─> S-60m (link di ritorno + pagine landing) ─> S-60n (UI iOS) ─> S-60o (UI Android) ─> S-60p (ciclo di vita) ─> [COLLAUDO 4]
 ─> S-60q (Commissione Suprema + manuale)
S-60t [Matteo: commerciale/legale] ── si può fare SUBITO, in parallelo; serve solo prima di S-60u
S-60r [Matteo: banco di prova tecnico + sandbox guidata] ── dopo S-60m (meglio dopo S-60q) ─> S-60s (analisi sandbox e ritocchi)
S-60u [Matteo: produzione e dichiarazioni] ── dopo S-60q, S-60s, S-60t ─> S-60v (accensione + sito)
```

### 11.3 Task di Claude Code

#### S-60a · Contratto e vettori condivisi (≈ 1,5 h)
- **File:** `03_CODICE/bucktrail-android/scripts/bank-vectors.py` (nuovo), `MoneyTrackerTests/Fixtures/bank-vectors-v1.json` (nuovo; gruppi 1–7, il gruppo 8 in S-60l),
  `03_CODICE/bucktrail-backend/README.md` (nuovo: 15 righe, rinvio a questo progetto §3.4).
- **Accettazione:** lo script implementa con la sola libreria standard UUIDv5, `BankAmount`, `tx_key` (con canonico), `MerchantNameCleaner`, categoria,
  matcher e `OpeningBalance` esattamente come §3.4.1, §4.3, §4.4, §5; `--write` genera il JSON, `--check` lo verifica; ogni soglia del §4.4 ha un caso al bordo dentro e uno fuori.
- **Verifica:** `python3 -I 03_CODICE/bucktrail-android/scripts/bank-vectors.py --check MoneyTrackerTests/Fixtures/bank-vectors-v1.json`.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`,
  poi in `.cantiere/progetto-banca.md` i §3.4, §4.3, §4.4, §5, §10.2 e §11.1 (R1–R12 vincolanti). Controlla in `.cantiere/PIANO.md` che S-50a…S-50m siano
  `[x]`: se no, fermati e scrivilo. Task S-60a: scrivi `03_CODICE/bucktrail-android/scripts/bank-vectors.py` (solo libreria standard Python, implementazione
  di riferimento di UUIDv5 con NS_BANK, parsing importi HALF_UP, tx_key con importo canonico e suffissi, pulizia nomi, suggerimento categoria con tabella MCC,
  matcher con tutte le soglie, saldo iniziale) e genera `MoneyTrackerTests/Fixtures/bank-vectors-v1.json` con i gruppi 1–7 del §10.2 (almeno 30 descrizioni
  italiane realistiche ma inventate, nessun dato reale). Ogni soglia ha un caso al bordo dentro e uno fuori. Crea `03_CODICE/bucktrail-backend/README.md`
  (scopo, struttura, comandi, rinvio al progetto). Verifica: `python3 -I …/bank-vectors.py --check MoneyTrackerTests/Fixtures/bank-vectors-v1.json`. Chiudi il turno secondo R1–R2.»

#### S-60b · Funzione `bank` (≈ 2 h)
- **File (nuovi):** `03_CODICE/bucktrail-backend/supabase/functions/bank/{index.ts,core.ts,normalize.ts,seal.ts,providers/provider.ts,providers/enablebanking.ts}`,
  `03_CODICE/bucktrail-backend/supabase/config.toml` (solo `[functions.bank] verify_jwt = true`), `03_CODICE/bucktrail-backend/tests/*.test.ts`,
  `tests/fixtures/eb-*.json`, `tests/fixtures/normalized-*.json`, `03_CODICE/bucktrail-backend/package.json` (solo `"type":"module"` e script `test`, **nessuna dipendenza**).
- **Accettazione:** contratto §3.4 completo; sigilli §3.4.2 (HKDF da `BANK_SERVER_SECRET`); autenticazione via `GET /auth/v1/user`; limiti §3.7 tramite RPC
  `bank_hit`; registro §3.7; nessun import da URL esterni in `core.ts`/`normalize.ts`/`seal.ts` (Web Crypto e `fetch` iniettato) così che girino in Node 26;
  `index.ts` unico file con `Deno.*`. T2, T3, T4 verdi. La normalizzazione rispetta i vettori `txkey`/`amount` di S-60a (test che li legge).
- **Verifica:** `node --test 03_CODICE/bucktrail-backend/tests/`.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §3 (tutto), §4.5 (solo per i nomi di tabelle e `bank_hit`), §8.1, §10.2–10.3 (T2–T4) e §11.1 (R1–R12). Task S-60b: scrivi la
  Supabase Edge Function `bank` in `03_CODICE/bucktrail-backend/supabase/functions/bank/` esattamente secondo il contratto v1 del §3.4: router POST, validazione
  rigorosa, utente da `GET {SUPABASE_URL}/auth/v1/user`, sigilli AES-256-GCM con AAD e chiavi HKDF da `BANK_SERVER_SECRET`, JWT RS256 per Enable Banking (1 ora,
  in memoria), adattatore `providers/enablebanking.ts` dietro l'interfaccia `BankProvider` (endpoint `/aspsps`, `/auth`, `/sessions`, `/accounts/{uid}/balances`,
  `/accounts/{uid}/transactions`, `DELETE /sessions/{id}`), normalizzazione §3.4.1, errori §3.4.3, limiti con RPC `bank_hit`, tabelle `bank_links` e
  `bank_auth_states` via PostgREST con la service role, registro minimo §3.7. Tutta la logica in moduli puri testabili con Node 26 (`fetch` e orologio iniettati);
  solo `index.ts` usa `Deno`. Nessuna dipendenza npm. Scrivi fixture realistiche ma inventate e i test T2, T3, T4. Verifica: `node --test 03_CODICE/bucktrail-backend/tests/`.
  Non fare deploy. Chiudi il turno secondo R1–R2.»

#### S-60c · SQL e server finto (≈ 1,5 h)
- **File:** `03_CODICE/bucktrail-backend/sql/s60-bank-v1.sql`, `s60-bank-v1-rollback.sql` (copie esatte del §4.5); `03_CODICE/bucktrail-android/scripts/fake-supabase.py`
  (estensione §10.2), `scripts/test-fake-supabase-bank.py` (nuovo).
- **Accettazione:** SQL identico al progetto (un test Python confronta il file con il blocco del §4.5); server finto con rotte bank, scenari, tabelle `mt_bank_*`,
  guardia E2E emulata anche sulle nuove tabelle, `kind` nuovi accettati in `mt_vault`; comportamenti esistenti invariati (test S-50 del server finto verdi). T5 verde.
- **Verifica:** `python3 -I …/test-fake-supabase-bank.py`, `python3 -I …/test-fake-supabase-e2e.py`, `cd 03_CODICE/bucktrail-android && ./gradlew testDebugUnitTest`.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §4.5, §6.6 di `.cantiere/progetto-e2e-sync.md` (server finto S-50), §10.2, §11.1. Task S-60c: copia gli script SQL del §4.5 in
  `03_CODICE/bucktrail-backend/sql/` (identici); estendi `fake-supabase.py` con `POST /functions/v1/bank/<azione>` che serve `03_CODICE/bucktrail-backend/tests/fixtures/normalized-*.json`
  secondo `FAKE_BANK_SCENARIO` e `FAKE_BANK_FAIL_AFTER`, con le tabelle `mt_bank_*` (PK `id`, filtri `user_id`), guardia E2E emulata anche su di esse e `kind`
  bancari in `mt_vault`. Scrivi `test-fake-supabase-bank.py` (libreria standard, porta libera, una prova per rotta e scenario, più il confronto SQL file↔progetto).
  Verifica con i comandi del task. Chiudi il turno secondo R1–R2 e indica «serve collaudo di blocco 1 (S-60a…c) + stress-test sicurezza backend».»
- **Collaudo blocco 1** (subagente `collaudatore` + skill `stress-test`): «Collauda S-60a…c leggendo solo il diff del blocco e `.cantiere/progetto-banca.md` §3, §4.5, §8.1.
  Controlla con la lista OWASP API Security Top 10 (2023): BOLA sui sigilli, autenticazione, esposizione di dati (nessun IBAN completo né `session_id` in uscita),
  limiti, autorizzazione a livello di funzione, SSRF, configurazione (no CORS, no-store), registro. Esegui `node --test` e i test Python. Prova a mano 10 input
  ostili (JSON enorme, tipi sbagliati, sigillo di un altro utente, state riusato). Esito in PIANO.»

#### S-60d · Dominio puro iOS (≈ 2 h)
- **File (nuovi):** `MoneyTracker/Domain/Bank/{BankIds,BankAmount,MerchantNameCleaner,BankCategorySuggester,BankMatcher,TransferDetector,OpeningBalance}.swift`,
  `MoneyTrackerTests/BankDomainTests.swift`.
- **Accettazione:** funzioni pure `nonisolated` (come `KeywordCategoryClassifier`), nessun accesso a SwiftData/rete; tutti i vettori 1–7 verdi; `BankCategorySuggester`
  riceve classificatore e storico per iniezione (usa `CategoryClassifying` e `LastUsedCategory` esistenti senza modificarli). Suite iOS completa verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §4.3, §4.4, §4.7, §5, §10.2 e §11.1. Task S-60d: crea in `MoneyTracker/Domain/Bank/` i 7 file puri del §4.7 (nessun file
  esistente di Domain va modificato), con `Decimal` per gli importi e UUIDv5 via `Insecure.SHA1`. Scrivi `MoneyTrackerTests/BankDomainTests.swift` che legge
  `Fixtures/bank-vectors-v1.json` e verifica i gruppi 1–7. Verifica: la suite `BankDomainTests` e poi la suite iOS completa (comandi §10.5). Chiudi il turno secondo R1–R2.»

#### S-60e · Dominio puro Android (≈ 2 h)
- **File (nuovi):** `app/src/main/java/com/bucktrail/android/domain/bank/*.kt` (stessi 7), `app/src/test/java/com/bucktrail/android/domain/bank/BankDomainVectorsTest.kt`;
  `app/build.gradle.kts` (solo `systemProperty("bankVectors", …)`).
- **Accettazione:** vettori 1–7 verdi su JVM; UUIDv5 con `MessageDigest("SHA-1")` (vietato `nameUUIDFromBytes`); `BigDecimal` con `RoundingMode.HALF_UP`. Suite Android verde.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §4.3, §4.4, §4.7, §5, §10.2 e §11.1. Task S-60e: porta in Kotlin (`domain/bank/`) le 7 funzioni pure di S-60d, identiche nel
  comportamento, e scrivi `BankDomainVectorsTest.kt` che legge i vettori tramite `systemProperty("bankVectors", rootProject.file("../../MoneyTrackerTests/Fixtures/bank-vectors-v1.json"))`.
  Verifica: `cd 03_CODICE/bucktrail-android && ./gradlew testDebugUnitTest`. Chiudi il turno secondo R1–R2.»

#### S-60f · Modelli iOS e SchemaV4 (≈ 1,5 h)
- **File:** nuovi `MoneyTracker/Models/{BankConnection,BankAccountLink,BankDecision,BankInboxItem}.swift`; modificati `MoneyTracker/Persistence/SchemaMigration.swift`
  (SchemaV4 + stage leggero), `MoneyTracker/MoneyTrackerApp.swift` (schema V4) e ogni altro punto che usa `SchemaV3` (cercarli con `graphify query` e `grep`);
  nuovo `MoneyTrackerTests/SchemaV4MigrationTests.swift`; `MoneyTracker/Sync/Bank/BankFeature.swift` (interruttore spento + override DEBUG `-BankEnabled YES`).
- **Accettazione:** T6 iOS verde; `SchemaMigrationTests` esistente verde e invariato; app avviata sul simulatore con uno store V3 popolato (copiato prima dell'aggiornamento)
  → dati identici (conteggio movimenti e saldo totale in Home uguali, screenshot prima/dopo in CONSEGNA).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §4.1, §4.2, §4.6 e §11.1. Task S-60f: crea i 4 modelli SwiftData del §4.2 (nessuna relazione verso i modelli esistenti, solo UUID;
  `Decimal` per `lastBalance`), aggiungi `SchemaV4` e lo stage leggero V3→V4 in `SchemaMigration.swift` senza toccare V1–V3, aggiorna tutti i punti che costruiscono
  lo schema, crea `BankFeature.swift` spento. Scrivi `SchemaV4MigrationTests.swift` (store V3 su disco con dati → riapertura V4 → dati identici). Poi prova sul
  simulatore: installa la build attuale (prima del task) con dati demo copiati come dati reali o inseriti a mano, aggiorna, verifica che saldi e movimenti siano
  identici (screenshot). Verifica: suite iOS completa. Chiudi il turno secondo R1–R2.»

#### S-60g · Room 3 → 4 (≈ 1,5 h)
- **File:** nuovi `data/BankEntities.kt`, `data/BankDao.kt`; modificati `BucktrailDatabase.kt` (versione 4, entità), `data/Migrations.kt` (`Migration(3,4)` solo `CREATE TABLE IF NOT EXISTS`),
  punto di registrazione delle migrazioni; test nuovi `app/src/androidTest/.../Migration3To4Test.kt` e JVM `BankSchemaSqlTest.kt`; `app/build.gradle.kts` (`BANK_ENABLED` false, `-Pbank=true` in debug).
- **Accettazione:** T6 Android verde su emulatore; migrazione 2→3 esistente intatta; prova su emulatore: database v3 popolato → aggiornamento → dati identici.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §4.2, §4.6 e §11.1, e la decisione «Migrazione Room 2→3» in `.cantiere/DECISIONI.md`. Task S-60g: aggiungi le 4 entità Room del §4.2
  (centesimi `Long` per `lastBalance`), il DAO, la `Migration(3, 4)` additiva e la versione 4; aggiungi `BANK_ENABLED` spento. Scrivi il test strumentato di
  migrazione con dati e il test JVM sulla SQL. Prova su emulatore Bucktrail_API_36 con un database v3 popolato. Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest`
  e `./gradlew connectedDebugAndroidTest`. Chiudi il turno secondo R1–R2 e indica «serve collaudo di blocco 2 (S-60d…g)».»
- **Collaudo blocco 2:** «Collauda S-60d…g leggendo solo il diff e `.cantiere/progetto-banca.md` §4, §5. Controlla: vettori identici sulle 3 implementazioni,
  nessun `Double` per importi, nessun file esistente di Domain modificato, migrazioni solo additive, test esistenti intatti (`git diff --stat`). Esito in PIANO.»

#### S-60h · iOS: client e importatore (≈ 2 h)
- **File (nuovi):** `MoneyTracker/Sync/Bank/{BankAPI.swift (protocollo BankAPIClient + client URLSession verso /functions/v1/bank con JWT di SupabaseManager), BankImporter.swift, BankController.swift}`,
  `MoneyTrackerTests/{BankImporterTests,BankFlagOffTests}.swift`, `MoneyTrackerTests/Support/InMemoryBankAPI.swift`.
- **Accettazione:** importatore `@MainActor` che scrive con il `ModelContext` e il salvataggio esistente (così `recordChanges` marca i movimenti per la sync);
  finestra/cursore/potatura §4.3; saldo iniziale solo per conti nuovi; T7, T8, T9 (parte logica), T10 verdi; nessuna chiamata di rete a interruttore spento.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §3.4, §3.6, §4.3, §4.4, §5, §10.3 (T7–T10) e §11.1. Task S-60h: crea `BankAPI.swift` (protocollo + client verso la funzione con
  il token di `SupabaseManager`, errori §3.4.3), `BankImporter.swift` (usa solo le funzioni pure di `Domain/Bank/`; crea `Transaction` con `id = importId`, nomi
  e categorie §5, note = descrizione; `BankDecision`, `BankInboxItem`; cursore aggiornato solo a finestra salvata; conti nuovi con `OpeningBalance`; mai
  modificare movimenti esistenti tranne `isDone` su conferma esplicita), `BankController.swift` (stato osservabile per la UI, aggiornamento all'apertura se > 6 h).
  Test con `InMemoryBankAPI`. Verifica: suite iOS completa. Chiudi il turno secondo R1–R2.»

#### S-60i · Android: client e importatore (≈ 2 h)
- **File (nuovi):** `bank/{BankApi.kt, HttpBankApi.kt, BankImporter.kt, BankController.kt}`, test `app/src/test/.../bank/{BankImporterTest,BankFlagOffTest,FakeBankApi}.kt`.
- **Accettazione:** come S-60h; scritture Room in un'unica transazione per finestra; le scritture passano per il `ChangeWatcher` (sync) come le altre.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi in
  `.cantiere/progetto-banca.md` i §3.4, §3.6, §4.3, §4.4, §5, §10.3 (T7–T10) e §11.1. Task S-60i: porta su Android client (`HttpURLConnection` + kotlinx-serialization
  come `SupabaseApi.kt`), importatore e controller di S-60h, con lo stesso comportamento; una transazione Room per finestra. Test con `FakeBankApi` nuovo (i fake
  esistenti non si toccano). Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest`. Chiudi il turno secondo R1–R2.»

#### S-60j · iOS: sync delle entità bancarie (≈ 2 h)
- **File:** `MoneyTracker/Sync/SyncService.swift` e i file `Sync/E2E/` di S-50 (`SyncRemote`, `VaultRemote`, `E2EMigrator`, `E2EVerifier`): aggiunta delle 3 tabelle/kind
  e del passo isolato §4.8; nuovi `Sync/Bank/BankSyncRows.swift`, `MoneyTrackerTests/BankSyncTests.swift`.
- **Accettazione:** T10 (richieste d'oro S-50 identiche a interruttore spento), T11, T12 verdi; tutti i test E2E di S-50 verdi e invariati.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §4.8, §6, §10.3 (T10–T12), §11.1 e in `.cantiere/progetto-e2e-sync.md` §7 e §8.2. Task S-60j: aggiungi la sync delle 3 entità
  bancarie come passo separato dopo quello esistente, con `do/catch` proprio, in chiaro su `mt_bank_*` e nel vault con i kind `bank_*`; estendi l'elenco dei
  kind del migratore e del verificatore E2E solo se `BankFeature.isEnabled`; tabelle assenti → `serverSupported = false`. Nessun cambiamento ai percorsi esistenti
  a interruttore spento (dimostralo con i test d'oro di S-50). Verifica: suite iOS completa. Chiudi il turno secondo R1–R2.»

#### S-60k · Android: sync delle entità bancarie (≈ 2 h)
- **File:** `sync/SyncMapper.kt`, `sync/SyncEngine.kt` (parametro finale con default no-op, come S-50), `sync/e2e/*` di S-50, nuovi `sync/BankSync.kt` e test.
- **Accettazione:** come S-60j su Android; `HttpSupabaseApiTest` e test S-50 verdi e invariati.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §4.8, §6, §10.3 (T10–T12), §11.1 e `.cantiere/progetto-e2e-sync.md` §7 e §8.2. Task S-60k: porta su Android la sync bancaria di S-60j
  (passo isolato, chiaro/vault, kind nel migratore E2E solo con `BANK_ENABLED`), aggiungendo parametri con valori predefiniti che lasciano identico il comportamento
  attuale. Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest`. Chiudi il turno secondo R1–R2.»

#### S-60l · Interoperabilità e prova d'insieme (≈ 1,5 h)
- **File:** gruppo `rows` nei vettori (`bank-vectors.py`, JSON), `MoneyTrackerTests/BankInteropTests.swift`, `.../BankInteropTest.kt`.
- **Accettazione:** T13 verde; T17 eseguito su emulatore **e** simulatore col server finto (log e `curl` in CONSEGNA); nessun IBAN completo né `session_id` nel server finto.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §3.6, §4.3, §10.2–10.3 (T13, T17) e §11.1. Task S-60l: aggiungi ai vettori il gruppo `rows` (righe prodotte da iOS e da Android per i
  3 kind) e i test incrociati; simula due dispositivi sullo stesso remoto in memoria che aggiornano lo stesso collegamento (zero doppioni). Poi esegui la prova
  d'insieme T17 con `fake-supabase.py` su emulatore (`-Pbank=true`) e simulatore (`-BankEnabled YES`). Verifica: suite complete iOS e Android. Chiudi il turno
  secondo R1–R2 e indica «serve collaudo di blocco 3 (S-60h…l) + stress-test».»
- **Collaudo blocco 3** (`collaudatore` + skill `stress-test`): «Collauda S-60h…l leggendo solo il diff e `.cantiere/progetto-banca.md` §4, §6. Stress-test: 5 000
  movimenti in una finestra (tempi), 3 pagine con rete che cade a metà, 200 doppioni candidati, nomi lunghissimi e Unicode, importi ai limiti, due dispositivi
  insieme, attivazione/disattivazione E2E con dati bancari. Esito e numeri in PIANO.»

#### S-60m · Link di ritorno e pagine della landing (≈ 1,5 h)
- **File:** iOS `MoneyTracker/Info.plist` (`CFBundleURLTypes`), `MoneyTracker/MoneyTracker.entitlements` (associated domains), gestione `onOpenURL` nella radice
  (`ContentView` o `MoneyTrackerApp`, dentro `if BankFeature.isEnabled`), `Sync/Bank/BankLinkFlow.swift` (stato in attesa nel Keychain, verifier, `start`/`finish`);
  Android `AndroidManifest.xml` (2 intent-filter), `MainActivity.kt` (`onNewIntent`), `bank/BankLinkFlow.kt`; landing `SOCIAL/landing/banca/ritorno.html`,
  `SOCIAL/landing/.well-known/apple-app-site-association`, `.well-known/assetlinks.json` (impronta debug; release `[DA COMPLETARE]`), `_worker.js` (content-type e intestazioni §3.5);
  `03_CODICE/bucktrail-backend/scripts/sandbox-smoke.mjs` (Node 26, importa `providers/enablebanking.ts` e `normalize.ts`; ascolta su `http://localhost:8765/callback`
  per ricevere il `code`; in alternativa accetta incollato un URL `https://…/banca/ritorno?…` o `bucktrail://banca/ritorno?…`; salva le risposte grezze in
  `tests/fixtures/sandbox-*.json` togliendo eventuali IBAN e nomi; chiude sempre la sessione; legge la chiave da `--key`, mai dal repository).
- **Accettazione:** T14 verde; su simulatore `xcrun simctl openurl booted "bucktrail://banca/ritorno?code=x&state=y"` e su emulatore `adb shell am start -a android.intent.action.VIEW -d "bucktrail://banca/ritorno?code=x&state=y"`
  raggiungono il gestore (con interruttore acceso in DEBUG) e vengono ignorati senza stato in attesa; pagina di ritorno provata in locale (`npx wrangler pages dev` **non** necessario: basta aprire il file e controllare la redirezione con un URL finto);
  nessuno script di analytics nella pagina.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §3.5, §8.1, §10.3 (T14) e §11.1. Task S-60m: implementa il flusso di ritorno tipo PKCE su iOS e Android (stato in attesa cifrato,
  15 minuti, `start` → browser di sistema → ritorno → `finish`), gli schemi e i filtri esatti del §3.5, la pagina `SOCIAL/landing/banca/ritorno.html` (it/en, nessun
  analytics, `replaceState`, pulsante di riserva), i file `.well-known` e le intestazioni in `_worker.js`. Ricava l'impronta debug con `keytool`. Non pubblicare la
  landing. Scrivi anche `03_CODICE/bucktrail-backend/scripts/sandbox-smoke.mjs` come descritto nei file del task (provalo con un `fetch` finto: nessuna chiamata
  vera). Verifica: suite complete, `node --test`, le prove `simctl openurl` / `adb am start`. Chiudi il turno secondo R1–R2 e scrivi in PER-MATTEO che S-60r è pronto
  (istruzioni del §11.4 S-60r).»

#### S-60n · Interfaccia iOS (≈ 2 h)
- **File:** nuovi `MoneyTracker/Views/Bank/{BankConnectionsView,BankPickerView,BankConsentView,BankAccountsSetupView,BankConnectionDetailView,BankInboxView}.swift`;
  modificati `SettingsView.swift` (sezione), `TransactionsView.swift` (striscia), `AccountsView.swift` (riga collegato + allinea saldo), `AddTransactionView.swift`
  (riga «Importato da»), 7 `Localizable.strings` (solo chiavi `bank_*` in fondo); `MoneyTrackerUITests/BankUITests.swift`; harness DEBUG `-BankUITestHarness YES`.
- **Accettazione:** tutte le schermate e gli stati §7.2–7.3; testi §7.4; T15, T16 verdi; screenshot §7.5 in `/tmp/bank-ios/`; UI test esistenti verdi; ogni modifica a
  viste esistenti è dentro `if BankFeature.isEnabled` (o condizionata a «conto collegato» / «inbox non vuota»).
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, la skill
  `frontend-design` solo per la direzione (l'handoff `02_RISORSE/originali/bucktrail-redesign/DESIGN_HANDOFF.md` vince), poi `.cantiere/progetto-banca.md` §7 (tutto),
  §10.3 (T15–T16) e §11.1. Task S-60n: costruisci le 6 schermate iOS e le aggiunte minime alle viste esistenti del §7.1, con token `DS.*`, `.scaledFont`, nessun
  colore fisso, nessun `preferredColorScheme`; aggiungi le chiavi `bank_*` nelle 7 lingue copiandole dal §7.4. Scrivi `BankUITests` con l'harness DEBUG. Fai gli
  screenshot del §7.5 e confrontali con Impostazioni/Conti/Movimenti esistenti (bordi, badge, troncamenti in tedesco e XXXL). Verifica: suite iOS completa. Chiudi il turno secondo R1–R2.»

#### S-60o · Interfaccia Android (≈ 2 h)
- **File:** nuovo `ui/screens/BankScreens.kt`; modificati `SettingsSheets.kt`, schermate Movimenti/Conti/modifica movimento, `SfIcons.kt` (2 icone), `res/values*/strings.xml`
  (solo `bank_*`, con lo stesso meccanismo usato per `e2e_*` in S-50k), test Compose strumentato.
- **Accettazione:** come S-60n su Android; screenshot in `/tmp/bank-android/`; test esistenti verdi.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §7, §10.3 (T15–T16) e §11.1. Task S-60o: riproduci su Android le schermate e gli stati di S-60n (confronto obbligatorio con gli
  screenshot iOS in `/tmp/bank-ios/`), colori del tema Sentiero, icone vettoriali proprie per `building.columns` e `tray.and.arrow.down`, chiavi `bank_*` nelle 7 lingue.
  Screenshot in `/tmp/bank-android/`. Verifica: `./gradlew assembleDebug lintDebug testDebugUnitTest` e `connectedDebugAndroidTest`. Chiudi il turno secondo R1–R2.»

#### S-60p · Ciclo di vita (≈ 1,5 h)
- **File:** `BankController` iOS/Android, `Auth/SupabaseManager.swift` (`deleteAccount`: `disconnect` al meglio prima della RPC, solo con interruttore acceso), `clearLocalData`
  iOS / `SyncEngine.clearLocalData` Android (entità bancarie e stato in attesa), test `BankLifecycleTests.swift` / `BankLifecycleTest.kt`.
- **Accettazione:** scollega (con e senza B36, autenticazione del dispositivo per B36), rinnovo con riabbinamento per `account_ref`, scadenza, logout, cambio utente,
  eliminazione account (se la RPC fallisce non si tocca nulla), demo invisibile; skill `stress-test` con risultati in CONSEGNA.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §3.6, §8.2, §8.3 e §11.1. Task S-60p: completa e prova i casi di vita su iOS e Android (scollega, elimina importati, rinnovo,
  scadenza, logout, cambio utente, eliminazione account, demo). Esegui la skill `stress-test` (`.agents/skills/stress-test/SKILL.md`) su questi casi. Verifica:
  suite complete. Chiudi il turno secondo R1–R2 e indica «serve collaudo di blocco 4 (S-60m…p)».»
- **Collaudo blocco 4:** «Collauda S-60m…p leggendo solo il diff, `.cantiere/progetto-banca.md` §3.5, §7, §8.3 e gli screenshot in `/tmp/bank-ios/` e `/tmp/bank-android/`.
  Controlla: testi uguali al §7.4 nelle 7 lingue, niente stringhe fisse, token del tema, bordi e badge ingranditi, nessun `preferredColorScheme`, interruttori spenti,
  Impostazioni/Conti/Movimenti identiche a interruttore spento, nessun analytics nella pagina di ritorno. Esito in PIANO.»

#### S-60q · Commissione Suprema e manuale (≈ 1,5 h)
- **File:** correzioni nei soli file S-60; `docs/MoneyTracker.md` (sezione «Collegamento bancario (dietro interruttore, spento)» + Changelog); `docs/MoneyTracker.pdf`.
- **Accettazione:** 6 giudici a 10/10 sul diff completo S-60 (sicurezza anche con OWASP MASVS-STORAGE/NETWORK e API Top 10); suite complete verdi; PDF rigenerato. Niente push.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md` (Commissione
  Suprema), `.cantiere/progetto-banca.md` §3, §4, §6, §8, §12 e §11.1. Task S-60q: convoca la Commissione Suprema sul diff completo di S-60 (dal commit prima di S-60a a HEAD):
  6 giudici, voto 1–10, diagnosi file+riga e correzione per ogni voto sotto 10; correggi solo file S-60 e ripeti fino a 10/10. Aggiorna `docs/MoneyTracker.md` (ciò che è
  costruito, dietro interruttore spento) e rigenera il PDF col comando di REGOLE-PROGETTO. Verifica: suite complete. Nessun push. Chiudi il turno secondo R1–R2.»

#### S-60s · Analisi della sandbox (≈ 1 h, dopo S-60r)
- **File:** `tests/fixtures/sandbox-*.json` (prodotti in S-60r, dati finti della sandbox), `normalize.ts` e vettori se servono, nuovo test `sandbox-shapes.test.ts`.
- **Accettazione:** la normalizzazione gestisce le forme reali della sandbox (o il task elenca le differenze e le corregge); risposte ai [DA VERIFICARE] tecnici:
  valori di `status`, presenza di `merchant_category_code`, `entry_reference`/`transaction_id`, `identification_hash`, IBAN, banche IT presenti (Fineco, N26, Revolut,
  Hype…) da `aspsps`, endpoint per elencare sessioni. Esiti scritti in questo progetto (§2.1, §3.4.1, §6.4) con data.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §2.1, §3.4.1, §6.4, §10.4 e §11.1. Task S-60s: analizza i file `03_CODICE/bucktrail-backend/tests/fixtures/sandbox-*.json` prodotti da
  Matteo in S-60r; aggiungi un test che li normalizza; correggi `normalize.ts` (e vettori/app se cambia il contratto, senza rompere la v1) dove le forme reali
  differiscono; rispondi ai [DA VERIFICARE] tecnici elencati nel task aggiornando il progetto con data. Se il contratto v1 deve cambiare in modo incompatibile, fermati e
  scrivi `[!]` con la proposta. Verifica: `node --test`, test Python, suite complete se tocchi le app. Chiudi il turno secondo R1–R2 e aggiorna PER-MATTEO per S-60u.»

#### S-60v · Accensione e sito (≈ 1 h) — SOLO dopo S-60q, S-60s, S-60t, S-60u `[x]`
- **File:** `BankFeature.swift` (`isEnabled = true`), `app/build.gradle.kts` (`BANK_ENABLED` true anche in release), `SOCIAL/landing/privacy.html`, `index.html`, `en.html`
  (testi §8.4), `docs/MoneyTracker.md` + PDF, `.cantiere/APPROVAZIONI.md` (testi del sito in attesa di ✅).
- **Accettazione:** suite complete verdi; testi del sito in APPROVAZIONI; nessuna pubblicazione del sito né push senza Matteo. Regola: una volta pubblicata una versione
  con l'interruttore acceso **non si torna a spento** (gli utenti collegati perderebbero l'accesso ai loro collegamenti): per fermare si usa `connect_enabled = false`.
- **Prompt:** «Sei l'operaio (Claude Code · Sonnet) nel cantiere MoneyTracker, ramo `redesign-sentiero`. Leggi AGENTS.md, `.cantiere/REGOLE-PROGETTO.md`, poi
  `.cantiere/progetto-banca.md` §8.4, §8.5, §11.3 S-60v e §11.1 (R4 qui non vale). Controlla in PIANO che S-60q, S-60s, S-60t e S-60u siano `[x]`: se no, fermati.
  Task S-60v: accendi gli interruttori compilati, inserisci i testi del §8.4 in privacy e FAQ (it/en) adattandoli alla struttura esistente e togliendo «in arrivo»
  dalla sezione bancaria, aggiorna `docs/MoneyTracker.md` e il PDF, scrivi i testi del sito in `.cantiere/APPROVAZIONI.md` in attesa di ✅. Verifica: suite complete.
  Non pubblicare il sito, non fare push. Chiudi il turno secondo R1–R2.»

### 11.4 Passi di Matteo (3 in tutto, istruzioni complete AGENTS §6.13)

#### S-60t · [?] Matteo · Verifiche commerciali e legali (si può fare SUBITO, in parallelo; ~30 minuti + attese)
1. 📍 **Apple Developer** (browser → developer.apple.com/account → «Membership details»). ▶️ Guarda «Entity type» / «Program type». ↩️ Riportami «Individual» o «Organization».
2. 📍 **Enable Banking** (browser → enablebanking.com → «Contact» / info@enablebanking.com). ▶️ Invia questo messaggio:
   ```
   Hello, I'm an independent developer in Italy building a personal finance app (iOS/Android) that would use your AIS API under your licence
   (read-only balances and transactions, personal accounts, Italy first). Expected volume at launch: under 50 connected accounts.
   1) Can you contract with an individual / sole trader based in Italy (KYB)? 2) What is the minimum monthly invoice and the price per
   connected account per month? 3) GDPR: are you an independent controller or a processor towards us, and do you provide a DPA?
   4) Where is data processed? 5) Does your API allow listing all sessions of an application? Thank you.
   ```
   ↩️ Incollami la risposta quando arriva.
3. 📍 **Professionista** (avvocato o consulente fintech/privacy). ▶️ Fai la domanda della riga L2 del §9 e chiedi il registro dei trattamenti (L4). ↩️ Riportami la risposta in 3 righe.
Dopo le risposte il capocantiere segna `[x]` e, se servono, l'architetto aggiorna il modello di costo (§12.2).

#### S-60r · [?] Matteo · Banco di prova tecnico + prova guidata in sandbox (dopo S-60m, ~40 minuti, una sola seduta)
1. 📍 Browser → enablebanking.com → **Sign up** (gratuito) → Control Panel → **API applications** → **Register new application**: ambiente **Sandbox**,
   nome «Bucktrail sandbox», redirect URL `https://bucktrailapp.com/banca/ritorno` **e** `http://localhost:8765/callback` (se il pannello rifiuta il secondo,
   lascia solo il primo: lo script accetta anche il link incollato), scegli «Generate private key in the browser» e scarica il file `.pem`.
   ▶️ Nel Terminale (nuova scheda): `mkdir -p ~/.bucktrail && mv ~/Downloads/*.pem ~/.bucktrail/eb-sandbox.pem && chmod 600 ~/.bucktrail/eb-sandbox.pem`. Annota l'**Application ID**.
2. 📍 Terminale, cartella del cantiere. ▶️ `openssl rand -hex 32` → copia il risultato (è `BANK_SERVER_SECRET`).
3. 📍 Browser → supabase.com → progetto Bucktrail → **Edge Functions → Secrets** → aggiungi: `ENABLEBANKING_APP_ID` = l'Application ID; `ENABLEBANKING_PRIVATE_KEY` =
   tutto il contenuto del `.pem` (Terminale: `cat ~/.bucktrail/eb-sandbox.pem | pbcopy`, poi incolla); `ENABLEBANKING_ENV` = `sandbox`; `BANK_SERVER_SECRET` = il valore del
   punto 2; `BANK_REDIRECT_URL` = `https://bucktrailapp.com/banca/ritorno`. Poi **Project Settings → General**: annota la **Region** e il **Reference ID**.
4. 📍 Supabase → **SQL Editor → New query**. ▶️ Incolla tutto il blocco SQL del §4.5 (da `-- Bucktrail · S-60` a `order by 1, 2;`) e premi **Run**. ↩️ Numero di righe (devono essere **19**) o il testo dell'errore.
5. 📍 Terminale, cartella del cantiere. ▶️
   ```
   cd 03_CODICE/bucktrail-backend && npx supabase login && npx supabase functions deploy bank --project-ref <Reference ID>
   ```
   (al login si apre il browser: conferma). ↩️ L'ultima riga stampata.
6. 📍 Cloudflare Pages (come per gli altri caricamenti della landing, istruzioni in PER-MATTEO): carica la cartella `SOCIAL/landing` aggiornata (contiene solo la pagina
   di ritorno e i file `.well-known`, nessun testo nuovo visibile). ↩️ «caricata».
7. 📍 Terminale, cartella del cantiere. ▶️
   ```
   node 03_CODICE/bucktrail-backend/scripts/sandbox-smoke.mjs --key ~/.bucktrail/eb-sandbox.pem --app <Application ID>
   ```
   Segui le istruzioni: apri l'URL stampato, scegli la banca di prova, usa le credenziali di prova indicate nella pagina. Se il ritorno arriva a `localhost` lo
   script prosegue da solo; se arriva alla pagina di Bucktrail, fai clic destro su «Torna a Bucktrail» → «Copia indirizzo link» e incollalo nel Terminale.
   ↩️ «finito» (lo script salva i file per S-60s) oppure lo screenshot dell'errore.
8. *(Facoltativo, banca vera)* Control Panel → **Register new application** ambiente **Production** (stesso redirect) → «Activate by linking accounts» con la tua banca
   (modalità ristretta, gratuita). Poi, con il capocantiere, prova sul tuo telefono con una build di prova e un **account Bucktrail di prova**. ↩️ «ok» o screenshot.

#### S-60u · [?] Matteo · Produzione e dichiarazioni (dopo S-60q, S-60s, S-60t; ~30 minuti)
1. Decisione sul modello di costo (§12.2) con il preventivo di Enable Banking: rispondi «incluso» oppure «pass annuale».
2. 📍 Enable Banking Control Panel: firma il contratto, completa il KYB, applicazione **Production** attiva (non ristretta). Supabase → Edge Functions → Secrets:
   sostituisci `ENABLEBANKING_APP_ID` e `ENABLEBANKING_PRIVATE_KEY` con quelli di produzione, `ENABLEBANKING_ENV` = `production`.
3. 📍 Terminale: ▶️ `keytool -list -v -keystore <percorso della tua chiave di rilascio>` oppure Play Console → Configurazione → Integrità dell'app → **Firma dell'app**:
   copia l'impronta **SHA-256** e incollala al capocantiere (va in `assetlinks.json`).
4. 📍 App Store Connect → App Privacy e Google Play Console → Sicurezza dei dati / Funzionalità finanziarie: inserisci le voci del §8.5 (il capocantiere ti guida schermata per schermata).
5. Approva i testi del sito in `.cantiere/APPROVAZIONI.md` (scrivi ✅).
6. 📍 Supabase → SQL Editor ▶️ `update public.bank_config set connect_enabled = true where id = 1;` **solo** quando la versione con l'interruttore acceso è approvata dagli store. ↩️ «fatto».

---

## 12. Rischi, costi, decisioni

### 12.1 Rischi residui
| # | Rischio | Gravità | Mitigazione |
|---|---|---|---|
| R1 | **App Store 5.1.1(ix)**: rifiuto per account individuale in ambito finanziario | **alta** | S-60t punto 1 prima di tutto; codice dietro interruttore (nessun danno); eventuale società |
| R2 | Enable Banking non contrattualizza un privato / minimo mensile troppo alto | alta | S-60t; piano B Salt Edge (adattatore nuovo); restare in modalità ristretta finché i numeri non tornano |
| R3 | Serve una registrazione presso Banca d'Italia | media | S-60t punto 3; nessuna accensione senza risposta |
| R4 | Qualità dati delle banche italiane (CBI Globe variabile, ID instabili, `h:` senza ID) | media | ID con fallback e suffissi; dedupe confermata dall'utente; sandbox S-60s; mai cancellazioni automatiche |
| R5 | Doppioni non riconosciuti (importi in valuta, date molto distanti) | media | soglie §4.4 conservative + «Ignora» + cancellazione senza rinascita |
| R6 | Consenso unico per banca: un'altra app dell'utente che usa Enable Banking sulla stessa banca può annullare il nostro | bassa | stato «scaduto/revocato» chiaro, rinnovo in 1 minuto |
| R7 | Movimenti visibili alla funzione in transito (anche con E2E) | bassa (dichiarata) | nessun salvataggio, log minimi, testo onesto §6.4/§8.4 |
| R8 | Operatore con chiave privata + elenco sessioni (se l'API lo consente) | bassa | S-60s verifica; testo privacy prudente |
| R9 | Costi Supabase oltre il piano gratuito | bassa | 500 000 invocazioni/mese gratuite ([Supabase](https://supabase.com/docs/guides/functions/pricing)); ~600/mese per utente collegato → ~800 utenti collegati prima del piano Pro (25 $/mese) |
| R10 | Interruttore acceso e poi spento | media | vietato dopo la pubblicazione (§11.3 S-60v); si usa `connect_enabled` |
| R11 | Universal/App Link non verificato (cache Apple, impronta release mancante) | bassa | ritorno di riserva con `bucktrail://` dalla pagina |
| R12 | `mt_vault_kind_check` con nome diverso | bassa | controllo in S-60c e nel ↩️ di S-60r |

### 12.2 Costi
- **Fissi:** Enable Banking fattura minima mensile **[DA VERIFICARE, S-60t]**; Supabase gratuito fino a ~800 utenti collegati, poi 25 $/mese; nessun certificato
  eIDAS (si usa la licenza di Enable Banking; un certificato proprio costerebbe 2 000–8 000 €/anno secondo fonti di terzi); professionista una tantum **[DA VERIFICARE]**.
- **Per utente:** costo per conto collegato al mese `c` **[DA VERIFICARE]**. Ricavo netto per vendita ≈ 4,99 € − IVA 22 % (→ 4,09 €) − commissione store 15 %
  (programma piccoli sviluppatori) ≈ **3,48 €, una volta sola**. Con 1,5 conti collegati in media, un utente costa `1,5 · c` €/mese: con `c = 0,10 €` il costo pareggia
  il ricavo in ~23 mesi; con `c = 0,30 €` in ~8 mesi.
- **Modello consigliato (deciso ora, confermato in S-60u con il preventivo):**
  1. **v1 incluso nel prezzo** con limiti: massimo **2 banche per utente**, tetto globale `max_active_links` (50 all'inizio), aggiornamenti al massimo ogni 6 h.
  2. Se `c ≤ 0,10 €/conto/mese` e la fattura minima è coperta dalle vendite: resta incluso.
  3. Altrimenti: **«Pass collegamento bancario 12 mesi» facoltativo, non rinnovabile automaticamente** (acquisto in-app di tipo «non-renewing subscription» /
     prodotto a tempo su Play), prezzo = costo annuo stimato con margine. **Non è un abbonamento**: non si rinnova da solo; l'app base resta 4,99 € una tantum.
     È un progetto separato (S-61), da non costruire ora (niente funzioni «per il futuro»).
  Scartati: abbonamento mensile automatico (contro la richiesta di Matteo), prezzo dell'app più alto per tutti (fa pagare chi non collega banche), collegamento
  gratuito illimitato (insostenibile per qualunque `c` > 0).

### 12.3 Decisioni (riportate in `.cantiere/DECISIONI.md`)
Enable Banking (piano B Salt Edge) · solo AIS, solo conti personali · una Edge Function proxy senza salvataggio di dati bancari · sigilli AES-GCM legati
all'utente al posto dell'ID di sessione · movimento importato = `Transaction` con UUID v5 deterministico (nessun campo nuovo sui modelli esistenti) ·
3 entità sincronizzate + 1 locale, senza relazioni · doppioni sempre confermati dall'utente con soglie esatte · pendenti mai importati · nessuna
modifica/cancellazione automatica · saldo iniziale calcolato solo per conti nuovi · solo valuta dell'app · un consenso per banca condiviso tra
dispositivi · percorso unico con e senza Protezione avanzata (transito in memoria, entità nel vault) · scollegare non cancella i movimenti importati
(salvo scelta) · browser di sistema + Universal/App Link + ritorno di riserva con verificatore tipo PKCE · niente webhook, niente background ·
interruttori compilati spenti + interruttore server solo per spegnere · approvazione visiva sostituita da test UI e screenshot (libertà di Matteo).

### 12.4 Stima
19 task di Claude Code (S-60a…q, s, v) da 1–2 ore ≈ **30–35 ore di lavoro dell'agente** + 4 collaudi di blocco (~30 min ciascuno) + Commissione.
Con sessioni corte (una per task, `/clear` in mezzo): **circa 24–27 sessioni**, ragionevolmente **8–10 giorni** di quota Claude, da iniziare **dopo S-50**.
Task più pesanti di contesto: S-60b, S-60h, S-60j, S-60n (leggere solo le parti necessarie dei file lunghi).
Matteo: S-60t ~30 min + attese; S-60r ~40 min; S-60u ~30 min (+ tempi di contratto e revisione degli store).

### 12.5 Cosa NON fare
- Non mettere mai chiavi del fornitore, `BANK_SERVER_SECRET`, `session_id`, `uid` o IBAN completi nell'app, nel repository, nei log o nei documenti.
- Non salvare dati bancari sul server fuori dalla sync dell'utente; non loggare corpi delle richieste.
- Non aggiungere campi a `Transaction`/`Account` né colonne a `mt_transactions`; non modificare file esistenti di `Domain/`, i calcoli, i test esistenti.
- Non importare movimenti `pending`; non fondere doppioni senza conferma; non modificare né cancellare movimenti esistenti in automatico; non toccare `initialBalance` di conti esistenti.
- Non usare WebView per l'autenticazione bancaria; non includere analytics nella pagina di ritorno.
- Non aggiungere aggiornamenti in background, webhook, PIS, conti aziendali, conversioni di valuta, acquisti in-app (S-61 eventuale).
- Non accendere gli interruttori prima di S-60v; non spegnerli dopo una pubblicazione; non usare l'interruttore server per accendere funzioni non viste dalla revisione.
- Non usare Supabase vero, service role o Enable Banking vero nei task autonomi; non fare push del codice o del sito senza Matteo.
- Non promettere sul sito ciò che il §8.4 vieta.
