# CHECKPOINT — MoneyTracker

**Data:** 2026-11-28 12:06 · **Tag:** da creare (`checkpoint-2026-11-28-1206`) · **Ramo:** `redesign-sentiero` · **Fatto da:** capocantiere (Claude Code · Sonnet), checkpoint COMPLETO (ultimo veloce: 2026-11-28 00:59)

## Siamo qui

- Sentiero completo e collaudato: S-73a..g e S-73i chiusi (Conti come la Home, data futura = pianificato, sezione «Da confermare» approvata da Matteo). Restano in coda bassa priorità S-73h (icona) e S-73j (2 test cache).
- Commissione Suprema giro 2: 10/10/10/10/10/10. Test iOS 265/265 + UI 5/5, Android 370/370, lint verde.
- Prossimo passo: decidere con Matteo il merge di `redesign-sentiero` su `main`. Poi S-80 (mockup S-80m) oppure S-71 import (progetto S-71p).

## Fatto dall'ultimo checkpoint (00:59)

| Quando | Chi (strumento · modello) | Cosa |
|---|---|---|
| 00:59–03:13 | impresa + collaudatore (Antigravity · Gemini 4 Hydrogen; Claude Code · Sonnet) | S-73a..e (Conti come Home, data futura = pianificato, swipe), collaudo ok (iOS 255/255, Android 366/366) |
| 03:04 | impresa (Antigravity) | S-70h (segnaposto «0» e conteggio conti leggero), S-73f (sezione «Da confermare»); S-52a chiuso (senza conto 13/209) |
| 10:25 | impresa (Antigravity) | S-73g (conferma ✓ 44pt/48dp, card identica Home/Movimenti, conti archiviati esclusi, ja «確認待ち») |
| 10:50 | collaudatore (Claude Code · Sonnet) | collaudo ok S-73g; Commissione giro 1 10/9/10/9/9/10, aperto S-73i e proposte |
| 11:19 | impresa (Antigravity) | S-73i (interruttore «Già effettuato» per pianificati scaduti), `ProjectionRules.swift`, cache iOS |
| 12:05 | collaudatore (Claude Code · Sonnet) | Commissione giro 2 10/10/10/10/10/10; S-73i [x] |
| 01:51 | architetto (Claude Code · Opus) | progetto spese divise e rimborsi (S-80), approvato da Matteo, parcheggiato dopo Sentiero |
| 12:06 | capocantiere (checkpoint) | docs/MoneyTracker.md v3.31 e PDF rigenerato (12:07) |

Prove reali di Matteo (sync due dispositivi, scorciatoie Android) fatte e spuntate.

## Stato di salute

| Controllo | Esito | Note |
|---|---|---|
| Build / test / lint | 🟢 | iOS 265/265 + 1 live skip, UI 5/5; Android 370/370; lint verde. Lanciare sempre tutto il target (mai `-only-testing` su singole suite) |
| Guardiano notturno | 🔴 | ultimo rapporto 28/11: solo CORS `cloudflareinsights` sul sito in locale (127.0.0.1). Non riguarda l'app |
| Pagella (misurata) | 🟡 | 84/100. Codice, sicurezza, lingue 100. Bassi solo sito: robustezza 32, velocità 56 |
| Lingue allineate | 🟢 | 7 lingue su iOS e Android per le voci nuove (S-73f/g/i, S-70h) |
| Sicurezza | 🟢 | Zone intoccabili non toccate (`Domain/` solo `ProjectionRules` fuori dal dominio, `Models/`, `Sync/`, `Auth/`, `Intents/`, `Export/`) |
| Ordine e spazio | 🟡 | 23 GB liberi (soglia 35). Pulizia tmp -38 MB. Build Android rigenerabili ~110 MB ancora presenti (non verificato se cancellate) |
| Grafo aggiornato | 🟢 | 6816 nodi, 15141 archi, 544 comunità |
| Documento master | 🟢 | `docs/MoneyTracker.md` v3.31, PDF rigenerato 2026-11-28 12:07 (34 pagine) |

## Bug

- Risolti: S-73 (Conti e «A conti fatti» diversi dalla Home); S-70h; S-52a; S-73e (fissa «già effettuata» non più riportata a pianificata).
- Aperti: nessun bug. Bassa priorità: S-73h (icona coerente) → Copilot; S-73j (2 test cache) → Copilot.

## Cantiere

