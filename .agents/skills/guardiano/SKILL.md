---
name: guardiano
description: Legge il rapporto del guardiano notturno (collaudo automatico su GitHub Actions - pagine, clic, link, 8 dispositivi, monkey test, accessibilità, Lighthouse, confronto visivo) e trasforma i problemi in task. Usala quando Matteo chiede "com'è andata stanotte?", "cosa ha trovato il guardiano", o per attivare il guardiano in un cantiere.
---
# Guardiano notturno

Il guardiano è uno script, non un'IA: gira su GitHub ogni notte e a ogni push, anche a Mac spento, e costa
0 crediti. Configurazione: `.cantiere/guardiano.json`. Script: `.cantiere/strumenti/guardiano/`.

## Leggere il rapporto
1. `bash .cantiere/strumenti/guardiano/scarica.sh` → porta l'ultimo rapporto in `.cantiere/guardiano/ultimo/` (veloce; `--foto` per scaricare anche gli screenshot, solo se servono)
   e ne stampa il riassunto (5 righe). Leggi SOLO quello; apri `RAPPORTO.md` solo per i problemi 🔴.
2. Per ogni problema 🔴 (o 🟡 ricorrente) crea un task in PIANO.md, raggruppando quelli con la stessa causa.
   Assegna con la skill `assegna` (di solito Antigravity per layout e grafica, Codex o Copilot per JS e correzioni piccole).
3. Rispondi a Matteo in max 5 righe: semaforo, i 3 problemi principali, task creati.
   Gli screenshot per dispositivo sono in `.cantiere/guardiano/ultimo/screenshot/` (i file `__diff` mostrano
   cosa è cambiato rispetto alla notte prima).

## Attivarlo in un cantiere (una volta)
1. Il cantiere deve essere su GitHub: `gh repo create <nome> --private --source . --push`
   (repository privato: 2000 minuti gratis al mese, un giro dura circa 10 minuti).
2. Compila `.cantiere/guardiano.json`: `cartella_sito` (dove sta il sito), `comando_build` (se serve generarlo),
   `cartella_pubblicata` (la cartella servita, es. `public`), oppure `url` per controllare l'anteprima online. Se il sito sostituisce un sito già online, metti `dominio_produzione` (es. `https://cliente.it`): i link assoluti verso quel dominio (canonical, hreflang, og) vengono controllati sull'anteprima, non sul vecchio sito.
3. Prova a mano: `gh workflow run guardiano.yml`, poi dopo 10 minuti `scarica.sh`.
4. Se il giro è rosso GitHub manda un'email a Matteo: è normale, serve a quello.

## Note
- Non bombarda il sito pubblico: un giro = poche decine di visite. Mai test di carico sul sito online.
- Per lanciarlo sul Mac (solo per prova): `bash .cantiere/strumenti/guardiano/esegui.sh` (scarica Chromium: ~300 MB).
