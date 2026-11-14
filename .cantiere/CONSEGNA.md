# CONSEGNA — S-17

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 10:42
**Stato:** S-17 [~], da collaudare.

## Fatto
- Solo codice in `MoneyTracker/Sync/SyncService.swift` e test in `MoneyTrackerTests/RecurringRuleSyncTests.swift`.
- `mergeRecurringRules` conserva le regole locali quando il remoto è vuoto e il locale popolato, come richiesto da Matteo.
- Nuovo test verifica conservazione di ID, watermark ed eccezioni dopo save/fetch. Rimossa dal test precedente la vecchia attesa di cancellazione su remoto vuoto; resta verificata la cancellazione degli orfani con remoto popolato.
- Build e 5/5 test RecurringRuleSyncTests verdi: `/tmp/moneytracker-s17-verified.log`; diff senza errori di whitespace.

## Limiti e file esclusi
- Remoto parzialmente popolato: comportamento invariato; non protegge ogni possibile regola non spedita.
- Nessuna prova su Supabase reale. S-13f resta [~] fino alla prova tra dispositivi/utenti dopo S-13g; S-16 e S-15 restano aperti.
- `graphify-out/2026-11-14/` era già non tracciato: lasciato fuori. Grafo non rigenerato per rispettare il perimetro richiesto.

## Prossimo
S-17 → collaudatore (Claude Code · Sonnet).
Prompt: «Prendi il turno secondo AGENTS.md §4. Collauda S-17 leggendo solo il diff dell’ultimo commit della seconda impresa e il log /tmp/moneytracker-s17-verified.log. Verifica che remoto vuoto e locale popolato conservino regole, watermark ed eccezioni e che il merge con remoto popolato mantenga la cancellazione orfani. Se ok chiudi S-17 [x] con data/esito; altrimenti registra i difetti. Non ampliare il perimetro. Chiudi il turno col cartellino.»
