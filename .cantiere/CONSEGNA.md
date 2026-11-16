# CONSEGNA — S-18

**Da:** impresa (Codex · GPT-6), 2026-11-16 09:40. Ramo `redesign-sentiero`. Nessun push/merge.

## Proposta e implementazione
Matteo ha approvato esplicitamente in chat prima di implementare: card serie Sentiero arrotondata, icona categoria 38×38, nome/importo, frequenza/stato e pulsante prossima data; virtuali con struttura righe Movimenti, icona tratteggiata e importo ambra, data e avviso esclusa dai totali. Registrato in APPROVAZIONI.md.
- Unico file app modificato: Views/ProgrammedRuleCard.swift (contiene anche VirtualOccurrenceRow). Token adattivi e font Sentiero esistenti, icone categoria, card raggio 18/bordo, separatore, pulsanti con target minimo 44 pt, ViewThatFits per disporre nome/importo verticalmente quando necessario. Avviso virtuale senza lineLimit, data sempre presente.
- Identico calcolo prossima occorrenza, cache, fallback serie terminata e callback editor. Nessuna modifica a logica, saldi, totali, zone intoccabili o test esistenti. Theme.swift non necessitava modifiche.
- Aggiunto RecurrenceAppearanceUITests.swift per acquisizioni e apertura editor nelle quattro configurazioni. Il test dark va eseguito separatamente con il simulatore impostato dark via simctl (commento nel file); i launch defaults AppleInterfaceStyle non controllano l'aspetto del simulatore.

## Verifiche
- Build + **80 unit e 7 UI verdi** (4 acquisizioni + 3 RecurrenceFlow), log `/tmp/moneytracker-s18.log`; risultato `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Run-MoneyTracker-2026.11.16_09-28-08-+0100.xcresult`.
- Primo comando sandbox fermato sui cache Xcode; comando rieseguito con autorizzazione. Nessun cambio per aggirare test.
- Nel primo run il test denominato Dark aveva prodotto immagini light: rilevato durante ispezione, non considerato prova dark. Tolto l'argomento inefficace AppleInterfaceStyle; eseguito `xcrun simctl ui 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48 appearance dark`, poi test mirato RecurrenceAppearanceUITests/testDark: **verde**, 40,878 s. Log `/tmp/moneytracker-s18-dark.log`, risultato `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Test-MoneyTracker-2026.11.16_09-37-58-+0100.xcresult`. Simulatore ripristinato light.
- Otto immagini valide (due viste × light/dark/XL/tedesco) ispezionate: card e virtuali leggibili, importi ambra, date e avvisi visibili; tedesco tradotto; XL aumenta testi e altezze. Nessuna nuova stringa. Confronto con DESIGN_HANDOFF §2/§3 MovementRow e proposta approvata; il mockup originario non rappresenta specificamente queste due nuove viste.
- Immagini light/XL/tedesco in `/tmp/moneytracker-s18-images/` (manifest, series-sheet.png, virtual-sheet.png); usare le due dark reali in `/tmp/moneytracker-s18-dark-images/` (manifest, dark-sheet.png), ignorare le prime dark nominali.
- `git diff --check` verde; graphify AST aggiornato senza LLM. Screenshot/xcresult fuori da git.

## Limiti e file esclusi
S-18 riguarda esclusivamente queste due viste, non certifica tutto il redesign. In XL la tab bar mostra etichette affollate: registrato S-28 senza modificare ContentView. Restano S-19 e Commissione S-13h.
Tutti gli artefatti graphify-out erano già modificati/non tracciati; aggiornati localmente e lasciati fuori dal commit. Nessun file estraneo incluso.

## Prossimo
Collaudo indipendente S-18 → collaudatore Claude Code (Sonnet): leggere solo il diff del commit S-18 e queste evidenze, confrontare proposta approvata e otto immagini valide; verificare callback e logica invariati, light/dark/XL/tedesco, nessuna zona intoccabile. Solo collaudatore o Matteo porta S-18 a [x]. Dopo: S-19 al redattore. Nessun push/merge.
