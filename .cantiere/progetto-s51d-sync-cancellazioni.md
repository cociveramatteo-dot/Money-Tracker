# Progetto S-51d — cancellazioni nella sync (iOS + Android)

> Architetto (Claude Code · Opus), 2026-11-27. Copre anche S-51c (resurrezione). Riferimenti: S-51b (prova reale),
> `.cantiere/progetto-e2e-sync.md` §2 (niente updated_at/tombstone: cancellazione = riga assente; resta vero).

## 1. Causa

**iOS.** `SyncService.upload(…)` in modalità `.incremental` (`MoneyTracker/Sync/SyncService.swift:805-875`) per OGNI
tabella chiama `prune` → `deleteOrphans` (`:1143-1152`), che cancella sul server `remoteIds − localIds`. Il push parte
sempre PRIMA del pull: `manualRefresh` (`:570-578`), `syncOnForeground` (`:480-488`), `schedulePush` → `pushResilient`
(`:622-640`, `:441`), e in E2E `performE2ESync` (`SyncService+E2E.swift:154-157`, stessa `upload` col vault). Quindi
qualunque riga creata da un altro dispositivo dopo l'ultimo pull di questo telefono è «orfana» e viene cancellata
dal server prima di poter essere scaricata. Colpisce **tutte e cinque le tabelle** (conti, movimenti, budget,
obiettivi, ricorrenze), non solo i movimenti; in chiaro e nel vault (`VaultRemote.delete` filtra per key_id, ma i
nuovi record hanno la chiave attiva). Il test esistente `SyncServiceFlagOffTests.pushUploadsInOrderAndDeletesOnlyCurrentUsersOrphans`
(`MoneyTrackerTests/SyncServiceFlagOffTests.swift:12-51`) codifica proprio questo comportamento: un orfano mai visto
dal dispositivo viene cancellato. L'assunto di S-51 («istantanea completa») vale solo per il pull, non per il push.

**Android: stesso difetto.** `SyncEngine.pushInternal` (`…/sync/SyncEngine.kt:131-167`) cancella `remoteIds − localIds`
per ogni tabella (`deleteOrphans`, `:180-186`); la sessione ripresa fa push prima del pull (`syncOnLogin`, `:260-267`;
`SyncService.kt:150`). Un movimento creato su iPhone e non ancora scaricato da Android verrebbe cancellato allo
stesso modo (S-51b non l'ha visto solo perché Android ha sempre fatto pull prima che iOS creasse A).

**S-51c (resurrezione), confermata per lettura.** Android carica `it.id !in remoteTx` (`SyncEngine.kt:150`) e fa upsert
completo di conti/budget/obiettivi/ricorrenze: una riga cancellata su iOS ma ancora presente su Android torna sul
server al primo push di Android. Su iOS lo stesso vale per le quattro tabelle con upsert completo.

Radice comune: il push distingue solo «ce l'ho / non ce l'ho», ma senza una **base** (ciò che il dispositivo sapeva
sincronizzato) non può distinguere «cancellato qui» da «creato altrove», né «creato qui» da «cancellato altrove».

## 2. Scelta: merge a tre vie sugli ID con «base» persistita per tabella

Per ogni tabella il dispositivo ricorda **B = insieme degli ID sincronizzati all'ultimo scambio riuscito** (solo UUID,
nessun dato). Al push, con L = ID locali, R = ID remoti (già letti oggi da `fetchIds`), D = movimenti sporchi:

| Caso | Significato | Azione |
|---|---|---|
| in R, non in L, **in B** | cancellato qui | cancella sul server |
| in R, non in L, non in B | creato altrove | **non toccare** (lo porta il pull) |
| in L, non in R, **in B** | cancellato altrove | **non caricare**; se sporco, toglilo da D (la cancellazione vince); il pull lo toglie in locale |
| in L, non in R, non in B | creato qui | carica (anche se la marcatura sporca è andata persa) |
| in L e in R | sincronizzato | movimenti: carica solo se in D; altre tabelle: upsert come oggi |

Aggiornamento di B:
- dopo il push di una tabella riuscito: `B = (L ∩ R) ∪ caricati` (tolti i cancellati di qua e di là);
- dopo un pull salvato con successo (`download` ritorna `true`): `B[t] = ID scaricati di t` (istantanea completa);
- `clearLocalStore` (logout/cambio utente/cancellazione account) e `reset`/`clearLocalData` Android: B eliminata.

