---
name: archivia
description: Chiude un cantiere finito - checkpoint finale, tutto su GitHub e nel magazzino, poi liberazione dello spazio sul Mac. Usala quando Matteo dice "chiudiamo il cantiere", "archivia il progetto", "il progetto è finito".
---
# Archivia (chiusura del cantiere)

Si archivia solo un progetto consegnato o abbandonato: chiedi conferma a Matteo prima di iniziare.

1. **Checkpoint completo** finale e pagella completa (se il progetto è stato consegnato).
2. **Tutto salvato**: `git status` pulito, `git push --follow-tags`. Se il cantiere non ha un remoto GitHub,
   crealo (`gh repo create <nome> --private --source . --push`) o chiedi a Matteo come procedere.
3. **Verbale di chiusura** in `.cantiere/CHIUSURA.md`: cosa è stato fatto, dove sta (link GitHub, sito online,
   magazzino, notebook), credenziali NON scritte qui, cose aperte, contatti del cliente utili, lezioni imparate
   (2–3 righe, utili per i prossimi cantieri).
4. **Copia nel magazzino**: `.cantiere/` e `01_PROGETTO/` copiati nella cartella del cantiere nel magazzino
   (sottocartella `_cantiere/`), così tutto il progetto vive su Drive anche senza il Mac.
5. **Ultimo passo (lo fa Matteo dal terminale)**:
   ```
   archivia-cantiere ~/Desktop/<CARTELLA>
   ```
   Controlla che GitHub e magazzino siano aggiornati, sposta la cartella del cantiere in `MAGAZZINO/ARCHIVIO/`
   (le dipendenze come `node_modules` vengono tolte) e aggiorna il registro dell'azienda.
6. Cartellino con `➡️ PROSSIMO: Matteo — lancia archivia-cantiere`.
