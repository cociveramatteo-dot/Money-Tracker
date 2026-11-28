# CHECKPOINT — MoneyTracker

**Data:** 2026-11-28 00:59 · **Tag:** `checkpoint-2026-11-28-0059` · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet), checkpoint VELOCE (ultimo completo: 2026-11-27 20:37)

## Siamo qui

- Chiusi dopo il checkpoint del 27/11: S-70a/a2/b/e/f/i/j/k e S-70d (doppio tap «Aggiungi movimento» ok sull'iPhone con Categoria vuota; «Chiedi ogni volta» non supportato, Matteo rinuncia), S-72b/a/d/c/e (collaudo ok), S-72f (ok Matteo).
- S-73 (Conti: la «→» e «A conti fatti» contano le pianificate di tutti i mesi): diagnosi architetto `d148ace`, approvata da Matteo con opzione B per le date (data futura ⇒ pianificata su iOS, come Android). Vincolo: in Conti non si toglie niente, i numeri diventano solo giusti.
- Test: iOS 249/249 (54 suite), Android 361/361. `MoneyTracker.xcscheme` modificato in locale: non si committa.

## Fatto dall'ultimo checkpoint (16:14)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 17:01 | capocantiere (Claude Code · Sonnet) | S-53a (`3d3bb4b`): backup E2E cancellato per confronto /var vs /private/var; fix, 30/30 test E2E iOS |
| 17:25 | collaudatore (Claude Code · Sonnet) | S-53a/b collaudo ok; prova di Matteo S-53b ok |
| 18:20 | impresa (Antigravity · Gemini 4 Hydrogen) | S-54, S-55, S-56 (`04ed36b`, `0f12838`, `3af6702`, `25073ed`) |
| 18:26 | collaudatore (Claude Code · Sonnet) | S-54/55/56 collaudo ok; corretto ordine pianificati Android (`MovementsScreen.kt:252`) |
| 18:48 | capocantiere + Matteo | S-50 chiuso: prova reale su iPhone e Android ok, S-54/55/56 ok sui telefoni |
| 20:20 | impresa (Antigravity · Gemini 4 Hydrogen) | S-50g2 (`8c0b06e`, filtro guardiano); S-50z (`d0dd4e3`, script prova R8 Android) |
| 20:29 | collaudatore (Claude Code · Sonnet) | S-50g2 e S-50z collaudo ok |
| fase 1 | capocantiere (checkpoint) | 2 correzioni piccole, NON ancora committate: `FAKE_PASSWORD` in `prova-release-r8.py` (falso allarme segreti); `TransactionDisplayOrder.swift` calcola il giorno una volta per movimento |

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test | 🟢 | iOS 249/249 (S-70k), Android 361/361 (S-72f). Con `-only-testing` su singole `@Suite` risultano 0 test: lanciare tutto il target |
| Guardiano notturno | 🔴 | ultimo rapporto 27/11 10:45 (beacon cloudflare, falso positivo); non riscaricato in questo veloce |
| Pagella (misurata) | 🟡 | 85/100, non consegnabile (robustezza 34, velocità 56) |
| Magazzino | 🟡 | `magazzino.py`: «c'è da sistemare» (cartelle `04_CONSEGNE/`, swiftpm configuration); collegamenti 🟢 |
| Spazio | 🟡 | 21 GB liberi (soglia 35) |
| Grafo | 🟢 | `graphify update .` ok |
| Biblioteca | 🟡 | 2 fonti da aggiungere al notebook (licenze font OFL, poco utili) |

## Bug

- Risolti: S-52 (113 movimenti scollegati sul server, ricollegati); S-53 (backup E2E su telefono); S-54 ordine movimenti; S-55 occhio sui campi segreti; S-56 chiave di recupero con trattini; S-50g2 filtro guardiano (locale); falso allarme `FAKE_PASSWORD`; performance `TransactionDisplayOrder` (non committati).
- Aperti: S-70g errore Xcode `sortedForDisplay` (risolto con Clean Build Folder, Matteo dice sparito: chiudibile); S-70a, a2, b, e, f → Antigravity; guardiano 🔴 fino al push.

## Cantiere

- Spostati: nessuno. Magazzino: CATALOGO aggiornato (54 file, 47 descrizioni), nessuno spostato.
- Eliminati: cartella vuota `.claude/worktrees`.
- Da confermare (Matteo): vedi «Cose che deve fare Matteo».

## Struttura (dal grafo)

- 6154 nodi (+130), 13768 archi. Modifiche strutturali: nessuna segnalata.
- Cartelle di root invariate. Codice Swift in `MoneyTracker/`, Android in `03_CODICE/bucktrail-android/`.

## Domani si riparte così

1. Sessione nuova nella cartella del cantiere → «riprendiamo».
2. S-73a, b, c, d, e → Antigravity (`agy`). Prompt: «Cantiere /Users/matteo/Desktop/APP/MoneyTracker, ramo redesign-sentiero. Leggi AGENTS.md e .cantiere/PIANO.md e fai SOLO S-73a, S-73b, S-73c, S-73d, S-73e, in quest'ordine (diagnosi e specifiche nel PIANO, sezione S-73; decisione approvata da Matteo in DECISIONI 2026-11-28 S-73: opzione B). Vincolo di Matteo: in Conti non si toglie e non si sposta niente, «A conti fatti», la «→» sotto ogni conto e tutto il resto restano dove sono, cambia solo il numero, che diventa uguale alla regola della Home. Domain/ e AccountBalanceCache non si toccano, salvo quanto scritto esplicitamente nel PIANO. Un commit per task, iOS e Android. Verifica: tutto il target MoneyTrackerTests verde (non usare -only-testing su singole @Suite), Android assembleDebug lintDebug testDebugUnitTest verdi, test nuovi come da PIANO, screenshot di Conti chiaro e scuro in .cantiere/tmp/s73/. Alla fine segna [~] nel PIANO, scrivi CONSEGNA e una riga in DIARIO, committa solo i tuoi file con "[impresa] … (S-73x)". Non toccare MoneyTracker.xcscheme.»
3. Poi collaudatore su S-73 (tocca i saldi: collaudo vero) e prova di Matteo in Conti.
4. Il prossimo checkpoint deve essere COMPLETO (con Commissione Suprema e documento master).

## Cose che deve fare Matteo

- [ ] Pulizia disco (22 GB liberi): cancellare output rigenerabili Android (~113 MB), `.gradle` (21 MB), temporanei `SOCIAL/caroselli/v2/_out` e `_work`, `.cantiere/tmp` (12 MB). Dimmi sì o no.
- [ ] Doppione `screenshot-app-iphone/` vs `screenshot-app/` (13 file): quale tenere.
- [ ] Doppioni del manuale social in `social-manuale-versioni/` e `non-committati-2026-11-18/`: cosa tenere.
- [ ] S-70g: confermare che l'errore Xcode non torna.
- [ ] S-70d: prova del doppio tap sul telefono (dopo S-70a) e ok agli screenshot S-70b.
- [ ] Ok per il merge di `redesign-sentiero` su `main` (quando vuoi).
- [ ] Banca: risposta di Enable Banking e 4 domande al professionista (`.cantiere/PER-MATTEO.md`).
- [ ] NotebookLM: 6 fonti (`.cantiere/PER-MATTEO.md`).
- [ ] TikTok: nome e account Business. SC-2: materiale faceless.
- [ ] Approvazioni in attesa: nessuna voce ⏳ trovata in `APPROVAZIONI.md`.

## Suggerimenti · Rischi

- Il guardiano è 🔴 per un falso positivo: si chiude con il push del filtro S-50g2.
- `AGENTS.md` §2 dice ancora «Antigravity sospeso fino al 2026-11-20». I fatti dicono che lavora (S-54/55/56, S-50g2). Da aggiornare: non fatto in questo turno.
- `MoneyTracker.xcscheme` locale (`-E2EEnabled YES`): non va committato.
- Le 2 correzioni della fase 1 e le modifiche ai grafi entrano nel commit del checkpoint (non fatto dal segretario).
- Velocità landing LCP 4,2 s: nessun task assegnato (non verificato).
