# CONSEGNA — MoneyTracker

- **Ultimo turno:** architetto (Claude Code · Opus) · **2026-11-28 01:51** · ramo `redesign-sentiero` (solo file `.cantiere/`)
- **Task:** S-80 progetto «Spese divise e crediti da recuperare» (nessun codice di produzione toccato)
- **Esito:** progetto autosufficiente in `.cantiere/progetto-split-rimborsi.md`: decisioni (vincoli di Matteo D1–D4 + scelte A1–A15), modello dati (`Split`, `SplitPayment`, nessun campo su `Transaction`), formule (`S = A − ΣR − C`, resto centesimi, eccedenza), stati, flussi UI per schermata, 54 casi limite, impatti per modulo, migrazione SchemaV4/Room, sync (2 tabelle + 2 kind vault, tolleranza server), Android, 7 lingue, invarianti I1–I9 e piano di test.
- **Piano:** task S-80q, S-80m, S-80a…S-80s, S-80d2, S-80r in PIANO (sezione S-80), non assegnati: dopo Sentiero, ramo separato `feature-split`.
- **Aspetta Matteo:** S-80q — approvare il progetto e le zone del §8, rispondere a Q1–Q4 (§2.3, con raccomandazioni).
- **Rimasto dal turno precedente:** S-73a/b/c/d `[~]` da collaudare, S-73e `[ ]` (impresa).
- **File non miei lasciati fuori dal commit:** `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` (modifica locale storica) e `MoneyTrackerUITests/FutureTransactionPlannedUITests.swift` (modificato da un'altra impresa durante il mio turno, probabilmente S-73).
