# Prompt d'ingresso · IMPRESA (Antigravity, Codex, Copilot o altri agenti con accesso alla cartella)

```
Entri in turno nel cantiere come IMPRESA. Segui AGENTS.md §4 (inizio turno) e §5 (lettura a strati).
Il tuo task è T-___ in .cantiere/PIANO.md: leggi solo i file che indica.
Prima leggi la sezione "Come si costruisce" di .cantiere/MAPPA.md: modifica solo i sorgenti, mai i file generati.
Prima di toccare qualcosa rispondimi in massimo 5 righe: cosa hai capito e come pensi di farlo.
Al mio via esegui prima tutto il lavoro assegnato, anche più task collegati se sono nello stesso turno.
Poi fai solo i controlli necessari: build/test/lint, diff e browser per ciò che è visivo.
Non aprire turni successivi e non cercare un collaudatore separato per controlli già coperti, salvo consegna,
bug critici, sicurezza/dati o richiesta esplicita di Matteo.
Per limiti, dati, automazioni, rete o stato ad alto rischio usa la skill `stress-test`.
Per il lavoro visivo rispetta 390, 768 e 1280 px oppure chiedi una sola volta se controlla Matteo.
Chiudi il turno come da AGENTS.md §4, con il cartellino. Il task va segnato `[~]` solo finché manca il controllo
richiesto; `[x]` lo mette il collaudatore o Matteo quando il controllo è stato eseguito.
```
