# GIORNALE DEI LAVORI

Una riga per turno, solo aggiunte in fondo. Mai modificare le righe vecchie.
I checkpoint hanno una riga che inizia con `== CHECKPOINT`.

| Quando | Chi (ruolo / strumento / modello) | Task | Fatto | Aperto |
|---|---|---|---|---|
| 2026-11-13 15:49 | Matteo | — | Cantiere aperto | Compilare AGENTS.md §1, primo piano |
| 2026-11-13 19:23 | capocantiere (Claude Code · Sonnet) | S-1 token, font, dark mode | Token Sentiero in DS (light/dark), font Space Grotesk+Inter, CategoryTint, test; build + 21 unit + 12 UI verdi | collaudo S-1 (collaudatore); poi S-2 a Codex |
| 2026-11-13 19:39 | collaudatore (Claude Code · Sonnet) | collaudo S-1 | ✅ collaudato, nessun difetto; contrasti WCAG ok | S-2 a Codex |
| 2026-11-13 20:15 | seconda impresa (Codex · GPT-6) | S-2 componenti base | Sette componenti nuovi, preview light/dark; build + 21 unit + 12 UI verdi | collaudo S-2, verifica visiva preview |
| 2026-11-13 20:20 | collaudatore (Claude Code · Sonnet) | collaudo S-2 | ❌ non conforme: chiavi i18n «Sforato»/«Soglia 80%» mancanti in 7 lingue, raggio hero 16 invece di 24–26; resto ok | S-2b rilavorazione (Codex), poi ricollaudo |
| 2026-11-13 20:35 | seconda impresa (Codex · GPT-6) | S-2b correzioni collaudo | Due chiavi in 7 lingue, hero raggio 24, layout MovementRow, accessibilità percentuale reale; build + 21 unit + 12 UI verdi | ricollaudo S-2b e chiusura S-2 |
| 2026-11-13 20:40 | collaudatore (Claude Code · Sonnet) | ricollaudo S-2b | ✅ quattro correzioni conformi; S-2 e S-2b chiusi [x] | S-3 al capocantiere; resa visiva a vista da Matteo |
| 2026-11-13 21:52 | capocantiere (Claude Code · Sonnet) | S-3 tab bar flottante + FAB | FloatingTabBar, FAB Sentiero, UI test su id tab_*; build + test verdi | collaudo S-3 (collaudatore) |
| 2026-11-13 22:08 | collaudatore (Claude Code · Sonnet) | S-3 | collaudo ok, S-3 [x] (note Dynamic Type accessibilità, FAB da vedere a vista) | S-4 |
| 2026-11-13 22:30 | capocantiere (Claude Code · Sonnet) | S-4 Home con TrailView | BalanceTrail (puro, 6 test), TrailView, HomeHeroCard, Home Sentiero; build + 27 unit + 12 UI verdi | collaudo S-4; resa a vista (curva, XL, tedesco, dark) |
| 2026-11-13 22:40 | collaudatore (Claude Code · Sonnet) | S-4 | collaudo ok, S-4 [x]: funzioni Home presenti, BalanceTrail corretto (Decimal, ancoraggi), i18n 6 lingue ok, nessuna modifica al codice | resa a vista (XL, tedesco, altezza righe ultimi movimenti) da confermare da Matteo; poi S-5 |

| 2026-11-13 22:54 | seconda impresa (Codex · GPT-6) | S-5 Movimenti | restyling, MovementRow, chip, pianificati e card giornaliere; i18n x7; build verde, grafo aggiornato | test bloccati dal runner/simulatore; collaudo e resa a vista aperti, S-5 [~] |
