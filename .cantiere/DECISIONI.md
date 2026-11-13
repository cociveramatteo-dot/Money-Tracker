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

## D-004 · 2026-11-13 · Simulatore di riferimento
- **Decisione:** i test si lanciano su **iPhone 18 Pro, iOS 27.2** (`id=37445D1E-DEF7-4A32-9A39-EA9EACCA3E48`, su questo Mac).
- **Perché:** il runtime iOS 26.5 è stato rimosso; su iOS 27.1 c'era solo «iPhone Duo» e i 12 test UI fallivano (anche sul codice originale `tour-v1`: problema d'ambiente, non del cantiere). Su 27.2 tutto verde.
- **Chi ha deciso:** Matteo / Claude Code

## D-005 · 2026-11-13 · Token «Sentiero» e dark mode (S-1)
- **Decisione:** i token stanno nell'enum `DS` di `Views/Theme.swift`, adattivi con `Color(lightHex:darkHex:)`; **non** si usa `Color(hex:)` di `BucktrailTheme.swift` (colori fissi, cancellerebbe il dark mode). Un solo token per ruolo: i nomi storici restano e cambiano valore: `ink` (testo), `paper` (= `bg`), `fog` (= `border`), `smoke` (= `inkSecondary`), `positive` = alias di `accent`, `negative` = alias di `danger`. Nuovi: `surface`, `divider`, `accent`, `onAccent`, `accentSoft`, `planned`, `plannedText`, `plannedSoft`, `danger`, `dangerSoft`, `transfer`, `hero`, `heroText`, `heroSecondary`, `heroDivider`, `heroAccent`, `heroPlanned`.
- **Valori light:** tabella §2 dell'handoff. **Valori dark:** `bg #0E1210`, `surface #171C19`, testo `#F1F3EF`, `hero #1F2622` come proposto; in più `accent`/`heroAccent` `#5FD19B`, `planned`/`plannedText` `#F2A65A`, `danger #F26B5E`, `transfer #6FA8E0`, `inkSecondary #9AA39D`. **Scarto dall'handoff:** l'handoff teneva accent/planned «invariati» in dark, ma `#1F7A4D` su `#0E1210` ha contrasto ≈3.6:1 (sotto AA per il testo): le varianti schiarite superano 4.5:1 su bg e surface (calcolato). Per lo stesso motivo `onAccent` è quasi-nero in dark (testo su FAB verde chiaro).
- **Effetto visivo:** i nomi storici cambiano valore, quindi l'app prende subito una leggera tinta verde-grigia (paper, fog, smoke, ink); layout e componenti invariati finché non migrano gli step 3–9.
- **Font:** Space Grotesk (Medium, SemiBold, Bold) e Inter 18pt (Regular, Medium, SemiBold), statici, in `MoneyTracker/Resources/Fonts/` + `UIAppFonts` in `Info.plist` + licenze OFL accanto. `DS.Typo` usa `Font.custom(…, relativeTo:)` (Dynamic Type) con ripiego automatico su SF Pro; importi con `.monospacedDigit()`. Originali in `02_RISORSE/originali/font/`.
- **Chi ha deciso:** Claude Code (brief + handoff)

## D-006 · 2026-11-13 · Tinte categoria
- **Regola:** `CategoryTint.tint(for: nome)` (`Views/CategoryTint.swift`): mappa fissa per le 14 categorie predefinite (verde: Salute, Lavoro, Risparmio, Altro; ambra: Cibo, Shopping, Regali; blu: Trasporti, Casa, Viaggi, Giroconto; viola: Svago, Abbonamenti, Istruzione); per le personalizzate hash **FNV-1a 32 bit** del nome in UTF-8 modulo 4 (non `hashValue`, instabile tra avvii). Nessuna modifica al modello SwiftData; varianti dark per ogni tinta. Test in `CategoryTintTests`.
- **Chi ha deciso:** Claude Code (brief)
