# S-13 · Motore ricorrenze a serie virtuali (D-008) — piano tecnico

Architetto (Claude Code · Opus) · 2026-11-13 · ramo `redesign-sentiero`

## a) Diagnosi: perché oggi le ricorrenti "non compaiono"

Verificato sul codice (`Domain/RecurringTransactionEngine.swift`, `MoneyTrackerApp.swift:227-246`, `Sync/SyncService.swift`):

1. **Solo occorrenze già scadute.** `guard candidate <= now` (riga 128): la copia del mese nasce solo il giorno esatto, mai prima. Non c'è nessuna vista sul futuro. **Confermato.**
2. **Guardia `lastRun` unica e globale.** È in `UserDefaults` e non distingue il container: se gira prima la demo, il container reale salta il turno per tutto il giorno. In più `.task` parte prima del `syncOnLogin`, quindi i modelli che arrivano col pull dopo il lancio non vengono elaborati fino al giorno dopo. **Confermato.** L'aggancio a `scenePhase` invece c'è già: il sospetto "solo all'apertura" è vero solo a metà.
3. **(Causa principale, nuova) Il sync cancella le copie generate.** Il motore salva in un `@ModelActor`, cioè su un altro contesto. L'osservatore `didSave` registra solo `ctx === realContainer.mainContext`, quindi le copie non diventano mai "dirty" e non vengono mai caricate su Supabase. Al pull successivo (foreground dopo 5 minuti, login, pull-to-refresh) risultano "orfane" e vengono **eliminate** in locale (`SyncService.swift:651-656`). Il giorno dopo vengono rigenerate e poi di nuovo cancellate.
4. **Dipendenza dalla copia più recente.** `latestById` più il fallback per nome/categoria/importo: se l'utente cancella o modifica la copia, il cursore torna indietro e il motore rigenera. Con il punto 3 il ciclo si chiude.
5. Due dispositivi generano copie con UUID diversi, quindi doppioni via sync.

Conseguenza progettuale: idempotenza **senza dipendere dalle copie esistenti**, ID deterministici, salvataggio sul `mainContext` (passa da `recordChanges`, AuditLogger e cache dei saldi).

## b) Modello dati

**Nuova entità `@Model RecurringRule`** (`Models/RecurringRule.swift`). Il nome non va in conflitto con la struct `RecurringSeries` né con `Calendar.RecurrenceRule`.

| campo | tipo | note |
|---|---|---|
| `id` | UUID | |
| `name`, `type`, `category`, `categoryIcon`, `notes` | String | valori base delle occorrenze |
| `amount` | Decimal | |
| `isFixed` | Bool | |
| `accountId` | UUID? | **niente relazione** con Account: così Account e Transaction restano invariati |
| `frequency` | String | `"mensile"`, `"settimanale"`, `"annuale"` (stessi valori di oggi) |
| `startDate` | Date | normalizzata alle 12:00 locali, ancora di giorno/mese/giorno della settimana |
| `endDate` | Date? | ultimo giorno **incluso**, nil = infinita |
| `exceptionsJSON` | String | `[chiaveOccorrenza: Eccezione]`. Chiave = `"yyyy-MM-dd"` della data originale. `Eccezione = { skip: Bool, amount: String?, date: Date?, name: String?, notes: String? }`. L'importo è una stringa per restare Decimal esatto. Decodifica difensiva: JSON malformato vale `[:]` e non manda in crash |
| `materializedThrough` | Date? | primo giorno dell'ultimo mese materializzato (watermark) |
| `createdAt` | Date | |

- **Transaction non cambia.** La copia materializzata ha `templateId = rule.id.uuidString`, `recurringFrequency = ""`, `isDone = false` e **`id = UUIDv5(rule.id, chiave)`** (SHA-1 di CryptoKit, bit di versione e variante impostati). Lo stesso ID su ogni dispositivo: l'upsert di Supabase unisce i doppioni.
- **Legacy:** i vecchi template (`recurringFrequency != ""`) e le loro copie restano intatti. Il campo viene solo ignorato e nessun codice nuovo lo scrive più. Gli UUID delle nuove regole sono nuovi, quindi non possono collidere con `templateId` legacy.
- **SchemaV3** = modelli di V2 + `RecurringRule`. Stage `.lightweight(fromVersion: SchemaV2, toVersion: SchemaV3)` dopo `migrateV1toV2`. Aggiungere un'entità nuova non tocca le righe esistenti. Bisogna aggiornare `SchemaV2` in **4 punti**: `MoneyTrackerApp.swift:35`, `Intents/AddExpenseIntent.swift:18` (altrimenti l'intent apre uno store V3 con schema V2 e fallisce), `makeContainer` dei test e `SchemaMigrationTests`. *Ripiego*: se SwiftData rifiuta due versioni che condividono le classi live (errore di checksum o versione sconosciuta), si congela V2 in classi annidate come già fatto per V1.
- **Supabase:** nuova tabella `mt_recurring_rules` (colonne snake_case come sopra, `exceptions` text, `materialized_through` timestamptz null) con **RLS** `auth.uid() = user_id` per select/insert/update/delete. Su `mt_transactions` non cambia niente: `template_id` porta già l'ID della regola, quindi i dati esistenti restano compatibili. Push: upsert completo più `deleteOrphans`, come per i budget (le regole sono poche decine). Pull: come per i budget, ma `materializedThrough = max(locale, remoto)`. `clearLocalData` cancella anche le regole.
- **Attenzione:** `push()` è un unico `do/catch`. Se la tabella non esiste, **fallisce tutto il push** (anche le transazioni) e il pull viene saltato. Matteo deve creare la tabella **prima** di provare in app il codice Sync.

