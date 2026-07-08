# MoneyTracker — Istruzioni per Claude

## Struttura cartella (immutabile)

```
MoneyTracker/          ← source Swift (Views/, Domain/, Models/, Auth/, ...)
MoneyTracker.xcodeproj ← progetto Xcode
MoneyTrackerTests/     ← unit test XCTest
graphify-out/          ← knowledge graph del progetto
docs/
├── MoneyTracker.md    ← documento master (sorgente)
└── MoneyTracker.pdf   ← documento master (PDF distribuibile)
```

Non aggiungere altri file o cartelle nella root. Non creare nuovi documenti.
L'unico documento di riferimento è `docs/MoneyTracker.pdf` (generato da `docs/MoneyTracker.md`).

## Workflow checkpoint

Ogni volta che si fa un checkpoint significativo, nell'ordine:

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

## Graphify

Il grafo `graphify-out/graph.json` è già costruito. Per domande sul codebase:
`/graphify query "domanda"`

Per aggiornare il grafo dopo modifiche al codice:
`/graphify --update`
