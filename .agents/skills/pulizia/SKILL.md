---
name: pulizia
description: Pulisce e riordina il cantiere (spazzatura, codice morto, file fuori posto, catalogo, spazio). Usala quando Matteo dice "pulizia", "riordina", "metti in ordine", e come fasi 2–3 del checkpoint.
---
# Pulizia (in Claude Code: fase A al subagente `pulizie`, fase B al `magazziniere`)

## A · Pulizie
Strumenti: `python3 .cantiere/strumenti/magazzino.py` e `bash .cantiere/strumenti/spazio.sh`.
- **Si cancella senza chiedere:** `.DS_Store`, `Thumbs.db`, `*.tmp`, `*.bak`, `*.swp`, `*~`, `*.orig`, log di debug,
  cartelle vuote fuori da quelle standard.
- **Si propone e si aspetta l'ok:** codice morto (verificato con `graphify explain` e `grep`), `console.log`
  di debug, risorse non usate, doppioni, file > 20 MB fuori dal magazzino (→ spostarli nel magazzino).
- **Mai toccare:** il magazzino (`00_CLIENTE`, `02_RISORSE`, `04_CONSEGNE`), `DIARIO.md`, `DECISIONI.md`,
  `.cantiere/archivio/`, `.git/`.

## B · Magazzino
1. Svuota `99_DA_SMISTARE/`: ogni file al posto giusto col nome giusto (AGENTS.md §7). Materiale del cliente
   → magazzino. In dubbio: lascialo e segnalo `[?]`.
2. Correggi i nomi sbagliati, mai dentro `03_CODICE/` (solo segnalare) né in `02_RISORSE/originali/`.
   MAI senza correggere i riferimenti nello stesso turno: prima `grep -rn "<vecchio nome>" --exclude-dir=.git .`
   e aggiorna ogni link/percorso trovato. File e cartelle che Matteo usa a mano (incontri, messaggi, documenti per
   il cliente, PDF da stampare) NON si rinominano: si propongono in "da confermare".
3. `python3 .cantiere/strumenti/catalogo.py` → aggiorna `CATALOGO.md` nel magazzino. Per i file nuovi senza
   descrizione scrivi una riga (nel catalogo, colonna Descrizione: lo script la conserva).
4. Aggiorna "Dettaglio" in `.cantiere/MAPPA.md`.

Restituisci: tolto · spostato/rinominato · da confermare (con motivo). Max 12 righe.