- Spostati/rinominati: nessuno.
- Eliminati: solo temporanei (-38 MB in `.cantiere/tmp`, S-54/55-56/70/72/72f/73).
- Magazzino: CATALOGO 54 file. MAPPA aggiornata con S-80.
- Da confermare (Matteo): vedi «Cose che deve fare Matteo».

## Struttura (dal grafo)

- Codice iOS in `MoneyTracker/`, Android in `03_CODICE/bucktrail-android/`. Nuovo file `MoneyTracker/Views/ProjectionRules.swift` (regola previsione fuori dalle View).
- Il progetto S-80 (spese divise) è solo progettato in `.cantiere/progetto-split-rimborsi.md`: nessun codice.

## Domani si riparte così

1. Sessione nuova nella cartella del cantiere → «riprendiamo».
2. Matteo decide il merge di `redesign-sentiero` su `main` (Sentiero completo e collaudato). Non si fa senza il suo ok.
3. Bassa priorità → Copilot: S-73h. Prompt: «Cantiere /Users/matteo/Desktop/APP/MoneyTracker, ramo redesign-sentiero. Leggi AGENTS.md e .cantiere/PIANO.md e fai SOLO S-73h: la card «Da confermare» mostra l'icona della categoria, le righe normali no. Applica la stessa regola: `resolvedCategorySymbol` su iOS (`TransactionsView.swift:531`, `DashboardView.swift:520`), `resolvedCategoryIcon` su Android. Non cambiare calcoli. Verifica: intero target MoneyTrackerTests verde (mai -only-testing), Android assembleDebug lintDebug testDebugUnitTest verdi. Non toccare Domain/, Models/, Sync/, Auth/, Intents/, Export/ né MoneyTracker.xcscheme. Segna [~] in PIANO, scrivi CONSEGNA e una riga DIARIO, committa solo i tuoi file con "[impresa] … (S-73h)".»
4. Bassa priorità → Copilot: S-73j. Prompt: «Cantiere /Users/matteo/Desktop/APP/MoneyTracker, ramo redesign-sentiero. Leggi AGENTS.md e .cantiere/PIANO.md e fai SOLO S-73j, solo test nuovi, nessun codice di produzione: (1) in ProjectionAndOverdueCacheTests il controllo dopo la conferma (880 prima e dopo) deve usare un caso in cui il valore atteso cambia; (2) test FilteredCache che cambia categoria e importo min/max con la stessa cache. Verifica: intero target MoneyTrackerTests verde (mai -only-testing). Segna [~] in PIANO, scrivi CONSEGNA e una riga DIARIO, committa solo i tuoi file con "[impresa] … (S-73j)".»
5. Poi collaudatore su S-73h e S-73j. Dopo il merge (con ok di Matteo): S-80m (mockup S-80, Antigravity) oppure S-71p (progetto import, architetto).

## Cose che deve fare Matteo

- [ ] Merge di `redesign-sentiero` su `main`: dire sì o no (Sentiero completo e collaudato).
- [ ] S-80 spese divise: dopo Sentiero, parte solo con il suo via libera (progetto approvato in DECISIONI 2026-11-28 · S-80).
- [ ] Pulizia disco: cancellare build Android rigenerabili (~110 MB) e `.gradle`/temporanei SOCIAL (`_out`, `_work`). Dire sì o no. Non verificato.
- [ ] Doppioni: `screenshot-app-iphone/` vs `screenshot-app/`; `social-manuale-versioni/` vs `non-committati-2026-11-18/`. Cosa tenere.
- [ ] NotebookLM: 6 fonti da aggiungere (`.cantiere/PER-MATTEO.md`).
- [ ] Banca (S-60): risposta di Enable Banking e 4 domande al professionista (`.cantiere/PER-MATTEO.md`).
- [ ] Approvazioni: nessuna voce ⏳ in `.cantiere/APPROVAZIONI.md` (trovata solo la legenda).

## Suggerimenti · Rischi

- Il guardiano è 🔴 solo per il beacon CORS del sito in locale: non blocca l'app. Non verificato se il prossimo giro notturno sarà verde.
- Pagella 84/100 solo per il sito (robustezza 32, velocità 56, LCP 4,2 s). Nessun task assegnato: non verificato se entra nel lancio.
- `AGENTS.md` §2 dice ancora «Antigravity sospeso fino al 2026-11-20»: i fatti dicono che lavora. Da aggiornare, non fatto in questo turno.
- `MoneyTracker.xcscheme` locale (`-E2EEnabled YES`): non va committato.
- Tag `checkpoint-2026-11-28-1206` e commit del checkpoint: da fare dal capocantiere.
