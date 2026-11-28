# Commissione Suprema — checkpoint 2026-11-28

Diff: `checkpoint-2026-11-28-0059..HEAD` (S-73a..g, S-70h, solo documenti S-80/S-52a). Collaudatore (Claude Code · Sonnet).
Singoli task già collaudati: qui solo l'insieme e le interazioni.

## Verifiche
- `collaudo.sh`: 🟡 solo avviso `.gradle/.../executionHistory.bin` 19,6 MB (cache di build, non in git). 0 errori, 0 debug, 0 TODO.
- Guardiano 28/11 09:59 (scaricato, più recente del push 01:00): 🔴 solo per CORS di cloudflareinsights su 127.0.0.1 (sito, non l'app), heading-order ×3, link YouTube dubbio. Nessun cambiamento visivo.
- iOS `MoneyTrackerTests` (intero target, iPhone 18 Pro): TEST SUCCEEDED (1 skip live).
- Android `assembleDebug lintDebug testDebugUnitTest`: verdi.

## Voti

| Giudice | Voto | Diagnosi |
|---|---|---|
| 1. Sicurezza e integrità dati | 10 | Nessuna zona intoccabile toccata (Domain/Models/Sync/Auth/Intents/Export/Formatting). Conferma = solo `isDone = true` + `safeSave()` (Home) o `toggleTransferOrFixed` (Movimenti), trasferimenti esclusi dalla card. Nessun segreto o log. |
| 2. Pulizia e architettura | 9 | `MonthlyPlannedBalance.swift:9` dipende da `DashboardView.countsInProjection` (regola di calcolo dentro una View). Funziona e la regola è unica, ma spostarla in un helper neutro sarebbe più pulito. Refactor non richiesto dal task → solo proposta, non corretto. Android già pulito (`HomeProjection.countsInMonth`). |
| 3. Logica e matematica | 10 | Home, Conti («→» e «A conti fatti») e «E se» (conti esclusi) usano la stessa regola su iOS e Android; Decimal/BigDecimal ovunque; previsione = attuale + pianificati che contano nel mese, Android = iniziale + movimenti che contano: equivalenti. Swipe e form coerenti fra le due piattaforme (data futura ⇒ pianificato). |
| 4. Performance | 9 | iOS ricalcola a ogni `body` tre scansioni O(n) di tutti i movimenti: `AccountsView.swift:45` (`expectedByAccountID`), `DashboardView.swift:160` (`OverduePlannedMovements.list`), `TransactionsView.swift:657` (`overduePlanned`). Per volumi personali è trascurabile; Android usa `remember`. Proposta, non bug. |
| 5. Bug e robustezza | 9 | Interazione S-73c/S-73f: un singolo NON fisso pianificato diventato scaduto, aperto dalla card «Da confermare», mostra il form senza «Già effettuato» (`AddTransactionView.swift:205`, Android `AddTransactionForm.kt:171`). Nessuna perdita di dati (salva `isDone` invariato) ma lo stato non si vede/cambia nel form → task **S-73i** (serve una scelta di UX, non solo una riga). Mezzanotte gestita (`projectionDay` + notifiche giorno/ora). |
| 6. Lingua, i18n, UX, Theme | 10 | «Da confermare» nelle 7 lingue iOS e Android; «Vedi tutti», «Conferma», «Pianificato», «Fissa» già presenti (it usa la chiave). Solo token DS adattivi, niente `preferredColorScheme`. Segnaposto «E se» `0` coerente iOS/Android. |

## Correzioni fatte
Nessuna: non sono emersi bug piccoli con causa chiara fuori dalle zone intoccabili.

## Rinvii
- S-73i (bug/UX, bassa priorità) in PIANO.
- S-73h già in coda (icona `circle.dotted`).
- Giudici 2 e 4: proposte di miglioramento, non difetti; restano 9 per scelta (AGENTS §6.9: niente refactor non richiesti).

---

## Secondo giro — 2026-11-28 12:05

Diff: `368d824` (S-73i), `d86d015` (`ProjectionRules`), `a3f4d2e` (cache iOS). Collaudatore (Claude Code · Sonnet).

### Verifiche
- iOS `MoneyTrackerTests` intero target: 265/265 in 60 suite (1 skip live). UI: `OverduePlannedUITests` 2/2, `FutureTransactionPlannedUITests` 2/2, `OverduePlannedFormUITests` 1/1 → TEST SUCCEEDED.
- Android `assembleDebug lintDebug testDebugUnitTest --rerun`: BUILD SUCCESSFUL, 370/370.
- Test esistenti non modificati (i 3 commit aggiungono solo file di test nuovi). Nessun debug/TODO nel diff.

### Cache (rischio dati vecchi)
- `MonthlyPlannedBalance.Cache` (Conti): impronta = giorno, conti (id, `currentBalance`), per ogni movimento id, data, importo, tipo, `isDone`, `isFixed`, `isTransfer`, `templateId`, `recurringFrequency` = tutto ciò che leggono `countsInProjection` e `signedAmount`. Aggiunta/cancellazione/spostamento di conto cambiano conteggi e id. Archiviazione ed esclusione non entrano nel calcolo cache (la partizione `included`/archiviati resta calcolata dal vivo).
- `ListCache` (Home e base di Movimenti): impronta = giorno, numero, id, `isDone`, `isTransfer`, conto e `isArchived`, data, `createdAt`, `id`: copre `isOverdue` e le chiavi di `sortedForDisplay`. Nome/importo nelle righe si leggono dal vivo dagli oggetti.
- `FilteredCache` (Movimenti): mese selezionato, ricerca e date personalizzate controllati prima della cache; impronta su filtro, categoria, min/max, id delle regole, `isFixed`/`templateId`/`type`/`category`/`amount` della base. Mezzanotte: `projectionDay` ora aggiornato da scenePhase, `NSCalendarDayChanged` e `significantTimeChange` (prima `Date()` a ogni render).
- Nessuna mutazione di stato osservato nel body: le cache sono classi non @Observable dentro `@State`; il calcolo dell'impronta legge comunque tutte le proprietà, quindi l'osservazione SwiftData registra le dipendenze anche in caso di hit.

### Voti finali

| Giudice | Voto | Nota |
|---|---|---|
| 1. Sicurezza e integrità dati | 10 | Nessuna zona intoccabile toccata; S-73i non cambia `isDone` al caricamento. |
| 2. Pulizia e architettura | 10 | Regola in `ProjectionRules.swift`; `DashboardView.countsInProjection` resta come delega di una riga solo per `ProjectionMonthTests` esistente (test intoccabile): nessuna logica duplicata. |
| 3. Logica e matematica | 10 | Le cache restituiscono il risultato della funzione originale; impronte complete sugli input. |
| 4. Performance | 10 | Niente più filtro/ordinamento/somme Decimal a ogni body; resta una scansione O(n) per l'impronta (stesso schema della `projectionFingerprint` già in Home), adeguata ai volumi personali. |
| 5. Bug e robustezza | 10 | S-73i chiuso su iOS e Android; mezzanotte gestita anche in Movimenti. |
| 6. Lingua, i18n, UX, Theme | 10 | Nessuna stringa nuova; interruttore riusa chiavi esistenti. |

### Correzioni fatte
Nessuna: non sono emersi bug. S-73i → `[x]`.
