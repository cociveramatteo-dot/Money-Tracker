# CONSEGNA — il biglietto per chi entra in turno

**Da:** seconda impresa (Codex · GPT-6) · 2026-11-14 02:05 · S-13a + S-13b implementati [~]

## Fatto
- `Domain/RecurrenceCalculator.swift`: valori Sendable senza SwiftData; gregoriano, fuso locale esplicito/iniettabile, mezzogiorno; mensili ancorate, annuali bisestili, settimanali con giorni; intervalli [inizio, fine), fine regola inclusiva per giorno originale; skip/override e codec JSON difensivo, importi Decimal/stringa; UUIDv5 SHA-1 con vettore RFC verificato. Override fuori mese ignorato difensivamente.
- `Models/RecurringRule.swift`: nuova entità, accountId senza relazione, date iniziali/finali normalizzate; nessuna conversione di ricorrenti legacy.
- `Persistence/SchemaMigration.swift`: SchemaV3 = V2 + RecurringRule, stage lightweight V2→V3. SwiftData accetta i modelli condivisi: ripiego di congelamento V2 non necessario.
- App e IntentContainer usano V3 con lo stesso piano. Transaction/Account, Sync, viste e vecchio motore invariati.
- Nuovi test calculator (10 funzioni, con casi parametrizzati); sole aggiunte a SchemaMigrationTests (3 test): store V2→V3 con template/copia e Decimal/relazioni invariati, persistenza regola su disco, percorso V1→V3. Test V1→V2 originale invariato.

## Verifica effettiva
- Simulatore `37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`.
- S-13a isolato: 10 test verdi (`/tmp/moneytracker-s13a.log`).
- `xcodebuild ... build test`: BUILD SUCCEEDED; 39 unit verdi; **10 UI verdi, 2 falliti** (`/tmp/moneytracker-s13-build.log`).
- Dopo shutdown all + boot: tutti i **40 unit verdi** (27 esistenti + 13 nuovi, incluso V1→V3 aggiunto durante la prima build); i due UI riprovati falliscono ancora (`/tmp/moneytracker-s13-recheck.log`).
- Fallimenti: NavigationStressUITests.testAddMultipleTransactionsThenDeleteAll:55 e TransactionFlowUITests.testAddTransactionWithoutCategoryDefaultsToAltro:68: la ricerca StaticText del nome appena salvato non trova la riga. Causa non dimostrata, nessuna attribuzione al nuovo schema. Registrati in S-15, test e viste non alterati. **La verifica richiesta 12 UI verdi non è raggiunta.**
- `git diff --check` OK. Riesame locale: separazione puro/persistenza, Decimal, nessuna scrittura su dati legacy nel nuovo stage, limiti calendario, nessuna nuova stringa UI; resta necessario il collaudo indipendente e non si dichiara Commissione Suprema superata.
- Grafo aggiornato con `graphify update .` (AST, nessuna API). Avviso del tool: 9 file JSON di metadati/asset senza nodi. Backup automatico spostato in `/tmp/moneytracker-s13-graphify-backup`, fuori da git.

## Aperto
- S-13a e b attendono collaudatore, stato [~]. S-15: diagnosticare e ripristinare i due UI falliti senza indebolire test.
- Il test "0 transazioni nuove dopo materializeDue" va in S-13c: il materializer ancora non esiste. Qui l'apertura/migrazione lascia 0 regole e nessuna transazione nuova.
- Vecchio motore ancora attivo per scelta del perimetro: lo spegne S-13c. Nessuna tabella Supabase creata o codice Sync aggiunto.
- Nessuna modifica preesistente trovata a inizio turno; commit limitato ai file propri, grafo e documenti del turno. Nessun merge/push.

## Prossimo: S-13c → Codex
📍 Nuova sessione Codex nella cartella del cantiere, stesso ramo. ▶️ Prompt completo:

```text
Entra in turno secondo AGENTS.md §4, solo se STATO è libero. Sul ramo redesign-sentiero esegui solo S-13c: leggi CONSEGNA.md, D-008/D-009, scheda S-13 e piano-s13.md (fonte di verità), poi graphify query prima del codice. S-13a+b sono implementati [~], 40 unit verdi; due UI falliscono e sono registrati in S-15: non modificarli né cambiare viste per aggirarli. Crea RecurringMaterializer e test: @MainActor sul mainContext, Decimal, UUIDv5 del calculator, watermark per regola, materializzazione di tutto il mese corrente come pianificato, recupero mesi mancanti massimo 36, idempotenza e copie cancellate/modificate non ricreate o sovrascritte. Una regola nuova non genera storico; fatti e saldi protetti. Spegni/elimina solo il vecchio RecurringTransactionEngine e i suoi test autorizzati da D-009; aggiorna gli avvii in MoneyTrackerApp dopo sync login/foreground, scenePhase e significantTimeChange come nel piano, anche demo/offline. Non convertire o cancellare dati legacy, non toccare Sync/, viste, Transaction o Account. Test di materializer e invarianza; build e test sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48; se runner bloccato shutdown all e boot. Fine turno: documenti, S-13c [~] mai [x], commit mirato, STATO libero e cartellino.
```
↩️ Riportare esito del cartellino e commit; S-15 resta aperto al collaudatore.