## c) Algoritmi

**Calcolo puro** `RecurrenceCalculator.occurrences(rule: RuleSnapshot, in: DateInterval) -> [Occurrence]` (`Domain/RecurrenceCalculator.swift`, Sendable, senza SwiftData):
- Calendario `Calendar(identifier: .gregorian)` con il fuso del dispositivo, **mai `Calendar.current`**: con ja/zh e un calendario giapponese o buddista configurato l'aritmetica cambierebbe. Tutte le date alle 12:00, così cambio d'ora e piccoli spostamenti di fuso non cambiano il giorno.
- **Mensile:** n-esimo mese = mese di partenza + n. Giorno = `min(giornoAncora, giorniDelMese)`. Sempre dall'ancora, mai a catena (31 gen → 28/29 feb → **31 mar**).
- **Annuale:** mese e giorno dell'ancora. Il 29 febbraio diventa 28 negli anni non bisestili e torna 29 in quelli bisestili.
- **Settimanale:** `start + 7k giorni` (aggiunta `.day`). Indipendente da `firstWeekday` e `weekOfYear` (il motore di oggi usa `weekOfYear`, che dipende dalla locale). Il primo k si ricava dalla differenza in giorni tra la partenza e l'inizio dell'intervallo.
- Filtri: `>= startDate`, `<= endDate`, chiavi con `skip` escluse. Gli override si applicano a importo, data, nome e note; **la data di un override resta nello stesso mese** (si valida nell'editor).
- `Occurrence { ruleId, key, originalDate, date, amount: Decimal, name, category, categoryIcon, type, accountId, isFixed, notes, isOverridden }`.

**Materializzazione** `RecurringMaterializer.materializeDue(context:now:)`, `@MainActor` sul `mainContext`:
- Per ogni regola, per ogni mese M da `max(mese di startDate, materializedThrough + 1 mese)` fino al **mese corrente**: calcola le occorrenze di M e inserisce quelle il cui ID deterministico non esiste (fetch per ID, seconda protezione). Poi `materializedThrough = mese corrente`, `safeSave()` una volta sola.
- **Creazione di una regola:** `materializedThrough = mese precedente a max(mese di start, mese corrente)`. I mesi passati di una serie nuova **non** si generano (D-008 §7: lo storico lo gestisce Matteo); le occorrenze del mese corrente da `startDate` in poi sì.
- Idempotenza: una seconda esecuzione trova il watermark e non fa niente. Una copia cancellata o modificata non viene ricreata né sovrascritta, perché il watermark è già passato (e la cancellazione "solo questa" aggiunge anche `skip`). Se l'app resta chiusa per mesi, il recupero copre tutti i mesi mancati come pianificate, con un tetto di sicurezza di 36 mesi per regola. Le copie nate su due dispositivi hanno lo stesso ID e vengono unite.
- **Quando parte:** dopo `syncOnLogin` e `syncOnForeground` (così si lavora su regole e watermark aggiornati), su `scenePhase == .active` (anche offline) e su `UIApplication.significantTimeChangeNotification` (mezzanotte del primo con l'app aperta). Gira per il container attivo, demo compresa: il watermark sta nella regola, non in UserDefaults.
- **Spegnimento del vecchio motore:** cancellare `RecurringTransactionActor`, le sue 2 chiamate in `MoneyTrackerApp` e `RecurringTransactionEngineTests.swift`, che vengono sostituiti dai test nuovi. La deroga di D-008 copre questa cancellazione: va annotata in DECISIONI. Nessun dato viene toccato.

## d) Eccezioni (`Domain/RecurringSeriesEditor.swift`, `@MainActor`)

Si interviene su un'occorrenza X con chiave k e data originale D. X può essere virtuale (mese futuro) o una copia vera.

| azione | regola | copie già materializzate |
|---|---|---|
| Salta mese | `skip` per tutte le chiavi del mese (per le settimanali, tutte e 4-5) | non fatte del mese: eliminate. Fatte: invariate |
| Termina da qui / disattiva per sempre | `endDate = D − 1 giorno` (disattiva = da oggi) | non fatte con data ≥ D: eliminate. Il passato resta |
| Modifica **solo questa** | override su k | se X è una copia: si aggiorna anche la transazione |
| Elimina **solo questa** | `skip` su k | copia eliminata |
| Modifica **questa e le successive** | la vecchia regola prende `endDate = D − 1`, nasce una regola nuova da D con i valori nuovi. Le eccezioni ≥ D vengono scartate | non fatte ≥ D della vecchia: eliminate. Poi `reconcileCurrentMonth(nuova)` |
| Elimina **questa e le successive** | come "termina da qui" | idem |
| Modifica **tutte** | regola modificata sul posto. Se cambiano frequenza o giorno, si azzerano le eccezioni | `reconcileCurrentMonth`: non fatte del mese corrente aggiornate, eliminate o create secondo base + override |
| Elimina **tutte** | regola cancellata | non fatte: eliminate. **Fatte: restano** (soldi già mossi) |

`reconcileCurrentMonth` gira **solo** dopo un'azione esplicita "successive" o "tutte", mai all'avvio. Le copie `isDone == true` non vengono mai toccate.

## e) Viste (solo interfaccia dati, la grafica la fa l'impresa grafica sul mockup)

- **Movimenti (`TransactionsView`):** per un mese **dopo** quello corrente, la lista unisce le transazioni vere a `RecurrenceCalculator` sulle regole attive, tramite `enum TxRow { case real(Transaction), virtual(Occurrence) }`. Il mese corrente e quelli passati non hanno virtuali, perché lì sono già materializzate. **Totali, filtri di importo e saldi contano solo `.real`.** Tocco su un virtuale: azioni salta mese, termina da qui, modifica o elimina con la scelta di ambito. Il flag `isVirtual` serve alla distinzione grafica.
- **Ricorrenti:** sezione nuova "Serie programmate" (`@Query RecurringRule`), con nome, importo, frequenza, prossima occorrenza (`calculator.next(after: now)`) e stato (attiva / termina il … / terminata). La sezione del `RecurringSeriesDetector` resta così com'è.
- **AddTransactionView:** il selettore Ricorrenza compare **solo in creazione**. Al salvataggio con una frequenza si crea la `RecurringRule` (start = data scelta) e la transazione salvata diventa la prima occorrenza (`id` deterministico, `templateId`). In modifica di una copia: dialogo "solo questa / questa e le successive / tutte". In modifica di un template legacy: selettore nascosto, si comporta da transazione normale. Il menu "Interrompi ricorrenza" diventa "Termina da qui" sulle copie delle regole nuove; sui legacy sparisce, perché non ha più effetto.
- **Pianifica, Dashboard, Statistiche, AccountBalanceCache:** **nessuna modifica**. Leggono solo `Transaction` e i virtuali non ci arrivano mai per costruzione.

## f) Test (Swift Testing, `@Suite`, container in memoria `SchemaV3`)

- **Calculator** (puro, `TimeZone` Europe/Rome fissato): 31 gen → 28 feb (29 nel 2028) → 31 mar → 30 apr; annuale 29/2/2024 → 28/2/2025 → 29/2/2028; settimanale attraverso i cambi d'ora di marzo e ottobre (sempre 7 giorni, stesso giorno della settimana, ore 12); stesso risultato con `firstWeekday` 1 o 2; mese con 5 settimanali; start a metà mese; `endDate` inclusiva; skip; override di importo e data; salta mese su settimanale; occorrenze presenti a 12 e 13 mesi; locale ja con calendario giapponese uguale al gregoriano.
- **ID deterministico:** stesso input dà lo stesso UUID tra due run; chiavi diverse danno UUID diversi; UUID valido v5.
- **Materializer:** primo giro crea le occorrenze del mese con `isDone == false`; il secondo giro ne crea 0; copia cancellata non ricreata; copia modificata non sovrascritta; 3 mesi chiusi danno 3 mesi recuperati; tetto a 36; regola nuova con start passato non genera i mesi passati; regola terminata non genera; due container danno lo stesso ID.
- **Invarianza:** con N regole e virtuali calcolati per i prossimi 12 mesi, `fetchCount(Transaction)`, `currentBalance`/`futureBalance` di ogni conto e somme entrate/uscite del mese sono **identici** a prima.
- **Editor:** ogni riga della tabella in d), con copie fatte invariate.
- **Migrazione:** store V2 **su disco** con transazioni (compreso un template legacy mensile e una copia) aperto con V3 e piano: conteggio, importi Decimal, `recurringFrequency` e `templateId` invariati, 0 regole create, 0 transazioni nuove dopo `materializeDue`.
- **Sync:** encode/decode di `SBRecurringRule` (CodingKeys, Decimal, `exceptions`); merge del watermark con `max`.
- **Decimal:** override `"0.1"` più base `"0.2"` dà somme esatte.

## g) Sotto-task (ordine obbligato)

| ID | a chi | file | fatto quando |
|---|---|---|---|
| **S-13a** Calcolo puro + UUIDv5 + codec delle eccezioni | Codex | nuovi `Domain/RecurrenceCalculator.swift`, `MoneyTrackerTests/RecurrenceCalculatorTests.swift` | test del calculator e dell'ID verdi. Nessun altro file toccato |
| **S-13b** Modello + SchemaV3 | Codex | nuovo `Models/RecurringRule.swift`; `Persistence/SchemaMigration.swift`; `MoneyTrackerApp.swift:35`; `Intents/AddExpenseIntent.swift:18`; `SchemaMigrationTests.swift` | test di migrazione V2 → V3 su disco verde, quelli V1 → V2 ancora verdi, build ok |
| **S-13c** Materializer + spegnimento del vecchio motore + punti di avvio | Codex | nuovo `Domain/RecurringMaterializer.swift` + test; cancellati `RecurringTransactionEngine.swift` e `RecurringTransactionEngineTests.swift`; `MoneyTrackerApp.swift` | test del materializer e dell'invarianza verdi; `grep RecurringTransactionActor` vuoto |
| **S-13d** Editor (ambiti, salta, termina) | Codex | nuovo `Domain/RecurringSeriesEditor.swift` + test | test della tabella d) verdi |
| **S-13e [?]** Creare la tabella su Supabase | **Matteo** (SQL pronto, scritto in S-13f e copiato in PER-MATTEO) | dashboard Supabase → SQL Editor | la tabella esiste e la RLS è attiva (Matteo riporta "fatto") |
| **S-13f** Sync | Codex (scrive lo SQL **prima** del codice) | `Sync/SyncService.swift` (DTO, push, pull, clearLocalData) | test del DTO verde; **provato in app solo dopo S-13e**: regola creata su un dispositivo compare dopo il pull |
| **S-13g [~]** UI funzionale (dati + azioni) | Codex, autorizzato da Matteo 2026-11-14: S-12 chiuso, Antigravity non disponibile; stile Theme esistente, rifinitura virtuali separata S-18 | `TransactionsView.swift`, `AddTransactionView.swift`, `Localizable` (7 lingue, traduzioni al redattore) | il flusso a mano sul simulatore funziona; stringhe in 7 lingue |
| **S-13h** Documento master + collaudo + Commissione Suprema | collaudatore / capocantiere | `docs/MoneyTracker.md` §Ricorrenze, §Modelli, Changelog | build e test verdi, 10/10 |

