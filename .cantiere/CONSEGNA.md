# CONSEGNA — 2026-11-27 11:51 · impresa (Codex · GPT-6)

## S-51d e S-51c [~]

- iOS `53d62d9` e Android `9d58e4e` salvano gli ID sincronizzati per utente e tabella. Un nuovo record remoto sopravvive al push, una cancellazione locale già nota si propaga e una cancellazione remota vince anche su una modifica locale non inviata.
- Gli ID cancellati altrove restano in attesa del pull che li rimuove anche in locale. Il test dei due push consecutivi copre questa finestra. In iOS le letture in chiaro usano la paginazione per confrontare istantanee complete.
- Android chiede conferma solo per le cancellazioni di record noti. Il pull ricorda anche gli ID illeggibili. Se non ne ha mai avuta una copia locale, il dispositivo li preserva. Il primo accesso con remoto vuoto e il ripristino autenticato dal dispositivo continuano a trasferire i movimenti locali.

## Test

- **iOS** · 40 test verdi in `SyncBaselineTests`, `SyncServiceFlagOffTests`, `SyncLostTransactionTests`, `E2EMigratorTests` e `RecurringRuleSyncTests`, selezionati con `xcodebuild -only-testing`. I nuovi test usano sia il trasporto in chiaro sia il vault in memoria. La suite UI completa è rimasta fuori dalla selezione.
- **Android** · 332 test verdi con `./gradlew testDebugUnitTest`, nessun test saltato.
- I due test esistenti indicati da Matteo ora preparano una base con l’orfano noto. Come previsto dal §5 del progetto, sono stati aggiornati anche i test che fallivano per lo stesso cambio di protocollo. In iOS, l’ordine delle chiamate nel login e nel test del client in chiaro bloccato da E2E. In Android, le basi delle fixture per batch, guardia cancellazioni e consenso tra modalità. Gli assert su isolamento utente, conferma, blocco delle scritture e batch sono rimasti attivi.

## S-51b [!] · Supabase reale

Due esecuzioni di `prova-due-dispositivi.py` hanno avviato entrambi i dispositivi virtuali e compilato le app. Il test iOS `TwoDeviceLiveSyncTests/testLiveSync()` è terminato con `EXC_BREAKPOINT` in entrambe. Lo stack indica `_dispatch_assert_queue_fail` nella closure di `MoneyTrackerApp.body`, chiamata da `LazyView.body` durante il rendering asincrono su iOS 27.2. Il runner si è fermato nella prima fase e il caso è registrato come S-51f.

| Fase | iOS → Android | Android → iOS | Riapertura iOS |
|---|---|---|---|
| Prima dell’attivazione | Non verificato | Non verificato | Non avviata |
| Con Protezione avanzata | Non avviato | Non avviato | Non avviata |
| Dopo la disattivazione | Non avviato | Non avviato | Non avviata |

A fine prova Supabase ha confermato, in entrambi i tentativi, Protezione avanzata disattivata e tutti gli ID preesistenti presenti. Sono stati usati il simulatore iPhone 18 Pro e l’emulatore Android temporanei dello script.

## Stato del cantiere

Aggiornato il grafo con `graphify update .`. Lo schema Xcode e `graphify-out/` erano già modificati a inizio turno e sono rimasti fuori dai commit del lavoro. S-51e resta aperto per la potatura durante la disattivazione E2E.

**Prossimo** · Collaudatore su S-51 (`e462c34`) e S-51d (`53d62d9`, `9d58e4e`). Leggere il diff, verificare il comportamento durante push consecutivi e riesaminare la prova reale bloccata da S-51f. La prova resta da completare su un simulatore funzionante.
