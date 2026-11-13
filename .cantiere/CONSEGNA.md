# CONSEGNA — il biglietto per chi entra in turno

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-13 22:54 · S-5 · ramo `redesign-sentiero`

## Fatto
- Movimenti: titolo DS grande, filtri avanzati con badge, ricerca h 46/raggio 16, tipi in scroll orizzontale con FilterChip (compreso Ricorrenti); percorsi e identificatori originali mantenuti.
- Hub con lista del mese, riga secondaria mese/categorie (SegmentedPill)/filtri attivi. Le sottosezioni conservano ricerca locale, filtri categoria e ricorrenti.
- Pianificati in cima con intestazione ambra e totale; operazioni effettuate raggruppate per Oggi/Ieri/data in card adattive con totale giornaliero. I subtotali di presentazione usano signedAmount Decimal ed escludono trasferimenti, senza modificare calcoli del dominio.
- MovementRow per le righe, stessi handler tap/menu/swipe e conferma trasferimenti. Stato accessibile Fatto/Pianificato.
- Intestazione nuova nelle 7 lingue; Ieri/Oggi esplicitati anche nel catalogo italiano. plutil x7 e diff --check ok.
- Confronto automatico con HEAD: @Query, filtered, recurringSeries, searchResults, grouped originale, advancedFilterSheet, funzioni di mutazione e identificatori invariati. Nessun test modificato.
- Graphify query eseguita prima del codice; grafo aggiornato (AST, 0 token LLM). Backup automatico del grafo spostato in `/tmp/moneytracker-s5-graph-backup`, fuori dal repository.

## Verifica ancora aperta
Il comando build test richiesto è stato tentato più volte, ma il runner non avvia i test: simulatore sulla schermata di boot, servizio `com.apple.instruments.deviceservice.lockdown` / DTServiceHubClient non disponibile. Riavvio non risolutivo. Non ci sono test verdi da dichiarare. Log: `/tmp/moneytracker-s5-build.log` (contiene anche output ritardato delle sessioni interrotte).
Build separata: **BUILD SUCCEEDED**, exit 0; log `/tmp/moneytracker-s5-build-only.log`.
Controllo a vista light/dark, XL, tedesco, demo e screenshot prima/dopo NON effettuato: CUA Simulator in timeout, screenshot simctl mostra solo il boot iOS.

## Prossimo passo
Collaudatore (Claude Code · Sonnet): leggere il diff del commit S-5, ripristinare il runner e rilanciare il comando richiesto. Verificare hub, ricerca globale, sei sezioni, ricerca locale, filtri, swipe, trasferimenti e ricorrenti; poi resa a vista. Solo dopo chiudere S-5 [x].
Nessun file di altri lavori presente all'apertura; niente merge o push.
