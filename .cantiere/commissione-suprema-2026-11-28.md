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
