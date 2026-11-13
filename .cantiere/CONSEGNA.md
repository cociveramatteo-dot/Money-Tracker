# CONSEGNA — il biglietto per chi entra in turno

**Da:** capocantiere (Claude Code · Sonnet) **Il:** 2026-11-13 21:52 **Commit:** vedi `git log -1` (S-3)

## Fatto
- `Views/Components/FloatingTabBar.swift` (capsula h66, raggio 24, margini 14, offset 20, pill `accentSoft` 44×28, 2 preview).
- `ContentView.swift`: stessa `TabView` e stessi tag 0–4, barra nativa nascosta con `.toolbar(.hidden, for: .tabBar)` **su ogni tab** (sulla TabView non basta); spazio sotto riservato con un `Color.clear` nel VStack, perché `safeAreaInset` non arrivava alle liste aperte in push (la riga finiva sotto la barra e lo swipe falliva).
- FAB 58×58 raggio 20, `accent`, plus `onAccent`, ombra accent 35%, trailing 22, 100 sopra il fondo; stessi id `fabButton`/`fabMenu_*`; `accessibilityLabel` Nuovo movimento/budget/obiettivo/conto (aggiunta «Nuovo movimento» in 7 lingue).
- UI test: `goToTab` e due asserzioni ora usano `tab_<nome>` (i tab nativi non erano più presenti).

## Verificato
build + test sul simulatore: TEST SUCCEEDED, 12 UI test verdi (unit invariati). Tre tentativi: barra nativa ancora attiva → inset non propagato → layout VStack.

- Dopo segnalazione di Matteo (premendo il FAB spariva l'ombra e comparivano «alette azzurre» di selezione): forma di anteprima del menu = squircle (`contentShape(.contextMenuPreview, …)`), `buttonStyle(.plain)`, ombra spostata fuori dall'etichetta. Non riproducibile da qui senza vista a schermo: **Matteo deve riprovare sul simulatore/iPhone**. Build + test verdi di nuovo.

## Da guardare nel collaudo
- Resa a vista (light/dark, XL, tedesco: etichette tab con `minimumScaleFactor 0.7`).
- La tab bar non scorre più sopra i contenuti (striscia `paper` sotto): scelta per robustezza, valutare con Matteo.
- Il FAB resta nascosto in ricerca movimenti come prima.

## Prossimo passo
S-3 collaudato ok. Prossimo: S-4 (Home con TrailView). Matteo: riprovare il FAB (ombra/alette) sul simulatore.
