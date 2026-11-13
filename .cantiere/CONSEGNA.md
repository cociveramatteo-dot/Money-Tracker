# CONSEGNA — il biglietto per chi entra in turno

**Da:** capocantiere (Claude Code · Sonnet) **Il:** 2026-11-13 22:30 **Commit:** vedi `git log -1` (S-4)

## Fatto
- `Domain/BalanceTrail.swift`: serie reale + proiezione (funzione pura, D-007); ultimo reale = saldo attuale, ultimo proiettato = saldo atteso. `MoneyTrackerTests/BalanceTrailTests.swift`: 6 test (senza pianificati, coerenza atteso, scaduti/oltre mese, date fuori range, mese vuoto, Decimal esatto).
- `Views/Components/TrailView.swift` (Canvas, `accessibilityHidden`, tratteggio `[1,7]`, cerchi vuoti per pianificati, alone «oggi») e `HomeHeroCard.swift`.
- `DashboardView.swift`: header (data + «Bucktrail», occhio e impostazioni 44×44), hero con TrailView e riga «Saldo atteso a fine mese» solo con pianificati, conti in scroll orizzontale (148 pt, con pulsante ordine conti e «Gestisci»), fissi del mese (invariati), ultimi movimenti con `MovementRow` (swipe elimina, menu contestuale, tap modifica, collassabile, «Vedi tutti»). Oscura importi → `•••• €` ovunque, righe comprese (prima le righe non si oscuravano: nuovo come da handoff).
- `ContentView`: `goToTab` passato alla Home. 7 lingue: nuove chiavi «Vedi tutti», «Saldo atteso a fine mese», «nessun movimento», «Oscura/Mostra importi», «1 movimento pianificato», «%lld movimenti pianificati».

## Verificato
build + test: 27 unit (21 + 6) e 12 UI verdi.

## Da guardare nel collaudo
- Resa a vista: curva (mese vuoto, con/senza pianificati), light/dark, XL, tedesco; altezza righe `@ScaledMetric` negli ultimi movimenti (potrebbe tagliare a taglie molto grandi).
- Le carte conto non sono toccabili (come prima: la Home non apriva i conti). La tinta del quadratino è per tipo di conto (adattiva), non `colorHex`.
- Barra navigazione nascosta nella Home (header custom): verificare che nessuna funzione dipendesse dalla toolbar (occhio e impostazioni sono nell'header).
- Limite D-007 sull'aggiornamento della curva dopo modifica solo-data di un pianificato.

## Prossimo passo
Collaudatore su S-4; poi S-5 (Movimenti) a Antigravity/Codex.
