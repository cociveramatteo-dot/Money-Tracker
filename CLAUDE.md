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
