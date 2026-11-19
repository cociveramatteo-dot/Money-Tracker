# REGOLE DEL PROGETTO — MoneyTracker

> Valgono per **TUTTI**: Claude Code, Antigravity, Codex, Copilot, subagenti, consulenti (AGENTS.md §1 e §5 ti mandano qui).
> Prima stavano solo in CLAUDE.md, che gli altri strumenti non leggono: spostate qui il 2026-11-18 (AGENTS.md §6.14).
> Le frasi come «scrivi `/graphify` in Claude» sono comandi di Claude Code; le imprese usano `graphify update .` da terminale.


## Struttura cartella

```
MoneyTracker/          ← source Swift (Views/, Domain/, Models/, Auth/, ...) — resta qui, nessun trasloco
MoneyTracker.xcodeproj ← progetto Xcode
MoneyTrackerTests/     ← unit test XCTest
MoneyTrackerUITests/   ← UI test
graphify-out/          ← knowledge graph del progetto
SOCIAL/                ← piano di lancio social (manuale strategico, calendario, materiali)
docs/
├── MoneyTracker.md    ← documento master (sorgente)
└── MoneyTracker.pdf   ← documento master (PDF distribuibile)
.cantiere/ .agents/ AGENTS.md GEMINI.md   ← regolamento e stato del cantiere
00_CLIENTE 02_RISORSE 04_CONSEGNE         ← collegamenti al magazzino su Drive
01_PROGETTO 03_CODICE 99_DA_SMISTARE      ← cartelle del cantiere
```

Ammessi nella root **solo** le cartelle e i file elencati sopra (più i file di progetto già tracciati: `README.md`,
`TestPlan.xctestplan`, `report_notturno.md`). Non aggiungere altro. Il codice non si sposta in `03_CODICE`
(romperebbe i percorsi del progetto Xcode). L'unico documento di riferimento del prodotto è `docs/MoneyTracker.pdf`
(generato da `docs/MoneyTracker.md`); non creare nuovi documenti. Eccezione: i materiali del progetto social stanno in `SOCIAL/`.

## Progetto SOCIAL

Ogni lavoro sul lancio social (testi, format, montaggio, calendario, metriche, legale) segue **sempre** `SOCIAL/Bucktrail_Manuale_Strategico_v2.pdf`. Decisioni, soglie e calendario: `.cantiere/DECISIONI.md`, `SOCIAL/calendario-v1.md`, task SC-* in `.cantiere/PIANO.md`.

