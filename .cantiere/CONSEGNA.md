# CONSEGNA — il biglietto per chi entra in turno

**Da:** seconda impresa (Codex · GPT-6) **Il:** 2026-11-13 20:15 **Commit:** vedi `git log -1` (S-2)

## Fatto
- S-2: creati solo i sette file nuovi `MoneyTracker/Views/Components/{Card,HeroCard,MovementRow,ProgressBar,BudgetStatus,SegmentedPill,FilterChip}.swift`.
- Ogni componente ha due #Preview, light e dark tramite environment; nessun preferredColorScheme.
- Font DS.Typo, colori adattivi DS e tinte categoria CategoryTint. fog e heroDivider usati soltanto come bordi, track o separatori, mai testo/icone.
- MovementRow: uscita, entrata, pianificato con bordo tratteggiato, trasferimento; importi e metadati formattati dal chiamante. Nessun accesso ai modelli o modifica dei calcoli.
- ProgressBar: altezza 8, soglie visive 80%/100%, tacca all'80% sulla hero; BudgetStatus con importo oltre budget fornito dal chiamante.
- Filtri primari, secondari tratteggiati e avanzati con xmark; selezione SegmentedPill tramite Binding.
- Track del segmento e bordo secondario usano fog: sostituzione dei valori fissi dell'handoff con il token adattivo disponibile, come richiesto.

## Verificato
- Comando richiesto: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' build test`.
- BUILD SUCCEEDED e TEST SUCCEEDED: 21 test unitari + 12 UI, zero fallimenti. Nessun crash del runner.
- Primo tentativo nel sandbox senza accesso CoreSimulator; esecuzione autorizzata fuori sandbox riuscita.
- Nessun errore o warning dei nuovi componenti. Warning infrastrutturale AppIntents metadata sul target test e messaggi runtime del simulatore nel log.
- `git diff --check` pulito; nessuna vista o test esistente modificato. Nessuna modifica preesistente esterna al lavoro.
- Log temporaneo: `/tmp/moneytracker-s2-build-full.log` (non in git).

## Aperto
- S-2 a [~]: serve collaudatore. Preview compilate, non ispezionate visivamente; verificare light/dark, Dynamic Type XL e tedesco prima di chiudere S-2.
- Le etichette di BudgetStatus usano Text localizzabile; verificare le traduzioni in fase di integrazione, senza modificare qui risorse esistenti.

## Prossimo passo
Collaudatore su Claude Code (Sonnet): leggere AGENTS.md e STATO, aprire turno se libero, leggere questa consegna e solo il diff del commit S-2. Verificare requisiti e preview, registrare esito e chiudere S-2 solo se conforme. Poi S-3 al capocantiere.
