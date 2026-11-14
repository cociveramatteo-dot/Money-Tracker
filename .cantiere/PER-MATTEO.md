# PER MATTEO — le cose che aspettano te

Le scrivono le IA del cantiere, sempre con istruzioni complete (AGENTS.md §6.13). Quando una è fatta, la spostano
in "Fatte" con la data. `riprendiamo` e il checkpoint te le ricordano, in ordine.

## Da fare
- [ ] 2026-11-14 09:29 · Avviare collaudo S-13a/b/c. 📍 Claude Code · Sonnet nella cartella `/Users/matteo/Desktop/APP/MoneyTracker`. ▶️ Incollare:
  ```text
Entra in turno secondo AGENTS.md §4 solo se STATO è libero. Sul ramo redesign-sentiero collauda S-13a/b/c, senza iniziare S-13d: leggi CONSEGNA, schede S-13/S-15, piano-s13.md e D-008/D-009; per il codice leggi solo il diff dei commit 25b1b6e e dc58891 (git diff 0a76000..dc58891 -- MoneyTracker MoneyTrackerTests). Controlla calculator/UUIDv5/Decimal, migrazioni V1→V2→V3 senza conversioni legacy, mainContext/watermark/limite 36 mesi, idempotenza e copie fatte invariate, avvii dopo sync e spegnimento del vecchio motore. Le prove registrate sono build e 48 unit verdi; tutti i 12 UI sono stati eseguiti sullo stesso codice in due sessioni, 10 verdi e due falliti già noti S-15 (stress riga55 e senza-categoria riga68). Nuovo log dei sei UI ripresi: /tmp/moneytracker-s13c-ui-resume.log; gli altri log sono in CONSEGNA. Nessuna asserzione o vista è stata modificata per aggirare i difetti; diagnostica S-15 senza correzioni fuori perimetro. Rimangono solo cinque riferimenti al vecchio actor nei commenti di file fuori perimetro, rimandati a S-13h. Segna [x] solo se il tuo collaudo lo giustifica, altrimenti registra difetti precisi e lascia [~]. Chiudi con documenti, commit mirato e STATO libero. Dopo il collaudo, prossimo sviluppo: S-13d (editor degli ambiti) a Codex.
  ```
  ↩️ Riportare cartellino ed eventuali difetti del collaudatore; poi si assegna S-13d a Codex.
- [ ] 2026-11-13 · Segnalazione attrezzi (S-5, Codex). 📍 Nella chat «Azienda», incollare:
  ```text
  Nel cantiere MoneyTracker il controllo CUA dell'app Simulator va in timeout. xcodebuild compila (BUILD SUCCEEDED) ma il runner non avvia i test sul simulatore 37445D1E-DEF7-4A32-9A39-EA9EACCA3E48: DTServiceHubClient / com.apple.instruments.deviceservice.lockdown non disponibile. Anche dopo shutdown/boot il problema persiste. Verificare il collegamento tra strumenti Codex e simulatore; non modificare codice o test per aggirare il problema.
  ```
  ↩️ Riportare al collaudatore la risposta o la conferma del ripristino. (Codex)
<!-- - [ ] AAAA-MM-GG · cosa · 📍 dove · ▶️ comando o testo esatto · ↩️ cosa riportare · (chi l'ha chiesto) -->

## Fatte

- 2026-11-14 · Collaudo S-12 completato dal collaudatore (01:30, [x]); rimossa richiesta già eseguita.

- 2026-11-14 09:29 · Ripresa Codex completata: eseguiti i sei UI rimasti, note di sospensione sostituite con esito e istruzioni di collaudo.
