# CONSEGNA — 2026-11-26 13:59 · Seconda impresa (Codex · GPT-6)

**S-50r [~] · iOS, decodifica e cifratura del vault fuori dal main actor**

- `VaultRemote.select` chiama `decodeRows` in un `Task.detached`. `upsert` codifica e cifra nello stesso modo un batch alla volta, con un massimo di 200 righe e invii in sequenza.
- `SyncRow` richiede `Sendable` e i cinque DTO `SB*` conformano con verifica del compilatore. Le conversioni che accedono ai modelli SwiftData restano isolate al main actor.
- Nuova regressione `E2EVaultConcurrencyTests` con 401 righe in batch 200/200/1. Fallisce se la codifica o la decodifica avviene sul thread principale. Test preesistenti conservati.

## Verifiche iOS

- iPhone 18 Pro, iOS 27.2. **Build riuscita e 185 test unitari passati**. Inclusi la nuova regressione e i quattro stress test E2E su 20.000 movimenti, limiti delle eccezioni, perdita di rete e attivazioni concorrenti. Log `.cantiere/tmp/s50r/build.log` e `.cantiere/tmp/s50r/test.log`.
- **8/8 test UI della Protezione avanzata passati**. La suite UI generale è stata interrotta dopo tre test passati per dare priorità alle prove E2E. Xcode registra il quarto test generale come annullato. Risultato dedicato in `.cantiere/tmp/s50r/ios-e2e-ui.xcresult`.
- Grafo del codice aggiornato e `git diff --check` pulito. La regressione verifica il thread di esecuzione. La prova su 20.000 movimenti verifica l'integrità della migrazione in memoria.

**Prossimo** · Collaudatore su Claude Code (Sonnet), poi S-50p. Esaminare il diff S-50r e verificare che i task detached ricevano solo valori Sendable, che i controlli delle righe e gli invii a batch restino equivalenti e che gli esiti iOS siano coerenti con i log. Registrare il collaudo in PIANO.