S-13a e S-13b sono indipendenti e si possono fare in parallelo. S-13c richiede a+b, S-13d richiede c, S-13f richiede b, S-13g richiede c, d e f.

**Rischi:**
1. Lo stage lightweight con classi live condivise: c'è il ripiego (congelare V2).
2. Il push si blocca se la tabella manca: S-13e va fatto prima della prova in app.
3. Una copia cancellata su A può risorgere da B se B era offline col watermark vecchio (raro, utente singolo: accettato).
4. Conflitto su `TransactionsView` con Antigravity: S-13g va per ultimo.
5. Fusi con più di 12 ore di differenza tra due dispositivi potrebbero produrre chiavi diverse (accettato).

## Domande per Matteo

1. "Elimina **tutte**": le pianificate non ancora fatte spariscono e quelle già fatte restano. Va bene?
2. "Disattiva per sempre" oggi: l'occorrenza di oggi ancora pianificata viene eliminata?
3. Le vecchie ricorrenti: le vuoi vedere elencate da qualche parte (per esempio una lista "da sistemare" nella sezione Ricorrenti), o ti basta rifarle a mano come transazioni nuove con la Ricorrenza attiva? Default: niente lista.
4. Ricorrenze sui **trasferimenti**: servono? Oggi non esistono. Default: fuori da S-13.
5. In Dashboard o Pianifica vuoi una card "Prossime scadenze" con i virtuali? Default: no in S-13; eventualmente un task grafico separato col mockup.

➡️ Prossimo: S-13a → Codex (calcolo puro e test, nessun conflitto con Antigravity)
