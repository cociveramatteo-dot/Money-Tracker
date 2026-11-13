# CONSEGNA — il biglietto per chi entra in turno

**Da:** collaudatore (Claude Code · Sonnet) **Il:** 2026-11-13 22:40

## Fatto
S-4 collaudato: conforme, chiuso [x]. Nessuna modifica al codice.
- Funzioni Home tutte presenti (oscura importi, impostazioni, ordine conti, fissi con i due toggle, ultimi movimenti tap/swipe/menu/collassa, refresh, empty state).
- BalanceTrail puro e corretto (Decimal, ancoraggi scaduti/oltre mese/fatti futuri); 6 test sensati; nessuna funzione di Domain/ modificata.
- Serie calcolata solo in rebuildTrail (onChange initial:true + chiusura editing); DB vuoto: trail a saldo 0, hero senza riga «atteso».
- i18n: 7 chiavi nuove nelle 6 lingue, plutil ok.

## Note per la resa a vista (Matteo)
- `.frame(height: count * rowHeight)` degli ultimi movimenti: a taglie accessibilità o tedesco le righe potrebbero tagliare (altezza fissa scalata).
- Hero assente per un frame al primo render (trail nil finché onChange initial).

## Prossimo passo
S-5 (Movimenti) a Antigravity/Codex.