### Messaggio di brand dei social (Matteo, 2026-11-19) — da usare in OGNI contenuto
Bucktrail = **l'app unica per conti e movimenti personali**. I temi da far passare, in ogni post, titolo o caption:
1. **Design pulito e professionale** (Sentiero), semplice da usare.
2. **Tanta complessità, ben divisa e spiegata:** conti, movimenti, ricorrenze, budget, obiettivi, statistiche; ogni cosa al suo posto.
3. **C'è tutto ciò che serve**, quello che si cerca nelle app simili, **in un'app sola**.
4. **Senza abbonamento** (4,99 € una volta, «prezzo di lancio previsto» finché non è sullo Store).
5. **Basta Excel, basta pagare altri servizi (anche IA):** tutto in un'app.
**Consegna dei post a Matteo (2026-11-19):** niente AirDrop. Ogni post si esporta su Drive con `python3 SOCIAL/esporta-post.py N` in `04_CONSEGNE/social/post-N/` (cartelle `TikTok/` e `Instagram/` con le immagini numerate 01-09, copertina facoltativa, e `00 LEGGIMI - POST N.txt`). Lì dentro SOLO cose da pubblicare. Il file di testo è `.txt` semplice (non md), da copiare e incollare: giorno, ora, piattaforme, ordine dei file, musica, descrizioni, hashtag, link, passi di pubblicazione, cosa fare dopo. Si scrive in `SOCIAL/istruzioni-post/post-N.txt` (versionato) e lo script lo copia.
Cautele (manuale §1.3): niente «definitiva» o confronti con altre app per nome; niente promesse su privacy/dati verso le IA o sul cloud finché non sono verificate sul codice (l'app ha la sincronizzazione Supabase); niente dati inventati. Frase-titolo: Matteo sta scegliendo (opzioni in `SOCIAL/caroselli/presentazione-v1.md` e DECISIONI 2026-11-19).

## Workflow checkpoint

Ogni volta che si fa un checkpoint significativo, nell'ordine:

0. **Controllo qualità spietato ("Commissione Suprema")** — vedi sotto. Se anche un solo giudice non dà 10/10, correggi il codice e ripeti finché tutti i giudici non danno 10/10. Solo allora procedi allo step 1.
1. **Aggiorna** `docs/MoneyTracker.md` con le modifiche apportate (sezione Changelog + sezioni rilevanti)
2. **Rigenera il PDF**:
   ```bash
   \
   pandoc docs/MoneyTracker.md -o /tmp/mt_doc.html --standalone && \
   "/Applications/Google Chrome.app/Contents/MacOS/Google Chrome" \
     --headless --disable-gpu \
     --print-to-pdf="docs/MoneyTracker.pdf" \
     --print-to-pdf-no-header \
     "file:///tmp/mt_doc.html" 2>/dev/null
   ```
3. **Commit e push**:
   ```bash
   git add -A && git commit -m "checkpoint: [descrizione concisa]" && git push
   ```
4. **Aggiorna il grafo**: scrivi `/graphify --update` in Claude

### Commissione Suprema (controllo qualità pre-checkpoint)

Prima di ogni checkpoint, rivedi tutte le modifiche pendenti (diff rispetto all'ultimo commit) come un tribunale di 6 giudici spietati, tolleranza zero, un voto 1-10 ciascuno nel proprio dominio:

1. **Sicurezza & integrità dati** — falle di sicurezza, dati sensibili esposti, debolezze in SwiftData/Keychain/API, protezione file.
2. **Pulizia & architettura** — struttura, modularità, leggibilità, code smell, funzioni/view troppo lunghe da spezzare.
3. **Logica & matematica** — calcoli, arrotondamenti (`Decimal`), gestione del ciclo di vita dei dati, correttezza in ogni scenario.
4. **Performance & fluidità** — operazioni pesanti sul main thread, memory leak, re-render SwiftUI inutili, query non ottimizzate.
5. **Bug & robustezza** — edge case (DB vuoto, offline, input assurdi), force-unwrap pericolosi, percorsi che potrebbero far crashare l'app.
6. **Lingua & coerenza i18n/UX** — stringhe hardcoded non localizzate, coerenza tra le 7 lingue supportate, coerenza estetica/tipografica con Theme.swift.

Per ogni giudice sotto il 10/10: diagnosi precisa (file + riga) e codice esatto per risolvere il problema. Applica le correzioni, poi ripeti la valutazione. Non passare al commit finché ogni giudice non assegna 10/10.

## Graphify

Il grafo `graphify-out/graph.json` è già costruito. Per domande sul codebase:
`/graphify query "domanda"`

Per aggiornare il grafo dopo modifiche al codice:
`/graphify --update`

## graphify

This project has a knowledge graph at graphify-out/ with god nodes, community structure, and cross-file relationships.

Rules:
- For codebase questions, first run `graphify query "<question>"` when graphify-out/graph.json exists. Use `graphify path "<A>" "<B>"` for relationships and `graphify explain "<concept>"` for focused concepts. These return a scoped subgraph, usually much smaller than GRAPH_REPORT.md or raw grep output.
- If graphify-out/wiki/index.md exists, use it for broad navigation instead of raw source browsing.
- Read graphify-out/GRAPH_REPORT.md only for broad architecture review or when query/path/explain do not surface enough context.
- After modifying code, run `graphify update .` to keep the graph current (AST-only, no API cost).
