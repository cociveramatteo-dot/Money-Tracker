# Collaudo iOS 2026-11-24 (collaudatore, Claude Code · Sonnet)

Ramo redesign-sentiero, commit 54ad77f (S-41) e 8259b35 (S-42). Simulatore iPhone 18 Pro, iOS 27.2. Log in scratchpad.

## Esito
| Voce | Esito |
|---|---|
| Build | verde |
| Unit test (tutta la suite) | 94/94 in 20 suite, verde |
| UI test mirati (Ricorrenze, Home/Annulla, Transazioni, Pianifica) | 17 su 18 verdi al primo giro. `RecurrenceFlowUITests.testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes` fallito al terzo scope («Questa e le successive»: la riga non scompare entro 5 s) e VERDE al rilancio isolato (294 s). Sospetto flaky per carico/lentezza (il test è lento), non regressione: il diff dei task non tocca quel percorso (menu contestuale, non lo swipe). Da tenere d'occhio |
| Zone intoccabili | nessuna toccata: i due commit modificano solo `Views/DashboardView.swift`, `Views/TransactionsView.swift` e aggiungono `RecurrenceCancelAndHomeUITests.swift` (più .cantiere e graphify-out) |
| Controllo visivo Home | chiaro, scuro, accessibilità XL (demo): Hero, curva, carte conti con «→ saldo atteso», Fissi del mese, Ultimi movimenti coerenti col mockup Main; nessun bordo/badge ingrandito. Con font grandi la tab bar tronca le etichette e il «+» copre «Gestisci»: già così prima (non dei task) |
| S-42 layout | Ultimi movimenti: altezza al contenuto, 4 righe complete, swipe nativo; annullamento dell'editor da swipe e da menu serie: la riga resta (3 test verdi, screenshot ok) |
| S-41 passaggio di mese | NON verificato nell'interfaccia (serve cambiare data di sistema); la logica è coperta da BalanceTrailTests. Nel demo di oggi: 3 pianificati −397,40 €, atteso 21.511,76 € coerente con le carte conto |

## Difetti piccoli
- Ultimi movimenti: sotto l'ultima riga compare un filo separatore all'orlo della card (screenshot home-recent-movements). Estetico, non corretto (richiede di sapere se è il List o il divider: proposta sotto).

## Suggerimenti
1. `monthlyProjection()` è chiamata nel `body` di DashboardView a ogni render (ciclo su tutte le transazioni): spostarla in una proprietà memoizzata o in `onChange`, come faceva `trailSignature`.
2. Togliere il divider dell'ultima riga di Ultimi movimenti (`listRowSeparator(.hidden)` sull'ultimo elemento).
3. Rendere meno fragile `testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes` (attese più lunghe o split in 3 test).
4. Test UI per il passaggio di mese di S-41 (data iniettabile).
5. Tab bar e «+» con font accessibilità: vedi S-40.

## S-36 — rami vecchi (nessuna cancellazione; proposta)
Main è del 2026-11-17; nessuno dei rami è antenato di main. Ognuno ha 1 commit.
| Ramo | Contenuto | In main/redesign? | Proposta |
|---|---|---|---|
| fix/nightly-20260708-1644 | solo report_notturno.md | no, ma irrilevante | cancellare |
| fix/nightly-20260708-1655 | UI test NavigationStress: attesa del campo importo + report | no | cancellare (test poi riscritti; S-15 già chiuso) |
| fix/nightly-20260710-0405 | AccountFlowUITests: timeout 5→15 s | no | cancellare (assorbito da 0727) |
| fix/nightly-20260716-0403 | SupabaseManager: `guard !isUITesting` in checkSession | no, nel codice attuale non c'è | tenere l'idea, vedi sotto; ramo cancellabile |
| fix/nightly-20260724-0411 | idem 0716 | no | cancellare |
| fix/nightly-20260726-0413 | 0716 + `highPriorityGesture` in AccountsView/CategoryManagementView + timeout 10 s | no | superato da 0727 |
| fix/nightly-20260727-0411 | il più completo: guard UI-testing in SupabaseManager (Auth/ = zona intoccabile), highPriorityGesture, timeout 10 s | no | UNICO con lavoro utile: i fix servono contro i «Timed out while synthesizing event». Decisione di Matteo (tocca Auth/ e Views); se non interessa, cancellare |
| tmp-stash-inspect | WIP 2026-07-05, 49 file (tema adattivo, riorganizzazione cartelle, OnboardingTour, Models, Sync…) | no: snapshot vecchissimo, superato da redesign (tour rimosso) | lavoro obsoleto, cancellabile previa ok di Matteo |
