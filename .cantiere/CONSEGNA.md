# CONSEGNA — S-33 (impresa, Codex · GPT-6)

Ramo `fix-recurrence-ui-test`, creato da main `4fb666a`. Autorizzazione separata di Matteo del 2026-11-16. Nessun push/merge.

## Accertamento prima di qualsiasi modifica
Il codice è rimasto esattamente quello di main: nessun file app o test modificato.

| Run originale su main | Risultato | Evidenza |
|---|---|---|
| Isolato 1 | Verde, 102,700 s | `/tmp/mt-s33-main-1.log` |
| Isolato 2 | Verde, 100,202 s | `/tmp/mt-s33-main-2.log` |
| Dentro suite completa | Test verde, 91,866 s; suite tutta verde | `/tmp/mt-s33-full-main.log` |

I due run isolati e il run completo usano iPhone 18 Pro `37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`, esecuzione seriale, nessun timeout modificato.

## Cosa è provato e cosa manca
- Il rosso alla riga 100 nel vecchio `/tmp/mt-s32-full-fixed.log` è reale, ma non stabile: non si riproduce nei tre nuovi run sullo stesso codice applicativo di main.
- Nei run nuovi il long press espone «Ricorrenza», il test la trova come Button e apre `recurrence_scope`, poi completa modifica ed eliminazione. Nel secondo run: pressione a 46,03 s, voce trovata a 49,05 s, apertura editor a 50,52 s. Non è dimostrato un identificatore errato o un'attesa troppo corta.
- La riga movimento installa il menu in `MoneyTracker/Views/TransactionsView.swift:742`; `RecurrenceContextMenu` (`MoneyTracker/Views/RecurrenceControls.swift:156`) mostra il Button «Ricorrenza» quando `RecurrenceSelection.resolve` restituisce una selezione. Il resolver (riga 21) richiede regola associata e identità dell'occorrenza valida. Nessun difetto accertato in quel codice.
- Il vecchio bundle S-32 in DerivedData non esiste più: tentativo di export in `/tmp/mt-s33-export.log`. Non è possibile distinguere retroattivamente gesto non recepito, menu senza voce o altro errore di stato dal solo log. Nessun video del vecchio fallimento ispezionabile. L'export del secondo run verde non contiene allegati conservati (`/tmp/mt-s33-main-2-export.log`).
- Non attribuito a S-21/S-22 né a un altro commit: manca una riproduzione con prove. Causa precisa NON accertata; accertata solo l'intermittenza del fallimento segnalato.

## Esito e limite
Nessuna correzione speculativa, nessun test indebolito o modificato, nessuna zona protetta toccata. Il requisito «causa accertata» resta aperto: S-33 rimane [?], non [~] né [x]. Prossimo: decisione di Matteo se mantenere in osservazione o autorizzare una campagna mirata di riproduzione. Il bundle del run completo viene conservato fuori da DerivedData in `/tmp/mt-s33-full-main.xcresult`.

## Verifiche finali
Build e run completo riusciti (exit 0): 90 unit in 18 suite, 45/45 UI, inclusi 4/4 S-6 e DemoShowcaseUITests. Durata UI 27 minuti circa. `git diff --check` pulito. Nessun altro test modificato o indebolito. Nessun cambiamento a graphify-out.

## Chiusura — 2026-11-17 00:24
Solo documentazione di cantiere modificata; nessun file estraneo pendente. STATO libero. Nessun push/merge. Proposta a Matteo: mantenere S-33 in osservazione; se ricompare, conservare subito il bundle in /tmp prima di nuovi run. Il collaudatore può verificare il dossier indipendentemente, ma non c'è una correzione di codice da collaudare.
