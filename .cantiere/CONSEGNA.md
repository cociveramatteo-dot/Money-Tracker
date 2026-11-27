# CONSEGNA — MoneyTracker

- **Ultimo turno:** architetto (Claude Code · Opus) · **2026-11-28 00:53** · ramo `redesign-sentiero`
- **Task:** S-73 diagnosi (nessun codice di produzione toccato)
- **Esito:** causa trovata. La spesa fissa futura nasce pianificata (`isDone = false`) e il saldo attuale è giusto ovunque. In Conti sbagliano la «→» per conto e «A conti fatti»: usano `futureBalance` (tutti i movimenti di tutti i mesi), mentre la Home filtra con `DashboardView.countsInProjection` (S-41). Android uguale (`AccountsScreen.kt:88-90`).
- **Piano:** S-73a (iOS) e S-73b (Android) in `Views/` / `ui/`, senza toccare `Domain/`; S-73c/S-73d solo se Matteo sceglie l'opzione B (data futura ⇒ pianificato, come già fa Android); S-73e verifica possibile bug in modifica delle fisse «già effettuate».
- **Aspetta Matteo:** S-73q — conferma che il numero sbagliato è la «→» e approvazione di DECISIONI «2026-11-28 · S-73».
- **Rimasto dal turno precedente:** S-70k `[~]` da collaudare (impresa Antigravity, 00:43); prova reale S-70d di Matteo.
- **File non miei lasciati fuori dal commit:** `MoneyTracker.xcodeproj/xcshareddata/xcschemes/MoneyTracker.xcscheme` (modificato prima del turno).
