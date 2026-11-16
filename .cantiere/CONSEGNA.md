# CONSEGNA — S-32 (impresa, Codex · GPT-6)

Ramo `fix-demo-showcase-test`, creato dal main richiesto `ca9d50c`. Nessun push/merge.

## Diagnosi verificata
- Il vecchio `/tmp/mt-main-demo.log` rimanda a `/tmp/mt-main-demo-1794865269.xcresult`: xcresulttool riporta «Test crashed with signal kill», durante il setup. Non prova il difetto del tap.
- Test originale isolato: verde (`/tmp/mt-s32-baseline.log`). Nel run completo originale: rosso alla riga 29 (`/tmp/mt-s32-full-baseline.log`). Run diagnostico interrotto dopo la riproduzione per finalizzare ed estrarre il bundle.
- Bundle riproduzione: `Test-MoneyTracker-2026.11.16_22-56-41-+0100.xcresult` in DerivedData/Logs/Test. Allegati estratti in `/tmp/mt-s32-failure`; video `7B013782-3145-49D0-B794-FDA83C023134.mp4`. A 37 s la card Bolletta Enel è in basso, azione sotto la tab bar; a 40 s lo swipe successivo l’ha oltrepassata. Fotogrammi `/tmp/mt-s32-at37.png` e `/tmp/mt-s32-at40.png`.
- Causa: test fragile. Le regole non hanno ordinamento fisso; gli swipe ampi sull’app possono saltare la porzione tappabile tra header fisso e tab bar. Nessun difetto della vista dimostrato.

## Modifica minima
Solo `MoneyTrackerUITests/DemoShowcaseUITests.swift`: usa la ricerca per nome esistente tramite helper di focus già presente, poi attende `hittable` (5 s) e apre la stessa Bolletta Enel. Asserzione sull’editor e tutte le catture conservate. Nessun altro test, vista, dato demo o zona protetta modificato. Grafo consultato con graphify query, non modificato.

## Verifiche
- Test corretto isolato verde: `/tmp/mt-s32-fixed-alone.log` (68,343 s).
- Run finale completo concluso: `/tmp/mt-s32-full-fixed.log`; 90 unit verdi, UI 44/45 verdi, demo verde anche nella suite (69,251 s), 4/4 UI S-6 verdi. Exit 65 per il solo test estraneo descritto sotto. Durata UI circa 32 minuti.
- Bundle finale: `/Users/matteo/Library/Developer/Xcode/DerivedData/MoneyTracker-ccjguvvnbihhyiemgfhjfvaiqfwa/Logs/Test/Test-MoneyTracker-2026.11.16_23-06-23-+0100.xcresult`.
- `git diff --check` pulito.

## Aperto — S-33
`RecurrenceFlowUITests.testCreateEditAndDeleteScheduledSeries` fallisce alla riga 100: manca la voce «Ricorrenza» dopo il long press sul movimento. Causa e preesistenza non verificate; non attribuito a S-32. Nessun altro test modificato o indebolito. La richiesta vieta di toccare altri test: fermata l'implementazione a S-32, task separato [?] nel PIANO e istruzioni in PER-MATTEO. Il requisito di suite interamente verde non è soddisfatto; non dichiarare S-32 chiuso [x].

## Chiusura turno — 2026-11-16 23:39
Solo il test demo e i file di cantiere modificati; nessun file estraneo pendente. Nessun push/merge. STATO libero.

## Prossimo
Collaudo indipendente S-32 → collaudatore (Claude Code · Sonnet). Leggere il diff del commit, verificare causa/evidenze e integrità delle asserzioni; S-32 resta [~] fino al collaudo. Nessun push o merge senza Matteo.
