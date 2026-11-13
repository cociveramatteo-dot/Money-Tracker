# CONSEGNA — il biglietto per chi entra in turno

**Da:** capocantiere (Claude Code · Sonnet) **Il:** 2026-11-13 19:23 **Commit:** vedi `git log -1` (S-1)

## Fatto
- S-1: token «Sentiero» adattivi light/dark nell'enum `DS` (`MoneyTracker/Views/Theme.swift`), costruttore `Color(lightHex:darkHex:)`. I nomi storici (`ink`, `paper`, `fog`, `smoke`, `positive`, `negative`) restano e cambiano valore; nuovi: `surface`, `accent`, `planned`, `danger`, `hero*`, ecc.
- Font Space Grotesk e Inter in `MoneyTracker/Resources/Fonts/` + `UIAppFonts` in `Info.plist` + licenze OFL; `DS.Typo` con `Font.custom(…, relativeTo:)`.
- `Views/CategoryTint.swift`: tinta categoria deterministica (FNV-1a), test in `CategoryTintTests` e `FontRegistrationTests`.
- Decisioni D-005 e D-006 in `.cantiere/DECISIONI.md`; `docs/MoneyTracker.md` aggiornato.

## Verificato
- Build verde, nessun warning; 21 test unitari + 12 test UI verdi su iPhone 18 Pro (iOS 27.2).
- Non verificato a occhio: resa grafica in light/dark e Dynamic Type (nessuna schermata è stata ancora ridisegnata).

## Mi sono fermato a
S-1 fatto, in attesa di collaudo. Nota d'ambiente: la prima esecuzione dell'intera suite ha dato «Test crashed with signal kill before establishing connection» (simulatore); dopo `simctl shutdown all` e rilancio separato (unit, poi UI) tutto verde.

## Prossimo passo
- Task: collaudo di S-1 (collaudatore), poi S-2 «Componenti base»
- A chi: collaudatore (Claude Code); S-2 → Codex

## Attenzione
- Scarto dall'handoff: in dark accent/planned schiariti per contrasto AA (D-005).
- Tutti i colori storici cambiano subito leggermente tinta in tutta l'app.
- Il PDF `docs/MoneyTracker.pdf` non è stato rigenerato (si fa al checkpoint).
