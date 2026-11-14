# PER MATTEO — le cose che aspettano te

Le scrivono le IA del cantiere, sempre con istruzioni complete (AGENTS.md §6.13). Quando una è fatta, la spostano
in "Fatte" con la data. `riprendiamo` e il checkpoint te le ricordano, in ordine.

## Da fare
- [ ] 2026-11-14 · Avviare il collaudo S-12. 📍 Claude Code, nella cartella `/Users/matteo/Desktop/APP/MoneyTracker`, modello Sonnet. ▶️ Incollare:
  ```text
  Entra in turno secondo AGENTS.md §4. Collauda S-12 dell'ultimo commit [seconda impresa] sul ramo redesign-sentiero: leggi CONSEGNA.md, la scheda S-12 in PIANO.md e il diff del commit. Per il codice leggi solo il diff. Confronta gli otto screenshot reali light/dark/accessibility-XL/tedesco in .cantiere/tmp con reference/Movimenti.dc.html e DESIGN_HANDOFF.md §4 nel pacchetto bucktrail-redesign. Verifica le prove 27 unit + 12 UI e i controlli su pagina unica, chip, Ricorrenti, banner e totale XL. Le differenze residue sono elencate in CONSEGNA: tab bar XL resta S-10 e motore ricorrenze S-13. Nessun calcolo o zona protetta può cambiare. Segna S-12 [x] solo se il collaudo è OK; altrimenti scrivi difetti precisi. Chiudi il turno con documenti e commit mirato secondo §4.
  ```
  ↩️ Riportare l'esito del collaudatore e gli eventuali difetti; nessun merge o pubblicazione. (Codex)
- [ ] 2026-11-13 · Segnalazione attrezzi (S-5, Codex). 📍 Nella chat «Azienda», incollare:
  ```text
  Nel cantiere MoneyTracker il controllo CUA dell'app Simulator va in timeout. xcodebuild compila (BUILD SUCCEEDED) ma il runner non avvia i test sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48: DTServiceHubClient / com.apple.instruments.deviceservice.lockdown non disponibile. Anche dopo shutdown/boot il problema persiste. Verificare il collegamento tra strumenti Codex e simulatore; non modificare codice o test per aggirare il problema.
  ```
  ↩️ Riportare al collaudatore la risposta o la conferma del ripristino. (Codex)
<!-- - [ ] AAAA-MM-GG · cosa · 📍 dove · ▶️ comando o testo esatto · ↩️ cosa riportare · (chi l'ha chiesto) -->

## Fatte
