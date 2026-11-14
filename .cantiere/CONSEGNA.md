# CONSEGNA — S-13d: editor Domain da collaudare

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 09:56
**Ramo:** `redesign-sentiero`. S-13a/b/c già [x], non rifatti; S-13d resta **[~]**.

## Implementato
- Nuovo `MoneyTracker/Domain/RecurringSeriesEditor.swift`, solo `@MainActor` su `container.mainContext`: modifica/eliminazione solo questa, successive e tutte; salta mese (tutte le chiavi settimanali comprese); termina da qui e termina dopo questa.
- Solo questa: codec override Decimal esatto (amount string, data nello stesso mese, nome/note); eliminazione con skip. Le copie fatte restano immutate, anche con modifica/eliminazione singola.
- Successive: chiusura inclusiva vecchia regola al giorno precedente, scarto eccezioni successive, nuova regola con UUID nuovo ancorata alla data originale selezionata. Riconciliazione esplicita del solo mese corrente; non duplica una copia fatta dello stesso giorno originale col nuovo namespace.
- Tutte: regola sul posto; cambio ancora/frequenza azzera eccezioni. Riconciliazione crea/aggiorna/elimina le pianificate del corrente, mai le fatte. Elimina tutte conserva le fatte. Nessuna generazione di storico; regola futura con watermark nil rimane in attesa e materializza correttamente al suo mese iniziale.
- Fetch prima delle mutazioni, `context.save()` throwing (senza assertion di safeSave), invalidazione AccountBalanceCache solo dopo successo. In errore ripristina soltanto regola/copie proprie, anche cancellazioni e split, preservando modifiche pendenti estranee. Confine save iniettabile per provare errori senza corrompere il database.
- API: `apply(_:to:originalDate:context:now:)` restituisce nuova regola per successive, originale negli altri casi, nil per elimina tutte. `snapshot(_:)` costruisce i valori di modifica. Solo questa usa i quattro campi previsti dal codec; gli altri attributi si modificano con successive/tutte.

## Errori: confine con S-13g, requisito ancora da integrare a schermo
- `RecurrenceOperationStatus` è `@Observable @MainActor`: `perform { try ... }` conserva `errorMessage` leggibile fino ad azzeramento esplicito. Accetta sia errori editor/riconciliazione sia errori di `RecurringMaterializer.materializeDue` (test per entrambi); nessuna soppressione in soli log nel nuovo editor.
- **Non c’è ancora un alert effettivamente visibile nell’app.** Il vincolo esplicito di S-13d vieta modifiche UI; quindi S-13g deve obbligatoriamente collegare questo stato a un alert e instradare anche gli errori degli avvii del materializer. I catch di avvio attuali restano quelli di S-13c: questo turno non li ha cambiati. Le nuove stringhe andranno nelle 7 lingue in g. Non dichiarare il requisito della visibilità a schermo già verificato.

## Verifiche
- Nuovo `MoneyTrackerTests/RecurringSeriesEditorTests.swift`: **12 test**, tabella d), tutte le frequenze, copie fatte e legacy, override virtuale e Decimal, validazione mese/contesto, split senza doppione fatto, future/nil watermark, error state e ripristino dopo salvataggio fallito (edit/delete/split, con successivo save riuscito).
- **BUILD SUCCEEDED + TEST SUCCEEDED, 60 unit verdi in 10 suite** sul simulatore `37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`. Comando: `xcodebuild -scheme MoneyTracker -destination 'platform=iOS Simulator,id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48' -only-testing:MoneyTrackerTests build test`.
- Log finale `/tmp/moneytracker-s13d.log`; xcresult `Run-MoneyTracker-2026.11.14_09-54-27-+0100.xcresult` in DerivedData/Logs/Test. Primo tentativo bloccato da sandbox; rieseguito con autorizzazione. Prima compilazione dei test corretta per un try mancante nel nuovo test, poi tutte le prove verdi.
- UI S-15 note (stress:55, senza-categoria:68) non rieseguite: verifica richiesta build + unit; nessuna asserzione aggirata.
- Grafo interrogato prima del codice e aggiornato AST-only dopo: 1414 nodi/2462 archi. Log `/tmp/moneytracker-s13d-graphify-final.log`; avviso preesistente sui 9 JSON senza nodi. Backup generati spostati in `/tmp/moneytracker-s13d-graphify-backup` e `-final-backup`, non in git.
- Nessuna modifica a Sync/, viste, Models legacy, test esistenti, calculator/materializer/schema. Nessun merge, push o pubblicazione. Al via risultava modificato solo STATO dopo presa turno; nessun lavoro estraneo escluso dal commit.

## Prossimo
Collaudatore Claude Code · Sonnet, solo diff del commit S-13d. Poi S-13f prepara SQL per S-13e di Matteo prima della prova cloud; S-13g dopo dipendenze, con collegamento errori obbligatorio.

📍 Claude Code, cartella `/Users/matteo/Desktop/APP/MoneyTracker`, modello Sonnet. ▶️ Prompt da incollare:

```text
Esegui il collaudo S-13d sul ramo redesign-sentiero. Entra in turno secondo AGENTS.md §4 solo se STATO è libero. Leggi CONSEGNA.md, S-13 in PIANO.md, D-008/D-009 e piano-s13.md; per il codice solo il diff del commit [seconda impresa] editor ricorrenze e riconciliazione (S-13d). Controlla ambiti solo questa/successive/tutte, codec skip/override Decimal e validazione mese, salta mese settimanale, termina da qui/dopo questa, copie fatte sempre immutate, split senza doppione fatto, riconciliazione solo corrente, futuro con watermark nil e nessuno storico/legacy convertito. Verifica ripristino delle sole mutazioni proprie dopo errore di save e conservazione modifiche estranee. Prove: build e 60 unit verdi, /tmp/moneytracker-s13d.log sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48. La UI non è stata toccata: stato errore osservabile disponibile ma alert e instradamento errori degli avvii materializer sono obbligo ancora aperto di S-13g, non dichiararli già visibili. Non toccare Sync, viste, modelli legacy o test esistenti, né aggirare i due UI S-15 noti stress:55 e senza-categoria:68. S-13d resta [~] fino al tuo esito; chiudi documenti, commit mirato e STATO libero.
```
↩️ Riportare cartellino ed eventuali difetti precisi.
