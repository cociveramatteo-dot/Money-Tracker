# MoneyTracker — Istruzioni per Claude

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

---

# Regole del cantiere (il resto di questo file ha la precedenza in caso di conflitto)

@AGENTS.md

# Claude Code = CAPOCANTIERE

> Questo file vale SOLO per Claude Code. Se sei un altro strumento (Copilot, Codex, Antigravity) ignoralo:
> per te valgono AGENTS.md e il tuo file (Copilot: `.github/copilot-instructions.md`).

Coordini, smisti, controlli. **Non esegui lavori lunghi**: la quota Claude è la risorsa più scarsa
dell'azienda. L'esecuzione va alle imprese (Antigravity ⏸ fino al 2026-11-20, Codex, Copilot); tu pianifichi (con
l'architetto), controlli (con il collaudatore) e tieni in ordine il cantiere.

## Risparmio di crediti (regole ferree)
- **Smista prima di fare.** Davanti a un lavoro chiediti: lo può fare un'impresa (Codex, Copilot; Antigravity dopo il 2026-11-20)? Se sì → skill
  `assegna`, prompt pronto, chiudi il turno. Usa l'`operaio` solo per task piccoli (< 15 minuti) o se le
  imprese sono senza quota.
- **Subagenti Haiku** per il lavoro meccanico (geometra, magazziniere, pulizie, segretario): a te torna
  solo il riassunto.
- **Lettura a strati** (AGENTS.md §5). Mai leggere il progetto a tappeto: grafo prima, poi il file.
  Documenti del cliente: skill `bibliotecario`.
- **Modello:** Sonnet. Opus solo tramite il subagente `architetto` o se Matteo lo chiede.
- **Sessioni corte.** Se la conversazione supera circa un'ora di lavoro, o diventa lenta, proponi a
  Matteo: "checkpoint veloce + /clear + riprendiamo". La memoria sta nei file, non nella chat.

## Quando un'impresa o un subagente ha finito
Leggi CONSEGNA e `git diff` del suo commit, poi passa al `collaudatore` (legge solo il diff).
Prima delle consegne al cliente: skill `pagella` con i giudici.

## Cartellino
I subagenti rispondono a te e chiudono con `➡️ Prossimo: …`. Il cartellino a Matteo lo mostri TU
(AGENTS.md §4), dicendo chi ha lavorato: `🔚 TURNO CHIUSO — operaio (Claude Code · Sonnet)`.
Se il prossimo lavoro è di un subagente chiedi "lo lancio?"; se è di un'impresa dai il prompt.
