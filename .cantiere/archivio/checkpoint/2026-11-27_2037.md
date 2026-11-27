# CHECKPOINT — MoneyTracker

**Data:** 2026-11-27 20:37 · **Tag:** `checkpoint-2026-11-27-2037` · **Ramo:** `redesign-sentiero` · **Fatto da:** segretario (Claude Code · Haiku 5.5) su dati del capocantiere, checkpoint COMPLETO (fase 6)

## Siamo qui

- S-50 (Protezione avanzata) chiuso dopo la prova reale di Matteo su iPhone e Android. Chiusi anche S-52, S-53, S-54, S-55, S-56, S-50g2, S-50z (collaudi ok).
- Test verdi: iOS 211 (46 suite), Android 343. Commissione Suprema 6×10/10. Il file `MoneyTracker.xcscheme` resta modificato in locale: non si committa.
- Prossimo: S-70a, a2, b, e, f → Antigravity. S-70g chiudibile. S-71 (import) solo dopo, con ok di Matteo, all'architetto. Merge su `main` solo con ok di Matteo.

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
| Build / test | 🟢 | iOS 211 test (46 suite). Android 343. Attenzione: con `-only-testing` su singole `@Suite` Swift Testing risultano 0 test ma «SUCCEEDED»: lanciare tutto il target `MoneyTrackerTests` |
| Guardiano notturno | 🔴 | giro 27/11 10:45: beacon cloudflareinsights ×8 + 3 avvisi heading-order. Falso positivo. Il filtro S-50g2 va online col push di questo checkpoint: atteso 🟢/🟡 dal prossimo giro (non verificato) |
| Pagella (misurata) | 🟡 | 85/100, non consegnabile. Robustezza 34 (guardiano). Velocità 56 (LCP landing 4,2 s su telefono) |
| Commissione Suprema | 🟢 | 6 giudici a 10/10 (fase 1) |
| Bilingue | 🟢 | 4 coppie, 0 errori |
| Sicurezza | 🟡 | `collaudo.sh`: solo `.gradle/executionHistory.bin` 19,6 MB (cache non tracciata). Nessuna chiave reale nel codice |
| Ordine e spazio | 🟡 | disco 22 GB liberi (soglia 35 GB). Pulizia proposta: vedi Cantiere |
| Grafo | 🟢 | `graphify update .` ok. Avviso: 18 file json senza nodi (non verificato se rilevante) |

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
2. Primo lavoro: S-70a, S-70a2, S-70b, S-70e, S-70f → Antigravity. Prompt: «Cantiere /Users/matteo/Desktop/APP/MoneyTracker, ramo redesign-sentiero. Leggi AGENTS.md e .cantiere/PIANO.md e fai SOLO i task S-70a, S-70a2, S-70b, S-70e, S-70f. Per S-70b vale la specifica di Matteo del 2026-11-27 19:05 scritta nel PIANO. Verifica: build e test iOS e Android verdi, screenshot in .cantiere/tmp/. Alla fine segna [~] nel PIANO, scrivi CONSEGNA e una riga in DIARIO, committa solo i tuoi file con "[impresa] … (S-70)". Non toccare MoneyTracker.xcscheme.»
3. Dopo il punto 2: Matteo prova il doppio tap sul telefono (S-70d), poi collaudatore.
4. Capocantiere: commit e push del checkpoint; chiudere S-70g se Matteo conferma.

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
