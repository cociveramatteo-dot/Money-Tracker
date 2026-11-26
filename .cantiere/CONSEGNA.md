# CONSEGNA — 2026-11-26 20:50 · impresa (Codex · GPT-6)

## Fatto

- **S-51 [~]** · Per il database reale, WAL e SHM usano `.completeUntilFirstUserAuthentication`. Il ripiego in RAM blocca la sincronizzazione e mostra un avviso fisso nelle sette lingue. Dopo il primo download E2E, eventuali movimenti locali ancora da caricare fanno partire un push. Rimosso il file diagnostico non tracciato `ReproLostTransactionTests.swift`. Commit `e462c34`.
- **S-51b [!]** · Consegnati lo [script ripetibile](../03_CODICE/bucktrail-android/scripts/prova-due-dispositivi.py), il [README](../03_CODICE/bucktrail-android/README.md) e i test. Il giro su Supabase reale ha riprodotto S-51d. L’aggiornamento iOS ha eliminato il movimento B dopo che Android lo aveva inviato e il test ne aveva confermato l’ID sul server. La riapertura ha ritrovato A una sola volta nell’archivio SwiftData e B assente.

| Fase | iOS → Android (A) | Android → iOS (B) | Riapertura iOS (A e B) |
| --- | --- | --- | --- |
| Protezione disattivata | OK | KO · iOS elimina B dal server | KO · B assente |
| Protezione attiva | OK | KO · iOS elimina B dal vault | KO · B assente |
| Dopo la disattivazione | OK | KO · iOS elimina B dal server | KO · B assente |

Attivazione su iOS, sblocco su Android e disattivazione su iOS OK. La lettura finale di Supabase ha confermato Protezione avanzata disattivata e presenza di tutti gli ID preesistenti nelle cinque tabelle. I simulatori temporanei sono stati rimossi.

## Verifiche e limiti

- S-51 ha superato i cinque casi di regressione con notifica SwiftData reale. Build iOS riuscita e 190 test Swift Testing verdi sul comando completo. Al primo giro il runner UI è scaduto in attesa dell’accessibilità. Al secondo giro il comando seriale è stato fermato dopo due errori dei test Conti, uno sul focus della tastiera e uno sulla chiusura dell’app.
- Android ha superato 324 test unitari e `lintDebug`. Build e installazione Debug della prova reale riuscite. La prova usa l’archivio SwiftData osservato dall’app iOS e l’app Android strumentata. Il test salta l’autenticazione locale del dispositivo durante la migrazione del simulatore. Il primo giro, svolto con un contesto SwiftData separato, non aveva inviato A. Il secondo giro, con il contesto dell’app, ha completato tutti e tre gli invii di A e riprodotto la perdita di B.
- Durante la riapertura, la query XCUITest ha contato più elementi di accessibilità per A mentre SwiftData contava un solo record. La versione consegnata verifica la visibilità con XCUITest e l’unicità con SwiftData. La build finale dei due target di test è riuscita. I tre esiti KO della riapertura sono confermati dall’assenza di B in SwiftData.
- La protezione file dopo riavvio e primo sblocco resta da verificare su un iPhone fisico. `graphify update .` riuscito.

## File toccati

- `MoneyTracker/MoneyTrackerApp.swift`, `MoneyTracker/Sync/SyncService.swift`, `MoneyTracker/Sync/SyncService+E2E.swift`, sette `Localizable.strings` e `MoneyTrackerTests/SyncLostTransactionTests.swift`.
- `MoneyTrackerTests/TwoDeviceLiveSyncTests.swift`, `MoneyTrackerUITests/TwoDeviceLiveReopenUITests.swift`, `TwoDeviceLiveSyncTest.kt`, `prova-due-dispositivi.py` e `03_CODICE/bucktrail-android/README.md`.
- `.cantiere/DECISIONI.md`, `PIANO.md`, `DIARIO.md`, `STATO.md` e questa consegna. Modifiche locali escluse dai commit del turno: `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` e `graphify-out/`.

## Prossimo

S-51d all’architetto per definire la correzione. Ripetere S-51b dopo il fix. S-51 resta da collaudare.
