# Commissione Suprema 2026-11-24
Ambito: `checkpoint-2026-11-21-1030..HEAD`. Il codice iOS dell'intervallo (S-41, S-42) risulta già prima del checkpoint: nel perimetro iOS restano solo le correzioni di oggi. Input: collaudo Android 2026-11-23, collaudo iOS 2026-11-24.

## Giro 1 (prima delle correzioni)
| Giudice | Voto | Diagnosi |
|---|---|---|
| 1 Sicurezza e integrità dati | 8 | `app/build.gradle.kts`: il debug punta di default al Supabase reale (URL da SupabaseConfig.swift) |
| 2 Pulizia e architettura | 9 | `DashboardView.swift` `body`: proiezione ricostruita a ogni render |
| 3 Logica e matematica | 10 | Amounts/Balance/BalanceTrail identici a iOS (collaudo Android); S-41 coperto da BalanceTrailTests |
| 4 Performance | 9 | stessa proiezione O(n) con allocazioni a ogni render |
| 5 Bug e robustezza | 9 | filo separatore sotto l'ultima riga di Ultimi movimenti |
| 6 Lingua e UX | 9 | stringa demo Android con «MoneyTracker» in 6 lingue (la tedesca già neutra) |

## Correzioni
1. Android `build.gradle.kts`: build type `debug` con URL/chiave finti (`https://supabase-finto.invalid`) salvo `-PsupabaseUrl/-PsupabaseKey`; solo `release` legge `SupabaseConfig.swift`.
2. Android `strings.xml` (it, en, es, fr, ja, zh-Hans): «MoneyTracker» -> «Bucktrail» in `mostra_l_app_con_dati_di_esempio_senza_e`.
3. `DashboardView.swift`: `ProjectionCache` (scatola non osservata) con impronta di tutti i campi letti dalla proiezione (data giorno, saldo totale, conti inclusi, id/conto/data/importo/tipo/isDone/isFixed/isTransfer/templateId/recurringFrequency); la proiezione si ricostruisce solo se l'impronta cambia.
4. `DashboardView.swift`: `.listRowSeparator(.hidden, edges: .bottom)` sull'ultima riga di Ultimi movimenti.

## Verifiche dopo le correzioni
- Android: `assembleDebug lintDebug testDebugUnitTest` verde (BUILD SUCCESSFUL, 0 errori lint).
- iOS: suite unit 94/94 in 20 suite; UI `RecurrenceCancelAndHomeUITests` 3/3 (incluso `testHomeRecentMovements`).

## Giro 2 (dopo le correzioni)
| Giudice | Voto |
|---|---|
| 1 Sicurezza e integrità dati | 10 |
| 2 Pulizia e architettura | 10 |
| 3 Logica e matematica | 10 |
| 4 Performance e fluidità | 10 |
| 5 Bug e robustezza | 10 |
| 6 Lingua e coerenza i18n/UX | 10 |

Convergenza al giro 2.

## Per Matteo (non toccato: zone intoccabili o decisioni sue)
- Ramo `fix/nightly-20260727-0411` tocca Auth/ (guard UI-testing): decidere. Nessun ramo cancellato.
- Test flaky `testDeleteMonthlyFixedSeriesFromMovementMenuAllScopes` (verde al rilancio): da rendere meno fragile.
- Non verificati su dispositivo: biometria/PIN, notifiche, widget, TalkBack, sync reale, passaggio di mese S-41 nella UI.
- Release Android usa ancora il Supabase reale per costruzione (voluto).
- Non verificato a schermo: l'aspetto del separatore nascosto in Home (coperto solo dal test UI di layout, non da screenshot) e il debug installato con URL finto.
