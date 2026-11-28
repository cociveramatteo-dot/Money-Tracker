# Progetto S-80 — Spese divise e crediti da recuperare (iOS + Android)

> Architetto (Claude Code · Opus), 2026-11-28. Approvato da Matteo come idea; questo documento va approvato (S-80q) prima del codice.
> **Quando:** DOPO il redesign «Sentiero», su un ramo separato `feature-split` creato da `main` quando Sentiero è stato unito.
> **Per chi esegue:** questo file è autosufficiente. Leggi la sezione del tuo task + §1–§5 (regole e modello). Non serve la chat.
> Decisione registrata in `.cantiere/DECISIONI.md` «2026-11-28 · S-80».

---

## 0. Indice
1. Obiettivo · 2. Decisioni · 3. Modello dati · 4. Regole di calcolo · 5. Stati e transizioni · 6. Flussi UI ·
7. Casi limite · 8. Impatti per modulo · 9. Migrazione · 10. Sync · 11. Android · 12. i18n · 13. Sicurezza ·
14. Invarianti e piano di test · 15. Task S-80…

---

## 1. Obiettivo

L'utente paga 80 € una cena per tre e deve ricevere 60 € dagli altri. Oggi l'uscita da 80 € gonfia statistiche, budget e
previsioni. Con la funzione:
- il **saldo attuale** resta quello vero della banca (80 € sono usciti davvero, i rimborsi entrano davvero quando arrivano);
- le **statistiche** contano da subito solo la quota dell'utente (20 €); i rimborsi non sono «entrate»;
- la **previsione / «a conti fatti»** mostra in una riga a parte «+60 € da recuperare»;
- l'utente segue chi gli deve cosa, registra gli incassi (anche su un altro conto), chiude, archivia, manda promemoria.

Fuori dalla v1 (ma il modello è predisposto): **debiti** (qualcuno ha pagato per te), **ricorrente + diviso** (affitto,
abbonamenti condivisi), widget, Siri/App Intents che creano spese divise, accesso alla rubrica.

---

## 2. Decisioni

### 2.1 Vincolanti (di Matteo, non si discutono)
- **D1 Saldo attuale reale.** Il credito entra solo nel «a conti fatti»/previsto, con riga esplicita «+X da recuperare».
- **D2 Statistiche.** L'uscita conta subito per la sola quota dell'utente; i rimborsi muovono il saldo ma NON sono entrate
  nelle statistiche (nessun effetto sul mese in cui arriva il rimborso).
- **D3 Archiviazione.** La parte non recuperata torna a carico della spesa originale, nel MESE DELLA SPESA (retroattivo).
- **D4 Partecipanti in v1.** Per persona: nome (opzionale → «Persona 1, 2…»), dovuto, ricevuto. Niente Contatti: testo
  libero con suggerimenti dai nomi già usati.
- Selettore «Tipo» nel form: **Normale · Ricorrente · Diviso con altri**, esclusivi in v1. «Spesa fissa» resta compatibile
  con Normale e Diviso.

### 2.2 Decisioni dell'architetto (con motivo e alternative scartate)