**Avvio (B assente o di un altro utente, es. prima apertura dopo l'aggiornamento):** nessuna cancellazione remota,
nessun «cancellato altrove»; movimenti: si caricano solo i sporchi (comportamento attuale senza prune); altre tabelle
upsert come oggi; poi `B = (L ∩ R) ∪ caricati`. Prezzo accettato, una volta sola: una cancellazione fatta offline prima
dell'aggiornamento e non ancora inviata ricompare al pull successivo.

Persistenza: iOS `UserDefaults` (come `dirtyTransactionIds`), chiave `syncService.baseline`, valore JSON
`{ "user": UUID, "tables": { kind: [UUID] } }`; Android `SharedPrefsSyncState`, chiave `baseline` con stesso schema
(id minuscoli). Ordine di grandezza: 40 byte/ID → 10 000 movimenti ≈ 400 KB, accettabile; non serve altro.

Logica in una **funzione pura** identica sulle due piattaforme (testabile senza rete):
- iOS `MoneyTracker/Sync/SyncBaseline.swift` · Android `…/sync/SyncBaseline.kt`
- `plan(local: Set, remote: Set, base: Set?, dirty: Set, fullUpsert: Bool) -> (upload: Set, deleteRemote: Set, deletedElsewhere: Set, newBase: Set)`

Punti d'innesto:
- **iOS** `upload(…)`: solo per `mode == .incremental` — per ogni tabella `fetchIds` PRIMA dell'upsert, `plan`, upsert
  di `upload`, `delete(deleteRemote)` (una richiesta), `dirtyTransactionIds.subtract(caricati ∪ deletedElsewhere)`,
  salva B della tabella. `deleteOrphans` resta per le modalità di migrazione (invariate). `download(…)`: a salvataggio
  riuscito, salva B con gli ID scaricati. `clearLocalStore`: rimuove la chiave.
- **Android** `pushInternal`: quando `frozen == null` (push normale) usa `plan`; le migrazioni (`pushMigration`)
  restano come sono. `DeletionGuard` conta solo `deleteRemote` (non più tutto `R − L`). `pull()`: dopo `apply`
  riuscito (non su `Skipped`) salva B dagli ID remoti (inclusi gli `ignored`). Base azzerata in `clearLocalData` e al
  cambio utente in `syncOnLogin`.

Funziona in chiaro e nel vault: gli ID sono gli stessi UUID logici (`VaultRemote.fetchIds` = id del record con la
chiave attiva), la base è per utente e non per modalità. Migrazione E2E: non cambia (vedi §4). Nessuna modifica SQL,
nessuna modifica a Models/Persistence.

## 3. Alternative scartate

- **Registro locale delle cancellazioni intenzionali («deletedIds»)**: va catturato a ogni `context.delete` (viste,
  cascade conto→movimenti, Domain, ricorrenze, Intents in altro processo) — fuori da Sync/, fragile sui cascade, e da
  solo non risolve S-51c (resurrezione). La base si calcola tutta dentro Sync/ dagli scambi riusciti.
- **Pull prima del push**: chiude la finestra solo in parte (una riga creata altrove tra pull e push viene comunque
  cancellata), e il pull prima del push cancella/sovrascrive le modifiche locali non inviate. Più rischioso.
- **Tombstone/updated_at sul server**: richiede schema SQL, migrazione e cambi E2E; contraddice §2 del progetto E2E.
- **Smettere di cancellare dal push**: le cancellazioni intenzionali non arriverebbero mai agli altri dispositivi.

## 4. Fuori ambito (rischi residui, da tracciare)

- **S-51e (da aprire, non urgente):** le migrazioni E2E con potatura (`E2EMigrator.synchronize(…, deleteOrphans: true)`
  in `disable`, iOS `E2EMigrator.swift:119/478-489`; Android `E2EMigrator.kt:107/459`) hanno la stessa finestra: una
  riga creata altrove durante la disattivazione può essere cancellata. Finestra breve e azione rara; correggerla tocca
  le verifiche di allineamento del migratore. Non in questa sessione.
- Pull che arriva prima del push dopo una cancellazione locale (login con cloud pieno, operazione `.pull` E2E): la
  riga cancellata qui ricompare. Comportamento attuale, non peggiora.
- Conti creati in locale tra push e pull: il pull li cancella (comportamento attuale, `SyncService.swift:952-954`).
- Modifica concorrente su due dispositivi della stessa riga: vince l'ultimo upsert (come oggi, nessun updated_at).

## 5. Test di regressione

iOS (Swift Testing, nuovo file `MoneyTrackerTests/SyncBaselineTests.swift`, `InMemoryRemote` e vault in memoria
`InMemoryVaultState`, `arguments: [false, true]` per chiaro/vault dove il fixture lo consente):
1. `plan` puro: le 5 righe della tabella §2 + avvio con B assente.
2. Riga remota nuova (creata «altrove» dopo l'ultimo pull) sopravvive a `manualRefresh`/push e arriva in locale col
   pull — per movimenti E per almeno un'altra tabella (budget o conto).
3. Cancellazione intenzionale: pull (B contiene X) → delete locale X → push → X assente sul server.
4. Nessuna resurrezione: B contiene Y, server senza Y, Y locale e sporco → push non carica Y, pull lo toglie, D senza Y.
5. Avvio senza B: riga remota sconosciuta non cancellata; dopo il push B = (L∩R) ∪ caricati.
6. `clearLocalStore` elimina la base.
Aggiornare `SyncServiceFlagOffTests.pushUploadsInOrderAndDeletesOnlyCurrentUsersOrphans`: l'orfano va reso «noto»
(base pre-impostata con il suo ID) e la sequenza di chiamate attesa diventa fetchIds→upsert→delete per tabella. È un
test esistente modificato perché codifica il bug: dichiararlo in CONSEGNA e DECISIONI. Stessa cosa per eventuali
altri test che falliscono per lo stesso motivo (solo quelli; nient'altro).

Android (JUnit, `SyncFakes`): `SyncBaselineTest` (stessi casi puri) + in `SyncEngineTest`: riga remota nuova
sopravvive al push; cancellazione locale propagata dopo un pull; S-51c — movimento cancellato altrove non ricaricato;
avvio senza base. Aggiornare `pushUploadsDirtyAndMissingAndDeletesOrphansWithOneRequestEach` (`SyncEngineTest.kt:140`)
allo stesso modo del test iOS.

Verifica finale: `03_CODICE/bucktrail-android/scripts/prova-due-dispositivi.py` su Supabase reale (le tre fasi):
atteso B presente su iOS e riapertura OK.

## 6. Decisione da registrare (la scrive Codex in `.cantiere/DECISIONI.md`)

«S-51d: la sync cancella sul server solo gli ID presenti nella base locale (ultimo scambio riuscito) e assenti in
locale; non carica gli ID della base assenti sul server. Base per utente e per tabella in UserDefaults/SharedPreferences.
Scartati: registro delle cancellazioni, pull prima del push, tombstone SQL. Migrazioni E2E invariate (S-51e).»

## 7. Prompt per Codex (una sessione)

Lancio (Terminale, nuova scheda): `codex --yolo -C /Users/matteo/Desktop/APP/MoneyTracker`

```
Sei l'impresa (Codex) del cantiere MoneyTracker, ramo redesign-sentiero. Leggi AGENTS.md e
.cantiere/REGOLE-PROGETTO.md, poi fai l'inizio turno (§4). Task: S-51d (BUG CRITICO) in .cantiere/PIANO.md.
Il progetto completo è .cantiere/progetto-s51d-sync-cancellazioni.md: leggilo tutto, è vincolante (§1 causa,
§2 scelta, §5 test). Autorizzazione di Matteo a toccare MoneyTracker/Sync/ e la sync Android per S-51/S-51d.
NON toccare Models/Persistence, E2EMigrator (iOS e Android), viste, schema SQL.

Quota limitata: niente lavoro superfluo, niente refactor, niente pulizie. Ordine di priorità, chiudi ogni fase
prima della successiva e, se la quota finisce, chiudi il turno con ciò che è fatto:
1. iOS: nuovo MoneyTracker/Sync/SyncBaseline.swift (funzione pura plan, §2) e innesto in SyncService.upload
   (solo mode .incremental), download (a salvataggio riuscito) e clearLocalStore. Test MoneyTrackerTests/
   SyncBaselineTests.swift (casi §5) + aggiornamento del solo test esistente che codifica il bug (§5).
   Esegui SOLO i test di sync interessati (SyncBaselineTests, SyncServiceFlagOffTests, SyncLostTransactionTests,
   E2EMigratorTests, RecurringRuleSyncTests) con xcodebuild -only-testing; non lanciare la suite UI.
   Commit: [impresa] S-51d iOS: base di sync, niente cancellazione dei record nuovi remoti
2. Android: SyncBaseline.kt + innesto in SyncEngine.pushInternal (solo push normale, frozen == null), pull()
   (dopo apply riuscito), clearLocalData/cambio utente, SharedPrefsSyncState (chiave baseline); DeletionGuard
   conta solo le cancellazioni della base. Test §5 + aggiornamento SyncEngineTest.kt:140.
   Esegui ./gradlew testDebugUnitTest (in 03_CODICE/bucktrail-android). Commit: [impresa] S-51d Android: base di sync (copre S-51c)
3. Rilancia la prova reale 03_CODICE/bucktrail-android/scripts/prova-due-dispositivi.py (README in
   03_CODICE/bucktrail-android/README.md; credenziali solo da ~/.config/moneytracker/test-account.env, mai nei
   log). Riporta in CONSEGNA la tabella delle tre fasi.

Fine turno come AGENTS.md §4: S-51d e S-51c a [~] con esito, S-51b [~] se la prova reale passa (altrimenti resta
[!] con il motivo), riga in DIARIO, CONSEGNA riscritta, decisione §6 in DECISIONI.md, graphify update .
Commit solo dei file del tuo lavoro + .cantiere/ (mai git add -A). NON committare
MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme né graphify-out/ se non sono tuoi.
Chiudi col cartellino; prossimo: collaudatore su S-51 + S-51d.
```
