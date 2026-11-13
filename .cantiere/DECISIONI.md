# REGISTRO DELLE DECISIONI

Le decisioni che non si devono ridiscutere ogni volta. Solo aggiunte.

## D-001 · 2026-11-13 · Adozione del modello Cantiere
- **Decisione:** il progetto segue il regolamento in AGENTS.md.
- **Perché:** stessa squadra e stesso metodo in ogni progetto, ripresa del lavoro a basso costo di token.
- **Chi ha deciso:** Matteo

## D-002 · 2026-11-13 · Rimosso il guardiano dei siti web
- **Decisione:** cancellato `.github/workflows/guardiano.yml` (Lighthouse/Playwright).
- **Perché:** è pensato per i siti web, inutile su un'app iOS, e girerebbe a ogni push su `main` e ogni notte consumando minuti GitHub. Un eventuale workflow `xcodebuild test` su runner macOS si valuta più avanti, solo con l'ok di Matteo.
- **Chi ha deciso:** brief del cantiere (Matteo)

## D-003 · 2026-11-13 · `@MainActor` su CurrencyFormattingTests
- **Decisione:** aggiunto `@MainActor` alla struct `CurrencyFormattingTests` (nessuna asserzione cambiata).
- **Perché:** il target app ha `SWIFT_DEFAULT_ACTOR_ISOLATION = MainActor`, quindi `Decimal.parseAmount` è isolato su MainActor e il test target (non isolato) non compilava: i test unitari erano rotti già prima del cantiere. Eccezione puntuale alla regola «test esistenti intoccabili», autorizzata da Matteo.
- **Chi ha deciso:** Matteo