| # | Decisione | Perché | Scartato |
|---|---|---|---|
| A1 | **Nessun campo nuovo su `Transaction`.** Due modelli nuovi: `Split` (la divisione, con i partecipanti in JSON) e `SplitPayment` (un incasso o una compensazione). Il collegamento sta dal lato nuovo: `Split.expenseTransactionId`, `SplitPayment.transactionId`. | `Transaction` è in tutte le zone intoccabili (sync, E2E, export, ricorrenze, Android). Un client vecchio che riscrive un movimento (in E2E il payload è riscritto per intero) cancellerebbe i campi nuovi. Così i vecchi client non perdono nulla. | Campi `splitId/participantId` su `Transaction` (rischio perdita dati con client vecchi, migrazione su tabella grande); tutto in un JSON dentro la spesa. |
| A2 | **Incassi in tabella propria** (una riga per incasso), partecipanti in JSON dentro `Split`. | Due telefoni che registrano incassi offline in parallelo creano righe diverse: la sync a tre vie (S-51d) le tiene entrambe. I partecipanti si modificano di rado e da un solo posto. | Incassi nel JSON dello split (l'ultimo che scrive vince → un incasso perso ma il movimento di entrata resta: statistiche sbagliate in silenzio). Terza tabella per i partecipanti (più SQL e sync senza vantaggio reale). |
| A3 | **Il movimento di entrata è la verità sui soldi.** L'importo di un incasso «con denaro» è l'importo del suo movimento collegato, se esiste, è un'entrata, è fatto (`isDone`) e non è un trasferimento. Se il movimento manca o non è valido, l'incasso **non conta** (ignorato, non cancellato). | Chi modifica/cancella il rimborso da Movimenti (anche da un client vecchio o da un altro telefono) ricalcola il credito da solo, senza codice di sincronizzazione speciale. | Copiare l'importo nell'incasso e tenerli allineati (due verità, divergono). |
| A4 | **Tutto ciò che si può derivare non si salva.** «Saldato automatico», residuo, quota in parti uguali, validità: calcolati ogni volta da una funzione pura. Si salvano solo le scelte dell'utente (persone, quote personalizzate, «saldato a mano», «archiviato»). | Nessun conflitto di sync su valori calcolati; cancellare un incasso riapre il credito da solo. | Campo `status` scritto a ogni incasso. |
| A5 | **Rimborso oltre il dovuto: si accetta.** La parte in più («eccedenza») conta come **entrata normale** nelle statistiche, nel mese del rimborso; nessun credito negativo. Lo stesso vale se l'utente riduce la spesa dopo aver incassato. Il foglio incasso avvisa prima di salvare. | È denaro in più vero (mancia, arrotondamento); una sola regola copre anche la modifica al ribasso. Nessun dato perso, nessun blocco. | Bloccare l'importo (il bonifico vero da 25 € andrebbe spezzato in due movimenti); aumentare la quota degli altri. |
| A6 | **Resto dei centesimi:** in parti uguali lo assorbe l'utente se è incluso (gli altri pagano il valore arrotondato per difetto); se l'utente non è incluso, il centesimo in più va ai primi partecipanti in ordine di lista. | Non si chiede mai a un amico un centesimo in più di quanto pagherebbe l'utente; risultato deterministico. | Arrotondamento bancario (somma ≠ totale). |
| A7 | **Impostazione globale** «Includi i crediti nelle previsioni» (predefinita: sì). Niente interruttore per singolo credito: per escluderne uno si usa «Archivia». | Un interruttore per credito duplica l'archiviazione e confonde. | Toggle per credito. |
| A8 | **Il credito segue il conto della spesa** per il «a conti fatti»: conta nel totale solo se il conto della spesa è incluso nel totale. Non si mostra sulla «→» del singolo conto (non si sa su che conto arriverà). | Il −80 di un conto escluso non è nel totale: il +60 non deve esserci. | Credito sempre nel totale; credito sulla «→» del conto della spesa. |
| A9 | **Cancellare una spesa divisa con incassi:** si chiede sempre all'utente: «Elimina anche i rimborsi» oppure «Tieni i rimborsi come entrate normali». Ogni cancellazione «indiretta» (conto eliminato, altro telefono, client vecchio) **stacca**: i rimborsi restano entrate normali, lo split resta orfano e ignorato. | Mai cancellare denaro reale senza conferma. | Cancellazione a cascata automatica. |
| A10 | **Orfani ignorati, mai cancellati in automatico** in v1 (split senza spesa, incassi senza split o senza movimento). Si eliminano solo nei percorsi espliciti dell'utente. | Durante la sync un pezzo può arrivare prima dell'altro; cancellare un «orfano» momentaneo distruggerebbe dati. Righe piccole, nessun danno. | Raccolta automatica degli orfani. |
| A11 | **Divisione ammessa solo su uscite singole:** non su entrate, trasferimenti, movimenti di una serie ricorrente (`templateId` o `recurringFrequency` non vuoti). | L'editor delle serie (`Domain/RecurringSeriesEditor.swift`) cancella e ricrea copie: lo split resterebbe orfano. Ricorrente+diviso è v2 con modello dedicato. | Permetterlo su occorrenze materializzate. |
| A12 | **Incassi solo con data fino a oggi.** | Si registra denaro già arrivato; con S-73c una data futura creerebbe un movimento pianificato che non deve contare come ricevuto. | Incassi futuri «promessi». |
| A13 | **Contanti:** esiste già il tipo conto `AccountType.contanti`. Nel foglio incasso, se l'utente non ha un conto contanti, l'elenco conti ha in fondo «+ Crea conto Contanti» (saldo iniziale 0, crea e seleziona). | Riusa la creazione conto esistente; il denaro contante resta tracciato. | Incasso senza conto (rompe il saldo reale). |
| A14 | **Compatibilità in avanti:** ogni `Split` ha `schemaVersion` (v1 = 1) e `direction` (`credit` in v1). Un client che trova `schemaVersion` maggiore o una `direction` sconosciuta mostra lo split in sola lettura, non lo modifica, non lo conta. | Quando arriveranno debiti e ricorrente+diviso, i client v1 non devono rovinare i dati. | Nessuna versione. |
| A15 | **Server senza tabelle nuove:** se Supabase risponde «tabella inesistente» per `mt_splits`/`mt_split_payments` (o il vault rifiuta il `kind`), la sync **salta solo quelle due tabelle**, tiene i dati in locale e riprova alla sync successiva; le altre tabelle si sincronizzano normalmente. | L'app può uscire prima che Matteo esegua l'SQL senza bloccare tutto. | Legare la release all'SQL. |

### 2.3 Da confermare con Matteo (S-80q) — con raccomandazione
- **Q1 Totali in Movimenti e «Fisse del mese» in Home:** contano la quota (come le statistiche) — **consigliato**, coerente con D2 — oppure l'importo pieno pagato? La riga del singolo movimento mostra comunque l'importo pieno.
- **Q2 Eccedenza (A5):** conferma che i soldi in più ricevuti contano come entrata normale.
- **Q3 Promemoria:** notifica predefinita spenta; scelte 7 / 14 / 30 giorni. Consigliato così.
- **Q4 Mockup (D-014):** approvare le schermate di S-80m prima del codice UI.

---

## 3. Modello dati

### 3.1 iOS — SwiftData (nuovi file in `MoneyTracker/Models/`, nessun modello esistente cambia)

```swift
@Model final class Split {
    var id: UUID
    var expenseTransactionId: UUID      // la spesa pagata dall'utente (Transaction.id)
    var direction: String               // "credit" (v1). Riservato: "debt"
    var schemaVersion: Int              // 1
    var mode: String                    // "equal" | "custom"
    var includeMe: Bool                 // l'utente è una delle parti (default true)
    var participantsJSON: String        // [SplitParticipant] codificato (vedi sotto)
    var archivedAt: Date?               // non nil = archiviato ("mi arrendo")
    var ruleId: UUID?                   // riservato v2 (ricorrente+diviso), sempre nil in v1
    var createdAt: Date
}

struct SplitParticipant: Codable, Hashable, Identifiable {
    var id: UUID
    var name: String                    // "" = senza nome → «Persona N» calcolato a video
    var owed: Decimal?                  // solo in mode "custom"; nil in "equal"
    var settledAt: Date?                // «saldato a mano»: il residuo è perdonato
    var order: Int                      // posizione nella lista (resto centesimi, Persona N)
}

@Model final class SplitPayment {
    var id: UUID
    var splitId: UUID
    var participantId: UUID?            // nil = «altri incassi» (vedi §7 caso 33)
    var kind: String                    // "money" | "offset" (compensato, senza denaro)
    var amount: Decimal                 // per "offset" è la verità; per "money" è solo copia informativa (A3)
    var transactionId: UUID?            // obbligatorio per "money", nil per "offset"
    var date: Date
    var createdAt: Date
}
```
- Riferimenti tramite `UUID` semplici, **nessuna `@Relationship`** verso `Transaction` (non cambia lo schema di `Transaction`,
  come `transferGroupId`). `Split ↔ SplitPayment` collegati per `splitId` (niente relazione SwiftData: sync per ID).
- `participantsJSON` codificato con encoder dedicato (chiavi ordinate, `Decimal` come stringa per non perdere precisione;
  cfr. S-16), limite 50 partecipanti.
- Schema: **`SchemaV4`** = modelli di V3 + `Split` + `SplitPayment`, stadio `lightweight` V3→V4 in
  `Persistence/SchemaMigration.swift` (§9).

### 3.2 Android — Room
- `SplitEntity` (`splits`) e `SplitPaymentEntity` (`split_payments`) con gli stessi campi (UUID come `String` minuscola,
  `Decimal` come `String` come per gli altri importi di `data/Entities.kt`, date in millisecondi).
- Indici: `split_payments(splitId)`, `splits(expenseTransactionId)` unico.
- Nuova versione del database = versione attuale + 1, migrazione additiva `CREATE TABLE` in `data/Migrations.kt`.

### 3.3 Supabase (righe in chiaro) e vault (E2E)
| Tabella | `kind` nel vault | Colonne (snake_case, tutte anche dentro il payload cifrato) |
|---|---|---|
| `mt_splits` | `split` | id, user_id, expense_transaction_id, direction, schema_version, mode, include_me, participants (testo JSON), archived_at, rule_id, created_at |
| `mt_split_payments` | `split_payment` | id, user_id, split_id, participant_id, kind, amount, transaction_id, date, created_at |

Nessuna foreign key verso `mt_transactions` (in E2E non esisterebbe comunque): l'integrità è garantita dalle regole A3/A10.

---

## 4. Regole di calcolo (funzione pura, identica iOS/Android)

File: iOS `MoneyTracker/Splits/SplitMath.swift` (cartella nuova, solo logica pura su struct, nessun SwiftData);
Android `domain/SplitMath.kt`. Ingresso: istantanee (`SplitSnapshot`, `PaymentSnapshot`, `TxSnapshot`), uscita:
`SplitResult` per split + `SplitIndex` per i consumatori. Ordinamento stabile ovunque: `(date, createdAt, id)`.

Notazione: `A` = importo della spesa; `P` = partecipanti (gli altri, mai l'utente); `N = |P| + (includeMe ? 1 : 0)`;
`u` = unità minima della valuta (`10^-cifre` della valuta corrente, da `NumberFormatter` con `currencyCode`; EUR 0,01,
JPY 1); `floor_u(x)` = arrotonda per difetto al multiplo di `u`.

### 4.1 Dovuto
- **mode = equal:** `q = floor_u(A / N)`, `r = A − q·N` (multiplo di `u`, `0 ≤ r < N·u`).
  - `includeMe`: ogni `p ∈ P` deve `q`; l'utente `q + r` (A6).
  - `!includeMe`: i primi `r/u` partecipanti per `order` devono `q + u`, gli altri `q`. Quota utente = 0.
- **mode = custom:** `owed_p` salvato per ciascuno; quota utente `M = A − Σ owed_p`.
- `O = Σ_{p∈P} owed_p` (totale da ricevere). Sempre `M = A − O`.

### 4.2 Validità (uno split non valido è ignorato nei conti e segnalato «Da sistemare»)
Valido ⇔ spesa esistente, `type == uscita`, `!isTransfer`, `templateId` e `recurringFrequency` vuoti, `A > 0`,
`|P| ≥ 1`, `N ≥ 2`, ogni `owed_p ≥ 0`, `O > 0`, `O ≤ A`, `direction == credit`, `schemaVersion ≤ 1`.
Il form impedisce di salvare uno split non valido; l'invalidità può nascere solo da modifiche esterne (client vecchio,
altro telefono) e si risolve dal dettaglio («Sistema»).

### 4.3 Ricevuto e applicato (per persona)
- Incasso **effettivo** `e(x)`: `offset` → `x.amount`; `money` → `tx.amount` se il movimento esiste, è `entrata`, `isDone`,
  `!isTransfer`; altrimenti 0 (ignorato, A3). Incassi con `amount ≤ 0` ignorati.
- Per ogni `p`, scorrendo i suoi incassi in ordine stabile: `applied(x) = min(e(x), owed_p − già_applicato_p)`;
  `excess(x) = e(x) − applied(x)`.
- `R_p = Σ applied` (ricevuto utile), `E = Σ excess` di tutti gli incassi (eccedenza, A5).
- Incassi con `participantId` nil o sconosciuto: dopo le persone, si applicano al residuo complessivo delle persone non
  saldate (in ordine di `order`), il resto è eccedenza.
- Le compensazioni (`offset`) non generano mai eccedenza: il foglio le limita al residuo; una parte in più arrivata via sync è scartata (non è denaro, non può essere un'entrata). `E` = solo eccedenze di incassi in denaro.
- `residuo_p = 0` se `settledAt != nil`, altrimenti `owed_p − R_p` (sempre ≥ 0).

### 4.4 Stato e credito
- `Archiviato` ⇔ `archivedAt != nil`. `Saldato` ⇔ non archiviato e ∀p `residuo_p = 0`. `Aperto` altrimenti.
- `ΣR = Σ_p R_p` (+ applicato degli «altri incassi»). `F = Σ_{p saldati a mano} (owed_p − R_p)` (perdonato).
- **Credito aperto** `C = O − ΣR − F` se non archiviato (= Σ residuo_p; vale 0 quando Saldato), `C = 0` se Archiviato.

### 4.5 Statistiche (D2, D3)
- **Spesa contata** (mese della spesa): **`S = A − ΣR − C`** in ogni stato. Quindi: aperto senza perdoni `S = A − O`;
  con persone saldate a mano il perdonato torna subito sulla spesa; Saldato o Archiviato `S = A − ΣR`
  (la parte non recuperata torna sulla spesa nel mese della spesa: D3 retroattivo).
- **Movimento di rimborso** (money valido): nelle statistiche entrate conta solo `excess(x)` nel mese del suo movimento;
  `applied(x)` non conta (né entrata né uscita).
- Compensazioni (`offset`): nessun movimento, nessun effetto su saldo; nelle statistiche valgono come ricevuto.
- Split non valido o orfano: tutto come oggi (spesa piena, rimborsi = entrate normali).
- Statistiche considerano come oggi solo i movimenti `isDone`.

### 4.6 Previsioni («a conti fatti», D1, A7, A8)
- `crediti = Σ C` degli split validi, Aperti, il cui conto spesa è incluso nel totale, e la cui spesa «conta» nella
  previsione del mese (`isDone`, oppure pianificata che passa `DashboardView.countsInProjection` / `HomeProjection` S-73).
- Se l'impostazione è accesa: **a conti fatti = valore di oggi + crediti**, con la riga «+crediti da recuperare» visibile.
- Saldo attuale, «→» del singolo conto, curva `BalanceTrail`: **invariati**.

### 4.7 Esempio di riferimento (vettore V1)
Cena 80,00 €, 3 parti, includeMe, equal → `q = 26,66`, `r = 0,02`: Marco 26,66, Anna 26,66, utente 26,68; `O = 53,32`;
`S = 26,68`. Marco rimborsa 30,00 su Conto B → applied 26,66, eccedenza 3,34 (entrata nel mese del rimborso),
`C = 26,66`. Anna «saldata a mano» senza pagare → Saldato, `F = 26,66`, `S = 80 − 26,66 − 0 = 53,34`, `C = 0`.
Saldo attuale: −80 + 30 = −50 (come la banca).

---

## 5. Stati e transizioni

```
            incassi coprono tutto            «Riapri» (toglie i settledAt)
  APERTO ─────────────────────────► SALDATO ───────────────────────────► APERTO
    │  ▲   «Saldato» (settledAt a tutti     │
    │  │    i residui > 0)                  │ «Archivia»
    │  └── incasso cancellato/ridotto ◄─────┤ (anche da Aperto)
    │      (derivato, automatico)           ▼
    └──────────── «Archivia» ─────────► ARCHIVIATO ── «Ripristina» (archivedAt = nil) ──► stato derivato
```
- Saldato automatico/riapertura automatica: derivati (A4), nessuna scrittura.
- «Saldato» per persona: `settledAt` sulla persona. «Saldato» del credito: `settledAt` a tutte le persone con residuo > 0.
- «Riapri» da Saldato: toglie tutti i `settledAt` messi a mano. Da Archiviato: «Ripristina».
- Archiviato non riceve incassi (il pulsante non c'è; un incasso arrivato via sync conta in `ΣR_p`).
- Eliminare: solo eliminando la spesa o con «Togli divisione» (§6.1).

---

## 6. Flussi UI (stile «Sentiero»)

Regole grafiche comuni: token `DS` di `Views/Theme.swift`, colori adattivi, mai `preferredColorScheme`, importi
`.monospacedDigit()`, Dynamic Type fino ad AX-XL, «oscura importi» rispettato ovunque (anche in condivisione e notifiche).
Semantica Sentiero: **verde pieno = ricevuto (reale)**, **ambra tratteggiata = da recuperare (atteso)**.
Icone: spesa divisa `person.2.fill` (diversa da `repeat` delle ricorrenze); rimborso `arrow.uturn.down`. Android: equivalenti
Material dalla tabella icone di `android-parita.md` §1.5 (aggiungere le due righe). Prima del codice: mockup S-80m (D-014).

### 6.1 Form movimento (`Views/AddTransactionView.swift`, Android `ui/forms/AddTransactionForm.kt`)
- Al posto della sezione ricorrenza: selettore segmentato **Tipo: Normale · Ricorrente · Diviso con altri**. «Diviso» è
  visibile solo per Uscita, non per Entrata né Trasferimento. «Spesa fissa» resta un interruttore indipendente (vale
  con Normale e Diviso). Scegliere Ricorrente nasconde il pannello divisione e viceversa.
- Pannello **Diviso** (componente riusabile `SplitEditor`, usato anche da «Segna come da rimborsare»):
  - in alto, grande: **Da ricevere `O`**; sotto: **Speso effettivamente (tua quota) `M`**;
  - «Includi me» (sì); «Persone» stepper (minimo 2 se includi me, 1 altrimenti; massimo 50; il numero comprende l'utente
    quando è incluso);
  - «Quota a testa» precompilata (`q`), modificabile: se l'utente la cambia (es. 27,00) la modalità diventa custom e
    tutti i partecipanti prendono quel valore, `M` si ricalcola;
  - lista partecipanti: nome (campo libero, suggerimenti dai nomi già usati, max 40 caratteri) e dovuto modificabile per
    persona (diventa custom); pulsante «Parti uguali» per tornare a equal;
  - messaggi di blocco (Salva disabilitato, motivo visibile sotto): «Servono almeno 2 persone», «La somma delle quote
    supera la spesa», «Quota non valida», «Importo della spesa mancante»; avviso non bloccante per nomi doppi.
- In **modifica** di una spesa divisa con incassi: riga «Già ricevuto X»; tipo (Uscita) e Tipo «Diviso» bloccati con
  spiegazione; se la modifica porta un dovuto sotto il già ricevuto → avviso «Y in più: conteranno come entrate» (A5).
  «Togli divisione»: se ci sono incassi, scelta «Tieni i rimborsi come entrate normali» / «Elimina anche i rimborsi» /
  Annulla. Rimuovere una persona con incassi non è possibile: «Marco ha già dato 20 €: elimina prima i suoi incassi».
- Salvataggio: un'unica `context.save()` per spesa + split (atomico); su Android una transazione Room.

### 6.2 Righe in Movimenti e Ultimi movimenti (`Views/Components/MovementRow.swift`, `TransactionsView.swift`, `DashboardView.swift`; Android `ui/screens/TransactionRow.kt`)
- Spesa divisa: importo pieno; icona `person.2.fill`; sottoriga «tua quota M»; barretta sottile sotto la riga:
  verde `ΣR_p`, ambra tratteggiata residuo, etichetta accessibile «Ricevuto X su O». Saldato: barra piena verde, spunta.
  Archiviato: barra grigia. Non valido: icona di avviso «Da sistemare».
- Rimborso: icona `arrow.uturn.down`, titolo salvato (es. «Rimborso · Regalo Leo · Marco»).
- Tocco su spesa divisa o rimborso: apre il dettaglio del credito (§6.4); la modifica del movimento resta nel menu/scorrimento come oggi.
- Scorrimento/menu contestuale «Segna come da rimborsare» sulle uscite ammesse (A11) senza split.
- Filtro **«Da rimborsare»** in `TxFilter` (Android: filtro in `MovementsScreen`): spese divise, con segmento Aperti ·
  Saldati · Archiviati (predefinito Aperti).

### 6.3 Home (`DashboardView.swift`, Android `HomeScreen`)
- Sezione a tendina **«Da recuperare»** sotto «Ultimi movimenti», visibile solo se esiste almeno un credito Aperto e valido.
  Intestazione: titolo + totale `Σ C` (ambra) + freccia; stato aperto/chiuso ricordato (`@AppStorage`). Contenuto: fino a
  5 crediti (nome spesa, data, barretta, residuo), «Vedi tutti» → filtro «Da rimborsare»; «Per persona» → §6.6.
  Stile simile alle card obiettivi di Pianifica.
- Hero «saldo atteso a fine mese»: se crediti > 0 e impostazione accesa, riga «+X da recuperare» e il totale «a conti fatti»
  lo include. Conti (`AccountsView`): intestazione «A conti fatti» = Σ conti + crediti con sottoriga «di cui X da recuperare»;
  la «→» dei conti non cambia.

### 6.4 Dettaglio credito (nuova `Views/Splits/SplitDetailView.swift`, Android `ui/screens/SplitDetailScreen.kt`)
- Testata: nome spesa, data, conto, totale `A`, tua quota `S`, barra, «Da recuperare C» o stato.
- Persone: nome, dovuto, ricevuto, residuo, stato; azioni per persona: «Registra incasso», «Promemoria» (§6.7), «Segna saldato»/«Riapri».
- Incassi: data, da chi, conto (o «Compensato»), importo, eccedenza evidenziata; scorrimento «Elimina» con conferma
  (elimina incasso + movimento collegato; per gli offset solo l'incasso).
- Azioni: «Saldato», «Archivia», «Riapri»/«Ripristina», «Modifica spesa», «Sistema» (solo se non valido: apre il form).
- Orfani: se la spesa non esiste più il dettaglio non è raggiungibile (A10).

### 6.5 Foglio «Registra incasso» (`Views/Splits/AddSplitPaymentSheet.swift`)
- Da chi (predefinita la prima persona con residuo), Importo (predefinito il suo residuo), Conto (predefinito il conto
  della spesa se non archiviato; elenco conti non archiviati; «+ Crea conto Contanti» se manca, A13), Data (≤ oggi,
  predefinita oggi), interruttore «Senza movimento di denaro (compensato)» che nasconde il conto.
- Avviso eccedenza: «Marco deve ancora 20 €: i 5 € in più conteranno come entrata».
- Salvataggio atomico: crea il `Transaction` entrata (`name` = «Rimborso · <nome spesa> · <nome persona>» nella lingua
  corrente, stessa categoria e icona della spesa, `isDone = true`, `notes` vuote) + `SplitPayment(kind: money,
  transactionId)`. Offset: solo `SplitPayment(kind: offset)`.

### 6.6 Riepilogo per persona (`Views/Splits/SplitPeopleView.swift`)
- Raggruppa per nome normalizzato (spazi tolti, maiuscole/accenti ignorati); senza nome non si raggruppa (resta per spesa).
- Riga: «Marco ti deve 45,00 € su 3 spese», tocco → elenco spese; pulsante condividi.

### 6.7 Promemoria e notifica
- Condividi (`ShareLink` / Android `Intent.ACTION_SEND`): testo localizzato, esempio it:
  «Ciao Marco! Per «Regalo Leo» del 12/11 mi devi ancora 20,00 €. Grazie!». Più spese: elenco puntato e totale.
  Con «oscura importi» acceso si condivide comunque l'importo (è un'azione esplicita), ma l'anteprima a video resta oscurata.
- Notifica locale (impostazione, predefinita spenta; 7/14/30 giorni): una per credito, alla data `max(createdAt, data spesa)
  + X giorni` alle 10:00; annullata se il credito si chiude, si archivia o si elimina; riprogrammata all'avvio. Testo senza
  importi se «oscura importi» è acceso. Identificatore `split-<uuid>`.

### 6.8 Impostazioni (`SettingsView.swift`, Android impostazioni)
- Sezione «Crediti da recuperare»: «Includi nelle previsioni» (sì), «Promemoria crediti aperti» (Spento/7/14/30 giorni).
  Chiavi `UserDefaults`/`AppPrefs`: `splits.includeInForecast`, `splits.reminderDays`. Impostazioni locali al dispositivo (non sincronizzate).

---

## 7. Casi limite (caso → comportamento deciso)

| # | Caso | Comportamento |
|---|---|---|
| 1 | 80 / 3 (centesimi) | Regola A6: 26,66 · 26,66 · utente 26,68. Somma sempre = A. |
| 2 | Utente non incluso, 80 / 3 | 26,67 · 26,67 · 26,66 (primi in lista +0,01); quota utente 0; S = 0 finché aperto. |
| 3 | Quota arrotondata dall'utente (27 × 2 su 80) | custom; M = 26; se Σ > A blocco «La somma delle quote supera la spesa». |
| 4 | Una persona con dovuto 0 | Ammessa (invitato); serve O > 0; risulta subito saldata. |
| 5 | Rimborso > dovuto | A5: applied fino al dovuto, eccedenza = entrata nel mese del rimborso, avviso prima di salvare. |
| 6 | Spesa ridotta dopo incassi (ricevuto > nuovo dovuto) | Avviso nel form; dopo il salvataggio l'eccesso diventa eccedenza (A5); nessun valore negativo. |
| 7 | Spesa aumentata dopo incassi | equal: ricalcolo automatico; custom: quote invariate, M cresce. |
| 8 | Persone cambiate dopo incassi | Aggiungere: libero. Rimuovere una persona con incassi: bloccato con messaggio. |
| 9 | Compensazione senza denaro | `offset`: conta come ricevuto, saldo invariato, nessun movimento. |
| 10 | Ti danno 1 € in meno e accetti | «Segna saldato» sulla persona: residuo perdonato, torna sulla spesa nel mese della spesa (S = A − ΣR). |
| 11 | Archivia | C = 0, S = A − ΣR nel mese della spesa (retroattivo), visibile in «Archiviati». Ripristinabile. |
| 12 | Cancello la spesa con incassi | Domanda A9 (tieni come entrate / elimina anche i rimborsi). Split e incassi eliminati in entrambi i casi. |
| 13 | Cancello un rimborso da Movimenti | Conferma «È il rimborso di Marco per «Regalo Leo»: il credito tornerà a X»; elimina movimento + incasso; credito si riapre (derivato). |
| 14 | Modifico a mano l'entrata generata (importo) | Vale il nuovo importo (A3); il form mostra la fascia «Rimborso collegato a «…»» con «Scollega»; tipo bloccato su Entrata. |
| 15 | Entrata generata resa pianificata, trasformata in uscita/trasferimento (client vecchio o altro telefono) | L'incasso non conta finché il movimento non torna entrata fatta (A3). |
| 16 | «Scollega» un rimborso | Elimina l'incasso, il movimento resta entrata normale. |
| 17 | Spesa spostata su un altro conto | Nessun effetto sul credito; per A8 conta l'inclusione del nuovo conto. |
| 18 | Rimborso su conto diverso | Normale (scelta nel foglio). |
| 19 | Conto della spesa eliminato | Cascade esistente elimina la spesa → split orfano ignorato (A10). La conferma di eliminazione conto aggiunge «Contiene N spese divise e M rimborsi»; in quel percorso split/incassi collegati si eliminano (percorso esplicito). Rimborsi su altri conti restano entrate normali. |
| 20 | Conto di un rimborso eliminato | Il movimento sparisce → incasso ignorato → credito si riapre. Nel percorso esplicito si elimina anche l'incasso. |
| 21 | Conto archiviato | Split e incassi esistenti invariati; il conto non compare tra le destinazioni di nuovi incassi. |
| 22 | Conto escluso dal totale | Credito fuori dal «a conti fatti» se la spesa è su quel conto (A8); statistiche come gli altri movimenti di quel conto oggi. |
| 23 | Valute | L'app ha una valuta unica globale (`currencyCode`); split usa la stessa. Cambiare valuta non converte nulla (come oggi). `u` dalla valuta corrente; per valute senza decimali A6 lavora a unità. |
| 24 | Spesa con data passata | Normale; statistiche nel suo mese. |
| 25 | Spesa con data futura (pianificata, S-73c) | Split ammesso; credito nella previsione solo dove la spesa conta (§4.6); statistiche quando diventa fatta; incassi ammessi (amico che paga prima). |
| 26 | Incasso con data futura | Non selezionabile (A12). Via sync da client che lo permettesse: il movimento sarebbe pianificato → non conta finché non è fatto. |
| 27 | Incasso con data precedente alla spesa | Ammesso (anticipo). |
| 28 | Importo zero/negativo | Spesa: > 0 (regola esistente). Quote ≥ 0. Incasso > 0. Valori ≤ 0 da sync ignorati. |
| 29 | Importi enormi | Limite 1.000.000.000 (come `WhatIfScenario.amount`) per spesa, quote e incassi; Decimal ovunque, mai Double nei calcoli. |
| 30 | Persone duplicate | Ammesse (ID diversi), avviso nel form; nel riepilogo per persona si sommano per nome normalizzato. |
| 31 | Nome vuoto | «Persona N» calcolato a video con `order` nella lingua corrente (cambio lingua ok). Il titolo del rimborso usa il nome al momento. |
| 32 | Cambio lingua | Testi calcolati a video si traducono; titoli dei rimborsi già creati restano com'erano (come ogni nome salvato). |
| 33 | Incasso di una persona rimossa altrove (conflitto sync) | Va negli «altri incassi»: si applica al residuo complessivo, poi eccedenza (§4.3). Mostrato nel dettaglio come «Altri incassi». |
| 34 | Due telefoni registrano incassi in parallelo/offline | Righe distinte, entrambe tenute (S-51d); se superano il dovuto → eccedenza + avviso nel dettaglio «Ricevuto più del dovuto». |
| 35 | Due telefoni modificano lo split (persone) in parallelo | Vince l'ultimo che sincronizza (riga intera); incassi salvi (tabella propria); persone sparite → caso 33. |
| 36 | Spesa eliminata su A, incasso registrato offline su B | Dopo la sync: spesa e split assenti, incasso orfano ignorato, entrata di B resta entrata normale (denaro vero). |
| 37 | Split arriva prima della spesa (o viceversa) | Orfano momentaneo ignorato, si «accende» quando arriva l'altro pezzo (A10). |
| 38 | Offline | Tutto locale; sync quando torna la rete come gli altri dati. |
| 39 | Server senza tabelle nuove | A15: salta solo quelle tabelle, ritenta dopo. |
| 40 | Client vecchio (non aggiornato) su un altro dispositivo | Non vede split: spesa piena e rimborsi come entrate (degradazione accettata); non può rovinare gli split (A1). Le sue modifiche a spese/rimborsi sono gestite da A3 e §4.2. |
| 41 | Chi aggiorna l'app con dati vecchi | Migrazione additiva vuota: zero split, tutti i numeri identici a prima (invariante I6). Nessuna euristica sui rimborsi passati. |
| 42 | Split futuro (`schemaVersion` 2, `debt`) visto da v1 | Sola lettura, non conta, non si modifica (A14). |
| 43 | Trasferimenti | Non dividibili; un rimborso non può essere un trasferimento. |
| 44 | Movimento ricorrente | Non dividibile in v1 (A11); la voce «Segna come da rimborsare» non compare. |
| 45 | Siri / Comandi | Creano spese normali; si possono dividere dopo con «Segna come da rimborsare». |
| 46 | Export JSON/CSV/PDF | §8 «Export». Import (S-71) dovrà includere `splits` e `splitPayments` (requisito scritto in S-71p). |
| 47 | Logout / cambio utente / elimina account | `clearLocalStore` elimina anche `Split` e `SplitPayment`; la cancellazione account lato server cancella anche `mt_splits`, `mt_split_payments` e i `kind` nuovi del vault. |
| 48 | Attivazione/disattivazione Protezione avanzata | Migratore E2E copia/ripristina anche i due `kind` nuovi (stessa procedura delle altre tabelle). |
| 49 | Modalità demo | Seeder con 2 crediti (uno aperto con un incasso, uno saldato) per schermate e social. |
| 50 | Divido una spesa già esistente vecchia di mesi | Ammesso; statistiche di quel mese cambiano (ricalcolo, come D3). |
| 51 | Due split sulla stessa spesa (conflitto sync) | Vince lo split con `createdAt` più vecchio (poi `id`); l'altro ignorato e mostrato «Da sistemare» nel dettaglio con «Elimina duplicato». |
| 52 | Molti crediti (100+) | Indice calcolato una volta per render con cache a impronta (come `projectionCache`), O(n). |
| 53 | Budget per categoria / notifiche budget | Usano la spesa contata `S` (stessa regola delle statistiche). |
| 54 | Statistiche per conto | La quota `S` resta sul conto della spesa; l'eccedenza sul conto del rimborso. |

---

## 8. Impatti per modulo

> Zone normalmente intoccabili toccate da questa funzione (vanno autorizzate da Matteo con S-80q): `Models/` (solo file
> nuovi), `Persistence/SchemaMigration.swift` (solo V4), `Sync/` (tabelle nuove), `Export/PDFReportGenerator.swift`,
> `Domain/NotificationManager.swift` (budget usa `S` + promemoria crediti). `Domain/AccountBalanceCache`, `BalanceTrail`,
> `Transaction`, `Account`, ricorrenze, Auth, Intents: **non si toccano**.

**Punto unico per i consumatori:** `SplitIndex` (iOS `Splits/SplitIndex.swift`, Android `domain/SplitIndex.kt`) costruito da
`SplitMath` con tutti split/incassi/movimenti, esposto con:
`statsAmount(of tx) -> Decimal` (uscita divisa → `S`; rimborso → `excess`; altro → `tx.amount`),
`isSplitExpense(tx)`, `isReimbursement(tx)`, `result(for splitId)`, `openCredits(includedAccountIds, projectionDay)`.
Con zero split restituisce sempre `tx.amount` (I6). Un consumatore = una sostituzione `t.amount` → `index.statsAmount(t)`.

| Modulo | iOS | Android | Cosa |
|---|---|---|---|
| Statistiche | `Views/StatisticsView.swift` | `domain/Statistics.kt`, `ui/screens/StatisticsScreen.kt` | `statsAmount` per totali, categorie, mesi |
| Budget | `Views/BudgetView.swift:337`, `Views/PianificaView.swift:56`, `Domain/NotificationManager.checkBudgets` | `domain/Budgeting.kt`, `domain/NotificationRules.kt` | idem |
| Totali Movimenti | `Views/MovementSectionTotals.swift` | equivalente in `MovementsScreen` | idem (Q1) |
| Fisse del mese | `DashboardView.monthlyFixed*Total` (righe 66-77) | `HomeScreen` | idem (Q1) |
| Abitudini | `Views/HabitsView.swift` (verificare cosa somma) | equivalente | idem se somma importi |
| Previsione Home / Conti / E se | `DashboardView` hero, `AccountsView` intestazione, `MonthlyPlannedBalance` invariato | `HomeProjection.kt`, `AccountsScreen`, `WhatIfScenario.kt` | riga crediti §4.6, solo totali |
| Saldo | `AccountBalanceCache` | `domain/Balance.kt` | **nessuna modifica** |
| Righe | `MovementRow`, `TransactionsView`, `DashboardView` | `TransactionRow.kt` | icona, sottoriga, barra |
| Eliminazioni | tutti i `context.delete` di movimenti: `DashboardView.swift:450,465`, `TransactionsView.swift:579-582`, `RecurringSeriesDetailView.swift:103` (ricorrenti: mai split, nessun effetto), `AddTransactionView.swift:448`, eliminazione conto | `TransactionOps.kt`, `Repository.kt` | passare da `SplitDeletion` (helper unico) che applica A9 |
| Sync | `SyncService.swift` (`SBSplit`, `SBSplitPayment`, upload/download, baseline), `SyncService+E2E.swift`, `Sync/E2E/SyncRemote.swift` (`SyncTable` +2 casi), migratore E2E | `sync/SyncMapper.kt`, `sync/SyncEngine.kt`, `SyncService.kt` | §10 |
| Export | `SettingsView` (`GDPRExport` + `splits`, `splitPayments`; CSV + colonne in coda `split_role`, `personal_share`), `PDFReportGenerator` (totali con `S`, riga «Da recuperare») | `data/JsonExport.kt`, `domain/Exports.kt`, `domain/PdfReport.kt` | campi nuovi opzionali, in coda |
| Notifiche | `NotificationManager` (+ promemoria crediti) | `NotificationRules.kt` + scheduler | §6.7 |
| Demo | `Debug/DemoDataSeeder.swift` | `data/DemoData.kt` | caso 49 |
| Documento master | `docs/MoneyTracker.md` | — | sezione nuova al checkpoint |

---

## 9. Migrazione

- **iOS:** `SchemaV4` (V3 + `Split` + `SplitPayment`), `MigrationStage.lightweight(V3→V4)`, `SchemaV3` resta com'è
  (punta ai modelli live: verificare che V3 elenchi gli stessi modelli di prima; se SwiftData richiede modelli congelati per
  V3, congelare una copia come fatto per V1). Test: store V3 su disco con dati di prova → apertura V4 → conteggi e importi
  identici, zero split. Store App Group condiviso (`Persistence/SharedStore.swift`): stessa migrazione.
- **Android:** versione Room +1, `CREATE TABLE` additivi + indici; test con `MigrationTestHelper` su un database della
  versione precedente.
- Nessuna conversione di dati esistenti. Nessuna euristica.

---

## 10. Sync

- **SQL (Matteo, una volta, S-80d):** script idempotente e reversibile che crea `mt_splits` e `mt_split_payments` con le stesse
  regole RLS di `mt_transactions` (`user_id = auth.uid()` per select/insert/update/delete), indice `(user_id, id)`,
  estende il `check` di `mt_vault.kind` a `('account','transaction','budget','goal','rule','split','split_payment')`,
  aggiunge alle due tabelle la stessa guardia `bt_e2e_active` delle altre `mt_*` (S-50q) e aggiorna la funzione/percorso
  di cancellazione account. Script di ritorno separato. Server finto `03_CODICE/bucktrail-android/scripts/fake-supabase.py`
  esteso con le due tabelle.
- **Protocollo:** identico alle tabelle esistenti: merge a tre vie con base per tabella (S-51d,
  `Sync/SyncBaseline.swift`), upsert completo (`fullUpsert = true`, righe piccole), pull = istantanea completa,
  cancellazione = riga assente, niente `updated_at`. Ordine: dopo `transactions`. Base persistita: aggiungere le due chiavi `kind`.
- **E2E:** due `kind` nuovi nel vault, payload con le stesse chiavi snake_case (§3.3), vettori di test condivisi estesi.
- **Tolleranza (A15):** errore «relation does not exist» / PostgREST 404 / violazione check `kind` → saltare le due
  tabelle con log senza dati, sync delle altre riuscita.
- **Conflitti:** casi 33–37, 51.
- **Client vecchi:** casi 40–42.

---

## 11. Android (parità)
Stessa logica (`SplitMath.kt` = traduzione 1:1 di `SplitMath.swift`), stessi vettori JSON di test (file canonico
`MoneyTrackerTests/Fixtures/split-vectors.json`, copia identica in `03_CODICE/bucktrail-android/app/src/test/resources/split-vectors.json`;
un test per piattaforma li esegue tutti; il guardiano confronta lo SHA dei due file). Stessa UI (Compose, token di
`android-parita.md` §1), stesse stringhe nelle 7 lingue. Aggiornare `android-parita.md` (§2 modello dati, §3 nuova
sottosezione «Spese divise», §1.5 icone).

---

## 12. i18n (7 lingue: it, en, de, es, fr, ja, zh-Hans)
Chiavi nuove (testo italiano di riferimento; traduzioni del redattore, poi giro tedesco AX-XL e giapponese per lunghezze):
Tipo · Normale · Ricorrente · Diviso con altri · Includi me · Persone · Quota a testa · Parti uguali · Da ricevere ·
Speso effettivamente (tua quota) · Persona %d · Servono almeno 2 persone · La somma delle quote supera la spesa ·
Quota non valida · Due persone con lo stesso nome · Già ricevuto %@ · %@ in più: conteranno come entrate ·
Togli divisione · Tieni i rimborsi come entrate normali · Elimina anche i rimborsi · %@ ha già dato %@: elimina prima i suoi incassi ·
tua quota %@ · Ricevuto %@ su %@ · Da sistemare · Segna come da rimborsare · Da rimborsare · Aperti · Saldati · Archiviati ·
Da recuperare · Vedi tutti · Per persona · +%@ da recuperare · di cui %@ da recuperare · Registra incasso · Promemoria ·
Segna saldato · Saldato · Archivia · Riapri · Ripristina · Modifica spesa · Sistema · Altri incassi · Ricevuto più del dovuto ·
Da chi · Conto · Data · Senza movimento di denaro (compensato) · Compensato · Crea conto Contanti ·
%@ deve ancora %@: i %@ in più conteranno come entrata · Rimborso · %@ · %@ (titolo) · È il rimborso di %@ per «%@»: il credito tornerà a %@ ·
Rimborso collegato a «%@» · Scollega · Contiene %d spese divise e %d rimborsi · %@ ti deve %@ su %d spese (plurali con
`.stringsdict` / `plurals`) · testo condivisione singolo e multiplo · Crediti da recuperare · Includi nelle previsioni ·
Promemoria crediti aperti · Spento · %d giorni · notifica: titolo e corpo con e senza importo.
Regola: nessuna stringa nel codice senza chiave; `E2ELocalizationTests`-like test che verifica la presenza delle chiavi in tutte e 7 le lingue.

---

## 13. Sicurezza (OWASP mobile, integrità dati)
- RLS su entrambe le tabelle; nessuna policy permissiva; `user_id` sempre del chiamante (test con utente B che legge A: 0 righe, nel server finto).
- I nomi delle persone sono dati personali di terzi: in E2E finiscono cifrati; mai nei log (`AuditLogger`/`os_log` solo id e conteggi); non nel testo delle notifiche se «oscura importi» è acceso.
- Input: lunghezze massime (nome 40, 50 persone, payload < 64 KiB), parse importi con `Decimal.parseAmount`, limite 1e9.
- Condivisione: solo testo, niente link, id o dati di altri crediti.
- Decoder JSON partecipanti tollerante: JSON rotto → split «Da sistemare», nessun crash.

---

## 14. Invarianti e piano di test

### 14.1 Invarianti (devono valere sempre; test di proprietà con generatore a seme fisso, 1000 casi per piattaforma)
- **I1 Saldo intatto:** `currentBalance` di ogni conto = somma dei movimenti fatti, qualunque operazione sugli split
  (creare, saldare, archiviare, compensare, eliminare split) non lo cambia; cambia solo creando/eliminando un movimento di rimborso, esattamente del suo importo.
- **I2 Somma quote:** in equal `Σ owed_p + quota_utente = A` esatta al centesimo; in custom `M = A − O ≥ 0` per ogni split valido.
- **I3 Limiti:** `0 ≤ R_p ≤ owed_p`, `residuo_p ≥ 0`, `excess ≥ 0`, `C ≥ 0`, `0 ≤ S ≤ A`.
- **I4 Conservazione:** per ogni split valido, con `Σe_money` = incassi in denaro effettivi e `R_off` = compensazioni applicate:
  `(A − Σe_money) − (S − E) = C + R_off` (flusso di cassa netto meno netto statistico = credito aperto + compensazioni).
  Inoltre `Σ applied + E = Σ effettivi in denaro + R_off applicate`.
- **I5 Statistiche senza split = identiche a prima** (golden test: stesso dataset demo, prima e dopo la funzione, ogni totale uguale).
- **I6 Previsione:** con impostazione accesa `aContiFatti_nuovo = aContiFatti_vecchio + crediti`; spenta = vecchio. «→» per conto invariata.
- **I7 Determinismo:** risultato indipendente dall'ordine di arrivo delle righe (permutazioni casuali) e identico iOS/Android (vettori condivisi).
- **I8 Idempotenza sync:** due pull consecutivi non cambiano nulla; un incasso conta una volta sola per `id`.
- **I9 Orfani innocui:** split/incassi orfani non cambiano alcun numero e non causano crash.

### 14.2 Unitari
- `SplitMathTests` (iOS) / `SplitMathTest` (Android): ogni regola §4, vettori V1… (minimo 25: casi 1–7, 9–11, 15, 23 JPY, 28, 29, 33, 34, 51), I1–I9.
- `SplitIndexTests`: consumatori (statistiche, budget, totali) con e senza split.
- Migrazione V3→V4 / Room N→N+1.
- Sync: `SplitSyncTests` con `SyncRemote` finto: creazione, cancellazione, incassi paralleli da due dispositivi, tabella mancante (A15), E2E (vault), baseline, `clearLocalStore`.
- Localizzazione: chiavi presenti in 7 lingue, plurali.
- Notifiche: programmazione/annullo.

### 14.3 UI (XCUITest / Compose)
- Crea spesa divisa 80/3 → Movimenti: icona, «tua quota 26,68», barra; Home: «Da recuperare 53,32», hero «+53,32 da recuperare».
- Registra incasso su altro conto → saldo di quel conto +X, Statistiche entrate invariate, credito ridotto.
- Eccedenza: avviso visibile, statistiche entrate + eccedenza.
- Saldato manuale, Archivia (statistiche del mese della spesa salgono), Riapri.
- Cancella spesa con incassi: le due scelte. Cancella rimborso da Movimenti: credito riaperto.
- Segna come da rimborsare su movimento esistente. Filtro Da rimborsare. Riepilogo per persona. Condivisione (foglio aperto).
- Blocchi del form (meno di 2 persone, somma > spesa).
- Light/dark, Dynamic Type AX-XL in tedesco, oscura importi, modalità demo, screenshot in `.cantiere/tmp/s80/`.

### 14.4 Stress test (skill `stress-test`, obbligatoria: soldi, sync, migrazione)
- 500 split, 5000 incassi: tempo di costruzione dell'indice < 50 ms su simulatore; scorrimento Movimenti fluido.
- Due simulatori + Android contro il server finto: incassi paralleli offline, cancellazione incrociata, client senza funzione (build vecchia) che modifica spese e rimborsi.

---

## 15. Task (dopo Sentiero, ramo separato `feature-split`)

Ordine obbligato: S-80q → S-80m → (S-80a, S-80b) → S-80c → S-80d (+ S-80d2 Matteo, non bloccante) → S-80e/S-80f → S-80g/S-80h → S-80i → S-80j → S-80k →
S-80n → S-80o → S-80p → S-80s → S-80r. Ogni task: un commit per task, test del task verdi + intero target
`MoneyTrackerTests` (mai `-only-testing` su singole `@Suite`), Android `assembleDebug lintDebug testDebugUnitTest`.
Stime in ore di impresa. Imprese consigliate secondo `.cantiere/SQUADRA.md` (Antigravity principale; Copilot per i
task piccoli e descritti; architetto/collaudatore Claude).

Dettaglio di ogni task in `PIANO.md` sezione «S-80».
